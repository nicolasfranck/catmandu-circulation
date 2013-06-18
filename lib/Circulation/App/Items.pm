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
use LWP::UserAgent;
use URI::Escape qw(uri_escape);

prefix '/items' => sub {

  get '/' => sub {
    my $params = params();

    my $record = $params->{record} || "";
    my $library = $params->{library} || "";  

    #aleph record
    unless(is_string($record)){
      status 'not_found';
      return;  
    }  

    my $r = records()->get($record);

    #no such record
    unless(is_hash_ref($r)){
      status 'not_found';
      return;
    }

    #when filtering on 'library', then check if record is in this library
    if($library){
      my $index_library = first_index { $_ eq $library} @{ $r->{libraries} || [] };
      unless($index_library >= 0){
        status 'not_found';
        return;
      }
      #filter 'libraries'
      $r->{libraries} = [$library];
      #filter items
        $r->{items} = [
          grep {
            $_->{library} eq $library;
        }@{ $r->{items} }
      ];
    }
    
    $r->{record} = $record;

    my @libraries;
    #haal bibliotheekgegevens en openingsuren op
    for my $lib(@{$r->{libraries} || [] }){
      my $l;

      my $url = sprintf(Catmandu->config->{library}->{url},$lib);
      my $p = Catmandu->config->{library}->{params};
      $p = is_hash_ref($p) ? $p:{};
      $p->{locale} = Catmandu->config->{library}->{locale}->{ language_tag() } || Catmandu->config->{library}->{default_locale};
      $url .= "?".join '&',map { "$_=".uri_escape($p->{$_}) } keys %$p;
      my $res = ua()->get($url);
      
      if($res->is_success){
        $l = from_json($res->content);
      }

      push @libraries,$l if $l;

    }

    $r->{libraries} = \@libraries;

    template 'items',{ record => $r };
  };

  get '/available' => sub {
    my $res = availability_resolver()->resolve(params()->{record});
    content_type 'json';
    to_json($res);
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

sub ua {
  state $ua = LWP::UserAgent->new(cookie_jar => {});
}

1;
