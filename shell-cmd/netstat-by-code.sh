#!/bin/bash

## use shell scripts to implement netstat cmd for list tcp4 sockets.
## 2024-01
## test in Ubuntu 22.04

## cat /proc/net/tcp
## reference: https://gist.github.com/jkstill/5095725


# echo -e "Local Address\tRemote Address\tState\tTimer\tPID\tCMD"
printf "%-24s %-24s %-12s %-24s %-12s\n" "Local Address" "Remote Address" "State" "Timer" "PID"
echo "--------------------------------------------------------------------------------------------------------"


# 创建一个空的 inode 到 PID 的映射
declare -A inode_map

# 遍历所有进程的文件描述符，填充映射
for fd_dir in /proc/[0-9]*/fd/*; do
  if [ -L $fd_dir ]; then
    link_inode=$(ls -l $fd_dir 2>/dev/null | awk '{print$NF}')
    if [ -z "$link_inode" ]; then
      continue
    fi
    # 将 inode 映射到 PID
    inode_map[$link_inode]=$(basename $(dirname $(dirname $fd_dir)))
  fi
done

# echo "Inode Map Size: ${#inode_map[@]}"
# # 打印 inode_map 的内容
# echo "Inode Map Contents:"
# for key in "${!inode_map[@]}"; do
#   echo "$key -> ${inode_map[$key]}"
# done

# Skip the first line (header)
sed 1d /proc/net/tcp | while read line
do
    # Extract relevant fields from the line
    local_address=$(echo $line | awk '{print $2}')
    remote_address=$(echo $line | awk '{print $3}')
    state_code=$(echo $line | awk '{print $4}')
    timer_info=$(echo $line | awk '{print $6}')
    timer_tr=$(echo $timer_info | cut -d: -f1)
    timer_sec=$(echo $timer_info | cut -d: -f2)
    inode=$(echo $line | awk '{print $10}')


    # Convert hex addresses to human-readable IP and port
    local_address_dec=$(printf "%d.%d.%d.%d:%d\n" 0x${local_address:6:2} 0x${local_address:4:2} 0x${local_address:2:2} 0x${local_address:0:2} 0x$(echo $local_address | cut -d: -f2))
    remote_address_dec=$(printf "%d.%d.%d.%d:%d\n" 0x${remote_address:6:2} 0x${remote_address:4:2} 0x${remote_address:2:2} 0x${remote_address:0:2} 0x$(echo $remote_address | cut -d: -f2))

    # Convert socket state to human-readable
    state_dec=$((16#$state_code))

    case $state_dec in
        1) state_name="ESTABLISHED" ;;
        2) state_name="SYN_SENT" ;;
        3) state_name="SYN_RECV" ;;
        4) state_name="FIN_WAIT1" ;;
        5) state_name="FIN_WAIT2" ;;
        6) state_name="TIME_WAIT" ;;
        7) state_name="CLOSE" ;;
        8) state_name="CLOSE_WAIT" ;;
        9) state_name="LAST_ACK" ;;
        10) state_name="LISTEN" ;;
        *) state_name="UNKNOWN" ;;
    esac

    # Convert timer (keepalive and timeout) to human-readable
    # 0 off/1 on
    timer_tr_dec=$((16#$timer_tr))
    case $timer_tr_dec in
        0) tr_name="off" ;;
        1) tr_name="on" ;;
        2) tr_name="keepalive" ;;
        3) tr_name="timewait " ;;
        4) tr_name="Windowprobe" ;;
        *) tr_name="na" ;;
    esac

     timer_sec_dec=$((16#$timer_sec))
     # timer_sec_float=$(echo "scale=2; $timer_sec_dec / 100" | bc)
     timer_sec_float=$(awk -v a=$timer_sec_dec 'BEGIN {printf "%.2f", a / 100.0}')

    # Find owner (pid)  of socket
    tcp_fd_link=$(echo "socket:["$inode"]")
    # 使用映射来找到 PID
    pid=${inode_map["$tcp_fd_link"]}
    # if [ -n "$pid" ]; then
    #     cmd_pid=$(cat /proc/$pid/cmdline 2>/dev/null)
    # fi
    # Print the information
    # echo  -e "$local_address_dec\t$remote_address_dec\t$state_name\t${tr_name}(${timer_sec_float}s)\t$pid"
    printf "%-24s %-24s %-12s %-24s %-12s\n" "$local_address_dec" "$remote_address_dec" "$state_name" "${tr_name}(${timer_sec_float}s)" "$pid"
done

