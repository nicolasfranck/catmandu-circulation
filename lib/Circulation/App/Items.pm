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
    my($source,$fSYS) = split(':',$record);

    unless(is_string($source) && is_string($fSYS)){
      status 'not_found';
      return;  
    }  

    my $r;
    try{
      my $result = meercat()->search(query => "source:$source AND fSYS:$fSYS",limit => 1);
      my $xml = $result->first->{fXML};
      open my $fh,"<:utf8",\$xml or die($!);
      $r = Catmandu::Importer::MARC->new(type => "XML",file => $fh,fix => 'items')->first;
      close $fh;
    };

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
    $r->{l} = [];

    #request? Catmandu::Fix::items converteert 852c (met holdings) naar items! Je kan ze enkel onderscheiden op basis van bestaan van een barcode
    my @req_res;
    for my $lib(@{ $r->{libraries} }){
      my $l = request_reserve()->get($lib);
      push @req_res,$l if $l;
    }
    for my $item(@{ $r->{items} }){   
      my $index = first_index { $_->{library} eq $item->{library} } @req_res;

      #geen speciale regeling? Sorry, dan geen request knop, want bibliotheek moet akkoord gaan!
      unless($index >=0){
        $item->{action} = "none";
        next;
      }

      my $rs = $req_res[$index];

      #speciale regeling

      #enkel holdings
      if(!is_string($item->{barcode})){

        $item->{action} = $rs->{no_items_action};

      }elsif( $item->{item_process_status} =~ /$rs->{item_process_status}/ ){

        $item->{action} = $rs->{item_process_action};

      }elsif( $item->{item_status} =~ /$rs->{item_status}/ ){
  
        $item->{action} = $rs->{action};
  
      }else{

        $item->{action} = $rs->{default_action};

      }

    }    
    
    #retrieve library information from alephx
    for my $lib(@{$r->{libraries} || [] }){
      my $l = {
        library => $lib
      };
      {
        #library information
        my $bor_info = alephx()->bor_info(
          library => 'rug50',
          bor_id => $lib,
          loans => 'N',
          cash => 'N',
          hold => 'N'
        );
        if($bor_info->is_success){      
          $l->{bor_info} = {};
          $l->{bor_info}->{$_} = $bor_info->{$_} for keys %$bor_info;
        }
      }
      {
        #calendar of that library
        my $url = sprintf(Catmandu->config->{libraries}->{calendar}->{url},$lib);
        my $p = Catmandu->config->{libraries}->{calendar}->{params};
        $p = is_hash_ref($p) ? $p:{};
        $p->{locale} = Catmandu->config->{libraries}->{calendar}->{locale}->{ language_tag() } || Catmandu->config->{libraries}->{calendar}->{default_locale};
        $url .= "?".join '&',map { "$_=".uri_escape($p->{$_}) } keys %$p;
        my $res = ua()->get($url);
        my $calendar = [];
        if($res->is_success){
          $l->{calendar} = from_json($res->content);
        }
      }
      push @{ $r->{l} },$l;
    }

    $r->{libraries} = $r->{l};
    
    #cleanup
    delete $r->{$_} for qw(l library_items);

    return to_json($r,{ pretty => 1 });
    #template 'items',{ record => $r };
  };

  get '/available' => sub {
    my $params = params();
    my $record = $params->{record};

    my @items;
    my @errors;
    my $res = {
      record => $record,
      items => \@items,
      errors => \@errors
    };
  
    try{

      my($source,$fSYS) = split(':',$record || "");
      #opgelet: alephx gebruikt enkel 1ste 9 cijfers van doc_number. De rest wordt genegeerd.
      my $r = alephx()->item_data(base => $source,doc_number => $fSYS);  
      if($r->is_success){
        for my $item(@{ $r->items() }){
          $item->{$_} = $item->{$_}->[0] for keys %$item;
          push @items,$item;
        }
      }else{
        push @errors,$r->error;
      }    
    }catch{
      push @errors,$_;
    };
    content_type 'json';
    to_json($res,{ pretty => 1 });
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

=cut

};

sub ua {
  state $ua = LWP::UserAgent->new(cookie_jar => {});
}

1;
