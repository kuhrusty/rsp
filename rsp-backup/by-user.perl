#!/usr/bin/perl

=head1 NAME

by-user.perl - prints information about posts by a list of user names

=head1 SYNOPSIS

by-user.perl [options] [names]

If no user names are given on the command line, they'll be read from stdin.
If a given user name doesn't already exist in the database written by
snort.perl, this will bail.

=head1 OPTIONS

=over 8

=item B<--bgg>

Lists of posts or threads will be formatted with BGG [thread] or [article]
markup.

=item B<-c>

Count: just print the number of posts or threads, not the list of IDs.

=item B<-t>

Look at threads I<started> by users, not posts.  Note that, if the original
post was deleted, the first remaining post will look like the user started
the thread.  This is a bug.

=item B<--man>

Display complete manual page.

=back

=head1 SEE ALSO

See the README at
https://github.com/kuhrusty/rsp/blob/master/rsp-backup/README.md

=cut

use strict;
use Getopt::Long;
use Pod::Usage;

use lib ".";
use rspdb;

my $countOnly = 0;
my $bggFormat = 0;
my $threadsOnly = 0;
my $needManPage = 0;

Getopt::Long::Configure ("bundling");
GetOptions('bgg!' => \$bggFormat,
           'c!' => \$countOnly,
           't!' => \$threadsOnly,
           'man!' => \$needManPage) || pod2usage(1);
if ($needManPage) {
    pod2usage('-verbose' => 2); 
}

my @usernames = @ARGV;
if (scalar @usernames == 0) {
    @usernames = <>;  #  read from stdin
    @usernames = map { chomp; $_ } @usernames;  #  remove trailing newlines
}

my $dbh = &rspdb::getDBHandle();
my %uidToUsername;
foreach my $username (@usernames) {
    my $uid = &rspdb::getUserID($dbh, $username);
    $uidToUsername{$uid} = $username;
}
my @uids = keys %uidToUsername;

if ($countOnly) {
    my %th = $threadsOnly ?
            &rspdb::getThreadCountsByUsers($dbh, \@uids) :
            &rspdb::getPostCountsByUsers($dbh, \@uids);
    &formatCounts(\%th);
} else {
    my %th = $threadsOnly ?
            &rspdb::getThreadIDsByUsers($dbh, \@uids) :
            &rspdb::getPostIDsByUsers($dbh, \@uids);
    &formatLists(\%th, $threadsOnly ? 'thread' : 'article');
}

$dbh->disconnect();

sub formatCounts() {
    my ($hash) = @_;
    my $total = 0;
    foreach my $uid (sort { $uidToUsername{$a} cmp $uidToUsername{$b} } keys %uidToUsername) {
        my $count = (defined $hash->{$uid}) ? $hash->{$uid} : 0;
        print "", $uidToUsername{$uid}, "\t$count\n";
        $total += $count;
    }
    print "Total:\t$total\n";
}

sub formatLists() {
    my ($hash, $markup) = @_;
    my $total = 0;
    foreach my $uid (sort { $uidToUsername{$a} cmp $uidToUsername{$b} } keys %uidToUsername) {
        my $ta = $hash->{$uid};
        if ($bggFormat) {
            print '[b]', $uidToUsername{$uid}, " r{", ($#{$ta} + 1), "}r[/b]\n\n";
        } else {
            print "", $uidToUsername{$uid}, "\t", ($#{$ta} + 1), "\n";
        }
        foreach my $tid (sort { $a <=> $b } @{$ta}) {
            if ($bggFormat) {
                print "[$markup=$tid][/$markup]\n";
            } else {
                print "  $tid\n";
            }
        }
        $bggFormat && print "\n";
        $total += ($#{$ta} + 1);
    }
    if ($bggFormat) {
        print "[b]Total: r{$total}r[/b]\n";
    } else {
        print "Total:\t$total\n";
    }
}
