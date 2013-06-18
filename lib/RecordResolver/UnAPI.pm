package RecordResolver::UnAPI;
use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Moo;

use LWP::Simple;
use URI::Escape;
use XML::XPath;
use Data::Dumper;
use File::Slurp;

has baseurl => ( is => 'ro', required => 1,isa => sub{ check_string($_[0]); } );
has docdel_libraries => (is => 'ro',required => 1,isa => sub { check_array_ref($_[0]); });

our $DEBUG = 0;

sub resolve {
    my $self = shift;
    my $id   = shift;   

    return $self->resolve_card($id) if ($id =~ /^rug0(2|3)/);
    my $res = $self->resolve_default($id);    
  
    # Little Boopsie hack..if record can't be found it's probably a ser01
    # try again with rug01
    unless ($res) {
      $id =~ s/^\w+/ser01/;
      $res = $self->resolve_default($id);
    }

    return $res;
}

sub resolve_card {
    my $self = shift;
    my $id   = shift;   

    die "need a baseurl" unless $self->baseurl;
    
    my $url = sprintf "%s?id=%s&format=%s" 
                            , $self->baseurl
                            , uri_escape($id)
                            , 'marcxml';

    my $content = get($url);
    
    return undef unless $content;

    utf8::encode($content);
    
    my $xp = XML::XPath->new(xml => $content);
    
    my $obj = {};

    $obj->{card} = $xp->findvalue("/marc:record/marc:datafield[\@tag='CAT']/marc:subfield[\@code='f']")->value();
    
    my $library  = $xp->findvalue("/marc:record/marc:datafield[\@tag='852'][1]/marc:subfield[\@code='c']")->value();
   
    $obj->{location} = [ {
        bib     => $library ,
        shelf   => '<>' ,
        holding => undef,
        barcode => undef
    }];

    if ($id =~ /^(\w+):.*/) {
      $obj->{card_url} = "/meercat/x/stream?source=$1&id=" . $obj->{card}; 
    }
    
    return $obj;
}

sub resolve_default {
    my $self = shift;
    my $id   = shift;   

    die "need a baseurl" unless $self->baseurl;
    
    my $url = sprintf "%s?id=%s&format=%s" 
                            , $self->baseurl
                            , uri_escape($id)
                            , 'marcxml';

    my $content = get($url);
    
    return undef unless $content;

    #utf8::encode($content);
   
    my $xp = XML::XPath->new(xml => $content);
    
    my $obj = {};

    $obj->{title}       = $xp->findvalue('/marc:record/marc:datafield[@tag="245"]')->value();
    $obj->{author}      = $xp->findvalue('/marc:record/marc:datafield[@tag="100"]/marc:subfield[@code="a"]')->value();
    $obj->{publisher}   = $xp->findvalue('/marc:record/marc:datafield[@tag="260"]/marc:subfield[@code="b"]')->value();
    $obj->{dateIssued}  = $xp->findvalue('/marc:record/marc:datafield[@tag="260"]/marc:subfield[@code="c"]')->value();
    $obj->{description} = $xp->findvalue('/marc:record/marc:datafield[@tag="300"]')->value();
    $obj->{isbn}        = $xp->findvalue('/marc:record/marc:datafield[@tag="020"]')->value();
    $obj->{issn}        = $xp->findvalue('/marc:record/marc:datafield[@tag="022"]')->value();
    $obj->{series}      = $xp->findvalue('/marc:record/marc:datafield[@tag="490"]')->value();

    if ($id =~ /^ser01/) {
     my $nodeset = $xp->find('/marc:record//marc:datafield[@tag="852"]');
     foreach my $node ($nodeset->get_nodelist) {
       my $bib     = $xp->findvalue('./marc:subfield[@code="c"]',$node)->value();
       my $shelf   = $xp->findvalue('./marc:subfield[@code="j"]',$node)->value();
       my $holding = $xp->findvalue('./marc:subfield[@code="a"]',$node)->value();
       my $note    = $xp->findvalue('./marc:subfield[@code="z"]',$node)->value();
       $holding .= " $note" if $note;
       my $barcode = undef;
       push(@{$obj->{location}} , { 
            bib     => $bib , 
            shelf   => $shelf , 
            holding => $holding ,
            barcode => $barcode
            }) if (grep(/^$bib$/,@{$self->docdel_libraries}));
     }
    }
    else {
     my $nodeset = $xp->find('/marc:record//marc:datafield[@tag="Z30"]');
     foreach my $node ($nodeset->get_nodelist) {
       my $bib     = $xp->findvalue('./marc:subfield[@code="2"]',$node)->value();
       my $shelf   = $xp->findvalue('./marc:subfield[@code="3"]',$node)->value();
       my $holding = undef;
       my $barcode = $xp->findvalue('./marc:subfield[@code="5"]',$node)->value();
       my $note    = $xp->findvalue('./marc:subfield[@code="h"]',$node)->value();
       $shelf     .= " $note" if $note;
       push(@{$obj->{location}} , { 
               bib     => $bib , 
               shelf   => $shelf , 
               holding => $holding ,
               barcode => $barcode
               }) if (grep(/^$bib$/,@{$self->docdel_libraries}));
      }
    }       

    if ($DEBUG) {
	    write_file("/tmp/circulation_unapi_$$.txt",Dumper($obj));
    }    
	
    return $obj;
}


with 'RecordResolver';

1;
