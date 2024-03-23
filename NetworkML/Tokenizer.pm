package NetworkML::Tokenizer;

use strict;
use warnings;
use File::Basename;
use JSON::PP "encode_json", "decode_json";
use Encode;

sub new {
    my $skip_token_names = [
	"SKIP",
	"COMMENT"
	];

    my $default_token_names = [
	'SKIP',
	'COMMENT',
	'VAR',
	'IF',
	'ELSIF',
	'ELSE',
	'WHILE',
	'AND',
	'OR',
	'NOT',
	'TRUE',
	'FALSE',
	'LEDGE',
	'REDGE',
	'STRING',
	'FLOAT',
	'INTEGER',
	'SYMBOL',
	'SPECIAL_SYMBOL',
	'=>',
	'==',
	'!=',
	'>=',
	'<=',
	'+=',
	'-=',
	'<',
	'>',
	'+',
	'-',
	'*',
	'/',
	'%',
	'(',
	')',
	'[',
	']',
	'{',
	'}',
	',',
	'.',
	'=',
	':',
	';'
	];

    my $default_tokens = {
	# Keywords
	'SKIP' => "(\\s|\\n)+",
	    'COMMENT' => "#([^\n])*\n",
	    'VAR' => "var",
	    'IF' => "if",
	    'ELSIF' => "elsif",
	    'ELSE' => "else",
	    'WHILE' => "while",
	    'AND' => "and",
	    'OR'  => "or",
	    'NOT' => "not",
	    'TRUE' => "true",
	    'FALSE' => "false",
	    'STRING' => "\\\"[^\"]*\\\"",
	    #'STRING' => "\"(?:[^\\\"]+|\\\.)*\"",
	    'LEDGE' => "\\-+\\[",
	    'REDGE' => "\\]\\-+\\>",
	    'INTEGER' => "\\d+",
	    'FLOAT' => "\\d+\.\\d+",
	    'SYMBOL' => "[_a-zA-Z][_a-zA-Z0-9]*",
	    'SPECIAL_SYMBOL' => "\\$[_a-zA-Z][_a-zA-Z0-9]*",
	    '=>' => "=>",
	    '=='  => "==",
	    '!='  => "!=",
	    '>='  => "\\>=",
	    '<='  => "\\<=",
	    '+=' => "\\+=",
	    '-=' => "\\-=",
	    '>'  => "\\>",
	    '<'  => "\\<",
	    '+' => "\\+",
	    '-' => "\\-",
	    '*' => "\\*",
	    '/' => "\/",
	    '%' => "%",
	    '(' => "\\(",
	      ')' => "\\)",
	    '[' => "\\[",
	      ']' => "\\]",
	    '{' => "\\{",
		  '}' => "\\}",
	    ',' => ",",
	    '.' => "\\.",
	    '=' => "=",
	    ':' => ":",
	    ';' => ";"
    };

    my $class = shift;
    my $self = {
	TokenNames => $default_token_names,
	TokenPatterns => $default_tokens,
	SkipTokenNames => $skip_token_names,
    };

    return bless $self, $class;
}

sub text_loc {
    my $self = shift;
    my $text = shift;
    my $pos = shift;
    my $length = shift;
    my $start_vpos = 0;
    my $start_hpos = 0;
    my $i;
    for ($i = 0; $i < $pos; $i++) {
	my $cur = substr($text, $i, 1);
	if($cur eq "\n") {
	    $start_vpos++;
	    $start_hpos = 0;
	} else {
	    $start_hpos++;
	}
    }
    my $end_vpos = $start_vpos;
    my $end_hpos = $start_hpos;
    for (; $i < $pos + $length; $i++) {
	my $cur = substr($text, $i, 1);
	if($cur eq "\n") {
	    $end_vpos++;
	    $end_hpos = 0;
	} else {
	    $end_hpos++;
	}
    }
    return $start_vpos, $start_hpos, $end_vpos, $end_hpos;
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
		    my ($sv, $sh, $ev, $eh) = $self->text_loc($text, $pos, length($token));
		    my $v = { Value=>$token, Type=>$t,
			      TextLoc=>{ Pos=>$pos+1, Length=>length($token),
					 StartV=>$sv+1, StartH=>$sh+1, EndV=>$ev+1, EndH=>$eh+1 } };
		    push(@$token_list, $v);
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


1;
__END__
