package Language::Prolog::Yaswi::Low;

our $VERSION = '0.07';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( init
		  cleanup
		  toplevel
		  openquery
		  cutquery
		  nextsolution
		  swi2perl
		  testquery
		  getvar
		  getquery
		  getallvars
		  $converter );


use Carp;
use Language::Prolog::Types::Converter;

our $converter=Language::Prolog::Types::Converter->new();
our @args;

# our @fids;

our ($qid, $query, @vars, @cells, %vars_cache);


sub getvar ($) {
    my $name=$_[0]->name();
    croak "no such variable '$name'"
	unless exists $vars_cache{$name};
    return swi2perl($vars_cache{$name});
}

sub getallvars {
    return map { swi2perl($_) } @cells[0..$#vars]
}

sub getquery () {
    swi2perl($query);
}

require XSLoader;
XSLoader::load('Language::Prolog::Yaswi::Low', $VERSION);

@args=(PL_EXE(), '-q');

sub init {
    @args=(PL_EXE(), @_);
    start();
}


1;
__END__

=head1 NAME

Language::Prolog::Yaswi::Low - Low level interface to SWI-Prolog

=head1 SYNOPSIS


  # don't use Language::Prolog::Yaswi::Low;
  use Language::Prolog::Yaswi; #instead ;-)

=head1 ABSTRACT


=head1 DESCRIPTION

Stub documentation for Language::Prolog::Yaswi::Low, created by h2xs.

=head2 EXPORT

lots of things by default.


=head1 SEE ALSO

L<Language::Prolog::Yaswi>

=head1 AUTHOR

Salva, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

SWI-Prolog is distributed under the GPL license. Read the LICENSE file
from your SWI-Prolog distribution for details.

=cut
