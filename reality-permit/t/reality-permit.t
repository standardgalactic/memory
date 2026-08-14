use v5.38;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

require "$Bin/../reality-permit.pl";

my $first = issue_permit(1982, 1, 0);
my $again = issue_permit(1982, 1, 0);
is $first, $again, 'the bureaucracy is deterministic';
like $first, qr/Permit:\s+RP-000007BE-001/, 'permit number contains the seed';
like $first, qr/Finding:\s+(?:APPROVED|DENIED)/, 'a ruling is issued';
like issue_permit(1982, 1, 1), qr/Appeal status:/, 'appeals reach the larger committee';
is main('--count', '0'), 2, 'invalid count is rejected';

done_testing;
