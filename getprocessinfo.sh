#!/bin/bash

TestPID=""
FilterName="$1"

if [ -z "$FilterName" ]; then
    echo "pls add the progress name filter prams!"
    exit -1 
fi
TestPID=`ps aux | grep "$FilterName" | grep -v 'grep'  | head -n 1 | awk '{print $2}'` 2>/dev/null
TestPgName=`ps aux | grep "$FilterName" | grep -v 'grep'  | head -n 1 | awk '{print $11}' | awk  -F '/' '{print $2}'` 2>/dev/null

if [ -z $TestPID ];  then
   echo "Progress Not Found!"
   exit -1
fi
cpu_cores=$(getconf _NPROCESSORS_ONLN)
clock_ticks=$(getconf CLK_TCK)
total_memory=$( grep -Po '(?<=MemTotal:\s{8})(\d+)' /proc/meminfo )
stat_array=( `sed -E 's/(\([^\s)]+)\s([^)]+\))/\1_\2/g' /proc/$TestPID/stat` )
uptime_array=( `cat /proc/uptime` )
uptime=${uptime_array[0]}
utime=${stat_array[13]}
stime=${stat_array[14]}
cutime=${stat_array[15]}
cstime=${stat_array[16]}
num_threads=${stat_array[19]}
if [[ $num_threads == 0 ]]; then 
  num_threads= `grep "Threads:" /proc/$TestPID/status 2>/dev/null | awk '{print $2}'`
fi
mem_rss=`grep "Rss:" /proc/$TestPID/smaps | awk 'BEGIN {a=0 } {a = a+$2} END {print a}'`
mem_pss=`grep "Pss:" /proc/$TestPID/smaps | awk 'BEGIN {a=0 } {a = a+$2} END {print a}'`
mem_swap=`grep "Swap:" /proc/$TestPID/smaps | awk 'BEGIN {a=0 } {a = a+$2} END {print a}'`
mem_ref=`grep "Referenced:" /proc/$TestPID/smaps | awk 'BEGIN {a=0 } {a = a+$2} END {print a}'`
memory_usage=$( awk 'BEGIN {print( ('$mem_rss'  * 100) / '$total_memory'  )}' )
starttime=${stat_array[21]}
total_time=$(( $utime + $stime ))
total_time=$(( $total_time + $cstime ))
seconds=$( awk 'BEGIN {print ( '$uptime' - ('$starttime' / '$clock_ticks') )}' )
cpu_usage=0
if  expr $seconds '>' 0 1>/dev/null; then
  cpu_usage=$( awk 'BEGIN {print ( 100 * (('$total_time' / ('$clock_ticks' * '$cpu_cores')) / '$seconds') )}' )
fi

printf "MemInfo(KB):Total:$total_memory  RSS:$mem_rss PSS:$mem_pss Swap:$mem_swap Ref:$mem_ref Usage:%.4f\n" $memory_usage 
printf "CpuInfo(%%):Threads:$num_threads Usage:%.4f\n" $cpu_usage 
exit 0
