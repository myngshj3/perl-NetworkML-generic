package NetworkML::Parser;

use strict;
use warnings;
use JSON::PP "encode_json", "decode_json";
use Encode;


sub new {
    my $class = shift;
    my $self = {
	tokens => {},
	patterns => {}
    };
    return bless $self, $class;
}

sub clone {
    my $self = shift;
    my $json_text = $self->to_str;
    my $clone = NetworkML::DiGraph->new;
    $clone->from_str($json_text);
    return $clone;
}

sub load_lexical_definition {
    my $self = shift;
    my $text_def = shift;
    my @text_lines = split("\n", $text_def);
    my $lines = [];
    for my $l (@text_lines) {
	unless ($l =~ /^\s*(#.*|\s*)$/) {
	    $l =~ s/^\s+(.+)$/$1/;
	    $l =~ s/(.+)\s*(#.*|)\s*/$1/;
	    $l =~ s/^([A-Z][A-Z0-9]+)\s*=\s*\"(.+)\"$/$1\t$2/;
	    my @p = split('\t', $l);
	    $self->{tokens}->{$p[0]} = $p[1];
	    # print token definitions
	    print $p[0], " = <", $p[1], ">\n";
	}
    }
}

sub print_lexical_definition {
    my $self = shift;
    my $tokens = $self->{tokens};
    for my $t (keys %$tokens) {
	print $t, " = <", $tokens->{$t}, ">\n";
    }
}

sub load_syntax_definition {
    my $self = shift;
    my $text_def = shift;
    my @text_lines = split("\n", $text_def);
    my $length = @text_lines;
    print $text_def, "\n";
    my $i = 0;
    while ($i < $length) {
	my $line = $text_lines[$i];
	if ($line =~ /\|\s*$/) {
	    while ($i+1 < $length && $text_lines[$i+1] =~ /\|\s*$/) {
		$line .= $text_lines[$i+1];
		$i++;
	    }
	    return 0 if ($i == $length); # format error
	    $i++;
	    $line .= $text_lines[$i];
	}
	unless ($line =~ /^\s*(#.*|\s*)$/) { # ignore comments
	    my @tokens = split(":=", $line);
	    if (defined($tokens[0]) && defined($tokens[1])) {
		my $pattern_name = $tokens[0];
		$pattern_name =~ s/^(.*)\s+$/$1/;
		$pattern_name =~ s/^\s+(.*)$/$1/;
		print "pattern name: $pattern_name\n";
		my $patterns_string = $tokens[1];
		my @patterns = split('\|', $patterns_string);
		my $pattern_array = [];
		$self->{patterns}->{pattern_name} = $pattern_array;
		for my $pattern (@patterns) {
		    $pattern =~ s/^(.*)\s+$/$1/;
		    $pattern =~ s/^\s+(.*)$/$1/;
		    my $token_array = [];
		    for my $p (split("\s+", $pattern)) {
			push(@$token_array, $p);
		    }
		    push(@$pattern_array, $token_array);
		}
		$self->{patterns}->{$pattern_name} = $pattern_array;
	    }
	}
	$i++;
    }
}


1;
__END__
