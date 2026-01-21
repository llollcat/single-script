#!/bin/bash


MENU_ITEMS=()
if [ -d "$MODULES_DIR/kunai" ] && [ -d "$MODULES_DIR/bpftrace" ]; then
    if [ -f "$MODULES_DIR/bpftrace/nouse" ]; then
        MENU_ITEMS=("Использовать bpf")
        elif [ -f "$MODULES_DIR/kunai/nouse" ]; then
        MENU_ITEMS=("Использовать kunai")
    else
        touch "$MODULES_DIR/bpftrace/nouse" 2>/dev/null
    fi
fi

function on_menu(){
    local menu_item="$1"
    case $menu_item in
        "Использовать kunai")
            rm "$MODULES_DIR/kunai/nouse" 2>/dev/null
            touch "$MODULES_DIR/bpftrace/nouse" 2>/dev/null
        ;;
        "Использовать bpf")
            touch "$MODULES_DIR/kunai/nouse" 2>/dev/null
            rm "$MODULES_DIR/bpftrace/nouse" 2>/dev/null
        ;;
    esac
}