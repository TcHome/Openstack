#!/bin/bash

####################################################
#
# File: OP0_Prepare.sh
# Version: 1.0
# Made by wangdeng (2018-5-11)
# OS: CentOS 7.4 1708
# RunAt: All Location
# Run by: root
# Info:
#   ...
# 
####################################################

####################################################
# Part 0.1: Locatin and Nodetype
####################################################

# Set Location
#----------------------------------
echo ""
echo " Where do you run this script ?"
echo "-----------------------"
echo " 1. xxg - Intenational Information Port"
echo " 2. office - Testing Server in F17 Building A"
echo " 3. home - My home behind router"
echo " 4. I don't know"
echo "-----------------------"
echo -n "Your Choice: "

while :
do
	read choise
	case $choise in
	  '1') location=xxg
	  	   break
	    ;;
	  '2') location=office
	  	   break
	    ;;
	  '3') location=home
	  	   break
	    ;;
	  '4') echo "Sorry, I can't help you ."
	       exit
	    ;;
	  *) echo "Sorry, you choose wrong item. Try again please."
			 echo -n "Your Choice: "
	    ;;
	esac
done
echo -e '\033[33m Set Location ...\033[0m'
echo "  Location = $location"

  
# Set Nodetype
#----------------------------------
echo ""
echo " What type node would you run this scipt at ?"
echo "-----------------------"
echo " 1. Controller Node"
echo " 2. Compute Node"
echo " 3. Block Storage Node"
echo " 4. Object Storage Node 1"
echo " 5. Object Storage Node 2"
echo " 6. I don't know"
echo "-----------------------"
echo -n "Your Choice: "

while :
do
	read choise
	case $choise in
	  '1') nodetype=ctrl
	       break
	    ;;
	  '2') nodetype=comp
	       break
	    ;;
	  '3') nodetype=blks
	       break
	    ;;
	  '4') nodetype=objs1
	       break
	    ;;
	  '5') nodetype=objs2
	       break
	    ;;
	  '6') echo "Sorry, I can't help you ."
	    exit
	    ;;
	  *) echo "Sorry, you choose wrong item. Try again please."
		   echo -n "Your Choice: "
	    ;;
	esac
done
echo -e '\033[33m Set Nodetype ...\033[0m'
echo "  nodetype = $nodetype"

####################################################
# Part 0.2: Host Infomation
####################################################

# Set node name
#-------------------------
echo -e '\033[33m Set node name ...\033[0m'
ctrl_hostname=controller
comp_hostname=compute
blks_hostname=blockstorage
objs1_hostname=object1
objs2_hostname=object2

# Set IP Plan
#------------------------------
echo -e '\033[33m Set IP Plan ...\033[0m'
# gl for management & yw for business
case $location in
  'xxg')
    ip_gl=10.23.8.32
    msk_gl=255.255.255.224
    gw_gl=10.23.8.33
    ip_yw=10.23.8.64
    msk_yw=255.255.255.224
    gw_yw=10.23.8.65
    prefix=27
    ;;
  'office') 
    ip_gl=10.1.17.0
    msk_gl=255.255.255.0
    gw_gl=10.17.1.254
    ip_yw=172.1.17.0
    msk_yw=255.255.255.0
    gw_yw=172.1.17.254
    prefix=24
    ;;
  'home') 
    ip_gl=192.168.1.0
    msk_gl=255.255.255.0
    gw_gl=192.168.1.1
    ip_yw=172.168.1.0
    msk_yw=255.255.255.0
    gw_yw=172.168.1.1
    prefix=24
    ;;
esac
subnet_gl=$ip_gl/$prefix
subnet_yw=$ip_yw/$prefix

# Set node's ip
#------------------------------
echo -e "\033[33m Set node's IP ...\033[0m"
gl_seg=`echo $ip_gl | awk -F '.' '{print $1"."$2"."$3}'`
yw_seg=`echo $ip_yw | awk -F '.' '{print $1"."$2"."$3}'`
case $location in
  'xxg') 
    ctrl_gl_ip=$gl_seg.40
    comp_gl_ip=$gl_seg.41
    blks_gl_ip=$gl_seg.42
    objs1_gl_ip=$gl_seg.43
    objs2_gl_ip=$gl_seg.44

    ctrl_yw_ip=$yw_seg.70
    comp_yw_ip=$yw_seg.71
    blks_yw_ip=$yw_seg.72
    objs1_yw_ip=$yw_seg.73
    ojbs2_yw_ip=$yw_seg.74
    ;;
  'office') 
    ctrl_gl_ip=$gl_seg.118
    comp_gl_ip=$gl_seg.119
    blks_gl_ip=$gl_seg.186
    objs1_gl_ip=$gl_seg.117
    objs2_gl_ip=$gl_seg.120

    ctrl_yw_ip=$yw_seg.118
    comp_yw_ip=$yw_seg.119
    blks_yw_ip=$yw_seg.186
    objs1_yw_ip=$yw_seg.117
    objs2_yw_ip=$yw_seg.120
    ;;
  'office'|'home') 
    ctrl_gl_ip=$gl_seg.10
    comp_gl_ip=$gl_seg.11
    blks_gl_ip=$gl_seg.12
    objs1_gl_ip=$gl_seg.13
    objs2_gl_ip=$gl_seg.14

    ctrl_yw_ip=$yw_seg.10
    comp_yw_ip=$yw_seg.11
    blks_yw_ip=$yw_seg.12
    objs1_yw_ip=$yw_seg.13
    objs2_yw_ip=$yw_seg.14
    ;;
esac

####################################################
# Part 0.2: Config Infomation
####################################################

# Set Password
#------------------------------
echo -e '\033[33m Set node name ...\033[0m'
password=Cloud123!
DBPASS=$password
RABBITMQ_PASS=$password
KEYSTONE_PASS=$password
GLANCE_PASS=$password
NOVA_PASS=$password
NEUTRON_PASS=$password
DASHBOARD_PASS=$password
CINDER_PASS=$password
PLACEMENT_PASS=$password


# Set Path
#------------------------------
echo -e '\033[33m Set path ...\033[0m'
cfgbakpath=~/cfg_bak
repobakpath=$cfgbakpath/repobak
etcpath=/etc
netpath=/etc/sysconfig/network-scripts
cdpath=/mnt/cdrom

# Set Netcard
#------------------------------
echo ""
echo " What type node would you run this scipt at ?"
echo "-----------------------"
echo " 1. ens33/ens34"
echo " 2. ens160/ens192"
echo " 3. other -- 123/456 for ens123/ens456"
echo " 4. I don't know"
echo "-----------------------"
echo -n "Your Choice: "

while :
do
	read choise
	case $choise in
	  '1') 
	      netcard1=ens33
	      netcard2=ens34
	      nc_rlt="  netcard1 is ens33 && netcard2 is ens34"
	      break
	    ;;
	  '2')
	      netcard1=ens160
	      netcard2=ens192
	      nc_rlt="  netcard1 is ens160 && netcard2 is ens192"
	      break
	    ;;
	  '3') 
	      echo -n "Your netcards pair is: "
	      read ncstr
	      netcard1=ens${ncstr%%/*}
	      netcard2=ens${ncstr##*/}
	      nc_rlt="  netcard1 is $netcard1 && netcard2 is $netcard1"
	      break
	    ;;
	  '4') echo "Sorry, I can't help you ."
	    exit
	    ;;
	  *) echo "Sorry, you choose wrong item. Try again please."
	     echo -n "Your Choice: "
	    ;;
	esac
done
echo -e '\033[33m Set Netcard ...\033[0m'
echo $nc_rlt

####################################################
# Part 0.3: Server Infomation
####################################################

# Set DNS Server
#------------------------------
case $location in
  'xxg') 
    dns_outer=8.8.8.8
    dns_inner=10.23.8.3
    ;;
  'home') 
    dns_outer=8.8.8.8
    dns_inner=$dns_outer
    ;;
  'office')
    dns_outer=10.1.28.25
    dns_inner=$dns_outer
    proxy=http://proxy.hq.cmcc:8080/
    ;;
esac

# Set NTP Server
#------------------------------
ntp_outer=133.100.11.8
ntp_inner=$ctrl_gl_ip

####################################################
# Part 0.4: Confirm Setting
####################################################

# Confirm Setting
#------------------------------
echo ""
echo " Are these setting right , Yes or No ?"
echo "-----------------------"
echo " y. Yes"
echo " n. No"
echo "-----------------------"
echo -n "Your Choice: "

while :
do
	read choise
	case $choise in
	  'Y'|'y') echo -e "Enviorment setting is ready."
      break
	    ;;
	  'N'|'n') echo "Ah...See you next time."
	    exit
	    ;;
	  *) echo "Sorry, you choose wrong item. Try again please."
	     echo -n "Your Choice: "
	    ;;
	esac
done

####################################################
# Part 0.5: Check system
####################################################

# Check OS
#------------------------------
echo -e '\033[33m Check centos version ...\033[0m'
if [[ `cat /etc/centos-release` != *7.* ]]; then
	echo  -e '\033[31;1m[Err] Not correct CentOS version (7.x) !\033[0m'
	exit
fi
	
# Check root account
#------------------------------
echo -e '\033[33m Check account ...\033[0m'
if [ `whoami` != "root" ]; then
	echo -e '\033[31;1m[Err] Use root account please !\033[0m'
  exit
fi

# Confirm Operation before
#------------------------------
echo -e '\033[33m Confirm Operation ...\033[0m'
echo ""
echo " Now, confirm these operations below have been done"
echo "   -- OS is clear. (Pure mini CentOS 7.4)"
echo "   -- Config and Up the first netcard. (ifcfg-ensxx)"
echo "   -- Config the NetworkManagement. (NetworkManagement.conf)"
echo "   -- Restart the network service."
echo "   -- Upload the cdrom with OS. (CentOS 7.4)"
echo "   Yes or No ?"
echo "-----------------------"
echo " y. Yes"
echo " n. No"
echo "-----------------------"
echo -n "Your Choice: "

while :
do
	read choise
	case $choise in
	  'Y'|'y') echo -e "Now, Let's go ...\n"
      break
	    ;;
	  'N'|'n') echo "Ah...See you next time."
	    exit
	    ;;
	  *) echo "Sorry, you choose wrong item. Try again please."
	    exit
	    ;;
	esac
done

####################################################
# Part 0.5: Write Config file
####################################################

# envconf.rc
#------------------------------
echo -e '\033[33m Write to envconf.rc ...\033[0m'
cfgfile=envconf.rc
if [ -e $cfgfile ]; then
	mv $cfgfile $cfgbakpath/$cfgfile.`date '+%y%m%d.%H%M%S'`
fi
echo "#
# 
#  Generate by wangd @ "`date '+%y%m%d.%H%M%S'`"

# Locatin and Nodetype
export location=$location
export nodetype=$nodetype

# Host Infomation
export ctrl_hostname=$ctrl_hostname
export comp_hostname=$comp_hostname
export blks_hostname=$blks_hostname
export objs1_hostname=$objs1_hostname
export objs2_hostname=$objs2_hostname
export ip_gl=$ip_gl
export msk_gl=$msk_gl
export gw_gl=$gw_gl
export ip_yw=$ip_yw
export msk_yw=$msk_yw
export gw_yw=$gw_yw
export prefix=$prefix
export ctrl_gl_ip=$ctrl_gl_ip
export comp_gl_ip=$comp_gl_ip
export blks_gl_ip=$blks_gl_ip
export objs1_gl_ip=$objs1_gl_ip
export objs2_gl_ip=$objs2_gl_ip
export ctrl_yw_ip=$ctrl_yw_ip
export comp_yw_ip=$comp_yw_ip
export blks_yw_ip=$blks_yw_ip
export objs1_yw_ip=$objs1_yw_ip
export objs2_yw_ip=$objs2_yw_ip
export subnet_gl=$subnet_gl
export subnet_yw=$subnet_yw

# Config Password
export password=Cloud123!
export DBPASS=$DBPASS
export RABBITMQ_PASS=$RABBITMQ_PASS
export KEYSTONE_PASS=$KEYSTONE_PASS
export GLANCE_PASS=$GLANCE_PASS
export NOVA_PASS=$NOVA_PASS
export NEUTRON_PASS=$NEUTRON_PASS
export DASHBOARD_PASS=$DASHBOARD_PASS
export CINDER_PASS=$CINDER_PASS
export PLACEMENT_PASS=$PLACEMENT_PASS


# Config Infomation
export cfgbakpath=$cfgbakpath
export repobakpath=$repobakpath
export etcpath=$etcpath
export netpath=$netpath
export cdpath=$cdpath
export netcard1=$netcard1
export netcard2=$netcard2

# Server Infomation
export dns_outer=$dns_outer
export ntp_outer=$ntp_outer
export dns_inner=$dns_inner
export ntp_inner=$ntp_inner
export proxy=$proxy
" > envconf.rc

# OPFlag
#    The flag of operation
#------------------------------
echo -e '\033[33m Write to OPFlag ...\033[0m'
echo '0' > OPFlag
