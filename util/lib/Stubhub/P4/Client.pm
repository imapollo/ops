package Stubhub::P4::Client;

#
# Basic P4 client operations.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;
use REG::P4::Util qw( $P4OPTS delete_dynamic_client dynamic_client logged_in p4cmd );
use REG::Util qw( mktmpdir );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &check_out_perfoce_file
                        &clean_perforce_client
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

sub clean_die ( @ ) ;

#
# Create temp directory.
#
sub create_temp_directory {
    my ( $dir_prefix ) = @_;
    Readonly my $TMP_DIR => "/tmp";
    my $tmp_directory_token = "$TMP_DIR/$dir_prefix" . '${timestamp}';
    my $tmp_directory = mktmpdir ({
            try => $tmp_directory_token,
            perms => 0750,
        });
    return $tmp_directory;
}

#
# Check out a file from perforce.
#
sub check_out_perfoce_file {
    my ( $file_path ) = @_;

    $ENV{ PATH } = ':/usr/local/bin'
        . ':/opt/java/bin'
        . ':/opt/ant/bin';

    defined $ENV{ P4CONFIG } and $ENV{ P4CONFIG } = "";

    my $dynamic_perforce_client;
    Readonly my $PERFORCE_DEFAULT_SERVER_SRW => "perforce.stubcorp.dev";
    Readonly my $PERFORCE_DEFAULT_PORT_NUMBER => "1666";

    my $dynamic_perfoce_dir = create_temp_directory( "p4-dynamic-wc-" );

    not defined $dynamic_perfoce_dir and clean_die "Could not create root directory of dynamic perforce client;"
        , " first attempt tried to create '$dynamic_perfoce_dir'";

    $P4OPTS = "-u build -p $PERFORCE_DEFAULT_SERVER_SRW:$PERFORCE_DEFAULT_PORT_NUMBER";

    $dynamic_perforce_client = dynamic_client({
            depot   => 'depot',
            root    => $dynamic_perfoce_dir,
        });

    $P4OPTS = "$P4OPTS -c $dynamic_perforce_client->{ Client }";

    maybe_log_into_perforce();
    sync_perforce_files( "$file_path" );

    return ( $dynamic_perforce_client, $dynamic_perfoce_dir );
}

#
# Clean up the directory.
#
sub clean_up {
    my ( $temp_dir ) = @_;
    `/bin/rm -rf $temp_dir`;
}

#
# Clean up the perforce client.
#
sub clean_perforce_client {
    my ( $dynamic_perforce_client, $dynamic_perfoce_dir ) = @_;
    if ( defined $dynamic_perforce_client ) {
        delete_dynamic_client({
            client => $dynamic_perforce_client,
            p4opts => $P4OPTS,
        });
    }
    clean_up( $dynamic_perfoce_dir );
}

#
# Sync files from perforce depot.
#
sub sync_perforce_files {
    my ( $depot_file ) = @_;

    my $func = ( caller 0 )[ 3 ];
    my $ESP_TOKEN_TABLE_DEPOT_PATH="$depot_file";

    my $cmd = p4cmd( "sync $ESP_TOKEN_TABLE_DEPOT_PATH" );

    my @results = qx{ $cmd 2>&1 };
    my $status = $? >> 8;

    my $results = join( "", @results );

    $status != 0 and clean_die "cmd returned non-zero status; cmd => '$cmd';",
        " status => $status; output => '$results'";

    return;
}

#
# Login to perforce if necessary.
#
sub maybe_log_into_perforce {
    my $BATCHMODE = ( not -t );
    # log into perforce if not already logged in
    if ( not logged_in() ) {
        if ( $BATCHMODE ) {
            clean_die "not logged into perforce; using => $P4OPTS";
        } else {
            system p4cmd( 'login' );
        }
    }
    my $status = $? >> 8;
    $status != 0 and clean_die "could not log into perforce using => $P4OPTS";

    return;
}

