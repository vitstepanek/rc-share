#!/usr/bin/perl -w

# Read lines from stdin. Timestamp in the beginning of each line (if any) will be cut off and the rest of the line sent to stdout.
# If no timestamp is found the whole line is printed. 
#
# Format example:
# 2022-05-11T11:32:13.576+02:00


use strict;
use warnings FATAL => 'all';


while (my $line = <STDIN>) {
    chomp $line;
    if ($line =~ /^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}\+\d{2}:\d{2})( )(.*)$/) {
        print STDOUT $3 . "\n";
    } else {
        print STDOUT $line . "\n";
    }
}





1;
