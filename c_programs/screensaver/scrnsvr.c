/*
 * compile with:
 * gcc [options] scrnsvr.c -o scrnsvr -lXss -lX11 -lpthread
 *
 * OR for full RELRO (more info: https://www.redhat.com/en/blog/hardening-elf-binaries-using-relocation-read-only-relro)
 *
 * gcc -g -O0 -Wl,-z,relro,-z,now [options] scrnsvr.c -o scrnsvr -lXss -lX11 -lpthread
*/
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <pthread.h>
#include <X11/extensions/scrnsaver.h>
#include <X11/Xutil.h>
#include <ctype.h> //for isspace()
#include <sysexits.h> //for some exit statuses (see RETURN_CODES.txt)

#define pr(...) (fprintf(stderr,__VA_ARGS__)) //print errors to stderr
#define ckea(x) (x[0] == '\0' || (x[0] == '-' && (x[1] == 'r' || x[1] == 'l' || x[1] == 'b'))) //check if required options exist
#define len(x) (sizeof(x)/sizeof(x[0])) //array length
#define print_array(z,x) for(int y=0;y<z;y++)printf("%d element: %s\n",y,x[y]); //print every array element
#define pd() (printf("\nciao\n"))
#define compare_key(x) (!strcmp(k,x))
#define ACTIVATED "Enabled"
#define DEACTIVATED "Disabled"
#define HOME "HOME"
#define COMMENT_COLON ';'
#define COMMENT_HASH '#'

void child(void *ptr);
void slf(void *ptr);
void svf(char *cmd_saver);
char *strtrm(char *str);
int xerrh(Display *d,XErrorEvent *e);

void printUsage(){ 
		//pr("Usage: scrnsvr -[tearlswncc1c2c3c4c5xdDuU]\n\n");
		pr("Usage: scrnsvr [OPTIONS]\n\n");
		pr("--help\t\tShows this help\n\n");
		pr("--config [file]\tSpecify custom config file (absolute path, default: $HOME/.config/scrnsvr.ini)\n");
		pr("--copy-config\tCopy a demo config to $HOME/.config/scrnsvr.ini\n");
		pr("-t [timeout]\tTime in seconds before [saver] gets activated (default: 120)\n");
		pr("-a [timeout]\tTime in seconds before [locker] gets activated AFTER [saver] has been activated (default: 30)\n");
		pr("-s [timeout]\tTime in seconds before [blanker] gets activated (default: 180)\n");
		pr("-r [saver]\t(REQUIRED) Screensaver (e.g. an xscreensaver module)\n");
		pr("-l [locker]\t(REQUIRED) Program that locks your screen\n");
		pr("-b [blanker]\t(REQUIRED) Program that blanks/sets your screen off\n\n");
		pr("-w [list]\tSpace-separated case-insensitive list of windows titles which inhibit the screensaver (added to: youtube vlc mpv vimeo 'picture in picture')\n");
		pr("-n\t\tDisables 'Saving in ~n secs' notifications\n");
		pr("-i  [pixels]\tPixels of windows borders (if you want to consider fullscreen also windows that have the same geometry as the display but aren't actually fullscreen)\n");
		pr("-c  [notifier]\tCommand used to send notifications (if -n is NOT specified) (not uses different levels)\n");
		pr("-c1 [notifier]\tCommand used to send notifications when there is 1 second left(if -n is NOT specified)\n");
		pr("-c2 [notifier]\tCommand used to send notifications when there is 2 second left(if -n is NOT specified)\n");
		pr("-c3 [notifier]\tCommand used to send notifications when there is 3 second left(if -n is NOT specified)\n");
		pr("-c4 [notifier]\tCommand used to send notifications when there is 4 second left(if -n is NOT specified)\n");
		pr("-c5 [notifier]\tCommand used to send notifications when there is 5 second left(if -n is NOT specified)\n");
		pr("-x\t\tExecutes until the loop (without entering it) and exits\n");
		pr("-f\t\tDisables the detection of the fullscreen state of the current focused window\n");
		pr("-v\t\tPrints selected options (even if defaulted)\n");
		pr("-d\t\tShows debug info (Use -D,-u,-U for more levels of debugging)\n");
}

struct child_struct //struct for thread locker arguments
{
	int vpid;
	int time_saver;
	char *cmd_lock;
	pthread_t svr;
};
struct slf_struct //struct for thread sleeper arguments
{
	int time_sleep;
	char *cmd_sleep;
};

int main(int argc, char *argv[])
{
	if(getuid() == 0){ //check if root
		pr("\nYou should NOT run this program as root. Press Control-C to cancel (10 seconds timeout, then continue running as normal)\n\n");
		sleep(10);
	}
	char saver[50] = "";
	char locker[50] = "";
	char sleeper[50] = ""; //it's called blanker in the switch
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
	int timeout = 120*1000;
	int time_saver = 30;
	int time_sleep = 180;
	int notifs = 1;
	int print_opts = 0;
	int debug = 0;
	int debug_high = 0;
	int debug_ultra_high = 0;
	int debug_ultra_mega_high = 0;
	int is_fullscreen = 0;
	int is_fullscreen_geom = 0;
	int borders_pixel = 0;
	int check_fullscreen = 1;
	int can_lock_pa = 1;
	int can_lock_wm = 1;
	int exits = 0;
	char servs[100][101] = {"youtube", "vlc", "mpv", "vimeo", "picture in picture"};
	int len_servs = len(servs);
	int get_args = 0;
	int j = len_servs;
	j = 5; //number of precompiled services
	//config file related variables
	FILE *conf;
	int config = 1;
	int print_notice = 1;
	char home[255] = "";
	char config_file[255] = "";

	const char *s = getenv(HOME);
       	strcpy(home,(s!=NULL)? s : "getenv returned NULL");

	for(int i = 0; i < argc; i++){
		if(argv[i][0] == '-'){
			switch(argv[i][1]){
				case 't': //time before screensaver
					if(argv[i+1])timeout = atoi(argv[i+1])*1000;
					else {printUsage();exit(EX_DATAERR+20);}
					break;
				case 'a': //time after timeout
					if(argv[i+1])time_saver = atoi(argv[i+1]);
					else {printUsage();exit(EX_DATAERR+21);}
					break;
				case 's': //time for blanker
					if(argv[i+1])time_sleep = atoi(argv[i+1]); //time before screen off
					else {printUsage();exit(EX_DATAERR+22);}
					break;
				case 'i': //ignore borders for fullscreen detection
					if(argv[i+1])borders_pixel = atoi(argv[i+1]);
					else {printUsage();exit(EX_DATAERR+23);}
					break;
				case 'r': //screensaver
					sprintf(saver, "%s", argv[i+1]);
					break;
				case 'l': //locker
					sprintf(locker, "%s", argv[i+1]);
					break;
				case 'b': //blanker
					sprintf(sleeper, "%s", argv[i+1]);
					break;
				case 'n': //no notifs
					notifs = 0;
					break;
				case 'c': //custom notifiers
					switch(argv[i][2]){
						case '1': //1 sec
							sprintf(notifier_1, "%s", argv[i+1]);
							break;
						case '2': //2 secs
							sprintf(notifier_2, "%s", argv[i+1]);
							break;
						case '3': //3 secs
							sprintf(notifier_3, "%s", argv[i+1]);
							break;
						case '4': //4 secs
							sprintf(notifier_4, "%s", argv[i+1]);
							break;
						case '5': //5 secs
							sprintf(notifier_5, "%s", argv[i+1]);
							break;
						case '\0':
							sprintf(notifier, "%s", argv[i+1]);
							break;
					}
					break;
				case 'x': //exits right before loop
					exits = 1;
					break;
				case 'v': //prints options
					print_opts = 1;
					break;
				case 'f': //disable fullscreen check
					check_fullscreen = 0;
					break;
				case 'w': //activate get list programs inhibit
					get_args = 1;
					break;
				case 'd': //debug
					debug = 1;
					break;
				case 'D': //DEBUG
					debug = 1;
					debug_high = 1;
					break;
				case 'u': //ultra debug
					debug = 1;
					debug_high = 1;
					debug_ultra_high = 1;
					break;
				case 'U': //ULTRA DEBUG
					debug = 1;
					debug_high = 1;
					debug_ultra_high = 1;
					debug_ultra_mega_high = 1;
					break;
				case '-': //double dashes options
					if(!strcmp(argv[i],"--help")){
						printUsage();
						exit(EX_OK);
					}
					else if(!strcmp(argv[i],"--config")){
						sprintf(config_file,"%s",argv[i+1]);
					}
					else if(!strcmp(argv[i],"--copy-config")){
						system("cp -vi /usr/share/scrnsvr/scrnsvr.ini.example $HOME/.config/scrnsvr.ini");
						exit(EX_OK);
					}
					break;
				default: //Uknown option
					pr("Uknown option: %s. Use only '%s', or the switch '--help', to get a list of options\n",argv[i],argv[0]);
					exit(EX_USAGE);
			}
		}
		else if(get_args == 1){ //get args for -w
			if(strlen(argv[i])>99){
				pr("Argument '%s' of the -w flag is too long\n",argv[i]);
				exit(EX_DATAERR);
			}
			strcpy(servs[j],argv[i]);
			if(debug_high == 1)printf("%s\n",argv[i]);
			j++;
		}
	}
	
	if (strlen(config_file) == 0)
		strcpy(config_file,strcat(home,"/.config/scrnsvr.ini"));

	conf = fopen(config_file,"r");
	if(conf == NULL && config == 1){
		if(print_notice == 1)pr("No valid config file specified (and the default doesn't exist), to turn off this notice specify a valid config file with --config or copy the default config file with --copy-config\n");
		config = 0;
		if(argc < 7){ //are there the required switches?
			printUsage();
			exit(EX_USAGE);
		}
	}
	if(config == 1){
	size_t len_k;
	size_t len_v;
	size_t len;
	//rewind(conf);
	char comment[1];
	//int y = 0;
	while(!feof(conf)){
		char c_fgetc = fgetc(conf);
		if(c_fgetc == COMMENT_COLON || c_fgetc == COMMENT_HASH){
			fscanf(conf,"%[^\n]\n",comment); //with NULL it doesn't work
			continue;
		}
		fseek(conf,-1,SEEK_CUR);
		char *key = NULL;
		char *value = NULL;
		len_k = getdelim(&key,&len,'=',conf);
		len_v = getline(&value,&len,conf); //finishes the line, can also use 'getdelim(&value,&len,'\n',conf);'
		key[len_k-1] = '\0'; //remove '=' (delim)
		char *k = strtrm(key); //trim leading and trailing spaces from key
		char *v = strtrm(value); //trim leading and trailing spaces from value
		if(len_k <= 1)continue; //if key is null
		if(!v || len_v < 1){
			pr("Value for key '%s' is missing\n",k);
			exit(EX_CONFIG);
		}
		if(debug_high == 1) printf("len_k=%lu\nlen_v=%lu\n",len_k,len_v);
		if(debug == 1) printf("k=%s\nv=%s\n",k,v);
		if(compare_key("timeout")) //-t
			timeout = atoi(v)*1000;
		else if (compare_key("time saver")) //-a
			time_saver = atoi(v);
		else if (compare_key("time sleep")) //-s
			time_sleep = atoi(v);
		else if (compare_key("borders width")) //-i
			borders_pixel = atoi(v);
		else if (compare_key("saver")) //-r
			sprintf(saver, "%s", v);
		else if (compare_key("locker")) //-l
			sprintf(locker, "%s", v);
		else if (compare_key("blanker")) //-b
			sprintf(sleeper, "%s", v);
		else if (compare_key("notifs")){ //-n
			int vn = atoi(v);
			notifs = (vn == 0 || vn == 1) ? vn : 1 ;}
		else if (compare_key("notifier")) //-c
			sprintf(notifier, "%s", v);
		else if (compare_key("notifier 1")) //-c1
			sprintf(notifier_1, "%s", v);
		else if (compare_key("notifier 2")) //-c2
			sprintf(notifier_2, "%s", v);
		else if (compare_key("notifier 3")) //-c3
			sprintf(notifier_3, "%s", v);
		else if (compare_key("notifier 4")) //-c4
			sprintf(notifier_4, "%s", v);
		else if (compare_key("notifier 5")) //-c5
			sprintf(notifier_5, "%s", v);
		else if (compare_key("check fullscreen")){ //-f
			int vn = atoi(v);
			check_fullscreen = (vn == 0 || vn == 1) ? vn : 1 ;}
		else if (compare_key("services")){ //-w
			const char del[] = ",";
			char *tok;
			tok = strtok(v,del);
			for (int cs = j; tok != NULL; cs++){
				strcpy(servs[cs],strtrm(tok));
				tok = strtok (NULL,del);
				if(debug_high == 1)printf("servs[%dcs]%s\n",cs,servs[cs]);
				if(strlen(servs[cs])>99){
					pr("Value '%s' of the servs key is too long (it's > 99)\n",servs[cs]);
					exit(EX_DATAERR);
				}
			}}
		else{
			pr("Unkown key '%s' with value '%s'\n",k,v);
			exit(EX_CONFIG);}
	}fclose(conf);}
	if(debug_ultra_high == 1)print_array(len(servs),servs);
	
	//check if required parameters are valid
	if(ckea(saver)){printUsage();exit(EX_DATAERR+24);}
	if(ckea(locker)){printUsage();exit(EX_DATAERR+25);}
	if(ckea(sleeper)){printUsage();exit(EX_DATAERR+26);}
	
	//-v
	if(print_opts == 1){
		printf("Config (--config): %s\n",config_file);
		printf("Before [Screensaver] from now (-t): %d s\n",timeout/1000);
		printf("Before [Locker] from [Screensaver] (-a): %d s\n",time_saver);
		printf("Before [Blanker] from now (-s): %d s\n",time_sleep);
		printf("Screensaver (-r): %s\n",saver);
		printf("Locker (-l): %s\n",locker);
		printf("Blanker (-b): %s\n",sleeper);
		printf("Inhibiting windows (-w): ");
		for(int w = 0;w<len(servs);w++){
			if(servs[w][0] != '\0'){
				printf("'%s' ",servs[w]);
			}
		}
		printf("\nNotifs (-n): %s\n",(notifs == 1)?ACTIVATED:DEACTIVATED);
		printf("Borders (in pixels) (-i): %d\n",borders_pixel);
		printf("Notifier (-c): %s\n",notifier);
		printf("Notifier (1 second left) (-c1): %s\n",notifier_1);
		printf("Notifier (2 second left) (-c2): %s\n",notifier_2);
		printf("Notifier (3 second left) (-c3): %s\n",notifier_3);
		printf("Notifier (4 second left) (-c4): %s\n",notifier_4);
		printf("Notifier (5 second left) (-c5): %s\n",notifier_5);
		printf("Fullscreen detection (-f): %s\n",(check_fullscreen == 1)?ACTIVATED:DEACTIVATED);
	}
	
	if(debug_high == 1 || (print_opts == 1 && notifier[0] != '\0'))printf("notifier: %s\n",notifier);
	if(debug_high == 1 || (print_opts == 1 && notifier_1[0] != '\0'))printf("notifier_1: %s\n",notifier_1);
	if(debug_high == 1 || (print_opts == 1 && notifier_2[0] != '\0'))printf("notifier_2: %s\n",notifier_2);
	if(debug_high == 1 || (print_opts == 1 && notifier_3[0] != '\0'))printf("notifier_3: %s\n",notifier_3);
	if(debug_high == 1 || (print_opts == 1 && notifier_4[0] != '\0'))printf("notifier_4: %s\n",notifier_4);
	if(debug_high == 1 || (print_opts == 1 && notifier_5[0] != '\0'))printf("notifier_5: %s\n",notifier_5);

	time_sleep -= (timeout/1000); //makes sure the specified blank time is the time before blanker executes (instead of putting that time after the locker)
	//compiles commands
	sprintf(cmd_saver, "%s", saver);
	sprintf(cmd_lock, "%s &", locker);
	sprintf(cmd_sleep, "%s", sleeper);
	sprintf(pgrep_lock, "pgrep -x '%s' >/dev/null", locker);
	sprintf(pgrep_sleep, "pgrep -x '%s' >/dev/null", sleeper);

	if(debug_high == 1)printf("%s\n",cmd_saver);
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
	if(noti == 0){//if dunstify is present use it
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
	
	//variables required for the loop
	unsigned int milliseconds;
	milliseconds = 100;
	useconds_t useconds = milliseconds * 1000; //time between the loops in micro-seconds
	int sys;
	Display *my_display = XOpenDisplay(NULL);
	
	//threads "pid"
	int vpid = 69420; //saver thread
	int cpid = 69420; //locker thread
	int spid = 69420; //sleeper thread

	pthread_t chi, sle, svr;
	//args for threads functions
	struct child_struct args_child;
	struct slf_struct args_slf;

	args_child.vpid = vpid;
	args_child.svr = svr;
	args_child.time_saver = time_saver;
	args_child.cmd_lock = cmd_lock;
	
	args_slf.time_sleep = time_sleep;
	args_slf.cmd_sleep = cmd_sleep;
	
	char cmd_parun[] = "pactl list short | grep RUNNING >/dev/null"; //if I put it at the start, it could get overwritten by servs[] (idk why, but ok)
	if(debug_high == 1)printf("%s\n",cmd_parun);

	if(exits == 1)exit(EX_OK); //if -x is specified exit
	//loop
	XSetErrorHandler(xerrh);
	while(my_display){
		usleep(useconds); //pause for useconds micro-seconds
		Display *my_display = XOpenDisplay(NULL); //get display
		XScreenSaverInfo *info = XScreenSaverAllocInfo(); //assing display info
		XScreenSaverQueryInfo(my_display, DefaultRootWindow(my_display), info); //get display info

		int display_width = XDisplayWidth(my_display,XDefaultScreen(my_display));
		int display_height = XDisplayHeight(my_display,XDefaultScreen(my_display));
		if(debug_high == 1)printf("Display geom: %dx%d\n",display_height,display_width);

		//get current focused window
		Window focused = 0; // Window {aka long unsigned int}
		int revto;
		/*int ciao =*/ XGetInputFocus(my_display, &focused, &revto);
		//printf("%d:%d:%ld\n",ciao,revto,focused);
		if(focused != 0){
			//check if focused window is fullscreen
			if(check_fullscreen == 1){
				XWindowAttributes attribs;
				XGetWindowAttributes(my_display, focused, &attribs);
				if(attribs.width && attribs.height){
					int focused_height = attribs.height;
					int focused_width = attribs.width;
					if(debug_high == 1)printf("Focused window geom: %dx%d\n",focused_width,focused_height);
					if(debug_ultra_mega_high == 1)printf("%d ",display_height == focused_height);
					if(debug_ultra_mega_high == 1)printf("%d\n",display_width == focused_width);
					if(display_height == focused_height || display_height == (focused_height - borders_pixel)){
						if(display_width == focused_width || display_width == (focused_width - borders_pixel)){
							is_fullscreen_geom = 1;
						}
						else{is_fullscreen_geom = 0;}
					}
					else{
						is_fullscreen_geom = 0;
					}
				}
				
				Atom prop_state = XInternAtom(my_display, "_NET_WM_STATE",False);
				Atom prop_fullscreen = XInternAtom(my_display, "_NET_WM_STATE_FULLSCREEN",True);
				Atom actype;
				Atom cprop;
				int fmt;
				unsigned long nitems,bytesafter;
				unsigned char *states;

				int status = XGetWindowProperty(my_display, focused, prop_state, 0L, sizeof(Atom), False, AnyPropertyType, &actype, &fmt, &nitems, &bytesafter, &states);
				if(status == Success && states){
					for(int i=0;i<nitems;i++){
						cprop = ((Atom *)states)[i];
						if(cprop == prop_fullscreen)is_fullscreen = 1;
						else is_fullscreen = 0;
					}
				}
			}

			//check if name is one of servs
			XTextProperty fname;
			Status fst = XGetWMName(my_display, focused, &fname);
			if(fst && debug_high == 1)printf("%s\n",fname.value);

			if(fst){
				for(int i=0;i<len_servs;i++){
					if(debug_ultra_high == 1)printf("%s\n",servs[i]);
					if(debug_ultra_mega_high == 1)printf("%d\n",i);
					if(debug_ultra_mega_high == 1)printf("%s\n",fname.value);
					char *pl=strcasestr((const char *)fname.value,servs[i]);
					if(servs[i][0] && pl != NULL){
						can_lock_wm = 0;
						break;
					}else can_lock_wm = 1;
				}
			}
		}

		can_lock_pa=system(cmd_parun)/256; //audio playing?
		sys=system(pgrep_lock)/256; //is the locker running?
		if(debug == 1)printf("can_lock_pa = %d\n",can_lock_pa);
		if(debug == 1)printf("can_lock_wm = %d\n",can_lock_wm);
		if(debug == 1)printf("is_fullscreen = %d\n",is_fullscreen);
		if(debug == 1)printf("is_fullscreen_geom = %d\n",is_fullscreen_geom);
		//if
		//   audio not playing then lock
		//   focused tab hasn't servs then lock
		//   app is not fullscreen then lock

		//if((can_lock_pa == 1 || can_lock_wm == 1) && !is_fullscreen){ //wasn't sure about the logic lol
		if(!((can_lock_pa != 1 && can_lock_wm != 1) || (is_fullscreen || is_fullscreen_geom)) || sys != 1){
			if(info->idle >= timeout && info->idle <= timeout+180){ //has timeout passed?
				if(debug_high == 1)printf("sys = %d\n",sys);
				if(sys == 1){ //if locker not running then
					if(spid != 69420){pthread_cancel(sle);}
					if(cpid != 69420){pthread_cancel(chi);}
					if(vpid != 69420){pthread_cancel(svr);}
					vpid=pthread_create(&svr,NULL,(void *)&svf, (void *)cmd_saver);
					cpid=pthread_create(&chi,NULL,(void *)&child, (void *)&args_child);
					spid=pthread_create(&sle,NULL,(void *)&slf, (void *)&args_slf);
				}else{ //if yes then
					printf("locker running\n");
					if(spid != 69420){pthread_cancel(sle);}
					spid=pthread_create(&sle,NULL,(void *)&slf, (void *)&args_slf);
				}
			}
			else if(info->idle < timeout){ //is the timeout almost passed?
				sys=system(pgrep_lock)/256; //is the locker running?
				if(debug_high == 1)printf("sys = %d\n",sys);
				if(sys == 1){ //if no then
					if(notifs == 1){ //are the notifications enabled?
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
					//cancel threads if idle time is less than timeout
					if(spid != 69420){pthread_cancel(sle);}
					if(cpid != 69420){pthread_cancel(chi);}
					if(vpid != 69420){pthread_cancel(svr);}
				}
			}
		}
		printf("%lu\n", info->idle); //printf idle time in milliseconds
		//printf("%lu\n", (*info).idle); //just another form of the line before this one
		XCloseDisplay(my_display); //close diplay, it'll be reopened at the start of the loop
	}
	return 0;
}
void svf(char *cmd_saver){ //function for screensaver thread
	system(cmd_saver);
}
void child(void *ptr){ //function for locker thread
	printf("forked\n");
	struct child_struct *args = ptr;
	sleep(args->time_saver);
	printf("locked\n");
	system(args->cmd_lock);
	if(args->vpid != 69420){pthread_cancel(args->svr);}
}
void slf(void *ptr){ //function for sleeper thread
	struct slf_struct *args = ptr;
	sleep(args->time_sleep);
	printf("off\n");
	system(args->cmd_sleep);
}
int xerrh(Display *d,XErrorEvent *e){
	char txt[100];
	XGetErrorText(d,e->error_code,txt,sizeof(txt));
	pr("Error: %d (%s). Maj: %d. Min: %d. Serial: %ld",e->error_code,txt,e->request_code,e->minor_code,e->serial);
	return 0;
}
char *strtrm(char *str) //from https://stackoverflow.com/a/122721/12206923 (first solution)
{
	char *end;

	// Trim leading space
	while(isspace((unsigned char)*str)) str++;

	if(*str == 0)  // All spaces?
	  return str;

	// Trim trailing space
	end = str + strlen(str) - 1;
	while(end > str && isspace((unsigned char)*end)) end--;

	// Write new null terminator character
	end[1] = '\0';

	return str;
}
