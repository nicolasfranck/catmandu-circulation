#!/usr/bin/env perl
use Catmandu::Sane;
use Catmandu qw(:load);
use Circulation qw(meercat);
use Data::Dumper;
use Catmandu::Importer::MARC;

my $query = shift;
my $result = meercat()->search(query => $query,limit => 1);
my $xml = $result->first->{fXML};
open my $fh,"<:utf8",\$xml or die($!);
my $r = Catmandu::Importer::MARC->new(type => "XML",file => $fh,fix => 'items')->first;
close $fh;
print Dumper($r);
