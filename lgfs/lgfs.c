#include <stdio.h>
#include <unistd.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

//char *trimwhitespace(char *str)
char *strtrm(char *str)
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
struct group {
	char *name;
	char *location;
	char *files;
};

int main(int argc, char *argv[]){
	char com = ';';
	FILE *conf;
	char home[100] = "";
	char config_file[100] = "";
	const char *s = getenv("HOME");
       	strcat(home,(s!=NULL)? s : "getenv returned NULL");
	strcat(config_file,strcat(home,"/.config/zlgfs.conf"));
	
	conf = fopen("/home/koraynilay/.config/zlgfs.conf","r");
	if(conf == NULL)return 5;
	char *key = NULL;
	char *value = NULL;
	int i;
	size_t len;
	//rewind(conf);
	while(!feof(conf)){
		struct group gr;
		if(fgetc(conf) == '['){
			for(int i=0;i<3;i++){
				if(fgetc(conf) == com){
					i--;
					char comment[1];
					fscanf(conf,"%[^\n]",comment);
				//	fgets(NULL,0,conf);
				//	fseek(conf,-1,SEEK_CUR);
					continue;
				}
				fseek(conf,-1,SEEK_CUR);
				getdelim(&key,&len,'=',conf);
				getdelim(&value,&len,'\n',conf);
				key[strlen(key)-1] = '\0';
				char *k = strtrm(key),*v = strtrm(value);
				/*switch(k[0]){
					case 'n':
						gr.name = v;
				}*/
				//printf("key: %s\nvalue: %s\n",strtrm(key),strtrm(value));
				printf("key: %s\nvalue: %s\n",k,v);
			}
		}
	}
	fclose(conf);
	return 0;
	/*if(str[i] = '\\'){
		case
	}*/
}



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
