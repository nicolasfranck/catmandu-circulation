package Catmandu::Fix::items;
use Catmandu::Sane;
use Catmandu;
use Moo;
use Catmandu::Util qw(:is :check data_at);
use URI::Escape qw(uri_escape);

has marc => (
  is => 'ro',
  isa => sub{ check_array_ref($_[0]); }
);
has path => (
  is => 'ro',
  isa => sub{ check_array_ref($_[0]); }
);
has path_key => (
  is => 'ro',
  isa => sub { check_string($_[0]); }
);

around BUILDARGS => sub {
  my ($orig,$class,%args) = @_;

  my($path,$path_key) = parse_data_path($args{path}) if is_string($args{path});
  my($marc,$marc_key) = parse_data_path($args{marc}) if is_string($args{marc});
  push @$marc,$marc_key if $marc_key;
  $orig->($class,path => $path,path_key => $path_key,marc => $marc,marc_key => $marc_key);
};

sub fix {
  my($self,$data)=@_;

  my $marc = data_at($self->marc,$data);

  my $items = [];

  for my $field(@{ $marc->{fields} || [] }){
    next unless $field->{'852'};
    my $subfields = $field->{'852'}->{subfields} || [];

    my $barcode = get_value($subfields,'p');

    #indien veld 'p' (barcode), dan bestaat er een uitgebreidere versie in de Z30
    next if $barcode;

    #geen barcode? Dan zal er ook geen Z30 zijn. Uitleenbaarheid hangt dan af van de bibliotheek
    my $item = {
      faculty => get_value($subfields,'x'),
      department => get_value($subfields,'b'),
      library => get_value($subfields,'c'),
      location => get_value($subfields,'j'),
      holding => get_value($subfields,'a')
    };

    push @$items,$item;
  } 

  #Z30 info
  for my $field(@{ $marc->{fields} || [] }){
    next unless $field->{'Z30'};
    my $subfields = $field->{'Z30'}->{subfields} || [];

    #Z30f is numerieke code, Z30F is leesbare tekst
    my $item_status = get_value($subfields,'F');
    my $item_status_code = get_value($subfields,'f');

    my $item = {
      faculty => get_value($subfields,'x'),
      department => get_value($subfields,'1'),
      library => get_value($subfields,'2'),
      location => get_value($subfields,'3'),     
      volume => get_value($subfields,'h'),      
      barcode => get_value($subfields,'5'),      
      item_status => get_value($subfields,'f'),
      item_status_h => get_value($subfields,'F'),
      item_process_status => get_value($subfields,'p')
    };
    
    push @$items,$item;
  }

  use Data::Dumper;
  print STDERR Dumper($items);

  set_data(data_at($self->path,$data),$self->path_key,$items);
    
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


  items('marc' => 'marc','path' => 'it')


  Uitzonderingen: sommige tijdschriften (ser01) hebben holdings én items
=cut

1;
