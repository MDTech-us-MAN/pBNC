#!/usr/bin/perl

use forks::BerkeleyDB;

use strict;
use warnings;

use Path::Class;
use Storable 'dclone';
use POE;
use POE::Component::IRC;
use POE::Component::Server::TCP;
use IPC::DirQueue;

my $MainDir;
my $PkgsDir;

BEGIN {

# Get the absolute path to the config dir where this file should be.
$MainDir = file("$0")->absolute->dir;

# Get the absolute path to the pkgs dir to be included.
$PkgsDir = dir($MainDir->parent, 'pkgs');

}

# Include Common pkgs.
use lib "$PkgsDir";


use pBNC::Common;



# Get config dir.
my $ConfigDir = dir($MainDir->parent, 'config');

my %GlobalConfigStore;


### Read User Configs. ###

# Get User Config directory.
my $UserConfigDir = dir($ConfigDir, 'users');

# Get User configs
while (my $UserConfFile = $UserConfigDir->next) {
	if (EndsWith("$UserConfFile", '.conf')) {
#		print "$UserConfFile\n\n";
		my $UserInfo = ReadConfig("$UserConfFile");
		
		my $username = $UserInfo->{username};

#		print "$username\n\n";
		
		$GlobalConfigStore{$username} = { %$UserInfo };
		$GlobalConfigStore{$username}{ircClient} = POE::Component::IRC->spawn();
		#@GlobalConfigStore{$username}{SendQ} = @( );
		#@GlobalConfigStore{$username}{RecieveQ} = @( );
	}
}



my $SendQ = IPC::DirQueue->new({ dir => $ConfigDir . "/queues/SendQ" });

my $RecieveQ = IPC::DirQueue->new({ dir => $ConfigDir . "/queues/RecieveQ" });


####################################


# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
POE::Session->create(
	inline_states => {
		_start     => \&POE_Ready,
		irc_001    => \&on_connect,
		irc_raw	   => \&on_raw,
	},
);

sub POE_Ready {
	foreach my $key (keys %GlobalConfigStore)
	{
		my %value = %{ $GlobalConfigStore{$key} };
		$value{onConn} = "";
		$value{ircClient}->yield(register => "all");
		$value{ircClient}->yield(
			connect => {
				Nick		=> $value{nick},
				Username	=> $value{ident},
				Ircname		=> $key,
				Server		=> $value{serverhost},
				Port		=> $value{serverport},
#				Debug		=> 1,
				Raw		=> 1
			}
		);
	}
}

sub on_connect {
	my $currClient = $_[SENDER]->get_heap();
	
	$currClient->yield( join => "#lobby" );
}


sub on_raw {
	my $recieved = $_[ARG0];
	
	my @parts = split / /, $recieved, 3;
	
	if ( uc($parts[0]) ne "PING" ) {
		print "$parts[0] $parts[1] $parts[2]\n\n";
		
		my $CurrKey;
		
		foreach my $key (keys %GlobalConfigStore)
		{
			if ( $GlobalConfigStore{$key}{ircClient} eq $_[SENDER]->get_heap() ) {
				$CurrKey = $key;
				last;
			}
		}
		
		if (!$GlobalConfigStore{$CurrKey}{EOMOTDR}) {
			$GlobalConfigStore{$CurrKey}{onConn} .= "$recieved\n";
			
			my @parts = split / /, $recieved, 3;
			
			if ($parts[1] && $parts[1] eq "376") {
				$GlobalConfigStore{$CurrKey}{EOMOTDR} = 1;
			}
		}
		
		
		push @{ $GlobalConfigStore{$CurrKey}{RecieveQ} }, {username => $CurrKey, data => $recieved};
		$poe_kernel->signal($poe_kernel, 'RecieveQ_Add', $CurrKey);
	}
}


POE::Session->create(
	inline_states => {
		_start => sub {
			#$_[KERNEL]->sig(SendSig => 'SendQ_Add');
			
			$_[KERNEL]->delay(tick => 1);
		},
		
		tick => sub {
			#my ($session, $heap, $Key) = @_[SESSION, HEAP, ARG0];
			foreach my $key (keys %GlobalConfigStore)
		        {
		        my %value = %{ $GlobalConfigStore{$key} };
			
			if ($GlobalConfigStore{$key}{SendQ}) {
				
			
			
			my %job = pop @{ $GlobalConfigStore{$key}{SendQ} };
			
			if (%job) {
			
				my $message = $job{data};
				
				my $username = $job{username};
				
				print "$username";
			
				$GlobalConfigStore{$username}{ircClient}->yield( quote => "$message" );
	
			}
			}}
			$_[KERNEL]->delay(tick => 1);
		},
	},
);

#############################################

my %IDUsernamePairs;




my $ClientListener :shared = POE::Component::Server::TCP->new(
	Alias       => "echo_server",
	Port        => 12345,
	InlineStates => {send => sub {
		my ($heap, $message) = @_[HEAP, ARG0];
		$heap->{client}->put($message);
	}},
	ClientInput => sub {
		my ($session, $heap, $input) = @_[SESSION, HEAP, ARG0];
		print "Session ", $session->ID(), " got input: $input\n";
		
		my @parts = split / /, $input, 2;
		
		if ($parts[0] eq "PASS") {
			if ( grep $_ eq $parts[1], keys %GlobalConfigStore ) {
				$IDUsernamePairs{$session->ID()} = $parts[1];
			}
		} elsif ($parts[0] eq "USER") {
			$heap->{client}->put($GlobalConfigStore{$IDUsernamePairs{$session->ID()}}{onConn});
		} else {
			if ($parts[0] ne "USER" && $IDUsernamePairs{$session->ID()}) {
				push @{ $GlobalConfigStore{$IDUsernamePairs{$session->ID()}}{SendQ} }, {data => "$parts[0] $parts[1]", username => $IDUsernamePairs{$session->ID()} };
				$poe_kernel->signal($poe_kernel, 'SendQ_Add');
			}
		}
	}
);


POE::Session->create(
        inline_states => {
                _start => sub {
                        #$_[KERNEL]->sig(RecvSig => 'RecieveQ_Add');
			$_[KERNEL]->delay(tick => 1);
                },

                tick =>  sub {
		#RecvSig => sub {
                        #my ($session, $heap, $Key) = @_[SESSION, HEAP, ARG0];
			
			foreach my $key (keys %GlobalConfigStore)
                        {

                        my %job = pop @{ $GlobalConfigStore{$key}{RecieveQ} };

                        if (%job) {

                                my $message = $job{data};

                                my $username = $job{username};
			
				my $sent = 0;
		
		                foreach my $key (keys %IDUsernamePairs) {
					if ($IDUsernamePairs{$key} eq $username) {
						$poe_kernel->post($key => send => "$message");
						$sent = 1;
					}
				}
			
				if ($sent) {
	#				$job->finish();
				}
			
				#$GlobalConfigStore{$username}{ircClient}->yield( quote => "$message" );
			}
			$_[KERNEL]->delay(tick => 1);
			}
	        },
	},
);


POE::Kernel->run();

