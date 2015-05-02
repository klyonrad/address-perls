use warnings;
#use Switch;
use feature 'say';
use feature 'unicode_strings';
use v5.16;
use Data::Dump 'dump';


my $input = '';
#my @inputs;
my @entries;

sub newEntry {
	my %newAttributes; #hash / map... whatever you call it
	my @lines;

	say "enter new entry:";

	my $newLine = "";
	$newLine = <stdin>;
	chomp $newLine;
	while ($newLine ne ".") {
		#print ($newLine ne ".");
		my @newAttribute = split /:/, $newLine, 2;
		$newAttributes{$newAttribute[0]} = $newAttribute[1]; #[0] is key, [1] is value
		#dump @newAttribute;
		push @lines, $newLine;

		$newLine = <stdin>; #get new key-value
		chomp $newLine;
	}
	say "writing entry finished";
	dump %newAttributes;
	#dump @lines;
}

sub addAttributes {

}

sub deleteEntry {

}

sub showEntry {

}

sub showAllEntries {

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

sub searchEntry {

}

sub menuPrompt {
	say "Hello. Please choose an option. h for help";
	my $input = <stdin>;
	print "\n";
	chomp $input;
	return $input;
}



while (1) {
	my $input = menuPrompt();

	# if ($input eq 'h') {
	# 	showHelp();
	# }

	given ($input) { #experimental, "bug-free" since v5.16
		when ("e") 	{newEntry(); }
		when ("a") 	{say "not implemented"}
		when ("d") 	{say "not implemented"}
		when ("l nn") {say "not implemented"}
		when ("l") 	{say "not implemented"}
		when ("h") 	{showHelp(); }
		when ("s") 	{say "not implemented"}
		when ("q")	{exit}
		default		{say "wrong char"}
}
	#chomp $input;
	#push @inputs, $input;
}

#dump @inputs;