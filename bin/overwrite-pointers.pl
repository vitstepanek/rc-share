#!/usr/bin/perl -w

# Overwrite addresses like this to make diff easier
# 0x22c4fe0


use strict;
use warnings FATAL => 'all';


while (my $line = <STDIN>) {
    chomp $line;
    $line =~ s/0x[[:xdigit:]]+/0xaddress/g;
    print STDOUT $line . "\n";
}




1;
