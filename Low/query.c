#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "context.h"

#include "frames.h"
#include "Low.h"
#include "vars.h"
#include "query.h"

/* SV *qid; */
/* SV *query; */


void savestate_query(pTHX_ pMY_CXT) {
    save_item(c_qid);
    sv_setsv(c_qid, &PL_sv_undef);
    save_item(c_query);
    sv_setsv(c_query, &PL_sv_undef);
}

void close_query(pTHX_ pMY_CXT) {
    /* warn ("close_query(qid=%_)", qid); */
    PL_close_query(SvIV(c_qid));
    clear_vars(aTHX_ aMY_CXT);
    sv_setsv(c_query, &PL_sv_undef);
    sv_setsv(c_qid, &PL_sv_undef);
    rewind_frame(aTHX_ aMY_CXT);
}

void cut_query(pTHX_ pMY_CXT) {
    pop_frame(aTHX_ aMY_CXT);
    close_query(aTHX_ aMY_CXT);
}

void test_no_query(pTHX_ pMY_CXT) {
    if(SvOK(c_qid)) {
	croak ("there is already an open query (qid=%_)", c_qid);
    }
}

void test_query(pTHX_ pMY_CXT) {
    if(!SvOK(c_qid)) {
	croak ("there is not open query");
    }
}

int is_query(pTHX_ pMY_CXT) {
    return SvOK(c_qid);
}
