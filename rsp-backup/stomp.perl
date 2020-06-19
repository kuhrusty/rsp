#!/usr/bin/perl -pi

#  Truly horrible script which stomps some HTML entities which XML::LibXML was
#  croaking on.  (Not sure why it's trying to parse them in the first place.)

s/&rsquo;/'/g;
s/&ccedil;/c/g;  #  look, broken is broken
s/&eacute;/e/g;
s/&egrave;/e/g;
s/&Iacute;/I/g;
s/&oslash;/o/g;
s/&ouml;/o/g;
s/&sect;/SS/g;

s/&rlm;//g;  #  wtf
s/&ndash;/-/g;
s/&thinsp;/ /g;
