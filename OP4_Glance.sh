#!/bin/bash

####################################################
#
# File: OP4_Glance.sh
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
# Part 4 : Only runned at Controller node
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

if [ $nodetype = 'ctrl' ]; then

####################################################
# Part 4.0: Prepare
####################################################

# Load /envconf.rc
#---------------------------
source ./envconf.rc

# Mount cdrom
#---------------------------
echo -e '\033[33mMount cdrom ...\033[0m'
if [[ `mount | grep 'cdrom' | awk -F ' ' '{print $1}'` != /dev/sr0 ]]; then
  mount /dev/sr0 $cdpath
else
  echo 'CDROM has mounted, ignore ...'
fi

####################################################
# Part 4.1: Install Glance
####################################################

# Config mysql for glance
#---------------------------
echo -e '\033[33mConfig mariadb for glance ...\033[0m'
if [ `mysql -uroot -p$DBPASS -e "show databases;" | grep -c 'glance'` -eq 0  ]; then
  mysql -uroot -p$DBPASS -e "
  create database glance;
  grant all privileges on glance.* to 'glance'@'localhost' identified by '$GLANCE_PASS';
  grant all privileges on glance.* to 'glance'@'%' identified by '$GLANCE_PASS';
  show databases;
  "
else
  echo 'Database glance has been created. Ignore ...' 
fi

# Get token as admin
#---------------------------
echo -e '\033[33mGet token as admin  ...\033[0m'
. admin-openrc

# Create User, Role, service, endpoint
#---------------------------
echo -e '\033[33mCreate User, Role, service, endpoint  ...\033[0m'
# openstack user create --domain default --password-prompt glance								# Original
openstack user create --domain default --password=$GLANCE_PASS glance
# add glance(User) to admin(Role)
openstack role add --project service --user glance admin
# create glance "Service"
openstack service create --name glance --description "OpenStack Image" image
# create endpoint of image
openstack endpoint create --region RegionOne image public http://$ctrl_hostname:9292
openstack endpoint create --region RegionOne image internal http://$ctrl_hostname:9292
openstack endpoint create --region RegionOne image admin http://$ctrl_hostname:9292

# Install glance
#---------------------------
echo -e '\033[33mInstall glance ...\033[0m'
if [[ `yum list installed | grep 'openstack-glance' | awk -F ' ' '{print $1}'` != *openstack-glance* ]]; then
  yum install openstack-glance -y
else
  echo 'openstack-glance has installed, ignore ...'
fi

####################################################
# Part 4.2: Config Glance
####################################################

# config glance-api.conf
#---------------------------
cfgfile=/etc/glance/glance-api.conf
echo -e "\033[33mConfig $cfgfile ...\033[0m"
mv $cfgfile $cfgbakpath/glance-api.conf.`date '+%y%m%d.%H%M%S'`
echo "#
[database]
connection = mysql+pymysql://glance:$GLANCE_PASS@$ctrl_hostname/glance
[keystone_authtoken]
auth_uri = http://$ctrl_hostname:5000
auth_url = http://$ctrl_hostname:35357
memcached_servers = $ctrl_hostname:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = $GLANCE_PASS
[paste_deploy]
flavor = keystone
[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
" > $cfgfile

# config glance-registry.conf
#---------------------------
cfgfile=/etc/glance/glance-registry.conf
echo -e "\033[33mConfig $cfgfile  ...\033[0m"
mv $cfgfile $cfgbakpath/glance-registry.conf.`date '+%y%m%d.%H%M%S'`
echo "#
[database]
connection = mysql+pymysql://glance:$GLANCE_PASS@$ctrl_hostname/glance
[keystone_authtoken]
auth_uri = http://$ctrl_hostname:5000
auth_url = http://$ctrl_hostname:35357
memcached_servers = $ctrl_hostname:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = $GLANCE_PASS
[paste_deploy]
flavor = keystone
" > $cfgfile

# Init glance
#---------------------------
echo -e '\033[33mInit glance ... ( ignore output info )\033[0m'
su -s /bin/sh -c "glance-manage db_sync" glance				

# Start glance
#---------------------------
echo -e '\033[33mStart glance and set to autostart ...\033[0m'
systemctl start openstack-glance-api openstack-glance-registry
systemctl enable openstack-glance-api openstack-glance-registry

####################################################
# Part 4.3: Check installation
####################################################

# Get token as admin
#---------------------------
echo -e '\033[33mGet token as admin  ...\033[0m'
. admin-openrc

# Get OS img
#---------------------------
echo -e '\033[33mGet cirrOS img  ...\033[0m'
wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img

# Create image
#---------------------------
echo -e '\033[33mCreate cirrOS img  ...\033[0m'
openstack image create "cirros" \
  --file cirros-0.3.5-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public
  
# confirm glance operation
#---------------------------
echo -e '\033[33mConfirm glance operation  ...\033[0m'
openstack image list

fi

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
####################################################

####################################################
# Part 4.4: Write to OPFlag
####################################################

# OPFlag
#------------------------------
echo -e '\033[33m Write to OPFlag ...\033[0m'
echo '4' > OPFlag
