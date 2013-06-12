package Catmandu::Fix::items;
use Catmandu::Sane;
use Catmandu;
use Moo;
use Catmandu::Util qw(:is :check);
use URI::Escape qw(uri_escape);

around BUILDARGS => sub {
  my ($orig,$class,%args) = @_;
  $orig->($class,%args);
};

sub fix {
  my($self,$data)=@_;

  $data->{items} = [];

  for my $field(@{ $data->{marc}->{fields} || [] }){
    next unless $field->{'852'};
    my $subfields = $field->{'852'}->{subfields} || [];
    
    my $item = {
      faculty => get_value($subfields,'x'),
      department => get_value($subfields,'b'),
      library => get_value($subfields,'c'),
      location => get_value($subfields,'j'),
      holding => get_value($subfields,'a'),
      barcode => get_value($subfields,'p')
    };
    
    #indien veld 'p' (barcode), dan bestaat er een uitgebreidere versie in de Z30
    next if $item->{barcode};

    #geen barcode? Dan zal er ook geen Z30 zijn. Bijgevolg is het niet uitleenbaar!
    delete $item->{barcode};

    #geen Z30 info over dit item? Niet ontlenen!
    $item->{loan} = 0;

    push @{ $data->{items} },$item;
  } 

  #Z30 info
  for my $field(@{ $data->{marc}->{fields} || [] }){
    next unless $field->{'Z30'};
    my $subfields = $field->{'Z30'}->{subfields} || [];

    #Z30f is numerieke code, Z30F is leesbare tekst
    my $loan = get_value($subfields,'F');
    my $loan_code = get_value($subfields,'f');

    my $item = {
      faculty => get_value($subfields,'x'),
      department => get_value($subfields,'1'),
      library => get_value($subfields,'2'),
      location => get_value($subfields,'3'),     
      volume => get_value($subfields,'h'),      
      barcode => get_value($subfields,'5'),      
      loan_status => $loan,
      loan_status_code => $loan_code
    };
    
    push @{ $data->{items} },$item;
  }
    
  #maak algemene info op bibliotheek
  my $facet_libraries = {};  
  my @list;

  for my $item(@{ $data->{items} }){
    my $library_id = $item->{library};
    $facet_libraries->{$library_id}++;
  }

  for my $library_id(keys %$facet_libraries){
    push @list,{
      num => $facet_libraries->{$library_id},
      library => $library_id
    };
  }

  @list = sort { (- ( $a->{num} <=> $b->{num} )) || $a->{library} cmp $b->{library} } @list;

  $data->{library_items} = \@list;

  $data;
}
sub get_value {
  my($fields,$key) = @_;
  for my $field(@$fields){
    my($k) = keys %$field;
    if($k eq $key){
      return $field->{$k};
    }
  }
}

=head1 items

  852p  => barcode. In dat geval uitgebreidere info in Z30. Sla dit over en ga naar Z30
        => geen holding (852a)
        => uitleenbaar        

  852a  => holding
        => geen barcode (852p)
        => niet uitleenbaar (want enkel Z30F bevat item-status)

  Z30f => ontleen-status, i.e. kan het ontleend worden, en zo ja onder welke condities? Code
     F => vertaling van Z30f


  Uitzonderingen: sommige tijdschriften (ser01) hebben holdings én items
=cut

1;
