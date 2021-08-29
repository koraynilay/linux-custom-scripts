#!/bin/sh
ns=99999 # null sink
lm=99999 # loopback mic
la=99999 # loopback apps/audio
case $1 in
	on|start)dsstreamon;;
	off|stop)dsstreamoff;;
esac
dsstream(){
	ns=$(pactl load-module module-null-sink sink_name=dsstream sink_properties=device.description=dsstream)
	lm=$(pactl load-module module-loopback source=PulseEffects_mic.monitor sink=dsstream)
	la=$(pactl load-module module-loopback source=PulseEffects_apps.monitor sink=dsstream)
}
dsstream(){
	pactl unload-module $ns
	pactl unload-module $lm
	pactl unload-module $la
}
