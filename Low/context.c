#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "Low.h"
#include "context.h"


#ifndef MULTIPLICTY
my_cxt_t my_cxt;
#endif


void init_cxt(pTHX) {
    MY_CXT_INIT;
    /* warn ("initializing Yaswi::Low cxt"); */

    c_depth=get_sv(PKG "::depth", 1);
    SvREFCNT_inc(c_depth);
    sv_setsv(c_depth, &PL_sv_undef);

    c_qid=get_sv(PKG "::qid", 1);
    SvREFCNT_inc(c_qid);
    sv_setsv(c_qid, &PL_sv_undef);

    c_query=get_sv(PKG "::query", 1);
    SvREFCNT_inc(c_query);
    sv_setsv(c_query, &PL_sv_undef);

    c_fids=get_av(PKG "::fids", 1);
    SvREFCNT_inc(c_fids);
    av_clear(c_fids);

    c_cells=gv_fetchpv(PKG "::cells", GV_ADDMULTI, SVt_PVAV);
    SvREFCNT_inc(c_cells);
    av_clear(GvAV(c_cells));

    c_vars=gv_fetchpv(PKG "::vars", GV_ADDMULTI, SVt_PVAV);
    SvREFCNT_inc(c_vars);
    av_clear(GvAV(c_vars));

    c_cache=gv_fetchpv(PKG "::vars_cache", GV_ADDMULTI, SVt_PVHV);
    SvREFCNT_inc(c_cache);
    hv_clear(GvHV(c_cache));

    c_converter=get_sv(PKG "::converter", 1);
    SvREFCNT_inc(c_converter);
    /* sv_setsv(c_converter, &PL_sv_undef); */

    c_prolog_ok=0;
    c_prolog_init=0;
}


void release_cxt(pTHX_ pMY_CXT) {
    SvREFCNT_dec(c_converter);
    SvREFCNT_dec(c_cache);
    SvREFCNT_dec(c_vars);
    SvREFCNT_dec(c_cells);
    SvREFCNT_dec(c_fids);
    SvREFCNT_dec(c_query);
    SvREFCNT_dec(c_qid);
    SvREFCNT_dec(c_depth);
}
