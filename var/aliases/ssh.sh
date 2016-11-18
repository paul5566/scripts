#
# Copyright 2013-2015 Victor Penso
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

# Use archive mode by default
alias rsync='rsync -avzrtp'

# Remote login as root
alias ssh-root='ssh -l root'

# less secure but faster
alias ssh-fast-encrypt='ssh -C4c arcfour,blowfish-cbc'

# Agent forwarding
alias ssh-agent-forward='ssh -A'

# quick export NODES environment variable
function NODE() {
  if [ $# -lt 1 ]
  then
    : ${NODE:?}
    echo $NODE
  else
    export NODE=$@
  fi
}


#
# Remote login shell for command execution
#
function ssh-zsh-command() {
  # if NODE environment variable is not set
  if [[ -z ${NODE+x} ]]; then
    NODE=${1:?error: Provide remote login [<user>@]<host>}
    shift
  fi
  # User needs to provide command to be executed on remote node
  if [[ $# -eq 0 ]]; then
    echo "error: Provide command to be executed on $target!"
  else
    # argument list to be executed as command
    cmd=${@//\'/\'\\\'\'} # escape single quotes
    # login to remote node, start an interactive shell and execute command 
    ssh $NODE "zsh -i -c '$cmd'"
    # do not use pseudo-ttys above
  fi
}
alias szc=ssh-zsh-command

# Spy on the SSH traffic
alias ssh-snoop='tcpdump -lnn -i any port ssh and tcp-syn'

# Compression by default for remote mounts
alias sshfs='sshfs -C'

# Omit checking of target host key
alias ssh-no-checks='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
alias scp-no-checks='scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

# Generate key-pairs, use `-f <PATH>` to provide the location
alias ssh-keygen-ecdsa="ssh-keygen -t ecdsa -b 521 "
alias ssh-keygen-rsa='ssh-keygen -t rsa -b 4096'
alias ssh-keygen-no-password="ssh-keygen -q -t rsa -b 2048 -N ''"

# Launch SSH proxy
function shuttle() { sshuttle -r --dns $1 0/0 }

alias ssh-sync='noglob ssh-sync'


