#!/bin/bash

####################################################
#
# File: OP5.A_Nova_Ctrl.sh
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
# Part 5.A.1: Install Nova
####################################################

# Config mysql for nova
#---------------------------
echo -e '\033[33mConfig mariadb for nova ...\033[0m'
if [ `mysql -uroot -p$DBPASS -e "show databases;" | grep -c 'nova'` -eq 0  ]; then
  mysql -uroot -p$DBPASS -e "
  create database nova;
  create database nova_api;
  create database nova_cell0;
  grant all privileges on nova_api.* to 'nova'@'localhost' identified by '$NOVA_PASS';
  grant all privileges on nova_api.* to 'nova'@'%' identified by '$NOVA_PASS';
  grant all privileges on nova.* to 'nova'@'localhost' identified by '$NOVA_PASS';
  grant all privileges on nova.* to 'nova'@'%' identified by '$NOVA_PASS';
  grant all privileges on nova_cell0.* to 'nova'@'localhost' identified by '$NOVA_PASS';
  grant all privileges on nova_cell0.* to 'nova'@'%' identified by '$NOVA_PASS';
  show databases;
  "
else
  echo 'Database nova has been created. Ignore ...' 
fi

# Get token as admin
#---------------------------
echo -e '\033[33mGet token as admin  ...\033[0m'
. admin-openrc

# Create User, Role, service, endpoint
#---------------------------
echo -e '\033[33mCreate User, Role, service, endpoint  ...\033[0m'
# -- nova
# openstack user create --domain default --password-prompt nova								# Original
openstack user create --domain default --password=$NOVA_PASS nova
# add nova(User) to admin(Role)
openstack role add --project service --user nova admin
# create nova "Service"
openstack service create --name nova --description "OpenStack Compute" compute
# create endpoint of compute
openstack endpoint create --region RegionOne compute public http://$ctrl_hostname:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://$ctrl_hostname:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://$ctrl_hostname:8774/v2.1/%\(tenant_id\)s
# -- placement
# create placement service user
openstack user create --domain default --password=$PLACEMENT_PASS placement
# add placement(User) to admin(Role)
openstack role add --project service --user placement admin
# create nova "Service"
openstack service create --name placement  --description "Placement API" placement
# create endpoint of placement
openstack endpoint create --region RegionOne placement public http://$ctrl_hostname:8778
openstack endpoint create --region RegionOne placement internal http://$ctrl_hostname:8778
openstack endpoint create --region RegionOne placement admin http://$ctrl_hostname:8778


# Install nova
#---------------------------
echo -e '\033[33mInstall nova  ...\033[0m'
yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy \
  openstack-nova-scheduler openstack-nova-placement-api -y
  
####################################################
# Part 5.A.2: Config Nova
####################################################

# config nova.conf
#---------------------------
cfgfile=/etc/nova/nova.conf
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
mv $cfgfile $cfgbakpath/nova.conf.`date '+%y%m%d.%H%M%S'`
echo "#
[DEFAULT]
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:$RABBIT_PASS@$ctrl_hostname
auth_strategy = keystone
my_ip = $ctrl_gl_ip
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
[api_database]
connection = mysql+pymysql://nova:$NOVA_PASS@$ctrl_hostname/nova_api
[database]
connection = mysql+pymysql://nova:$NOVA_PASS@$ctrl_hostname/nova
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
vncserver_listen = \$my_ip
vncserver_proxyclient_address = \$my_ip
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
[scheduler]
discover_hosts_in_cells_interval = 300
" > $cfgfile

cfgfile=/etc/httpd/conf.d/00-nova-placement-api.conf
cp $cfgfile $cfgbakpath/00-nova-placement-api.conf.`date '+%y%m%d.%H%M%S'`
sed -i '/<Dir/,/<\/Dir/d' $cfgfile 
echo "<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>" >> $cfgfile

# Init nova 
#---------------------------
echo -e '\033[33mInit nova ... ( ignore output info )\033[0m'
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova						
#-- check
nova-manage cell_v2 list_cells


# Start nova
#---------------------------
echo -e '\033[33mStart nova and set to autostart ...\033[0m'
systemctl restart openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl enable openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

####################################################
# Part 5.A.3: Check installation
####################################################

##############################
# Now, turn to node compute.
# Config nova on node compute.
# When done, back to node controller. 
##############################  
  
# get token as admin
#---------------------------
echo -e '\033[33mGet token as admin  ...\033[0m'
. admin-openrc

# confirm nova operation
#---------------------------
openstack hypervisor list
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

# confirm nova operation
#---------------------------
#echo -e '\033[33mConfirm nova operation  ...\033[0m'
#-- service list
openstack compute service list
#-- catalog list
openstack catalog list
#-- image list
openstack image list
#-- Check the cells and placement API 
nova-status upgrade check
