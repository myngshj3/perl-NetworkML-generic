package NetworkML::DiGraph;

use strict;
use warnings;
use JSON::PP "encode_json", "decode_json";
use Encode;

sub new {
    my $class = shift;
    my $self = {
	nodes => {},
	edges => {}
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

sub get_nodes {
    my $self = shift;
    return $self->{nodes};
}

sub add_node {
    my $self = shift;
    my $node = shift;
    my $attrs = shift;
    my $nodes = $self->{nodes};
    $nodes->{$node} = {};
    if (defined($attrs)) {
	foreach my $key (keys %$attrs) {
	    $nodes->{$node}->{$key} = $attrs->{$key};
	}
    }
}

sub remove_node {
    my ($self, $node) = @_;
    my $nodes = $self->{nodes};
    my $edges = $self->{edges};
    foreach my $edge (keys %$edges) {
	$self->remove_edge($edge) if ($edge =~ /^$node,/);
	$self->remove_edge($edge) if ($edge =~ /,$node$/);
    }
    delete($nodes->{$node});
}

sub get_edges {
    my $self = shift;
    return $self->{edges};
}

sub add_edge {
    my $self = shift;
    my $edge = shift;
    my $attrs = shift;
    my $edges = $self->{edges};
    $edges->{$edge} = {};
    if (defined($attrs)) {
	foreach my $key (keys %$attrs) {
	    $edges->{$edge}->{$key} = $attrs->{$key};
	}
    }
}

sub remove_edge {
    my ($self, $edge) = @_;
    my $edges = $self->{edges};
    delete($edges->{$edge});
}

sub print_nodes {
    my $self = shift;
    my $nodes = $self->{nodes};
    print "NODES:\n";
    foreach my $n (keys %$nodes) {
	print STDOUT "$n:\n";
	my $attrs = $nodes->{$n};
	foreach my $key (keys %$attrs) {
	    print STDOUT "\t", $key, "=>", $attrs->{$key}, "\n";
	}
    }
}

sub print_edges {
    my $self = shift;
    my $edges = $self->{edges};
    print "EDGES:\n";
    foreach my $e (keys %$edges) {
	print STDOUT "($e) :\n";
	my $attrs = $edges->{$e};
	foreach my $key (keys %$attrs) {
	    print STDOUT "\t", $key, "=>", $attrs->{$key}, "\n";
	}
    }
}

sub to_str {
    my ($self) = @_;
    my $data = { nodes => $self->{nodes}, edges => $self->{edges} };
    my $json_text = JSON::PP->new->utf8->encode($data);
    return $json_text;
}

sub from_str {
    my ($self, $in_text) = @_;
    my $json_data = JSON::PP->new->utf8->decode($in_text);
    $self->{nodes} = $json_data->{nodes};
    $self->{edges} = $json_data->{edges};
}

sub dump {
    my ($self) = @_;
    my $data = { nodes => $self->{nodes}, edges => $self->{edges} };
    my $json_text = JSON::PP->new->utf8->encode($data);
    print $json_text;
}

sub load {
    my ($self) = @_;
    my $in_text = do { local $/; <> };
    my $json_data = JSON::PP->new->utf8->decode($in_text);
    $self->{nodes} = $json_data->{nodes};
    $self->{edges} = $json_data->{edges};
}


1;
__END__
