/*
|| This file is part of Pike. For copyright information see COPYRIGHT.
|| Pike is distributed under GPL, LGPL and MPL. See the file COPYING
|| for more information.
*/

#ifndef PORT_H
#define PORT_H

#include "global.h"
#include <math.h>

#ifdef __MINGW32__
/******************************************************/
/* First we must ensure that all defines are in mingw */
/******************************************************/
#ifndef PROCESSOR_PPC_601
#define PROCESSOR_PPC_601       601
#endif

#ifndef PROCESSOR_PPC_604
#define PROCESSOR_PPC_603       603
#endif

#ifndef PROCESSOR_PPC_604
#define PROCESSOR_PPC_604       604
#endif

#ifndef PROCESSOR_PPC_620
#define PROCESSOR_PPC_620       620
#endif

#ifndef PROCESSOR_OPTIL
#define PROCESSOR_OPTIL         0x494f  /* MSIL */
#endif

#ifndef PROCESSOR_ARCHITECTURE_MSIL
#define PROCESSOR_ARCHITECTURE_MSIL 8
#endif

#ifndef PROCESSOR_ARCHITECTURE_AMD64
#define PROCESSOR_ARCHITECTURE_AMD64            9
#endif

#ifndef PROCESSOR_ARCHITECTURE_IA32_ON_WIN64
#define PROCESSOR_ARCHITECTURE_IA32_ON_WIN64    10
#endif

#ifndef PROCESSOR_HITACHI_SH3
#define PROCESSOR_HITACHI_SH3   10003   /* Windows CE */
#endif

#ifndef PROCESSOR_HITACHI_SH3E
#define PROCESSOR_HITACHI_SH3E  10004   /* Windows CE */
#endif

#ifndef PROCESSOR_HITACHI_SH4
#define PROCESSOR_HITACHI_SH4   10005   /* Windows CE */
#endif

#ifndef PROCESSOR_SHx_SH3
#define PROCESSOR_SHx_SH3       103     /* Windows CE */
#endif

#ifndef PROCESSOR_SHx_SH4
#define PROCESSOR_SHx_SH4       104     /* Windows CE */
#endif

#ifndef PROCESSOR_STRONGARM
#define PROCESSOR_STRONGARM     2577    /* Windows CE - 0xA11 */
#endif

#ifndef PROCESSOR_ARM720
#define PROCESSOR_ARM720        1824    /* Windows CE - 0x720 */
#endif

#ifndef PROCESSOR_ARM820
#define PROCESSOR_ARM820        2080    /* Windows CE - 0x820 */
#endif

#ifndef PROCESSOR_ARM920
#define PROCESSOR_ARM920        2336    /* Windows CE - 0x920 */
#endif

#ifndef PROCESSOR_ARM_7TDMI
#define PROCESSOR_ARM_7TDMI     70001   /* Windows CE */
#endif

#ifndef LOGON32_LOGON_NETWORK
#define LOGON32_LOGON_NETWORK 3
#endif

/* FP_CLASS compleation */

/* Now for some functions */
#define Emulate_GetLongPathName GetLongPathNameA

#endif /* __MINGW32__ */


#ifndef STRUCT_TIMEVAL_DECLARED
#define STRUCT_TIMEVAL_DECLARED
struct timeval;
#endif

#ifndef HAVE_GETTIMEOFDAY
void GETTIMEOFDAY(struct timeval *t);
#else
#  ifdef GETTIMEOFDAY_TAKES_TWO_ARGS
#    define GETTIMEOFDAY(X) gettimeofday((X),NULL)
#  else
#    define GETTIMEOFDAY gettimeofday
#  endif
#endif

#ifndef HAVE_SNPRINTF
#ifdef HAVE__SNPRINTF
/* In WIN32 snprintf is known as _snprintf... */
#define snprintf _snprintf
#define HAVE_SNPRINTF 1
#endif
#endif

#ifndef HAVE_RINT
#define rintf(X) floorf ((X) + 0.5)
#define rint(X) floor( (X) + 0.5 )
#define rintl(X) floorl ((X) + 0.5)
#endif

#ifndef HAVE_STRCASECMP
PMOD_EXPORT int STRCASECMP(const char *a,const char *b);
#else
#  define STRCASECMP(A,B) strcasecmp(A,B)
#endif

#ifndef HAVE_VSNPRINTF
PMOD_EXPORT int vsnprintf(char *buf, size_t size, const char *fmt, va_list args);
#endif
#define VSNPRINTF(A,B,C,D) vsnprintf(A,B,C,D)

#ifndef HAVE_SNPRINTF
PMOD_EXPORT int snprintf(char *buf, size_t size, const char *fmt, ...);
#endif
#define SNPRINTF snprintf

/* Compat. */
#define RINTF(X) rintf(X)
#define RINT(X) rint(X)
#define RINTL(X) rintl(X)

#define HAVE_STRCHR 1
#define STRCHR strchr
#ifdef STRCHR_DECL_MISSING
char *strchr(const char *s,int c);
#endif

#define HAVE_ISSPACE 1
#define ISSPACE(X) isspace(X)

#define HAVE_TIME 1
#define TIME(X) time(X)

#define HAVE_STRTOL 1
#define STRTOL(X,Y,Z) strtol(X,Y,Z)

#define HAVE_STRTOD 1
#define STRTOD(X,Y) strtod(X,Y)

#define HAVE_STRCSPN 1
#define STRCSPN(X,Y) strcspn(X,Y)

#define HAVE_STRNLEN 1
#define STRNLEN(X,Y) strnlen(X,Y)

#define HAVE_STRNCMP 1
#define STRNCMP(X,Y,Z) strncmp(X,Y,Z)

#define HAVE_MEMSET 1
#define MEMSET(X,Y,Z) memset(X,Y,Z)

#define HAVE_MEMCPY 1
#define MEMCPY(X,Y,Z) memcpy(X,Y,Z)

#define HAVE_MEMMOVE 1
#define MEMMOVE(X,Y,Z) memmove(X,Y,Z)

#define HAVE_MEMCMP 1
#define MEMCMP(X,Y,Z) memcmp(X,Y,Z)

#define HAVE_MEMCHR 1
#define MEMCHR(X,Y,Z) memchr(X,Y,Z)

#define HAVE_VFPRINTF 1
#define VFPRINTF(X,Y,Z) vfprintf(X,Y,Z)

#define HAVE_VSPRINTF 1
#define VSPRINTF(X,Y,Z) vsprintf(X,Y,Z)

#define HAVE_FREXP 1
#define FREXP(X,Y) frexp(X,Y)

#define HAVE_LDEXP 1
#define LDEXP(X,Y) ldexp(X,Y)

#ifndef HAVE_STRDUP
#undef strdup
#ifdef HAVE__STRDUP
#define strdup(X) _strdup(X)
#endif
#endif

#ifdef EXTRACT_UCHAR_BY_CAST
#  define EXTRACT_UCHAR(p) (*(const unsigned char *)(p))
#else
#  define EXTRACT_UCHAR(p) (0xff & (int)*(p))
#endif

#ifdef EXTRACT_CHAR_BY_CAST
#  define EXTRACT_CHAR(p) (*(const signed char *)(p))
#else
static INLINE int EXTRACT_CHAR(const char *p) { return *p > 0x7f ? *p - 0x100 : *p; }
#endif

#ifdef HANDLES_UNALIGNED_MEMORY_ACCESS
#  define EXTRACT_UWORD(p) (*(unsigned INT16 *)(p))
#  define EXTRACT_WORD(p) (*(INT16 *)(p))
#  define EXTRACT_INT(p) (*(INT32 *)(p))
#else
#ifdef PIKE_DEBUG
PMOD_EXPORT unsigned INT16 EXTRACT_UWORD_(unsigned char *p);
PMOD_EXPORT INT16 EXTRACT_WORD_(unsigned char *p);
PMOD_EXPORT INT32 EXTRACT_INT_(unsigned char *p);
#else
/*@unused@*/ static INLINE unsigned EXTRACT_UWORD_(unsigned char *p)
{
  unsigned INT16 a;
  memcpy(&a,p,sizeof(a));
  return a;
}

/*@unused@*/ static INLINE int EXTRACT_WORD_(unsigned char *p)
{
  INT16 a;
  memcpy(&a,p,sizeof(a));
  return a;
}

/*@unused@*/ static INLINE INT32 EXTRACT_INT_(unsigned char *p)
{
  INT32 a;
  memcpy(&a,p,sizeof(a));
  return a;
}
#endif

#define EXTRACT_UWORD(p) EXTRACT_UWORD_((unsigned char *)(p))
#define EXTRACT_WORD(p) EXTRACT_WORD_((unsigned char *)(p))
#define EXTRACT_INT(p) EXTRACT_INT_((unsigned char *)(p))

#endif

PMOD_EXPORT unsigned INT32 my_rand(void);
PMOD_EXPORT void my_srand(INT32 seed);

PMOD_EXPORT void sysleep(double left);

PMOD_EXPORT /*@null@*/ void *pike_realloc(void *ptr, size_t sz);

#ifdef OWN_GETHRTIME
void own_gethrtime_init(void);
void own_gethrtime_update(struct timeval *ptr);
long long gethrtime(void);

#define hrtime_t long long
#endif

#ifdef HAVE_UNION_INIT
#define INFNAN_INDEX 0
#define INFNAN_DATATYPE union
#define INFNAN_INIT 
#else
#define INFNAN_INDEX -1
#define INFNAN_DATATYPE struct
#define INFNAN_INIT , {0.0}
#endif

#ifdef DOUBLE_IS_IEEE_BIG
#define DECLARE_INF static const INFNAN_DATATYPE { unsigned char c[8]; double d[1]; } \
	inf_ = { { 0x7f, 0xf0, 0, 0, 0, 0, 0, 0 } INFNAN_INIT };
#define DECLARE_NAN static const INFNAN_DATATYPE { unsigned char c[8]; double d[1]; } \
	nan_ = { { 0x7f, 0xf8, 0, 0, 0, 0, 0, 0 } INFNAN_INIT };
#define MAKE_INF(s) ((s)*inf_.d[INFNAN_INDEX])
#define MAKE_NAN() (nan_.d[INFNAN_INDEX])
#else
#ifdef DOUBLE_IS_IEEE_LITTLE
#define DECLARE_INF static const INFNAN_DATATYPE { unsigned char c[8]; double d[1]; } \
	inf_ = { { 0, 0, 0, 0, 0, 0, 0xf0, 0x7f } INFNAN_INIT };
#define DECLARE_NAN static const INFNAN_DATATYPE { unsigned char c[8]; double d[1]; } \
	nan_ = { { 0, 0, 0, 0, 0, 0, 0xf8, 0x7f } INFNAN_INIT };
#define MAKE_INF(s) ((s)*inf_.d[INFNAN_INDEX])
#define MAKE_NAN() (nan_.d[INFNAN_INDEX])
#else
#ifdef FLOAT_IS_IEEE_BIG
#define DECLARE_INF static const INFNAN_DATATYPE { unsigned char c[4]; float f[1]; } \
	inf_ = { { 0x7f, 0x80, 0, 0 } INFNAN_INIT };
#define DECLARE_NAN static const INFNAN_DATATYPE { unsigned char c[4]; float f[1]; } \
	nan_ = { { 0x7f, 0xc0, 0, 0 } INFNAN_INIT };
#define MAKE_INF(s) ((s)*inf_.f[INFNAN_INDEX])
#define MAKE_NAN() (nan_.f[INFNAN_INDEX])
#else
#ifdef FLOAT_IS_IEEE_LITTLE
#define DECLARE_INF static const INFNAN_DATATYPE { unsigned char c[4]; float f[1]; } \
	inf_ = { { 0, 0, 0x80, 0x7f } INFNAN_INIT };
#define DECLARE_NAN static const INFNAN_DATATYPE { unsigned char c[4]; float f[1]; } \
	nan_ = { { 0, 0, 0xc0, 0x7f } INFNAN_INIT };
#define MAKE_INF(s) ((s)*inf_.f[INFNAN_INDEX])
#define MAKE_NAN() (nan_.f[INFNAN_INDEX])
#else

#undef INFNAN_INDEX
#undef INFNAN_DATATYPE
#undef INFNAN_INIT 

#define DECLARE_INF
#define DECLARE_NAN

#ifdef HAVE_INFNAN
#define MAKE_INF(s) (infnan((s)*ERANGE))
#else
#ifdef HUGE_VAL
#define MAKE_INF(s) ((s)*HUGE_VAL)
#else
#ifdef PORT_DO_WARN
/* Only warn when compiling port.c; might get here when using
 * --disable-binary. */
#warning Don�t know how to create Inf on the system!
#endif
#define MAKE_INF(s) ((s)*LDEXP(1.0, 1024))
#endif /* HUGE_VAL */
#endif /* HAVE_INFNAN */

#ifdef HAVE_INFNAN
#define MAKE_NAN() (infnan(EDOM))
#else
#ifdef HAVE_NAN
/* C99 provides a portable way of generating NaN */
#define MAKE_NAN() (nan(""))
#else
#ifdef NAN
#define MAKE_NAN() (NAN)
#else
#ifdef PORT_DO_WARN
#warning Don�t know how to create NaN on this system!
#endif
#define MAKE_NAN() (0.0)
#endif /* NAN */
#endif /* HAVE_NAN */
#endif /* HAVE_INFNAN */

#endif /* FLOAT_IS_IEEE_LITTLE */
#endif /* FLOAT_IS_IEEE_BIG */
#endif /* DOUBLE_IS_IEEE_LITTLE */
#endif /* DOUBLE_IS_IEEE_BIG */

#ifdef __MINGW32__
#ifndef HAVE__DOSMAPERR
void _dosmaperr(int x);
#endif
#endif

#ifdef __clang__
#define PIKE_CLANG_FEATURE(x)   __has_feature(x)
#define PIKE_CLANG_BUILTIN(x)   __has_builtin(x)
#else
#define PIKE_CLANG_FEATURE(x)	(0)
#define PIKE_CLANG_BUILTIN(x)   (0)
#endif

#endif
