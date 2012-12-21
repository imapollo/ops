#!/bin/ksh

cat /qad/projects/ddt/resourceRegister/portRegister | grep -v wtb | grep -v team | grep -v devel | grep -v mzq | grep -v dvr | grep -v xjz | grep -v arf | grep -v lrr | grep -v available | grep -v lsy | grep -v myb | grep -v == | grep -v "port config" | grep -v release | grep -v "#" | grep -v "^vm" | grep -v bpk | awk '{ print $3 " " $5 }' | sort | while read line
do
   user=`echo $line | awk '{ print $1 }'`
   path=`echo $line | awk '{ print $2 }'`
   if [ ! -d $path ]; then
      echo removed: $user $path
      continue
   fi
   if [ ! -f $path/config/deploymentDescriptor.xml ]; then
      echo removed: $user $path
      continue
   fi
   host=`grep "host name=" $path/config/deploymentDescriptor.xml | sed 's/.*"\(.*\)".*/\1/'`
   if echo $host | grep -qe "^vm"; then
      echo removed: $user $path
      continue
   fi
   echo unremoved: $user $path
done | sort
