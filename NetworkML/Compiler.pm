package NetworkML::Compiler;

use strict;
use warnings;
use File::Basename;
use JSON::PP "encode_json", "decode_json";
use NetworkML::Parser;
use NetworkML::Context;
use Encode;

sub new {
    my $class = shift;
    my $self = {
	Parser => NetworkML::Parser->new(),
	Tokenizer => NetworkML::Tokenizer->new()
    };
    return bless $self, $class;
}

sub getParser {
    my $self = shift;
    return $self->{Parser};
}

sub testProgram {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    # test children.
    for my $e (@{$args}) {
	$self->testElement($e, $context, $terminals, $errs, $options);
    }
}

sub testStatements {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    # test children.
    for my $e (@{$args}) {
	$self->testElement($e, $context, $terminals, $errs, $options);
    }
}

sub testDecl {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    # check Right Term.
    $self->testElement($args->[1], $context, $terminals, $errs, $options);
    # check Left term.
    my $sym = $args->[0][1];
    if ($context->hasSymbol($sym->{Value})) {
	push@$errs,sprintf("Error: Symbol \'%s\' is already declared. At line %d pos %d.",
			   $sym->{Value}, $sym->{TextLoc}->{StartV}, $sym->{TextLoc}->{StartH});
    } else {
	$context->registSymbol($sym->{Value}, 0);
    }
}

sub testSubst {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    # check Right Term.
    $self->testElement($args->[1], $context, $terminals, $errs, $options);
    # check Left term.
    $self->testElement($args->[0], $context, $terminals, $errs, $options);
}

sub testIncrement {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    # check Right Term.
    $self->testElement($args->[1], $context, $terminals, $errs, $options);
    # check Left term.
    $self->testElement($args->[0], $context, $terminals, $errs, $options);
}

sub testDecrement {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    # check Right Term.
    $self->testElement($args->[1], $context, $terminals, $errs, $options);
    # check Left term.
    my $sym = $args->[0][1]->{Value};
    $self->testElement($args->[0], $context, $terminals, $errs, $options);
}

sub testFunccall {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my ($funcsym, $tuple) = @{$element->[1]};
    # check argument tuple.
    $self->testElement($tuple, $context, $terminals, $errs, $options);
    $funcsym = $funcsym->[1];
    # check if funcsymbol is already declared.
    unless ($context->hasSymbol($funcsym->{Value})) {
	push@$errs,sprintf("Error: FuncSymbol \'%s\' is not declared yet. At line %d pos %d.",
			   $funcsym->{Value},
			   $funcsym->{TextLoc}->{StartV}, $funcsym->{TextLoc}->{StartH});
    }
}

sub testLoop {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    # check condition term.
    $self->testElement($args->[1], $context, $terminals, $errs, $options);
    # check statements term.
    $self->testElement($args->[0], $context, $terminals, $errs, $options);
}

sub testOpenedIfStatement {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    # check child conditional statements.
    for my$arg (@$args) {
	$self->testElement($arg, $context, $terminals, $errs, $options);
    }
}

sub testIfStatement {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    my ($cond, $statements) = @$args;
    $self->testElement($cond, $context, $terminals, $errs, $options);
    $self->testElement($statements, $context, $terminals, $errs, $options);
}

sub testElsifStatement {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    my ($cond, $statements) = @$args;
    $self->testElement($cond, $context, $terminals, $errs, $options);
    $self->testElement($statements, $context, $terminals, $errs, $options);
}

sub testElseStatement {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $args = $element->[1];
    my ($cond, $statements) = @$args;
    $self->testElement($statements, $context, $terminals, $errs, $options);
}

sub testSymbol {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $sym = $element->[1];
    # check if symbol in context.
    unless ($context->hasSymbol($sym->{Value})) {
	push@$errs,sprintf("Symbol \'%s\' is not declared yet.",
			   $sym->{Value},
			   $sym->{TextLoc}->{StartV}, $sym->{TextLoc}->{StartH});
    }
}

sub testElement {
    my ($self, $element, $context, $terminals, $errs, $options) = @_;
    my $funcMap = {
	program => *testProgram,
	statements => *testStatements,
	decl => *testDecl,
	subst => *testSubst,
	increment => *testIncrement,
	decrement => *testDecrement,
	funccall => *testFunccall,
	loop => *testLoop,
	opened_if_statement => *testOpenedIfStatement,
	if_statement => *testIfStatement,
	elsif_statement => *testElsifStatement,
	else_statement => *testElseStatement,
	SYMBOL => *testSymbol,
    };
    unless (defined($element)) {
	return;
    }
    my ($name, $args) = @$element;
    unless (grep{$_ eq $name}@{$terminals}) {
	my $tester = $funcMap->{$name};
	if (defined($tester)) {
	    $tester->($self, $element, $context, $terminals, $errs, $options);
	}
    }
}

sub test {
    my ($self, $program, $options) = @_;
    my $context = NetworkML::Context->new();
    my $terminals = $self->getParser()->getTerminals();
    my $errs = [];
    $self->testElement($program, $context, $terminals, $errs, $options);
    if (scalar(@$errs) != 0) {
	for my $e (@$errs) {
	    print STDERR $e, "\n";
	}
    }
    return $errs;
}

sub dumpElement {
    my ($self, $elem, $terminals, $indent) = @_;
    my $pad=""; map{$pad.=" "}(1..$indent);
    unless(defined($elem)){
	print$pad,"undef\n";
	return;
    }
    my ($name, $entity) = @$elem;
    print$pad,$name,": ";
    if (grep{$_ eq $name}@{$terminals}) {
	if (substr("$entity",0,4) eq "HASH") {
	    print$entity->{Value},"\n";
	}
	elsif (substr("$entity",0,5) eq "ARRAY") {
	    print"[\n";
	    $indent+=2;
	    for my $c (@$entity) {
		$self->dumpElement($c, $terminals, $indent);
	    }
	    print$pad,"]\n";
	}
    } else {
	print"[\n";
	$indent+=2;
	for my $c (@$entity) {
	    $self->dumpElement($c, $terminals, $indent);
	}
	print$pad,"]\n";
    }
}

sub dump {
    my ($self, $program, $options) = @_;
    my $terminals = $self->getParser()->getTerminals();
    $self->dumpElement($program, $terminals, 0);
}


1;
__END__
