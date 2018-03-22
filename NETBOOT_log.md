# Configuration of a Ubuntu 16.04 to provide a netboot PXE image

References:

[1](https://www.ostechnix.com/install-dhcp-server-in-ubuntu-16-04/)
[2](https://www.ostechnix.com/how-to-install-pxe-server-on-ubuntu-16-04/)
[3](http://debianaddict.com/2012/06/19/diskless-debian-linux-booting-via-dhcppxenfstftp/)
[4](https://www.linuxquestions.org/questions/blog/isaackuo-112178/diskless-pxe-netboot-how-to-for-debian-8-jessie-37169/)
[5](http://www.iram.fr/~blanchet/tutorials/read-only_diskless_debian9.pdf)

## DHCP server

1. Install DHCP server

    ```bash
    sudo apt-get install isc-dhcp-server
    ```

2. Open DHCP server configuration file

    ```bash
    sudo vim /etc/default/isc-dhcp-server
    ```

3. Assign network interface:

    ```
    [...]
    INTERFACES="eth2"
    ```

4. Enter the domain name and domain-name-servers in dhcpd.conf:

    ```
    option domain-name-servers 10.0.18.1;
    option routers 10.0.18.1;
    ```

5. Configure server to ONLY supply IPs to specified MAC addresses in dhcpd.conf:

    ```
    subnet 192.168.2.0 netmask 255.255.255.0 {
      range 192.168.2.30 192.168.2.100;
      option domain-name-servers 192.168.2.1;
      option domain-name "test-dig1.lan";
      option subnet-mask 255.255.255.0;
      option routers 192.168.2.1;
      option broadcast-address 192.168.2.255;
      default-lease-time 600;
      max-lease-time 7200;
    }

    group {

        use-host-decl-names on; # Forces hostname to host

        host dell-r230-server-1 {
          option domain-name-servers 192.168.2.1;
          option domain-name "test-dig1.lan";
          option routers 192.168.2.1;
          option broadcast-address 192.168.2.255;
          default-lease-time 600;
          max-lease-time 7200;
          hardware ethernet 50:9a:4c:75:ce:3d;
        #  fixed-address 10.0.18.230;
          fixed-address 192.168.2.230;
        }

        host dell-r230-server-1-idrac {
          option domain-name-servers 192.168.2.1;
          option domain-name "test-dig2.lan";
          option routers 192.168.2.1;
          option broadcast-address 192.168.2.255;
          default-lease-time 600;
          max-lease-time 7200;
          hardware ethernet 50:9a:4c:75:ce:3f;
        #  fixed-address 10.0.18.231;
          fixed-address 192.168.2.231;
        }
    }
    ```

6. Add the following lines at the end of /etc/dhcp/dhcpd.conf

    ```
    allow booting;
    allow bootp;
    option option-128 code 128 = string;
    option option-129 code 129 = text;
    next-server 192.168.2.12;
    filename "pxelinux.0";
    ```

7. Make this server as official DHCP for your clients, find and uncomment the following line in dhcpd.conf:

    ```
    [...]
    authoritative;
    [...]
    ```

    Check if the file is similiar to the one in config_files/dhcpd.conf, inside
    this reposirory.

8. Restart DHCP server

    ```bash
    sudo systemctl restart isc-dhcp-server
    ```

9. Check server status

    ```bash
    sudo systemctl status isc-dhcp-server
    ```

    ```bash
    lerwys@lerwysPC:/srv$ sudo systemctl status isc-dhcp-server
    ● isc-dhcp-server.service - ISC DHCP IPv4 server
       Loaded: loaded (/lib/systemd/system/isc-dhcp-server.service; enabled; vendor preset: enabled)
       Active: active (running) since Seg 2018-03-05 13:44:53 -03; 3s ago
         Docs: man:dhcpd(8)
     Main PID: 22331 (dhcpd)
        Tasks: 1
       Memory: 7.1M
          CPU: 8ms
       CGroup: /system.slice/isc-dhcp-server.service
               └─22331 dhcpd -user dhcpd -group dhcpd -f -4 -pf /run/dhcp-server/dhcpd.pid -cf /etc/dhcp/dhcpd.conf eth2

    Mar 05 13:44:53 lerwysPC dhcpd[22331]: Wrote 0 deleted host decls to leases file.
    Mar 05 13:44:53 lerwysPC dhcpd[22331]: Wrote 0 new dynamic host decls to leases file.
    Mar 05 13:44:53 lerwysPC dhcpd[22331]: Wrote 0 leases to leases file.
    Mar 05 13:44:53 lerwysPC dhcpd[22331]: Listening on LPF/eth2/34:e6:d7:fc:44:c2/10.0.18.0/24
    Mar 05 13:44:53 lerwysPC sh[22331]: Listening on LPF/eth2/34:e6:d7:fc:44:c2/10.0.18.0/24
    Mar 05 13:44:53 lerwysPC sh[22331]: Sending on   LPF/eth2/34:e6:d7:fc:44:c2/10.0.18.0/24
    Mar 05 13:44:53 lerwysPC sh[22331]: Sending on   Socket/fallback/fallback-net
    Mar 05 13:44:53 lerwysPC dhcpd[22331]: Sending on   LPF/eth2/34:e6:d7:fc:44:c2/10.0.18.0/24
    Mar 05 13:44:53 lerwysPC dhcpd[22331]: Sending on   Socket/fallback/fallback-net
    Mar 05 13:44:53 lerwysPC dhcpd[22331]: Server starting service.
    ```


## Docker Registry (TESTING ONLY, using self-signed certificates)

This assumes docker-ce and docker-compose have been previously installed
by following the instructions in [Docker Installation Instructions](https://docs.docker.com/install/)

1. Generate your own certificate:

    ```bash
    sudo mkdir -p /certs

    sudo openssl req \
        -newkey rsa:4096 -nodes -sha256 -keyout /certs/domain.key \
        -x509 -days 365 -out /certs/domain.crt
    ```

    Be sure to use digdockerregistry.com.br as the CN

    ```bash
    sudo mkdir -p /etc/docker/certs.d/digdockerregistry.com.br:443
    sudo cp /certs/domain.crt /etc/docker/certs.d/digdockerregistry.com.br:443/ca.crt

    sudo cp /certs/domain.crt /usr/local/share/ca-certificates/digregistrydomain.com.br.crt
    sudo update-ca-certificates
    ```

2. Copy generated .crt to NFS home (to be done after configuring PXE server and /srv/nfsroot)

    ```bash
    sudo mkdir -p /srv/nfsroot/etc/docker/certs.d/digdockerregistry.com.br:443
    sudo cp /certs/domain.crt /srv/nfsroot/etc/docker/certs.d/digdockerregistry.com.br:443/ca.crt

    sudo cp /certs/domain.crt /srv/nfsroot/usr/local/share/ca-certificates/digregistrydomain.com.br.crt
    sudo chroot /srv/nfsroot update-ca-certificates
    ```

3. Registry domain name in DNS or change the host /etc/hosts:

    ```bash
    sudo bash -c 'echo "192.168.2.12 digdockerregistry.com.br" >> /etc/hosts'
    ```

4. Restart docker engine

    ```bash
    sudo systemctl restart docker
    ```

5. Run Docker registry

    ```bash
    docker run -d \
      --restart=always \
      --name registry \
      -v /certs:/certs \
      -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
      -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
      -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
      -p 443:443 \
      registry:2
    ```

6. Push images with tag digdockerregistry.com.br

    Example:
    ```bash
    docker tag lnlsidg/dmm7510-epics-ioc:debian-9 digdockerregistry.com.br/dmm7510-epics-ioc:debian-9
    docker push digdockerregistry.com.br/dmm7510-epics-ioc:debian-9
    ```

## PXE server

1. Install TFTP, NFS, debootstrap

    ```bash
    sudo apt-get install tftp-hpa nfs-kernel-server debootstrap syslinux
    ```

3. We will store our initrd and boot loader under /srv/tftp and our NFS root filesystem under /srv/nfsroot and NFS home under/srv/nfshome:

    ```bash
    sudo mkdir -p /srv/tftp /srv/nfsroot /srv/nfshome/{dell-r230-server-1,dell-r230-server-2}
    ```

3. Configure tftp’s /etc/default/tftpd-hpa:

    ```
    TFTP_USERNAME="tftp"
    TFTP_DIRECTORY="/srv/tftp"
    TFTP_ADDRESS=":69"
    TFTP_OPTIONS="--secure"
    RUN_DAEMON="yes"
    OPTIONS="-l -s /srv/tftp"
    ```

4. Add the following to /etc/inetd.conf:

    ```
    tftp    dgram   udp    wait    root    /usr/sbin/in.tftpd /usr/sbin/in.tftpd -s /srv/tftp
    ```

5. Restart TFTP

    sudo systemctl restart tftpd-hpa

6. Check if it's running ok:

    ```bash
	lerwys@lerwysPC:~/Repos/Installation_instructions$ sudo systemctl status tftpd-hpa
	● tftpd-hpa.service - LSB: HPA's tftp server
	   Loaded: loaded (/etc/init.d/tftpd-hpa; bad; vendor preset: enabled)
	   Active: active (running) since Seg 2018-03-05 14:06:37 -03; 3s ago
	     Docs: man:systemd-sysv-generator(8)
	  Process: 23372 ExecStop=/etc/init.d/tftpd-hpa stop (code=exited, status=0/SUCCESS)
	  Process: 23384 ExecStart=/etc/init.d/tftpd-hpa start (code=exited, status=0/SUCCESS)
	    Tasks: 1
	   Memory: 192.0K
	      CPU: 9ms
	   CGroup: /system.slice/tftpd-hpa.service
	           └─23399 /usr/sbin/in.tftpd --listen --user tftp --address :69 --secure /srv/tftp

	Mar 05 14:06:37 lerwysPC systemd[1]: Starting LSB: HPA's tftp server...
	Mar 05 14:06:37 lerwysPC tftpd-hpa[23384]:  * Starting HPA's tftpd in.tftpd
	Mar 05 14:06:37 lerwysPC tftpd-hpa[23384]:    ...done.
	Mar 05 14:06:37 lerwysPC systemd[1]: Started LSB: HPA's tftp server.
    ```

7. Mount special filesystems:

    ```bash
    cd /srv/nfsroot/
    sudo mount -o bind /dev dev/mount -t sysfs sys sys
    sudo mount -t sysfs sys sys/
    sudo mount -o bind /dev dev/
    ```

8. Our nfsroot and nfshome needs to be mountable via NFS. Export them to our local network by putting the following in /etc/exports:

    ```
    /srv/nfsroot 10.0.0.0/24(rw,async,no_subtree_check,no_root_squash)
    #/srv/nfshome 10.0.0.0/24(ro,no_root_squash,no_subtree_check)
    /srv/nfshome/dell-r230-server-1 10.0.0.0/24(rw,async,no_subtree_check,insecure)
    /srv/nfshome/dell-r230-server-2 10.0.0.0/24(rw,async,no_subtree_check,insecure)

    /srv/nfsroot 192.168.2.0/24(rw,async,no_subtree_check,no_root_squash)
    #/srv/nfshome 192.168.2.0/24(ro,no_root_squash,no_subtree_check)
    /srv/nfshome/dell-r230-server-1 192.168.2.0/24(rw,async,no_subtree_check,insecure)
    /srv/nfshome/dell-r230-server-2 192.168.2.0/24(rw,async,no_subtree_check,insecure)
    ```

9. Check if NFS server is running ok:

    ```bash
    sudo systemctl status nfs-kernel-server.service
    ```

    ```bash
    lerwys@lerwysPC:~$ sudo systemctl status nfs-kernel-server.service
    ● nfs-server.service - NFS server and services
       Loaded: loaded (/lib/systemd/system/nfs-server.service; enabled; vendor preset: enabled)
       Active: active (exited) since Seg 2018-03-05 14:10:22 -03; 850ms ago
      Process: 23643 ExecStopPost=/usr/sbin/exportfs -f (code=exited, status=0/SUCCESS)
      Process: 23641 ExecStopPost=/usr/sbin/exportfs -au (code=exited, status=0/SUCCESS)
      Process: 23638 ExecStop=/usr/sbin/rpc.nfsd 0 (code=exited, status=0/SUCCESS)
      Process: 23659 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
      Process: 23655 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
     Main PID: 23659 (code=exited, status=0/SUCCESS)

    Mar 05 14:10:21 lerwysPC systemd[1]: Starting NFS server and services...
    Mar 05 14:10:22 lerwysPC systemd[1]: Started NFS server and services.
    ```

10. Export  NFS folders

    ```bash
    sudo exportfs -rv
    ```

11. We will be booting to a custom Debian install. Install it in /srv/nfsroot using Debootstrap:

    ```bash
    sudo debootstrap stable /srv/nfsroot http://ftp.us.debian.org/debian
    ```

12. Configure user and password:
    ```bash
    sudo chroot /srv/nfsroot passwd root
    sudo chroot /srv/nfsroot usermod -d /home/root root

    sudo chroot /srv/nfsroot adduser server
    ```

13. Install desired packages into the NFS:

    ```bash
    sudo chroot /srv/nfsroot apt-get update
    sudo chroot /srv/nfsroot apt-get install -y \
        initramfs-tools \
        linux-image-amd64 \
        autofs \
        openssh-server
    ```

    1. Install Docker CE

        ```bash
        sudo chroot /srv/nfsroot apt-get install -y \
             apt-transport-https \
             ca-certificates \
             curl \
             gnupg2 \
             software-properties-common \
             lvm2
        ```

    2. Add GPG key:

        ```bash
        sudo chroot /srv/nfsroot bash -c "curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -"
        ```

    3. Add apt repository

        ```bash
        sudo chroot /srv/nfsroot add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
            $(lsb_release -cs) \
            stable"
        ```

    4. Update and install docker CE

        ```bash
        sudo chroot /srv/nfsroot apt-get update
        sudo chroot /srv/nfsroot apt-get install -y docker-ce
        ```

    5. Add docker group permissions

        ```bash
        sudo chroot /srv/nfsroot groupadd docker
        sudo chroot /srv/nfsroot usermod -aG docker server
        ```

    6. Install Docker Compose

        ```bash
        sudo chroot /srv/nfsroot curl -L \
            https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` \
            -o /usr/local/bin/docker-compose
        ```

    7. Add executable permissions

        ```bash
        sudo chroot /srv/nfsroot chmod +x /usr/local/bin/docker-compose
        ```

    8. Change default Docker Storage Driver to device-mapper

        ```bash
        sudo bash -c 'cat << "EOF" > /srv/nfsroot/etc/docker/daemon.json
        {
          "storage-driver": "overlay2"
        }
        EOF
        '
        ```

    9. Setup autofs to mount the hostname home directory

        ```bash
        sudo bash -c 'echo -e "\n# Automount NFS partitions\n/home   /etc/auto.home" \
            >> /srv/nfsroot/etc/auto.master'
        ```

        ```bash
        sudo bash -c 'cat << "EOF" > /srv/nfsroot/etc/auto.home
        server   192.168.2.12:/srv/nfshome/$HOST
        EOF
        '
        ```

14. Configure its initramfs to generate NFS-booting initrd's:

    ```bash
    sudo sed 's/MODULES=.*$/MODULES=netboot/' -i /srv/nfsroot/etc/initramfs-tools/initramfs.conf
    sudo bash -c "echo "BOOT=nfs" >> /srv/nfsroot/etc/initramfs-tools/initramfs.conf"
    ```

15. Configure fstab:

    ```bash
    sudo chroot /srv/nfsroot apt-get -y install nfs-common
    ```

    ```bash
    sudo chroot /srv/nfsroot mkdir -p /var/lib/docker /etc/{docker,docker.rw}
    ```

    ```bash
    sudo bash -c "cat << EOF > /srv/nfsroot/etc/fstab
    proc                 /proc      proc    defaults   0 0
    /dev/nfs             /          nfs     tcp,nolock 0 0
    none                 /tmp       tmpfs   defaults   0 0
    none                 /var/tmp   tmpfs   defaults   0 0
    none                 /media     tmpfs   defaults   0 0
    none                 /var/log   tmpfs   defaults   0 0
    none                 /etc/docker.rw   tmpfs   defaults   0 0
    none                 /var/lib/docker   tmpfs   defaults   0 0
    EOF
    "
    ```

    ```bash
    sudo bash -c 'cat << EOF > /srv/nfsroot/etc/systemd/system/mount-docker-overlay.service
    [Unit]
    Description=Mount /etc/docker as an overlay fielsystem
    RequiresMountsFor=/etc/docker.rw
    Before=docker.service
    Requires=docker.service

    [Service]
    ExecStart=/bin/sh -c " \
        /bin/mkdir -p /etc/docker.rw/rw && \
        /bin/mkdir -p /etc/docker.rw/workdir && \
        /bin/mount -t overlay overlay \
            -olowerdir=/etc/docker,upperdir=/etc/docker.rw/rw,workdir=/etc/docker.rw/workdir /etc/docker \
    "

    [Install]
    WantedBy=multi-user.target
    EOF
    '
    ```

    ```bash
    sudo chroot /srv/nfsroot systemctl enable mount-docker-overlay
    ```

16. Registry domain name in DNS or change the host /srv/nfsroot/etc/hosts:

    ```bash
    sudo bash -c 'echo "192.168.2.12 digdockerregistry.com.br" >> /srv/nfsroot/etc/hosts'
    ```

17. Configure mtab

    ```bash
    sudo ln -s /proc/mounts /srv/nfsroot/etc/mtab
    ```

18. Add bootstrap service for applications

    ```bash
    sudo bash -c "cat << EOF > /srv/nfsroot/etc/systemd/system/bootstrap-apps.service
    [Unit]
    Description=Bootstrap service to load applications
    After=autofs.service
    Wants=autofs.service
    After=docker.service
    Wants=docker.service
    After=mount-docker-overlay.service
    Requires=mount-docker-overlay.service

    [Service]
    ExecStart=/home/server/bootstrap-apps.sh

    [Install]
    WantedBy=multi-user.target
    EOF
    "
    ```

    ```bash
    sudo chroot /srv/nfsroot systemctl enable bootstrap-apps
    ```

19. Configure NFS homes:

    ```bash
    sudo mkdir -p /srv/nfshome/dell-r230-server-1
    sudo bash -c 'cat << 'EOF' > /srv/nfshome/dell-r230-server-1/bootstrap-apps.sh
    #!/usr/bin/env bash


    DMM7510_INSTANCE=DCCT1
    # Testing Image
    /usr/bin/docker pull \
        digdockerregistry.com.br/dmm7510-epics-ioc:debian-9

    /usr/bin/docker run \
        --net host \
        -t \
        --rm \
        --volumes-from dmm7510-epics-ioc-${DMM7510_INSTANCE}-volume \
        --name dmm7510-epics-ioc-DCCT1 \
        digdockerregistry.com.br/dmm7510-epics-ioc:debian-9 \
        -i 10.0.18.37 \
        -p 5025 \
        -d DCCT1 \
        -P TEST: \
        -R DCCT:
    EOF
    '
    sudo chmod 755 /srv/nfshome/dell-r230-server-1/bootstrap-apps.sh

    sudo mkdir -p /srv/nfshome/dell-r230-server-2
    sudo bash -c 'cat << 'EOF' > /srv/nfshome/dell-r230-server-2/bootstrap-apps.sh
    #!/usr/bin/env bash


    DMM7510_INSTANCE=DCCT2
    # Testing Image
    /usr/bin/docker pull \
        digdockerregistry.com.br/dmm7510-epics-ioc:debian-9

    /usr/bin/docker run \
        --net host \
        -t \
        --rm \
        --volumes-from dmm7510-epics-ioc-${DMM7510_INSTANCE}-volume \
        --name dmm7510-epics-ioc-DCCT1 \
        digdockerregistry.com.br/dmm7510-epics-ioc:debian-9 \
        -i 10.0.18.37 \
        -p 5025 \
        -d DCCT1 \
        -P TEST: \
        -R DCCT:
    EOF
    '
    sudo chmod 755 /srv/nfshome/dell-r230-server-2/bootstrap-apps.sh

    ```

20. Generate initrd

    ```bash
    sudo chroot /srv/nfsroot update-initramfs -u
    ```

21. Copy support libraries from debian netboot to TFTP folder

    ```bash
    mkdir -p ~/Downloads/debian-netboot && cd ~/Downloads
    wget -nc http://ftp.nl.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/netboot.tar.gz
    cd ~/Downloads/debian-netboot
    tar xvf ../netboot.tar.gz

    sudo mkdir -p /srv/tftp/bootlibs
    sudo cp ~/Downloads/debian-netboot/debian-installer/amd64/boot-screens/*.c32 /srv/tftp/bootlibs
    sudo ln -s bootlibs/ldlinux.c32 /srv/tftp/
    ```

22. Copy generated initrd, kernel image, and pxe bootloader to tftp root and create folder for PXE config:

    ```bash
    sudo cp /srv/nfsroot/boot/initrd.img-*-amd64 /srv/tftp/
    sudo cp /srv/nfsroot/boot/vmlinuz-*-amd64 /srv/tftp/
    cd /srv/tftp && wget -nc http://ftp.nl.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/pxelinux.0
    sudo mkdir /srv/tftp/pxelinux.cfg
    ```

23. Configure boot loader. Put the following into /srv/tftp/pxelinux.cfg/default:

    ```bash
    sudo bash -c "cat << EOF > /srv/tftp/pxelinux.cfg/default
    # boot diskless computer with debian stretch
    default Debian
    prompt 1
    timeout 10
    label Debian
    kernel vmlinuz-4.9.0-4-amd64
    append root=/dev/nfs initrd=initrd.img-4.9.0-4-amd64 nfsroot=192.168.2.12:/srv/nfsroot ro panic=10 ipv6.disable=1  ip=:::::eno1
    EOF
    "
    ```
24. PXE server is ready to go. Reboot the client into PXE boot and wait for initizalization.
