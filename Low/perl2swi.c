#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "Low.h"
#include "callback.h"
#include "hook.h"
#include "opaque.h"
#include "perl2swi.h"


/* prototypes */

static term_t perl2swi_ifunctor(pTHX_ SV *o, AV *refs, AV *cells);
static term_t perl2swi_array(pTHX_ 
			     AV *array, int u,
			     AV *refs, AV *cells);
static term_t perl2swi_nil(AV *refs, AV *terms);
static term_t perl2swi_ilist(pTHX_ SV *o, AV *refs, AV *cells);
static term_t perl2swi_iulist(pTHX_ SV *o, AV *refs, AV *cells);
static term_t perl2swi_list(pTHX_ SV *o, AV *refs, AV *cells);
static term_t perl2swi_functor(pTHX_ SV *o, AV *refs, AV *cells);
static term_t perl2swi_var(pTHX_ SV *sv, AV *refs, AV *cells);
static term_t perl2swi_opaque(pTHX_ SV *o, AV *refs, AV *cells);
static term_t perl2swi_any_ref(pTHX_ SV *ref, AV *refs, AV *cells);
static term_t perl2swi_object(pTHX_ SV *sv, AV *refs, AV *cells);
static term_t lookup_ref(pTHX_ SV *sv, AV *refs, AV *cells);
static term_t perl2swi_rv(pTHX_ SV *sv, AV *refs, AV *cells);


SV *converter;


static SV *my_fetch (pTHX_ AV *av, int i) {
    SV **sv_p=av_fetch(av, i, 0);
    return (sv_p ? *sv_p : &PL_sv_undef);
}


static term_t perl2swi_ifunctor(pTHX_ SV *o, AV *refs, AV *cells) {
    if(SvTYPE(o)==SVt_PVAV) {
	AV *array=(AV *)o;
	int i;
	int arity=av_len(array);
	term_t t=PL_new_term_ref();
	atom_t name=PL_new_atom(SvPV_nolen(my_fetch(aTHX_ array, 0)));
	PL_put_functor(t, PL_new_functor(name, arity));
	PL_unregister_atom(name);
	for(i=1; i<=arity; i++) {
	    PL_unify_arg(i, t,
			 perl2swi_sv(aTHX_
				     my_fetch(aTHX_ array, i),
				     refs, cells));
	}
	return t;
    }
    else 
	die ("implementation mismatch, " TYPEINTPKG "::functor object is not an array ref");
    return -1;
}

static term_t perl2swi_array(pTHX_
			     AV *array, int u,
			     AV *refs, AV *cells) {
    int i;
    int len=av_len(array);
    term_t tail, list;

    /* warn ("perl2swi_array(%_, %i, %_, %_)\n", array, u, refs, cells); */

    if(u) {
	if (len<0)
	    die ("implementation mismatch, " TYPEINTPKG "::ulist object is an array with less than one element\n");
	--len;
	tail=perl2swi_sv(aTHX_
			 my_fetch(aTHX_ array, len),
			 refs, cells);
    }
    else {
	tail=perl2swi_nil(refs, cells);
    }
    for(i=len;i>=0;tail=list, --i) {
	list=PL_new_term_ref();
	PL_cons_list(list,
		     perl2swi_sv(aTHX_
				 my_fetch(aTHX_ array, i),
				 refs, cells),
		     tail);
    }
    return tail;
}

static term_t perl2swi_nil(AV *refs, AV *terms) {
    term_t t=PL_new_term_ref();
    PL_put_nil(t);
    return t;
}

static term_t perl2swi_ilist(pTHX_ SV *o, AV *refs, AV *cells) {
    if(SvTYPE(o)==SVt_PVAV)
	return perl2swi_array(aTHX_ (AV *)o, 0, refs, cells);
    else
	die ("implementation mismatch, " TYPEINTPKG "::list object is not an array ref");
    return -1;
}

static term_t perl2swi_iulist(pTHX_ SV *o, AV *refs, AV *cells) {
    if(SvTYPE(o)==SVt_PVAV)
	return perl2swi_array(aTHX_ (AV *)o, 1, refs, cells);
    else
	die ("implementation mismatch, " TYPEINTPKG "::list object is not an array ref");
    return -1;
}

static term_t perl2swi_list(pTHX_ SV *o, AV *refs, AV *cells) {
    dSP;
    int i;
    int len;
    term_t tail, list;

    len=call_method__int(aTHX_ o, "length");
    tail=perl2swi_sv( aTHX_
		      call_method__sv(aTHX_ o, "tail"),
		      refs, cells );

    for (i=len; --i>=0; tail=list) {
	ENTER;
	SAVETMPS;
	list=PL_new_term_ref();
	PL_cons_list(list,
		     perl2swi_sv( aTHX_
				  call_method_int__sv(aTHX_ o, "larg", i),
				  refs, cells ),
		     tail);
	FREETMPS;
	LEAVE;
    }
    return tail;
}

static term_t perl2swi_functor(pTHX_ SV *o, AV *refs, AV *cells) {
    dSP;
    int i;
    int arity=call_method__int(aTHX_ o, "arity");
    term_t t=PL_new_term_ref();
    term_t arg0=PL_new_term_refs(arity);
    atom_t name;
    for(i=0; i<arity; i++) {
	ENTER;
	SAVETMPS;
	PL_unify(arg0+i, 
		 perl2swi_sv(aTHX_
			     call_method_int__sv(aTHX_ o, "farg", i),
			     refs, cells));
	FREETMPS;
	LEAVE;
    }
    name=PL_new_atom(SvPV_nolen(call_method__sv(aTHX_ o,"functor")));
    PL_cons_functor_v(t,
		      PL_new_functor(name, arity),
		      arg0);
    PL_unregister_atom(name);
    return t;
}

static term_t perl2swi_var(pTHX_ SV *sv, AV *refs, AV *cells) {
    term_t t=PL_new_term_ref();
    /* PL_put_variable(t); */
    return t;
}

static term_t perl2swi_opaque(pTHX_ SV *o, AV *refs, AV *cells) {
    dSP;
    SV *key;
    term_t t;
    ENTER;
    SAVETMPS;
    key=call_sub_sv__sv(aTHX_
			PKG "::register_opaque",
			call_method__sv(aTHX_
					o,
					"opaque_reference"));
    if (!hook_set) set_my_agc_hook();
    t=PL_new_term_ref();
    PL_unify_term(t,
		  PL_FUNCTOR_CHARS, OPAQUE_FUNCTOR, 3,
		  PL_CHARS, SvPV_nolen(key),
		  PL_TERM, perl2swi_sv(aTHX_
				       call_method__sv(aTHX_
						       o,
						       "opaque_class"),
				       refs, cells),
		  PL_TERM, perl2swi_sv(aTHX_
				       call_method__sv(aTHX_
						       o,
						       "opaque_comment"),
				       refs, cells));
    FREETMPS;
    LEAVE;
    return t;
}

static term_t perl2swi_any_ref(pTHX_ SV *ref, AV *refs, AV *cells) {
    /* warn ("Converting Perl ref -> Prolog term\n"); */
    return perl2swi_sv( aTHX_
			call_method_sv__sv(aTHX_
					   converter, "perl_ref2prolog", ref),
		        refs, cells);
}

static term_t perl2swi_object(pTHX_ SV *sv, AV *refs, AV *cells) {
    /* warn ("perl2swi_object(%_, %_, %_)\n", sv, refs, cells); */
    if (sv_derived_from(sv, TYPEPKG "::Term")) {
	if (sv_isa(sv,TYPEINTPKG "::list")) {
	    return perl2swi_ilist(aTHX_ SvRV(sv), refs, cells);
	}
	else if(sv_isa(sv, TYPEINTPKG "::ulist")) {
	    return perl2swi_iulist(aTHX_ SvRV(sv), refs, cells);
	}
	else if (sv_isa(sv, TYPEINTPKG "::functor")) {
	    return perl2swi_ifunctor(aTHX_ SvRV(sv), refs, cells);
	}
	else if (sv_isa(sv, TYPEINTPKG "::nil")) {
	    return perl2swi_nil(refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::UList")) {
	    return perl2swi_list(aTHX_ sv, refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::List")) {
	    return perl2swi_list(aTHX_ sv, refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::Functor")) {
	    return perl2swi_functor(aTHX_ sv, refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::Variable")) {
	    return perl2swi_var(aTHX_ sv, refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::Opaque")) {
	    return perl2swi_opaque(aTHX_ sv, refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::Nil")) {
	    return perl2swi_nil(refs, cells);
	}
	else {
	    die ("unable to convert "TYPEPKG"::Term object '%s' to Prolog term",
		  SvPV_nolen(sv));
	    return -1;
	}
    }
    else
	return perl2swi_any_ref(aTHX_ sv, refs, cells);
}

static term_t lookup_ref(pTHX_ SV *sv, AV *refs, AV *cells) {
    int i;
    int len=av_len(refs);
    /* warn ("lookup_ref(%_, %_, %_)\n", sv, refs, cells); */
    if(sv_isobject(sv) && sv_derived_from(sv, TYPEPKG "::Variable")) {
	/* variables are the same if they have the same name, even if
	 * they have different references */
	dSP;
	SV *name;
	ENTER;
	SAVETMPS;
	name=call_method__sv(aTHX_ sv, "name");
	for (i=0; i<=len; i++) {
	    SV *ref=my_fetch(aTHX_ refs, i);
	    if ( sv_isobject(ref) &&
		 sv_derived_from(ref, TYPEPKG "::Variable") &&
		 !sv_cmp(name, call_method__sv(aTHX_ ref, "name"))) {
		break;
	    }
	}
	FREETMPS;
	LEAVE;
    }
    else {
	SV *new_ref=SvRV(sv);
	for (i=0; i<=len; i++) {
	    SV **ref_p=av_fetch(refs, i, 0);
	    if(!ref_p)
		die ("internal error, unable to fetch reference pointer from references cache");
	    if (new_ref==SvRV(*ref_p))
		break;
	}
    }
    if (i<=len) {
	SV **cell_p=av_fetch(cells, i, 0);
	if(!cell_p || !SvOK(*cell_p)) {
	    warn ("cycled reference passed to Prolog as nil\n");
	    return perl2swi_nil( refs, cells);
	}
	return SvIV(*cell_p);
    }
    /* warn ("%_ is not in cache\n", sv); */
    return -1;
}

static term_t perl2swi_rv(pTHX_ SV *sv, AV *refs, AV *cells) {
    term_t t;
    /* warn ("perl2swi_rv(%_, %_, %_)\n", sv, refs, cells); */
    if ((t=lookup_ref(aTHX_ sv, refs, cells))==-1) {
	SV *cell;
	int cell_index;
	/* warn ("creating new term for ref\n"); */
	SvREFCNT_inc(sv);
	av_push(refs, sv);
	cell_index=av_len(refs);
	if(sv_isobject(sv)) {
	    /* warn ("%_ is object\n", sv); */
	    t=perl2swi_object(aTHX_ sv, refs, cells);
	}
	else {
	    SV *val=SvRV(sv);
	    if(SvTYPE(val)==SVt_PVAV) {
		/* warn ("converting array\n"); */
		t=perl2swi_array(aTHX_ (AV *)val, 0, refs, cells);
	    }
	    else {
		/* warn ("converting any ref\n"); */
		t=perl2swi_any_ref(aTHX_ sv, refs, cells);
	    }
	}
	/* store cell in cache */
	cell=newSViv(t);
	/* SvREADONLY_on(cell); */
	if(!av_store(cells, cell_index, cell)) {
	    die("unable to store cell in cells cache\n");
	}
    }
    return t;
}

term_t perl2swi_sv(pTHX_ SV *sv, AV *refs, AV *cells) {
    /* warn ("perl2swi_sv(%_, %_, %_)\n", sv, refs, cells); */
    if (!SvOK(sv)) {
	return perl2swi_nil(refs, cells);
    }
    else if (SvROK(sv)) {
	/* warn ("converting ref %_ to term", sv); */
	return perl2swi_rv(aTHX_ sv, refs, cells);
    }
    else {
	term_t t=PL_new_term_ref();
	/* warn ("converting scalar %_ to term", sv); */
	if (SvIOK(sv)) {
	    PL_put_integer(t, SvIV(sv));
	}
	else if (SvNOK(sv)) {
	    PL_put_float(t, SvNV(sv));
	}
	else if (SvPOK(sv)) {
	    PL_put_atom_chars(t, SvPV_nolen(sv));
	}
	else {
	    die ("unable to convert unknow type '%s' to Prolog term",
		 SvPV_nolen(sv));
	}
	return t;
    }
}

void perl2swi_module(pTHX_ SV *sv, module_t *m) {
    /* warn ("converting %_ to module\n", sv); */
    if(SvOK(sv)) {
	atom_t name=PL_new_atom(SvPV_nolen(sv));
	PL_get_module(name, m);
	PL_unregister_atom(name);	
    }
    else {
	*m=NULL;
    }
}
