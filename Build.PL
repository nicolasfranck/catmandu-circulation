use warnings;
use strict;
use Module::Build;

my $requires = {
  perl => '>=5.10.1',
  'Catmandu' => '>=0.2001',
  'Catmandu::Store::Solr' => 0,
  'Catmandu::AlephX' => 0,
  'HTTP::Tiny' => 0,
  'Plack' => '>=0.9985',
  'Dancer' => 1.311,
  'Dancer::Middleware::Rebase' => 0,
  'Dancer::Plugin::Lexicon' => 0.05,
  'Dancer::Session::Cookie' => 0,
  'Locale::Maketext::Lexicon' => 0,
  'Template::Plugin::JSON::Escape' => 0,
  'Digest::SHA' => 0,
  'AuthCAS' => 0,
  'XML::LibXSLT' => 0
};
my $recommends = {};
my $build = Module::Build->new(
  module_name => 'Circulation',
  dist_version => '0.01',
  dist_author => [
    'Nicolas Franck <nicolas.franck@ugent.be>',
  ],
  dist_abstract => 'Circulation',
  requires => $requires,
  recommends => $recommends,
  create_license => 1
);
$build->create_build_script;
