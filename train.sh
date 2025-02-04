#!/usr/bin/env bash

# 创建logs目录存放日志文件
mkdir -p logs

# 要测试的batch sizes和sequence lengths列表（根据需要修改）
SEQ_LENGTHS=(64)
BATCH_SIZES=(1)
MODEL_NAMES=("gpt2_d48s.bin") # 模型文件名列表

# 可执行程序名字（假设已编译好该程序）
EXECUTABLE="./train_gpt2"

# 假设memory_monitor.sh脚本在同级目录下
MEM_MONITOR_SCRIPT="memory_monitor.sh"

# 每种配置运行前先kill掉之前的monitor进程，避免多重监控
pkill -f memory_monitor.sh

for MODEL in "${MODEL_NAMES[@]}"; do
    for BS in "${BATCH_SIZES[@]}"; do
        for MSL in "${SEQ_LENGTHS[@]}"; do
            # 为此次运行创建独立的日志文件名
            # 在日志文件名中加入模型名称，便于区分
            LOGFILE="logs/run_bs${BS}_msl${MSL}_model${MODEL}.log"
            MEMLOG="logs/memory_bs${BS}_msl${MSL}_model${MODEL}.log"

            echo "Starting run with BS=${BS}, MSL=${MSL}, MODEL=${MODEL}"

            # 启动程序，并将输出重定向到日志文件
            # 程序的参数按照要求传入： -b <int> -t <int> -M <string>
            ${EXECUTABLE} -b ${BS} -t ${MSL} -M ${MODEL} 2>&1 | tee ${LOGFILE} &
            TARGET_PID=$!
            echo "running ${EXECUTABLE} -b ${BS} -t ${MSL} -M ${MODEL} | tee ${LOGFILE}"
            echo "PID: ${TARGET_PID}"

            # 启动内存监控脚本，并传递要监控的pid和输出日志文件路径
            sh ${MEM_MONITOR_SCRIPT} ${TARGET_PID} > "${MEMLOG}" 2>&1 &
            echo "running sh ${MEM_MONITOR_SCRIPT} ${TARGET_PID} > ${MEMLOG} 2>&1 &"

            # 等待程序运行结束
            wait ${TARGET_PID} || true

            # 程序结束后，kill掉内存监控脚本
            pkill -f "${MEM_MONITOR_SCRIPT}" || true
            
            echo "Completed run with BS=${BS}, MSL=${MSL}, MODEL=${MODEL}"
        done
    done
done