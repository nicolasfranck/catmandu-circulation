package Circulation::Indexable::Request;
use Catmandu::Sane;
use Moo;

sub to_index_record {
  my($self,$object) = @_;
  my $idx = {};
  $idx->{_id} = $object->{_id};
  $idx->{date_dt}   = $object->{created};
  $idx->{status_s}  = $object->{status};
  $idx->{library_s} = $object->{request}->{library};
  $idx->{name_s}    = $object->{request}->{name};
  $idx->{availability_s} = $object->{record}->{availability}->{status};
  $idx;
}

with 'Circulation::Indexable';

1;
