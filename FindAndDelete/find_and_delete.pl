#/usr/bin/perl
#############
# Filter lines on output file without ids found on input file with integer greater than limit
# Usage: 
#      perl find_and_delete.pl -i in.txt -o out.txt -limit 70
#############

use strict;
use Getopt::Long;

my $input_file  = 'in.txt';
my $output_file = 'out.txt';
my $limit	= 80;  	#default
my $help;

GetOptions ("i=s"       => \$input_file,
      	    "o=s"       => \$output_file,
	    "limit:i"   => \$limit,
            "help|?"    => \$help)
or die("Error in command line arguments\n");

open (my $in_fh, '<', $input_file ) or die $!;
open (my $out_fh, '<', $output_file ) or die $!;

my @ids = ();
foreach my $in_line ( <$in_fh> ) {
    chomp($in_line);
    my @records = split(/\s+/,$in_line);
    push @ids, $records[1] if $records[0] >= $limit;
}

#print "@ids";

open (my $result_fh, '>', $output_file."_new" ) or die $!;
foreach my $out_line ( <$out_fh> ) {
    my $found = 0;
    foreach my $id (@ids) {
	$found = 1 if ( $out_line =~ /$id/ );
    }
    print $result_fh $out_line if $found ==0;
    print $out_line if $found ==0;
}

close $in_fh;
close $out_fh;
close $result_fh;

