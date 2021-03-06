↴ [var/aliases/kernel.sh](../var/aliases/kernel.sh)  

Download the latest Linux from  [www.kernel.org](https://www.kernel.org/)


```bash
>>> apt -y install libncurses5-dev gcc make git exuberant-ctags bc libssl-dev
## Build in a scratch location, i.e. /tmp
>>> version=4.11.7
>>> wget -qO- https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${version}.tar.xz | tar -xvJ
>>> cd linux-${version}
## Configure and build the kernel
>>> make x86_64_defconfig                                   # x86_64 configuration 
>>> make kvmconfig                                          # enable KVM support
# directory to store the build products
>>> kernel=${KERNEL}/${version} && echo $kernel && mkdir $kernel 
>>> log=${kernel}/build.log && echo $log
>>> make -j8 2>&1 | tee -a $log
# save kernel and its configuration
>>> cp -v arch/x86/boot/bzImage $kernel/linux && cp -v .config ${kernel}/linux.config
make modules 2>&1 | tee $log                            # compiles modules
mkdir ${kernel}/modules
# installs kernel modules
make modules_install INSTALL_MOD_PATH=${kernel}/modules 2>&1 >> tee -a $log
>>> ls -1 $kernel
build.log
linux
linux.config
modules/
```

## Modules

```bash
lsmod                                         # show loaded modules
modinfo <name>                                # information about a module
systool -v -m <name>                          # list the options that are set for a loaded module
modprobe -c | less                            # comprehensive configuration of all the modules
modprobe --show-depends <name>                # list dependencies of a module
modprobe <name>                               # load a module
insmod <path> <args>                          # load a module from a file
modprobe -r <name>                            # unload module
rmmod <name>                                  # ^^
/etc/modules                                  # list of modules to load at boot
/etc/modules-load.d/*.conf                    # ^^
/etc/modprobe.d/*.conf                        # module parameter configuration
/lib/modules/$(uname -r)/                     # module and configuration for a given kernel
# list all available kernel modules
find /lib/modules/$(uname -r) -type f -name \*.ko

```
