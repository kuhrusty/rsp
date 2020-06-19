--  Tables for storing some information about RSP posts.  None of this is
--  interesting.
--
--  Note also that these are MyISAM instead of InnoDB because we probably
--  don't actually care about referential integrity (we're slapping the data
--  in once & from then on, just querying it), and we DO love the speed of
--  MyISAM.  We love it a LOT: starting from empty tables, InnoDB took ~29s
--  to insert 28 threads/459 posts/78 users (without post bodies); to do the
--  same thing, MyISAM took WELL UNDER HALF A SECOND.
--
--  hibikir suggested using SQLite; that looks cool, and I wish I had tried it.

CREATE TABLE user (
  userid int NOT NULL AUTO_INCREMENT,
  name varchar(40) NOT NULL,
  PRIMARY KEY (userid),
  UNIQUE KEY (name)
) ENGINE=MyISAM;

CREATE TABLE thread (
  threadid int NOT NULL,
  userid int NOT NULL,
  --  cosmetic
  subject varchar(80) NOT NULL DEFAULT '',
  PRIMARY KEY (threadid),
  FOREIGN KEY (userid) REFERENCES user (userid)
) ENGINE=MyISAM;

CREATE TABLE post (
  postid int NOT NULL,
  threadid int NOT NULL,
  userid int NOT NULL,
  --  hey Terwox, uncomment this
  --  also, note this only goes up to 64KB, and Shreve routinely posted
  --  2MB of text at a time.  (only half joking)
  --  also you may want to add some "flagged" tinyint column
  --body TEXT NULL,
  PRIMARY KEY (postid),
  FOREIGN KEY (threadid) REFERENCES thread (threadid),
  FOREIGN KEY (userid) REFERENCES user (userid)
) ENGINE=MyISAM;

--CREATE TABLE word (
--  wordid int NOT NULL AUTO_INCREMENT,
--  word varchar(40) NOT NULL,
--  PRIMARY KEY (wordid),
--  UNIQUE KEY (word)
--) ENGINE=MyISAM;
--
--CREATE TABLE postword (
--  postid int NOT NULL,
--  wordid int NOT NULL,
--  UNIQUE KEY (postid, wordid),
--  FOREIGN KEY (postid) REFERENCES post (postid),
--  FOREIGN KEY (wordid) REFERENCES word (wordid)
--) ENGINE=MyISAM;
