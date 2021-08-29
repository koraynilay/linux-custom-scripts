#!/bin/sh
ns=/tmp/dsstream-null-sink # null sink
lm=/tmp/dsstream-loopback-mic # loopback mic
la=/tmp/dsstream-loopback-apps # loopback apps/audio
case $1 in
	on|start)dsstreamon;;
	off|stop)dsstreamoff;;
esac
dsstream(){
	pactl load-module module-null-sink sink_name=dsstream sink_properties=device.description=dsstream > "$ns"
	pactl load-module module-loopback source=PulseEffects_mic.monitor sink=dsstream > "$lm"
	pactl load-module module-loopback source=PulseEffects_apps.monitor sink=dsstream > "$la"
}
dsstream(){
	pactl unload-module $(cat "$ns")
	pactl unload-module $(cat "$lm")
	pactl unload-module $(cat "$la")
}
