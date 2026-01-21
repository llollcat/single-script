#!/bin/bash

CALCULATE_HASHES=true

function on_init() {
    if command -v ./checker.sh >/dev/null 2>&1; then
        return 0
    else
        echo "checker.sh отсутствует"
        return 3
    fi
}


function run_checker(){
    local name=$1
    source ./checker.sh
    
    echo "Checker запущен    https://github.com/rebootuser/LinEnum"
    checker_name="${METRICS_DIR}/${name}_$(date +"%H-%M-%S_%d-%m-%Y").txt"
    touch "$checker_name"
    # Do not add spinner $! unless breaking checker
    call_each2 >> "$checker_name" 2>/dev/null
    
    if [[ "$CALCULATE_HASHES" == "true" ]]; then
        echo "Считаем хеши. 5 минут в среднем. Папка Share не должна быть примонтирована"
        generate_md5sum_baseline >> "$checker_name"  2>/dev/null &
        spinner $!
    fi
    
    return 0
}


function on_before() {
    run_checker before
    return 0
}


function on_after() {
    run_checker after
    
    return 0
}