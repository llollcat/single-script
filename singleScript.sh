#!/bin/bash

#source: https://gitlab.lab.local/lazin-mp/single-script-linux

source ./checker.sh
METRICS_DIR="./metric"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TCPDUMP_SAVE_NAME="${METRICS_DIR}/cap_${TIMESTAMP}.pcap"
CALCULATE_HASHES=true

# Массив соответствия утилиты и имени bpftrace
declare -a BPF_SCRIPTS=(
	"capable.bt:Trace_security_capability_checks.txt"
	"execsnoop.bt:Trace_new_processes_via_exec_syscalls.txt"
	"tcpaccept.bt:Trace_TCP_passive_connections_accept.txt"
	"tcpconnect.bt:Trace_TCP_active_connections_connect.txt"
	"bashreadline.bt:Trace_Print_entered_bash_commands_system_wid.txt"
	"opensnoop.bt:Trace_open_syscalls_filename.txt"
	"setuids.bt:Trace_setuid_syscall.txt"
	"threadsnoop.bt:Trace_New_thread_creation.txt"
	"killsnoop.bt:Trace_killsnoop.txt"
	"gethostlatency.bt:Trace_hostlatensy.txt"
	"ppid_proc.bt:Trace_new_processes_via_exec_syscalls_for_tree.txt"
)

function run_checker() {
	local name=$1
	checker_name="${METRICS_DIR}/${name}_$(date +"%Y%m%d_%H%M%S").txt"
	touch "$checker_name"
	call_each2 > "$checker_name"
	if [[ "$CALCULATE_HASHES" == "true" ]]; then
		echo "Считаем хеши..."
		generate_md5sum_baseline > "$checker_name"
	fi
}

function change_date() {
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
		exit 1
	fi

	# Установка системного времени
	if ! sudo date -s "$nearest_date" >/dev/null 2>&1; then
		echo "Ошибка при обновлении системного времени."
		exit 1
	fi

	# Синхронизация аппаратного времени
	if ! sudo hwclock --systohc >/dev/null 2>&1; then
		echo "Ошибка при синхронизации аппаратного времени."
		exit 1
	fi

	system_time=$(date +'%Y-%m-%d %H:%M:%S')
	hardware_time=$(sudo hwclock --show | awk '{print $1 " " $2}')

	echo "Системное время установлено: $system_time"
	echo "Аппаратное время: $hardware_time"

	TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
	TCPDUMP_SAVE_NAME="${METRICS_DIR}/cap_${TIMESTAMP}.pcap"
}



function run_tcpdump() {
	sudo killall tcpdump 2>/dev/null
	sudo rm -rf $TCPDUMP_SAVE_NAME
	
	touch "$TCPDUMP_SAVE_NAME"
	chmod 777 "$TCPDUMP_SAVE_NAME"
	sudo nohup tcpdump -w "$TCPDUMP_SAVE_NAME" >/dev/null 2>&1 &
}

function end_metric() {
	sudo pkill -f bpftrace 2>/dev/null
	sudo killall tcpdump 2>/dev/null

}

function run_bpftrace() {
	killall bpftrace 2>/dev/null || true
	for entry in "${BPF_SCRIPTS[@]}"; do
		IFS=':' read -r script output <<< "$entry"
		nohup "./$script" -f 'text' -B 'full' -o "$METRICS_DIR/$output" >/dev/null 2>&1 &
	done
}


function clear_bpf() {
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
}


function show_menu() {
	echo "Считать хеши?: $CALCULATE_HASHES"
	echo "Выберите действие:"
	echo "1) Снятие Before, Live, After с помощью bpf"
	echo "2) Снятие Before, Live, After на праздничную дату с помощью bpf"
	echo "3) Снятие только Live, After с помощью bpf"
	echo "4) Снятие только After"
	echo "5) Включить/выключить снятие хешей"
	echo "0) Выход"
}

function main() {
	echo "Проблемы/предложения: https://gitlab.lab.local/lazin-mp/single-script-linux/-/issues"
	if [[ "$EUID" -ne 0 ]]; then
		echo "Пожалуйста, запустите скрипт от имени root (sudo)."
		exit 1
	fi


	chmod 777 ./*
	
	while true; do
		show_menu
		read -p "Введите номер: " choice
		
		case $choice in
			2) 
				echo "Меняем дату:"
				change_date;&
			1)	
				if [ -d "$METRICS_DIR" ]; then
					read -p "Папка $METRICS_DIR уже существует, удалить? y/n " is_delete
					lower_is_delete=$(echo "$is_delete" | tr '[:upper:]' '[:lower:]')  # Переводим в lowercase
					if [ "$lower_is_delete" = "y" ]; then
						sudo rm -rf "$METRICS_DIR"
					else
						echo "Не удаляем, выходим."
						exit 0
					fi
				fi
				
				mkdir -p "$METRICS_DIR"
				chmod 777 --recursive $METRICS_DIR
				echo "Снятие Before:"
				run_checker "Before"
				# pause
				read -n 1 -s -r -p "Для начала снятия Live нажмите Enter:"
				echo ""
				echo "Live запущен...";&
			3)	
				mkdir -p "$METRICS_DIR"
				chmod 777 --recursive $METRICS_DIR

				run_bpftrace
				run_tcpdump
				# pause
				read -n 1 -s -r -p "Для окончания снятия Live нажмите Enter:"
				echo ""
				end_metric
				clear_bpf;&

			4)					
				mkdir -p "$METRICS_DIR"
				chmod 777 --recursive $METRICS_DIR
				echo "Снимаем After:"
				run_checker "After"
				echo "Снятие метрик завершено!"
				chmod 777 --recursive $METRICS_DIR;;
			5) 
				((CALCULATE_HASHES=!CALCULATE_HASHES));;

			0) exit 0;;
			*) echo "Неверный выбор, попробуйте снова.";;
		esac
		echo ""
	done
}

main