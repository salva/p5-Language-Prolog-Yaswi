package Language::Prolog::Yaswi;

our $VERSION = '0.05';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'query' => [ qw( swi_set_query
				      swi_set_query_module
				      swi_result
				      swi_next
				      swi_var
				      swi_query
				      swi_cut
				      swi_find_all
				      swi_find_one
				      swi_call )],
		     'assert' => [ qw( swi_assert
				       swi_asserta
				       swi_assertz
				       swi_facts  )],
		     'interactive' => [ qw( swi_toplevel )],
		     'context' => [ qw( $swi_module
					$swi_ctx_module
					$swi_converter) ],
		     'run' => [ qw( swi_init
				    swi_cleanup )] );

our @EXPORT_OK = ( @{$EXPORT_TAGS{query}},
		   @{$EXPORT_TAGS{assert}},
		   @{$EXPORT_TAGS{interactive}},
		   @{$EXPORT_TAGS{context}},
		   @{$EXPORT_TAGS{run}} );

our @EXPORT = qw();

use Carp;
use Language::Prolog::Types qw(:util F L C isV isL);

use Language::Prolog::Yaswi::Low;

our $swi_module=undef;
our $swi_ctx_module=undef;

sub swi_init;
*swi_init=\&init;

sub swi_cleanup();
*swi_cleanup=\&cleanup;

sub swi_toplevel();
*swi_toplevel=\&toplevel;

*swi_converter=*converter;

sub swi_set_query_module($$$) {
    @{&openquery(@_)}
}

sub swi_cut();
*swi_cut=\&cutquery;


sub swi_set_query (@) {
    # warn "swi_set_query(@_)\n";
    return swi_set_query_module(C(',', @_),
				$swi_module,
				$swi_ctx_module);
}

sub swi_next() {
    package main;
    Language::Prolog::Yaswi::Low::nextsolution();
}

sub swi_query {
    testquery();
    getquery();
}

sub swi_var($) {
    testquery();
    getvar($_[0]);
}

sub swi_result() {
    testquery();
    getallvars();
}

sub map_vars {
    testquery();
    return map {
	isV($_)     ? getvar($_) :
        isL($_)     ? L(_vars(prolog_list2perl_list($_))) :
        ($_ eq '*') ? getquery() :
	(ref($_) eq '') ? $_ :
	croak "invalid mapping '$_'";
    } @_;
}

sub swi_find_all ($;@) {
    my @r;
    swi_set_query(shift);
    while (swi_next) {
	# warn "new solution found\n";
	push @r, map_vars(@_);
    }
    return @r
}

sub swi_find_one ($;@) {
    swi_set_query(shift);
    if (swi_next) {
	my @r=map_vars(@_);
	swi_cut;
	return wantarray ? @r : $r[0];
    }
    return ();
}

sub swi_call {
    swi_set_query(@_);
    if (swi_next) {
	swi_cut;
	return 1;
    }
    return undef;
}

sub swi_assertz {
    my $head=shift;
    defined $head or croak "swi_assertz called without head";
    swi_call F(assertz => C(':-' => $head, C(',', @_)))
}

*swi_assert=\&swi_assertz;

sub swi_asserta {
    my $head=shift;
    defined $head or croak "swi_asserta called without head";
    swi_call F(asserta => C(':-' => $head, C(',', @_)))
}

sub swi_facts {
    return swi_call C(',', (map { F(assertz => $_) } @_));
}

1;
__END__


=head1 NAME

Language::Prolog::Yaswi - Yet another interface to SWI-Prolog

=head1 SYNOPSIS

  use Language::Prolog::Yaswi ':query';
  use Language::Prolog::Types::overload;
  use Language::Prolog::Sugar functors => { equal => '='
                                            is    => 'is' },
                              chains => { orn => ';',
                                          andn => ',',
                                          add => '+' },
                              vars => [qw (X Y Z)];

  swi_set_query( equal(X, Y),
                 orn( equal(X, 27),
                      equal(Y, 'hello')));

  while (swi_next) {
      printf "Query=".swi_query()."\n";
      printf "  X=%_, Y=%_\n\n", swi_var(X), swi_var(Y);
  }

  print join("\n",
             xsb_findall(andn(equal(X, 2),
                              orn(equal(Y, 1),
                                  equal(Y, 3.1416))
                              is(Z, plus(X,Y,Y))),
                         [X, Y, Z]);

=head1 ABSTRACT

Language::Prolog::Yaswi implements a bidirectional interface to the
SWI-Prolog system (L<http://www.swi-prolog.org/>).


=head1 DESCRIPTION

This package provides a bidirectional interface to SWI-Prolog. That
means that Prolog code can be called from Perl that can call Perl code
again and so on:

  Perl -> Prolog -> Perl -> Prolog -> ...

(unfortunately, by now, the cicle has to be started from Perl,
although it is very easy to circunvent this limitation with the help
of a dummy Perl script that just calls Prolog the first time).

The interface is based on the set of classes defined in
Language::Prolog::Types. Package Language::Prolog::Sugar can also be
used to improve the look and readability of scripts mixing Perl and
Prolog code.

The interface to call Prolog from Perl is very simple, at least if you
are used to Prolog non deterministic nature.

=head2 SUBROUTINES

Grouped by export tag:

=over 4

=item C<:query>

=over 4

=item C<swi_set_query($query1, $query2, $query3, ...)>

Compose a query with all its parameters and sets it. Return the set of
free variables found in the query.

=item C<swi_set_query_module($query, $module, $ctx_module)>

Allows to set a query in a different module than the default.

=item C<swi_result()>

Return the values binded to the variables in the query.

=item C<swi_next()>

Iterates over the query solutions.

If a new solution is available returns true, if not, closes the query
and returns false.

It should be called after C<swi_set_query(...)> to obtain the first
solution.

=item C<swi_var($var)>

Returns the value binded to C<$var> in the current query/solution combination.

=item C<swi_query>

Returns the current query with the variables binded to its values in
the current solution (or unbinded if swi_next has not been called
yet).

=item C<swi_cut>

Closes the current query even if not all of its solutions have been
retrieved. Similar to prolog C<!>.

=item C<swi_find_all($query, @pattern)>

iterates over $query and returns and array with @pattern binded to
every solution. i.e:

  swi_find_all(member(X, [1, 3, 7, 21]), X)

returns the array C<(1, 3, 7, 21)> and

  swi_find_all(member(X, [1, 3, 7, 21]), [X])

returns the array C<([1], [3], [7], [21])>.

More elaborate constructions can be used:

  %mothers=swi_find_all(mother(X,Y), X, Y)


There is also an example of its usage in the SYNOPSIS.


=item C<swi_find_one($query, @pattern>

as C<swi_find_all> but only for the first solution.

=item C<swi_call>

runs the query once and return true if a solution was found or false
otherwise.

=back

=item C<:interactive>

=over 4

=item C<swi_toplevel>

mostly for debugging pourposes, runs SWI-Prolog shell.

=back

=item C<:assert>

=over 4

=item C<swi_assert($head =E<gt> @body)>

=item C<swi_assertz($head =E<gt> @body)>

add new definitions at the botton of the database

=item C<swi_asserta($head =E<gt> @body)>

adds new definitions at the top of the database

=item C<swi_facts(@facts)>

commodity subroutine to add several facts (facts, doesn't have body)
to the database in one call.

i.e.:

  use Language::Prolog::Sugar functors=>[qw(man woman)];

  swi_facts( man('teodoro'),
             man('socrates'),
             woman('teresa'),
             woman('mary') );

=back

=item C<:context>

=over 4



=item C<$swi_module>

=item C<$swi_ctx_module>

allow to change the module and the context module for the upcoming
queries.

use ALWAYS the C<local> operator when changing their values!!!

i.e.:

   local $swi_module='mymodule'
   swi_set_query($query_from_mymodule);

=item C<$swi_converter>

allows to change the way data is converter from Perl to Prolog.

You should not use it for any other thing that to configure perl
classes as opaque, i.e.:

  $swi_converter->pass_as_opaque(qw(LWP::UserAgent
                                    HTTP::Request
                                    HTTP::Result))

=back

=item C<:run>

=over 4

=item C<swi_init(@args)>

lets init the prolog engine with a different set of arguments
(identical to the command line arguments for the C<pl> SWI-Prolog
executable.

Defaults arguments are C<-q> to stop the SWI-Prolog welcome banner
for being printed to the console.

Language::Prolog::Yaswi will automatically create a new engine with
the default arguments (or with the last passed via swi_init), when
needed.

=item C<swi_cleanup()>

releases the prolog engine.

Language::Prolog::Yaswi will release the engine when the script
finish, this function is usefull to release the engine to free
resources or to be able to init it again with a different set of
arguments.

=back

=head2 CALLBACKS

Yaswi adds to SWI-Prolog three new predicates to call perl back.

All the calls are made in array contest and the Result value is always
a list. There is no way to make a call in scalar context yet.

=over 4

=item C<perl5_eval(+Code, -Result)>

makes perl evaluate the string C<Code> (really a Prolog atom) and
returns the results.

=item C<perl5_call(+Sub, +Args, -Result)>

calls a perl sub.

=item C<perl5_method(+Object, +Method, +Args, -Result)>

calls the method C<Method> from the perl object C<Object>.

To get objects passed to prolog as opaques instead of marshaled to
prolog types, its class (or one of its parent classes) has to be
previously register as opaque with the $swi_converter object. i.e.:

  perl5_eval('$swi_converter->pass_as_opaque("HTTP::Request")',_),
  perl5_eval('use HTTP::Request',_),
  perl5_method('HTTP::Request', new, [], [Request]),
  perl5_method(Request, as_string, [], [Text]);

Registering class C<UNIVERSAL> makes all objects to be passed to
prolog as opaques.


=back

=head2 EXPORT

This module doesn't export anything by default. Subroutines should be
explicitely imported.

=head2 THREADS

To get thread support in this module both Perl and SWI-Prolog have to
be previously compiled with threads (Perl needs the ithread model
available from Perl version 5.8.0, the 5.005 threads model is not
supported).

When Perl is called back from a thread created from Prolog a new fresh
Perl engine is constructed. That means there will be no modules
preloaded on it, no access to Perl data from other threads (not even
data marked as shared!), etc. Threads created from Perl do not suffer
from this limitation.


=head1 KNOWN BUGS

Under Unix, it's not possible to load prolog shared libraries (i.e.
xpce).


=head1 SEE ALSO

SWI-Prolog documentation L<http://www.swi-prolog.org/>, L<pl(1)>,
L<Languages::Prolog::Types> and L<Language::Prolog::Sugar>.


=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
