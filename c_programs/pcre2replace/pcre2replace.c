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
	printf("%s", string);

	PCRE2_UCHAR *outputbuffer = malloc(sizeof(char) * 20000);
	int errornumber;
	PCRE2_SIZE erroroffset;

	PCRE2_SPTR pattern = (PCRE2_SPTR)argv[2];
	pcre2_code *re = pcre2_compile(pattern, PCRE2_ZERO_TERMINATED, 0, &errornumber, &erroroffset, NULL);
	if (re == NULL) {
		PCRE2_UCHAR buffer[256];
		pcre2_get_error_message(errornumber, buffer, sizeof(buffer));
		printf("PCRE2 compilation failed at offset %d: %s\n", (int)erroroffset, buffer);
		return 1;
	}

	PCRE2_SPTR subject = (PCRE2_SPTR)string;
	PCRE2_SIZE length = fsize;
	PCRE2_SIZE startoffset = 0;
	uint32_t options = PCRE2_SUBSTITUTE_EXTENDED;
	PCRE2_SPTR rep = (PCRE2_SPTR)argv[3];
	PCRE2_SIZE rlength = strlen(argv[3]);
	PCRE2_SIZE outlengthptr;
	pcre2_substitute(re, subject, length, startoffset, options, NULL, NULL, rep, rlength, outputbuffer, &outlengthptr);

	if(argv[4][0] != '-') {
		f = fopen(argv[4], "wb");
		fwrite(outputbuffer, sizeof(outputbuffer[0]), strlen((char*)outputbuffer), f);
		fclose(f);
	}
	else fwrite(outputbuffer, sizeof(outputbuffer[0]), strlen((char*)outputbuffer), stdout);
}
