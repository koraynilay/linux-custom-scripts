#include <stdio.h>
#include <unistd.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#define pr(...) (fprintf(stderr,__VA_ARGS__)) //print errors to stderr
#define ex(x) (x) ? (x) : ""

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
struct section {
	char *name;
	char *location;
	char *entries;
};
struct group {
	struct section *array_sections;
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
	size_t len;
	//rewind(conf);
	char comment[1];
	struct group all;
	int j;
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
			printf("name: %s\n",gr.name);
			printf("location: %s\n",gr.location);
			printf("entries: %s\n\n",gr.entries);
			//here checks cwd
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
