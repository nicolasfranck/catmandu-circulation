#!/usr/bin/env perl
use Catmandu::Sane;
use Catmandu qw(:load);
use Circulation qw(meercat);
use Data::Dumper;

Catmandu->fixer('items')->fix(meercat())->each(sub{
  print Dumper(shift);
});
