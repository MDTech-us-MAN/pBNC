#!/usr/bin/perl

use strict;
use warnings;
use Path::Class;

use Config::Tiny;

my $ConfigDir;
my $PkgsDir;

BEGIN {

# Get the absolute path to the config dir where this file should be. 
$ConfigDir = file("$0")->absolute->dir;

# Get the absolute path to the pkgs dir to be included.
$PkgsDir = dir($ConfigDir->parent, 'pkgs');

}

# Include Common pkgs.
use lib "$PkgsDir";

# Include the Common module.
use pBNC::Common;

print "Welcome to pBNC!\n\n";

print "This is script should be used to generate a config file for a new user.\n\n";

print "We will now ask you a few questions to get the required information.\n\n\n";


# Define the hash.
my %UserInfo;


# Get username.
print "\nWhat is the username for the new user? This must be unique. ";

# Save it to variable;
my $UserName = <STDIN>;

# Remove the newline.
chomp($UserName);

# Remove leading and trailing spaces.
$UserName = trim($UserName);

# Put it into the hash.
$UserInfo{'username'} = $UserName;

# Get Nickname used when connecting to the IRC server.
print "\n\nWhat is the nickname to be used on IRC? [$UserName] ";

# Save the reply.
$UserInfo{'nick'} = <STDIN>;

# Remove the newline.
chomp($UserInfo{'nick'});

# Remove leading and trailing spaces.
$UserInfo{'nick'} = trim($UserInfo{'nick'});

# If no entry, default to the username.
if (!$UserInfo{'nick'}) {
	$UserInfo{'nick'} = $UserName;
}


# Get the ident.
print "\n\nWhat ident should be sent to the IRC server [$UserInfo{'nick'}] ";

# Save the reply.
$UserInfo{'ident'} = <STDIN>;

# Remove the newline.
chomp($UserInfo{'ident'});

# Remove leading and trailing spaces.
$UserInfo{'ident'} = trim($UserInfo{'ident'});

# If no entry, default to the username.
if (!$UserInfo{'ident'}) {
        $UserInfo{'ident'} = $UserInfo{'nick'};
}


# Get the Real Name.
print "\n\nWhat should be Real Name to be sent on IRC? [$UserInfo{'nick'}] ";

# Save the reply.
$UserInfo{'realname'} = <STDIN>;

# Remove the newline.
chomp($UserInfo{'realname'});

# Remove leading and trailing spaces.
$UserInfo{'realname'} = trim($UserInfo{'realname'});

# If no entry, default to the username.
if (!$UserInfo{'realname'}) {
        $UserInfo{'realname'} = $UserInfo{'nick'};
}


# Get IRC Server.
print "\n\nWhat is the IRC server this user will connect to? ";

# Save the reply.
$UserInfo{'serverhost'} = <STDIN>;

# Remove the newline.
chomp($UserInfo{'serverhost'});

# Remove leading and trailing spaces.
$UserInfo{'serverhost'} = trim($UserInfo{'serverhost'});

# If no entry, exit.
if (!$UserInfo{'serverhost'}) {
        print "\nIRC Server cannot be empty!\n";
	exit 1;
}


# Get IRC Port.
print "\n\nWhat is the port that will be used to connect to IRC? [6667] ";

# Save the reply.
$UserInfo{'serverip'} = <STDIN>;

# Remove the newline.
chomp($UserInfo{'serverip'});

# Remove leading and trailing spaces.
$UserInfo{'serverip'} = trim($UserInfo{'serverip'});

# If no entry, exit.
if (!$UserInfo{'serverip'}) {
        $UserInfo{'serverip'} = "6667";
}


# Get Server Password.
print "\n\nWhat password should I send to the IRC server? (Probably empty) "; 

# Save the reply.
$UserInfo{'serverpass'} = <STDIN>;

# Remove the newline.
chomp($UserInfo{'serverpass'});

# Remove leading and trailing spaces.
$UserInfo{'serverpass'} = trim($UserInfo{'serverpass'});

# If no entry, set to nothing.
if (!$UserInfo{'serverpass'}) {
        $UserInfo{'serverpass'} = "";
}


print "\n\n\n\nSaving user configuration... \n";

sleep 1;

my $UserConfFile = "$ConfigDir/users/$UserName.conf";

if (-e "$UserConfFile") {
	print "    A configuration file with this name already exists. Would you like to overwrite it? (Yes/[No]) ";
	
	# Get Reply
	my $OverwriteReply = <STDIN>;
	
	# Remove the newline.
	chomp($OverwriteReply);
	
	# Remove leading and trailing spaces.
	$OverwriteReply = trim($OverwriteReply);
	
	# Check input.
	if (uc($OverwriteReply) ne "Y" && uc($OverwriteReply) ne "YES") {
		print "\nExiting.\n";
	} else {
		system("rm -rf $UserConfFile");
	}
}

print "\nWriting configuration file... ";

# Create new config.
my $Config = Config::Tiny->new;

# Write To config.
$Config->{UserInfo} = \%UserInfo;

# Save config.
$Config->write("$UserConfFile", 'utf8');


print "\n\nNew User has been added successfully.";

print "\n\nHave a good day!\n\n";


#while( my( $key, $value ) = each %UserInfo ){
#    print "$key: $value\n";
#}
