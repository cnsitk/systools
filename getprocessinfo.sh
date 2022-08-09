#!/bin/bash

TestPID="$1"


if [ -z $TestPID ];  then
   echo "Pls add the Progress ID!"
   exit -1
fi

cpu_cores=$(getconf _NPROCESSORS_ONLN)
clock_ticks=$(getconf CLK_TCK)
total_memory=$( grep -Po '(?<=MemTotal:\s{8})(\d+)' /proc/meminfo )

mem_rss=`grep "Rss:" /proc/$TestPID/smaps | awk 'BEGIN {a=0 } {a = a+$2} END {print a}'`
mem_pss=`grep "Pss:" /proc/$TestPID/smaps | awk 'BEGIN {a=0 } {a = a+$2} END {print a}'`
mem_swap=`grep "Swap:" /proc/$TestPID/smaps | awk 'BEGIN {a=0 } {a = a+$2} END {print a}'`
mem_ref=`grep "Referenced:" /proc/$TestPID/smaps | awk 'BEGIN {a=0 } {a = a+$2} END {print a}'`
memory_usage=$( awk 'BEGIN {print( ('$mem_rss'  * 100) / '$total_memory'  )}' )

stat_array=`cat /proc/$TestPID/stat | cut -d' ' -f14-20`
utime=`echo $stat_array | cut -d' ' -f1`
stime=`echo $stat_array | cut -d' ' -f2`
cutime=`echo $stat_array | cut -d' ' -f3`
cstime=`echo $stat_array | cut -d' ' -f4`
total_time01=$(( $utime + $stime + $cstime + $cutime ))
num_threads=`echo $stat_array | cut -d' ' -f7`

sleep_interanl=1
sleep $sleep_interanl

stat_array=`cat /proc/$TestPID/stat | cut -d' ' -f14-20`
utime=`echo $stat_array | cut -d' ' -f1`
stime=`echo $stat_array | cut -d' ' -f2`
cutime=`echo $stat_array | cut -d' ' -f3`
cstime=`echo $stat_array | cut -d' ' -f4`
total_time02=$(( $utime + $stime + $cstime + $cutime ))
num_threads=`echo $stat_array | cut -d' ' -f7`

cpu_usage=$( awk 'BEGIN {print ( 100 * ( ('$total_time02'  - '$total_time01') / '$clock_ticks')  / ('$sleep_interanl' * '$cpu_cores')  )}' )

printf "MemInfo(KB):Total:$total_memory  RSS:$mem_rss PSS:$mem_pss Swap:$mem_swap Ref:$mem_ref Usage:%.4f\n" $memory_usage
printf "CpuInfo(%%):Threads:$num_threads Usage:%.4f\n" $cpu_usage
exit 0
