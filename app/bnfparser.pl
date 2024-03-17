
push @INC, ".";

use strict;
use warnings;
use Getopt::Long;
require NetworkML::BNFParser;

my $grammer_file="grammer.bnf";
my $program_file="-";

GetOptions(
    "grammer=s" => \$grammer_file,
    "program=s" => \$program_file
    );
open(G, "<", $grammer_file) or die "Coundn't open grammer file '$grammer_file'.";
my $grammer_text = do{local$/;<G>};
close(G);

my $bnfparser = NetworkML::BNFParser->new($grammer_text);
$bnfparser || die "BNFParser not initialized.";
print "Parse Grammer successfully initialized.\n";
my ($err, $msg) = $bnfparser->parse_grammer();
if ($err) {
    print STDERR $msg;
    exit $err;
}
print "-- Grammer description --\n";
$bnfparser->dump_description();


exit 0;
