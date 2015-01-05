/* Integer types with defined sizes.
 *
 * Extracted from global.h 1.90
 */

/* NB: This file is multiple-inclusion protected on a fine-grained level,
 *     to support simple restoring of the macros if needed due to
 *     system headerfile conflicts (eg <X11/Xmd.h> on AIX 4.2).
 */

/* We here define a few types with more defined values */

/* First INT64
 *
 * Select variants in portability order:
 *   long	C89/LP64
 *   long long	C99 & gcc2
 *   __int64	lc & icc
 */
#ifndef INT64
# if SIZEOF_LONG >= 8
#  define INT64 long
#  define UINT64 unsigned long
# elif SIZEOF_LONG_LONG - 0 >= 8
#  define INT64 long long
#  define UINT64 unsigned long long
# elif SIZEOF___INT64 - 0 >= 8
#  define INT64 __int64
#  define UINT64 unsigned __int64
# endif
#endif /* !INT64 */

/* NB: Use same order as in definition of INT64! */
#ifdef INT64
# ifndef SIZEOF_INT64
#  if SIZEOF_LONG >= 8
#   define SIZEOF_INT64 SIZEOF_LONG
#  elif SIZEOF_LONG_LONG - 0 >= 8
#   define SIZEOF_INT64 SIZEOF_LONG_LONG
#  elif SIZEOF___INT64 - 0 >= 8
#   define SIZEOF_INT64 SIZEOF___INT64
#  else
    /* We probably ought to warn here, but... */
#   define SIZEOF_INT64 8
#  endif
# endif
# ifndef MAX_INT64
#  if SIZEOF_LONG >= 8
#    define MAX_UINT64 ULONG_MAX
#    define MAX_INT64 LONG_MAX
#    define MIN_INT64 LONG_MIN
#  elif SIZEOF_LONG_LONG - 0 >= 8
#   ifdef LLONG_MAX
#    define MAX_UINT64 ULLONG_MAX
#    define MAX_INT64 LLONG_MAX
#    define MIN_INT64 LLONG_MIN
#   elif defined(LONG_LONG_MAX)
#    define MAX_UINT64 ULONG_LONG_MAX
#    define MAX_INT64 LONG_LONG_MAX
#    define MIN_INT64 LONG_LONG_MIN
#   else
#    define MAX_UINT64 0xffffffffffffffffULL
#    define MAX_INT64 0x7fffffffffffffffLL
#    define MIN_INT64 (-0x7fffffffffffffffLL - 1LL)
#   endif
#  elif SIZEOF___INT64 - 0 >= 8
#   define MAX_UINT64 _UI64_MAX
#   define MAX_INT64 _I64_MAX
#   define MIN_INT64 _I64_MIN
#  else
    /* We probably ought to warn here, but... */
#   define MAX_UINT64 0xffffffffffffffffULL
#   define MAX_INT64 0x7fffffffffffffffLL
#   define MIN_INT64 (-0x7fffffffffffffffLL - 1LL)
#  endif
# endif
#endif

/* Check for __int128 here (and its unsigned companion)
 *  There is no way to express 128 bit integer constants, so we have to
 *  put them together
 */
#ifndef INT128
# if SIZEOF___INT128 - 0 >= 16
#  define INT128 __int128
# elif SIZEOF___INT128_T - 0 >= 16
#  define INT128 __int128_t
# endif
# ifdef INT128
#  define MAX_INT128	(((INT128)MAX_INT64 << 64) | (INT128)MAX_UINT64)
#  define MIN_INT128	(-MAX_INT128 - (INT128)1)
# endif
#endif
#ifndef UINT128
# if SIZEOF_UNSIGNED___INT128 - 0 >= 16
#  define UINT128 unsigned __int128
# elif SIZEOF_UNSIGNED___INT128_T - 0 >= 16
#  define UINT128 unsigned __int128_t
# elif SIZEOF___UINT128_T - 0 >= 16
#  define UINT128 __uint128_t
# endif
# ifdef UINT128
#  define MAX_UINT128	(((UINT128)MAX_UINT64 << 64) | (UINT128)MAX_UINT64)
# endif
#endif


/* Then INT32 */
#ifndef INT32
# if SIZEOF_SHORT >= 4
#  define INT32 short
# elif SIZEOF_INT >= 4
#  define INT32 int
# else
#  define INT32 long
# endif
#endif
#ifndef MAX_INT32
# define MAX_UINT32 4294967295U
# define MAX_INT32 2147483647
# define MIN_INT32 (-2147483647-1)
#endif

/* INT16 */
#ifndef INT16
# define INT16 short
#endif

#ifndef MAX_INT16
# define MAX_UINT16 65535
# define MAX_INT16 32767
# define MIN_INT16 (-32768)
#endif

/* and INT8 */
#ifndef INT8
# define INT8 char
#endif

#ifndef MAX_INT8
# define MAX_UINT8 255
# define MAX_INT8 127
# define MIN_INT8 (-128)
#endif

#ifdef INT64
# define LONGEST INT64
# define PRINTLONGEST PRINTINT64
# define MAX_ULONGEST MAX_UINT64
# define MAX_LONGEST MAX_INT64
# define MIN_LONGEST MIN_INT64
# define SIZEOF_LONGEST SIZEOF_INT64
#else
# define LONGEST INT32
# define PRINTLONGEST ""
# define MAX_ULONGEST MAX_UINT32
# define MAX_LONGEST MAX_INT32
# define MIN_LONGEST MIN_INT32
# define SIZEOF_LONGEST 4
#endif

#if SIZEOF_TIME_T == SIZEOF_INT
# define MAX_TIME_T INT_MAX
# define MIN_TIME_T INT_MIN
#elif SIZEOF_TIME_T == SIZEOF_LONG
# define MAX_TIME_T LONG_MAX
# define MIN_TIME_T LONG_MIN
#elif SIZEOF_TIME_T == SIZEOF_SHORT
# define MAX_TIME_T SHORT_MAX
# define MIN_TIME_T SHORT_MIN
#elif SIZEOF_TIME_T == SIZEOF_INT64
# define MAX_TIME_T MAX_INT64
# define MIN_TIME_T MIN_INT64
#else
# define MAX_TIME_T MAX_INT32
# define MIN_TIME_T MIN_INT32
#endif
