#!/usr/bin/perl

#  To see the documentation embedded in this guy, "perldoc snort.perl"
#  or run ./snort.perl --man

=head1 NAME

snort.perl - stuffs RSP post data into a database

=head1 SYNOPSIS

snort.perl [options] files

=head1 OPTIONS

=over 8

=item B<--body>

Includes the body of the post in the post table.  Currently this includes
the HTML markup, which may not be what you want if your name is Terwox.

Note that this will croak or fail if the post table doesn't have a "body"
column.

=item B<-v>

Verbose: prints more information about what it's doing.

=item B<-s>

Silent: prints less.

=item B<--man>

Display complete manual page.

=back

=head1 DESCRIPTION

This reads one or more XML backups (presumably from Meat's RSP archive) and
stuffs information about their contents into a database.

This can be run repeatedly on the same data without causing duplicates.

After running this for some of the data, you may want to run ANALYZE TABLE
and OPTIMIZE TABLE on each rspdb table.

See the README at
https://github.com/kuhrusty/rsp/blob/master/rsp-backup/README.md

=cut

use 5.010;  #  for LibXML
use strict;
use Getopt::Long;
use Pod::Usage;
use XML::LibXML;

use lib ".";
use rspdb;

#  if true, we'll write the HTML of each post to the post table
my $withBody = 0;
my $needManPage = 0;
my $verbose = 0;
my $silent = 0;

Getopt::Long::Configure ("bundling");
GetOptions('body!' => \$withBody,
           's!' => \$silent,
           'v!' => \$verbose,
           'man!' => \$needManPage) || pod2usage(1);
if ($needManPage) {
    pod2usage('-verbose' => 2); 
} elsif ($verbose && $silent) {
    pod2usage("I can't be silent AND verbose!");
}

((scalar @ARGV) > 0) || pod2usage("Give me some input files!");

#  expand_entities => 0 and $xmlParser->expand_entities(0) did not help
my $xmlParser = XML::LibXML->new();#'expand_entities' => 0);
#$xmlParser->expand_entities(0);

my $dbh = &rspdb::getDBHandle();
foreach my $file (@ARGV) {
    $silent || print "processing $file\n";
    #  load_xml() croaks if it can't parse the file
    &processXML($xmlParser->load_xml(location => $file));
}
$dbh->disconnect();


sub processXML() {
    my ($dom) = @_;

    my $threadid = $dom->findvalue('./thread/@id');
    $silent || print "  thread $threadid\n";
    my $postcount = 0;
    foreach my $post ($dom->findnodes('./thread/articles/article')) {
        &processPost($threadid, $post, $postcount++);
    }
}

sub processPost() {
    my ($threadid, $post, $postcount) = @_;

    my $postid = $post->findvalue('./@id');
    my $user = $post->findvalue('./@username');
    my $body = $withBody ? $post->findvalue('./body') : undef;
    if ($verbose) {
        print "  post == $postid\n";
        print "  user == $user\n";
        $withBody && print "  body == $body\n\n";
    }

    my $userid = &rspdb::getOrCreateUserID($dbh, $user);

    if ($postcount == 0) {
        $verbose && print "    adding to thread table\n";
        my $subject = $post->findvalue('./subject');
        &rspdb::addThread($dbh, $threadid, $userid, $subject);
    }
    &rspdb::addPost($dbh, $threadid, $postid, $userid, $body);
}
