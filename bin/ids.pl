#!/usr/bin/env perl
use Catmandu qw(:load);
use Catmandu::Sane;
use Circulation qw(:all);

records()->each(sub{ say $_[0]->{_id}; });
