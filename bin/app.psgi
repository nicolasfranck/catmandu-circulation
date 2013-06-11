#/usr/bin/env perl
use Catmandu::Sane;
use Catmandu qw(:load);
use Dancer;
use Plack::Builder;

use Circulation::App::Control::First;
use Circulation::App::Login;
use Circulation::App::Request;

my $base_url = Catmandu->config->{base_url};

my $app = sub {
  Dancer->dance(Dancer::Request->new(env => $_[0]));
};

builder {
  mount "/" => builder {
    enable '+Dancer::Middleware::Rebase', base => $base_url, strip => 1 if $base_url;
    enable 'Debug' if $ENV{PLACK_DEBUG};
    $app;
  };
};
