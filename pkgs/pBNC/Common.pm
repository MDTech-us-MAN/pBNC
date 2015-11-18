#!/usr/bin/perl

package pBNC::Common;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw( trim EndsWith writeStrToFile WriteConfig ReadConfig );


$VERSION = 0.011;


use Config::Tiny;


# Remove leading and trailing whitespaces.
sub trim {
	my $s = shift;
	$s =~ s/^\s+|\s+$//g;
	return $s
};

sub EndsWith {
	my $s = shift;
	my $EndsWith = shift;
	if ($s =~ /$EndsWith$/) {
		return 1;
	} else {
		return 0;
	}
};




sub writeStrToFile {
	my $OutPath = shift;
	my $TextToWrite = shift;
	
	my $FileHandle;
	open($FileHandle, '>>:encoding(UTF-8)', "$OutPath") or die("Error! Unable to open file '$OutPath' for writing.");
	print $FileHandle "$TextToWrite";
	close ($FileHandle) or die ("Unable to close file '$OutPath'.");
};

sub WriteConfig {
	my $OutPath = shift;
        my %UserInfo = @_;
	
	# Create new config.
	my $Config = Config::Tiny->new;
	
	# Write to config.
	$Config->{UserInfo} = \%UserInfo;
	
	# Save config.
	$Config->write("$OutPath", 'utf8');
};

sub ReadConfig {
	my $ConfPath = shift;
	#my %OutputHash = @_;
	
	
	# Read Config.
	my $Config = Config::Tiny->read( "$ConfPath", 'utf8' );
	
	# Read the data.
	my %UserInfo = %{$Config->{UserInfo}};
	
	return (\%UserInfo);
}
