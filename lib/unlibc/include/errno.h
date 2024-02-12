#ifndef ERRNO_H
#define ERRNO_H

extern volatile int errno;

enum {
  EINTR = 4
};

char *strerror(int errnum);

#endif
