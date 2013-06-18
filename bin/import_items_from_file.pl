#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu qw(:load);
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::Fix;
use Catmandu::Importer::MARC;
use Getopt::Long;
use Time::HiRes qw(gettimeofday tv_interval);
use Circulation qw(:all);
use open qw(:std :utf8);

my $file;
my $verbose = undef;
my $test = undef;
my $count = 0;
my $start = [gettimeofday];
my $source;

GetOptions(
  "test" => \$test,
  "file=s" => \$file,
  "v" => \$verbose,
  "source=s" => \$source
);

$file = "/dev/stdin" unless defined($file) && (-r -f $file);


sub start {
  return unless $verbose;
  say STDERR "(start)";
}

sub verbose {
  return unless $verbose;
  ++$count;
  my $speed = $count / tv_interval($start);
  say STDERR sprintf " (doc %d %f)" ,$count,$speed if ($count % 100 == 0);
}

sub stats {
  return unless $verbose;
  my $speed = $count / tv_interval($start);
  say STDERR sprintf " (doc %d %f)" , $count, $speed;
  say STDERR "(end)";
}
sub fixer {
  state $fixer = do {
    my $fs = is_array_ref(Catmandu->config->{fixer}->{'items'}) ? Catmandu->config->{fixer}->{'items'} : [];
    unshift (@$fs,"add_field('source','$source')");
    push(@$fs,"move_field('source','i.\$append')");
    push (@$fs,"move_field('_id','i.\$append')");
    push (@$fs,"join_field('i',':')");
    push (@$fs,"move_field('i','_id')");
    Catmandu::Fix->new(fixes => $fs);
  };
}

my $it = Catmandu::Importer::MARC->new(type => "ALEPHSEQ",file => $file);
$it = fixer()->fix($it);
$it = $it->tap(\&verbose) if $verbose;
if($test){
  Catmandu->exporter()->add_many($it);
}else{
  records()->add_many($it);
}

