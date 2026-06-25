# LFCS Question Source Map

Topic map for the question bank (all rows below are built; see `BANK_COVERAGE.md` for build status). `distro=rocky` questions run on `lfcs-rocky1`; `multivm=yes` questions run across `node1` + `node2`; `multivm=half` means the topic has both single-node and two-node questions.

| domain | topic | target_count | distro | multivm |
|---|---|---:|---|---|
| Essential Commands | filesystem layout | 3 | ubuntu | no |
| Essential Commands | vim | 3 | ubuntu | no |
| Essential Commands | diff/patch/file | 3 | ubuntu | no |
| Essential Commands | tar/gzip/rsync/dd | 4 | ubuntu | no |
| Essential Commands | bash scripting basic | 4 | ubuntu | no |
| Essential Commands | bash scripting advanced | 3 | ubuntu | no |
| Essential Commands | grep | 4 | ubuntu | no |
| Essential Commands | basic regex | 3 | ubuntu | no |
| Essential Commands | extended regex egrep | 3 | ubuntu | no |
| Essential Commands | compare/manipulate file content | 3 | ubuntu | no |
| Essential Commands | less/more pagers | 2 | ubuntu | no |
| Essential Commands | find deep dive | 4 | ubuntu | no |
| Essential Commands | chmod/chown/chgrp | 4 | ubuntu | no |
| Essential Commands | SUID/SGID/sticky | 3 | ubuntu | no |
| Essential Commands | ACL+chattr | 2 | ubuntu | no |
| Essential Commands | git | 2 | ubuntu | no |
| Operations & Deployment | systemd service files | 5 | ubuntu | no |
| Operations & Deployment | process management | 4 | ubuntu | no |
| Operations & Deployment | logging rsyslog+journald | 4 | ubuntu | no |
| Operations & Deployment | task scheduling cron/at | 4 | ubuntu | no |
| Operations & Deployment | apt repositories | 3 | ubuntu | no |
| Operations & Deployment | dnf/yum repositories | 3 | rocky | no |
| Operations & Deployment | compile from source | 3 | ubuntu | no |
| Operations & Deployment | resource monitoring | 5 | ubuntu | no |
| Operations & Deployment | sysctl | 3 | ubuntu | no |
| Operations & Deployment | SELinux enable/manage | 4 | rocky | no |
| Operations & Deployment | SELinux context mgmt | 4 | rocky | no |
| Operations & Deployment | AppArmor | 3 | ubuntu | no |
| Operations & Deployment | docker | 4 | ubuntu | no |
| Operations & Deployment | KVM/virsh | 3 | ubuntu | no |
| Operations & Deployment | cloud-image VMs | 3 | ubuntu | no |
| Operations & Deployment | SSL/TLS openssl | 3 | ubuntu | no |
| Operations & Deployment | local security | 2 | ubuntu | no |
| Networking | IPv4/IPv6 + hostname resolution | 8 | ubuntu | no |
| Networking | ss/netstat service checks | 5 | ubuntu | no |
| Networking | bridge & bonding | 5 | ubuntu | no |
| Networking | firewall - ufw/nftables | 6 | ubuntu | no |
| Networking | firewall - firewalld | 5 | rocky | no |
| Networking | port redirection & NAT | 6 | ubuntu | yes |
| Networking | reverse proxy & load balancer | 5 | ubuntu | yes |
| Networking | NTP time sync | 5 | ubuntu | yes |
| Networking | SSH server & client | 10 | ubuntu | half |
| Networking | routing | 5 | ubuntu | no |
| Storage | partitioning | 6 | ubuntu | no |
| Storage | swap | 4 | ubuntu | no |
| Storage | create/configure filesystems | 6 | ubuntu | no |
| Storage | fstab boot mounts | 5 | ubuntu | no |
| Storage | mount options | 4 | ubuntu | no |
| Storage | NFS | 6 | ubuntu | yes |
| Storage | NBD | 4 | ubuntu | yes |
| Storage | LVM | 8 | ubuntu | no |
| Storage | storage perf monitoring | 4 | ubuntu | no |
| Storage | RAID/mdadm | 3 | ubuntu | no |
| Users and Groups | local user accounts | 5 | ubuntu | no |
| Users and Groups | groups & memberships | 4 | ubuntu | no |
| Users and Groups | system-wide profiles | 3 | ubuntu | no |
| Users and Groups | skel template env | 3 | ubuntu | no |
| Users and Groups | ulimit resource limits | 3 | ubuntu | no |
| Users and Groups | sudo privileges | 5 | ubuntu | no |
| Users and Groups | root account access | 3 | ubuntu | no |
| Users and Groups | LDAP accounts | 4 | ubuntu | yes |
