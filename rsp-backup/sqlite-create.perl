#!/usr/bin/perl

=head1 NAME

sqlite-create.perl - creates the RSP DB schema in SQLite.

=head1 SYNOPSIS

sqlite-create.perl [-n]

The -n causes it to do a dry-run, not actually executing any commands.

NOTE THAT I HAVE ABOUT 5 MINUTES' EXPERIENCE WITH SQLITE; save your receipt.

=cut

use strict;
use Getopt::Long;
use Pod::Usage;

use lib ".";
use rspdb;

my $nocreate = 0;
GetOptions('n!' => \$nocreate) || pod2usage(1);

$nocreate || rspdb::isSQLite() || die("We're not using SQLite?!");

my $dbh = rspdb::getDBHandle();

#  rather than duplicating our schema in here, let's be classy & read it from
#  our MySQL SQL file.
my $sql = 'rsp_schema.sql';

open(SQL, "<$sql") || die("couldn't open $sql");

my $buf;
while (<SQL>) {
    chomp;
    s/\s*--.*$//;  #  strip comments
    /^\s*$/ && next;  #  bail if that's all we had

    s/ AUTO_INCREMENT//;
    s/UNIQUE KEY/UNIQUE/;
    #  we need our primary key columns to be "INTEGER", not "int"
    s/(\s+)int(\s+)/\1INTEGER\2/i;

    if (s/(ENGINE=MyISAM)?;//) {
        $buf .= $_;
        print "$buf\n\n";
        $nocreate || $dbh->do($buf) || die("Thanks, Obama: " . DBI->errstr());
        $buf = "";
    } else {
        $buf .= "$_\n";
    }
}
close(SQL);
