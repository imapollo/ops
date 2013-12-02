package Stubhub::Log::Util;

#
# To use Log::Log4perl.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;
use Log::Log4perl;
use Log::Log4perl::Level;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &init
                        &get_logger
                        &get_logger_with_loglevel
                        &add_syslog_appender
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Initiate the Log4perl settings.
#
sub init {
    my $conf = q (
        log4perl.category.DevOps.Logger = INFO, Screen
        log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
        log4perl.appender.Screen.stderr = 0
        log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
        log4perl.appender.Screen.layout.ConversionPattern = %d %C [%p] %m%n
    );

    Log::Log4perl->init( \$conf );
}

#
# Add syslog logger appender.
#
sub add_syslog_appender {
    my ( $logger, $ident, $envid ) = @_;

    my $layout;
    if ( $envid eq "" ) {
        $layout = Log::Log4perl::Layout::PatternLayout->new( "%C [%p] %m%n" );
    } else {
        $layout = Log::Log4perl::Layout::PatternLayout->new( "[$envid] %C [%p] %m%n" );
    }

    my $syslog_appender = Log::Log4perl::Appender->new(
        "Log::Dispatch::Syslog",
        min_level => 'info',
        ident     => $ident,
        facility  => 'user',
        socket    => {
            type => 'udp',
            host => 'srwd00dvo002.stubcorp.dev',
            port => 514,
        },
    );
    $syslog_appender->layout( $layout );
    $logger->add_appender( $syslog_appender );
}


#
# Get the Logger instance and set log level.
#
sub get_logger_with_loglevel {
    my ( $show_verbose ) = @_;

    my $logger = Log::Log4perl->get_logger("DevOps::Logger");

    if ( $show_verbose ) {
        $logger->level( $DEBUG );
    } else {
        $logger->level( $INFO );
    }

    return $logger;
}

#
# Get the Logger instance.
#
sub get_logger {
    my $logger = Log::Log4perl->get_logger("DevOps::Logger");

    return $logger;
}
