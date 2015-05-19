package Address;

use Moose;

has 'attributes' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            email  => 'default@email.com',
            number => '555-NASE'
        };
    }

#If you want to use a reference of any sort as the default value, you must return it from a subroutine.
# https://metacpan.org/pod/Moose::Manual::Attributes#Default-and-builder-methods
);

sub saveAttribute {
	my $self = shift;
	my ($key, $value) = @_;
	
	#print "$key\n";
	#print "$value\n";
	
	my %entry = %{$self->attributes() };
	#$self->attributes{$key}  ($value);
	$entry{$key} = $value;
	$self->attributes( \%entry);
}

sub getAttribute { #returns -1 if key is not found
	my $self = shift;
	my ($key) = @_;
	
	my %entry = %{$self->attributes() };
	
	if ( exists ($entry{$key}) ) {
		return ($entry{$key} );
	} else {
		return -1;
	}
}

sub printAll {
	my $self = shift;
	#copied over from old main:
	my %entry = %{$self->attributes() }; #dereference
	my @attributes = keys %entry;
	for my $attribute ( keys %entry ) {
		print "The value of '$attribute' is $entry{$attribute}\n";
	}
	
	
	#from http://stackoverflow.com/a/21605117/1796645
	#foreach my $attr ($object->meta->get_all_attributes) {
	#  my $name = $attr->name;

	#  next unless $attr->has_value($object);

	  # Or, perhaps get_value(), depending on your requirements.
	#  say $attr->get_raw_value($object);
	#}
}

return 1;