#!c:/strawberry/perl/bin/perl.exe

use 5.10.1;
use strict;
use warnings;
use Data::Dumper;

my @missings;
my $fields_array = [ qw(SUPPLIER DEPT CLASS MULTIPLE) ];
my $data_array = [ ('EZS01', 'Pers.Euro', '', 'X') ];

# create my field / data hash ...
my $data = create_data_hash($fields_array, $data_array);

# define data validation structures ...
my $dv;
$dv->{SUPPLIER} = [ qw(EZS01 ABCD TTRD ESWE) ];
$dv->{DEPT}     = [ ('Pers. Euro') ];

# define my validation profile ...
my $profile = {
	required => [qw( SUPPLIER
                     DEPT
                     CLASS )
	],
	constraints => {
		SUPPLIER => [ Test_Validation::value_in( $dv->{SUPPLIER} ), ],
		DEPT => Test_Validation::value_in( $dv->{DEPT} ),
		MULTIPLE => [ Test_Validation::value_is_number(), Test_Validation::value_between(1, 4), ],
	}	
};

# execute the validation ...
my $results = Test_Validation->check($profile, $data);
print "The dv results are : \n";
print Dumper($results);
exit;

sub create_data_hash {
	my $fieldsarray  = shift;
	my $dataarray = shift;

	my $pos = 0;
	foreach ( @{$fieldsarray} ) {
		splice(@{$dataarray}, $pos, 0, $_);
		$pos += 2;
	}
	my %data_hash = @{$dataarray};	
	return \%data_hash;
}

#######################

package Test_Validation;
use Data::Dumper;

#-------------------------------------------------------------------------------
sub check {
	my ($self, $profile, $data) = @_;
	my $results;
	
	# check required fields ...
	my @required;
	foreach ( @{$profile->{required}} ) {
		unless ( $data->{$_} ) { push(@required, $_); }
	}
	$results->{required} = \@required;
	
	# process constraints ...
	my @constraints;
	foreach ( keys %{$profile->{constraints}} ) {
		if ( ref($profile->{constraints}->{$_}) eq "ARRAY" ) {
			my $counter = 0;	
			my $length = $#{$profile->{constraints}->{$_}};
			while ( $counter <= $length ) {
				if ( my $constraint = $profile->{constraints}->{$_}->[$counter]->($data->{$_}) ) {
					push(@constraints, [$_, $constraint]);
					last;
				}
				$counter++;
			}		
		}	
		else {
			if ( my $constraint = $profile->{constraints}->{$_}->( $data->{$_} ) ) { 
				push(@constraints, [$_, $constraint]); 
			}
		}		
	}
	$results->{constraints} = \@constraints;
	
	return $results;	
}

#-------------------------------------------------------------------------------
sub value_in {
	my ($array) = @_;
	if (not (defined $array)) {
		print "a data array (ref) is required\n\n";
	}
	return sub {
		my ($value) = @_;
		my $matched_value  = grep { uc($_) eq uc($value) } @{$array};
		if ( $matched_value ) {  
			return 0;
		}
		else {
			return 'Invalid value';
		}
	}	
}

#-------------------------------------------------------------------------------
sub value_between {
	my ($min, $max) = @_;
	if (not (defined $min and defined $max)) {
		print "max and min values are required\n\n";
	}
	return sub {
		my ($value) = @_;
		print "passed value : $value\n";
		if ( ( $value > $max ) || ( $value < $min) ) {
			return 'Value outside range' 
		}
		else {
			return 0;
		}
	}
}

#-------------------------------------------------------------------------------
sub value_is_number {
	return sub {
		my ($number) = @_;
		if ( $number =~ /^-?\d+\.?\d*$/ ) {  
			return 0;
		}
		else {
			return 'Not a Number';
		}
	}    
}

1;