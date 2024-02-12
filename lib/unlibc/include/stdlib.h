#ifndef STDLIB_H
#define STDLIB_H

void * malloc(size_t size);
void * calloc(size_t num, size_t size);
void * realloc(void *addr, size_t size);
void free(void *addr);
_Noreturn void exit(int status);

#endif
