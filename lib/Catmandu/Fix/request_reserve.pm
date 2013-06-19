package Catmandu::Fix::request_reserve;
use Catmandu::Sane;
use Catmandu;
use Moo;
use Circulation qw(request_reserve);
use Catmandu::Util qw(:is :check :data);
use List::MoreUtils qw(first_index);

sub fix {
  my($self,$data)=@_;

  #request? Catmandu::Fix::items converteert 852c (met holdings) naar items! Je kan ze enkel onderscheiden op basis van bestaan van een barcode
  my @req_res;
  for my $lib(@{ $data->{library} }){
    my $l = request_reserve()->get($lib);
    push @req_res,$l if $l;
  }
  for my $item(@{ $data->{items} }){
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
  
  $data;
}
=head1 request_reserve

  welke bibliotheken laten toe dat hun 'items' via onze 'request'-knop worden aangevraagd?

=cut

1;
