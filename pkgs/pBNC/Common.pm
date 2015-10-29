#!/usr/bin/perl

package pBNC::Common;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw( trim writeStrToFile );


$VERSION = 0.01;

# Remove leading and trailing whitespaces.
sub trim {
	my $s = shift;
	$s =~ s/^\s+|\s+$//g;
	return $s
};

sub writeStrToFile {
	my $OutPath = shift;
	my $TextToWrite = shift;
	
	my $FileHandle;
	open($FileHandle, '>>:encoding(UTF-8)', "$OutPath") or die("Error! Unable to open file '$OutPath' for writing.");
	print $FileHandle "$TextToWrite";
	close ($FileHandle) or die ("Unable to close file '$OutPath'.");
};
