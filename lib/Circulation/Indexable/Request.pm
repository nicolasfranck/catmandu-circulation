package Circulation::Indexable::Request;
use Catmandu::Sane;
use Moo;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::TimeZone;

sub time2str {
  my $time = shift || time;
  $time = int($time);
  DateTime::Format::Strptime::strftime(
    '%FT%TZ', DateTime->from_epoch(epoch=>$time,time_zone => DateTime::TimeZone->new(name => 'local'))
  );
}

sub to_index_record {
  my($self,$object) = @_;
  my $idx = {};
  $idx->{_id} = $object->{_id};
  my $date = time2str($object->{created});
  $idx->{date_dt}   = $date;
  $idx->{status_s}  = $object->{status};
  $idx->{library_s} = $object->{request}->{library};
  $idx->{name_s}    = $object->{request}->{name};
  $idx->{availability_s} = $object->{record}->{availability}->{status};
  $idx;
}

with 'Circulation::Indexable';

1;
