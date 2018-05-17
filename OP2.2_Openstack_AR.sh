#!/bin/bash

####################################################
#
# File: OP2.2_Openstack_AR.sh
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
# Part 2.2.0: Prepare
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
# Part 2.2.1: Check Information
####################################################

# Check kernal version
#---------------------------
echo -e '\033[33mCheck OS kernal version ...\033[0m'
echo "kernal version is : `uname -r`"

####################################################
# Part 2.2.1: Install Common Package
####################################################

# install python-openstackclient
#---------------------------
echo -e '\033[33mInstall python-openstackclient ...\033[0m'
if [[ `yum list installed | grep 'python-openstackclient' | awk -F ' ' '{print $1}'` != *python-openstackclient* ]]; then
  yum install python-openstackclient -y
else
  echo 'python-openstackclient has installed, ignore ...'
fi

# install openstack-selinux
#---------------------------
echo -e '\033[33mInstall openstack selinux ...\033[0m'
if [[ `yum list installed | grep 'openstack-selinux' | awk -F ' ' '{print $1}'` != *openstack-selinux* ]]; then
  yum install openstack-selinux -y
else
  echo 'python-openstackclient has installed, ignore ...'
fi

####################################################
# Part 2.2.2 ~ 2.2.6 : Only runned at Controller node
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

if [ $nodetype = 'ctrl' ]; then

####################################################
# Part 2.2.2: Install mysql
####################################################

# Install mariadb
#---------------------------
echo -e '\033[33mInstall mariadb python2-PyMySQL ...\033[0m'
if [[ `yum list installed | grep 'mariadb-server' | awk -F ' ' '{print $1}'` != *mariadb-server* ]]; then
  yum install mariadb mariadb-server python2-PyMySQL -y
  IsnewDB='True'
else
  IsnewDB='False'
  echo 'mariadb has installed, ignore ...'
fi

# Config mariadb's openstack.cnf
#---------------------------
cfgfile=/etc/my.cnf.d/openstack.cnf
echo -e "\033[33mConfig $cfgfile ...\033[0m"
if [ -f $cfgfile ]; then
  mv $cfgfile $cfgbakpath/mysql.openstack.cnf.`date '+%y%m%d.%H%M%S'`
fi
echo "#
[mysqld]
bind-address = $ctrl_gl_ip
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8	
" > $cfgfile

# Start mariadb.service
#------------------------------
echo -e '\033[33mStart mariadb and set to autostart ...\033[0m'
systemctl start mariadb
systemctl enable mariadb

# Initial mariadb
#------------------------------
echo -e '\033[33mInit mariadb ...\033[0m'
if [ $IsnewDB = 'True' ]; then
/usr/bin/expect << EOF
set timeout 30
spawn mysql_secure_installation
expect {
"enter for none" { send "\r"; exp_continue}
"password:" { send "$DBPASS\r"; exp_continue}
"new password:" { send "$DBPASS\r"; exp_continue}
"Y/n" { send "Y\r" ; exp_continue}
eof { exit }
}
EOF
else
  echo 'Ignore initiation of mySQL'
fi
#--------
#"Disallow root login remotely" { send "n\r" ; exp_continue}
#--------

####################################################
# Part 2.2.4: Install MongoDB
####################################################

# Install MongoDB
#------------------------------
echo -e '\033[33mConfig Mongodb ...\033[0m'
if [[ `yum list installed | grep 'mongodb-server' | awk -F ' ' '{print $1}'` != *mongodb-server* ]]; then
  yum install mongodb-server mongodb -y
else
  echo 'mongodb has installed, ignore ...'
fi

# Config mongod.cnf
#------------------------------
cfgfile=/etc/mongod.conf
cp $cfgfile $cfgbakpath/mongod.conf.`date '+%y%m%d.%H%M%S'`
sed -i "/bind_ip/c bind_ip = 127.0.0.1,$ctrl_gl_ip" $cfgfile
sed -i '/^#smallfiles/c smallfiles = true' $cfgfile

# Start mongod.service
#------------------------------
echo -e '\033[33mStart mongod and set to autostart ...\033[0m'
systemctl start mongod
systemctl enable mongod

####################################################
# Part 2.2.5: Install RabbitMQ
####################################################

# install rabbitMQ
#------------------------------
echo -e '\033[33mInstall Rabbitmq  ...\033[0m'
if [[ `yum list installed | grep 'rabbitmq' | awk -F ' ' '{print $1}'` != *rabbitmq* ]]; then
  yum install rabbitmq-server -y
else
  echo 'rabbitmq has installed, ignore ...'
fi

# Start rabbitmq-server
#------------------------------
echo -e '\033[33mStart rabbitmq-server and set to autostart ...\033[0m'
systemctl start rabbitmq-server
systemctl enable rabbitmq-server

# Config rabbitmq-server
#------------------------------
echo -e '\033[33mConfig rabbitmq ...\033[0m'
rabbitmqctl add_user openstack $RABBITMQ_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
#/usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management --online

# Restart mongod.service
#------------------------------
echo -e '\033[33mRestart rabbitmq-server ...\033[0m'
systemctl restart rabbitmq-server

####################################################
# Part 2.2.6: Install Memcache
####################################################

# Install MemCache
#------------------------------
echo -e '\033[33mInstall MemCache  ...\033[0m'
if [[ `yum list installed | grep 'memcached' | awk -F ' ' '{print $1}'` != *memcached* ]]; then
  yum install memcached python-memcached -y
else
  echo 'memcached has installed, ignore ...'
fi

# Config MemCache
#------------------------------
echo -e '\033[33mConfig memcached ...\033[0m'
cfgfile=/etc/memcached.conf
if [ -f $cfgfile ]; then
  mv $cfgfile $cfgbakpath/memcached.conf.`date '+%y%m%d.%H%M%S'`
fi
#echo "$ctrl_gl_ip" > $cfgfile          # ver: N
echo 'OPTION="127.0.0.1,::1,'$ctrl_hostname'"' > $cfgfile

# Start memcached
#------------------------------
echo -e '\033[33mStart memcached and set to autostart ...\033[0m'
systemctl start memcached
systemctl enable memcached

fi

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
####################################################

####################################################
# Part 2.2.7: Write to OPFlag
####################################################

# OPFlag
#------------------------------
echo -e '\033[33m Write to OPFlag ...\033[0m'
echo '2.2' > OPFlag
