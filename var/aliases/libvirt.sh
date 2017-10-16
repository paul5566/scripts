#
# Copyright 2013-2016 Victor Penso
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

export LIBVIRT_DEFAULT_URI=qemu:///system
export VM_IMAGE_PATH=/srv/vms/images
export VM_INSTANCE_PATH=/srv/vms/instances
export VM_DOMAIN=devops.test

##
# Wraps the `virsh` command
#
function vm() {
  # list VMs by default
  local command=${1:-list}
  # remove first argument if present
  [[ $# -ge 1 ]] && shift
  case "$command" in
  "cd")              cd $VM_INSTANCE_PATH/$1.$VM_DOMAIN ;;
  "clone"|"cl")      virsh-instance clone $@ ;;
  "config"|"cf")     virsh-config $@ ;;
  "create"|"c")      virsh create $@ ;;
  "define"|"d")      virsh define $@ ;;
  "exec"|"ex")       virsh-instance exec $@ ;;
  "image"|"i")       virsh-instance list ;;
  "kill"|"k")        virsh undefine "$1" ; virsh destroy "$1" ;;
  "list"|"l")        virsh list --all ;;
  "login"|"lo")      virsh-instance login $@ ;;
  "nat"|"n")         virsh-nat-bridge $@ ;;
  "path"|"p")        virsh-instance path $@ ;;
  "remove"|"r")      virsh-instance remove $@ ;;
  "shutdown"|"h")    virsh shutdown "$1" ;;
  "shadow"|"sh")     virsh-instance shadow $@ ;;
  "start"|"s")       virsh start $1 ;;
  "sync"|"sy")       virsh-instance sync $@ ;;
  "undefine"|"u")    virsh undefine $@ ;;
  *) 
    echo "Usage: vm cd|(c)reate|(d)efine|s(h)utdown|(k)ill|(l)ist|(r)emove|(s)tart|(u)ndefine [args]" 
    ;;
  esac
}

##
# Operate on a nodeset of virtual machines
#
function virsh-nodeset() {
  local command=$1
  case $command in
    "command"|"cmd"|"c")
      shift
      for node in $(nodeset -e $NODES)
      do
        echo $node
        cd $(virsh-instance path $node)
        $@
        cd - >/dev/null
      done
    ;;
    "execute"|"exec"|"ex"|"e")
      shift
      local args=$@
      nodeset-loop -s virsh-instance exec {} "'$args'"
      ;;
    "shadow"|"sh"|"s")
      img=${2:-centos7}
      nodeset-loop virsh-instance shadow $img {}
      ;;
    "remove"|"rm"|"r")
      nodeset-loop virsh-instance remove {}
      ;;
    *)
      echo "Usage: virsh-nodeset (c)ommand|(e)xecute|(s)hadow|(r)emove [args]"
      ;;
  esac
}



