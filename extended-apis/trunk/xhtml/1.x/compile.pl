#!/usr/bin/perl

use strict;
use warnings;

use Template;

my @files = ("std/toc/toc");

sub get_file_mtime
{
    my $path = shift;

    return (stat($path))[9];
}

foreach my $f (@files)
{
    my $wml_f = "$f.wml";
    my $wml_source = "$wml_f.tt2";
    my $src_mtime = get_file_mtime($wml_source);
    my $dest_mtime = get_file_mtime($wml_f);
    if ((! -e $wml_f) ||
        ($src_mtime > $dest_mtime)
       )
    {
        my $t = Template->new();
        $t->process($wml_source, +{}, $wml_f);
    }
}

