# Configuration of a Ubuntu 16.04 to provide a netboot PXE image

References:

https://www.ostechnix.com/install-dhcp-server-in-ubuntu-16-04/
https://www.ostechnix.com/how-to-install-pxe-server-on-ubuntu-16-04/
http://debianaddict.com/2012/06/19/diskless-debian-linux-booting-via-dhcppxenfstftp/
https://www.linuxquestions.org/questions/blog/isaackuo-112178/diskless-pxe-netboot-how-to-for-debian-8-jessie-37169/
http://www.iram.fr/~blanchet/tutorials/read-only_diskless_debian9.pdf

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

6. Make this server as official DHCP for your clients, find and uncomment the following line in dhcpd.conf:

    ```
    [...]
    authoritative;
    [...]
    ```

    Check if the file is similiar to the one in config_files/dhcpd.conf, inside
    this reposirory.

7. Restart DHCP server

    ```bash
    sudo systemctl restart isc-dhcp-server
    ```

8. Check server status

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

## PXE server

1. Install TFTP, NFS, debootstrap

    ```bash
    sudo apt-get install tftp-hpa nfs-kernel-server debootstrap syslinux
    ```

2. Mount special filesystems:

    ```bash
    cd /srv/nfsroot/
    sudo mount -o bind /dev dev/mount -t sysfs sys sys
    sudo mount -t sysfs sys sys/
    sudo mount -o bind /dev dev/
    ```

3. We will store our initrd and boot loader under /srv/tftp and our NFS root filesystem + NFS home + NFS startup under /srv/nfsroot:

    ```bash
    sudo mkdir -p /srv/tftp /srv/nfsroot /srv/nfshome /srv/nfsstartup
    ```

4. Our nfsroot needs to be mountable via NFS. Export it read-only to our local network by putting the following in /etc/exports:

    ```
    /srv/nfsroot 10.0.0.0/24(rw,async,no_subtree_check,no_root_squash)
    /srv/nfshome 10.0.0.0/24(ro,no_root_squash,no_subtree_check)
    /srv/nfsstartup 10.0.0.0/24(ro,no_root_squash,no_subtree_check)

    /srv/nfsroot 192.168.2.0/24(rw,async,no_subtree_check,no_root_squash)
    /srv/nfshome 192.168.2.0/24(ro,no_root_squash,no_subtree_check)
    /srv/nfsstartup 192.168.2.0/24(ro,no_root_squash,no_subtree_check)
    ```

5. We will be booting to a custom Debian install. Install it in /srv/nfsroot using Debootstrap:

    ```bash
    sudo debootstrap stable /srv/nfsroot http://ftp.us.debian.org/debian
    ```

6. Install desired packages into the NFS:

    ```bash
    sudo chroot /srv/nfsroot apt-get update
    sudo chroot /srv/nfsroot apt-get install -y \
        initramfs-tools \
        linux-image-amd64
    ```

    1. Install Docker CE

        ```bash
        sudo chroot /srv/nfsroot apt-get install -y \
             apt-transport-https \
             ca-certificates \
             curl \
             gnupg2 \
             software-properties-common
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

    5. Install Docker Compose

        ```bash
        sudo chroot /srv/nfsroot curl -L \
            https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` \
            -o /usr/local/bin/docker-compose
        ```

    6. Add executable permissions

        ```bash
        sudo chroot /srv/nfsroot chmod +x /usr/local/bin/docker-compose
        ```

7. Configure its initramfs to generate NFS-booting initrd's:

    ```bash
    sudo sed 's/MODULES=.*$/MODULES=netboot/' -i /srv/nfsroot/etc/initramfs-tools/initramfs.conf
    sudo bash -c "echo "BOOT=nfs" >> /srv/nfsroot/etc/initramfs-tools/initramfs.conf"
    ```

8. Configure fstab:

    ```bash
    sudo chroot /srv/nfsroot apt-get -y install nfs-common
    ```

    ```bash
    sudo bash -c "cat << EOF > /srv/nfsroot/etc/fstab
    proc                 /proc      proc    defaults   0 0
    /dev/nfs             /          nfs     tcp,nolock 0 0
    none                 /tmp       tmpfs   defaults   0 0
    none                 /var/tmp   tmpfs   defaults   0 0
    none                 /media     tmpfs   defaults   0 0
    none                 /var/log   tmpfs   defaults   0 0
    192.168.2.12:/srv/nfshome /home   nfs     tcp,nolock 0 0
    192.168.2.12:/srv/nfsstartup /startup   nfs     tcp,nolock 0 0
    EOF
    "
    ```

9. Configure mtab

    ```bash
    sudo ln -s /proc/mounts /srv/nfsroot/etc/mtab
    ```

10. Configure root user and password in NFS home:

    ```bash
    sudo chroot /srv/nfsroot passwd root
    sudo chroot /srv/nfsroot usermod -d /home/root root

    sudo mkdir -p /srv/nfshome/root
    sudo bash -c 'echo "root user" > /srv/nfshome/root/root.txt'
    sudo chmod 755 /srv/nfshome/root/root.txt
    ```

11. Generate initrd

    ```bash
    sudo chroot /srv/nfsroot update-initramfs -u
    ```

12. Copy support libraries from debian netboot to TFTP folder

    ```bash
    mkdir -p ~/Downloads/debian-netboot && cd ~/Downloads
    wget -nc http://ftp.nl.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/netboot.tar.gz
    cd ~/Downloads/debian-netboot
    tar xvf ../netboot.tar.gz

    sudo mkdir -p /srv/tftp/bootlibs
    sudo cp ~/Downloads/debian-netboot/debian-installer/amd64/boot-screens/*.c32 /srv/tftp/bootlibs
    sudo ln -s bootlibs/ldlinux.c32 /srv/tftp/
    ```

13. Copy generated initrd, kernel image, and pxe bootloader to tftp root and create folder for PXE config:

    ```bash
    sudo cp /srv/nfsroot/boot/initrd.img-*-amd64 /srv/tftp/
    sudo cp /srv/nfsroot/boot/vmlinuz-*-amd64 /srv/tftp/
    cd /srv/tftp && wget -nc http://ftp.nl.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/pxelinux.0
    sudo mkdir /srv/tftp/pxelinux.cfg
    ```

14. Configure boot loader. Put the following into /srv/tftp/pxelinux.cfg/default:

    ```bash
    sudo bash -c "cat << EOF > /srv/tftp/pxelinux.cfg/default
    # boot diskless computer with debian stretch
    default Debian
    prompt 1
    timeout 10
    label Debian
    kernel vmlinuz-4.9.0-4-amd64
    append root=/dev/nfs initrd=initrd.img-4.9.0-4-amd64 nfsroot=192.168.2.12:/srv/nfsroot ro panic=60 ipv6.disable=1  ip=:::::eno1
    EOF
    "
    ```

15. Export  NFS folders

    ```bash
    sudo exportfs -rv
    ```

16. Check if it's running ok:

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

17. Configure tftp’s /etc/default/tftpd-hpa:

    ```
    TFTP_USERNAME="tftp"
    TFTP_DIRECTORY="/srv/tftp"
    TFTP_ADDRESS=":69"
    TFTP_OPTIONS="--secure"
    RUN_DAEMON="yes"
    OPTIONS="-l -s /srv/tftp"
    ```

18. Add the following to /etc/inetd.conf:

    ```
    tftp    dgram   udp    wait    root    /usr/sbin/in.tftpd /usr/sbin/in.tftpd -s /srv/tftp
    ```

19. Restart TFTP

    sudo systemctl restart tftpd-hpa

20. Check if it's running ok:

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

21. Add the following lines at the end of /etc/dhcp/dhcpd.conf

    ```
    allow booting;
    allow bootp;
    option option-128 code 128 = string;
    option option-129 code 129 = text;
    next-server 192.168.2.12;
    filename "pxelinux.0";
    ```

22. Restart DHCP server

    ```bash
    sudo systemctl restart isc-dhcp-server
    ```
