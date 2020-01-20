#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <X11/extensions/scrnsaver.h>

int main(int argc, char *argv[])
{
	if(argc < 4){
		printf("Usage: scrnsvr [timeout] [locker] [sleeper]\ntimeout\t\ttime in seconds before [locker] gets activated\nlocker\t\tprogram that locks your screen\nsleeper\t\tprogram that sets your screen off\n");
		return 1;
	}
	char locker[50];
	char sleeper[50];
	char cmd_lock[60];
	char cmd_sleep[60];
	char pgrep_lock[70];
	char pgrep_sleep[70];
	char kill_sleep[80];
	sprintf(locker, "%s", argv[2]);
	sprintf(sleeper, "%s", argv[3]);
	sprintf(cmd_lock, "%s &", locker);
	sprintf(cmd_sleep, "%s &", sleeper);
	sprintf(pgrep_lock, "pgrep -x %s", locker);
	sprintf(pgrep_sleep, "pgrep -x %s", sleeper);
	sprintf(kill_sleep, "killall -SIGKILL %s", sleeper);
	unsigned int milliseconds;
	milliseconds = 500;
	useconds_t useconds = milliseconds * 1000;
	int timeout;
	int sys;
	timeout = atoi(argv[1])*1000;
	Display *my_display = XOpenDisplay(NULL);
	while(my_display){
		usleep(useconds);
		Display *my_display = XOpenDisplay(NULL);
		XScreenSaverInfo *info = XScreenSaverAllocInfo();
		XScreenSaverQueryInfo(my_display, DefaultRootWindow(my_display), info);
		if(info->idle >= timeout && info->idle <= timeout+600){
			sys=system(pgrep_lock)/256;
			printf("sys = %d\n",sys);
			if(sys == 1){
				system(cmd_lock);
				system(kill_sleep);
				system(cmd_sleep);
			}else{
				printf("locker running\n");
				system(kill_sleep);
				system(cmd_sleep);
			}
		}
		else if(info->idle < timeout){
			sys=system(pgrep_lock)/256;
			printf("sys = %d\n",sys);
			if(sys == 1){
				if(info->idle >= timeout-5000){
					if(info->idle >= timeout-4000){
						if(info->idle >= timeout-3000){
							if(info->idle >= timeout-2000){
								if(info->idle >= timeout-1000){
									system("dunstify -r 3 -u CRITICAL -t 600 -a scrnsvr \"Locking in ~1 sec\"");
								}else{
									system("dunstify -r 3 -u CRITICAL -t 600 -a scrnsvr \"Locking in ~2 sec\"");
								}
							}else{
								system("dunstify -r 3 -u CRITICAL -t 600 -a scrnsvr \"Locking in ~3 sec\"");
							}
						}else{
							system("dunstify -r 3 -u NORMAL -t 600 -a scrnsvr \"Locking in ~4 sec\"");
						}
					}else{
						system("dunstify -r 3 -u NORMAL -t 600 -a scrnsvr \"Locking in ~5 sec\"");
					}
				}
				system(kill_sleep);
			}
		}
		printf("%lu\n", (*info).idle);
		XCloseDisplay(my_display);
	}
	return 0;
}
