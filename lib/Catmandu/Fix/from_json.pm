package Catmandu::Fix::from_json;
use Catmandu::Sane;
use Moo;
use JSON;

with 'Catmandu::Fix::Base';

has path => (is => 'ro', required => 1);

around BUILDARGS => sub {
  my ($orig,$class,$path) = @_;
  $orig->($class,path => $path);
};

sub emit {
  my ($self, $fixer) = @_;
  my $path = $fixer->split_path($self->path);
  my $key = pop @$path;

  $fixer->emit_walk_path($fixer->var,$path,sub {
    my $var = shift;
    $fixer->emit_get_key($var,$key,sub{
      my $var = shift;
      "${var} = JSON::from_json(${var});";
    });
  });
}

=head1 NAME

Catmandu::Fix::uniq - remove duplicate from a list

=head1 SYNOPSIS

   #'["RE","RE"]' becomes ["RE"]
   from_json('faculty');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
