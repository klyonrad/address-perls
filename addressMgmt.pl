use warnings;
#use strict;
#use Switch;
use feature 'say';
use feature 'unicode_strings';
use v5.16;
use Data::Dump 'dump';
use Data::Dumper;
use DBI;
use MongoDB;

use Address;

#sub databaseHandle{
	#my $dbfile		= "addresses.db";
#	my $dsn			= "dbi:SQLite:dbname=$dbfile";
#	my $user		= "";
#	my $password	= "";
#	my $dbh = DBI->connect($dsn, $user, $password, {
#	   PrintError       => 0,
#	   RaiseError       => 1,
#	   AutoCommit       => 1,
#	   FetchHashKeyName => 'NAME_lc',
#	});
#}


#my $dbh = databaseHandle;

#my $sql = <<'END_SQL';
#CREATE TABLE addresses (
 # id       INTEGER PRIMARY KEY,
 # fname    VARCHAR(100),
 # lname    VARCHAR(100),
 # email    VARCHAR(100) UNIQUE NOT NULL,
#  password VARCHAR(20)
#)
#END_SQL
 
#$dbh->do($sql);



my $client     = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database   = $client->get_database( 'new-perlWP' );
my $collection = $database->get_collection( 'addresses' );
my $mongodbcursor       = $collection->find();
my @dbElementsArray = $mongodbcursor->all;
#dump @arr;
#print $arr[0]->{'name'}."\n"
#dump $data; 

my $input = '';

#my @inputs;
my @entries;

foreach (@dbElementsArray) { #copy collection elements in-memory
	my $newEntry = Address->new();
	my %hashDeRef = %{$_};
	for my $property (keys %hashDeRef) {
		$newEntry->saveAttribute($property, $hashDeRef{$property} );
	}
	push @entries, $newEntry;
}

#fill array with test data:
#my $testEntryOne = Address->new();
#$testEntryOne->saveAttribute( 'email',  'test@example.com' );
#$testEntryOne->saveAttribute( 'number', 67890 );
#push @entries, $testEntryOne;

#my $testEntryTwo = Address->new();
#$testEntryTwo->saveAttribute( 'email',  'blub@bla.de' );
#$testEntryTwo->saveAttribute( 'number', 98765 );
#push @entries, $testEntryTwo;

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

sub saveToDB {
	my ( $entry ) = @_; #should be of type Address
	my %hashDeref = %{$entry->getAllHashRef()};
	if ($entry->getAttribute('_id') == -1 ) {
		say 'not in database yet!';
		$collection->insert( $entry->getAllHashRef() );
	}
	else {
		say 'object may be already in database';
	}	
}

sub newEntry {
    say "enter new entry:";

    my %newAttributes = attributesInput();
	my $newEntry = Address->new();
	
	for my $key (keys %newAttributes) {
		$newEntry->saveAttribute($key, $newAttributes{$key});
	}
    push @entries, $newEntry;
	saveToDB($newEntry);
    say "writing entry finished";

    return;
}

sub addAttributes {
    my ($searchQuery) = @_;
    my @searchResults = searchEntry( $searchQuery, 1 );
	my $indexForChange = $searchResults[0];
	#dump $indexForChange;
	
    #todo: check for existence of that entry. if not then end function
	my $entry = $entries[$indexForChange];
	my $objectID = $entry->getAttribute('_id');

    say 'enter new attributes. Will overwrite data!';
    my %attributes = attributesInput();


    my @attributeKeys = keys %attributes;
    for my $attribute (@attributeKeys) { #store change both in-memory and in database
        #$entries[$indexForChange]{$attribute} = $attributes{$attribute};
		$entry->saveAttribute($attribute, $attributes{$attribute});
		$collection->update(
			{"_id" => $objectID}, 
			{'$set' => {
				$attribute => $attributes{$attribute}
				}
		});
    }
    return;
}

sub deleteEntry {
    my ($searchQuery) = @_;
	my @searchResults = searchEntry( $searchQuery, 1 );
    my $index = $searchResults[0];
	
	my $entry = $entries[$index];
	my $objectID = $entry->getAttribute('_id');

    #todo: check for existence of that entry. if not then end function
	$collection->remove( {"_id" => $objectID } );
    splice @entries, $index, 1;
	
    say "entry removed";
    return;
}

sub showEntry {
    my ($searchQuery) = @_;
	my @searchResults = searchEntry( $searchQuery, 1 );
    my $index = $searchResults[0];

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

        if ( ( index $entry->getAttribute('email'), $searchQuery ) != -1 )
        {    #search in string function
            say "(debug) found one at $index"; #debugging info
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

#$dbh->disconnect;
