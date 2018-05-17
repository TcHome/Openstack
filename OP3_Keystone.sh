#!/bin/bash

####################################################
#
# File: OP3_Keystone.sh
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
# Part 3 : Only runned at Controller node
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

if [ $nodetype = 'ctrl' ]; then

####################################################
# Part 3.0: Prepare
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
# Part 3.1: Install Keystone
####################################################

# Config mysql for keystone
#---------------------------
echo -e '\033[33mConfig mariadb for keystone...\033[0m'
if [ `mysql -uroot -p$DBPASS -e "show databases;" | grep -c 'keystone'` -eq 0  ]; then
  mysql -uroot -p$DBPASS -e "
  create database keystone;
  grant all privileges on keystone.* to 'keystone'@'localhost' identified by '$KEYSTONE_PASS';
  grant all privileges on keystone.* to 'keystone'@'%' identified by '$KEYSTONE_PASS';
  show databases;
  "
else
  echo 'Database Keystone has been created. Ignore ...' 
fi

# Install keystone
#---------------------------
echo -e '\033[33mInstall keystone ...\033[0m'
if [[ `yum list installed | grep 'openstack-keystone' | awk -F ' ' '{print $1}'` != *openstack-keystone* ]]; then
  yum install openstack-keystone httpd mod_wsgi openstack-utils -y
else
  echo 'openstack-keystone has installed, ignore ...'
fi

####################################################
# Part 3.2: Config Keystone
####################################################

# Config keystone.conf
#---------------------------
cfgfile=/etc/keystone/keystone.conf
echo -e "\033[33mConfig $cfgfile ...\033[0m"
if [ -f $cfgfile ]; then
  mv $cfgfile $cfgbakpath/keystone.conf.`date '+%y%m%d.%H%M%S'`
fi
echo "#
[database]
connection = mysql+pymysql://keystone:$KEYSTONE_PASS@$ctrl_hostname/keystone
[token]
provider = fernet
" > $cfgfile

# Init keystone
#---------------------------
echo -e '\033[33mInit keystone...\033[0m'
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password $KEYSTONE_PASS \
  --bootstrap-admin-url http://$ctrl_hostname:35357/v3/ \
  --bootstrap-internal-url http://$ctrl_hostname:35357/v3/ \
  --bootstrap-public-url http://$ctrl_hostname:5000/v3/ \
  --bootstrap-region-id RegionOne  
  
# Config httpd.conf
#---------------------------
cfgfile=/etc/httpd/conf/httpd.conf
echo -e "\033[33mConfig $cfgfile ...\033[0m"
if [ -f $cfgfile ]; then
  cp $cfgfile $cfgbakpath/httpd.conf.`date '+%y%m%d.%H%M%S'`
fi
sed -i "/#ServerName .*/c ServerName $ctrl_hostname" $cfgfile
ln -sf /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

# Start httpd.conf
#---------------------------
echo -e '\033[33mStart httpd and set to autostart ...\033[0m'
systemctl start httpd
systemctl enable httpd

####################################################
# Part 3.3: Create keyston Enviorment
####################################################

# Set admin env
#---------------------------
echo -e '\033[33mSet some enviroment variable for next operation  ...\033[0m'
export OS_USERNAME=admin
export OS_PASSWORD=$password
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$ctrl_hostname:35357/v3
export OS_IDENTITY_API_VERSION=3

# Create Project, User, Role
#---------------------------
echo -e '\033[33mCreate Project, User, Role  ...\033[0m'
# create "Service Project"
openstack project create --domain default --description "Service Project" service
# create "Demo Project"
openstack project create --domain default --description "Demo Project" demo
# create demo as "User"
#openstack user create --domain default --password=-prompt demo									# Original
openstack user create --domain default --password=$password demo
# create user as "Role"
openstack role create user
# Add demo(User) to user(Role)
openstack role add --project demo --user demo user

# Close temp token
#---------------------------
# keystone-paste.ini
cfgfile=/etc/keystone/keystone-paste.ini
echo -e '\033[33mClose temp token  ...\033[0m'
cp $cfgfile $cfgbakpath/keystone-paste.ini.`date '+%y%m%d.%H%M%S'`
sed -i 's/request_id admin_token_auth build_auth_context/request_id build_auth_context/g' $cfgfile
# unset parameter
echo -e '\033[33mUnset some enviroment variable for next operation  ...\033[0m'
unset OS_AUTH_URL OS_PASSWORD

# Get token as admin
#---------------------------
echo -e '\033[33mGet token as admin  ...\033[0m'
openstack --os-auth-url http://$ctrl_hostname:35357/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin \
  --os-password $password token issue
#openstack --os-auth-url http://$ctrl_hostname:35357/v3 --os-project-domain-name Default --os-user-domain-name Default --os-project-name admin --os-username admin token issue
# ??? Input password Cloud123!

# get token as demo
echo -e '\033[33mGet token as demo  ...\033[0m'
openstack --os-auth-url http://$ctrl_hostname:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name demo --os-username demo \
  --os-password $password token issue
#openstack --os-auth-url http://$ctrl_hostname:5000/v3 --os-project-domain-name Default --os-user-domain-name Default --os-project-name demo --os-username demo token issue
# ??? Input password Cloud123!

# create admin-openrc
#---------------------------
echo -e '\033[33mCreate ~/admin-openrc  ...\033[0m'
echo "#
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$password
export OS_AUTH_URL=http://$ctrl_hostname:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
" > ~/admin-openrc

# create demo-openrc
#---------------------------
echo -e '\033[33mCreate ~/demo-openrc  ...\033[0m'
echo "#
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$password
export OS_AUTH_URL=http://$ctrl_hostname:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
" > ~/demo-openrc

# get token as admin
#---------------------------
echo -e '\033[33mGet token as admin  ...\033[0m'
. admin-openrc
openstack token issue

fi

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
####################################################

####################################################
# Part 3.4: Write to OPFlag
####################################################

# OPFlag
#------------------------------
echo -e '\033[33m Write to OPFlag ...\033[0m'
echo '3' > OPFlag
