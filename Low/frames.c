#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "context.h"
#include "Low.h"
#include "frames.h"


fid_t frame(pTHX_ pMY_CXT) {
    SV **w;
    int len=av_len(c_fids);
    if (len<0) {
	die ("frame called and frame stack is empty");
    }
    w=av_fetch(c_fids, len, 0);
    if (!w) {
	die ("corrupted frame stack");
    }
    return SvIV(*w);
}

void push_frame(pTHX_ pMY_CXT) {
    SV *fid=newSViv(PL_open_foreign_frame());
    /* warn ("push_frame(%_)", fid); */
    av_push(c_fids, fid);
}

void pop_frame(pTHX_ pMY_CXT) {
    SV *fid=av_pop(c_fids);
    /* warn ("pop_frame(%_)", fid); */
    if (!SvOK(fid)) {
	die ("pop_frame called but frame stack is empty");
    }
    PL_discard_foreign_frame(SvIV(fid));
    SvREFCNT_dec(fid);
}

void rewind_frame(pTHX_ pMY_CXT) {
    fid_t fid=frame(aTHX_ aMY_CXT);
    /* warn ("rewind_frame(%i)", fid); */
    PL_rewind_foreign_frame(fid);
}

