# OpenSSH Host Certificates

Host certificates can be used as alternative to host public key authentication.

Hosts send signed SSH certificate to clients in order to enable the
**verification of the host's identity**. 

* The host certificate is signed by a trusted Certificate Authority (CA)
* The host certificate includes host name (principle) and expiration date
* Clients check if a trusted CA (listed in `known_hosts`) has signed the
  host certificate (using the CA public key)
* Clients don't store public keys for every host connection. Only the public
  keys of trusted certificate authorities.
* Either a signature check failed or if the CA is not trusted emits a warning 

**Generate a CA public key-pair** to sign host keys with `ssh-keygen`:

* Option `-f` defines the name of the (output) private key file (the public key
  gets `.pub` appended) 
* Option `-C` provides a comment to identify the CA key-pair

```bash
ssh-keygen -f devops-host_ca-$(mktemp -u XXXXXX) -C "Host signing key for DevOps"
```

Best practice is to have multiple sets of CA keys with different expiration
dates. This allows to revoke a key if required, while maintaining access to the
infrastructure. Generally it is useful to follow a naming convention like:

```bash
<organisation>-<key_type>-<unique_id>
# the example above, would create a public and private key like
devops-host_ca-Gb3t8s
devops-host_ca-Gb3t8s.pub

```

## Host Key Signing

Use the CA key-pair to **sign the host public key** using the `ssh-keygen`
command:

* Option `-h` creates a host certificate instead of a user certificate
* Option `-s` specifies a path to a **CA private key file**
* Option `-V` specifies a **validity interval** when signing a certificate
* Option `-n` specifies one or more **principals** (host names)
* Option `-I` specifies an identification string used in log output

```bash
# SSH client connection configuration
cat > ssh_config <<EOF
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
EOF
# download the public host key from a node
scp -F ssh_config root@lxdev01:/etc/ssh/ssh_host_rsa_key.pub .
# sign the host key with the CA signing key
ssh-keygen -h -s devops-host_ca-Gb3t8s \
           -V -1d:+52w \
           -n lxdev01,lxdev01.devops.test \
           -I 'lxdev01.devops.test host certificate' \
    ssh_host_rsa_key.pub
# upload the host certificate to the node
scp -F ssh_config ssh_host_rsa_key-cert.pub root@lxdev01:/etc/ssh
```

_The example above is just for illustration purpose, and not the recommended way
of distributing host certificates_

Inspect the host certificate:

```bash
>>> ssh-keygen -L -f ssh_host_rsa_key-cert.pub
ssh_host_rsa_key-cert.pub:
        Type: ssh-rsa-cert-v01@openssh.com host certificate
        Public key: RSA-CERT SHA256:iVBchuhVcTKvUA4XZb5ldnP2FMgiDKcqaIsWCq9ChIQ
        Signing CA: RSA SHA256:zTEUXG8CJ0j9l7s8wt1couYyHD+u8gFjpawbsNmxoFk
        Key ID: "lxdev01.devops.test host certificate"
        Serial: 0
        Valid: from 2020-01-23T11:26:51 to 2021-01-22T11:26:51
        Principals:
                lxdev01.devops.test
        Critical Options: (none)
        Extensions: (none)
```

## Host Configuration

**Enable a host certificate** in the `sshd` server configuration:

```bash
ssh -F ssh_config root@lxdev01 -C '
        echo "HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub" \
                >> /etc/ssh/sshd_config
        sudo systemctl restart sshd
'
# restart sshd to enable the configuration change
```

`HostCertificate` specifies a file containing a public host certificate. 
The certificate's public key must match a private host key already specified 
by `HostKey`.

## Client Configuration

The client use the certificate to verify the node integrity with the CA public
key. Therefore **add the CA public key to known hosts file**:

```bash
cat <<EOF | tee ssh_config
UserKnownHostsFile=ssh_known_hosts
EOF
cat <<EOF | tee -a ssh_known_hosts
@cert-authority * $(cat devops-host_ca-Gb3t8s.pub)
EOF
# connect using the known hosts file
ssh -vvv -F ssh_config root@lxdev01
```

The marker `@cert-authority` indicate that the line contains a certification 
authority (CA) key.

```bash
Server host certificate: ... serial 0 ID "lxdev01.devops.test host certificate" ...
Server host certificate hostname: lxdev01.devops.test
hostkeys_foreach: reading file "ssh_known_hosts"
record_hostkey: found ca key type RSA in file ssh_known_hosts:1
load_hostkeys: loaded 1 keys from lxdev01
Host 'lxdev01' is known and matches the RSA-CERT host certificate.
Found CA key in ssh_known_hosts:1
Certificate invalid: name is not a listed principal
```

