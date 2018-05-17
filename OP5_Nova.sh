#!/bin/bash

####################################################
#
# File: OP5_Nova.sh
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
# Part 5 : Only runned at Controller and Compute node
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

if [ $nodetype = 'ctrl' ] || [ $nodetype = 'comp' ]; then

####################################################
# Part 5.0: Prepare
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
# Part 5.1: Intallation
####################################################

# Load branch
#---------------------------
case $nodetype in
  'ctrl')
    source ./OP5.A_Nova_Ctrl.sh
    ;;
  'comp')
    source ./OP5.B_Nova_Comp.sh
    ;;
  * )
  ;;
esac

fi

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
####################################################

####################################################
# Part 5.2: Write to OPFlag
####################################################

# OPFlag
#------------------------------
echo -e '\033[33m Write to OPFlag ...\033[0m'
echo '5' > OPFlag
