use Test::More tests => 8;

use strict;
use warnings;

use Language::Prolog::Types ':short';
use Language::Prolog::Types::overload;
use Language::Prolog::Sugar functors => [qw( man god mortal foobolize)],
                            vars     => [qw( X )];

use Language::Prolog::Yaswi qw(:query :assert :load);

swi_assert(mortal(X) => man(X));

swi_facts(man('socrates'),
	  man('bush'),
	  god('zeus'));


swi_set_query(mortal(X));

ok( swi_next(), 'swi_next 1');
is( swi_var(X), 'socrates', 'swi_var 1');

ok( swi_next(), 'swi_next 2');
is( swi_var(X), 'bush', 'swi_var 2');

ok( !swi_next(), 'swi_next ends');

is_deeply( [swi_find_all(man(X),X)], ['socrates', 'bush'], 'swi_find_all');

is( swi_find_one(god(X), X), 'zeus', 'swi_find_one');

swi_inline <<CODE;

:- module(foo, [foobolize/1]).

foobolize(foo).
foobolize(bar).

CODE

is_deeply( [swi_find_all(foobolize(X), X )], [qw(foo bar)], "swi_inline");

