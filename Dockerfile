FROM debian:12

RUN apt-get update && apt-get dist-upgrade -y && \
    apt-get install -y qemu-system-x86 ovmf iproute2 telnet apache2 curl vim && \
    mkdir -p /opt/onie

COPY mk-vm.sh /opt/onie/
COPY onie-recovery-x86_64-kvm_x86_64-r0.iso /opt/onie/
COPY LICENSE.onie /opt/onie/

RUN chmod 755 /opt/onie/mk-vm.sh && ln -s /opt/onie/mk-vm.sh /usr/local/bin/mk-vm.sh
