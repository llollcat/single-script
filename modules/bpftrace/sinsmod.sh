#!/bin/bash

if [ -f "$MODULES_DIR/bpftrace/nouse" ]; then
    return 0
fi


function on_init() {
    if command -v ./bpftrace >/dev/null 2>&1; then
        if sudo bpftrace -e 'BEGIN { printf("OK\n"); exit(); }' 2>/dev/null | grep -q "OK"; then
            return 0
        else
            echo "Ошибка: bpftrace не работает"
            return 2
        fi
        
    else
        echo "bpftrace отсутствует"
        return 3
    fi
}


function on_live() {
    echo Используется bpftrace https://github.com/bpftrace/bpftrace
    sudo nohup ./bpftrace ./bashreadline.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_Print_entered_bash_commands_system_wide.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./capable.bt -f 'text' -B 'full' -o "./$METRICS_DIR/Trace_security_capability_checks.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./execsnoop.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_new_processes_via_exec_syscalls.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./gethostlatency.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_hostlatensy.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./killsnoop.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_killsnoop.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./opensnoop.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_open_syscalls_filename.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./ppid_proc.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_new_processes_via_exec_syscalls_for_tree.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./setuids.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_setuid_syscall.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./tcpaccept.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_TCP_passive_connections_accept.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./tcpconnect.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_TCP_active_connections_connect.txt" >/dev/null 2>&1 &
    sudo nohup ./bpftrace ./threadsnoop.bt -f 'text' -B 'full' -o "$METRICS_DIR/Trace_New_thread_creation.txt" >/dev/null 2>&1 &
    
    return 0
}

function on_post_live() {
    sudo pkill -f bpftrace 2>/dev/null
    
    
    declare -a files=(
        "Trace_open_syscalls_filename.txt"
        "Trace_new_processes_via_exec_syscalls_for_tree.txt"
        "Trace_security_capability_checks.txt"
    )
    
    declare -a patterns=("bpftrace" "tuned" "pgrep" "ppid_proc")
    
    for file in "${files[@]}"; do
        path="$METRICS_DIR/$file"
        if [[ -f "$path" ]]; then
            for pattern in "${patterns[@]}"; do
                sed -i "/$pattern/d" "$path"
            done
        fi
    done
    
    return 0
}