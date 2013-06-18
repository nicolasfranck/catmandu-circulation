package RecordResolver::Availability;
use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Moo;
use LWP::Simple;
use URI::Escape;
use XML::XPath;
use JSON;

has baseurl => (is => 'ro',required => 1,isa => sub { check_string($_[0]); });

sub resolve {
  my $self = shift;
  my $id   = shift;   

  die "need a baseurl" unless $self->baseurl;

  return undef unless (defined $id && length $id);

  my $url = sprintf "%s?barcode=%s"
		, $self->baseurl
		, uri_escape($id);

  my $content = get($url);

  return undef unless $content;

  return from_json($content);
}

with 'RecordResolver';

1;
