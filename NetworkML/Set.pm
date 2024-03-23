package NetworkML::Set;

use strict;
use warnings;
use threads;

sub new {
    my $class = shift;
    my $self = {}
    };
    return bless $self, $class;
}

sub add {
    my $self = shift;
    my $e = shift;
    $self->{$e} = undef unless defined($self->{$e});
}

sub remove {
    my $self = shift;
    my $e = shift;
    delete $self, $e if defined($self->{$e});
}

sub union {
    my $self = shift;
    my $target = shift;
    my $newSet = NetworkML::Set->new;
    for my $e ($self->to_list) {
	$newSet->add($e);
    }
    for my $e ($target->to_list) {
	$newSet->add($e);
    }
    return $newSet;
}

sub intersect {
    my $self = shift;
    my $target = shift;
    my $newSet = NetworkML::Set->new;
    for my $e ($self->to_list) {
	$newSet->add($e) if $target->contains($e);
    }
    return $newSet;
}

sub minus {
    my $self = shift;
    my $target = shift;
    my $newSet = NetworkML::Set->new;
    for my $e ($self->to_list) {
	$newSet->add($e) unless $target->contains($e);
    }
    return $newSet;
}

sub contains {
    my $self = shift;
    my $e = shift;
    return defined $self->{$e};
}

sub union {
    
}

sub to_list {
    my $self = shift;
    return keys %self;
}


1;
__END__
