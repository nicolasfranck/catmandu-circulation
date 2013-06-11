use warnings;
use strict;
use Module::Build;

#requires pre-installed:
#   Ubuntu: 
#       make, gcc, libxml2-dev, libexpat1-dev, zlib1g-dev
#   Centos/Redhat:
#       make, gcc, libxml2-devel, expat-devel, zlib-devel

my $requires = {
  perl => '>=5.10.1',
  'Catmandu' => '>=0.2001',
  'Catmandu::MARC' => 0,
  'Catmandu::Store::ElasticSearch' => 0,
  'Catmandu::Store::MongoDB' => 0,
  'HTTP::Tiny' => 0,
  'Plack' => '>=0.9985',
  'Dancer' => 1.311,
  'Dancer::Middleware::Rebase' => 0,
  'Dancer::Plugin::Feed' => 0,
  'Dancer::Plugin::Lexicon' => 0.05,
  'Dancer::Plugin::Catmandu::OAI' => 0,
  'Dancer::Logger::Log4perl' => '>=0.8.1',
  'Dancer::Session::Cookie' => 0,
  'Locale::Maketext::Lexicon' => 0,
  'Template::Plugin::JSON::Escape' => 0,
  'Digest::SHA' => 0,
  'AuthCAS' => 0,
  'Text::Unaccent' => 0,
  'XML::LibXSLT' => 0
};
my $recommends = {};
my $build = Module::Build->new(
  module_name => 'MeerCat',
  dist_version => '0.01',
  dist_author => [
    'Nicolas Franck <nicolas.franck@ugent.be>',
    'Nicolas Steenlant <nicolas.steenlant@ugent.be>',
    'Wouter Willaert <wouter.willaert@gmail.com>',
  ],
  dist_abstract => 'MeerCat Search Engine',
  requires => $requires,
  recommends => $recommends,
  create_license => 1
);
$build->create_build_script;
