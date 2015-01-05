#ifdef __SSE4_2__
# include <smmintrin.h>
#endif
#include "cyclic.h"
#include "global.h"
#include "interpret.h"
#include "mapping.h"
#include "module.h"
#include "array.h"
#include "pike_error.h"
#include "pike_float.h"
#include "pike_types.h"
#include "stralloc.h"
#include "svalue.h"
#include "array.h"
#include "operators.h"
#include "builtin_functions.h"

#include "dmalloc.h"

#ifndef CB_NODE_ALLOC
# define CB_NODE_ALLOC()	((cb_node_t)xalloc(sizeof(cb_node)))
#endif
#ifndef CB_NODE_FREE
# define CB_NODE_FREE(p)	xfree(p)
#endif

#define CB_STATIC
#define CB_INLINE
#define CB_SOURCE
#define CB_NAMESPACE
