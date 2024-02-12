#ifndef STDIO_H
#define STDIO_H

typedef void FILE;

extern FILE *stdout;
extern FILE *stdin;
extern FILE *stderr;

int sprintf(char *s, char *fmt, ...);
size_t fwrite(const void *data, size_t size, size_t count, FILE *stream);
char * fgets(char *s, int count, FILE *stream);
int fflush(FILE *stream);
int ferror(FILE *stream);
void clearerr(FILE *stream);

#endif
