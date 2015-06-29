package myApp;
use Dancer2;

our $VERSION = '0.1';

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
use utf8;

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

sub changePropertyInDB {
	my ( $entry, $key, $value ) = @_; #Type Address, keyname as string, value
	my $objectID = $entry->getAttribute('_id');
	
    #store change both in-memory and in database
    $entry->saveAttribute($key, $value);
    $collection->update(
 			{"_id" => $objectID}, 
 			{'$set' => {
 				$key => $value
 				}
 		});
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

sub deleteEntryWithIndex {
	my ($index) = @_;
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

## SETTINGS ##
set 'template'     => 'template_toolkit';
#set 'layout'       => 'main';
set 'layout'       => 'bootstrap';


## CONTENT ##
my $text = 'Diese Perl Dancer WebApp ist ein Beispiel für das nutzen des Template Moduls von Dancer. Plain-Text ist gut, aber besser ist es doch, wenn der Inhalt formatiert ist.';
my $part2 = '<p>Toll ist auch, dass fertige Arrays übergeben und verarbeitet werden können:';
my @content = ();
#@content = ('Bananen','Äpfel','Birnen','Erdbeeren');
@content = @entries;

## HOOK ##
hook before => sub {
	
};

hook before_template => sub {
    my $tokens = shift;
    $tokens->{'css_url'} = request->base . 'css/navbar.css';
    $tokens->{'bootstrap_css_url'} = request->base . 'css/bootstrap.min.css';
    $tokens->{'bootstrap_js_url'} = request->base . 'javascripts/bootstrap.min.js';
    $tokens->{'site_name'} = 'Perl Address Management';
    $tokens->{'title'} = $tokens->{'page_name'}.' | '.$tokens->{'site_name'};
};

## ROUTES ##
get '/' => sub {
    template 'list.tt', {
      'page_name' => 'List',
      'headline'  => 'All the entries in our address database',
      'text'      => $text,
	  'entries'   => \@entries
    };
};

get '/new' => sub {
    template 'new.tt', {
      'page_name' => 'New Entry',
      'headline'  => 'Enter a new entry in the form',
      'text'      => $text.$part2
    };
};

post '/new' => sub {	
	my $newEntry = Address->new();
	
	$newEntry->saveAttribute('email', param('email'));
	$newEntry->saveAttribute('number', param('number'));
		
    push @entries, $newEntry;
	saveToDB($newEntry);
	
	say 'saved entry:';
	$newEntry->printAll();
	
	redirect '/';
};

get 'edit/:id' => sub {
	
    #todo: check for existence of that entry. if not then end function
	my $entry = $entries[param('id')];
	my $objectID = $entry->getAttribute('_id');
	
    template 'edit.tt', {
      'page_name' => 'Edit Entry',
      'headline'  => 'Edit the entry in the form',
      'text'      => $text.$part2,
	  'entry'	  => $entry
    };
};

post 'edit/:id' => sub {
	say "changing entry for entry: " .param('id');
	
    #todo: check for existence of that entry. if not then end function
	my $entry = $entries[param('id')];
	$entry->printAll();
	changePropertyInDB($entry, 'email', param('email'));
	changePropertyInDB($entry, 'number', param('number'));
	redirect '/';
};

any '/delete/:id' => sub {
	deleteEntryWithIndex(param('id'));
	redirect '/';
};

#let's dance
dance;
true;
