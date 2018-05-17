#!/bin/bash

####################################################
#
# File: OP2.1_Openstack_BR.sh
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
# Part 2.1.0: Prepare
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
# Part 2.1.1: Config Chrony
####################################################

# Install chrony
#------------------------------
echo -e '\033[33mInstall chrony ...\033[0m'
if [[ `yum list installed | grep 'chrony' | awk -F ' ' '{print $1}'` != *chrony* ]]; then
  yum install chrony -y
else
  echo 'chrony has installed, ignore ...'
fi

# Config chrony.conf
#------------------------------
cfgfile=/etc/chrony.conf
echo -e "\033[33mConfig  $cfgfile...\033[0m"
cp $cfgfile $cfgbakpath/chrony.conf.`date '+%y%m%d.%H%M%S'`
sed -i '/^server /d' $cfgfile
case $nodetype in
  'ctrl') 
		echo "server $ntp_outer iburst" >> $cfgfile
		sed -i "/^#allow .*/c allow $subnet_gl" $cfgfile
    ;;
  'comp'|'blks'|'objs1'|'objs2') 
		echo "server $ctrl_gl_ip iburst" >> $cfgfile
    ;;
esac

# Start chrony.service
#------------------------------
echo -e '\033[33mStart chronyd and set to autostart ...\033[0m'
systemctl start chronyd
systemctl enable chronyd
chronyc sources

####################################################
# Part 2.1.2: Get Openstack Ocata Repo
####################################################

# Get newton repo files
#------------------------------
echo -e '\033[33mGet openstack repos ...\033[0m'
if [[ `yum list installed | grep 'centos-release-openstack-ocata' | awk -F ' ' '{print $1}'` != *centos-release-openstack-ocata* ]]; then
  yum install centos-release-openstack-ocata -y
else
  echo 'centos-release-openstack-ocata has installed, ignore ...'
fi

# Handle useless repo files
#------------------------------
cfgfile=/etc/yum.repos.d/CentOS-Ceph-Jewel.repo
if [ -f $cfgfile ]; then
  mv -f $cfgfile $repobakpath/CentOS-Ceph-Jewel.repo.`date '+%y%m%d.%H%M%S'`
fi
cfgfile=/etc/yum.repos.d/CentOS-QEMU-EV.repo
if [ -f $cfgfile ]; then
  mv -f $cfgfile $repobakpath/CentOS-QEMU-EV.repo.`date '+%y%m%d.%H%M%S'`
fi

# Handle repo files
#------------------------------
echo -e '\033[33mUpdate repos ...\033[0m'
ali_repo=/etc/yum.repos.d/CentOS-ops-o-ali.repo
ali_repo_ori=/etc/yum.repos.d/CentOS-OpenStack-ocata.repo

if [ -f $ali_repo_ori ]; then
  sed -i "s#mirror.centos.org#mirrors.aliyun.com#g" $ali_repo_ori
  sed -i "s#buildlogs.centos.org#mirrors.aliyun.com#g" $ali_repo_ori
  sed -i "s#debuginfo.centos.org#mirrors.aliyun.com#g" $ali_repo_ori
  sed -i "s#vault.centos.org#mirrors.aliyun.com#g" $ali_repo_ori
  sed -i "s#trunk.rdoproject.org#mirrors.aliyun.com#g" $ali_repo_ori
  mv -f $ali_repo_ori $ali_repo
  cp -f $ali_repo $repobakpath/CentOS-ops-o-ali.repo
else
  cp -f $repobakpath/CentOS-ops-o-ali.repo $ali_repo
fi
yum clean all && yum makecache

####################################################
# Part 2.1.3: Upgrade system
####################################################

# Upgrade system
#------------------------------
echo -e '\033[33mUpgrade system ...\033[0m'
yum upgrade -y

####################################################
# Part 2.1.4: Write to OPFlag
####################################################

# OPFlag
#------------------------------
echo -e '\033[33m Write to OPFlag ...\033[0m'
echo '2.1' > OPFlag

# Prepare to Reboot
#------------------------------
echo -n " Would you want to reboot now ? (Y/n): "
while :
do
	read choise
	case $choise in
	  ''|'Y'|'y') 
	      echo " Reboot now ! "
	      reboot
	    ;;
	  'N'|'n')
	      echo " You choose to reboot later. "
	      break
	    ;;
	  *) echo -n " Would you want to reboot now ? (Y/n): "
	    ;;
	esac
done
