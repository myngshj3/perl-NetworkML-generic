package NetworkML::Server;

use strict;
use warnings;
use threads;
use IO::Socket;
use NetworkML::Parser;

sub sigint();
sub sighup();
sub sigterm();
sub sigkill();
sub handle_request();

$SIG{INT} = \&sigint;
$SIG{HUP} = \&sighup;
$SIG{TERM}= \&sigterm;
$SIG{KILL}= \&sigkill;

our $instance = undef;

sub new {
    my $class = shift;
    my $self = {
	Server => undef,
	Clients => {},
	Loop => 1,
	ScriptEngine => NetworkML::Parser->new()
    };
    return bless $self, $class;
}

sub main {
    my $self = shift;
    my $self->{Server} = IO::Socket->new(
	Domain => AF_INET,
	Type => SOCK_STREAM,
	Proto => 'tcp',
	LocalHost => '0.0.0.0',
	LocalPort => 5320,
	ReusePort => 1,
	Listen => 5
	) or die "Couldn't create server socket.";
    while ($self->{Server}->{Loop}) {
	my $client = $server->accept();
	my $th = threads->new(\&handle_request, $self, $client);
	
    }
}

sub handle_request {
    my $self = shift;
    my $client = shift;
    my ($addr, $port) = ($client->peerhost, $client->peerpot);
    while ($self->{Server}->{Loop}) {
	my ($script, $data) = ("", "");
	$script .= $data while ($client->recv($data, 1024));
	my ($err, $msg, $result) = $script_engine->run($script);
	$client->send($result) unless  ($err);
	$client->send("status:" . $err);
	$client->send($msg);
    }
}

sub sigint {
    if (defined($instance)) {
	$instance->{Loop} = 0;
    }
}

sub sighup {
    if (defined($instance)) {
	$instance->{Loop} = 0;
    }
}

sub sigterm {
    if (defined($instance)) {
	$instance->{Loop} = 0;
    }
}

sub sigkill {
    if (defined($instance)) {
	$instance->{Loop} = 0;
    }
}


1;
__END__
