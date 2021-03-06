package Stubhub::Util::SSH;

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

use Readonly;
use Net::SSH::Expect;
use Stubhub::Log::Util qw (
                            get_logger
                        );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &login_ssh
                      &close_ssh
                      &execute_ssh
                      &mute_execute_ssh
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;
our $logger = get_logger();

#
# Login to ssh
#
sub login_ssh {
    my ( $hostname, $username, $password ) = @_;

    local $ENV{PATH} = "$ENV{PATH}:/usr/bin";

    my $ssh = Net::SSH::Expect->new(
        host => "$hostname",
        user => "$username",
        password  => "$password",
        raw_pty => 1
    );

    my $prompt = "[Pp]assword";
    $ssh->run_ssh();
    $ssh->waitfor('qr/\(yes\/no\)\?$/',3);
    $ssh->send("yes\n");
    $ssh->waitfor('qr/$prompt:\s*$/',30);
    $ssh->send("$password\n");
    my $login_welcome = $ssh->read_all(20);

    if ( $login_welcome !~ m/hello/ and $login_welcome !~ /Last login/ ) {
        die "Login has failed. Login output was $login_welcome";
    }

    return $ssh;
}

#
# Close ssh connection
#
sub close_ssh {
    my ( $ssh ) = @_;
    $ssh->close();
}

#
# Execute command via ssh mutely
#
sub mute_execute_ssh {
    my ( $ssh, $command ) = @_;
    my $output = $ssh->exec($command);
    if ( defined $output ) {
        # Fix the line separator to only accept '\n'
        $output =~ s/\r//g;
        my @outputs = split('\n', $output);
        return @outputs;
    } else {
        return;
    }
}

#
# Execute command via ssh
#
sub execute_ssh {
    my ( $ssh, $command ) = @_;
    my @outputs = mute_execute_ssh( $ssh, $command );
    $logger->info( join "\n", @outputs );
}
