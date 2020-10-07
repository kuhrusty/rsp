#!/usr/bin/perl

=head1 NAME

unzip-year.perl - unzips a year of posts from RSPThreads.zip

=head1 SYNOPSIS

unzip-year.perl [options] [years]

If no years (4-digit numbers starting with 20) are given on the command line,
they'll be read from stdin.

For each year given, this unzips that year from the zip file, runs stomp.perl
and snort.perl on them, and then removes that directory.

=head1 OPTIONS

=over 8

=item B<-f FILENAME>

Path to RSPThreads.zip; defaults to "RSPThreads.zip".

=item B<-l>

Lists the years in the zip file instead of unpacking files.  In this case, we
won't expect a year on the command line.

=item B<-c>

Prints the number of threads in each year; implies -l.

=item B<-s>

Prints the total size of the unpacked threads for that year; implies -l.

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

my $filename = 'RSPThreads.zip';
my $listOnly = 0;
my $listCount = 0;
my $listSize = 0;
my $needManPage = 0;

Getopt::Long::Configure ("bundling");
GetOptions('f=s' => \$filename,
           'l!' => \$listOnly,
           'c!' => \$listCount,
           's!' => \$listSize,
           'man!' => \$needManPage) || pod2usage(1);
if ($needManPage) {
    pod2usage('-verbose' => 2); 
}
($listCount || $listSize) && ($listOnly = 1);

my @years = @ARGV;
if ((!$listOnly) && (scalar @years == 0)) {
    @years = <>;  #  read from stdin
    @years = map { chomp; $_ } @years;  #  remove trailing newlines
}
my $stomp = $0;
my $snort = $0;
$stomp =~ s,/[^/]+$,/stomp.perl,;
$snort =~ s,/[^/]+$,/snort.perl,;
(-x $stomp) || die("\"$stomp\" is not executable!");
(-x $snort) || die("\"$snort\" is not executable!");
(-e $filename) || die("\"$filename\" doesn't exist!");
((-f $filename) && (-r $filename)) || die("\"$filename\" isn't readable, or isn't a normal file!");

foreach my $year (@years) {
    ($year =~ /^20\d\d$/) || die("bad year \"$year\" (I mean... not as bad as 2020...)");
}

if ($listOnly) {
    my %yc;
    my %ys;
    open(ZIPIN, "unzip -l $filename |") || die("unzip failed: $?");
    while (<ZIPIN>) {
        chomp;
        if (/^\s*(\d+)\s+.+\s+(\d+)\/\d+$/) {
            my ($size, $year) = ($1, $2);
            $yc{$year} += 1;
            $listSize && ($ys{$year} += $size);
        } else {
            #print STDERR "ignoring \"$_\"\n";
        }
    }
    close(ZIPIN) || die("couldn't close unzip: $!");

    foreach (sort { $a <=> $b } keys %yc) {
        print "$_";
        ($listCount && print "\t$yc{$_} threads");
        #$listSize && print "\t$ys{$_} bytes");
        #  instead of that, let's be a little more coarse
        ($listSize && print "\t", ($ys{$_} / 1000000), " MB");
        print "\n";
    }
    exit;
}

foreach my $year (@years) {
    &unpackYear($year);
}

sub unpackYear() {
    my ($year) = @_;

    print "=== Unpacking $year from $filename\n";
    (-e $year) && die("$year already exists!");
    mkdir $year || die("couldn't create $year directory!");
    &doOrDie("unzip $filename $year/*");

    print "=== Stomping $year/*\n";
    &doOrDie("$stomp $year/*");

    print "=== Snorting $year/*\n";
    &doOrDie("$snort $year/*");

    print "=== Deleting $year/*\n";
    &doOrDie("rm $year/*");
    rmdir($year) || die("couldn't rmdir $year: $!");
}

sub doOrDie() {
    my ($cmd) = @_;
    system($cmd);
    $? && die("something bad happened with $cmd");
}
