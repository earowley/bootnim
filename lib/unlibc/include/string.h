#ifndef STRING_H
#define STRING_H

void * memcpy(void *dst, void *src, size_t size);
void * memset(void *dst, int c, size_t size);
void * memchr(void *block, int c, size_t size);
int memcmp(void *a1, void *a2, size_t size);
size_t strlen(char *s);
int strcmp(char *s1, char *s2);

#endif
