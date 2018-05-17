#!/bin/bash

####################################################
#
# File: OP6.A_Neutron_Ctrl.sh
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
# Part 6.A.1: Install Neutron
####################################################

# Config mysql for neutron
#---------------------------
echo -e '\033[33mConfig mariadb for neutron ...\033[0m'
if [ `mysql -uroot -p$DBPASS -e "show databases;" | grep -c 'neutron'` -eq 0  ]; then
  mysql -uroot -p$DBPASS -e "
  create database neutron;
  grant all privileges on neutron.* to 'neutron'@'localhost' identified by '$NEUTRON_PASS';
  grant all privileges on neutron.* to 'neutron'@'%' identified by '$NEUTRON_PASS';
  show databases;
  "
else
  echo 'Database neutron has been created. Ignore ...' 
fi

# Get token as admin
#---------------------------
echo -e '\033[33mGet token as admin  ...\033[0m'
. admin-openrc

# Create User, Role, service, endpoint
#---------------------------
echo -e '\033[33mCreate User, Role, service, endpoint  ...\033[0m'
# openstack user create --domain default --password-prompt neutron								# Original
openstack user create --domain default --password=$NEUTRON_PASS neutron
# add nova(User) to admin(Role)
openstack role add --project service --user neutron admin
# create neutron "Service"
openstack service create --name neutron --description "OpenStack Networking" network
# create endpoint of network
openstack endpoint create --region RegionOne network public http://$ctrl_hostname:9696
openstack endpoint create --region RegionOne network internal http://$ctrl_hostname:9696
openstack endpoint create --region RegionOne network admin http://$ctrl_hostname:9696

# Model II:  Selfservice
#----------------------------

# Install openstack-neutron
#---------------------------
echo -e '\033[33mInstall neutron  ...\033[0m'
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables -y
  
####################################################
# Part 6.A.2: Config Nova
####################################################

# config neutron.conf
#---------------------------
cfgfile=/etc/neutron/neutron.conf
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
mv $cfgfile $cfgbakpath/neutron.conf.`date '+%y%m%d.%H%M%S'`
echo "#
[DEFAULT]
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
transport_url = rabbit://openstack:$RABBITMQ_PASS@$ctrl_hostname
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
[database]
connection = mysql+pymysql://neutron:$NEUTRON_PASS@$ctrl_hostname/neutron
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
[nova]
auth_url = http://$ctrl_hostname:35357
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = nova
password = $NOVA_PASS
" > $cfgfile

# config ml2_conf.ini
#---------------------------
cfgfile=/etc/neutron/plugins/ml2/ml2_conf.ini
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
mv $cfgfile $cfgbakpath/ml2_conf.ini.`date '+%y%m%d.%H%M%S'`
echo "#
[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = linuxbridge,l2population
extension_drivers = port_security
[ml2_type_flat]
flat_networks = provider
[ml2_type_vxlan]
vni_ranges = 1:1000
[securitygroup]
enable_ipset = True
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
local_ip = $ctrl_gl_ip
l2_population = True
[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
" > $cfgfile

# config l3_agent.ini
#---------------------------
cfgfile=/etc/neutron/l3_agent.ini
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
mv $cfgfile $cfgbakpath/l3_agent.ini.`date '+%y%m%d.%H%M%S'`
echo "#
[DEFAULT]
interface_driver = linuxbridge
" > $cfgfile
#interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver  ( Ver: N )

# config dhcp_agent.ini
#---------------------------
cfgfile=/etc/neutron/dhcp_agent.ini
mv $cfgfile $cfgbakpath/dhcp_agent.ini.`date '+%y%m%d.%H%M%S'`
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
echo "#
[DEFAULT]
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True
" > $cfgfile
#interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver  ( Ver: N)

# config metadata_agent.ini
#---------------------------
cfgfile=/etc/neutron/metadata_agent.ini
mv $cfgfile $cfgbakpath/metadata_agent.ini.`date '+%y%m%d.%H%M%S'`
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
echo "#
[DEFAULT]
nova_metadata_ip = $ctrl_hostname
metadata_proxy_shared_secret = METADATA_SECRET
" > $cfgfile

# config nova.conf
#---------------------------
cfgfile=/etc/nova/nova.conf
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
cp $cfgfile $cfgbakpath/nova.conf.`date '+%y%m%d.%H%M%S'`
sed -i '/\[neutron]/,+13d' $cfgfile
echo "[neutron]
url = http://$ctrl_hostname:9696
auth_url = http://$ctrl_hostname:35357
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = neutron
password = $NEUTRON_PASS
service_metadata_proxy = True
metadata_proxy_shared_secret = METADATA_SECRET
" >> $cfgfile

# Init neutron
#---------------------------
echo -e '\033[33mInit neutron  ...\033[0m'
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
echo -e '\033[33mRestart nova-api  ...\033[0m' 

# Start neutron
#---------------------------
#-- openstack-nova-api
echo -e '\033[33mRestart openstack-nova-api ...\033[0m'  
systemctl restart openstack-nova-api.service  
#-- neutron-server, neutron-linuxbridge-agent, neutron-dhcp-agent, neutron-metadata-agent
echo -e '\033[33mStart neutron, linuxbrdge-agent, dhcp-agent, metadata-agent and set to autostart ...\033[0m'  
systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
#-- eutron-l3-agent
echo -e '\033[33mStart l3-agent and set to autostart ...\033[0m'  
systemctl start neutron-l3-agent.service  
systemctl enable neutron-l3-agent.service


####################################################
# Part 6.A.3: Check installation
####################################################

# get token as admin
#---------------------------
echo -e '\033[33mGet token as admin  ...\033[0m'
. admin-openrc

# confirm neutron operation
#---------------------------
echo -e '\033[33mConfirm neutron operation  ...\033[0m'
# neutron ext-list  ( Ver: N )
# openstack network agent list  ( Ver: N )
openstack extension list --network

# neutron proxy
#---------------------------
openstack network agent list
