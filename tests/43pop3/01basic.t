#!/usr/bin/env perl

use warnings;
use strict;

use lib qw(. .. tests);
use Tools;

use Test::More;

BEGIN
{   if($windows)
    {   plan skip_all => "not available on MicroSoft Windows.";
        exit 0;
    }

    plan tests => 14;
}

BEGIN { use_ok('Mail::Transport::POP3') }

# Check if all methods are there OK

can_ok('Mail::Transport::POP3', qw(
 deleted
 deleteFetched
 DESTROY
 disconnect
 fetched
 folderSize
 header
 ids
 id2n
 init
 message
 messages
 messageSize
 send
 sendList
 socket
 url
));

my $original     = File::Spec->catdir ('43pop3', 'original');
my $popbox       = File::Spec->catdir ('43pop3', 'popbox');

copy_dir($original, $popbox);
my ($server, $port) = start_pop3_server($popbox);
my $receiver = start_pop3_client($port);

isa_ok($receiver, 'Mail::Transport::POP3');

my $socket = $receiver->socket;
ok($socket, "Could not get socket of POP3 server");
print $socket "EXIT\n";

my @message = <$popbox/????>;
my $total = 0;
$total += -s foreach @message;
my $messages = @message;
cmp_ok($receiver->messages, '==', $messages, "Wrong number of messages");
cmp_ok($receiver->folderSize, '==', $total, "Wrong number of bytes");

my @id = $receiver->ids;
cmp_ok(scalar(@id), '==', scalar(@message), "Number of messages doesn't match");
is(join('',@id), join('',@message), "ID's don't match filenames");

my $error = '';
foreach(@id)
{   my ($reported, $real) = ($receiver->messageSize($_),-s);
    $error .= "size $_ is not right: expected $real, got $reported\n"
     if $reported != $real;
}
ok(!$error, ($error || 'No errors with sizes'));

$error = '';
foreach(@id)
{   my $message = $receiver->message($_);
    open(my $handle, '<', $_);
    $error .= "content of $_ is not right\n"
     if join('', @$message) ne join('', <$handle>);
}
ok(!$error, $error || 'No errors with contents');

$receiver->deleted(1,@id);
ok($receiver->disconnect, 'Failed to properly disconnect from server');

@message = <$popbox/????>;
cmp_ok(scalar(@message) ,'==', 0, 'Did not remove messages at QUIT');
ok(rmdir($popbox), "Failed to remove $popbox directory: $!");

is(join('', <$server>), <<EOD, 'Statistics contain unexpected information');
1
APOP 1
DELE 4
EXIT 1
LIST 1
NOOP 8
QUIT 1
RETR 4
STAT 1
UIDL 1
EOD
