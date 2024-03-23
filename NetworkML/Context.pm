package NetworkML::Context;

use strict;
use warnings;
use File::Basename;
use JSON::PP "encode_json", "decode_json";
use Encode;

sub new {
    my $class = shift;
    my $self = {
	NameSpaces => [{}]
    };
    return bless $self, $class;
}

sub pushStack {
    my ($self, $options) = @_;
    push@{$self->{NameSpaces}},{};
}

sub popStack {
    my ($self, $options) = @_;
    pop@{$self->{NameSpaces}};
}

sub currentStack {
    my ($self, $options) = @_;
    my $nameSpaces = $self->{NameSpaces};
    return $nameSpaces->[scalar(@{$nameSpaces})-1];
}

sub hasSymbol {
    my ($self, $symbol, $options) = @_;
    for (my $i=0; $i < scalar(@{$self->{NameSpaces}}); $i++) {
	my $nameSpace = $self->{NameSpaces}->[$i];
	return 1 if defined $nameSpace->{$symbol};
    }
    return 0;
}

sub registSymbol {
    my ($self, $symbol, $value, $options) = @_;
    my $currentStack = $self->currentStack();
    unless (defined($currentStack->{$symbol})) {
	$currentStack->{$symbol} = $value;
    }
}

sub removeSymbol {
    my ($self, $symbol, $options) = @_;
    my $currentStack = $self->currentStack();
    if (defined($currentStack->{$symbol})) {
	delete $currentStack->{$symbol};
    }
}

1;
__END__
