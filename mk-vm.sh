#!/bin/bash
CPU=$(nproc)
MEM=8192
DISK="/opt/onie/onie-x86-demo.img"
DISK_SIZE=20G
CDROM="/opt/onie/onie-recovery-x86_64-kvm_x86_64-r0.iso"
OVMF="/usr/share/ovmf/OVMF.fd"
TELNET_CLIENT_IP="0.0.0.0"
TELNET_CLIENT_PORT="4321"
VM_LOG="$(mktemp)"

function log_info () { echo -e "\033[01;32m[INFO]\033[0m $@"; }
function log_erro () { echo -e "\033[01;31m[ERRO]\033[0m $@" >&2; }
function on_exit() { rm -f "${VM_LOG}"; }

trap on_exit EXIT

if [ ! -f "${DISK}" ] ; then
    BOOT="order=cd,once=d"
    log_info "Creating disk ${DISK} ${DISK_SIZE} (format qcow2)"
    qemu-img create -f qcow2 ${DISK} ${DISK_SIZE}
else
    BOOT="order=c"
fi

qemu-system-x86_64 \
    -name "onie" \
    -smp ${CPU} \
    -m ${MEM} \
    -device e1000,netdev=onienet \
    -netdev user,id=onienet,hostfwd=:0.0.0.0:3040-:22 \
    -cdrom ${CDROM} \
    -drive file=${DISK},media=disk,if=virtio,index=0 \
    -boot ${BOOT} \
    -serial telnet:${TELNET_CLIENT_IP}:${TELNET_CLIENT_PORT},server,nowait \
    -nographic > ${VM_LOG} 2>&1 &

VM_PID=$!

sleep 0.5

if [ ! -d "/proc/${VM_PID}" ] ; then
    log_erro "[ERRO] VM died"
    cat ${VM_LOG}
    exit 1
fi

log_info ">> telnet localhost ${TELNET_CLIENT_PORT}"
log_info ">> tail -f ${VM_LOG}"
log_info ">> kill ${VM_PID}"
log_info ">> rm ${DISK} # initialize"
log_info "Connecting VM with telnet..."

telnet localhost ${TELNET_CLIENT_PORT}

log_info "to kill VM: kill ${VM_PID}"

exit 0
