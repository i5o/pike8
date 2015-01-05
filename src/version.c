/*
|| This file is part of Pike. For copyright information see COPYRIGHT.
|| Pike is distributed under GPL, LGPL and MPL. See the file COPYING
|| for more information.
*/

#include "global.h"
#include "svalue.h"
#include "interpret.h"
#include "stralloc.h"
#include "version.h"

/*! @decl string version()
 *!
 *! Report the version of Pike. Does the same as
 *! @code
 *! sprintf("Pike v%d.%d release %d", __REAL_VERSION__,
 *!         __REAL_MINOR__, __REAL_BUILD__);
 *! @endcode
 *!
 *! @seealso
 *!   @[__VERSION__], @[__MINOR__], @[__BUILD__],
 *!   @[__REAL_VERSION__], @[__REAL_MINOR__], @[__REAL_BUILD__],
 */
PMOD_EXPORT void f_version(INT32 args)
{
  pop_n_elems(args);
  push_text ("Pike v"
		      DEFINETOSTR (PIKE_MAJOR_VERSION)
		      "."
		      DEFINETOSTR (PIKE_MINOR_VERSION)
		      " release "
		      DEFINETOSTR (PIKE_BUILD_VERSION));
}

void push_compact_version(void)
{
  push_constant_string_code (str, {
      p_wchar2 *wstr;
      str = begin_wide_shared_string (3, 2);
      wstr = STR2(str);
      wstr[0] = PIKE_MAJOR_VERSION;
      wstr[1] = PIKE_MINOR_VERSION;
      wstr[2] = PIKE_BUILD_VERSION;
      str = end_shared_string (str);
    });
}
