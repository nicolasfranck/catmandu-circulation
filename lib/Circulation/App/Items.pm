package Circulation::App::Request;
our $VERSION = '1.0';
use Catmandu::Sane;
use Catmandu;
use Dancer qw(:syntax);
use Dancer::Plugin::Lexicon;
use Circulation qw(:all);
use Catmandu::Util qw(:is :array require_package);
use List::MoreUtils qw(first_index);
use Try::Tiny;
use Catmandu::Importer::MARC;
use Time::HiRes;
use Clone qw(clone);
use URI::Escape qw(uri_escape);

prefix '/items' => sub {

  get '/' => sub {
    my $params = params();

    my $record = $params->{record} || "";
    my $library = $params->{library} || "";  
    my $faculty = $params->{faculty} || "";

    #aleph record
    unless(is_string($record)){
      status 'not_found';
      return;  
    }  

    my $r = meercat()->get($record);

    #no such record
    unless(defined($r)){
      status 'not_found';
      return;
    }

    $r = Catmandu->fixer('items')->fix($r);

    #when filtering on 'library', then check if record is in this library
    if($library){
      my $index_library = first_index { $_ eq $library} @{ $r->{library} || [] };
      unless($index_library >= 0){
        status 'not_found';
        return;
      }
      #filter items op 'library'
        $r->{items} = [
          grep {
            $_->{library} eq $library;
        }@{ $r->{items} }
      ];
    }

    #when filtering on 'faculty', then check if record is in this faculty
    if($faculty){
      my $index_faculty = first_index { $_ eq $faculty } @{ $r->{faculty} || [] };
      unless($index_faculty >= 0){
        status 'not_found';
        return;
      }
      #filter items op 'faculty'
        $r->{items} = [
          grep {
            $_->{faculty} eq $faculty;
        }@{ $r->{items} }
      ];
    }

    $r->{record} = $record;

    #my @libraries;
    #haal bibliotheekgegevens en openingsuren op
    my $o = clone(openingsuren_options());     
    $o->{locale} = config->{locale}->{ language_tag() } || config->{library}->{default_locale};
    $o->{library} = { map { $_->{library} => 1; } @{ $r->{items} || [] }  };
    $o->{library} = [keys %{ $o->{library} }];
    $r->{libraries} = openingsuren()->libraries($o);

    #return to_json($r,{ pretty => 1 });
    template 'items',{ record => $r };
  };

  get '/available' => sub {
    content_type 'json';
    to_json(availability_resolver()->resolve(params->{record}));
  };

=head1 SYNOPSIS

  aanpak request knop

  1.  check 'library' in item (Z30-item-status) en zoek record op in 'request_reserve'
  2.  zijn er 'items' bekend?
      ja: ga verder naar 3
      nee: doe wat in 'NoItemAction' staat
        => tijdschriften hebben geen items, maar wel holdings. Per bibliotheek wordt beslist of ze tijdschriften uitlenen.
  3.  ProcessStatus =~ <regex> 

        ProcessStatus == Z30-p

        is geldig 

          process status heeft voorrang op item-status, want is tijdelijk regeling (vb.deze week mag boek X niet worden uitgeleend)
          Dit controleer je dus altijd eerst!

          Kijk dan naar ProcessAction
        
        is niet geldig: ga naar 4
      
  4.  ItemStatus =~ <regex>
    
        item-status == Z30-f
  
        is geldig:
          doe wat in Action staat
        is niet geldig:
          doe wat in DefaultAction staat
        

  => indien geen record in request_reserve, dan geldt de regeling van het item zelf
  => deze informatie wijzigt héél zelden, en wordt daarom opgenomen in Catmandu::Fix::request_reserve,
     en wordt uitgevoerd tijdens import

=cut

};

sub openingsuren {
  state $o = require_package(config->{openingsuren}->{package})->new(config->{openingsuren}->{options});
}
sub openingsuren_options {
  state $o = config->{openingsuren}->{options};
}

1;
