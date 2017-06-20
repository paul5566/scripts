

Dummy deployment for a [chef-server](https://downloads.chef.io/chef-server) package:

→ [Install the Chef Server](https://docs.chef.io/install_server.html), official documentation from [docs.chef.io](http://docs.chef.io)

```bash
wget https://packages.chef.io/files/stable/chef-server/12.15.7/el/7/chef-server-core-12.15.7-1.el7.x86_64.rpm
yum -y install chef-server-core-12.15.7-1.el7.x86_64.rpm
chef-server-ctl reconfigure
su devops -c 'mkdir ~/.chef'
chef-server-ctl user-create devops dev ops dops@devops.test 'devops' --filename /home/devops/.chef/devops.pem
chef-server-ctl org-create devops 'devops people' --association_user devops --filename /etc/chef/devops.pem
```

## Knife

Configure [Knife](https://docs.chef.io/knife.html) for the devops user:

```bash
>>> cat .chef/knife.rb
log_level                :info
log_location             STDOUT
node_name                "#{ENV['USER']}"
client_key               "~/.chef/#{ENV['USER']}.pem"
chef_server_url          'https://lxrm01.devops.test/organizations/devops'
ssl_verify_mode          :verify_none
cache_type               'BasicFile'
cache_options( :path => "~/.chef/checksums" )
cookbook_path            ["~/chef/cookbooks"]
```

```bash
## Create a new client for a node and store its private key to /tmp
knife client create -d $fqdn 2>/dev/null >/tmp/${fqdn}.pem
## Copy the private key to the target node
scp /tmp/${fqdn}.pem root@${fqdn}:/etc/chef/client.pem
```

## Client

Official documentation from [docs.chef.io](http://docs.chef.io):

→ [chef-client](https://docs.chef.io/ctl_chef_client.html)  
→ [client.rb](https://docs.chef.io/config_rb_client.html)

Chef-client configuration file example:

```bash
>>> cat /etc/chef/client.rb
node_name              "#{`hostname -f`.strip}"
chef_server_url        'https://lxrm01.devops.test/organizations/devops'
client_key             '/etc/chef/client.pem'
ssl_verify_mode        :verify_none
validation_client_name 'devops-validator'
validation_key         '/etc/chef/devops.pem'
log_level              :fatal
log_location           STDOUT
file_backup_path       '/var/backups/chef'
file_cache_path        '/var/cache/chef'
>>> chef-client -c /etc/chef/client.rb # test if the configuration is working
```

Systemd configuration to execute the chef-client periodically:

```bash
## Service unit file
>>> cat /etc/systemd/system/chef-client.service
[Unit]
Description=Chef Client daemon
After=network.target auditd.service

[Service]
Type=oneshot
ExecStart=/opt/chef/embedded/bin/ruby /usr/bin/chef-client -c /etc/chef/client.rb -L /var/log/chef-client.log
ExecReload=/bin/kill -HUP $MAINPID
SuccessExitStatus=3

[Install]
WantedBy=multi-user.target
## Timer unit file
>>> cat /etc/systemd/system/chef-client.timer
[Unit]
Description=Chef Client periodic execution

[Install]
WantedBy=timers.target

[Timer]
OnBootSec=1min
OnUnitActiveSec=1800sec
AccuracySec=300sec
## Enable periodic execution 
>>> systemctl start chef-client.timer && systemctl enable chef-client.timer
```

Alternatively use the Chef base cookbook with the [chef_client.rb](https://github.com/vpenso/chef-base/blob/master/test/roles/chef_client.rb) role.

