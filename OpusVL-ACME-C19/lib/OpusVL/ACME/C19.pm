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
use List::Util qw(first any);

# Debug/Reporting modules
use Carp qw(cluck longmess shortmess);
use Data::Dumper;

# Version of this software
our $VERSION = '0.001';
my $debug = 0;

# Primary code block
sub new {
    my ($class,$set_debug) = @_;

    if ($set_debug) { $debug = 1 }

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
            symbol  =>  {
                'respiration_rate'          =>  ['≤8',,'9–11','12–20',,'21–24','≥25'],
                'spo2_scale_1'              =>  ['≤91','92–93','94–95','≥96',undef,undef,undef],
                'air_or_oxygen'             =>  [undef,'Oxygen',undef,'Air',undef,undef,undef],
                'systolic_blood_pressure'   =>  ['≤90','91–100','101–110','111–219',undef,undef,'≥220'],
                'pulse'                     =>  ['≤40',undef,'41–50','51–90','91–110','111–130','≥131'],
                'consciousness'             =>  [undef,undef,undef,'Alert',undef,undef,'CVPU'],
                'temperature'               =>  ['≤35.0',,'35.1–36.0','36.1–38.0','38.1–39.0','≥39.1',]
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
    return  sort { 
                $self->{news2}->{index}->{$a} <=> $self->{news2}->{index}->{$b} 
            } keys %{$self->{news2}->{index}};
}

sub news2_dump_row($self,$matrix_row) {
    return $self->{news2}->{matrix}->{$matrix_row};
}

sub news2_calculate_score($self,$scores = {}) {
    my %shallow_index = %{$self->{news2}->{index}};

    my $state           =   {
        'fault'     =>  0,
        'score'     =>  undef
    };
    my $journal         =   {};
    my $news2           =   {};
    my $skip        =   {};

    foreach my $score_key (keys %{$scores}) {
        delete $shallow_index{$score_key};
    }
    foreach my $missing_submission_key (keys %shallow_index) {
        push @{$journal->{$missing_submission_key}},
            "Not provided in request";
        _debug($journal->{$missing_submission_key}->[-1]);

        # Enable skip optimization
        $skip->{$missing_submission_key} = 1;

        # Mark a fault
        $state->{fault} = 1;
    }

    foreach my $score_index_key ($self->news2_index()) {
        # If we are missing the key, simply skip it
        if ($skip->{$score_index_key}) { next }

        # Various sizes and ptr's for ease
        my $input_value             =   $scores->{$score_index_key};
        my $validation_array_size   =   $#{ $self->{news2}->{matrix}->{$score_index_key} };
        my $validation_ptr          =   $self->{news2}->{matrix}->{$score_index_key};

        # Check a value was passed as all are mandatory
        if ($input_value)  {
            # Strip silly characters off either side of the input value
            ($input_value) = $input_value =~ m/^.*?([a-zA-Z0-9.]+).*?$/;
        }

        my $found_index;

        for (my $i = 0; $i <= $validation_array_size; $i++) {
            my $matrix_element_type = ref($validation_ptr->[0]);
            if ($matrix_element_type eq 'ARRAY')  {
                if (!$input_value) {
                    push @{$journal->{$score_index_key}},
                        "Invalid type passed as argument for $score_index_key (NULL)";
                    _debug($journal->{$score_index_key}->[-1]);
                    $state->{fault} = 1;
                    last;
                }
                elsif ($input_value !~ m/^\d+(\.\d+)?$/) {
                    push @{$journal->{$score_index_key}},
                        "Invalid type passed as argument for $score_index_key ($input_value)";
                    _debug($journal->{$score_index_key}->[-1]);
                    
                    $state->{fault} = 1;
                    last;
                }
                elsif (any { $_ == $input_value } @{$validation_ptr->[$i]}) {
                    $found_index = $i;
                    last;
                }
             }
             elsif ($matrix_element_type eq 'HASH') {
                if (!defined $input_value) {
                    push @{$journal->{$score_index_key}},
                        "Invalid type passed as argument for $score_index_key (NULL)";
                    _debug($journal->{$score_index_key}->[-1]);
                    $state->{fault} = 1;
                    last;
                }
                elsif ($validation_ptr->[$i]->{$input_value}) {
                    $found_index = $i;
                    last
                }
            }
        }

        if (defined $found_index) {
            $state->{score} += $self->{news2}->{scores}->[$found_index];
            $news2->{$score_index_key} = [
                $self->{news2}->{scores}->[$found_index],
                $self->{news2}->{symbol}->{$score_index_key}->[$found_index]
            ];
            push @{$journal->{$score_index_key}},
                "Score for $score_index_key, with value '$input_value': ".$self->{news2}->{scores}->[$found_index];
            _debug($journal->{$score_index_key}->[-1]);
        }
        elsif (defined $input_value) {
            push @{$journal->{$score_index_key}},
                "No score for: $score_index_key with value '$input_value'";
            _debug($journal->{$score_index_key}->[-1]);
        }
        elsif (!defined $found_index) {
            push @{$journal->{$score_index_key}},
                "No score for: $score_index_key with value 'NULL'";
            _debug($journal->{$score_index_key}->[-1]);
        }
        else {
            _debug("Should not be possible to reach here!");
            die;
        }
    }

    if ($state->{fault}) { $state->{score} = undef }

    my $object_final    =  {
        'state' =>  $state,
        'news2' =>  $news2,
        'log'   =>  $journal
    };

    _debug("object created: ".Dumper($object_final));

    return $object_final;
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

sub _debug($text) {
    if (!$debug) { return }
    say STDERR $text;
}

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Opus Vision Limited T/A OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
