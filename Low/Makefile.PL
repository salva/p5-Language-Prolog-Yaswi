use ExtUtils::MakeMaker;
use Config;

print "retrieving SWI-Prolog configuration:\n";
my $defaultpl= $^O=~/Win32/ ? 'plcon.exe' : 'pl';
my $pl=$ENV{PL} || $defaultpl;
print "  running '$pl -dump-runtime-variables'\n";
my @plvars=`$pl -dump-runtime-variables`;
if ($?) {
    print "unable to run swi-prolog command '$pl': $?\nAborting...\n";
    exit(1);
}

my %plvar;
foreach (@plvars) {
    if (/^(PL.*?)="(.*)";$/) {
	$plvar{$1}=$2;
	print "    $1: $plvar{$1}\n";
    }
}

if ($^O=~/Win32/) {
    $plvar{PLLIBS}.=qq( -L"$plvar{PLBASE}/lib" -lpl);
    $plvar{PLINC}=qq(-I"$plvar{PLBASE}/include");
    $plvar{PLEXE}=qq($plvar{PLBASE}/bin/libpl.dll);
    $plvar{PLPATH}=qq($plvar{PLBASE}/bin);
}
else {
    $plvar{PLLIBS}.=" -L$plvar{PLBASE}/runtime/$plvar{PLARCH}/ ";
    $plvar{PLLIBS}.=($plvar{PLTHREADS} eq 'yes') ? '-lplmt' : '-lpl';
    # $plvar{PLLIBS}.=' -export-dynamic';
    $plvar{PLINC}="-I$plvar{PLBASE}/include";
    $plvar{PLEXE}="$plvar{PLBASE}/bin/$plvar{PLARCH}/pl";
    $plvar{PLPATH}="$plvar{PLBASE}/bin/$plvar{PLARCH}/";
}
print "\nchecking thread support in Perl and SWI-Prolog:\n";
if ($plvar{PLTHREADS}=~/y/) {
    if ( !defined($Config::Config{usethreads}) ) {
	print ("\nYour Perl doesn't support threads but your SWI-Prolog\n".
	       "does, this configuration is not supported.\nAborting...\n");
	exit(1);
    }
    if ( !defined($Config::Config{useithreads}) ) {
	print ("\nThis package only supports interpreter threads (ithreads)\n".
	       "and your Perl has been compiled with a different variety.\n".
	       "Aborting...\n");
	exit(1);
    }
    print "  thread support enabled\n";
}
else {
    if (defined($Config::Config{useithreads}) ) {
	print ("\nYour Perl support threads but your SWI-Prolog\n".
	       "doesn't, this configuration is not supported.\nAborting...\n");
	exit(1);
    }
    if (defined($Config::Config{usethreads})) {
	print ("\nYou Perl has been compiled with an unsupported\n".
	       "thread model and your SWI-Prolog doesn't support\n".
	       "threads, this configuration is not supported.\nAborting...\n");
	exit(1);
    }
    print "  thread support disabled\n";
}


print "\ncreating plconfig.c\n";
unless (open (PLC, ">plconfig.c")) {
    print "unable to open 'plconfig.c' to store SWI-Prolog configuration\n";
    exit(1);
}

print PLC <<EOC;
char *PL_base="$plvar{PLBASE}";
char *PL_arch="$plvar{PLARCH}";
char *PL_exe="$plvar{PLEXE}";
char *PL_path="$plvar{PLPATH}";
EOC

unless (close (PLC)) {
    print "unable to write 'plconfig.c' to store SWI-Prolog configuration\n";
    exit(1);
}

WriteMakefile(
    'NAME'		=> 'Language::Prolog::Yaswi::Low',
    'VERSION_FROM'	=> 'Low.pm',
    'PREREQ_PM'		=> {},
    'ABSTRACT_FROM'     => 'Low.pm',
    'AUTHOR'            => 'Salvador Fandiño <sfandino@yahoo.com>',
    'LIBS'		=> [$plvar{PLLIBS}],
    'DEFINE'		=> '',
    'INC'		=> "-I. $plvar{PLINC}",
    'OBJECT'            => '$(BASEEXT)$(OBJ_EXT) callback$(OBJ_EXT) callperl$(OBJ_EXT)'.
	                   ' hook$(OBJ_EXT) perl2swi$(OBJ_EXT) swi2perl$(OBJ_EXT)'.
	                   ' frames$(OBJ_EXT) plconfig$(OBJ_EXT) argv$(OBJ_EXT)'.
	                   ' query$(OBJ_EXT) vars$(OBJ_EXT) context$(OBJ_EXT)'.
	                   ' engines$(OBJ_EXT)',
#    'LDDLFLAGS'         => '-export-dynamic',
#    'OPTIMIZE'		=> '-g',
);

