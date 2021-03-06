# [Fully Automated Installation](http://fai-project.org/)

* System to automate the installation of a Linux based operating system using a pre-defined [configuration space](http://fai-project.org/fai-guide/#_a_id_c3_a_the_configuration_space_and_its_subdirectories)
* FAI boots a live system over the network into the memory of the node and follows a defined list of tasks to install on the local storage

Basic FAI server deployment:

```bash
>>> grep -i pretty /etc/os-release
PRETTY_NAME="Debian GNU/Linux 8 (jessie)"
>>> wget -O - http://fai-project.org/download/074BCDE4.asc | apt-key add -
>>> echo "deb http://fai-project.org/download jessie koeln" > /etc/apt/sources.list.d/fai.list
>>> apt update && apt -y upgrade && apt -y install fai-quickstart
>>> sed -i -e 's/^#deb/deb/' /etc/fai/apt/sources.list
>>> sed -i -e 's/#LOGUSER/LOGUSER/' /etc/fai/fai.conf
>>> fai-setup -v                                 # build the NFS root directory in /srv/fai/nfsroot
## -- following the FAI guide -- ##
>>> cp -a /usr/share/doc/fai-doc/examples/simple/* /srv/fai/config/
                                                 # copy the example configiration space
>>> grep fai /etc/exports
/srv/fai/nfsroot *(async,ro,no_subtree_check,no_root_squash)
/srv/fai/config *(async,ro,no_subtree_check,no_root_squash)
>>> systemctl restart nfs-kernel-server
>>> exportfs
```

Stand alone ISO CD images for off-line deployment on target node:

```bash
>>> fai-mirror -c LINUX,AMD64,FAIBASE,DEBIAN,GRUB_PC -v /srv/fai/mirror | tee /var/log/fai-mirror.log
                                                 # Create a package mirror for a FAI CD
>>> tree /srv/fai/mirror/                        # mirror package tree
>>> fai-make-nfsroot -l
>>> fai-cd -m /srv/fai/mirror/ /srv/http/fai.iso # create a stand alone FAI CD for offline deployment
```

Variables:

```bash
FAI_CONFIGDIR                                   # defaults to /srv/fai/config on the server
                                                # defaults to /var/lib/fai/config during installation
LOGDIR                                          # defaults to /tmp/fai during deployment
source $LOGDIR/variables.log                    # load the FAI environment for testing/debugging
```

## Configuration

Custom FAI configuration folder **`FAI_CONFIG`** includes:

* NFS root directory for the live-system booted during installation
* The configuration-space used during installation
* The boot configuration used to boot over the network

Note: It is recommended to keep this configuration in version control system

```bash
>>> FAI_CONFIG=/srv/devops                      # path to the custom FAI configuration
>>> mkdir -p $FAI_CONFIG/{config,nfsroot,http,tftp,nfsroot-hooks}
>>> cp -a /usr/share/doc/fai-doc/examples/simple/* $FAI_CONFIG/config && cp -r /etc/fai/* $FAI_CONFIG/
                                                # copy the default configuration
>>> grep devops $FAI_CONFIG/nfsroot.conf        # adjust the configuration to custom path
NFSROOT=/srv/devops/nfsroot
TFTPROOT=/srv/devops/tftp
NFSROOT_HOOKS=/srv/devops/nfsroot-hooks/
FAI_CONFIGDIR=/srv/devops/config
```

Build the NFS root file-system from custom configuration:

```bash
>>> fai-make-nfsroot -v -C $FAI_CONFIG          # build a basic NFS root
>>> cat $FAI_CONFIG/NFSROOT                     # packages installed into the NFS root
>>> fai-make-nfsroot -vk -C $FAI_CONFIG         # install additional packages after modifing the above file
```

Export the NFS root file-system:

```bash
>>> source $FAI_CONFIG/nfsroot.conf             # read the NFR root configuration
>>> echo "$NFSROOT *(async,ro,no_subtree_check,no_root_squash)" >> /etc/exports
                                                # export the NFS root
>>> echo "$FAI_CONFIGDIR *(async,ro,no_subtree_check)" >> /etc/exports
                                                # export the configuration space
>>> systemctl restart nfs-kernel-server && exportfs
```

### Boot

Boot over HTTP with iPXE

```bash
>>> apt -y install lighttpd                                  # install a web-server
>>> grep server.document-root /etc/lighttpd/lighttpd.conf    # configure the document root
server.document-root        = "/srv/devops/http"
>>> systemctl restart lighttpd                               # load ne configuration
>>> cp $FAI_CONFIG/nfsroot/boot/{initrd,vmlinuz}* $FAI_CONFIG/http
                                                             # copy the kernel and init RAM disk
>>> cat $FAI_CONFIG/http/default                             # default iPXE configuration
#!ipxe
initrd initrd.img-3.16.0-4-amd64
kernel vmlinuz-3.16.0-4-amd64 ip=dhcp ro root=10.1.1.27:/srv/devops/nfsroot aufs FAI_FLAGS=verbose,sshd,createvt FAI_CONFIG_SRC=nfs://10.1.1.27/srv/devops/config FAI_ACTION=install
```

Kernel/init options [Dracut NFS](https://www.kernel.org/pub/linux/utils/boot/dracut/dracut.html#_nfs), [FAI Flags](http://fai-project.org/fai-guide/#_a_id_faiflags_a_fai_flags)

```bash
console=tty0 console=ttyS1,115200n8                           # Configure the serial console
rd.shell rd.debug log_buf_len=1M                              # Kernel debugging
FAI_FLAGS=[…],sshd,createvt                                   # enable SSH login during deployment
                                                              # access another console with ALT-F2, and ALT-F3
```

### Tasks

* Most tasks are defined in `/usr/lib/fai/subroutines`
* [The list of tasks](http://fai-project.org/fai-guide/#tasks) to install on the local storage

```bash
grep ^task /usr/lib/fai/subroutines                           # get the list of tasks
ls -1 /usr/lib/fai/task*                                      # list of external tasks
source /usr/lib/fai/subroutines && task_<name>                # execute a task for debugging during deployment
```

### Classes

* [Classes](http://fai-project.org/fai-guide/#_a_id_classc_a_the_class_concept) determine which configuration files to apply on a given node during installation
* Multiple nodes sharing the same configuration by having the same classes associated
* The order of the classes is important because it defines the priority of the classes from low to high
* Class [definition](http://fai-project.org/fai-guide/#defining%20classes): Uppercase, no hyphen, hash, semicolon, dot, but may contain underscores and digits

```bash
ls -1 $FAI_CONFIGDIR/class/[0-9][0-9]*           # files defining classes
cat $FAI_CONFIGDIR/class/50-host-classes         # define classes depending on the host name
grep -H -oP '\b[A-Z0-9_]*[A-Z]+[A-Z0-9_]*\b' $FAI_CONFIGDIR/class/[0-9][0-9]* | cut -d: -f2 | sort | uniq
                                                 # list all classes
ls -1 $FAI_CONFIGDIR/class/*.var                 # files defining variables
fai-class $FAI_CONFIGDIR /tmp/fai/FAI_CLASSES    # script used to extract class definition from configuration
$LOGDIR/fai.log                                  # common log information from the $FAI_NFSROOT/usr/sbin/fai
```

### Variables

* [Defining variables](http://fai-project.org/fai-guide/#_a_id_classvariables_a_defining_variables)
* Hooks should add variables to the `/additional.var`

```bash
$FAI_CONFIGDIR/class/*.var                       # configuration files for variables 
source /usr/lib/fai/subroutines && task_defvar   # debug the task
$LOGDIR/additional.var                           # file read from task_defvar
$LOGDIR/variables.log                            # file created by task_defvar
/usr/sbin/fai                                    # reads from /proc/cmdline  with `eval_cmdline`
/usr/lib/fai/get-boot-info                       # reads network configurationm called by `fai`
$LOGDIR/boot.log                                 # written by `get-boot-info`
```

### Storage

Configure RAIDs, LVM and partitions with **`setup-storage`**

```bash
man -P 'less -p "^EXAMPLES"' setup-storage      # show example configuration in documentation
ls -1 $FAI_CONFIGDIR/disk_config/ | grep '^[A-Z0-9]*$'
                                                # list storage configuration files
setup-storage -s -f $FAI_CONFIGDIR/disk_config/<class>
                                                # check the syntax of a storage configuration file
setup-storage -d -f $FAI_CONFIGDIR/disk_config/<class>
                                                # execute storage configuration manually for testing
$LOGDIR/format.log                              # output of setup-storage during deployment
grep -H disklist $LOGDIR/*                      # list of available drives in the system
fai-disk-info                                   # called if $disklist unset
$LOGDIR/fstab                                   # generated afer successful storage setup
$LOGDIR/disk_vars.sh                            # consumed by $FAI_CONFIGDIR/scripts/GRUB_PC/10-setup
```

### Packages

Define  [additional packages to be installed](http://fai-project.org/fai-guide/#_a_id_packageconfig_a_software_package_configuration) by **`install_packages`**

```bash
ls -1 $FAI_CONFIGDIR/debconf | grep '^[A-Z0-9]*$' | sort
                                                # pressed configuratin for packages
ls -1 $FAI_CONFIGDIR/package_config/*.asc       # apt keys added during deployment
ls -1 $FAI_CONFIGDIR/package_config/ | grep '^[A-Z0-9]*$'
                                                # package configuration files
install_packages -H                             # list of command supported in package configuration
install_packages -l                             # list packages which will be installed
FAI_ROOT                                        # defaults to /target mount-point for local file-systems
```

### Scripts

Custom code executed during installation by **`fai-do-scripts`**

* Each class uses a dedicated script directory which will be executed in alphabetical order
* Copy files with `fcopy`, extract archive s with `ftar`, appending lines to files with `ainsl`

```bash
ls -1 $FAI_CONFIGDIR/scripts/<class>/[0-9][0-9]* # scripts for a particular class
fai-do-scripts /var/lib/fai/config/scripts
$LOGDIR/shell.log                                # common logger location for executed scripts
```

## Test

Make sure to understand how to build [development and test environments with virtual machine](libvirt.md).

```bash
>>> qemu-img create -f qcow2 disk.img 100G  # disk image for the test virtual machine
>>> virsh-config -CNv -m 02:FF:0A:0A:06:1C libvirt_instance.xml
>>> virsh create libvirt_instance.xml
## ---  Hit CTRL-B to enter the iPXE shell -- ##
>>> dhcp                                        # enable the network interface
>>> chain http://10.1.1.27/default              # chain load iPXE configuration from the FAI server over HTTP
## -- Shift-Up/Down to scroll con qemu console -- ##
```

Connect external nodes to the virtual machine instance running a FAI server:

* Configure [network booting with PXE](pxe.md) to target the host of the virtual machine instance 
* Use port forwarding to make the TFTP-, HTTP-, and NFS-Server accessible

```bash
>>> for p in 69 80 111 2049 ; do virsh-instance-port-forward add lxdev01:$p $p ; done
>>> virsh-instance-port-forward list lxdev01
NAT rules:
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:69 to:10.1.1.27:69
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:80 to:10.1.1.27:80
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:111 to:10.1.1.27:111
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:2049 to:10.1.1.27:2049
Forward rules:
ACCEPT     tcp  --  0.0.0.0/0            10.1.1.27            tcp dpt:2049
ACCEPT     tcp  --  0.0.0.0/0            10.1.1.27            tcp dpt:111
ACCEPT     tcp  --  0.0.0.0/0            10.1.1.27            tcp dpt:80
ACCEPT     tcp  --  0.0.0.0/0            10.1.1.27            tcp dpt:69
>>> for p in 69 80 111 2049 ; do virsh-instance-port-forward drop lxdev01:$p $p ; done
```


## Examples

### InfiniBand

Support for Infiniband to the live system:

```bash
>>> cat NFSROOT
PACKAGES install
...
libmlx4-1
>>> fai-make-nfsroot -vk -C $FAI_CONFIG
>>> source $FAI_CONFIG/nfsroot.conf 
>>> mount -t proc proc $NFSROOT/proc && mount -t sysfs sys $NFSROOT/sys && mount -o bind /dev $NFSROOT/dev
>>> chroot $NFSROOT /bin/bash
tail -n +1 /usr/lib/dracut/modules.d/39infiniband/*       
==> /usr/lib/dracut/modules.d/39infiniband/infiniband.sh <==
#!/bin/bash

load_modules()
{
modprobe mlx4_core
modprobe mlx4_ib
modprobe ib_ipoib
modprobe ib_core
modprobe ib_mad
modprobe ib_sa
modprobe ib_addr
modprobe iw_cm
modprobe ib_cm
modprobe rdma_cm
modprobe rdma_ucm
modprobe ib_ucm
modprobe ib_uverbs
modprobe ib_umad
modprobe rdma_cm
modprobe ib_cm
modprobe iw_cm
modprobe ib_sa
modprobe ib_mad
modprobe ipv6
modprobe rds
modprobe ib_srp
modprobe ib_iser
modprobe rdma_cm
modprobe ib_uverbs
modprobe rdma_ucm
}

load_modules

==> /usr/lib/dracut/modules.d/39infiniband/module-setup.sh <==
#!/bin/bash

check() {
    return 0 # Include the dracut module in the initramfs.
}

install() {
    inst_hook pre-udev 39 "$moddir/infiniband.sh"
}

installkernel() {
    instmods mlx4_core
    instmods mlx5_ib
    instmods mlx4_ib
    instmods ib_ipoib
    instmods ib_core
    instmods ib_mad
    instmods ib_sa
    instmods ib_addr
    instmods iw_cm
    instmods ib_cm
    instmods rdma_cm
    instmods rdma_ucm
    instmods ib_ucm
    instmods ib_uverbs
    instmods ib_umad
    instmods rdma_cm
    instmods ib_cm
    instmods iw_cm
    instmods ib_sa
    instmods ib_mad
    instmods ipv6
    instmods rds
    instmods ib_srp
    instmods ib_iser
    instmods rdma_cm
    instmods ib_uverbs
    instmods rdma_ucm
    instmods mst_pciconf
    instmods mst_pci
    instmods eth_ipoib
    instmods mlx4_core
    instmods mlx4_en
    instmods mlx5_core
}
>>> dracut --add-drivers 'mlx4_en mlx4_ib mlx5_ib' -v -m nfs -m infiniband -f
>>> lsinitrd /boot/initramfs-3.16.0-4-amd64.img 
>>> exit
>>> umount $NFSROOT/proc $NFSROOT/sys $NFSROOT/dev
>>> cp -v $FAI_CONFIG/nfsroot/boot/{initramfs,vmlinuz}* $FAI_CONFIG/http 
>>> chmod a+r $FAI_CONFIG/http/{initramfs,vmlinuz}*
```

InfiniBand support in the installed system: 

```bash
## List of packages required
>>> cat $FAI_CONFIGDIR/package_config/INFINIBAND
PACKAGES install
libibcommon1
libibmad1
libibumad1
libopensm2
infiniband-diags
ibutils
## Load Infiniband kernel modules during boot
>>> cat $FAI_CONFIGDIR/scripts/INFINIBAND/10-etc_modules
#!/bin/bash
for module in mlx4_core mlx4_ib ib_umad ib_ipoib rdma_ucm; do
    ainsl -a $target/etc/modules "^$module$"
done
```



