This is some stuff for fiddling with Meat's RSP archive: parsing the files,
stuffing them into a MySQL database, "doing stuff" with them.

Things to note about the archive:
* The .zip file is one XML file per thread
* The files are organized by year *of last modification,* not the year they were originally posted
* The body of each post is the HTML of the post, not the BGG BBCode-style markup

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
