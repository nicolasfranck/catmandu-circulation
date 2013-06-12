package Circulation::App::Request;
our $VERSION = '1.0';
use Catmandu::Sane;
use Catmandu;
use Dancer qw(:syntax);
use Dancer::Plugin::Lexicon;
use Circulation qw(:all);
use Catmandu::Util qw(:is :array require_package);
use Try::Tiny;
use Catmandu::Importer::MARC;
use Time::HiRes;

get '/records/:_id/items' => sub {
  my $params = params();
  my($source,$fSYS) = split(':',$params->{_id} || "");
  my $start = Time::HiRes::time;
  my $result = meercat()->search(query => "source:$source AND fSYS:$fSYS",limit => 1);
  say STDERR "diff search:".(Time::HiRes::time - $start);
  $start = Time::HiRes::time;
  my $xml = $result->first->{fXML};
  open my $fh,"<:utf8",\$xml or die($!);
  my $record = Catmandu::Importer::MARC->new(type => "XML",file => $fh)->first;
  close $fh;
  $record = Catmandu->fixer('items')->fix($record);
  say STDERR "diff processing:".(Time::HiRes::time - $start);
 
  to_json($record);
};

1;
