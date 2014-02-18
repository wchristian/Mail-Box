#!/usr/bin/env perl
#
# Test conversions from HTML/XHTML to plain text with HTML::FormatText
#

use strict;
use warnings;

use lib qw(. .. tests);
use Tools;

use Test::More;

use Mail::Message::Body::Lines;

BEGIN {
   
   eval 'require HTML::FormatText';

   if($@)
   {   plan skip_all => "requires HTML::FormatText.\n";
       exit 0;
   }

   require Mail::Message::Convert::HtmlFormatText;
   plan tests => 7;
}

my $html  = Mail::Message::Convert::HtmlFormatText->new;

my $body = Mail::Message::Body::Lines->new
  ( type => 'text/html'
  , data => $raw_html_data
  );

my $f = $html->format($body);
ok(defined $f);
ok(ref $f);
isa_ok($f, 'Mail::Message::Body');
is($f->mimeType, 'text/plain');
is($f->charset, 'iso-8859-1');
is($f->transferEncoding, 'none');

is($f->string, <<'EXPECTED');
   Life according to Brian
   =======================

   This is normal text, but not in a paragraph.

   New paragraph in a bad way. And this is just a continuation. When
   texts get long, they must be auto-wrapped; and even that is working
   already.


   Silly subsection at once



   and another chapter
   ===================


   again a section
   ---------------

   Normal paragraph, which contains an [IMAGE], some italics with
   linebreak and code

   And now for the preformatted stuff
      it should stay as it was
         even   with   strange blanks
     and indentations

   And back to normal text...

     * list item 1

         1. list item 1.1

         2. list item 1.2

     * list item 2
EXPECTED

exit 0;
