#!/usr/bin/perl

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;
use Getopt::Long;
use File::Basename;

#default values
my @xml_files           =   ();   
my $output_directory    =   ".";           
my $alias_file_suffix   =   "_alias";      
my $test_file_prefix    =   "sample"; 
my $help                =   0;
my $verbose             =   1;

sub usage {
    my $exit_status = shift;
    my $usage = <<"END_USAGE";

    Usage: $0 [--xml_file=<xml_file>..] [--output_directory=<output_directory>] [--alias_file_name=<alias_file_name>] [--test_file_prefix=<test_file_prefix>] [--help]
    Options:
        --xml_file          :  Optional, Default: xml extension files in current directory, Can accept multiple xml files, provide complete xml file name with directory path. 
        --output_directory  :  Optional, Default: Current Directory, output directory of where test scripts and alias file will be created.
        --alias_file_suffix :  Optional, Default: _alias, alias file suffix, alias prefix will xml file basename.
        --test_file_prefix  :  Optional, Default: sample, prefix appended to created test files.
        --help              :  Optional, print this summary.
        --verbose           :  Optional, print verbose messsages.

    Examples:
        $0 --xml_file=/path/to/xml
        $0 --xml_file=/path/to/xml_file_1 --xml_file=/path/to/xml_file_2 --alias_file_name=my_alias --test_file_prefix=my_test 
        $0 --help

END_USAGE
    print $usage;
    exit($exit_status);
}

GetOptions(    
            'xml_file=s{1,}'        =>  \@xml_files,
            'output_directory=s'    =>  \$output_directory, 
            'alias_file_suffix=s'   =>  \$alias_file_suffix, 
            'test_file_prefix=s'    =>  \$test_file_prefix, 
            'help|?'                =>  \$help, 
            'verbose+'              =>  \$verbose, 
) or usage(1);

usage(0) if ($help == 1);

print "Arguments Passed: \n" 
            . "xml_files          : @xml_files \n"
            . "output_directory   : $output_directory \n"
            . "alias_file_suffix  : $alias_file_suffix \n "
            . "test_file_prefix   : $test_file_prefix \n" 
if ($verbose);


#Validate arguments passed

# Read xml files in current working direcoty, if none of the xml files passed as arguments.
@xml_files  =   glob "./*.xml" unless (@xml_files);   

# chop off slash character, if any, at the end of output directory name
chop ($output_directory) if ( substr($output_directory,-1,1) eq "/" );
if ( $output_directory ne "." && -d $output_directory ) {
    print "Given output_directory does not exists, please check \n" if ($verbose);
    exit(1);
}

#global variables
my $prefix = "";
my @suffixlist = ( ".xml" );

#main function starts here
eval {
    # create object
    my $xml = new XML::Simple;

    foreach my $xml_file (@xml_files) {
        unless ( -e $xml_file ) {
            print "Given xml file '".$xml_file."' does not exist, please check\n" if ($verbose);
            next;
        }   

        $prefix = basename( $xml_file, @suffixlist );
        
        my $alias_file_name = $prefix.$alias_file_suffix;

        print "\nProcessing $xml_file \n\n" if ($verbose);

        # read XML file
        my $data = $xml->XMLin($xml_file);
        print "Alias:".Dumper( $data->{alias} ) if ( $verbose > 2 );
        print "Tests:".Dumper( $data->{chapter} ) if ( $verbose > 2 );

        # open alias file in write mode
        my $alias_file_handler;
        open $alias_file_handler , ">", "$output_directory/$alias_file_name" or die "Unable to open alias file : $!.";

        #write the alias into file    
        foreach my $alias_key ( keys $data->{alias} ) {
            if ( defined $data->{alias}->{$alias_key}->{value} ) {
                print $alias_file_handler "alias ".$alias_key."='".$data->{alias}->{$alias_key}->{value}."'\n";
            }
            else {
                print "Skipping alias '".$alias_key."' as value not defined in given xml file '".$xml_file."'. \n" if($verbose);
            }
        }

        close $alias_file_handler;

        print "\nWritten alias file to '".$output_directory."' directory using $xml_file file : Done\n" if ($verbose);

        my $script_template = ""; 
        #read the script template code written after __DATA__ token
        {
            local $/;
            $script_template = <DATA>;
            print $script_template if($verbose > 1 );
        }

        my $test_count          =   0;
        my $test_script_code    =   "";
        my $author              =   "Raghavender Kommidi";
        my $author_email        =   "rkommidi\@gmail.com";
        my $comment             =   "Sample test to check out sysunit.";
        my $test_script_name    =   "";
        my $component           =   "test";
        my $issues              =   "";
        my $owner               =   "rkommidi\@gmail.com";
        my $server_name         =   "";
        my $confirm             =   "";
        my $detached            =   "";
        my $nogo                =   "";
        my $precondition        =   "";
        my $confirm_text        =   "";
        my $delay               =   "";
        my $expected_result     =   "";
        my $exit_code           =   "";
        my $test_command        =   "";

        foreach my $chapter ( @{$data->{chapter}} ) {
            foreach my $test ( @{$chapter->{test}} ) {
                next unless(defined $test->{number});

                $test_script_name = $prefix."_".$test->{number}.".test";

                # open test script file in write mode
                open my $test_script_handler , ">", "$output_directory/$test_script_name" or die "Unable to open test script file : $!.";

                $test_script_code    = $script_template;
                
                $server_name        =   ( defined $test->{servername} )     ?  $test->{servername}      :   "";
                $confirm            =   ( defined $test->{confirm})         ?  $test->{confirm}         :   "";
                $detached           =   ( defined $test->{detached} )       ?  $test->{detached}        :   "";
                $nogo               =   ( defined $test->{nogo} )           ?  $test->{nogo}            :   "";
                $precondition       =   ( defined $test->{precondition} )   ?  $test->{precondition}    :   "";
                $confirm_text       =   ( defined $test->{confirmtext} )    ?  $test->{confirmtext}     :   "";
                $delay              =   ( defined $test->{delay} )          ?  $test->{delay}           :   "";
                $expected_result    =   ( defined $test->{expectedresult} ) ?  $test->{expectedresult}  :   "";
                $exit_code          =   ( defined $test->{exitcode} )       ?  $test->{exitcode}        :   "";
                $test_command       =   ( defined $test->{command} )        ?  $test->{command}         :   "";


                #replace tokens with actual values
                $test_script_code =~ s/__TEST_NAME__/$test_script_name/gxms;
                $test_script_code =~ s/__AUTHOR__/$author/gxms;
                $test_script_code =~ s/__AUTHOR_EMAIL__/$author_email/gxms;
                $test_script_code =~ s/__COMMENT__/$comment/gxms;
                $test_script_code =~ s/__COMPONENT__/$component/gxms;
                $test_script_code =~ s/__ISSUES__/$issues/gxms;
                $test_script_code =~ s/__OWNER__/$owner/gxms;
                $test_script_code =~ s/__SERVER_NAME__/$server_name/gxms;
                $test_script_code =~ s/__CONFIRM__/$confirm/gxms;
                $test_script_code =~ s/__DELAY__/$delay/gxms;
                $test_script_code =~ s/__DETACHED__/$detached/gxms;
                $test_script_code =~ s/__NOGO__/$nogo/gxms;
                $test_script_code =~ s/__PRECONDITION__/$precondition/gxms;
                $test_script_code =~ s/__CONFIRM_TEXT__/$confirm_text/gxms;
                $test_script_code =~ s/__EXPECTED_RESULT__/$expected_result/gxms;
                $test_script_code =~ s/__EXPECTED_EXIT_CODE__/$exit_code/gxms;
                $test_script_code =~ s/__TEST_COMMAND__/$test_command/gxms;

                print $test_script_handler $test_script_code;
                close $test_script_handler;

                ++$test_count;

                print "Written test script file".$test_script_name." Count:". $test_count ." \n" if($verbose > 1);
            }
        }
            
        print "\nWritten $test_count test scripts using $xml_file file : Done\n" if ($verbose);
    }
};

warn "Internal Error: $@" if $@;

__DATA__
#!/bin/ksh

echo "# METADATA"
echo "{"
echo "'name':'__TEST_NAME__',"
echo "'author':'__AUTHOR__',"
echo "'email':'__AUTHOR_EMAIL__',"
echo "'version':'\$Revision: 0.1 $/',"
echo "'comment':'__COMMENT__',"
echo "'component':'__COMPONENT__',"
echo "'issues':'__ISSUES__',"
echo "'owner':'__OWNER__',"
echo "}"
echo "# ENDMETADATA"


# set variables here
#SCRIPTHOME=/home/rkommidi/sysunit
TNAME="__TEST_NAME__"
SERVERNAME="__SERVER_NAME__"
CONFIRM=__CONFIRM__
DETACHED=__DETACHED__
NOGO=__NOGO__
PRECONDITION="__PRECONDITION__"
CONFIRMTEXT="__CONFIRM_TEXT__"
DELAY=__DELAY__
EXPECTEDRESULTS="__EXPECTED_RESULT__"
EXPECTEDEXITCODE=__EXPECTED_EXIT_CODE__
TESTCMD="__TEST_COMMAND__"

# Relax requirement that test must be run as root:
RUNAS=rkommidi

if [[ ${#RUNAS} = 0 ]]
then
    echo "This test can be run as admin1/anyone"
elif [[ ${#RUNAS} != 0 ]]
then
    echo "This test must be run as ${RUNAS}"
fi

echo "# RUN $TNAME"

if [[ ${#RUNAS} = 0 || `/usr/bin/whoami` = $RUNAS ]]
then
    ACTUALRESULTS=$($TESTCMD 2>&1) 
    SLEEP $DELAY 
    ACTUALEXITCODE=$?
    echo -e "Expected results were : \n ${EXPECTEDRESULTS}"
    echo -e "Actual results are : \n ${ACTUALRESULTS}"
    if  [[ $ACTUALEXITCODE == $EXPECTEDEXITCODE ]] && [[ ${#EXPECTEDRESULTS} ==  0 || $EXPECTEDRESULTS == $ACTUALRESULTS || $EXPECTEDRESULTS =~ $ACTUALRESULTS ]] 
    then
        echo "# PASS $TNAME"
    else
        echo "# FAIL $TNAME " 
    fi
elif [[ `/usr/bin/whoami` = root ]]
then
    IFUSEREXISTS=$(/bin/su $RUNAS -c  date 2>&1)
    USERERR=$?
    if [[ $USERERR != 0 ]] 
    then
        echo "$RUNAS user doesn't exist, so test was not executed"
        echo "# FAIL $TNAME "
    else
        ACTUALRESULTS=$(/bin/su $RUNAS -c "$TESTCMD" 2>&1)
        SLEEP $DELAY 
        ACTUALEXITCODE=$?
        echo -e "Expected results were : \n ${EXPECTEDRESULTS}"
        echo -e "Actual results are : \n ${ACTUALRESULTS}"
        if  [[ $ACTUALEXITCODE == $EXPECTEDEXITCODE ]] && [[ ${#EXPECTEDRESULTS} ==  0 || $EXPECTEDRESULTS == $ACTUALRESULTS || $EXPECTEDRESULTS =~ $ACTUALRESULTS ]]
        then
            echo "# PASS $TNAME"
        else
            echo "# FAIL $TNAME "
        fi
    fi
else
    echo "# ERROR Must run as $RUNAS"
    exit
fi

exit
