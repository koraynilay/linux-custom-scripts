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
#define pr(x) (fprintf(stderr, x))
#define ckea(x) (x[0] == '\0' || (x[0] == '-' && (x[1] == 'r' || x[1] == 'l' || x[1] == 's')))

void child(void *ptr);
void slf(void *ptr);
void svf(char *cmd_saver);

void printUsage(){
		pr("Usage: scrnsvr [OPTIONS]\n\n");
		pr("-t [timeout]\t\ttime in seconds before [saver] gets activated (default: 120)\n");
		pr("-a [timeout]\t\ttime in seconds before [blanker] gets activated (default: 180)\n");
		pr("-e [timeout]\t\ttime in seconds before [locker] gets activated AFTER [saver] has been activated (default: 30)\n");
		pr("-r [saver]\t\t(REQUIRED) screensaver (e.g. an xscreensaver module)\n");
		pr("-l [locker]\t\t(REQUIRED) program that locks your screen\n");
		pr("-s [blanker]\t\t(REQUIRED) program that sets your screen off\n");
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
	int timeout = 120*1000;
	int time_saver = 30;
	int time_sleep = 180;

	for(int i = 0; i < argc; i++){
		if(argv[i][0] == '-'){
			switch(argv[i][1]){
				case 't':
					if(argv[i+1])timeout = atoi(argv[i+1])*1000;
					else printUsage();
					break;
				case 'e':
					if(argv[i+1])time_saver = atoi(argv[i+1]);
					else printUsage();
					break;
				case 'a':
					if(argv[i+1])time_sleep = atoi(argv[i+1]); //time before screen off
					else printUsage();
					break;
				case 'r':
					sprintf(saver, "%s", argv[i+1]);
					break;
				case 'l':
					sprintf(locker, "%s", argv[i+1]);
					break;
				case 's':
					sprintf(sleeper, "%s", argv[i+1]);
					break;
			}
		}
	}
	if(ckea(saver) || ckea(locker) || ckea(sleeper)){
		printUsage();
	}
	
	time_sleep -= (timeout/1000);
	sprintf(cmd_saver, "%s", saver);
	sprintf(cmd_lock, "%s &", locker);
	sprintf(cmd_sleep, "%s", sleeper);
	sprintf(pgrep_lock, "pgrep -x '%s' >/dev/null", locker);
	sprintf(pgrep_sleep, "pgrep -x '%s' >/dev/null", sleeper);

	//debug printf("%s\n",cmd_saver);
	//execv(cmd_saver,0);
/*debug
 	printf("%s\n",locker);
	printf("%s\n",sleeper);
	printf("%s\n",cmd_lock);
	printf("%s\n",cmd_sleep);
	printf("%s\n",pgrep_lock);
	printf("%s\n",pgrep_sleep);
	printf("%s\n",kill_sleep);
debug*/

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
	
	while(my_display){
		usleep(useconds);
		Display *my_display = XOpenDisplay(NULL);
		XScreenSaverInfo *info = XScreenSaverAllocInfo();
		XScreenSaverQueryInfo(my_display, DefaultRootWindow(my_display), info);

		if(info->idle >= timeout && info->idle <= timeout+180){
			sys=system(pgrep_lock)/256;
	//		printf("sys = %d\n",sys);
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
	//		printf("sys = %d\n",sys);
			if(sys == 1){
				if(info->idle >= timeout-1000){ //1 sec
					system("dunstify -r 3 -u C -t 200 -a scrnsvr 'Locking in ~1 sec'");
				}
				else if(info->idle >= timeout-2000){ //2 secs
					system("dunstify -r 3 -u C -t 200 -a scrnsvr 'Locking in ~2 secs'");
				}
				else if(info->idle >= timeout-3000){ //3 secs
					system("dunstify -r 3 -u C -t 200 -a scrnsvr 'Locking in ~3 secs'");
				}
				else if(info->idle >= timeout-4000){ //4 secs
					system("dunstify -r 3 -u N -t 200 -a scrnsvr 'Locking in ~4 secs'");
				}
				else if(info->idle >= timeout-5000){ //5 secs
					system("dunstify -r 3 -u N -t 200 -a scrnsvr 'Locking in ~5 secs'");
				}
				//debug printf("%d %d\n",cpid,spid);
				if(spid != 69420){pthread_cancel(sle);}
				if(cpid != 69420){pthread_cancel(chi);}
				if(vpid != 69420){pthread_cancel(svr);}
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
