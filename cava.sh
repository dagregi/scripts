#!/bin/bash

bar="▁▂▃▄▅▆▇█"
dict="s/;//g;"
config_file="/tmp/polybar_cava_config"
cava_pid=""

for i in $(seq 0 7); do
	dict="${dict}s/$i/${bar:$i:1}/g;"
done

cat >"$config_file" <<EOF
[general]
bars = 16

[input]
method = fifo
source = /tmp/mpd.fifo

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

start_cava() {
	cava -p "$config_file" | while read -r line; do
		echo "$line" | sed "$dict"
	done &
	cava_pid=$!
}

stop_cava() {
	if [ -n "$cava_pid" ]; then
		kill "$cava_pid" 2>/dev/null
		cava_pid=""
		sleep 0.1
		echo
	fi
}

last_state=""

while true; do
	state=$(mpc status | awk 'NR==2 {print $1}' | tr -d '[]')

	if [ "$state" = "playing" ]; then
		if [ "$last_state" != "playing" ]; then
			start_cava
			last_state="playing"
		fi
	else
		if [ "$last_state" = "playing" ]; then
			stop_cava
			last_state="$state"
		fi
	fi

	sleep 1
done
