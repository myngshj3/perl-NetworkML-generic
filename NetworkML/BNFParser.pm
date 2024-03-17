package NetworkML::BNFParser;

use strict;
use warnings;
use JSON::PP "encode_json", "decode_json";
use Encode;

our $skip_token_names = [
    "SKIP",
    "COMMENT"
];

our $default_token_names = [
    "SYMBOL",
    "EQ",
    "OR",
    "SEMICORON",
    "SKIP",
    "COMMENT"
];

our $default_tokens = {
    SKIP => "(\\s|\\n)+",
    COMMENT => "#([^\n])*\n",
    SYMBOL => "[_a-zA-Z][_a-zA-Z0-9]*",
    EQ  => "::=",
    OR  => "\\|",
    SEMICORON => ";"
};

sub new {
    my $class = shift;
    my $grammer_text = shift;
    unless (defined($grammer_text)) {
	return;
    }
    my $self = {
	TokenNames => $default_token_names,
	TokenPatterns => $default_tokens,
	SkipTokenNames => $skip_token_names,
	GrammerBNF => $grammer_text,
	Grammer => undef
    };
    return bless $self, $class;
}

sub get_root {
    my $self = shift;
    return $self->{Grammer}->{Root};
}

sub get_rules {
    my $self = shift;
    return $self->{Grammer}->{Rules};
}

sub tokenize {
    my $self = shift;
    my $text = shift;
    my $pos = 0;
    my $tokens = $self->{TokenPatterns};
    my $token_list = [];
    while ($pos < length($text)) {
	my $matched = 0;
	my $partial_text = substr($text, $pos);
	for my $t (@$default_token_names) {
	    my $p = $tokens->{$t};
	    my $token = ($partial_text =~ /^($p)/) ? $1 : undef;
	    if (defined $token) {
		$matched = 1;
		unless (grep {$_ eq $t} @$skip_token_names) {
		    push(@$token_list, {Value=>$token, Type=>$t, Pos=>$pos, Length=>length($token)});
		}
		$pos += length($token);
		last;
	    }
	}
	unless ($matched) {
	    return 1, $pos, $token_list;
	}
    }
    return 0, $pos, $token_list;
}

sub parse_grammer {
    my $self = shift;
    my $grammer_text = $self->{GrammerBNF};
    my $grammer = { Root=>undef, Rules=>{} };
    my ($err, $pos, $tokens) = $self->tokenize($grammer_text);
    if ($err) {
	print STDERR "Tokenizer error: error at $pos.\n";
	exit $err;
    }
    my $prev_name;
    while (my $name = shift(@$tokens)) {
	if ($name->{Type} eq "SYMBOL") {
	    my $eq = shift(@$tokens);
	    if (defined($eq) && $eq->{Type} eq "EQ") {
		my $expressions = [];
		my $list = [];
		while (1) {
		    my $sym = shift(@$tokens);
		    unless (defined($sym)) {
			return 1, "Grammer error: Invalid grammer termination after $eq->{Value} at " . ($eq->{Pos} + $eq->{Length}) . ".";
		    }
		    if ($sym->{Type} eq "SYMBOL") {
			push(@$list, $sym->{Value});
		    } elsif ($sym->{Type} eq "OR") {
			if (scalar(@$list) == 0) {
			    return 1, "Grammer error: Empty definition for $name->{Value} at $sym->{Pos}.\n";
			}
			push(@$expressions, $list);
			$list = [];
		    } elsif ($sym->{Type} eq "SEMICORON") {
			if (scalar(@$list) == 0) {
			    return 1, "Grammer error: Empty definition for $name->{Value} at $sym->{Pos}.\n";
			}
			push(@$expressions, $list);
			if (defined($grammer->{Rules}->{$name->{Value}})) {
			    return 1, "Grammer error: Redefined name $name->{Value} at $name->{Pos}.\n";
			}
			$grammer->{Rules}->{$name->{Value}} = $expressions;
			unless (defined($grammer->{Root})) {
			    $grammer->{Root} = $name->{Value};
			}
			last;
		    }
		}
	    } else {
		return 1, "Grammer error: Invalid assignment symbol for $name->{Text} at $name->{Pos}.\n";
	    }
	    $prev_name = $name->{Value};
	}
	else {
	    if (defined($prev_name)) {
		return 1, "Grammer error: No valid pattern name found after " . ($prev_name->{Pos} + $prev_name->{Length}) . ".";
	    }
	    else {
		return 1, "Grammer error: No valid pattern name found.\n";
	    }
	}
    }
    $self->{Grammer} = $grammer;
    return 0, "Grammer parserd successfully.";
}

sub dump_description {
    my $self = shift;
    my $grammer_text = $self->{GrammerBNF};
    my $grammer = $self->{Grammer};
    my $root = $grammer->{Root};
    my $rules = $grammer->{Rules};
    print "Root => ", $root, "\n";
    print "Rules => {", "\n";
    for my $k (keys %$rules) {
	print "  ", $k, " ::= ";
	my @data = ();
	my $expressions = $rules->{$k};
	for my $exp (@$expressions) {
	    push(@data, join(" ", @$exp));
	}
	print join(" | ", @data), " ;\n";
    }
    print "}", "\n";
}

sub test {
    
}


1;
__END__
