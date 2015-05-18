package address;

use Moose;

has 'attributes' => ( 
	is => 'ro',
	isa => 'HashRef', 
	default => sub { {} }
	#If you want to use a reference of any sort as the default value, you must return it from a subroutine.
	# https://metacpan.org/pod/Moose::Manual::Attributes#Default-and-builder-methods
);

sub saveAttribute {
	my ( $self, $key, $value) = @_;
	$self->attributes{$key} = $value;
}

sub getAttribute {
	my ( $self, $key) = @_;
	return $self->attributes{$key};
}

sub printAll {
	my $this = shift;
	#copied over from old main:
	my %entry = %{$this->attributes}; #dereference
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