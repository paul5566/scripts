Simple **HTTP server** setup:

```bash
yum -y install httpd
rm /etc/httpd/conf.d/welcome.conf
systemctl enable --now httpd
```

Grant access to the HTTP port, or disable the firewall 

```bash
firewall-cmd --permanent --add-service=http && firewall-cmd --reload
systemctl stop firewalld && systemctl disable firewalld
```

Disable SELinux

```bash
>>> grep ^SELINUX= /etc/selinux/config
SELINUX=disabled
>>> setenforce 0 && sestatus
```

# Yum Repository

Utilities to install:

* `reposync` - used to synchronize remote yum repositories to a 
  local directory, using yum to retrieve the packages
* `createrepo` - Create repomd (xml-rpm-metadata) repository

```bash
yum -y install yum-utils createrepo
```

Synchronize CentOS YUM repositories to the local directories

```bash
mkdir -p /var/www/html/centos/{base,updates}
reposync --downloadcomps \
         --plugins \
         --gpgcheck \
         --download-metadata \
         --repoid=base \
         --repoid=updates \
         --download_path=/var/www/html/centos
# create a new repodata for the local repositories
for repo in base updates
do
        createrepo --verbose\
                   --update \
                   --groupfile comps.xml \
                   /var/www/html/centos/$repo 
done
```

Periodic Updates using Systemd units:

```bash
>>> cat /etc/systemd/system/reposync.service
[Unit]
Description=Mirror package repository

[Service]
ExecStart=/usr/bin/reposync -gml --download-metadata -r base -p /var/www/html/centos/7/os/x86_64/
ExecStartPost=/usr/bin/createrepo -v --update /var/www/html/centos/7/os/x86_64/base -g comps.xml
Type=oneshot
>>> cat /etc/systemd/system/reposync.timer 
[Unit]
Description=Periodically execute package mirror sync

[Timer]
OnStartupSec=300s
OnUnitInactiveSec=2h

[Install]
WantedBy=multi-user.target
>>> systemctl start reposync.timer
``` 

# Full Mirror Sync

Full mirror (of a file-system) including ISO images and network install:

```bash
mkdir /var/www/html/centos
rsync --verbose \
      --archive \
      --compress \
      --delete \
      rsync://linuxsoft.cern.ch/centos \
      /var/www/html/centos
```

Note: You can use any CentOS mirror [1] with an `rsync://` endpoint.

Create a systemd service unit [2] to execute `rsync`:

```bash
# write a unit file to execute rsync
cat > /etc/systemd/system/rsync-centos-mirror.service <<EOF
[Unit]
Description=Rsync CentOS Mirror

[Service]
ExecStartPre=-/usr/bin/mkdir -p /var/www/html/centos
ExecStart=/usr/bin/rsync -avz --delete rsync://linuxsoft.cern.ch/centos /var/www/html/centos
Type=oneshot
EOF
# load the configuration
systemctl daemon-reload
# start rsync
systemctl start rsync-centos-mirror
# follow the rsync log...
journalctl -f -u rsync-centos-mirror
```

Use a systemd timer unit to periodically execute the service above:

```bash
cat > /etc/systemd/system/rsync-centos-mirror.timer <<EOF
[Unit]
Description=Periodically Rsync CentOS Mirror

[Timer]
OnStartupSec=300s
OnUnitInactiveSec=2h

[Install]
WantedBy=multi-user.target
EOF
# enable and start the timer unit
systemctl daemon-reload
systemctl enable --now rsync-centos-mirror.timer
# check the date for next activation
systemctl list-timers rsync*
```


## Custom Repository

Create a local repository to host RPM packages:

```bash
>>> yum -y install yum-utils createrepo                       # install the tools
>>> path=/var/www/html/repo                                   # directory holding the repository
>>> mkdir -p $path && createrepo $path                        # intialize the package repository
## move RPM packages into $path
>>> createrepo --update $path                                 # update once packages have been added
```

# Reference

[1] List of CentOS Mirrors  
<https://www.centos.org/download/mirrors/>

[2] Systemd Service Unit  
<https://www.freedesktop.org/software/systemd/man/systemd.service.html>

[3] Systemd Timer Unit  
<https://www.freedesktop.org/software/systemd/man/systemd.timer.html>