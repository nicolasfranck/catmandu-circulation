#!/usr/bin/env perl
use Catmandu qw(:load);
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Getopt::Long;
use Circulation qw(records documents);
use open qw(:std :utf8);
use Data::Dumper;

my $file;
my $test = undef;

GetOptions(
  "file=s" => \$file,
  "test" => \$test
);
$file = "/dev/stdin" unless defined($file) && (-f -r $file);

my $fixer = Catmandu->fixer('items');
my $exporter = Catmandu->exporter('YAML');

open my $fh,"<:utf8",$file or die($!);
while(my $id = <$fh>){
  chomp $id;
  my $document = documents()->get($id);
  unless($document){
    warn "$id does not exist\n";
    next; 
  }
  next unless $document;
  $document = $fixer->fix($document);
  if($test){
    $exporter->add($document);
  }else{
    say $id;
    records()->add_many($document);
  }
}
close $fh;

