use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Language::Prolog::Yaswi',
    'VERSION_FROM'	=> 'Yaswi.pm',
    'PREREQ_PM'		=> { Language::Prolog::Types => '0.08',
			     Language::Prolog::Sugar => '0.03',
			     Test::More => 0, },
#    'OPTIMIZE'          => '-g',
    'ABSTRACT_FROM'     => 'Yaswi.pm',
    'AUTHOR'            => 'Salvador Fandiño <sfandino@yahoo.com>',
);
