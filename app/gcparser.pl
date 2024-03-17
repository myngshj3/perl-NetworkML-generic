
use strict;
use warnings;
use NetworkML::Parser;

my $parser = NetworkML::Parser->new();
my $text = do{local$/;<>};
my $rtn = $parser->parse($text);
unless (defined($rtn)) {
    print STDERR "error. undefined\n";
    exit 1;
}
unless (0 < scalar(@$rtn)) {
    print STDERR "error. no valid script\n";
    exit 1;
}

sub dump_tree {
    my $tree = shift;
    my $nest = shift;
    my $indent = ""; map{ $indent .= "  " } (1..$nest);
    print $indent, "--- Root: ", $tree->{Root}, " [Pos=>", $tree->{Pos}," Length=>", $tree->{Length}, "] ---\n";
    print $indent, "    Children:[\n";
    $nest += 1;
    my $children = $tree->{Children};
    for my $c (@$children) {
	dump_tree($c, $nest);
    }
    $nest -= 1;
    print $indent, "    ]\n";
}

print "----------------------------------- Result of Parsing ---------------------------------------\n";
my $level = 0;
for my $tree (@$rtn) {
    dump_tree($tree, $level);
}

sub dump_tree {
    my $tree = shift;
    my $children = $tree->{Children};
    for my $c (@$children) {
	dump_tree($c, $nest);
    }
    print $indent, "    ]\n";
}

for my $t (@$rtn) {
    eval_tree($t);
}
