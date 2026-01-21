#!/bin/bash

if [ -f "$MODULES_DIR/kunai/nouse" ]; then
    return 0
fi


function on_init() {
    local kernel
    kernel=$(uname -r | cut -d'-' -f1)
    
    local major minor
    major=$(echo "$kernel" | cut -d'.' -f1)
    minor=$(echo "$kernel" | cut -d'.' -f2)
    local version="${major}.${minor}"
    
    
    
    if [[ "$major" -eq 5 && "$minor" -eq 4 ]]; then
        return 0
    fi
    
    if [[ "$major" -eq 5 && "$minor" -eq 15 ]]; then
        return 0
    fi
    
    # Проверка диапазона 5.18–6.6 (Arch)
    if [[ "$major" -eq 5 && "$minor" -ge 18 ]]; then
        return 0
    fi
    if [[ "$major" -eq 6 && "$minor" -le 6 ]]; then
        return 0
    fi
    
    if (( major < 5 )) || ( [[ "$major" -eq 5 ]] && [[ "$minor" -lt 4 ]] ); then
        return 2
    fi
    
    if [[ "$major" -gt 6 ]] || ( [[ "$major" -eq 6 ]] && [[ "$minor" -gt 6 ]] ); then
        return 1
    fi
    
    return 2
}
KUNAI_LOG_NAME=${METRICS_DIR}/kunai_$(date +"%H-%M-%S_%d-%m-%Y").log
export KUNAI_LOG_NAME
config="$(envsubst < "$MODULES_DIR/kunai/config_for_parce.yaml")"
export -n KUNAI_LOG_NAME

function on_live() {
    echo Используется Kunai https://why.kunai.rocks/docs/quickstart/
    echo "$config" > ./config.yaml
    sudo nohup ./kunai-amd64 run -c ./config.yaml >/dev/null 2>&1 &
    return 0
}


function on_post_live() {
    sudo pkill -f kunai 2>/dev/null
    return 0
}