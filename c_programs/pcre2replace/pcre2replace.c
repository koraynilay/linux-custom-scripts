#define PCRE2_CODE_UNIT_WIDTH 8
#include <stdio.h>
#include <string.h>
#include <pcre2.h>

int main(int argc, char *argv[]) {
	// from https://stackoverflow.com/a/14002993/12206923
	FILE *f = fopen(argv[1], "rb");
	fseek(f, 0, SEEK_END);
	long fsize = ftell(f);
	fseek(f, 0, SEEK_SET);  /* same as rewind(f); */

	char *string = malloc(fsize + 1);
	fread(string, fsize, 1, f);
	fclose(f);

	string[fsize] = '\0';
	//

	int errornumber;
	PCRE2_SIZE erroroffset;

	//char *ps = argv[2];
	//unsigned int patlen = strlen(ps);
	//unsigned char pattern[8192+10];
	//sprintf((char *)pattern, "%s%.*s%s", "", patlen, ps, "");
	PCRE2_SPTR pattern = (PCRE2_SPTR)argv[2];
	long unsigned int coptions = PCRE2_MULTILINE;
	printf("-pattern:%s;options: %04lx\n", pattern, coptions);
	pcre2_code *re = pcre2_compile(pattern, -1, coptions, &errornumber, &erroroffset, NULL);
	if (re == NULL) {
		PCRE2_UCHAR buffer[256];
		pcre2_get_error_message(errornumber, buffer, sizeof(buffer));
		printf("PCRE2 compilation failed at offset %d: %s\n", (int)erroroffset, buffer);
		return 1;
	}

	PCRE2_SPTR subject = (PCRE2_SPTR)string;
	size_t length = fsize;
	int startoffset = 0;
	unsigned int roptions = PCRE2_SUBSTITUTE_GLOBAL | PCRE2_SUBSTITUTE_EXTENDED;
	//unsigned int moptions = 0;
	PCRE2_SPTR rep = (PCRE2_SPTR)argv[3];
	PCRE2_SIZE rlength = strlen(argv[3]);

	PCRE2_UCHAR *outputbuffer = malloc(sizeof(char) * fsize*2);
	PCRE2_SIZE outlengthptr = fsize*2;

	uint32_t ovecsize = 512;
	pcre2_match_data *match_data = pcre2_match_data_create(ovecsize, NULL);
	//int r = pcre2_match(re, (PCRE2_SPTR)string, (int)length, startoffset, moptions, match_data, NULL);

	int r = pcre2_substitute(
			re,
			subject,
			(int)length,
			startoffset,
			//PCRE2_SUBSTITUTE_EXTENDED | PCRE2_SUBSTITUTE_GLOBAL,
			roptions,
			match_data,
			NULL,
			rep,
			rlength,
			outputbuffer,
			&outlengthptr
		);

	//printf("-subject:%s;r:%d\n", string, r);
	printf("r:%d\n", r);
	if(r <= 0) {
		printf("error :(\n");
		return 1;
	}

	if(argv[4][0] != '-') {
		f = fopen(argv[4], "wb");
		fwrite(outputbuffer, sizeof(outputbuffer[0]), strlen((char*)outputbuffer), f);
		fclose(f);
	}
	else fwrite(outputbuffer, sizeof(outputbuffer[0]), strlen((char*)outputbuffer), stdout);
}
