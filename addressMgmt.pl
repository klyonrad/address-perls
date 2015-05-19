use warnings;

#use Switch;
use feature 'say';
use feature 'unicode_strings';
use v5.16;
use Data::Dump 'dump';
use Data::Dumper;

use Address;

my $input = '';

#my @inputs;
my @entries;

#fill array with test data:
my $testEntryOne = Address->new();
$testEntryOne->saveAttribute( 'email',  'test@example.com' );
$testEntryOne->saveAttribute( 'number', 67890 );
push @entries, $testEntryOne;

my $testEntryTwo = Address->new();
$testEntryTwo->saveAttribute( 'email',  'blub@bla.de' );
$testEntryTwo->saveAttribute( 'number', 98765 );
push @entries, $testEntryTwo;

#my $testEntryThree = Address->new(
#	attributes => {
#		email => 'drei@drei.de',
#		number => 54698743
#	}
#);
#push @entries, {$testEntryThree};

#List::Utils pair/wise list ?

sub attributesInput {
    my %newAttributes;    #hash / map... whatever you call it
    my @lines;
    my $newLine = "";
    $newLine = <stdin>;
    chomp $newLine;
    while ( $newLine ne "." ) {

        #print ($newLine ne ".");
        ( my $key, my $value ) = split /:/, $newLine, 2;

 #my @newAttribute = split /:/, $newLine, 2;
 #$newAttributes{$newAttribute[0]} = $newAttribute[1]; #[0] is key, [1] is value
        $newAttributes{$key} = $value;

        #dump @newAttribute;
        push @lines, $newLine;

        $newLine = <stdin>;    #get new key-value
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
    my $indexForChange = searchEntry( $searchQuery, 1 );

    #todo: check for existence of that entry. if not then end function

    say 'enter new attributes. Will overwrite data!';
    my %attributes = attributesInput();

    my @newAttributes = keys %attributes;
    for my $attribute (@newAttributes) {
        $entries[$indexForChange]{$attribute} = $attributes{$attribute};
    }
    return;
}

sub deleteEntry {
    my ($searchQuery) = @_;
    my $index = searchEntry( $searchQuery, 1 );

    #todo: check for existence of that entry. if not then end function

    splice @entries, $index, 1;
    say "entry removed";
    return;
}

sub showEntry {
    my ($searchQuery) = @_;
    my $index = searchEntry( $searchQuery, 1 );

    #todo: check for existence of that entry. if not then end function

    say "the searched entry:";
    $entries[$index]->printAll();
    return;
}

sub showAllEntries {
    while ( my ( $index, $entry ) = each(@entries) ) {
        print "____ Entry " . $index . " ____\n";
        $entry->printAll();
        print "\n";
    }
    return;
}

sub showHelp {
    my @helpLines =
      ( #although looking weird in the source, two \t chars produce correct alignment
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
    my ( $searchQuery, $limit ) = @_;
    my @results;

    while ( my ( $index, $entry ) = each(@entries) ) {

        #dump $entry;

        if ( ( index $entry->getAttribute('email'), $searchQuery ) != -1 )
        {    #search in string function
            say "found one at $index";
            dump $entries[$index];
            push @results, $index;
            if ( $limit == 1 ) {
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
    my @args = split / /, $input, 2;    #split arguments into to parts
                                        #dump @args;
    return @args;
}

while (1) {
    my @arguments = menuPrompt();

    given ( $arguments[0] ) {           #experimental, "bug-free" since v5.16
        when ("e") { newEntry(); }
        when ("a") {
            if ( ( scalar @arguments ) < 2 ) {
                say 'search string is empty';
            }
            else {
                addAttributes( $arguments[1] );
            }
        }
        when ("d") {
            if ( ( scalar @arguments ) < 2 ) {
                say 'search string is empty';
            }
            else {
                #check for email address pattern
                deleteEntry( $arguments[1] );
            }
        }
        when ("l nn") {
            if ( ( scalar @arguments ) < 2 ) {
                say 'search string is empty';
            }
            else {
                # check for email address
                showEntry( $arguments[1] );
            }
        }
        when ("l") {
            if ( ( scalar @arguments ) < 2 ) {    #seach string is empty
                showAllEntries();
            }
            else {
                showEntry( $arguments[1] );
            }
        }
        when ("h") {
            showHelp();
        }
        when ("s") {
            if ( ( scalar @arguments ) < 2 ) {
                say 'search string is empty';
            }
            else {
                my @results = searchEntry( $arguments[1], 0 );
            }
        }
        when ("q") { exit }
        default    { say "wrong char"; }
    }
    print "\n";
}
