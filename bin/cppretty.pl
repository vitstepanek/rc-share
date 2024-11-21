#!/usr/bin/perl -w

# Simple regex-based code beautifier
# See --help for more


use strict;
use warnings FATAL=>'all';

use Data::Dumper;
use Getopt::Long;

my $action = "";
my $actionMap = {
    "replacetabs" => \&replaceTabs,
    "trailingbracket" => \&trailingBracket,
    "trailingwhitespace" => \&trailingWhitespace,
    "spaceafterif" => \&spaceAfterIf,
};

my $reaction = 'change';

my $reactionMap = {
    'change' => sub {
        my $original = shift;
        my $formatted = shift;
        return system("mv", $formatted, $original);
    },
    'compare' => sub {
        my $original = shift;
        my $formatted = shift;
        my $res = system("cmp", "--quiet", $formatted, $original);
        system("rm", "-f", $formatted);
        return $res;
    },
    'diff' => sub {
        my $original = shift;
        my $formatted = shift;
        my $res = system("diff", $original, $formatted);
        system("rm", "-f", $formatted);
        return $res;
    },
};

GetOptions(
    'action=s' => \$action,
    'list-actions' => sub { print "Available actions: " . join(', ', keys %$actionMap) . "\n"; exit 0; },
    'list-reactions' => sub { print "Available reactions: " . join(', ', keys %$reactionMap) . "\n"; exit 0; },
    'help' => sub {
        print "cppretty.pl --action <action-to-perform> --reaction <reaction-to-perform> <filename [, filename2, ...filenameN]> \n";
        print "     Actions:\n";
        print "         'replacetabs' - replaces all trailing tabs with spaces (4 spaces per tab)\n";
        print "         'trailingbracket' - moves opening curly bracket at the end of a line to a new line\n";
        print "         'trailingwhitespace' - all trailing whitespace at the end of a line is trashed\n";
        print "         'spaceafterif' - pushes a single space char between if and the condition\n";
        print "    Reactions:\n";
        print "         'change' (default) - format files\n";
        print "         'compare' - don't modify files, only check if any formatting is required; exit code of the script describes the result; files that require formatting are listed on STDERR\n";
        print "         'diff' - don'f modify files, output any differences if any; exit 0 if no diff, 1 otherwise \n";
        exit 0;
    },
    'reaction=s' => \$reaction,
) or die "Failed to parse options!";

# Files to beautify
my @files = @ARGV;

# Validations
die "Action missing!\n"
    unless length($action);

die "Unrecognized action '$action'!\n"
    unless exists $actionMap->{$action};

die "No files provided!\n"
    unless @files;

die "Unrecognized reaction '$reaction'!\n"
    unless exists $reactionMap->{$reaction};

# ACTIONS
# Each of these applies to a single chomp'ed line
# Beautified (or untouched) line is returned back

sub replaceTabs {
    my $line = shift;
    if ($line =~ /^(\t*)(.*)$/) {
        my $replacement = '    ' x length($1);
        $line = $replacement . $2;
    }
    return $line . "\n";
}

sub trailingBracket {
    my $line = shift;
    if ($line =~ /^(.+)\{$/) {
        my $baseLine = $1;
        if ($baseLine =~ /^\s+$/) {
            return $line . "\n";
        }
        my $indentation = $1 if ($line =~ /^(\s*)/);
        return $baseLine . "\n" . $indentation . "{\n";
    } else {
        return $line . "\n";
    }
}

sub trailingWhitespace {
    my $line = shift;
    if ($line =~ /^(.*)\s+$/) {
        $line = $1;
    }
    return $line . "\n";
}

sub spaceAfterIf {
    my $line = shift;
    if ($line =~ /^(\s*)(if|while|for)(\(.*)$/) {
        return $1 . $2 . " " . $3 . "\n";
    }
    return $line . "\n";
}


# Provide a closure reading/writing lines of a file
# Each line converted by action passed to the closure as an argument

sub processFile {
    my $filename = shift;
    my $sub = shift;
    my $reaction = shift;
    my $outfilename = $filename . ".pretty";

    return sub {

        open(INFH, "<", $filename) or die "Can't read file '$filename'! \n";
        open(OUTFH, ">", $outfilename) or die "Can't write to file '$outfilename'! \n";
        while (my $line = <INFH>) {
            chomp $line;
            $line = $sub->($line);
            print OUTFH $line;
        }
        close(INFH);
        close(OUTFH);

        return $reaction->($filename, $outfilename);
    }
}

my $overall = 0;
foreach my $filename (@files) {
    my $res = processFile($filename, $actionMap->{$action}, $reactionMap->{$reaction})->();
    if ($res ne 0) {
        print STDERR "$filename\n";
    }
}

# exit with 0 or 1
exit ! ($overall eq 0);

1;
