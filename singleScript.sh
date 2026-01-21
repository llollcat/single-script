#!/bin/bash

set -Euo pipefail
shopt -s nullglob

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR" || exit 1

METRICS_DIR="$PWD"
MODULES_DIR="$PWD/modules"

declare -a holidays=(
    "01-01"
    "01-07"
    "02-23"
    "03-08"
    "05-01"
    "05-09"
    "06-12"
    "11-04"
)

is_holiday() {
    local today=$(date +%m-%d)
    for d in "${holidays[@]}"; do
        [[ "$d" == "$today" ]] && return 0
    done
    return 1
}

create_metric_folder() {
    local base="$1"
    local dir="$SCRIPT_DIR/$base"
    local i=0
    while :; do
        local candidate="${dir}${i:+$i}"
        if [ ! -d "$candidate" ] || [ -z "$(find "$candidate" -mindepth 1 -print -quit 2>/dev/null)" ]; then
            mkdir -p "$candidate"
            METRICS_DIR="$candidate"
            break
        fi
        i=$((i+1))
    done
    chmod 777 "$METRICS_DIR"
}


print_logo() {
  cat <<'EOF'
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▒▓▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▓▓▓███▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓███▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▒▒▒▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▓▓█▓▓▓▓▓▓▓▒▒▒▒▓▓   ▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓█▓▓▒▒▒▒▒▒▒▓▓▓█▒▒▒▒▒▒▒▒▒▒▒▓▒  ░ ░▓▓▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▓▓▓▓▒▒▒▒▓▓▓▓█▓▒▒▒▒▒▒▒▒▒▒▓▓▓  ░▒ ░▓▓▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▓▓░▒▒▓▒░░▒ ░▓▓▒▒▒▒▓▓▓█▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▓▓▒   ░▒▓▓▓░▒█▒▒▓▓▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒
▒▒▒▒▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒░   ▒▓▓▒█▓▓▓▓▒░░░█▓▒▒▒▒▒▒▒▒▒▒
▒▒▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▓▓░░░░░▒▓▒▓█▓▒▒▒▒▒▒▒▒▒▒
▒▒▓█▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒█▓░░░░░░▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▓█▓█▓▓▓▒▒▒▒▒▓▓▓▓▓▓▓▓▓▒▒▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▓▓▓▓▒▒▒▒▒▒▓▓▒▓█▓░▒▓▓▒░░▒▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒
▒▒▒▓▓▓█▓▓█▓▓▓▒▒▒▒▒▓▓▓▒▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓█▓▒▓▓▒▒▒▒▓█▓░░▒▓█▓░▒▒▓█▓▒▓▒░░░▒▒▓▓▓▒▒▒▒▒
▒▒▒▒▒▒▓▓▓▓█▓█▓▓▓▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓█▓▒▒▓▓▒▒▓▓▒▓▓▒░░▒▓█▓▒▓█▓ ░▓▓▒▒▒░ ░▒▓▓▓▒▒
▒▓▓▓▓▓▓▓▓▓▓▓▓▒▓██▓▓▓▒▒▒▒▒▓▓▒▒▒▒▓▓▒▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒█▓▒░▒▓█▓░░▒▓█▓▒▓▒  ░▓▒ ░░   ░▓▓▒
▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▓▒▒▓▓▒▒▓▒▒▒▒▓▓▒▒▒▒▒▓█▓▒▒▓██▓▒░▒▓█▓▓▓▓▒▒▒▓▒   ▓▓▒░░░░▒▓▓▒
▒▒▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▓▓▓▒▒▓█▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▓▓▒░▒█▓▓▓▓▓▓▒▒▒
▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▓▓▒▒▒▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓█▓▒▒▒▓█▓▓▓▓▓▓▓▓█▓▓▓▒▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒▒▒▒▓▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▓▓▓▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▓▓▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▓█▒▒▒▒▓▓░ ▒█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█░ ░█▓▒▒▒▓█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▒▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

EOF
}


run_modules_func() {
    local func="$1"
    
    for mod in $MODULES_DIR/*/sinsmod.sh; do
        [[ -f "$mod" ]] || continue
        (
            pushd "$(dirname "$mod")" >/dev/null
            unset -f $func
            source "$mod"
            if declare -F "$func" > /dev/null; then
                $func
            fi
            popd >/dev/null
        )
    done
}

pause() {
    local message="$1"
    while read -r -t 0; do :; done
    read -n 1 -s -p "${message}"
    echo
}

spinner() {
    local pid=$1
    local chars='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%c" "${chars:i++%${#chars}:1}"
        sleep 0.1
    done
    printf "\r"
}

snapshot_namespace() {
    declare -F | awk '{print $3}'
}

restore_namespace() {
    local before=("$@")
    local after
    mapfile -t after < <(declare -F | awk '{print $3}')
    for f in "${after[@]}"; do
        [[ " ${before[*]} " == *" $f "* ]] || unset -f "$f"
    done
}

main() {
    
    NO_TMUX=0
    for arg in "$@"; do
        case "$arg" in
            --no-tmux)
                NO_TMUX=1
            ;;
        esac
    done
    
    if [ -z "${STDBUF_APPLIED:-}" ]; then
        export STDBUF_APPLIED=1
        exec stdbuf -oL -eL "$0" "$@"
    fi
    
    if [[ "$EUID" -ne 0 ]]; then
        echo "Запрос повышения прав..."
        sudo "$0" "$@"
        exit $?
    fi
    
    if [[ "$NO_TMUX" -eq 0 && -z "${TMUX:-}" ]]; then
        if command -v tmux &> /dev/null; then
            tmux new-session -A -s sins "$0"
            exit $?
        else
            echo "tmux не установлен, пробуем установить."
            sudo apt update
            sudo apt install tmux -y
            if [[ $? -eq 0 ]]; then
                tmux new-session -A -s sins "$0"
                exit $?
            else
                echo "tmux не удалось установить, запуск без tmux."
            fi
        fi
    fi
    
    if is_holiday; then
        create_metric_folder "metric_holiday"
    else
        create_metric_folder "metric"
    fi
    
    chmod -R 777 $MODULES_DIR/*
    
    # on_init всех модулей
    for mod in $MODULES_DIR/*/sinsmod.sh; do
        [[ -f "$mod" ]] || continue
        pushd "$(dirname "$mod")" >/dev/null
        before=$(snapshot_namespace)
        source "$mod"
        if declare -F "on_init" > /dev/null; then
            on_init
            if [[ $? -eq 3 ]]; then
                pause "================= Ошибки, завершение работы ================="
                exit 3
            fi
        fi
        restore_namespace $before
        popd >/dev/null
    done
    
    print_logo
    
    stty sane
    stty erase ^H
    
    CHOICE=-1
    while true; do
        menu_action=()
        function_path=()
        menu_item_number=1
        for mod in $MODULES_DIR/*/sinsmod.sh; do
            [[ -f "$mod" ]] || continue
            before=$(snapshot_namespace)
            unset MENU_ITEMS
            source "$mod"
            if [[ -v MENU_ITEMS ]]; then
                for ((i=0; i<${#MENU_ITEMS[@]}; ++i)); do
                    menu_action+=("$menu_item_number")
                    menu_action+=("${MENU_ITEMS[i]}")
                    function_path+=("$menu_item_number")
                    function_path+=("$mod")
                    ((++menu_item_number))
                done
                unset MENU_ITEMS
            fi
            restore_namespace $before
        done
        
        echo ""
        echo "================= Меню ================="
        if ! [ -z "$CHOICE" ]; then
            for ((i=0; i<${#menu_action[@]}; i+=2)); do
                [[ $((i+1)) -lt ${#menu_action[@]} ]] && echo "${menu_action[i]}: ${menu_action[i+1]}"
            done
        fi
        
        read -p "Выберите опцию: " CHOICE
        [[ -z "$CHOICE" ]] && echo "Ничего не выбрано, попробуйте снова." && continue
        [[ "$CHOICE" -eq 0 ]] && echo "Завершение..." && exit 0
        
        menu_item_num=$(( (CHOICE-1)*2 + 1 ))
        pushd "$(dirname "${function_path[menu_item_num]}")" >/dev/null
        before=$(snapshot_namespace)
        unset -f on_menu
        source "${function_path[menu_item_num]}"
        on_menu "${menu_action[menu_item_num]}"
        restore_namespace $before
        popd >/dev/null
    done
}

main "$@"
