#!/bin/bash

function on_init() {
    
    # Проверка наличия утилиты date
    if ! command -v date &> /dev/null; then
        echo "утилита 'date' не установлена"
        return 1
    fi
    
    # Проверка наличия утилиты timedatectl
    if ! command -v timedatectl &> /dev/null; then
        echo "утилита 'timedatectl' не установлена"
        return 1
    fi
    
    # Проверка наличия утилиты zip
    if ! command -v zip &> /dev/null; then
        echo "утилита 'zip' не установлена. Пытаемся установить..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y zip
            if ! command -v zip &> /dev/null; then
                echo "Не удалось установить 'zip'"
                return 1
            fi
        else
            echo "Пакетный менеджер apt не найден. Установите 'zip' вручную"
            return 1
        fi
    fi
    
    return 0
}



function change_date_on_holiday() {
    current_date=$(date +%m-%d)
    current_year=$(date +%Y)
    current_time=$(date +%H:%M:%S)
    
    # Проверка, является ли текущая дата праздничной
    for holiday in "${holidays[@]}"; do
        if [[ "$holiday" == "$current_date" ]]; then
            echo "Сегодня уже праздничная дата ($holiday), смена даты не требуется."
            return 0
        fi
    done
    
    nearest_holiday=""
    nearest_diff=366
    nearest_date=""
    
    for holiday in "${holidays[@]}"; do
        if [[ "$holiday" > "$current_date" ]]; then
            diff=$(( $(date -d "$current_year-$holiday" +%s) - $(date -d "$current_year-$current_date" +%s) ))
            diff=$(( diff / 86400 ))
            
            if (( diff < nearest_diff )); then
                nearest_diff=$diff
                nearest_holiday=$holiday
                nearest_date="$current_year-$holiday $current_time"
            fi
        fi
    done
    
    if [[ -z "$nearest_holiday" ]]; then
        next_year=$((current_year + 1))
        nearest_holiday=${holidays[0]}
        nearest_date="$next_year-$nearest_holiday $current_time"
    fi
    
    # Отключаем NTP перед установкой времени
    if ! sudo timedatectl set-ntp false; then
        echo "Не удалось отключить синхронизацию времени через NTP (timedatectl)."
        return 2
    fi
    
    # Установка системного времени
    if ! sudo date -s "$nearest_date" >/dev/null 2>&1; then
        echo "Ошибка при обновлении системного времени."
        return 2
    fi
    
    
    system_time=$(date +'%Y-%m-%d %H:%M:%S')
    hardware_time=$(sudo hwclock --show | awk '{print $1 " " $2}')
    
    echo "Системное время установлено: $system_time"
    echo "Аппаратное время: $hardware_time"
    
    return 0
}



MENU_ITEMS=("BEFORE" "LIVE" "AFTER" "RESERVED" "ARCHIVE" "DATE" "Проверить обновления модулей")
function on_menu(){
    local menu_item="$1"
    
    folder_created=false
    case $menu_item in
        "BEFORE")
            run_modules_func on_pre_before
            
            echo "Before запущен... " $(date +"%H:%M:%S %d-%m-%Y")
            run_modules_func on_before
            
            run_modules_func on_post_before
        ;;
        "LIVE")
            run_modules_func on_pre_live
            
            echo "Live запущен... " $(date +"%H:%M:%S %d-%m-%Y")
            run_modules_func on_live
            
            pause "Для завершения снятия Live нажмите Enter:"
            
            run_modules_func on_post_live
            
        ;;
        
        "AFTER")
            run_modules_func on_pre_after
            
            echo "After запущен... " $(date +"%H:%M:%S %d-%m-%Y")
            run_modules_func on_after
            
            run_modules_func on_post_after
        ;;
        
        "RESERVED")
            echo "Зарезервированно
        ;;
        
        
        "ARCHIVE")
            pushd "$(dirname "${function_path[menu_item_num]}")" >/dev/null
            
            cd $SCRIPT_DIR
            ZIP_NAME="$(basename "$METRICS_DIR")"
            zip -r "$SCRIPT_DIR/$ZIP_NAME.zip" "$ZIP_NAME"
            chmod 777 "$SCRIPT_DIR/$ZIP_NAME.zip"
            popd >/dev/null
            
        ;;
        
        "DATE")
            change_date_on_holiday
            exit 0
        ;;
        
        "Проверить обновления модулей")
            run_modules_func on_update_ask
        ;;
        *)
            echo "Неизвестная команда"
        ;;
    esac
    
    chmod 777 -R $METRICS_DIR
}