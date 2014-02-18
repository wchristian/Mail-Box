#!/usr/bin/env perl
#
# Test processing of message bodies which have their content stored
# in a file.
#

use strict;
use warnings;

use lib qw(. .. tests);
use Tools;

use Test::More tests => 33;
use IO::Scalar;

use Mail::Message::Body::File;

# Test to read a Lines from file.
# Let's fake the file, for simplicity.

my $filedata = <<'SIMULATED_FILE';
This is a file
with five lines, and it
is used to test whether
the reading into a lines body
would work (or not)
SIMULATED_FILE

my $f = IO::Scalar->new(\$filedata);

my $body = Mail::Message::Body::File->new(file => $f);
ok($body,                                           'body creation from file');
is($body->string, $filedata,                        'stringify');
cmp_ok($body->nrLines, "==", 5,                     'nr lines');

cmp_ok($body->size, "==", length $filedata,         'size');

my $fakeout;
my $g = IO::Scalar->new(\$fakeout);
$body->print($g);
is($fakeout, $filedata,                             'print');

my @lines = $body->lines;
cmp_ok(@lines, "==", 5,                             'count of lines');
my @filedata = split /^/, $filedata;
cmp_ok(@filedata, "==", 5,                          'count expected lines');
foreach (0..4) { is($lines[$_], $filedata[$_],      "line $_") }

# Reading data from lines.

$body = Mail::Message::Body::File->new(data => [@filedata]);
ok($body,                                           'creation from array of lines');
is($body->string, $filedata,                        'data');
cmp_ok($body->nrLines, "==", 5,                     'nr lines');
cmp_ok($body->size, "==", length $filedata,         'size');

$fakeout = '';
$body->print($g);
is($fakeout, $filedata,                             'result print');

@lines = $body->lines;
cmp_ok(@lines, "==", 5,                             'count of lines');
foreach (0..4) { is($lines[$_], $filedata[$_],      "line $_") }

# Test overloading

is("$body", $filedata,                              'overloaded stringification');
@lines = @$body;
ok(@lines,                                          'overloaded ref array');
cmp_ok(@lines, "==", 5,                             'count of lines');
foreach (0..4) { is($lines[$_], $filedata[$_],      "line $_") }

# Test cleanup

my $filename = $body->tempFilename;
ok(-f $filename,                                    'filename exists');
undef $body;
ok(! -f $filename,                                  'file cleaned up');

