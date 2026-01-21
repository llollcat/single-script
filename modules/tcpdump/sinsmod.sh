#!/bin/bash

function on_init() {
    if command -v tcpdump >/dev/null 2>&1; then
        return 0
    else
        echo "tcpdump отсутствует. Попытка установки..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y tcpdump
            if command -v tcpdump >/dev/null 2>&1; then
                echo "tcpdump успешно установлен."
                return 0
            else
                echo "Не удалось установить tcpdump."
                return 3
            fi
        else
            echo "Менеджер пакетов apt не найден. Установку выполнить невозможно."
            return 3
        fi
    fi
}


function on_live() {
    sudo killall tcpdump 2>/dev/null
    TCPDUMP_SAVE_NAME="${METRICS_DIR}/tcpdump_$(date +"%H-%M-%S_%d-%m-%Y").pcap"
    
    touch "$TCPDUMP_SAVE_NAME"
    chmod 777 "$TCPDUMP_SAVE_NAME"
    sudo nohup tcpdump -w "$TCPDUMP_SAVE_NAME" >/dev/null 2>&1 &
    
    return 0
}

function on_post_live() {
    sudo killall tcpdump 2>/dev/null
    return 0
}