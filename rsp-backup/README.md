This is some stuff for fiddling with Meat's RSP archive: parsing the files,
stuffing them into a MySQL database, "doing stuff" with them.

Things to note about the archive:
* The .zip file is one XML file per thread
* The files are organized by year *of last modification,* not the year they were originally posted
* The body of each post is the HTML of the post, not the BGG BBCode-style markup

### Using SQLite instead of MySQL ###

**Terwox!  If you want to store post bodies, uncomment the `body` column** in
[rsp_schema.sql](rsp_schema.sql).

I haven't fiddled with this much, but I *have* confirmed that you can load
post data (including bodies) into a SQLite database.  To do this:

1. Set `$sqlite` to 1 in `rspdb.pm`, and confirm that you like the value of
`$sqliteFile` right below it.  (That file will be created by SQLite.)

2. Run the script which turns the MySQL `rsp_schema.sql` into SQLite syntax
and creates the tables:

    $ ./sqlite-create.perl

3. **Ignore** the entire "Setting up a MySQL database" section below;
`snort.perl` will happily use SQLite instead.

That should be it!

### Setting up a MySQL database ###

**Terwox!  If you want to store post bodies, uncomment the `body` column** in
[rsp_schema.sql](rsp_schema.sql).

This assumes you've got MySQL installed & running.  Create the database and
user:

    $ sudo mysql -u root
    mysql> create database rsp;
    mysql> use rsp;
    mysql> create user 'rsp-user' identified by 'rsp';
    mysql> grant all on rsp.* to 'rsp-user'@'%';
    mysql> \q

Confirm you can log in:

    $ mysql -u rsp-user -prsp rsp

Create the schema:

    $ mysql -u rsp-user -prsp rsp < rsp_schema.sql

Confirm that there are tables:

    $ mysql -u rsp-user -prsp rsp
    mysql> show tables;
    +---------------+
    | Tables_in_rsp |
    +---------------+
    | post          |
    | thread        |
    | user          |
    +---------------+
    3 rows in set (0.00 sec)

### Adding post data to the database ###

Extract a year's worth of posts from the archive:

    $ unzip ~/Downloads/RSPThreads.zip '2009/*'

Run the script which stomps some HTML entities which XML::LibXML was croaking
on (see below for more on this).

    $ ./stomp.perl 2009/*

Run the script which inserts the posts into the database (optionally with the
`-v` verbose flag):

    $ ./snort.perl -v 2009/*

**If you wanted the text of each post** in the database, then make sure you
uncommented the `body` column in the `CREATE TABLE` bit above, and run like
this:

    $ ./snort.perl --body 2009/*

Optionally, clean up the unpacked files:

    $ rm -rf 2009

### Getting data back out ###

Of course you can run SQL queries against the data directly, but there's also
`by-user.perl`, a script I was using to get counts & lists of posts & threads.

Normally it takes a list of users on the command line:

    $ ./by-user.perl -c kuhrusty 'Norbert Chan' Meat Meat Meat
    Meat           1266
    Norbert Chan   4
    kuhrusty       3607
    Total:         4877

That's saying Meat has 1266 posts in the archive, Norbert Chan has 4, and
kuhrusty has 3607.

How about threads:

    $ ./by-user.perl -tc kuhrusty 'Norbert Chan' Meat Meat Meat
    Meat           8
    Norbert Chan   0
    kuhrusty       25
    Total:         33

Meat has started 8 threads, Norbert Chan has started 0, and kuhrusty has
started 25.  **Note** that this considers the first poster in the thread to
have started it, even though this is **incorrect** when the first post(s) in
the thread has been deleted.

We can see a list of thread IDs:

    $ ./by-user.perl -t Meat
    Meat    8
      839465
      1917257
      1918062
      2208604
      2393813
      2394532
      2441781
      2443018
    Total:  8

Or we can see that as a list formatted for BGG links:

    $ ./by-user.perl -t --bgg Meat
    [b]Meat r{8}r[/b]

    [thread=839465][/thread]
    [thread=1917257][/thread]
    [thread=1918062][/thread]
    [thread=2208604][/thread]
    [thread=2393813][/thread]
    [thread=2394532][/thread]
    [thread=2441781][/thread]
    [thread=2443018][/thread]

    [b]Total: r{8}r[/b]

Same goes for posts:

    $ ./by-user.perl --bgg 'Norbert Chan'
    [b]Norbert Chan r{4}r[/b]

    [article=3587365][/article]
    [article=3836371][/article]
    [article=10653614][/article]
    [article=19202225][/article]

    [b]Total: r{4}r[/b]

If no user names are given on the command line, they're read from stdin:

    $ ./by-user.perl -c < banned-claimed
    CapAp               3079
    DWTripp             12233
    DaviddesJ           20638
    Edward Sexby        306
    LightRider          6720
    ...

### About that stomp.perl ###

I don't know why XML::LibXML is failing to parse XML files containing HTML
with entities like `&ouml;` and `&ndash;`, but it is.  (I tried setting its
`expand_entities` option to 0, but that didn't make a difference.)  So, the
horrible [stomp.perl](stomp.perl) edits-in-place those files, replacing those
entities with, uhh, lesser substitutes.
**This is horribly wrong and I am shamed.**

If you're suspicious about what it's doing *(as you should be!),* and you
have something like `xxdiff` installed, you can check the output:

    $ unzip ~/Downloads/RSPThreads.zip '2009/*'
    $ mv 2009 2009.orig
    $ unzip ~/Downloads/RSPThreads.zip '2009/*'
    $ ./stomp.perl 2009/*
    $ xxdiff 2009.orig 2009

Some years, it doesn't stomp anything, so, uhh, that's good.

### More non-ASCII stupidity ###

There are two users in the archive whose names contain non-ASCII characters,
and they're handled in quite possibly the dumbest and wrongest way possible:
I *replace* the non-ASCII characters with XXX.  So, uhh, if you see a few
messages like `STOMPING NON-ASCII "..."`, and users named `Sr. UlXXXXXX` and
`Punainen NXXXXXXrtti`, that's why.

It is *wrong,* but at least I didn't waste much time trying to get it *right.*

Note that these poor folks' names were also mangled *differently* by
`stomp.perl` where they were quoted in other users' posts.
