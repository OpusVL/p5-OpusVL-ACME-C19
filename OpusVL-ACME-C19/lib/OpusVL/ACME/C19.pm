package OpusVL::ACME::C19;

=head1 NAME

OpusVL::ACME::C19 - Module abstract placeholder text

=head1 SYNOPSIS

=for comment Brief examples of using the module.

=head1 DESCRIPTION

=for comment The module's description.

=cut

# Internal perl
use v5.30.0;

# Internal perl modules (core)
use strict;
use warnings;

# Internal perl modules (core,recommended)
use utf8;
use experimental qw(signatures);

# Debug/Reporting modules
use Carp qw(cluck longmess shortmess);
use Data::Dumper;

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub new {
    my ($class) = @_;

    my $self = bless {
        news2   =>  {
            matrix  =>  {
                'respiration_rate'          =>  _generate_matrix_respiration_rate(),
                'spo2_scale_1'              =>  _generate_matrix_spo2_scale_1(),
                'air_or_oxygen'             =>  _generate_matrix_air_or_oxygen(),
                'systolic_blood_pressure'   =>  _generate_matrix_systolic_blood_pressure(),
                'pulse'                     =>  _generate_matrix_pulse(),
                'consciousness'             =>  _generate_matrix_consciousness(),
                'temperature'               =>  _generate_matrix_temperature()
            },
            index   =>  {
                respiration_rate            =>  1,
                spo2_scale_1                =>  2,
                air_or_oxygen               =>  4,
                systolic_blood_pressure     =>  5,
                pulse                       =>  6,
                consciousness               =>  7,
                temperature                 =>  8
            },
            scores  =>  [3,2,1,0,1,2,3],
        }
    }, $class;

    return $self;
}

sub news2_index($self) {
    return sort { $self->{news2}->{index}->{$a} <=> $self->{news2}->{index}->{$b} } keys %{$self->{news2}->{index}};
}

sub calculate_score($self,$scores = {}) {
    my %shallow_index = %{$self->{news2}->{index}};
    foreach my $score_key (keys %{$scores}) {
        delete $shallow_index{$score_key};
    }
    if (keys %shallow_index != 0) {
        my $display_keys = join(', ',keys %shallow_index);
        say STDERR "The following keys was missing in the score request: $display_keys";
        die;
    }
}

sub _generate_range($start,$end,$dp = 0,$step = 1) {
    my @range;

    my $dpmask      =   '%.0'.$dp.'f';
    my $cast        =   sub($input) { return sprintf($dpmask,$input) };
    my $active      =   $start+0;

    while ($active <= $end) {
        push(@range,$cast->($active));
        $active += $step;
    }

    return @range;
}

sub _generate_matrix_respiration_rate {
    return [
        [_generate_range(0,8,0,1)],
        [],
        [_generate_range(9,11,0,1)],
        [_generate_range(12,20,0,1)],
        [],
        [_generate_range(21,24,0,1)],
        [_generate_range(25,500,0,1)]
    ];
}

sub _generate_matrix_spo2_scale_1 {
    return [
        [_generate_range(0,91,0,1)],
        [_generate_range(92,93,0,1)],
        [_generate_range(94,95,0,1)],
        [_generate_range(96,500,0,1)],
        [],
        [],
        []
    ];
}

sub _generate_matrix_air_or_oxygen {
    return [
        {},
        {'Oxygen'=>1},
        {},
        {'Air'=>1},
        {},
        {},
        {}
    ];
}

sub _generate_matrix_systolic_blood_pressure {
    return [
        [_generate_range(0,90,0,1)],
        [_generate_range(91,100,0,1)],
        [_generate_range(101,110,0,1)],
        [_generate_range(111,219,0,1)],
        [],
        [],
        [_generate_range(220,500,0,1)],
    ];
}

sub _generate_matrix_pulse {
    return [
        [_generate_range(0,40,0,1)],
        [],
        [_generate_range(41,50,0,1)],
        [_generate_range(51,90,0,1)],
        [_generate_range(91,110,0,1)],
        [_generate_range(111,130,0,1)],
        [_generate_range(131,500,0,1)],
    ];
}

sub _generate_matrix_consciousness {
    return [
        {},
        {},
        {},
        {'Alert'=>1},
        {},
        {},
        {'CVPU'=>1}
    ];
}

sub _generate_matrix_temperature {
    return [
        [_generate_range(0,35,0,1)],
        [],
        [_generate_range(35.1,36.0,1,0.1)],
        [_generate_range(36.1,38.0,1,0.1)],
        [_generate_range(38.1,39.0,1,0.1)],
        [_generate_range(39.1,500,1,0.1)],
        []
    ];
}

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Opus Vision Limited T/A OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
