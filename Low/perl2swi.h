


int pl_unify_perl_sv(pTHX_ term_t t, SV *sv, AV *refs, AV *cells);
int pl_unify_perl_av(pTHX_ term_t t, AV *array, int u, AV *refs, AV *cells);

void perl2swi_module(pTHX_ SV *sv, module_t *m);
