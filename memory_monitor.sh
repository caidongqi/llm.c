#!/usr/bin/env bash

# usage: memory_monitor.sh <pid>
# 例如: memory_monitor.sh 12345
TARGET_PID=$1

if [ -z "$TARGET_PID" ]; then
    echo "Usage: $0 <pid>"
    exit 1
fi

# 确保目标进程存活一段时间
while kill -0 ${TARGET_PID} 2> /dev/null; do
    # 获取系统总体可用内存信息
    # 从meminfo中提取MemAvailable字段(单位kB)
    MEM_AVAILABLE=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')

    # 获取目标进程的内存使用情况
    # dumpsys meminfo输出较为复杂，这里示例提取PSS值(kB)
    # 实际需根据dumpsys meminfo输出格式适当修改
    MEM_INFO=$(dumpsys meminfo ${TARGET_PID} | grep "TOTAL" | awk '{print $2}')
    # MEM_INFO此处假定提取到进程总计使用的内存(kB)
    
    # 记录当前时间戳
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    echo "${TIMESTAMP} MemAvailable=${MEM_AVAILABLE}KB, ProcessMem=${MEM_INFO}KB"

    # 每秒记录一次
    sleep 1
done