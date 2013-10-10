package Stubhub::P4::Constants;

#
# P4 basic information.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/utl/devops/lib/perl';

use Readonly;

# BigIP templates subdir on P4 depot.
Readonly our $BIGIP_TEMPLATE_SUBDIR => 'templates/fsroot/etc/stubhub/f5';
# BigIP virtual server templates subdir on P4 depot.
Readonly our $BIGIP_VS_SUBDIR => 'virtuals';
# BigIP pool templates subdir on P4 depot.
Readonly our $BIGIP_POOL_SUBDIR => 'pools';
# BigIP irule templates subdir on P4 depot.
Readonly our $BIGIP_IRULE_SUBDIR => 'irules';

1;
