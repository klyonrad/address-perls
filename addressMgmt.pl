use warnings;
#use Switch;
use feature 'say';
use feature 'unicode_strings';
use v5.16;
use Data::Dump 'dump';
use Data::Dumper;

my $input = '';
#my @inputs;
my @entries;

#fill array with test data:
push @entries, {
		#name => "test",
		number => 67890,
		email => 'test@example.com'
	};
my @testEntryTwoList;
push @testEntryTwoList, ('email', 'blub@bla.de');
push @testEntryTwoList, ("number", '98765');
my %testEntryTwo = @testEntryTwoList;
push @entries, {%testEntryTwo};

sub attributesInput {
	my %newAttributes; #hash / map... whatever you call it
	my @lines;
	my $newLine = "";
	$newLine = <stdin>;
	chomp $newLine;
	while ($newLine ne ".") {
		#print ($newLine ne ".");
		(my $key, my $value) = split /:/, $newLine, 2;
		#my @newAttribute = split /:/, $newLine, 2;
		#$newAttributes{$newAttribute[0]} = $newAttribute[1]; #[0] is key, [1] is value
		$newAttributes{$key} = $value;
		#dump @newAttribute;
		push @lines, $newLine;

		$newLine = <stdin>; #get new key-value
		chomp $newLine;
	}

	#dump %newAttributes;
	return %newAttributes;
}

sub newEntry {
	say "enter new entry:";

	my %newEntry = attributesInput();
	push @entries, {%newEntry};
	say "writing entry finished";
	
	#dump @lines;
	return;
}

sub addAttributes {
	my ($searchQuery) = @_;
	my $indexForChange = searchEntry($searchQuery, 1);
	#todo: check for existence. if not then end function

	say 'enter new attributes. Will overwrite data!';
	my %attributes = attributesInput();

	my @newAttributes = keys %attributes;
	for my $attribute (@newAttributes) {
		#print "The value of '$attribute' is $attributes{$attribute}\n";
		$entries[$indexForChange]{$attribute} = $attributes{$attribute};
	}
	return;
}

sub deleteEntry {

}

sub showEntry {

}

sub showAllEntries {
	#print Dumper (@entries);
	dump (@entries);
	return;
}

sub showHelp {
	my @helpLines = ( #although looking weird in the source, two \t chars produce correct alignment
		"e 		- Einlesen eines neuen Eintrags",
		"a nn 		- Attribute zu Eintrag hinzufügen oder überschreiben",
		"d nn 		- Eintrag nn löschen",
		"l nn 		- Eintrag nn formatiert anzeigen",
		"l 		- alle Einträge in einer Liste",
		"h 		- Hilfe",
		"s text		- Suche nach text in allen Einträgen und Output"
		);

	say foreach @helpLines;
	return;
}

#seach for text in email field, returns results array with index for entries
#second parameter limits the amount of results
#if you only want one entry! has no effect with numbers other than 1
sub searchEntry {
	my ($searchQuery, $limit) = @_;
	my @results;

	while (my ($index, $entry) = each (@entries) ) {
		#dump $entry;
		my %hash = %{$entry}; #dereferencing
		if ( (index $hash{'email'}, $searchQuery) != -1) {
			say "found one at $index";
			dump $entries[$index];
			push @results, $index;
			if ($limit == 1) {
				last;
			}
		}
	}
	return @results;

}

sub menuPrompt {
	say "Hello. Please choose an option. h for help";
	my $input = <stdin>;
	print "\n";
	chomp $input;
	my @args = split / /, $input, 2; #split arguments into to parts
	#dump @args;
	return @args;
}



while (1) {
	my @arguments = menuPrompt();

	# if ($input eq 'h') {
	# 	showHelp();
	# }

	given ($arguments[0]) { #experimental, "bug-free" since v5.16
		when ("e") 	{newEntry(); }
		when ("a") 	{
			if ( (scalar @arguments) < 2) {
				say 'search string is empty';
			} else {
				addAttributes($arguments[1]);
			}
		}
		when ("d") 	{
			say "not implemented";
		}
		when ("l nn") {say "not implemented"}
		when ("l") 	{ 
			showAllEntries(); 
		}
		when ("h") 	{showHelp(); }
		when ("s") 	{
			if ( (scalar @arguments) < 2) {
				say 'search string is empty';
			} else {
				my @results = searchEntry($arguments[1], 0);
			}
		}
		when ("q")	{exit}
		default		{say "wrong char";}
}
	#chomp $input;
	#push @inputs, $input;
}