/*
 * compile with:
 * gcc [options] scrnsvr.c -o scrnsvr -lXss -lX11 -lpthread
*/

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <pthread.h>
#include <X11/extensions/scrnsaver.h>

#define pr(...) (fprintf(stderr,__VA_ARGS__))
#define ckea(x) (x[0] == '\0' || (x[0] == '-' && (x[1] == 'r' || x[1] == 'l' || x[1] == 'b'))) //check if required options exist
#define len(x) (sizeof(x)/sizeof(x[0]))
#define print_array(z,x) for(int y=0;y<z;y++)printf("%d element: %s\n",y,x[y]);

void child(void *ptr);
void slf(void *ptr);
void svf(char *cmd_saver);

void printUsage(){
		//pr("Usage: scrnsvr -[tearlswncc1c2c3c4c5xdDuU]\n\n");
		pr("Usage: scrnsvr [OPTIONS]\n\n");
		pr("--help\t\tShows this help\n\n");
		pr("-t [timeout]\ttime in seconds before [saver] gets activated (default: 120)\n");
		pr("-a [timeout]\ttime in seconds before [locker] gets activated AFTER [saver] has been activated (default: 30)\n");
		pr("-s [timeout]\ttime in seconds before [blanker] gets activated (default: 180)\n");
		pr("-r [saver]\t(REQUIRED) screensaver (e.g. an xscreensaver module)\n");
		pr("-l [locker]\t(REQUIRED) program that locks your screen\n");
		pr("-b [blanker]\t(REQUIRED) program that sets your screen off\n\n");
		pr("-w [list]\tSpace-separated case-insensitive list of windows titles which inhibit the screensaver (added to: youtube vlc mpv vimeo 'picture in picture')\n");
		pr("-n\t\tDisables 'Saving in ~n secs' notifications\n");
		pr("-c [notifier]\tCommand used to send notifications (if -n is NOT specified) (not uses different levels)\n");
		pr("-c1 [notifier]\tCommand used to send notifications when there is 1 second left(if -n is NOT specified)\n");
		pr("-c2 [notifier]\tCommand used to send notifications when there is 2 second left(if -n is NOT specified)\n");
		pr("-c3 [notifier]\tCommand used to send notifications when there is 3 second left(if -n is NOT specified)\n");
		pr("-c4 [notifier]\tCommand used to send notifications when there is 4 second left(if -n is NOT specified)\n");
		pr("-c5 [notifier]\tCommand used to send notifications when there is 5 second left(if -n is NOT specified)\n");
		pr("-x\t\tExecutes until the loop (without entering it) and exits\n");
		pr("-d\t\tShows debug info (Use -D,-u,-U for more levels of debugging)\n");
		exit(1);
}

struct child_struct
{
	int vpid;
	int time_saver;
	char *cmd_lock;
	pthread_t svr;
};
struct slf_struct
{
	int time_sleep;
	char *cmd_sleep;
};

int main(int argc, char *argv[])
{
	if(getuid() == 0){
		pr("\nYou should NOT run this as root. Press Control-C to cancel (10 seconds timeout)\n\n");
		sleep(10);
	}
	if(argc < 7){
		printUsage();
		return 1;
	}
	char saver[50] = "";
	char locker[50] = "";
	char sleeper[50] = "";
	char cmd_saver[60] = "";
	char cmd_lock[60] = "";
	char cmd_sleep[60] = "";
	char pgrep_lock[80] = "";
	char pgrep_sleep[80] = "";
	char notifier[50] = "";
	char notifier_1[50] = "";
	char notifier_2[50] = "";
	char notifier_3[50] = "";
	char notifier_4[50] = "";
	char notifier_5[50] = "";
	char cmd_wmctrl[500] = "wmctrl -l | grep -i -E '";
	int timeout = 120*1000;
	int time_saver = 30;
	int time_sleep = 180;
	int notifs = 1;
	int debug = 0;
	int debug_high = 0;
	int debug_ultra_high = 0;
	int debug_ultra_mega_high = 0;
	int can_lock_pa = 1;
	int can_lock_wm = 1;
	int exits = 0;
	char servs[100][50] = {"youtube", "vlc", "mpv", "vimeo", "picture in picture"};
	int len_servs = len(servs);
	int get_args = 0;
	int j = len_servs;
	j = 5; //number of precompiled services
	//if(debug_ultra_high == 1)printf("%s\n",cmd_parun);
	if(debug_ultra_mega_high == 1)printf("%p\n",cmd_wmctrl);
	//if(debug_ultra_mega_high == 1)printf("%p\n",cmd_parun);

	for(int i = 0; i < argc; i++){
		if(argv[i][0] == '-'){
			switch(argv[i][1]){
				case 't':
					if(argv[i+1])timeout = atoi(argv[i+1])*1000;
					else printUsage();
					break;
				case 'a':
					if(argv[i+1])time_saver = atoi(argv[i+1]);
					else printUsage();
					break;
				case 's':
					if(argv[i+1])time_sleep = atoi(argv[i+1]); //time before screen off
					else printUsage();
					break;
				case 'r':
					sprintf(saver, "%s", argv[i+1]);
					break;
				case 'l':
					sprintf(locker, "%s", argv[i+1]);
					break;
				case 'b':
					sprintf(sleeper, "%s", argv[i+1]);
					break;
				case 'n':
					notifs = 0;
					break;
				case 'c':
					switch(argv[i][2]){
						case '1':
							sprintf(notifier_1, "%s", argv[i+1]);
							break;
						case '2':
							sprintf(notifier_2, "%s", argv[i+1]);
							break;
						case '3':
							sprintf(notifier_3, "%s", argv[i+1]);
							break;
						case '4':
							sprintf(notifier_4, "%s", argv[i+1]);
							break;
						case '5':
							sprintf(notifier_5, "%s", argv[i+1]);
							break;
						case '\0':
							sprintf(notifier, "%s", argv[i+1]);
							break;
					}
					break;
				case 'x':
					exits = 1;
					break;
				case 'w':
					get_args = 1;
					break;
				case 'd':
					debug = 1;
					break;
				case 'D':
					debug = 1;
					debug_high = 1;
					break;
				case 'u':
					debug = 1;
					debug_high = 1;
					debug_ultra_high = 1;
					break;
				case 'U':
					debug = 1;
					debug_high = 1;
					debug_ultra_high = 1;
					debug_ultra_mega_high = 1;
					break;
				case '-':
					if(!strcmp(argv[i],"--help")){
						printUsage();
					}
					break;
				default:
					pr("Uknown option: %s. Use only '%s', or the switch '--help', to get a list of options\n",argv[i],argv[0]);
					exit(4);
			}
		}
		else if(get_args == 1){
			if(strlen(argv[i])>=50){
				pr("Argument '%s' of the -w flag is too long\n",argv[i]);
				exit(3);
			}
			strcpy(servs[j],argv[i]);
			if(debug_high == 1)printf("%s\n",argv[i]);
			j++;
		}
	}
	if(debug_ultra_high == 1)print_array(len(servs),servs);
	if(ckea(saver) || ckea(locker) || ckea(sleeper)){
		printUsage();
	}
	
	if(debug_high == 1)printf("notifier: %s\n",notifier);
	if(debug_high == 1)printf("notifier_1: %s\n",notifier_1);
	if(debug_high == 1)printf("notifier_2: %s\n",notifier_2);
	if(debug_high == 1)printf("notifier_3: %s\n",notifier_3);
	if(debug_high == 1)printf("notifier_4: %s\n",notifier_4);
	if(debug_high == 1)printf("notifier_5: %s\n",notifier_5);

	char pipe[] = "|";
	char devnull[] = "' >/dev/null";
	int i;
	for(i=0;i<len_servs;i++){
		if(debug_ultra_high == 1)printf("%s\n",servs[i]);
		if(debug_ultra_mega_high == 1)printf("%d\n",i);
		strcpy(pipe,"|");
		strcpy(devnull,"' >/dev/null");
		if(servs[i][0]){
			if(i==0){
				strcat(cmd_wmctrl,servs[i]);
			}else{
				strcat(cmd_wmctrl,strcat(pipe,servs[i]));
			}
		}
		if(debug_ultra_high == 1)printf("[%d]%s\n",i,cmd_wmctrl);
	}
	strcat(cmd_wmctrl,devnull);
	if(debug == 1)printf("%s\n",cmd_wmctrl);
	
	time_sleep -= (timeout/1000);
	sprintf(cmd_saver, "%s", saver);
	sprintf(cmd_lock, "%s &", locker);
	sprintf(cmd_sleep, "%s", sleeper);
	sprintf(pgrep_lock, "pgrep -x '%s' >/dev/null", locker);
	sprintf(pgrep_sleep, "pgrep -x '%s' >/dev/null", sleeper);

	if(debug_high == 1)printf("%s\n",cmd_saver);
	//execv(cmd_saver,0);
	if(debug_high == 1){
		printf("%s\n",locker);
		printf("%s\n",sleeper);
		printf("%s\n",cmd_lock);
		printf("%s\n",cmd_sleep);
		printf("%s\n",pgrep_lock);
		printf("%s\n",pgrep_sleep);
	}

	int dunstify = 0;
	int noti=system("dunstify --help > /dev/null 2>&1")/256;
	if(noti == 0){
		dunstify = 1;
		if(debug_ultra_high == 1)printf("noti = %d\n",noti);
	}
	else{
		noti=system("notify-send --help > /dev/null 2>&1")/256;
		if(noti == 0){
			dunstify = 2;
		}else if(notifier[0] == '\0' && notifier_1[0] == '\0' && notifier_2[0] == '\0' && notifier_3[0] == '\0' && notifier_4[0] == '\0' && notifier_5[0] == '\0'){
			notifs = 0;
		}
		if(debug_ultra_high == 1)printf("noti = %d\n",noti);
	}
	if(debug == 1)printf("dunstify = %d\n",dunstify);
	if(debug == 1)printf("notifs = %d\n",notifs);

	unsigned int milliseconds;
	milliseconds = 100;
	useconds_t useconds = milliseconds * 1000;
	int sys;
	Display *my_display = XOpenDisplay(NULL);

	int cpid = 69420;
	int spid = 69420;
	int vpid = 69420;

	pthread_t chi, sle, svr;
	struct child_struct args_child;
	struct slf_struct args_slf;

	args_child.vpid = vpid;
	args_child.svr = svr;
	args_child.time_saver = time_saver;
	args_child.cmd_lock = cmd_lock;
	
	args_slf.time_sleep = time_sleep;
	args_slf.cmd_sleep = cmd_sleep;
	
	char cmd_parun[] = "pactl list short | grep RUNNING >/dev/null";
	if(debug_high == 1)printf("%s\n",cmd_parun);
	if(exits == 1)exit(0);
	while(my_display){
		usleep(useconds);
		Display *my_display = XOpenDisplay(NULL);
		XScreenSaverInfo *info = XScreenSaverAllocInfo();
		XScreenSaverQueryInfo(my_display, DefaultRootWindow(my_display), info);
		can_lock_pa=system(cmd_parun)/256;
		can_lock_wm=system(cmd_wmctrl)/256;
		if(debug == 1)printf("can_lock_pa = %d\n",can_lock_pa);
		if(debug == 1)printf("can_lock_wm = %d\n",can_lock_wm);
		if(can_lock_pa == 1 || can_lock_wm == 1){
			if(info->idle >= timeout && info->idle <= timeout+180){
				sys=system(pgrep_lock)/256;
				if(debug_high == 1)printf("sys = %d\n",sys);
				if(sys == 1){
					if(spid != 69420){pthread_cancel(sle);}
					if(cpid != 69420){pthread_cancel(chi);}
					if(vpid != 69420){pthread_cancel(svr);}
					vpid=pthread_create(&svr,NULL,(void *)&svf, (void *)cmd_saver);
					cpid=pthread_create(&chi,NULL,(void *)&child, (void *)&args_child);
					spid=pthread_create(&sle,NULL,(void *)&slf, (void *)&args_slf);
				}else{
					printf("locker running\n");
					if(spid != 69420){pthread_cancel(sle);}
					spid=pthread_create(&sle,NULL,(void *)&slf, (void *)&args_slf);
				}
			}
			else if(info->idle < timeout){
				sys=system(pgrep_lock)/256;
				if(debug_high == 1)printf("sys = %d\n",sys);
				if(sys == 1){
					if(notifs == 1){
						if(info->idle >= timeout-1000){ //1 sec
							if(notifier_1[0] == '\0'){
								if(notifier[0] == '\0'){
									if(dunstify == 1)system("dunstify -r 3 -u C -t 200 -a scrnsvr 'Saving in ~1 sec'");
									else if(dunstify == 2)system("notify-send -u critical -t 200 -a scrnsvr 'Saving in ~1 sec'");
								}
								else system(notifier);
							}
							else system(notifier_1);
						}
						else if(info->idle >= timeout-2000){ //2 secs
							if(notifier_2[0] == '\0'){
								if(notifier[0] == '\0'){
									if(dunstify == 1)system("dunstify -r 3 -u C -t 200 -a scrnsvr 'Saving in ~2 secs'");
									else if(dunstify == 2)system("notify-send -r 3 -u C -t 200 -a scrnsvr 'Saving in ~2 secs'");
								}
								else system(notifier);
							}
							else system(notifier_2);
						}
						else if(info->idle >= timeout-3000){ //3 secs
							if(notifier_3[0] == '\0'){
								if(notifier[0] == '\0'){
									if(dunstify == 1)system("dunstify -r 3 -u C -t 200 -a scrnsvr 'Saving in ~3 secs'");
									else if(dunstify == 2)system("notify-send -r 3 -u C -t 200 -a scrnsvr 'Saving in ~3 secs'");
								}
								else system(notifier);
							}
							else system(notifier_3);
						}
						else if(info->idle >= timeout-4000){ //4 secs
							if(notifier_4[0] == '\0'){
								if(notifier[0] == '\0'){
									if(dunstify == 1)system("dunstify -r 3 -u C -t 200 -a scrnsvr 'Saving in ~4 secs'");
									else if(dunstify == 2)system("notify-send -r 3 -u C -t 200 -a scrnsvr 'Saving in ~4 secs'");
								}
								else system(notifier);
							}
							else system(notifier_4);
						}
						else if(info->idle >= timeout-5000){ //5 secs
							if(notifier_5[0] == '\0'){
								if(notifier[0] == '\0'){
									if(dunstify == 1)system("dunstify -r 3 -u C -t 200 -a scrnsvr 'Saving in ~5 secs'");
									else if(dunstify == 2)system("notify-send -r 3 -u C -t 200 -a scrnsvr 'Saving in ~5 secs'");
								}
								else system(notifier);
							}
							else system(notifier_5);
						}
					}
					if(debug_ultra_mega_high == 1)printf("%d %d\n",cpid,spid);
					if(spid != 69420){pthread_cancel(sle);}
					if(cpid != 69420){pthread_cancel(chi);}
					if(vpid != 69420){pthread_cancel(svr);}
				}
			}
		}
		//printf("%lu\n", (*info).idle);
		printf("%lu\n", info->idle);
		XCloseDisplay(my_display);
	}
	return 0;
}
void svf(char *cmd_saver){
	system(cmd_saver);
}
void child(void *ptr){
	printf("forked\n");
	struct child_struct *args = ptr;
	sleep(args->time_saver);
	printf("locked\n");
	system(args->cmd_lock);
	if(args->vpid != 69420){pthread_cancel(args->svr);}
}
void slf(void *ptr){
	struct slf_struct *args = ptr;
	sleep(args->time_sleep);
	printf("off\n");
	system(args->cmd_sleep);
}
