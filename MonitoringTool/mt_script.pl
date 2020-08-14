#!/usr/bin/perl

use Getopt::Long;
use Date::Calc qw(check_date);

# declare the perl command line flags/options we want to allow
my %options=();

GetOptions(
    'dir=s'    => \$options{dir},			# log directory path
    'date=s'     => \$options{date},		# date in 'yyyymmdd' formate
	'period=i'   => \$options{period},		# time period should be in minutes
    'help!'     => \$options{help},
) or die "Incorrect usage!\n";

#check whether valid date is given or not
if(defined $options{date}){
	die "Invalid date, Please check date given. " 
	unless (check_date(substr ($options{date},0,4),
					   substr ($options{date},4,2),
					   substr ($options{date},6,2))
			);
}

#default log directory configuration
#assumed both this perl script and logs directory are in same location
use constant DEFAULT_LOGS_DIR => 'logs';

#output directory, Excel reports will go into this directory
use constant DEFAULT_REPORTS_DIR => 'reports';


#use today's date if no date is specified
my($day, $month, $year) = (localtime)[3,4,5];
$month = sprintf '%02d', $month+1;
$day   = sprintf '%02d', $day;
$year = $year+1900;
my $date = (defined $options{date}) ? $options{date} : $year.$month.$day;

#use DEFAULT_LOGS_DIR, if no log directory is given
my $logdir = (defined $options{dir}) ? $options{dir} : DEFAULT_LOGS_DIR;

# Check whether given directory or default directory location exists or not
if (defined $logdir) {
	die "Log directory mentioned does not exists. Please check the path given." unless (-d $logdir);
}

#check for $logdir path whether ends with slash or not, if not add based on OS
my $last = substr $logdir,-1,1; 
my $os = $^O;
print "Running in: $os\n";
if($os eq "MSWin32"){			
	$logdir .= '\\' if ($last ne '\\');#windows based uses backward slash
}else{
	$logdir .= '/' if ($last ne '/');#windows based uses forward slash
}


#file name label can be changed here
my $cpu_file_name_label = "gfspan001_cpu_";
my $mem_file_name_label = "gfspan001_mem_";
my $io_file_name_label = "gfspan001_io_";

#filenames along with directory path
my $cpu_file = $logdir.$cpu_file_name_label.$date;
my $mem_file = $logdir.$mem_file_name_label.$date;
my $io_file = $logdir.$io_file_name_label.$date;

#check by printing the filenames
print "\ncpu_file: ".$cpu_file;
print "\nmem_file: ".$mem_file;
print "\nio_file: ".$io_file;

# open the files for reading
open (CPUFH, "<", $cpu_file) or die "cannot open < $cpu_file: $!";
open (MEMFH, "<", $mem_file) or die "cannot open < $mem_file: $!";
open (IOFH, "<", $io_file) or die "cannot open < $io_file: $!";

#CPU Calculation
my $time;
my $usr,$sys,$idl;
my $cpu;
my $total_cpu = undef;
while(<CPUFH>){
	if($_ =~ /^SET/){		#ignore headings
		#ignore this line
	}elsif ($_=~ /^\w+/){	#Time Match
		if (defined $total_cpu){
			print "\n Avg cpu at $time -> ".$total_cpu/5;
		}
		my ($hour,$mmss) = (split(/\s+/, $_))[2,3];
		$time = $hour .":". substr($mmss,0,5);
		$total_cpu = 0;
	}else{					#Other List of Values
		($usr,$sys,$idl) = (split(/\s+/, $_))[13,14,16];
		#print "\n $usr,$sys,$idl";
		$cpu = $usr+$sys+$idl;
		$total_cpu += $cpu;
	}
}
#this prints last value
print "\n Avg cpu at $time -> ".$total_cpu/5;


#Memory Calculation
my $free,$total;
my $mem;
my $total_mem = undef;
while(<MEMFH>){
	if($_ =~ /^\s+(k|r)/){		#ignore headings
		#ignore this line
	}elsif ($_=~ /^\w+/){		#Time Match
		if (defined $total_mem){
			print "\n Avg free memory at $time -> ".($total_mem/2)/1024 ."KB";
		}
		my ($hour,$mmss) = (split(/\s+/, $_))[2,3];
		$time = $hour .":". substr($mmss,0,5);
		$total_mem = 0;
	}else{						#Other List of Values
		($swap, $free) = (split(/\s+/, $_))[4,5];
		#print "\n $swap, $free";
		$mem = $free;
		$total_mem += $mem;
	}
}
#this prints last value
print "\n Avg free memory at $time -> ".($total_mem/2)/1024 ."KB";


#IO Calculation
my $rs,$ws,$device;
my $io;
my $total_io = undef;
while(<IOFH>){
	if($_ =~ /^\s+(e|r)/){		# ignore headings
		#ignore this line
		#print "\n".$_;
	}elsif ($_=~ /^\w+/){
		if (defined $total_io){
			print "\n Avg IO read write at $time -> ".$total_io/50;
		}
		my ($hour,$mmss) = (split(/\s+/, $_))[2,3];
		$time = $hour .":". substr($mmss,0,5);
		$total_io = 0;
	}else{
		($rs, $ws,$device) = (split(/\s+/, $_))[1,2,11];
		#print "\n $rs, $ws";
		$io = $rs+$ws;
		$total_io += $io;
	}
}

#this prints last value
print "\n Avg IO read write at $time -> ".$total_io/50;

#close file handler
close CPUFH;
close MEMFH;
close IOFH;