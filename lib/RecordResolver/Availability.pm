package RecordResolver::Availability;

use base qw(RecordResolver);

use LWP::Simple;
use URI::Escape;
use XML::XPath;
use JSON;

sub resolve {
    my $self = shift;
    my $id   = shift;   

    die "need a baseurl" unless $self->{baseurl};

    return undef unless (defined $id && length $id);

    my $url = sprintf "%s?barcode=%s"
			, $self->{baseurl}
			, uri_escape($id);

    my $content = get($url);
  
    return undef unless $content;

    return from_json($content);
}

1;
