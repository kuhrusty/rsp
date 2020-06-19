#  This is utility stuff included by snort.perl.

package rspdb;
use strict;
use DBI;

#  To use SQLite, set this to 1 and make sure you like the filename.
my $sqlite = 0;
my $sqliteFile = 'rspdb.sqlite';
my $IGNORE = 'IGNORE';
my %userNameToID = ();

#  Call disconnect() on this guy when you're done
sub getDBHandle() {
    my $dbh = $sqlite ?
        DBI->connect("DBI:SQLite:dbname=$sqliteFile", "", "") :
        DBI->connect("DBI:mysql:rsp", "rsp-user", "rsp");
    $dbh || die("couldn't connect: " . DBI->errstr());
    if ($sqlite) {
        $IGNORE = 'OR IGNORE';
        $dbh->do('PRAGMA synchronous = OFF');
    }
    return $dbh;
}

#  Returns true if we think we're using SQLite, false if not.
sub isSQLite() {
    $sqlite;  #  yeah, well, you paid $0 for this code, right?
}

#  Returns an int ID for the user, adding it to the database if necessary.
sub getOrCreateUserID() {
    my ($dbh, $username) = @_;

    if ((scalar %userNameToID) == 0) {
        &loadUsers($dbh);
    }

    #  here's a real classy workaround for two non-ASCII usernames.
    if ($username =~ /[^\x00-\x7e]/) {
        my $ts = $username;
        $ts =~ s/[^\x00-\x7e]/XXX/g;  #  I am shamed
        print STDERR "STOMPING NON-ASCII \"$username\" -> \"$ts\"\n";
        $username = $ts;
    }

    my $userid = $userNameToID{$username};
    (defined $userid) && (return $userid);

    my $sth = $dbh->prepare("INSERT INTO user (name) VALUES (?)");
    $sth->execute($username) || die("couldn't insert user: " . DBI->errstr());
    #$dbh->commit;  #  gives a warning about autocommit on my box
    $userid = $dbh->last_insert_id(undef, undef, 'user', 'name');
    $userNameToID{$username} = $userid;
    #print "added $username -> $userid\n";
    return $userid;
}

#  loads our userID cache
sub loadUsers() {
    my ($dbh) = @_;

    my $sth = $dbh->prepare("SELECT userid, name FROM user");
    $sth->execute() || die("couldn't load users: " . DBI->errstr());
    while (my @row = $sth->fetchrow_array) {
        $userNameToID{$row[1]} = $row[0];
    }
}

#  Adds the thread to the "thread" table if it's not already there
sub addThread() {
    my ($dbh, $threadid, $userid, $subject) = @_;

    #  well, we "know" we only have room for 80 chars in the column
    (defined $subject) && ($subject = substr($subject, 0, 80));

    my $sth = $dbh->prepare("INSERT $IGNORE INTO thread (threadid, userid, subject) VALUES (?, ?, ?)");
    $sth->execute($threadid, $userid, $subject) || die("couldn't add thread: " . DBI->errstr());
}

#  Adds the post to the "post" table if it's not already there.  $body should
#  be undef if you didn't uncomment the "body" column in the post table.
#
#  Also, if you call this on a post with $body undef, and then a second time
#  with $body filled in, the record won't get updated; you'll need to delete
#  from the post table first.
sub addPost() {
    my ($dbh, $threadid, $postid, $userid, $body) = @_;

    if (defined $body) {
        my $sth = $dbh->prepare("INSERT $IGNORE INTO post (postid, threadid, userid, body) VALUES (?, ?, ?, ?)");
        $sth->execute($postid, $threadid, $userid, $body) || die("couldn't add post with body: " . DBI->errstr());
    } else {
        my $sth = $dbh->prepare("INSERT $IGNORE INTO post (postid, threadid, userid) VALUES (?, ?, ?)");
        $sth->execute($postid, $threadid, $userid) || die("couldn't add post: " . DBI->errstr());
    }
}

1;
