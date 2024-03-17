package NetworkML::Parser;

use strict;
use warnings;
use File::Basename;
use JSON::PP "encode_json", "decode_json";
use Encode;
use NetworkML::BNFParser;

our $skip_token_names = [
    "SKIP",
    "COMMENT"
];

our $default_token_names = [
    "IF",
    "ELSIF",
    "ELSE",
    "WHILE",
    "LEDGE",
    "REDGE",
    "STRING",
    "FLOAT",
    "INTEGER",
    "SYMBOL",
    "SPECIAL_SYMBOL",
    "ASTERISK",
    "AND",
    "OR",
    "NOT",
    "EQ",
    "NE",
    "GT",
    "GE",
    "LT",
    "LE",
    "PLUS",
    "MINUS",
    "MULT",
    "DIVIDE",
    "MOD",
    "LPAR",
    "RPAR",
    "LBRACE",
    "RBRACE",
    "LBRACKET",
    "RBRACKET",
    "COMMA",
    "PERIOD",
    "ASSIGN",
    "CORON",
    "SEMICORON",
    "SKIP",
    "COMMENT"
];
our $default_tokens = {
    IF => "if",
    ELSIF => "elsif",
    ELSE => "else",
    WHILE => "while",
    SKIP => "(\\s|\\n)+",
    COMMENT => "#([^\n])*\n",
    STRING => "\"[^\"]*\"",
    #STRING => "\"(?:[^\\\"]+|\\\.)*\"",
    INTEGER => "\\d+",
    FLOAT => "\\d+\.\\d+",
    SYMBOL => "[_a-zA-Z][_a-zA-Z0-9]*",
    SPECIAL_SYMBOL => "\\$[_a-zA-Z][_a-zA-Z0-9]*",
    ASTERISK => "\\*",
    AND => "&&",
    OR  => "\\|",
    NOT => "not",
    EQ  => "==",
    NE  => "!=",
    GT  => "\\>",
    GE  => "\\>=",
    LT  => "\\<",
    LE  => "\\<=",
    PLUS => "\\-",
    MINUS => "\\+",
    MULT => "\\*",
    DIVIDE => "\/",
    MOD => "%",
    LPAR => "\\(",
    RPAR => "\\)",
    LBRACE => "\\[",
    RBRACE => "\\]",
    LBRACKET => "\\{",
    RBRACKET => "\\}",
    COMMA => "\\,",
    PERIOD => "\\.",
    ASSIGN => "=",
    CORON => ":",
    SEMICORON => ";",
    LEDGE => "\\-+\\[",
    REDGE => "\\]\\-+\\>"
};

my $dirname = dirname(__FILE__);
my $bnfpath = $dirname . "/" . "networkml.bnf";
open GRAMMER, "<", $bnfpath;
our $grammer_text = do {local $/;<GRAMMER>};
close GRAMMER;


sub program;
sub predefinitions;
sub predefinition;

our $reflection_map = {};


sub new {
    my $class = shift;
    my $self = {
	TokenNames => $default_token_names,
	TokenPatterns => $default_tokens,
	SkipTokenNames => $skip_token_names,
	GrammerBNF => $grammer_text,
	Grammer => {
	    Root => undef,
	    Rules => undef
	},
	ReflectionMap => $reflection_map
    };
    my $bnfparser = NetworkML::BNFParser->new($grammer_text);
    my ($err, $msg) = $bnfparser->parse_grammer();
    unless ($err) {
	$self->{Grammer}->{Root} = $bnfparser->get_root(),
	$self->{Grammer}->{Rules} = $bnfparser->get_rules()
    } else {
	print STDERR $msg;
	die "Grammer error: couldn't construct grammer tree.";
    }
    die "Grammer error: couldn't construct grammer tree" unless defined($self->{Grammer}->{Root}) && defined($self->{Grammer}->{Rules});
    return bless $self, $class;
}

sub clone {
    my $self = shift;
    my $json_text = $self->to_str;
    my $clone = NetworkML::Parser->new;
    $clone->from_str($json_text);
    return $clone;
}

sub tokenize {
    my $self = shift;
    my $text = shift;
    my $pos = 0;
    my $tokens = $self->{TokenPatterns};
    my $token_names = $self->{TokenNames};
    my $skip_token_names = $self->{SkipTokenNames};
    my $token_list = [];
    while ($pos < length($text)) {
	my $matched = 0;
	my $partial_text = substr($text, $pos);
	for my $t (@$token_names) {
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

sub parse {
    my $self = shift;
    my $text = shift;
    my ($err, $msg, $tokens) = $self->tokenize($text);
    if ($err) {
	print STDERR $msg;
	return;
    }
    for my $t (@$tokens) {
	print STDERR $t->{Value}, ", ", $t->{Type}, ", ", $t->{Pos}, ", ", $t->{Length}, "\n";
    }
    ($err,my $rtn,$msg) = $self->parse_($tokens, 0, $self->{TokenNames}, undef);
    if ($err) {
	print STDERR $msg, "\n";
	return;
    }
    return $rtn;
}

sub parse_ {
    my $self = shift;
    my $tokens = shift;
    my $token_offset = shift;
    my $terminals = shift;
    my $expression = shift;
    unless (defined($expression)) {
	$expression = [$self->{Grammer}->{Root}];
    }
    if (scalar(@$expression) == 0) {
	return 0, [], "no valid expression";
    }
    unless ($token_offset < scalar(@$tokens)) {
	return 0, [], "no more token to read";
    }
    my $exp_str = join(" ", @$expression);

    my $term = $expression->[0];
    die unless (defined($term));
    my $tail = [];
    for (my $i=1; $i < scalar(@$expression); $i++) {
	push(@$tail, $expression->[$i]);
    }

    my $rules = $self->{Grammer}->{Rules};
    # if term is not in rules of grammer
    unless (grep {$_ eq $term} (keys %$rules)) {
	print "search $term at $token_offset in grammer tree.\n";
	# if term is terminal word
	my ($type, $value) = ($tokens->[$token_offset]->{Type}, $tokens->[$token_offset]->{Value});
	if (($term eq $tokens->[$token_offset]->{Type} && grep {$_ eq $term} @$terminals) ||
	    ($term eq $tokens->[$token_offset]->{Value} &&
	     grep {$_ eq $tokens->[$token_offset]->{Value}} @$terminals)) {
	    my ($err, $tail_trees, $msg) = $self->parse_($tokens, $token_offset + 1, $terminals, $tail);
	    unless ($err) {
		my $root = $term;
		#if ($term eq $tokens->[$token_offset]->{Type} && grep {$_ eq $term} @$terminals) {
		#    $root .= "\n" . $tokens->[$token_offset + $offset + 1]->{Value}
		#}
		if ($term eq $tokens->[$token_offset]->{Type}) {
		    $root .= ":" . $tokens->[$token_offset]->{Value}
		}
		my $rtn = [{Root=>$root, Children=>[], Pos=>$token_offset, Length=>1}];
		for my $e (@$tail_trees) { push(@$rtn, $e); }
		return 0, $rtn;
	    }
	}
	return 1, undef, "No valid expression of $term at token-offset=$token_offset.";
    }
    else {
	print "Rule $term found at $token_offset.\n";
	my $expressions = $self->{Grammer}->{Rules}->{$term};
	for my $exp (@$expressions) {
	    my ($err, $exp_trees, $msg) = $self->parse_($tokens, $token_offset, $terminals, $exp);
	    if ($err) {
		next;
	    }
	    my $offset = 0;
	    map {$offset += $_->{Length}} @$exp_trees;
	    ($err, my $tail_trees, $msg) = $self->parse_($tokens, $token_offset + $offset, $terminals, $tail);
	    if ($err) {
		next;
	    }
	    my $rtn = [{Root=>$term, Children=>$exp_trees, Pos=>$token_offset, Length=>$offset}];
	    for my $e (@$tail_trees) { push(@$rtn, $e); }
	    return 0, $rtn;
	}
	return 1, undef, "No valid expression of $term at token-offset=$token_offset.";
    }
}

sub evaluate_one {
    my $self = shift;
    my $node = shift;
    my $children = shift;
    my $length = shift;
}

sub evaluate {
    my $self = shift;
    my $trees = shift;
    my $tokens = shift;
    my $results = [];
    for my $tree (@$trees) {
	my $root = $tree->{Root};
	my $token = $tree->{Token};
	my $pos = $tree->{Pos};
	my $children = $tree->{Children};
	my $evaluated_children = [];
	my $length = $tree->{Length};
	for my $c (@$children) {
	    push(@$evaluated_children, $self->evaluate([$c]));
	}
	my $reflector = $self->reflection_map->{$root};;
	push(@$results, $reflector->($evaluated_children));
    }
    return $results;
}

sub program {
    
}
sub predefinitions {}
sub predefinition {}

$reflection_map->{program} = *program;
$reflection_map->{predefinitions} = *predefintions;
$reflection_map->{predefinition} = *predefintion;


1;
__END__
