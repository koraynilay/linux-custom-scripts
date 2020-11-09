/* To compile: 
 * gcc [options] lgfs.c -o lgfs
 * For FULL RELRO (from https://www.redhat.com/en/blog/hardening-elf-binaries-using-relocation-read-only-relro ):
 * gcc -g -O0 -Wl,-z,relro,-z,now [options] lgfs.c -o lgfs
*/

#include <stdio.h>
#include <unistd.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <errno.h>
#include <time.h>
#define pr(...) (fprintf(stderr,__VA_ARGS__)) //print errors to stderr
#define ex(x) (x) ? (x) : ""
#define ARLEN 1024
//#define CLOCKS_PER_SEC 2700000
#define lar(x) (sizeof(x)/sizeof(x[0]))
#ifdef _WIN32
#define HOME "CSIDL_PROFILE"
#else
#define HOME "HOME"
#endif

char *strtrm(char *str); //from https://stackoverflow.com/a/122721/12206923 (first solution)
void replace(char *str, char to_replace, char replace_with);
void escape_char(char *str, char toesc);
int has_char(char *str, char c);
void printUsage(){ 
		pr("Usage: lgfs [OPTIONS]\n\n");
		pr("--help\t\tShows this help\n\n");
		pr("-o [options]\tOptions of -l\n");
		pr("-n\t\tTurns off the notice if a config file doesn't exist\n");
		pr("-a\t\tShow everything (also . and ..)\n");
		pr("-n\t\tTurns off the notice if a config file doesn't exist\n");
		//pr("-l\t\tExecutable to list the files (Default: 'ls')\n");
		//pr("-p\t\tPrints config file, if it exists, then exits\n");
		pr("-d\t\tShows debug info (Use -D for more levels of debugging)\n");
}

int debug = 0;
int debug_high = 0;
int debug_time = 0;
struct section {
	char *name;
	char *location;
	char *entries;
};

int main(int argc, char *argv[]){
	FILE *conf;
	clock_t start = clock();
	int config = 1;
	int print_notice = 1;
	int elems;
	int all = 0;
	char *dr = NULL;
	char com = ';';
	char home[100] = "";
	char config_file[100] = "";
	char ls_opts[200] = "ls -d --color=auto ";
	const char *s = getenv(HOME);
	for(int i=1;i<argc;i++){
		if(argv[i]){
			if(argv[i][0] == '-'){
				switch(argv[i][1]){
					case 'o':
						if(!argv[i+1]){
							pr("Option -o requires an argument\n");
							exit(2);
						}
						strcat(ls_opts,"-");
						strcat(ls_opts,argv[i+1]);
						strcat(ls_opts," ");
						i++;
						break;
					case 'n':
						config = 0;
						break;
					case 'a':
						all = 1;
						break;
					case '_':
						print_notice = 0;
						break;
					case '-': //double dashes options
						if(!strcmp(argv[i],"--help")){
							printUsage();
							exit(0);
						}
						break;
					case 't':
						debug_time = 1;
						break;
					case 'd':
						debug = 1;
						break;
					case 'D':
						debug = 1;
						debug_high = 1;
						break;
					default:
						pr("Uknown option: %s\n",argv[i]);
						exit(6);
				}
			}
			else{
				dr = argv[i];
			}
			if(debug_high == 1)printf("[%di (args)]%s\n",i,argv[i]);
		}
	}
	if(debug_time == 1){
		clock_t first = clock();
		printf("first: %f\n",(double)(first - start) / CLOCKS_PER_SEC);
	}
	if(debug == 1)printf("%s\n",ls_opts);
       	strcat(home,(s!=NULL)? s : "getenv returned NULL");
	strcat(config_file,strcat(home,"/.config/lgfs.conf"));
	
	conf = fopen(config_file,"r");
	if(conf == NULL && config == 1){
		if(print_notice == 1)pr("No config file, to turn off this notice run, without quotes, 'touch $HOME/.config/lgfs.conf' or you the option -n\n");
		config = 0;
	}
	char cwd[1024];
	char *ret=getcwd(cwd,1024);
	if(errno == ERANGE){
		pr("Current Working Directory is more than 1024 characters long.\n");
		exit(221);
	}
	if(ret == NULL){
		pr("Can't open Current Working Directory: it probably doesn't exist.\n");
		exit(20);
	}

	struct section argr[ARLEN] = {};
	if(config == 1){
		size_t len;
		//rewind(conf);
		char comment[1];
		int j = 0;
		while(!feof(conf)){
			struct section gr;
			gr.name = "";
			gr.location = "";
			gr.entries = "";
			char cch = fgetc(conf);
			//printf("%c\n",cch);
			if(cch == com){
				fscanf(conf,"%[^\n]\n",comment);
				fseek(conf,-1,SEEK_CUR);
				continue;
			}
			if(cch == '['){
				fscanf(conf,"%[^\n]\n",comment);
				for(int i=0;i<3;i++){
					if(fgetc(conf) == com){
						i--;
						fscanf(conf,"%[^\n]\n",comment);
						continue;
					}
					fseek(conf,-1,SEEK_CUR);
					char *key = NULL;
					char *value = NULL;
					getdelim(&key,&len,'=',conf);
					getdelim(&value,&len,'\n',conf);
					key[strlen(key)-1] = '\0';
					char *k = strtrm(key);
					char *v = strtrm(value);
					//printf("%p\n",v);
					//printf("%c\n",k[0]);
					switch(k[0]){
						case 'n':
							gr.name = v;
							break;
						case 'l':
							gr.location = v;
							break;
						case 'e':
							gr.entries = v;
							break;
						default:
							pr("Uknown key: %s\n",k);
							exit(3);
					}
				}
				if(debug == 1)printf("name: %s\n",gr.name);
				if(debug == 1)printf("location: %s\n",gr.location);
				if(debug == 1)printf("entries: %s\n\n",gr.entries);
				argr[j] = gr;
				j++;
				if(j == 1024)break;
			}
		}
		fclose(conf);
		elems = j+1;
	}
	if(debug_time == 1){
		clock_t second = clock();
		printf("secnd: %f\n",(double)(second - start) / CLOCKS_PER_SEC);
	}
	//get files in cwd
	DIR *d;
	struct dirent *dir;
	if(dr == NULL){
		d=opendir(".");
	}else{
		d=opendir(dr);
		strcat(dr,"/");
		strcat(cwd,dr);
	}
	if(debug_high == 1) printf("dr:%s\n",dr);

	char *ff=malloc(sizeof(char));
	strcpy(ff,"");
	unsigned int ff_size;
	if(d){ //if not NULL go
		while((dir = readdir(d)) != NULL){ //get every filename in cwd
			int concat = 1;
			if(dir->d_name[0] == '.' && all == 0) continue;
			if(has_char(dir->d_name,' ')) escape_char(dir->d_name, '\'');
			//if(has_char(dir->d_name,' ')) escape_char(dir->d_name, ' ');
			//if(has_char(dir->d_name,'(')) escape_char(dir->d_name, '(');
			//if(has_char(dir->d_name,')')) escape_char(dir->d_name, ')');
			//if(has_char(dir->d_name,'#')) escape_char(dir->d_name, '#');
			//if(has_char(dir->d_name,'*')) escape_char(dir->d_name, '*');
			//if(has_char(dir->d_name,'$')) escape_char(dir->d_name, '$');
			//if(has_char(dir->d_name,'/')) escape_char(dir->d_name, '/'); //do not escape '\' otherwise it won't work
			if(debug_high == 1)printf("%s\n",dir->d_name);
			if(debug_high == 1)printf("%s\n",dir->d_name);
			ff_size+=strlen(dir->d_name)*sizeof(dir->d_name);
			if(debug == 1)printf("%d\n",ff_size);
			for(int y=0;y<elems;y++){
				if(argr[y].entries && argr[y].location){
					if(strcmp(cwd,argr[y].location) == 0){ //if equals
						if(strstr(argr[y].entries,dir->d_name)){ //if found
							concat = 0;
							break;
						}
					}
					if(debug_high == 1)printf("[%dy]%s\n",y,argr[y].name);
				}
			}
			if(concat == 1){
				ff = realloc(ff, ff_size);
				strcat(ff," '");
				if(dr)strcat(ff,dr);
				strcat(ff,dir->d_name);
				strcat(ff,"'");
			}
		}
	}
	else{
		pr("Can't open '%s'\n",dr);
		exit(1);
	}
	closedir(d);
	if(debug_time == 1){
		clock_t third = clock();
		printf("third: %f\n",(double)(third - start) / CLOCKS_PER_SEC);
	}
	//printf("lss:%s\n",ff);
	//printf("cwd:%s\n",cwd);
	int opt_size = sizeof(ls_opts);
	char *ls = malloc(opt_size + ff_size);
	strcpy(ls,ls_opts);
	strcat(ls,ff);
	if(debug == 1)printf("ls: %s\n",ls);
	system(ls);
	if(config == 1){
		for(int i=0;i<elems;i++){
			if(argr[i].name && argr[i].location && argr[i].entries){
				if(debug == 1)printf("name: %s\n",argr[i].name);
				if(debug == 1)printf("location: %s\n",argr[i].location);
				if(debug == 1)printf("entries: %s\n\n",argr[i].entries);
				if(!strcmp(cwd,argr[i].location)){
					char *lg = malloc(opt_size + sizeof(argr[i].entries));

					strcpy(lg,ls_opts);
					strcat(lg,argr[i].entries);
					if(debug == 1)printf("lg: %s\n",lg);

					printf("=== %s ===\n",argr[i].name);
					system(lg);
					//printf("%s\n",argr[i].entries);
				}
				//printf("=== %s ===\n",argr[i].name);
			}
		}
	}
	if(debug_time == 1){
		clock_t end = clock();
		printf("enddd: %f\n",((double)(end - start) / CLOCKS_PER_SEC));
	}
	free(ff);
	free(ls);
	return 0;
}

//char *trimwhitespace(char *str)
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
void replace(char *str, char to_replace, char replace_with)
{
    for(int i = 0; i < strlen(str);i++)
    {
        if(str[i] == to_replace)
        {
            str[i] = replace_with;
            break;
        }
    }
}
void escape_char(char *str, char toesc)
{
	//printf("str:%ld\n",sizeof(str));
	//printf("\n\n:%s:\n\n",str);
	strcat(str," ");
	int l = strlen(str);
	//printf("%s\n",str);
	if(debug == 1)printf("%s:%d\n",str,l);
	for(int i=l-2;i>0;i--)
	{
		if(debug_high == 1)printf("i:%d\n",i);
		if(str[i] == toesc)
		{
			for(int j=l;j>=i;j--){
				if(debug_high == 1)printf("j:%d\n",j);
				if(j == i){
					str[j] = '\\';
				}else{
					str[j] = str[j-1];
				}
			}
		}
	}
	if(debug == 1)printf("%s\n",str);
}
//void escape_space(char *str)
//{
//	//printf("str:%ld\n",sizeof(str));
//	//printf("\n\n:%s:\n\n",str);
//	strcat(str," ");
//	int l = strlen(str);
//	//printf("%s\n",str);
//	if(debug == 1)printf("%s:%d\n",str,l);
//	for(int i=l-2;i>0;i--)
//	{
//		if(debug_high == 1)printf("i:%d\n",i);
//		if(str[i] == ' ')
//		{
//			for(int j=l;j>=i;j--){
//				if(debug_high == 1)printf("j:%d\n",j);
//				if(j == i){
//					str[j] = '\\';
//				}else{
//					str[j] = str[j-1];
//				}
//			}
//		}
//	}
//	if(debug == 1)printf("%s\n",str);
//}
int has_char(char *str, char c){
	if(str){
		for(int i=0;i<strlen(str);i++){
			if(str[i] == c){
				return 1;
			}
		}
	}
	return 0;
}
