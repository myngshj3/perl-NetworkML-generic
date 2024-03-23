
use strict;
use warnings;
use Getopt::Long;
use NetworkML::Compiler;

my $program_file="-";

GetOptions(
    "program-file=s" => \$program_file
    );
open(G, "<", $program_file) or die "Coundn't open program file: \'$program_file\'.";
my $program = do{local$/;<G>};
close(G);

my $compiler =  NetworkML::Compiler->new();
$compiler || die "Compiler couldn't be initialized.";
my $nberr = $compiler->getParser()->YYNberr();
if ($nberr) {
    print"Nberr:",$nberr;
}
my $terminals = $compiler->getParser()->getTerminals();
my ($err, $nml, $errmsgs) = $compiler->getParser()->parse($program);
if ($err!=0) {
    for my $e (@$errmsgs) {
	print$e,"\n";
    }
    exit 1;
}

$compiler->dump($nml);

my $errs = $compiler->test($nml);
if (defined($errs) && scalar(@$errs) != 0) {
    for my $e (@$errs) {
	print$e,"\n";
    }
}


exit 0;
