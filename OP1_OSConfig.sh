#!/bin/bash

####################################################
#
# File: OP1_OSConfig.sh
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
# Part 1.0: Operation with No Script
#
#          MUST BE READY ！！！
#
####################################################

# Set the First NetCart
#------------------------------
# ncpath=/etc/sysconfig/network-scripts
# cp $ncpath/ifcfg-ens33{,.bak}
# vi $ncpath/ifcfg-ens33   -------->   remove: IPv6, DEFROUTE, ID...   change: BOOTBROTO, ONBOOT, ...  add: IPADDR, PREFIX, NM_CONTROLLED...
#
#TYPE="Ethernet"
#BOOTPROTO="static"
#IPV6INIT="no"
#NAME="ens33"
#DEVICE="ens33"
#ONBOOT="yes"
#IPADDR="10.1.17.117"
#PREFIX="24"
#NM_CONTROLLED=no
#

# Startup netcard1
#------------------------------
# ifup ens33

####################################################
# Part 1.1: Make Path
####################################################

# Load /envconf.rc
#---------------------------
source ./envconf.rc

# Set backup folder
#---------------------------
if  [[ ! -d $cfgbakpath ]]; then
  mkdir $cfgbakpath
fi

if  [[ ! -d $repobakpath ]]; then
  mkdir $repobakpath
fi

# Set cdrom folder
#---------------------------
if  [[ ! -d $cdpath ]]; then
  mkdir $cdpath
fi

####################################################
# Part 1.2: Set network and host
####################################################

# Set netcard1
#---------------------------
echo -e '\033[33mSet netcard 1 ...\033[0m'
cfgfile=$netpath/ifcfg-$netcard1
cp $cfgfile $cfgbakpath/ifcfg-$netcard1.`date '+%y%m%d.%H%M%S'` 

# Set netcard2
#---------------------------
echo -e '\033[33mSet netcard 2 ...\033[0m'
cfgfile=$netpath/ifcfg-$netcard2
cp $cfgfile $cfgbakpath/ifcfg-$netcard2.`date '+%y%m%d.%H%M%S'` 
#-- remove --
sed -i '/^IPV4_FAILURE_FATAL/d' $cfgfile
sed -i '/^IPV6_AUTOCONF/d' $cfgfile
sed -i '/^IPV6_DEFROUTE/d' $cfgfile
sed -i '/^IPV6_PEERDNS/d' $cfgfile
sed -i '/^IPV6_PEERROUTES/d' $cfgfile
sed -i '/^IPV6_FAILURE_FATAL/d' $cfgfile
sed -i '/^UUID/d' $cfgfile
#-- change --
sed -i '/^BOOTPROTO/c BOOTPROTO=static' $cfgfile
sed -i '/^ONBOOT/c ONBOOT=yes' $cfgfile
sed -i '/^IPV6INIT/c IPV6INIT=no' $cfgfile
sed -i "/^NAME/c NAME=$netcard2" $cfgfile
sed -i "/^DEVICE/c DEVICE=$netcard2" $cfgfile
#-- add --
sed -i '/^IPADDR/d' $cfgfile
sed -i '/^PREFIX/d' $cfgfile
sed -i '/^NM_CONTROLLED/d' $cfgfile
case $nodetype in
  'ctrl') 
    echo "IPADDR=$ctrl_yw_ip" >> $cfgfile
    ;;
  'comp') 
    echo "IPADDR=$comp_yw_ip" >> $cfgfile
    ;;
  'blks') 
    echo "IPADDR=$blks_yw_ip" >> $cfgfile
    ;;
  'objs1')
    echo "IPADDR=$objs1_yw_ip" >> $cfgfile
    ;;
  'objs2') 
    echo "IPADDR=$objs2_yw_ip" >> $cfgfile
    ;;
esac
echo "PREFIX=$prefix" >> $cfgfile
echo "NM_CONTROLLED=no" >> $cfgfile
ifdown $netcard2 && ifup $netcard2

# Set hostname
#---------------------------
echo -e '\033[33mSet hostname ...\033[0m'
case $nodetype in
  'ctrl') 
    hostnamectl set-hostname $ctrl_hostname
    ;;
  'comp') 
    hostnamectl set-hostname $comp_hostname
    ;;
  'blks') 
    hostnamectl set-hostname $blks_hostname
    ;;
  'objs1')
    hostnamectl set-hostname $objs1_hostname
    ;;
  'objs2') 
    hostnamectl set-hostname $objs2_hostname
    ;;
esac

# Set hosts
#---------------------------
echo -e '\033[33mSet /etc/hosts ...\033[0m'
mv /etc/hosts $cfgbakpath/hosts.`date '+%y%m%d.%H%M%S'` 
echo "#
#local
127.0.0.1 localhost
::1 localhost
# net-gl
$ctrl_gl_ip   	$ctrl_hostname
$comp_gl_ip   	$comp_hostname
$blks_gl_ip   	$blks_hostname
$objs1_gl_ip   	$objs1_hostname
$objs2_gl_ip   	$objs2_hostname
# net-yw
$ctrl_yw_ip   	$ctrl_hostname
$comp_yw_ip   	$comp_hostname
$blks_yw_ip   	$blks_hostname
$objs1_yw_ip   	$objs1_hostname
$objs2_yw_ip   	$objs2_hostname
#">/etc/hosts

# Set NetworkManager.conf
#---------------------------
echo -e '\033[33mSet /etc/NetworkManager/NetworkManager.conf ...\033[0m'
cfgfile=/etc/NetworkManager/NetworkManager.conf
mv $cfgfile $cfgbakpath/NetworkManager.conf.`date '+%y%m%d.%H%M%S'`
echo 'dns=none' > $cfgfile
systemctl restart network

# Set resolv.conf
#---------------------------
echo -e '\033[33mSet /etc/resolv.conf ...\033[0m'
cfgfile=/etc/resolv.conf
mv  $cfgfile $cfgbakpath/resolv.conf.`date '+%y%m%d.%H%M%S'`
### nameserver could be changed to dns_inner where dsn_inner is ready ###
echo "nameserver $dns_outer" > $cfgfile

####################################################
# Part 1.3: Software Repo
####################################################

# Mount cdrom
#---------------------------
echo -e '\033[33mMount cdrom ...\033[0m'
if [[ `mount | grep 'cdrom' | awk -F ' ' '{print $1}'` != /dev/sr0 ]]; then
  mount /dev/sr0 $cdpath
else
  echo 'CDROM has mounted, ignore ...'
fi

# Config CD repo
#---------------------------
echo -e '\033[33mConfig /etc/yum.repos.d/cdrom.repo ...\033[0m'
for fn in `ls /etc/yum.repos.d/*.repo`
do
	mv $fn $repobakpath/${fn##*/}.`date '+%y%m%d.%H%M%S'`
done
echo "#
[c7-media]
name=CentOS-\$releasever - Media
baseurl=file://$cdpath
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
"> /etc/yum.repos.d/cdrom.repo
yum clean all && yum makecache

####################################################
# Part 1.4: Software Install
####################################################

# Install vim
#---------------------------
echo -e '\033[33mInstall vim ...\033[0m'
if [[ `yum list installed | grep 'vim' | awk -F ' ' '{print $1}'` != *vim* ]]; then
  yum install vim -y
else
  echo 'vim has installed, ignore ...'
fi

# Install wget
#---------------------------
echo -e '\033[33mInstall wget ...\033[0m'
if [[ `yum list installed | grep 'wget' | awk -F ' ' '{print $1}'` != *wget* ]]; then
  yum install wget -y
else
  echo 'wget has installed, ignore ...'
fi


# Install net-tools
#---------------------------
echo -e '\033[33mInstall net-tools ...\033[0m'
if [[ `yum list installed | grep 'net-tools' | awk -F ' ' '{print $1}'` != *net-tools* ]]; then
  yum install net-tools -y
else
  echo 'net-tools has installed, ignore ...'
fi

# Install expect
#---------------------------
echo -e '\033[33mInstall expect ...\033[0m'
if [[ `yum list installed | grep 'expect' | awk -F ' ' '{print $1}'` != *expect* ]]; then
  yum install expect -y
else
  echo 'expect has installed, ignore ...'
fi

# Install open-vm-tools (Optional for vm)
#---------------------------
echo -e '\033[33mInstall open-vm-tools ...\033[0m'
if [[ `yum list installed | grep 'open-vm-tools' | awk -F ' ' '{print $1}'` != *open-vm-tools* ]]; then
  yum install open-vm-tools -y
else
  echo 'open-vm-tools has installed, ignore ...'
fi

####################################################
# Part 1.5: Config Proxy
####################################################

# Config proxy
#---------------------------
echo -e '\033[33mConfig proxy ...\033[0m'
if [ $location = office ]; then
	echo -e '\033[33mConfig proxy for OFFICE ...\033[0m'
	# Config yum proxy
	cp /etc/yum.conf $cfgbakpath/yum.`date '+%y%m%d.%H%M%S'` 
  sed -i '/^proxy/d' /etc/yum.conf
	echo "proxy = $proxy" >> /etc/yum.conf
	# Config wget proxy
	cp /etc/wgetrc $cfgbakpath/wgetrc.`date '+%y%m%d.%H%M%S'`
  sed -i '/^http_proxy/d' /etc/wgetrc
  sed -i '/^https_proxy/d' /etc/wgetrc
  sed -i '/^ftp_proxy/d' /etc/wgetrc
	echo "http_proxy =  $proxy">> /etc/wgetrc
	echo "https_proxy =  $proxy">> /etc/wgetrc
	echo "ftp_proxy = $proxy">> /etc/wgetrc
	sed -i '/^#use_proxy/c use_proxy = on' /etc/wgetrc
else
	echo -e '\033[33mIgnore proxy for XXG and HOME ...\033[0m'
fi

####################################################
# Part 1.6: Stop firewall and SELinux
####################################################

# Stop SELinux and firewalld
#---------------------------
echo -e '\033[33mStop selinux and firewalld ...\033[0m'
setenforce 0
cp /etc/selinux/config $cfgbakpath/selinux.config.`date '+%y%m%d.%H%M%S'`
sed -i '/^SELINUX=/c SELINUX=disabled' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld	
		
####################################################
# Part 1.7: Config Ali Software Resource
####################################################

# Config Ali repo
#---------------------------
echo -e '\033[33mConfig ali repos ...\033[0m'
wget -O /etc/yum.repos.d/epel-7-ali.repo http://mirrors.aliyun.com/repo/epel-7.repo
wget -O /etc/yum.repos.d/CentOS-7-ali.repo http://mirrors.aliyun.com/repo/Centos-7.repo
#yum clean all && yum makecache


####################################################
# Part 1.8: Some Configuation
####################################################

# Config Alias
#---------------------------
echo -e '\033[33mConfig ~/.bashrc ...\033[0m'
cfgfile=~/.bashrc
cp $cfgfile $cfgbakpath/bashrc.`date '+%y%m%d.%H%M%S'`
#-- remove --
sed -i '/rm -i/d' $cfgfile
sed -i '/cp -i/d' $cfgfile
sed -i '/mv -i/d' $cfgfile
#-- add --
if [ `grep -c 'vim' $cfgfile` -eq 0 ]; then 
  echo "alias vi='vim'" >> $cfgfile
fi
if [ `grep -c 'mntcd' $cfgfile` -eq 0 ]; then 
  echo "alias mntcd='mount /dev/sr0 $cdpath'" >> $cfgfile
fi
if [ `grep -c 'cdnet' $cfgfile` -eq 0 ]; then 
  echo "alias cdnet='cd $netpath'" >> $cfgfile
fi
source $cfgfile

# OPFlag
#------------------------------
echo -e '\033[33m Write to OPFlag ...\033[0m'
echo '1' > OPFlag

