#!/usr/bin/perl
#----------------------------------------------------------------------------
# The contents of this file are subject to the "END USER LICENSE AGREEMENT
# FOR F5 Software Development Kit for iControl"; you may not use this file
# except in compliance with the License. The License is included in the
# iControl Software Development Kit.
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is iControl Code and related documentation
# distributed by F5.
#
# The Initial Developer of the Original Code is F5 Networks,
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2010
# F5 Networks, Inc. All Rights Reserved.  iControl (TM) is a registered
# trademark of F5 Networks, Inc.
#
# Alternatively, the contents of this file may be used under the terms
# of the GNU General Public License (the "GPL"), in which case the
# provisions of GPL are applicable instead of those above.  If you wish
# to allow use of your version of this file only under the terms of the
# GPL and not to allow others to use your version of this file under the
# License, indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by the GPL.
# If you do not delete the provisions above, a recipient may use your
# version of this file under either the License or the GPL.
#----------------------------------------------------------------------------
#use SOAP::Lite + trace => qw(method debug);

use SOAP::Lite;
use File::Basename;
use Math::BigInt;
use Data::Dumper;

 
#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------
my $sUID = "svcacctrelmgt";
my $sPWD = "R8bbitSt3w";
my $intExt = $ARGV[0];
my $sCmd = $ARGV[1];
my $sArg1 = $ARGV[2];
my $sArg2 = $ARGV[3];
my $sArg3 = $ARGV[4];

### Old BigIP server info 
#my $sHost = "10.80.9.10";
#$sHost = "10.80.9.16" if $intExt =~ /int/;

my $sHost;
my $env_num = $sArg1;
$env_num =~ s/[srwd|srwe|SRWD|SRWE]//g;
chomp($env_num);

if ( $env_num >= 76 ) {
    $sHost = "srwd00lba042-cl.stubcorp.dev";
    $sHost = "srwd00lba014.stubcorp.dev" if $intExt =~ /int/;
} else{
    $sHost = "10.80.139.242";
    $sHost = "10.80.139.232" if $intExt =~ /int/;
}

# TODO Test server
# $sHost = "srwd00lba041.stubcorp.dev";
# $sHost = "srwd00lba013.stubcorp.dev" if $intExt =~ /int/;

#============================================================================
sub usage()
#============================================================================
{
  print "Usage: LocalLBRule.pl [int|ext] [options] \n";
  print "  [options]\n";
  print "   list              - List all iRules\n";
  print "   backup dirname    - Backup all iRules to specified local directory\n";
  print "   load env filename - Load single iRule from specified filename to an evironment\n";
  print "   get iRulename     - Display specified iRule\n";
  print "   delete iRulename  - Delete specified iRule\n";
  print "   stats iRulename   - Get Statistics for specified iRule\n";            -
  exit;
}
 
if ( ($sHost eq "") or ($sUID eq "") or ($sPWD eq "") )
{
    usage();
}
 
#----------------------------------------------------------------------------
# Transport Information
#----------------------------------------------------------------------------
BEGIN {
sub SOAP::Transport::HTTP::Client::get_basic_credentials
{
    return "$sUID" => "$sPWD";
}
}
 
sub SOAP::Deserializer::typecast
{
    my ($self, $value, $name, $attrs, $children, $type) = @_;
    my $retval = undef;
    if ( "{urn:iControl}Common.StatisticType" eq $type ) { $retval = $value; }
    return $retval;
}
 
$LocalLBRule = SOAP::Lite
    -> uri('urn:iControl:LocalLB/Rule')
    -> readable(1)
    -> proxy("https://$sHost/iControl/iControlPortal.cgi");
 
#print Dumper $LocalLBRule;
#----------------------------------------------------------------------------
# Attempt to add auth headers to avoid dual-round trip
#----------------------------------------------------------------------------
eval { $LocalLBRule->transport->http_request->header
(
        'Authorization' =>
        'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };

#============================================================================
sub getiRuleDefinitions()
#============================================================================
{
  my($rulename) = (@_);
  if ( $rulename eq "" )
  {
    $soapResponse = $LocalLBRule->query_all_rules();
    &checkResponse($soapResponse);
    @RuleDefinitionList = @{$soapResponse->result};
    return @RuleDefinitionList;
  }
  else
  {
    $soapResponse = $LocalLBRule->query_rule(
      SOAP::Data->name(rule_names => [$rulename])
    );
    &checkResponse($soapResponse);
    @RuleDefinitionList = @{$soapResponse->result};
    $RuleDefinition = @RuleDefinitionList[0];
    return $RuleDefinition;
  }
}
   
#============================================================================
sub getiRuleList()
#============================================================================
{
  @RuleDefinitionList = &getiRuleDefinitions();
  my $i = 0;
  #print "-----------------\n";
  #print "iRule List\n";
  #print "-----------------\n";
  foreach $RuleDefinition (@RuleDefinitionList)
  {
    $rule_name = $RuleDefinition->{"rule_name"};
    $rule_definition = $RuleDefinition->{"rule_definition"};
    if ( ! ($rule_name =~ m/_sys/) )
    {
      print "$rule_name\n";
      #print "Details: $rule_definition\n";
      $i++;
    }
  }
}
 
#============================================================================
sub backupiRules()
#============================================================================
{
  my($dir) = (@_);
  my $localFile = "";
  my @RuleDefinitionList = &getiRuleDefinitions();
   
  unless(-d $dir)
  {
    mkdir $dir;
  }
   
  foreach $RuleDefinition (@RuleDefinitionList)
  {
    $rule_name = $RuleDefinition->{"rule_name"};
    $rule_definition = $RuleDefinition->{"rule_definition"};
    if ( ! ($rule_name =~ m/_sys/) )
    {
      $localFile = "${dir}/${rule_name}.tcl";
      print "Creating ${localFile}...\n";
      open (LOCAL_FILE, ">$localFile") or die("Can't open $localFile for output: $!");
      print LOCAL_FILE $rule_definition;
      close (LOCAL_FILE);
    }
  }
}
 
#============================================================================
sub loadiRule()
#============================================================================
{
  my($env, $file) = (@_);
  my $file_data;
  my $chunk_size = 64*1024;
  open(LOCAL_FILE, "<$file") or die("Can't open $localFile for input: $!");
  $bytes_read = read(LOCAL_FILE, $file_data, $chunk_size);
  close(LOCAL_FILE);
   
  $iRuleName = &basename($file);
  $iRuleName =~ s/.tcl$//g;
  $iRuleName =~ s/^/$env-/g;
   
  $iRuleDefinition = {
    rule_name => $iRuleName,
    rule_definition => $file_data
  };
   
  my $exists = &doesiRuleExist($iRuleName);
  if ( $exists )
  {
    # Modify existing iRule
    $soapResponse = $LocalLBRule->modify_rule(
      SOAP::Data->name(rules => [$iRuleDefinition])
    );
    &checkResponse($soapResponse);
    print "iRule $iRuleName successfully updated\n";
  }
  else
  {
    # Create new iRule
    $soapResponse = $LocalLBRule->create(
      SOAP::Data->name(rules => [$iRuleDefinition])
    );
    &checkResponse($soapResponse);
    print "iRule $iRuleName successfully created\n";
  }
}
 
#============================================================================
sub getiRule()
#============================================================================
{
  my($name) = (@_);
   
  $RuleDefinition = &getiRuleDefinitions($name);
  $rule_name = $RuleDefinition->{"rule_name"};
  $rule_definition = $RuleDefinition->{"rule_definition"};
   
  print "$rule_definition\n";
}
 
#============================================================================
sub build64()
#============================================================================
{
    ($UInt64) = (@_);
    $low = $UInt64->{"low"};
    $high = $UInt64->{"high"};
     
    # For some reason this doesn't work...
    #$value64 = Math::BigInt->new($high)->blsft(32)->bxor($low);
    $value64 = Math::BigInt->new(Math::BigInt->new($high)->blsft(32))->bxor($low);
    return $value64;
}
 
 
#============================================================================
sub getiRuleStats()
#============================================================================
{
  my($name) = (@_);
  $soapResponse = $LocalLBRule->get_statistics(
    SOAP::Data->name(rule_names => [$name])
  );
  &checkResponse($soapResponse);
   
  my $RuleStatistics = $soapResponse->result;
 
  my @statistics = @{$RuleStatistics->{"statistics"}};
  foreach $RuleStatisticEntry (@statistics)
  {
    $rule_name = $RuleStatisticEntry->{"rule_name"};
    $event_name = $RuleStatisticEntry->{"event_name"};
    $priority = $RuleStatisticEntry->{"priority"};
    @StatisticA = @{$RuleStatisticEntry->{"statistics"}};
    print "--------------------------------------\n";
    print "RULE '$rule_name' STATISTICS\n";
    print "-------------------- + ---------------\n";
    foreach $Statistic (@StatisticA)
    {
      $type = $Statistic->{"type"};
      $type =~ s/STATISTIC_RULE_//g;
      $value = &build64($Statistic->{"value"});
      printf "%20s | %s\n", $type, $value;
    }
    print "-------------------- + ---------------\n";
  }
}
 
#============================================================================
sub deleteiRule()
#============================================================================
{
  my($name) = (@_);
  $soapResponse = $LocalLBRule->delete_rule(
    SOAP::Data->name(rule_names => [$name])
  );
  &checkResponse($soapResponse);
  print "iRule '$name' successfully deleted.\n";
   
}
 
#============================================================================
sub doesiRuleExist()
#============================================================================
{
  my($name) = (@_);
  my $exists = 0;
   
  if ( ! $name eq "" )
  {
    my @RuleDefinitionList = &getiRuleDefinitions();
    foreach $RuleDefinition (@RuleDefinitionList)
    {
      $rule_name = $RuleDefinition->{"rule_name"};
      if ( $rule_name eq $name )
      {
	$exists = 1;
	break;
      }
    }
  }
  return $exists;
}
 
#============================================================================
sub checkResponse()
#============================================================================
{
    my ($soapResponse) = (@_);
    if ( $soapResponse->fault )
    {
	print $soapResponse->faultcode, " ", $soapResponse->faultstring, "\n";
	exit();
    }
}
 
     
 
#============================================================================
# Main application code
#============================================================================
print "PerlLocalLbRule.pl: sHost: $sHost\n";
print "PerlLocalLbRule.pl: sCmd:  $sCmd\n";
print "PerlLocalLbRule.pl: sArg1: $sArg1\n";
print "PerlLocalLbRule.pl: sArg2: $sArg2\n";

if ( $sCmd eq "")
{
  &usage;
}
elsif ( $sCmd eq "list" )
{
  &getiRuleList();
}
elsif ( $sCmd eq "backup" )
{
  if ( $sArg1 eq "" ) { &usage(); }
  &backupiRules($sArg1);
}
elsif ( $sCmd eq "load" )
{
  if ( $sArg1 eq ""  or $sArg2 eq "") { &usage(); }
  &loadiRule($sArg1, $sArg2);
}
elsif ( $sCmd eq "get" )
{
  if ( $sArg1 eq "" ) { &usage(); }
  &getiRule($sArg1);
}
elsif ( $sCmd eq "delete" )
{
  if ( $sArg1 eq "" ) { &usage(); }
  &deleteiRule($sArg1);
}
elsif ( $sCmd eq "stats" )
{
  if ( $sArg1 eq "" ) { &usage(); }
  &getiRuleStats($sArg1);
}
else
{
  &usage();
}
