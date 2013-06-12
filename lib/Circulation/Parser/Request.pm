package Circulation::Parser::Request;
use Moo;
use Catmandu::Util qw(:is :check);

has record_resolver => (
  is => 'ro',
  isa => sub {
    check_instance($_[0],"RecordResolver::UnAPI");
  }
);
has availability_resolver => (
  is => 'ro',
  isa => sub {
    check_instance($_[0],"RecordResolver::Availability");
  }
);

sub parse {
  my($self,%opts)=@_;
  my $params = $opts{params};
  my $env = $opts{env};
  my $cfg = $opts{cfg};
  my $session = $opts{session};

  my $object = {
    created => time,
    modified => time
  };

  $object->{request}->{remote_addr} = $env->{REMOTE_ADDR};

  my %main_param = (id=>1);

  foreach my $param_key(keys %$params){
    next unless ($param_key =~ /^_/);
    my $name = $param_key;
    $name =~ s/^_//;

    if($main_param{$name}){
      $object->{$name} = $params->{$param_key};
    }else{
      $object->{request}->{$name} = $params->{$param_key};
    }
  }

  if($object->{request}->{bibcall}){
    my ($library,$callnumber) = split(/;/,$object->{request}->{bibcall},2);
    $object->{request}->{library} = $library;
    $object->{request}->{callnr}  = $callnumber;
    delete $object->{request}->{bibcall};
  }

  if($object->{request}->{record}){
    my $record = $self->record_resolver->resolve($object->{request}->{record});
    $object->{record} = $record;
  }

  my $loc = $object->{record}->{location};

  if(defined $loc){
    if(@$loc == 1){
      my $library    = $loc->[0]->{bib};
      my $callnumber = $loc->[0]->{shelf};
      $callnumber ||= '---';
      my $holding    = $loc->[0]->{holding};
      my $barcode    = $loc->[0]->{barcode};

      $object->{request}->{library} = $library;
      $object->{request}->{callnr}  = $callnumber;
      $object->{request}->{holding} = $holding;
      $object->{request}->{barcode} = $barcode;

      $params->{_library} = $library;
      $params->{_callnr} = $callnumber;
      $params->{_holding} = $holding;
      $params->{_barcode} = $barcode;
    }
    else {
      foreach my $l (@$loc) {
        my $library    = $l->{bib};
        my $callnumber = $l->{shelf};
        my $holding    = $l->{holding};
        my $barcode    = $l->{barcode};

        if( $object->{request}->{library} eq $library && $object->{request}->{callnr} eq $callnumber){
          $object->{request}->{library} = $library;
          $object->{request}->{callnr}  = $callnumber;
          $object->{request}->{holding} = $holding;
          $object->{request}->{barcode} = $barcode;

          $params->{_library} = $library;
          $params->{_callnr} = $callnumber;
          $params->{_holding} = $holding;
          $params->{_barcode} = $barcode;

        }
      }
    }
  }

  if(defined $object->{request}->{barcode} && length($object->{request}->{barcode})){
    my $avail = $self->availability_resolver->resolve($object->{request}->{barcode});
    $object->{record}->{availability} = $avail->{loan} if $avail;
  }
  
  if($session && defined($session->{remember}) && $session->{remember} eq 'on'){
    $params->{_name} = $session->{name} unless $params->{_name};
    $params->{_contact} = $session->{contact} unless $params->{_contact};
    $params->{_uid} = $session->{uid} unless $params->{_uid};
    $params->{_remember} = 'on';
  }

  return $object;
}

with 'Circulation::Parser';

1;
