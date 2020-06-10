#include <stdio.h>
#include <unistd.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#define pr(...) (fprintf(stderr,__VA_ARGS__)) //print errors to stderr
#define ex(x) (x) ? (x) : ""

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
void escape_space(char *str)
{
	printf("\n\n:%s:\n\n",str);
	int l = strlen(str);
	strcat(str," ");
	printf("\n\n:%s:\n\n",str);
	for(int i=l;i>=l;i++)
	{
		printf("ciao");
		if(str[i] == ' ')
		{
		printf("ciao");
			for(int j=i;j>=l;j++){
				str[j] = str[j-1];
			}
			break;
		}
	}
	printf("\n\n%s\n\n",str);
}
int has_space(char *str){
	if(str){
		for(int i=0;i<strlen(str);i++){
			if(str[i]==' '){
				return 1;
			}
		}
	}
	return 0;
}

struct section {
	char *name;
	char *location;
	char *entries;
};
struct group {
	struct section *array_sections;
};

int main(int argc, char *argv[]){
	FILE *conf;
	int debug = 0;
	char com = ';';
	char home[100] = "";
	char config_file[100] = "";
	const char *s = getenv("HOME");
	char ls_opts[200] = "ls -d --color=auto ";
	for(int i=0;i<argc;i++){
		if(argv[i][0] == '-'){
			switch(argv[i][1]){
				case 'o':
					strcat(ls_opts,strcat(argv[i+1]," "));
					break;
				case 'd':
					debug = 1;
					break;
			}
		}
	}
	if(debug == 1)printf("%s\n",ls_opts);
       	strcat(home,(s!=NULL)? s : "getenv returned NULL");
	strcat(config_file,strcat(home,"/.config/lgfs.conf"));
	
	conf = fopen(config_file,"r");
	if(conf == NULL)return 5;
	size_t len;
	//rewind(conf);
	char comment[1];
	struct group all;
	int j;
	char cwd[1024];
	getcwd(cwd,1024);
	while(!feof(conf)){
		struct section gr;
		gr.name = "";
		gr.location = "";
		gr.entries = "";
		if(fgetc(conf) == '['){
			fscanf(conf,"%[^\n]\n",comment);
			for(int i=0;i<3;i++){
				if(fgetc(conf) == com){
					i--;
					fscanf(conf,"%[^\n]\n",comment);
					//printf("ciao\n");
					continue;
				}
				fseek(conf,-1,SEEK_CUR);
				char *key = NULL;
				char *value = NULL;
				getdelim(&key,&len,'=',conf);
				getdelim(&value,&len,'\n',conf);
				key[strlen(key)-1] = '\0';
				char *k = strtrm(key),*v = strtrm(value);
				//printf("%p\n",v);
				//printf("%p\n",value);
				//printf("%c\n",k[0]);
				/*if(k[0] == 'n') gr.name = v;
				else if(k[0] == 'l')gr.location = v;
				else if(k[0] == 'e')gr.entries = v;*/
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
						exit(2);
				}
				//printf("key: %s\nvalue: %s\n",strtrm(key),strtrm(value));
			}
			struct section array[1024];
			array[0] = gr;
			all.array_sections = array;
			//printf("cwd: %s\n",cwd);
			if(debug == 1)printf("name: %s\n",gr.name);
			if(debug == 1)printf("location: %s\n",gr.location);
			if(debug == 1)printf("entries: %s\n\n",gr.entries);
			//here checks cwd
			if(!strcmp(cwd,gr.location)){
				DIR *d;
				struct dirent *dir;
				d=opendir(".");
				char ff[200000] = "";
				if(d){
					while((dir = readdir(d)) != NULL){
						char *n = dir->d_name;
						if(strcmp(n,"..")){
							if(strcmp(n,".")){
								if(has_space(n))escape_space(n);
								strcat(ff," ");
								strcat(ff,n);
							}
						}
					}
					if(debug == 1)printf("%s\n",ff);
				}
				char ls[200000];
				char lg[200000];
				strcpy(ls,ls_opts);
				strcpy(lg,ls_opts);
				strcat(ls,ff);
				if(debug == 1)printf("ls: %s\n",ls);
				strcat(lg,gr.entries);
				if(debug == 1)printf("lg: %s\n",lg);

				system(ls);
				printf("=== %s ===\n",gr.name);
				system(lg);
				//printf("%s\n",gr.entries);
			}
		}
	}
	fclose(conf);
	return 0;
	/*if(str[i] = '\\'){
		case
	}*/
}

//char *strtrm(char *s){
//	char *p = s;
//	printf("'%s' '%s'\n",p,s);
//	for(int i=0;i<strlen(p);i++){
//		if(isspace(p[i])){
//			p[i] = "";
//		}else{break;}
//	}
//	for(int i=strlen(p);i<=strlen(p);i--){
//		if(isspace(p[i])){
//			p[i] = "\0";
//		}else{break;}
//	}
//	//p[strlen(p)] = '\0';
//	printf("%s\n",p);
//	return *p;
//}


/*
	while(getdelim(&key,&len,'=',conf) != -1){
		getdelim(&value,&len,'\n',conf);
		key[strlen(key)-1] = '\0';
		printf("key: %s\nvalue: %s\n",strtrm(key),strtrm(value));
		char cwd[1024];
		getcwd(cwd,1024);
		//printf("cwd: %s\n",cwd);
	}

*/
/*
		printf("in loop\n");
		i = 0;
		while(fgetc(conf) != '='){
			key[i]=fgetc(conf);
			printf("%c",key[i]);
			i++;
		}
		key[i+1] = '\0';
		i = 0;
		while(fgetc(conf) != '\n'){
			value[i]=fgetc(conf);
			printf("%c",value[i]);
			i++;
		}
		value[i+1] = '\0';
		printf("%s;%s",key,value);
		//break;
*/
