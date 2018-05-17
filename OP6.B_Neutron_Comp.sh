#!/bin/bash

####################################################
#
# File: OP6.B_Neutron_Comp.sh
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
# Part 6.B.1: Install Neutron
####################################################


# Install openstack-neutron
#---------------------------
echo -e '\033[33mInstall neutron  ...\033[0m'
yum install openstack-neutron-linuxbridge ebtables ipset -y
  
####################################################
# Part 6.B.2: Config Neutron
####################################################

# config neutron.conf
#---------------------------
cfgfile=/etc/neutron/neutron.conf
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
mv $cfgfile $cfgbakpath/neutron.conf.`date '+%y%m%d.%H%M%S'`
echo "#
[DEFAULT]
transport_url = rabbit://openstack:$RABBITMQ_PASS@$ctrl_hostname
auth_strategy = keystone
[keystone_authtoken]
auth_uri = http://$ctrl_hostname:5000
auth_url = http://$ctrl_hostname:35357
memcached_servers = $ctrl_hostname:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = $NEUTRON_PASS
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
" > $cfgfile

# config linuxbridge_agent.ini
#---------------------------
cfgfile=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
mv $cfgfile $cfgbakpath/linuxbridge_agent.ini.`date '+%y%m%d.%H%M%S'`
echo "#
[linux_bridge]
physical_interface_mappings = provider:$netcard1
[vxlan]
enable_vxlan = True
local_ip = $comp_gl_ip
l2_population = True
[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
" > $cfgfile

# config nova.conf
#---------------------------
cfgfile=/etc/nova/nova.conf
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
cp $cfgfile $cfgbakpath/nova.conf.`date '+%y%m%d.%H%M%S'`
sed -i '/\[neutron]/,+11d' $cfgfile
echo "[neutron]
url = http://$ctrl_hostname:9696
auth_url = http://$ctrl_hostname:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = $NEUTRON_PASS
" >> $cfgfile

# Start neutron
#---------------------------
#-- openstack-nova-compute
echo -e '\033[33mRestart openstack-nova-compute ...\033[0m'  
systemctl restart openstack-nova-compute.service  
#-- neutron-linuxbridge-agent
echo -e '\033[33mStart linuxbrdge-agent and set to autostart ...\033[0m'  
systemctl start neutron-linuxbridge-agent.service
systemctl enable neutron-linuxbridge-agent.service
