#undef PL_version
#define PL_version Perl_PL_version

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#undef PL_version
#define PL_version SWI_PL_version

#include <SWI-Prolog.h>
