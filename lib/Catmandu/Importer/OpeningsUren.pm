package Catmandu::Importer::OpeningsUren;
use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Catmandu::OpeningsUren;
use Moo;
use Clone qw(clone);

our $VERSION = '0.01';

with 'Catmandu::Importer';

my $default_options = { start => 0,limit => 200 };

has base_url => (is => 'ro',required => 1);
has options => (
  is => 'ro',  
  isa => sub { check_hash_ref($_[0]); },
  lazy => 1,
  default => sub { $default_options; }
);

sub generator {
  my($self) = @_;

  my $op = Catmandu::OpeningsUren->new(base_url => $self->base_url);
  my $options = clone($self->options);
  $options->{start} = is_natural($self->options->{start}) ? $self->options->{start} : $default_options->{start};
  $options->{limit} = is_natural($self->options->{limit}) ? $self->options->{limit} : $default_options->{limit};

  return sub {
    state $buffer = [];

    if(scalar(@$buffer) == 0){
      $buffer = $op->libraries($options);
      return unless is_array_ref($buffer) && scalar(@$buffer);
      $options->{start} += $options->{limit};
    }

    shift(@$buffer);
  };
}

=head1 NAME

  Catmandu::Importer::OpeningsUren - Package that imports data from OpeningsUren

=head1 SYNOPSIS

    my $importer = Catmandu::Importer::OpeningsUren->new(
      base_url => "http://adore.ugent.be/rest",
      options => {
          q => "BHSL.PAP"
      }
    );

    The options are solr based and are directly injected in the Catmandu::Store::Solr

=cut

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
