#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "context.h"
#include "plconfig.h"
#include "argv.h"
#include "swi2perl.h"
#include "perl2swi.h"
#include "opaque.h"
#include "frames.h"
#include "vars.h"
#include "query.h"
#include "callperl.h"
#include "engines.h"
#include "Low.h"

/* START_MY_CXT */


void savestate_Low(pTHX_ pMY_CXT) {
    save_item(c_depth);
    sv_inc(c_depth);
}

MODULE = Language::Prolog::Yaswi::Low   PACKAGE = Language::Prolog::Yaswi::Low   PREFIX = yaswi_

BOOT:
{
    dTHX;
    init_cxt(aTHX);
    boot_callperl();
}

PROTOTYPES: ENABLE

void
yaswi_CLONE()
CODE:
    init_cxt(aTHX);


SV *
yaswi_OPAQUE_PREFIX()
CODE:
    RETVAL=newSVpv(OPAQUE_PREFIX, 0);
OUTPUT:
    RETVAL


void
yaswi_END()
PREINIT:
    dMY_CXT;
CODE:
    /* warn ("calling END code (thread=%i)", PL_thread_self()); */
    release_prolog(aTHX_ aMY_CXT);
    release_cxt(aTHX_ aMY_CXT);


SV *
yaswi_PL_EXE()
CODE:
    RETVAL=newSVpv(PL_exe, 0);
OUTPUT:
    RETVAL


void
yaswi_start()
PREINIT:
    dMY_CXT;
CODE:
    if (PL_is_initialised(NULL, NULL)) {
	croak ("SWI-Prolog engine already initialised");
    }
    check_prolog(aTHX_ aMY_CXT);


void
yaswi_cleanup()
PREINIT:
    dMY_CXT;
CODE:
    test_no_query(aTHX_ aMY_CXT);
    if (SvIV(c_depth) > 1) {
	croak ("swi_cleanup called from call back");
    }
    release_prolog(aTHX_ aMY_CXT);


int
yaswi_toplevel()
PREINIT:
    dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    RETVAL=PL_toplevel();
OUTPUT:
    RETVAL


SV *
yaswi_swi2perl(term)
    SV *term;
PREINIT:
    dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    if (!SvIOK(term)) {
	croak ("'%_' is not a valid SWI-Prolog term", term);
    }
    RETVAL=swi2perl(aTHX_ SvIV(term),
		    get_cells(aTHX_ aMY_CXT));
OUTPUT:
    RETVAL


void
yaswi_openquery(query_obj, module, ctx_module)
    SV *query_obj;
    SV *module;
    SV *ctx_module
PREINIT:
    dMY_CXT;
    term_t q, arg0;
    functor_t functor;
    module_t m, cm;
    predicate_t predicate;
    AV *refs, *cells;
PPCODE:
    check_prolog(aTHX_ aMY_CXT);
    test_no_query(aTHX_ aMY_CXT);
    q=perl2swi_sv(aTHX_
		  query_obj,
		  refs=(AV *)sv_2mortal((SV *)newAV()),
		  cells=(AV *)sv_2mortal((SV *)newAV()));
    if (PL_is_atom(q)) {
	atom_t name;
	PL_get_atom(q, &name);
	functor=PL_new_functor(name, 0);
	arg0=PL_new_term_ref();
    }
    else if (PL_is_compound(q)) {
	int arity, i;
	PL_get_functor(q, &functor);
	arity=PL_functor_arity(functor);
	arg0=PL_new_term_refs(arity);
	for (i=0; i<arity; i++) {
	    PL_unify_arg(i+1, q, arg0+i);
	}
    }
    else {
	die ("query is unknow\n");
    }
    perl2swi_module(aTHX_ module, &m);
    predicate=PL_pred(functor, m);
    perl2swi_module(aTHX_ ctx_module, &cm);
    sv_setiv(c_qid, PL_open_query(cm,
				  PL_Q_NODEBUG|PL_Q_CATCH_EXCEPTION,
				  predicate, arg0));
    /* warn("open_query(%_)", qid); */
    sv_setiv(c_query, q);
    push_frame(aTHX_ aMY_CXT);
    set_vars(aTHX_ aMY_CXT_ refs, cells);
    XPUSHs(sv_2mortal(newRV_inc((SV *)refs)));

void
yaswi_cutquery()
PREINIT:
    dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    test_query(aTHX_ aMY_CXT);
    cut_query(aTHX_ aMY_CXT);

int
yaswi_nextsolution()
PREINIT:
    dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    test_query(aTHX_ aMY_CXT); 
    cut_anonymous_vars(aTHX_ aMY_CXT);
    pop_frame(aTHX_ aMY_CXT);
    /* warn ("next_solution(qid=%_)", qid); */
    if(PL_next_solution(SvIV(c_qid))) {
	push_frame(aTHX_ aMY_CXT);
	RETVAL=1;
    }
    else {
	term_t e;
	RETVAL=0;
	if (e=PL_exception(SvIV(c_qid))) {
	    /* warn ("exception cached"); */
	    SV *errsv = get_sv("@", TRUE);
	    sv_setsv( errsv,
		      sv_2mortal(swi2perl(aTHX_
					  e,
					  get_cells(aTHX_ aMY_CXT))));
	    close_query(aTHX_ aMY_CXT);
	    croak(Nullch);
	    /* croak ("exception pop up from Prolog"); */
	}
	else {
	    close_query(aTHX_ aMY_CXT);
	}
    }
OUTPUT:
    RETVAL
    
void
yaswi_testquery()
PREINIT:
    dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    test_query(aTHX_ aMY_CXT);


IV
yaswi_ref2int(rv)
    SV *rv;
CODE:
    if (!SvROK(rv)) {
	croak ("value passed to ref2int is not a reference");
    }
    RETVAL=(IV) SvRV(rv);
OUTPUT:
    RETVAL
