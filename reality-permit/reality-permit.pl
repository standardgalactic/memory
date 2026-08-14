#!/usr/bin/env perl
use v5.38;
use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromArray);

our $VERSION = '0.1.0';

my @ADJECTIVES = qw(fungal recursive velvet municipal haunted reversible damp ceremonial);
my @NOUNS = ('moon', 'archive', 'cauliflower', 'timeline', 'trousers', 'oracle', 'puddle', 'committee');
my @OFFENCES = (
    'excessive causality in a residential zone',
    'operating a moon without a visible serial number',
    'failure to declare three ornamental dimensions',
    'smuggling nostalgia across a thermodynamic boundary',
    'impersonating a Tuesday for financial advantage',
    'maintaining an unlicensed prophecy in a damp container',
);
my @REMEDIES = (
    'paint every paradox a less alarming color',
    'return one kilogram of gravity to the front desk',
    'appoint a qualified mollusc as temporal guarantor',
    'keep all infinities folded when not in use',
    'install handrails along the fourth dimension',
    'submit Form ∞-B in triplicate before yesterday',
);

sub rng($seed) {
    my $state = $seed & 0x7fffffff;
    return sub {
        $state = (1103515245 * $state + 12345) & 0x7fffffff;
        return $state;
    };
}

sub pick($random, $items) {
    return $items->[ $random->() % @$items ];
}

sub seal($status) {
    my $word = $status eq 'APPROVED' ? 'ONTOLOGICALLY VALID' : 'REALITY DEFERRED';
    return join "\n",
        '+----------------------------------+',
        "|      $word" . (' ' x (28 - length($word))) . '|',
        '|  MINISTRY OF POSSIBLE AFFAIRS    |',
        '+----------------------------------+';
}

sub issue_permit($seed, $number, $appeal = 0) {
    my $random = rng($seed + $number * 7919 + $appeal * 104729);
    my $applicant = ucfirst(pick($random, \@ADJECTIVES)) . ' ' . pick($random, \@NOUNS);
    my $offence = pick($random, \@OFFENCES);
    my $remedy = pick($random, \@REMEDIES);
    my $coherence = 20 + $random->() % 81;
    my $majesty = 20 + $random->() % 81;
    my $paperwork = $random->() % 101;
    my $score = int(($coherence + $majesty + $paperwork) / 3) + ($appeal ? 7 : 0);
    my $status = $score >= 55 ? 'APPROVED' : 'DENIED';
    my $permit = sprintf 'RP-%08X-%03d', $seed & 0xffffffff, $number;

    return join "\n",
        seal($status),
        "Permit:         $permit",
        "Applicant:      $applicant",
        "Finding:        $status",
        "Coherence:      $coherence%",
        "Majesty:        $majesty%",
        "Paperwork:      $paperwork%",
        "Allegation:     $offence.",
        "Required act:   Please $remedy.",
        ($appeal ? "Appeal status: Considered by a larger committee wearing the same hats." : ()),
        '';
}

sub usage($fh = *STDOUT) {
    say {$fh} <<'HELP';
reality-permit — determine whether proposed universes may legally exist

Usage:
  reality-permit.pl [--seed NUMBER] [--count NUMBER] [--appeal]
  reality-permit.pl --version

Examples:
  ./reality-permit.pl --seed 1982
  ./reality-permit.pl --seed 1982 --count 7 --appeal
HELP
}

sub main(@args) {
    my ($seed, $count, $appeal, $help, $version) = (time, 1, 0, 0, 0);
    GetOptionsFromArray(
        \@args,
        'seed=i'  => \$seed,
        'count=i' => \$count,
        'appeal!' => \$appeal,
        'help|h'  => \$help,
        'version' => \$version,
    ) or return 2;

    if ($help) { usage(); return 0 }
    if ($version) { say $VERSION; return 0 }
    if (@args) { warn "Unexpected argument: $args[0]\n"; return 2 }
    if ($count < 1 || $count > 100) { warn "--count must be between 1 and 100\n"; return 2 }

    say 'MINISTRY OF POSSIBLE AFFAIRS';
    say 'Office of Counterfactual Zoning and Moon Registration';
    say "Seed docket: $seed\n";
    print issue_permit($seed, $_, $appeal) for 1 .. $count;
    return 0;
}

exit main(@ARGV) unless caller;
1;
