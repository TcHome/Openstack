#!/bin/bash

####################################################
#
# File: OP5.B_Nova_Comp.sh
# Version: 1.0
# Made by wangdeng (2018-5-14)
# OS: CentOS 7.4 1708
# RunAt: All Location
# Run by: root
# Info:
#   ...
# 
####################################################

####################################################
# Part 5.B.1: Install Nova
####################################################

# Create rdo-qemu-ev.repo
#---------------------------
cfgfile=/etc/yum.repos.d/rdo-qemu-ev.repo
echo -e "\033[33mCreate $cfgfile ...\033[0m"
echo "#
[rdo-qemu-ev]
name=RDO CentOS-\$releasever - QEMU EV
baseurl=http://mirror.centos.org/centos/\$releasever/virt/\$basearch/kvm-common/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization

[rdo-qemu-ev-test]
name=RDO CentOS-\$releasever - QEMU EV Testing
baseurl=http://buildlogs.centos.org/centos/\$releasever/virt/\$basearch/kvm-common/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization
"> $cfgfile
yum clean all && yum makecache

# Install nova
#---------------------------
echo -e '\033[33mInstall nova  ...\033[0m'
yum install openstack-nova-compute -y

####################################################
# Part 5.B.2: Config Nova
####################################################

# Config nova.conf
#---------------------------
cfgfile=/etc/nova/nova.conf
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
mv $cfgfile $cfgbakpath/nova.conf.`date '+%y%m%d.%H%M%S'`
echo "#
[DEFAULT]
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:$RABBITMQ_PASS@$ctrl_hostname
auth_strategy = keystone
my_ip = $comp_gl_ip
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
[keystone_authtoken]
auth_uri = http://$ctrl_hostname:5000
auth_url = http://$ctrl_hostname:35357
memcached_servers = $ctrl_hostname:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = $NOVA_PASS
[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = \$my_ip
novncproxy_base_url = http://$ctrl_hostname:6080/vnc_auto.html
[glance]
api_servers = http://$ctrl_hostname:9292
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[placement]
os_region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://$ctrl_hostname:35357/v3
username = placement
password = $PLACEMENT_PASS
" > $cfgfile

#-----------------------------------
# get vmx info
# should not be 0 !! 
# Otherwise, In vmware vSphere, modify the .vmx file, add two lines below
# vpmc.enable = "TRUE"
# vhv.enable = "TRUE"
#-----------------------------------
echo -e '\033[33mCheck vmx,svm status  ...\033[0m'
if [ `egrep -c '(vmx|svm)' /proc/cpuinfo` -eq '0' ]; then
  echo 'vmx or svm is nessesary !'
fi

####################################################
# Part 5.B.3: Start Nova-compute
####################################################

# Start nova-compute
#---------------------------
echo -e '\033[33mStart libvirtd, nova and set to autostart ...\033[0m'
systemctl start libvirtd openstack-nova-compute
systemctl enable libvirtd openstack-nova-compute
