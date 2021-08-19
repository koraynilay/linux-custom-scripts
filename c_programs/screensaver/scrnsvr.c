/*
 * compile with:
gcc [options] scrnsvr.c -o scrnsvr -lpthread -lXss -lX11 -lXinerama -lXrandr
 *
 * OR for full RELRO (more info: https://www.redhat.com/en/blog/hardening-elf-binaries-using-relocation-read-only-relro)
 *
gcc -Wl,-z,relro,-z,now [options] scrnsvr.c -o scrnsvr -lpthread -lXss -lX11 -lXinerama -lXrandr
 *
*/
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <pthread.h>
#include <pcre.h>
#include <sys/time.h>
#include <stdbool.h>
#include <sys/wait.h>
//X11
#include <X11/extensions/scrnsaver.h>
#include <X11/extensions/Xrandr.h>
#include <X11/extensions/Xinerama.h>
#include <X11/Xutil.h>
//utils
#include <ctype.h> //for isspace()
#include <sysexits.h> //for some exit statuses (see RETURN_CODES.txt)

#define pr(...) (fprintf(stderr,__VA_ARGS__)) //print errors to stderr
#define ckea(x) (x[0] == '\0' || (x[0] == '-' && (x[1] == 'r' || x[1] == 'l' || x[1] == 'b'))) //check if required options exist
#define len(x) (sizeof(x)/sizeof(x[0])) //array length
#define print_array(z,x) for(unsigned long y=0;y<z;y++)printf("%ld element: %s\n",y,x[y]); //print every array element
#define pd() (printf("\nciao\n"))
#define compare_key(x) (!strcmp(k,x)) //compare key from config
//constants
#define ACTIVATED "Enabled"
#define DEACTIVATED "Disabled"
#define HOME "HOME"
#define COMMENT_COLON ';'
#define COMMENT_HASH '#'
#define PID_PTHREAD_DEF_VALUE 69420

void *svf(void *ptr); //function for saver pthread
void *lck(void *ptr); //function for locker pthread
void *slf(void *ptr); //function for sleeper pthread
char *strtrm(char *str); //trim spaces at start and end of strings
bool can_run_command(const char *cmd); //check if command is executable (and exists) in the system
int xerrh(Display *d,XErrorEvent *e); //handle X11 errors
//cancel threads
int pthread_cancel_pid(pthread_t thread, int *pid, int check_value, int debug){
	if(*pid != check_value){
		*pid = PID_PTHREAD_DEF_VALUE;
		int ret = pthread_cancel(thread);
		if(debug) printf("ret%d: %d\n",debug,ret);
		return ret;
	}
	return 1;
}

void printUsage(){ 
		//pr("Usage: scrnsvr -[tearlswhnkcc1c2c3c4c5xdDuU]\n\n"); //not yet supported
		pr("Usage: scrnsvr [OPTIONS]\n\n");
		pr(" --help\t\tShow this help\n\n");

		pr(" --config [file] Specify custom config file (absolute path, default: $HOME/.config/scrnsvr.ini)\n");
		pr(" --copy-config\t Copy a demo config to $HOME/.config/scrnsvr.ini\n");
		pr(" --shell-saver\t Invokes the shell to run [saver] (use if it needs argument(s))\n");
		pr(" --shell-locker\t Invokes the shell to run [locker] (use if it needs argument(s))\n");
		pr(" --shell-blanker Invokes the shell to run [blanker] (use if it needs argument(s))\n");
		pr(" -k\t\t Ignore config file\n");
		pr(" -t [timeout]\t Time in seconds before [saver] gets activated (default: 120)\n");
		pr(" -a [timeout]\t Time in seconds before [locker] gets activated AFTER [saver] has been activated (default: 30)\n");
		pr(" -r [timeout]\t Time in seconds before [blanker] gets activated (default: 180)\n");
		pr(" -s [saver]\t (REQUIRED) Screensaver (e.g. a xscreensaver module) (path/to/executable or shell command (in this case use -h or --shell-saver))\n");
		pr(" -l [locker]\t (REQUIRED) Program that locks your screen (path/to/executable or shell command (in this case use -h or --shell-locker))\n");
		pr(" -b [blanker]\t (REQUIRED) Program that blanks/sets your screen off (path/to/executable or shell command (in this case use -h or --shell-blanker))\n\n");
		pr(" -w [list]\t Space-separated case-insensitive list of windows titles which inhibit the screensaver (added to: youtube vlc mpv vimeo 'picture in picture')\n");
		pr(" -n\t\t Disables 'Saving in ~n secs' notifications\n");
		pr(" -h\t\t Invokes the shell to run [saver], [locker] and [blanker] (use if they need arguments)\n");
		pr(" -i  [pixels]\t Pixels of windows borders (if you want to consider fullscreen also windows that have a border but aren't actually fullscreen)\n");
		pr(" -c  [notifier]\t Command used to send notifications (if -n is NOT specified) (uses the same command for every level)\n");
		pr(" -c1 [notifier]\t Command used to send notifications when there is 1 second left(if -n is NOT specified)\n");
		pr(" -c2 [notifier]\t Command used to send notifications when there is 2 second left(if -n is NOT specified)\n");
		pr(" -c3 [notifier]\t Command used to send notifications when there is 3 second left(if -n is NOT specified)\n");
		pr(" -c4 [notifier]\t Command used to send notifications when there is 4 second left(if -n is NOT specified)\n");
		pr(" -c5 [notifier]\t Command used to send notifications when there is 5 second left(if -n is NOT specified)\n");
		pr(" -x\t\t Executes until the loop (without entering it) and exits; Useful to check config and options\n");
		pr(" -f\t\t Disables the detection of the fullscreen state of the current focused window\n");
		pr(" -v\t\t Prints selected options (even when they are the default)\n");
		pr(" -d\t\t Shows debug info (Use -D,-u or -U for more information)\n");
}

struct svr_struct { //struct for thread locker arguments
	char *cmd;
	int shell;
};
struct lck_struct { //struct for thread locker arguments
	int vpid;
	int time_saver;
	char *cmd;
	pthread_t svr;
	bool locked;
	int shell;
};
struct slf_struct { //struct for thread sleeper arguments
	int time_sleep;
	char *cmd;
	int shell;
};

int main(int argc, char *argv[]) {
	if(getuid() == 0){ //check if root
		pr("\nYou should NOT run this program as root. Press Control-C to cancel (10 seconds timeout, then continue running as normal)\n\n");
		sleep(10);
	}
	// string config options
	char saver[60] = "";
	char locker[60] = "";
	char sleeper[60] = ""; //it's called blanker in the switch
	char cmd_saver[70] = "";
	char cmd_lock[70] = "";
	char cmd_sleep[70] = "";
	char notifier[60] = "";
	char notifier_1[60] = "";
	char notifier_2[60] = "";
	char notifier_3[60] = "";
	char notifier_4[60] = "";
	char notifier_5[60] = "";
	// number config options
	unsigned long timeout = 120*1000; //120 seconds, *1000 cuz it uses useconds (microseconds) (the other *1000 is after the custom value gets set)
	int time_saver = 30;
	int time_sleep = 180;
	int notifs = 1;

	//debug command line options
	int print_opts = 0;
	int debug = 0;
	int debug_high = 0;
	int debug_ultra_high = 0;
	int debug_ultra_mega_high = 0;
	// window checks
	int is_fullscreen = 0;
	int is_fullscreen_geom = 0;
	int borders_pixel = 0;
	int check_fullscreen = 1;
	int can_lock_pa = 1;
	int can_lock_wm = 1;
	int exits = 0;

	int get_args = 0;
	// window titles to exclude
	char servs[100][101] = {"(?i)youtube", "(?i)vlc", "(?i)mpv", "(?i)vimeo", "(?i)picture in picture"};
	int len_servs = len(servs);
	int j = len_servs;
	j = 5; //number of precompiled services
	//config file related variables
	int rc, pcre_error_offset;
	const char *pcre_error;

	FILE *conf;
	int config = 1;
	int ignore_conf = 0;
	int print_notice = 1;
	char home[255];
	char config_file[255] = "";

	int shell_saver = 0;
	int shell_locker = 0;
	int shell_sleeper = 0;

	for(int i = 0; i < argc; i++){
		if(argv[i][0] == '-'){
			switch(argv[i][1]){
				case 't': //time before screensaver
					if(argv[i+1])timeout = atof(argv[i+1])*1000;
					else {printUsage();exit(EX_DATAERR+20);}
					break;
				case 'a': //time after timeout
					if(argv[i+1])time_saver = atoi(argv[i+1]);
					else {printUsage();exit(EX_DATAERR+21);}
					break;
				case 'r': //time for blanker
					if(argv[i+1])time_sleep = atoi(argv[i+1]); //time before screen off
					else {printUsage();exit(EX_DATAERR+22);}
					break;
				case 'i': //ignore borders for fullscreen detection
					if(argv[i+1])borders_pixel = atoi(argv[i+1]);
					else {printUsage();exit(EX_DATAERR+23);}
					break;
				case 's': //screensaver
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
				case 'h': //use shell to run saver, locker and sleeper
					shell_saver = 1;
					shell_locker = 1;
					shell_sleeper = 1;
					break;
				case 'k': //ignores config even if a valid config file exists
					ignore_conf = 1;
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
					else if(!strcmp(argv[i],"--config")){ //get custom config file
						sprintf(config_file,"%s",argv[i+1]);
					}
					else if(!strcmp(argv[i],"--copy-config")){
						system("cp -vi /usr/share/scrnsvr/scrnsvr.ini.example $HOME/.config/scrnsvr.ini");
						exit(EX_OK);
					}else if(!strcmp(argv[i],"--shell-saver")){ //use shell to run screensaver
						shell_saver = 1;
					}else if(!strcmp(argv[i],"--shell-locker")){ //use shell to run locker
						shell_locker = 1;
					}else if(!strcmp(argv[i],"--shell-blanker")){ //use shell to run sleeper
						shell_sleeper = 1;
					}else{ //Unknown -- (double dash) option
						pr("Uknown option: %s. Use only '%s', or the switch '--help', to get a list of options\n",argv[i],argv[0]);
						exit(EX_USAGE);
					}
					break;
				default: //Unknown - (single dash) option
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
	
	strcpy(home,getenv(HOME));
	if (strlen(config_file) == 0)
		strcpy(config_file,strcat(home,"/.config/scrnsvr.ini"));

	conf = fopen(config_file,"r");
	if(ignore_conf == 1) config = 0;
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
	//char comment[1];
	//int y = 0;
	while(!feof(conf)){
		char c_fgetc = fgetc(conf);
		if(c_fgetc == COMMENT_COLON || c_fgetc == COMMENT_HASH){
			fscanf(conf,"%*[^\n]\n"); //with NULL it doesn't work
			continue;
		}
		fseek(conf,-1,SEEK_CUR);
		//char key_string[50];
		//char value_string[100];
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
		else if (compare_key("time sleep")) //-r
			time_sleep = atoi(v);
		else if (compare_key("borders width")) //-i
			borders_pixel = atoi(v);
		else if (compare_key("saver")) //-s
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
		else if (compare_key("shell")){
			if(!strcmp(v,"true")){
					shell_saver = 1;
					shell_locker = 1;
					shell_sleeper = 1;
			}}
		else if (compare_key("shell saver")){
			if(!strcmp(v,"true"))
					shell_saver = 1;}
		else if (compare_key("shell locker")){
			if(!strcmp(v,"true"))
					shell_locker = 1;}
		else if (compare_key("shell blanker")){
			if(!strcmp(v,"true"))
					shell_sleeper = 1;}
		else{
			pr("Unkown key '%s' with value '%s'\n",k,v);
			exit(EX_CONFIG);}
	}fclose(conf);}
	if(debug_ultra_high == 1)print_array(len(servs),servs);
	
	//check if required parameters are valid
	if(ckea(saver))	 {printUsage(); exit(EX_DATAERR+24);}
	if(ckea(locker)) {printUsage(); exit(EX_DATAERR+25);}
	if(ckea(sleeper)){printUsage(); exit(EX_DATAERR+26);}
	
	//-v
	if(print_opts == 1){
		printf("Config (--config): %s\n",config_file);
		printf("Before [Screensaver] from now (-t): %ld s\n",timeout/1000);
		printf("Before [Locker] from [Screensaver] (-a): %d s\n",time_saver);
		printf("Before [Blanker] from now (-r): %d s\n",time_sleep);
		printf("Screensaver (-s): %s\n",saver);
		printf("Locker (-l): %s\n",locker);
		printf("Blanker (-b): %s\n",sleeper);
		printf("Inhibiting windows (-w): ");
		for(unsigned long w = 0;w<len(servs);w++){
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
	sprintf(cmd_lock, "%s", locker);
	sprintf(cmd_sleep, "%s", sleeper);

	if(debug_high == 1){
		printf("%s\n",cmd_saver);
		printf("%s;%s\n",cmd_lock,locker);
		printf("%s;%s\n",cmd_sleep,sleeper);
	}

	int dunstify = 0;
	if(can_run_command("dunstify")){//if dunstify is present use it
		dunstify = 1;
		if(debug_ultra_high == 1)printf("dunstify = yes\n");
	}
	else{
		if(can_run_command("notify-send")){
			dunstify = 2;
		}else if(notifier[0] == '\0' && notifier_1[0] == '\0' && notifier_2[0] == '\0' && notifier_3[0] == '\0' && notifier_4[0] == '\0' && notifier_5[0] == '\0'){
			notifs = 0;
		}
		if(debug_ultra_high == 1)printf("notify-send = yes\n");
	}
	if(debug == 1)printf("dunstify = %d\n",dunstify);
	if(debug == 1)printf("notifs = %d\n",notifs);
	
	//variables required for the loop
	unsigned int milliseconds;
	milliseconds = 100;
	useconds_t useconds = milliseconds * 1000; //time between the loops in micro-seconds
	Display *my_display = XOpenDisplay(NULL);
	
	//threads "pid"
	int vpid = PID_PTHREAD_DEF_VALUE; //saver thread
	int cpid = PID_PTHREAD_DEF_VALUE; //locker thread
	int spid = PID_PTHREAD_DEF_VALUE; //sleeper thread

	pthread_t chi, sle, svr;
	//args for threads functions
	struct svr_struct args_svr;
	struct lck_struct args_lck;
	struct slf_struct args_slf;

	args_svr.cmd = cmd_saver;
	args_svr.shell = shell_saver;

	args_lck.vpid = vpid;
	args_lck.svr = svr;
	args_lck.time_saver = time_saver;
	args_lck.cmd = cmd_lock;
	args_lck.locked = false;
	args_lck.shell = shell_locker;
	
	args_slf.time_sleep = time_sleep;
	args_slf.cmd = cmd_sleep;
	args_slf.shell = shell_sleeper;
	
	//char cmd_parun[] = "python -c 'import dbus; bus = dbus.SessionBus(); [exit(1 if dbus.SessionBus().get_object(service, \"/org/mpris/MediaPlayer2\").Get(\"org.mpris.MediaPlayer2.Player\", \"PlaybackStatus\", dbus_interface=\"org.freedesktop.DBus.Properties\") == \"Playing\" else 0) for service in bus.list_names() if service.startswith(\"org.mpris.MediaPlayer2.\")]'"; //if I put it at the start, it could get overwritten by servs[] (idk why, but ok)
	//if(debug_high == 1)printf("%s\n",cmd_parun);

	if(exits == 1)exit(EX_OK); //if -x is specified exit

	int sys;
	XSetErrorHandler(xerrh);
	struct timespec start, end;
	long int delta_time = 0;
	// Main Loop
	while(my_display){
		usleep(useconds - ((delta_time <= useconds) ? delta_time : useconds)); //pause for useconds micro-seconds
		//printf("%ld\n",useconds - ((delta_time <= useconds) ? delta_time : useconds));
		clock_gettime(CLOCK_REALTIME,&start);

		Display *my_display = XOpenDisplay(NULL); //get display
		XScreenSaverInfo *info = XScreenSaverAllocInfo(); //assing display info
		XScreenSaverQueryInfo(my_display, DefaultRootWindow(my_display), info); //get display info

		//get display geometry (height and width)
		int display_width = XDisplayWidth(my_display,XDefaultScreen(my_display));
		int display_height = XDisplayHeight(my_display,XDefaultScreen(my_display));
		if(debug_high == 1)printf("Display geom: %dx%d\n",display_height,display_width);

		//get current focused window
		Window focused = 0; // Window {aka long unsigned int}
		int revto;
		/*int ciao =*/ XGetInputFocus(my_display, &focused, &revto);
		//printf("%d:%d:%ld\n",ciao,revto,focused);
		if(focused != 0){
			//check if focused window is fullscreen only if the fullscreen check is enabled
			if(check_fullscreen == 1){
				XWindowAttributes attribs;
				XGetWindowAttributes(my_display, focused, &attribs);

				// not used now, but could be useful in the future
				//
				// //kinda borrowed from https://github.com/jordansissel/xdotool/blob/master/xdo.c#L195
				// int focused_x, focused_y;
				// Window parent, root, *children, dummy;
				// unsigned int nchildren;
				// XQueryTree(my_display, focused, &root, &parent, &children, &nchildren);
				// if (children != NULL) XFree(children);
				// if (parent == attribs.root) {
				// 	focused_x = attribs.x;
				// 	focused_y = attribs.y;
				// }
				// else XTranslateCoordinates(my_display, focused, attribs.root, 0, 0, &focused_x, &focused_y, &dummy);
				// if(debug_ultra_high == 1) printf("Focused x y:%d %d\n",focused_x,focused_y);

				if(attribs.width && attribs.height){
					int focused_height = attribs.height;
					int focused_width = attribs.width;
					int nsizes = 0;
					int event_base_return;
					int error_base_return;
					if(debug_high == 1)printf("Focused window geom: %dx%d\n",focused_width,focused_height);
					if(debug_ultra_mega_high == 1)printf("%d ",display_height == focused_height);
					if(debug_ultra_mega_high == 1)printf("%d\n",display_width == focused_width);

					//now check
					//if the height and width of the focues windows are equal to those of the current monitor
					//or
					//if the height and width minus the size in pixel specified as the border are equal to those of the current monitor

					//if there is only 1 monitor
					if((display_height == focused_height || display_height == (focused_height - borders_pixel)) &&
					   (display_width  == focused_width  || display_width  == (focused_width  - borders_pixel))){
							is_fullscreen_geom = 1;
					}
					//if there 1+ monitors and Xinerama is used
					else if(XineramaIsActive(my_display) == 1){
						XineramaScreenInfo *xinfo = XineramaQueryScreens(my_display, &nsizes); //get monitors
						for(int i=0;i<nsizes;i++){
							if(debug_high == 1) printf("Xinerama Screen %d Geometry:%dx%d\n",xinfo[i].screen_number,xinfo[i].width,xinfo[i].height);
							display_height = xinfo[i].height;
							display_width = xinfo[i].width;
							//check size
							if((display_height == focused_height || display_height == (focused_height - borders_pixel)) &&
							   (display_width  == focused_width  || display_width  == (focused_width  - borders_pixel))){
									is_fullscreen_geom = 1;
									break;
							}else is_fullscreen_geom = 0;
						}
						XFree(xinfo);
					}
					//if there 1+ monitors and XRandr is used
					else if(XRRQueryExtension(my_display, &event_base_return, &error_base_return) == 1){
						XRRMonitorInfo *xinfo = XRRGetMonitors(my_display, RootWindow(my_display, DefaultScreen(my_display)), True, &nsizes); //get monitors
						for(int i=0;i<nsizes;i++){
							if(debug_high == 1) printf("Xrandr Screen %d Geometry:%dx%d\n",i,xinfo[i].width,xinfo[i].height);
							display_height = xinfo[i].height;
							display_width = xinfo[i].width;
							if((display_height == focused_height || display_height == (focused_height - borders_pixel)) &&
							   (display_width  == focused_width  || display_width  == (focused_width  - borders_pixel))){
									is_fullscreen_geom = 1;
									break;
							}else is_fullscreen_geom = 0;
						}
						XFree(xinfo);
					}
					else is_fullscreen_geom = 0;
				}
				
				//check if the focused windows has the _NET_WM_STATE_FULLSCREEN attribute
				//aka has been made fullscreen (with F11 or the like)
				Atom prop_state = XInternAtom(my_display, "_NET_WM_STATE",False);
				Atom prop_fullscreen = XInternAtom(my_display, "_NET_WM_STATE_FULLSCREEN",True);
				Atom actype;
				Atom cprop;
				int fmt;
				unsigned long nitems,bytesafter;
				unsigned char *states;

				int status = XGetWindowProperty(my_display, focused, prop_state, 0L, sizeof(Atom), False, AnyPropertyType, &actype, &fmt, &nitems, &bytesafter, &states);
				if(status == Success && states){
					for(unsigned long i=0;i<nitems;i++){
						cprop = ((Atom *)states)[i];
						if(cprop == prop_fullscreen)is_fullscreen = 1;
						else is_fullscreen = 0;
					}
				}
			}

			//check if name (window title) matches at least 1 of servs regexes
			XTextProperty fname;
			Status fst = XGetWMName(my_display, focused, &fname);
			if(fst && debug_high == 1)printf("%s\n",fname.value);
			if(fst){
				for(int i=0;i<len_servs;i++){
					if(servs[i][0]){
						if(debug_ultra_high == 1)printf("%s\n",servs[i]);
						if(debug_ultra_mega_high == 1)printf("%d\n",i);
						if(debug_ultra_mega_high == 1)printf("%s\n",fname.value);
						pcre *re = pcre_compile(servs[i], 0, &pcre_error, &pcre_error_offset, NULL);
						if(re == NULL) printf("%s: failed to compile PCRE at %d: %s\n", servs[i], pcre_error_offset, pcre_error);
						else rc = pcre_exec(re, NULL, (const char *)fname.value, strlen((const char *)fname.value), 0, 0, NULL, 0);
						pcre_free(re);
						if(rc >= 0){ //match successful
							can_lock_wm = 0;
							break;
						}
					}else can_lock_wm = 1;
				}
			}
		}

		pid_t pid;
		if((pid = fork()) == 0){
			//TODO integrate this DBus check in C
			//check if there is a mpris.MediaPlayer2.something instance in dbus; adapted from https://askubuntu.com/a/1298711/1179015
			execlp("python", "python", "-c", "import dbus; bus = dbus.SessionBus(); [exit(1 if dbus.SessionBus().get_object(service, \"/org/mpris/MediaPlayer2\").Get(\"org.mpris.MediaPlayer2.Player\", \"PlaybackStatus\", dbus_interface=\"org.freedesktop.DBus.Properties\") == \"Playing\" else 0) for service in bus.list_names() if service.startswith(\"org.mpris.MediaPlayer2.\")]", (char *) NULL);
		}else{
			int status;
			waitpid(pid, &status, 0);
			if(WIFEXITED(status)) can_lock_pa = !WEXITSTATUS(status);
		}
		if(args_lck.locked == true) sys = 0; else sys = 1; //is the locker running?
		if(debug == 1)printf("can_lock_pa = %d\n",can_lock_pa);
		if(debug == 1)printf("can_lock_wm = %d\n",can_lock_wm);
		if(debug == 1)printf("is_fullscreen = %d\n",is_fullscreen);
		if(debug == 1)printf("is_fullscreen_geom = %d\n",is_fullscreen_geom);
		//lock if:
		//- player not detected (can_lock_pa == 1)
		//- focused tab hasn't servs
		//- app is not fullscreen ((is_fullscreen OR is_fullscreen_geom) != 0)

		//if((can_lock_pa == 1 || can_lock_wm == 1) && !is_fullscreen) //wasn't sure about the logic
		if(!((can_lock_pa != 1 && can_lock_wm != 1) || (is_fullscreen || is_fullscreen_geom)) || sys != 1){
			if(info->idle >= timeout && info->idle <= timeout+120){ //has timeout passed?
				if(debug_high == 1)printf("sys = %d\n",sys);
				if(sys == 1){ //if locker not running then
					pthread_cancel_pid(sle, &spid, PID_PTHREAD_DEF_VALUE, 0);
					pthread_cancel_pid(chi, &cpid, PID_PTHREAD_DEF_VALUE, 0);
					pthread_cancel_pid(svr, &vpid, PID_PTHREAD_DEF_VALUE, 0);
					vpid=pthread_create(&svr,NULL,svf, (void *)&args_svr);
					cpid=pthread_create(&chi,NULL,lck, (void *)&args_lck);
					spid=pthread_create(&sle,NULL,slf, (void *)&args_slf);
				}else{ //if yes then
					printf("locker running\n");
					pthread_cancel_pid(sle, &spid, PID_PTHREAD_DEF_VALUE, 0);
					spid=pthread_create(&sle,NULL,slf, (void *)&args_slf);
				}
			}
			else if(info->idle < timeout){ //is the timeout almost passed?
				//if yes then
				if(args_lck.locked == true) sys = 0; else sys = 1; //is the locker running?
				if(debug_high == 1)printf("sys = %d\n",sys);
				if(sys == 1){ //if no then
					if(notifs == 1){ //are the notifications enabled?
						//if yes send notification each second in the last 5 seconds
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
					if(debug_ultra_mega_high == 1)printf("pids: s:%d c:%d v:%d\n",spid,cpid,vpid);
					//cancel saver and locker and the screen is not locked yet if idle time is less than timeout
					pthread_cancel_pid(svr, &vpid, PID_PTHREAD_DEF_VALUE, 0);
					pthread_cancel_pid(chi, &cpid, PID_PTHREAD_DEF_VALUE, 0);
				}
				//cancel sleeper if idle time is less than timeout
				if(debug_ultra_high == 1)printf("pids: s:%d c:%d v:%d\n",spid,cpid,vpid);
				pthread_cancel_pid(sle, &spid, PID_PTHREAD_DEF_VALUE, 0);
			}
		}
		printf("%lu\n", info->idle); //printf idle time in milliseconds
		//printf("%lu\n", (*info).idle); //just another form of the line before this one
		XCloseDisplay(my_display); //close diplay, it'll be reopened at the start of the loop

		//calculate time spent in this iteration of loop
		clock_gettime(CLOCK_REALTIME,&end);
		//first get seconds.nanoseconds then convert it to actual nanoseconds
		delta_time = ((end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1000000000.0)*1000*1000;
		if(debug_high == 1)printf("start.tv_usec = %lf\n",start.tv_sec + start.tv_nsec/1000000000.0);
		if(debug_high == 1)printf("end.tv_usec = %lf\n",end.tv_sec + end.tv_nsec/1000000000.0);
		if(debug_high == 1)printf("delta_time = %ld\n",delta_time);
	}
	return 0;
}
// if shell is specified run the program (and its arguments) with the shell (aka with system())
#define system_or_execlp(args) {\
		if(args->shell == true) system(args->cmd);			\
		else{								\
			pid_t pid;						\
			if((pid = fork()) == 0){				\
				execlp(args->cmd, args->cmd, (char *) NULL);	\
			}else{							\
				int status;					\
				waitpid(pid, &status, 0);			\
			}							\
		}								\
}
void *svf(void *ptr){ //function for screensaver thread
	//int old_cancel_type;
	pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS,NULL);
	//if(debug_ultra_mega_high == 1) printf("%d\n",old_cancel_type);
	printf("forked_saver\n");
	
	struct svr_struct *args_struct = ptr;
	system_or_execlp(args_struct);
	return NULL;
}
void *lck(void *ptr){ //function for locker thread
	//int old_cancel_type;
	pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS,NULL);
	//if(debug_ultra_mega_high == 1) printf("%d\n",old_cancel_type);
	printf("forked_locker\n");
	
	struct lck_struct *args_struct = ptr;
	sleep(args_struct->time_saver);

	printf("locked\n");
	args_struct->locked = true;
	system_or_execlp(args_struct);

	args_struct->locked = false;
	printf("not locked anymore\n");
	//pthread_cancel_pid(args->svr, &(args->vpid), PID_PTHREAD_DEF_VALUE, 0);
	return NULL;
}
void *slf(void *ptr){ //function for sleeper thread
	//int old_cancel_type;
	pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS,NULL);
	//if(debug_ultra_mega_high == 1) printf("%d\n",old_cancel_type);
	printf("forked_sleeper\n");

	struct slf_struct *args_struct = ptr;
	sleep(args_struct->time_sleep);
	printf("sleeper activated\n");
	system_or_execlp(args_struct);
	return NULL;
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
bool can_run_command(const char *cmd) { //from https://stackoverflow.com/a/41231524/12206923
    if(strchr(cmd, '/')) {
        // if cmd includes a slash, no path search must be performed,
        // go straight to checking if it's executable
        return access(cmd, X_OK)==0;
    }
    const char *path = getenv("PATH");
    if(!path) return false; // something is horribly wrong...
    // we are sure we won't need a buffer any longer
    char *buf = malloc(strlen(path)+strlen(cmd)+3);
    if(!buf) return false; // actually useless, see comment
    // loop as long as we have stuff to examine in path
    for(; *path; ++path) {
        // start from the beginning of the buffer
        char *p = buf;
        // copy in buf the current path element
        for(; *path && *path!=':'; ++path,++p) {
            *p = *path;
        }
        // empty path entries are treated like "."
        if(p==buf) *p++='.';
        // slash and command name
        if(p[-1]!='/') *p++='/';
        strcpy(p, cmd);
        // check if we can execute it
        if(access(buf, X_OK)==0) {
            free(buf);
            return true;
        }
        // quit at last cycle
        if(!*path) break;
    }
    // not found
    free(buf);
    return false;
}
