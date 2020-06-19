#!/usr/bin/perl -pi

#  Truly horrible script which stomps some HTML entities which XML::LibXML was
#  croaking on.  (Not sure why it's trying to parse them in the first place.)

s/&rsquo;/'/g;
s/&eacute;/e/g;
s/&sect;/SS/g;
