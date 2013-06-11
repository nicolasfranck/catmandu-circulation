package Circulation::Request;
use Moo;
use Catmandu::Util qw(:is :check);

has request => (
  is => 'rw',
  isa => sub {
    check_hash_ref($_[0]);
  }
);
has record => (
  is => 'rw',             
  isa => sub {
    check_hash_ref($_[0]);
  }
);

1;
