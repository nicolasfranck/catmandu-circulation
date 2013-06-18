package Catmandu::Fix::items;
use Catmandu::Sane;
use Catmandu;
use Moo;
use Catmandu::Util qw(:is :check :data);
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
  $orig->($class,path => $path,path_key => $path_key,marc => $marc);
};

sub fix {
  my($self,$data)=@_;

  my $marc = data_at($self->marc,$data);

  my @items;
  my $year;

  for my $row(@$marc){
    my($field,$ind1,$in2,@subfields) = @$row;

    given($field){
      when("008"){
        #fallback publicatiedatum, indien geen datum per item
        $year = substr($subfields[1],7,4);
        $year = undef unless is_integer($year);
      }
      when("852"){
        my $barcode = get_value(\@subfields,'p');

        #indien veld 'p' (barcode), dan bestaat er een uitgebreidere versie in de Z30
        next if $barcode;        

        my $item = {
          faculty => get_value(\@subfields,'x'),
          department => get_value(\@subfields,'b'),
          library => get_value(\@subfields,'c'),
          location => get_value(\@subfields,'j'),
          holding => get_value(\@subfields,'a')
        };
        push @items,$item;
      }
      when("Z30"){
        #Z30f is numerieke code, Z30F is leesbare tekst
        my $item_status = get_value(\@subfields,'F');
        my $item_status_code = get_value(\@subfields,'f');

        my $item = {
          faculty => get_value(\@subfields,'x'),
          department => get_value(\@subfields,'1'),
          library => get_value(\@subfields,'2'),
          location => get_value(\@subfields,'3'),
          barcode => get_value(\@subfields,'5'),
          item_status => get_value(\@subfields,'f'),
          item_status_h => get_value(\@subfields,'F'),
          item_process_status => get_value(\@subfields,'p'),
          material => get_value(\@subfields,'m')
        };

        #publication_date? Is afhankelijk van type bron!
        #Z30-MATERIAL (export Z30m) == 'ISSUE', dan staat publicatiedatum in Z30-ISSUE-DATE (export Z30i
        if(is_string($item->{material})){
          if(lc($item->{material}) eq "issue"){
            my $pd = get_value(\@subfields,'i');
            if(is_string($pd) && is_integer($pd) && length($pd) == 8){
              $pd = substr($pd,0,4)."-".substr($pd,4,2)."-".substr($pd,6,2);
              $item->{publication_date} = $pd;
            }
          }elsif(defined $year){
            $item->{publication_date} = "$year-01-01";
          }
        }

        push @items,$item;
      
      }
    }   
  }
  
  set_data(data_at($self->path,$data),$self->path_key,\@items);
    
  $data;
}
sub get_value {
  my($fields,$key) = @_;
  for(my $i = 0;$i < scalar(@$fields);$i += 2){
    if($fields->[$i] eq $key){
      return $fields->[$i + 1];
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

  Z30m => materiaal. Indien 'ISSUE', dan staat publicatiedatum in Z30i (Z30-ISSUE-DATE),
          in het andere geval wordt het 008-veld gebruikt


  items('marc' => 'marc','path' => 'it')


  Uitzonderingen: sommige tijdschriften (ser01) hebben holdings én items
=cut

1;
