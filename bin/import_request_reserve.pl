#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu qw(:load);
use Catmandu::Importer::CSV;
use Catmandu::Util qw(:is :array);
use Circulation qw(request_reserve);

my $file = shift;
is_string($file) && -f $file || die("usage: $0 <file>\n");

my $importer = Catmandu::Importer::CSV->new(file => $file);

my @keys = qw(library default_action  item_status action  item_process_status item_process_action no_items_action);

my $n = $importer->each(sub {
    my $r = $_[0];
    my $f = {};
    for(@keys){
      $f->{$_} = $r->{$_};
    }
    $f->{_id} = $f->{library};
    say $f->{_id};
    request_reserve()->add($f);
});

=head1 SYNOPSIS

  format csv:

  library,default_action,item_status,action,item_process_status,item_process_action,no_items_action
  BIB,request,02|04|06|09|11|12|14|15|53|54|59|66|99,none,.+,none,request
  BIBA,request,02|04|06|09|11|12|14|15|53|54|59|66|99,none,.+,none,request
  BIBB,request,02|04|06|09|11|12|14|15|53|54|59|66|99,none,.+,none,request
  BIBC,request,02|04|06|09|11|12|14|15|53|54|59|66|99,none,.+,none,request
  BIBD,request,02|04|06|09|11|12|14|15|53|54|59|66|99,none,.+,none,request
  BIBE,request,02|04|06|09|11|12|14|15|53|54|59|66|99,none,.+,none,request
  BIBF,request,02|04|06|09|11|12|14|15|53|54|59|66|99,none,.+,none,request

=cut
