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
on.

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
