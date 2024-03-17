#!/usr/bin/perl

use strict;
use warnings;
use Curses::UI;
use Curses::UI::Dialog::Filebrowser;
use Getopt::Long;

my $clear_on_exit = 0;
my $color_support = 1;
my $compat = 0;
my $key_delay = 0;
my $mouse_support = 1;
my $debug = 0;
GetOptions(
    "clear_on_exit=i" => \$clear_on_exit,
    "color_cupport=i" => \$color_support,
    "compat=i" => \$compat,
    "key_delay=i" => \$key_delay,
    "mouse_support=i" => $mouse_support,
    "debug=i" => \$debug
    ) || die "Invalid option(s) specified.";


my $cui = Curses::UI->new(-color_support => $color_support,
			  -clear_on_edit => $clear_on_exit,
			  -compat => $compat,
			  -key_delay => $key_delay,
			  -mouse_support => $mouse_support,
			  -debug => $debug);
sub exit_dialog {
    my $return = $cui->dialog(
	-message => "Do you really want to quit?",
	-title => "Are you sure???",
	-button => ["Yes", "No"]
	);
    exit 0 if $return;
}

sub open_dialog {
    my $dialog = $cui->add('dialog', 'Dialog::Filebrowser',
			   -message => "Select file to open.",
			   -title => "File Select",
			   -button => ["Yes", "No"]
	);
    my $return = $dialog->focus();
    if ($return) { # Yes button
	my $file = $dialog->get();
    }
}

sub close_dialog {
}

sub save_dialog {
}

my $menu = [
    {
	-label => 'File',
	    -submenu => [
	     { -label => 'Open    ^O', -value => \&open_dialog },
	     { -label => 'Close   ^C', -value => \&close_dialog },
	     { -label => 'Save    ^S', -value => \&Save_dialog },
	     { -label => 'Exit    ^Q', -value => \&exit_dialog }
	]
    },
    {
	-label => 'Buffer',
	-submenu => [
	     { -label => 'Split into 2 panes ^2', -value => \&split_into_2_panes },
	     { -label => 'Combine panes ^1', -value => \&combine_panes },
	]
    },
];

my $menu_bar = $cui->add(
    "menu", "Menubar",
    -menu => \@$menu,
    -fg => "blue"
    );

my $win1 = $cui->add(
    "win1", "Window",
    -boarder => 1,
    -y => 1,
    -bfg => "red"
    );

my $texteditor = $win1->add(
    "text", "TextEditor",
    -text => "Here is some text\n" . "And some more"
);

$cui->set_binding(sub {$menu_bar->focus()}, "\cX");
$cui->set_binding(\&exit_dialog, "\cQ");


$texteditor->focus();
$cui->mainloop();

$cui->mainloop();


#$cui->addstr(10, 10, "Hello World");

sub show_progress {
    my $max = shift;
    $cui->progress(
	-max => $max,
	-message => "Counting 10 senconds ...",
	);    
    for my $sec (0..$max) {
	$cui->setprogress($sec);
	sleep 1;
    }
}

