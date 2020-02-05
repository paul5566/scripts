
Cf.:

* [Documentation](http://docs.ansible.com/)
* [Configuration File](http://docs.ansible.com/ansible/intro_configuration.html)
* [Configuration Settings](http://docs.ansible.com/ansible/latest/installation_guide/_config.html)
* [Directory Layout](http://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#directory-layout)

```bash
/etc/ansible/ansible.cfg                             # global config
./.ansible.cfg                                       # in path config
~/.ansible.cfg                                       # user config
ANSIBLE_CONFIG=<file>
/etc/ansible/hosts/                                  # inventory files
/etc/ansible/host_vars/<host>*.{yaml|yml|json}
/etc/ansible/group_vars/<group>*.{yaml|yml|json}
/etc/ansible/group_vars/<group>/*.{yaml|yml|json}
ANSIBLE_HOSTS=<file>
```

The **inventory** defines nodes, groups of nodes including connection information and node related variables. This information is stored to plain text files eventually structured within a directory tree:

```
[<group>]                                      # group definition
<fqdn>                                         # nodes...
<host>[x:y]<domain>                            # range, e.g. 01:50 (numeric) a:f (alphabetic)
<fqdn>:<port>
<host> ansible_port=<port> ansible_host=<ip> ansible_user=<name>
<host> var=val ...                             # host variables
[<group>:vars]                                 # group variables
var=val
...
[<group>:children]                             # groups of groups
<group>
...
```

Execute a command on a selected group of hosts:

```bash
ansible -a <command> <group>                         # run command on host group
ansible -i <file> ... <group> ...                    # use inventory containing group
ansible -o ...                                       # output one line per host
ansible -t <path> ...                                # store output as JSON file per host
ansible ... <group> -l ~<pattern>                    # subset of group by pattern
```

## Modules

Modules provide the configuration capabilities. Core modules are part of Ansible, e.g. "apt"

* connection modules
* lookup modules - data access
* filter modules - transform data
* callback modules - register events during task execution
* task modules
  - self contained scripts (language agnostic)
  - copied to target machine (JSON input and output)

```bash
ansible-doc -l                                       # list all modules
ansible-doc <module>                                 # print module docs
ansible -m <module> -a <command> ...                 # execute module
```

```bash
-a "<command>"                                    # execute remote command
-m shell -a "<command> chdir=<path> executable=/bin/bash"
-m copy -a "src=<path> dest=<path>"               # copy files to hosts
-m fetch -a "src=<path> dest=./fetched"           # copy files from hosts
-m fetch -a "src=<path> dest=/tmp/<prefix>-{{inventory_hostname}} flat=yes"
-m file -a "dest=<path> state=absent"             # remove a file
-m file -a "dest=<path> mode=<mode> owner=<user> group=<group>"
                                                  # change owner, group, permissions
-m replace -a "dest=<path> regexp=<regex> backup=yes"
                                                  # alter file content with a regex
-m synchronize -a "src=<path> dest=<path>"        # rsync path to hosts
-m get_url -a "url=<url> dest=<path> mode=<mode>" # download a file
-m service -a "name=<service> state=<state>"
                  # change service state:  running,started,stopped,restarted,reloaded
-m apt -a "update_cache=yes upgrade=yes"          # upgrade packages
-m apt -a "name=<pkg> state=<state>"
-m apt -a "name=<pkg> state=present install_recommends=yes"
-m apt -a "name=<pkg> state=absent purge=yes"
```

## Playbooks

Playbooks orchestrate configuration **tasks** and are written in YAML:

- Tasks are executed in order, one at a time, against machines matching a **host pattern**.
- Tasks execute a module with specific arguments. Idempotents allows repeated execution.
- **Notify** is triggered at the end of each task for each defined handler.
- **Handlers** are lists of tasks executed by notifiers.


```bash
ansible-playbook <playbook>                       # execute playbook 
ansible-pull -U <url> <playbook>                  # checkout repsotiory URL, execute playbook
```

```yaml
---
- host <pattern>                                  # groups or host patterns, separated by colons
  remote_user: <user>                             # name of the user account
  <key>: <value>                                  
  […]
  tasks:                                          # list of tasks
    - name: <comment>                             # task description
      <module>: [<options>]                       # module to call
        <key>: <value>                            # configuration for the module
        […]
      notify:                                     # actions triggered on change
      - <key>: <value>                            # list of handlers
      […]
    […]
  handlers:                                       # handler task list
    - name: <comment>
      service:
        <key>: <value
```

**Roles** organize playbooks in a defined directory structure.


