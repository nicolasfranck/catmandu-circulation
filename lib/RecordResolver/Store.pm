package RecordResolver::Store;
use Catmandu::Sane;
use Catmandu;
use Catmandu::Fix;
use Catmandu::Util qw(:is :check);
use Moo;

has store => (
  is => 'ro',
  required => 1,
  isa => sub { check_string($_[0]); }
);
has bag => (
  is => 'ro',
  required => 1,
  isa => sub { check_string($_[0]); }
);
has fix => (
  is => 'ro'
);

has _bag => (
  is => 'ro',
  lazy => 1,
  default => sub { 
    my $self = $_[0];
    Catmandu->store($self->store)->bag($self->bag);
  }
);

sub resolve {
  my($self,$id) = @_;

  my $res = $self->resolve_default($id);    

  # Little Boopsie hack..if record can't be found it's probably a ser01
  # try again with rug01
  unless ($res) {
    $id =~ s/^\w+/ser01/;
    $res = $self->resolve_default($id);
  }

  if($self->fix){
    $res = Catmandu->fixer($self->fix)->fix($res);
  }

  return $res;
}

sub resolve_default {
  my($self,$id)=@_;
  $self->_bag()->get($id);
}

with 'RecordResolver';

1;
