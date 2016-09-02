# $Id: 04-packet.t,v 1.1 2004/04/09 17:04:48 dasenbro Exp $

use Test::More tests => 34;
use strict;

BEGIN { use_ok('Net::DNS'); }     #1


my $domain = "example.com";
my $type   = "MX";
my $class  = "IN";

#------------------------------------------------------------------------------
# Make sure we can create a DNS packet.
#------------------------------------------------------------------------------

my $packet = Net::DNS::Packet->new($domain, $type, $class);

ok($packet,                                 'new() returned something');         #2
ok($packet->header,                         'header() method works');            #3
ok($packet->header->isa('Net::DNS::Header'),'header() returns right thing');     #4


my @question = $packet->question;
ok(@question && @question == 1,             'question() returned right number of items'); #5
ok($question[0]->isa('Net::DNS::Question'), 'question() returned the right thing');       #6


my @answer = $packet->answer;
ok(@answer == 0,     'answer() works when empty');     #7


my @authority = $packet->authority;
ok(@authority == 0,  'authority() works when empty');  #8

my @additional = $packet->additional;
ok(@additional == 0, 'additional() works when empty'); #9

$packet->push("answer", 
	Net::DNS::RR->new(
		Name    => "a1.example.com",
		Type    => "A",
		Address => "10.0.0.1"
	)
);
is($packet->header->ancount, 1, 'First push into answer section worked');      #10


$packet->push("answer", 
	Net::DNS::RR->new(
		Name    => "a2.example.com",
		Type    => "A",
		Address => "10.0.0.2"
	)
);
is($packet->header->ancount, 2, 'Second push into answer section worked');     #11


$packet->push("authority", 
	Net::DNS::RR->new(
		Name    => "a3.example.com",
		Type    => "A",
		Address => "10.0.0.3"
	)
);
is($packet->header->nscount, 1, 'First push into authority section worked');   #12


$packet->push("authority", 
	Net::DNS::RR->new(
		Name    => "a4.example.com",
		Type    => "A",
		Address => "10.0.0.4"
	)
);
is($packet->header->nscount, 2, 'Second push into authority section worked');  #13

$packet->push("additional", 
	Net::DNS::RR->new(
		Name    => "a5.example.com",
		Type    => "A",
		Address => "10.0.0.5"
	)
);
is($packet->header->adcount, 1, 'First push into additional section worked');  #14

$packet->push("additional", 
	Net::DNS::RR->new(
		Name    => "a6.example.com",
		Type    => "A",
		Address => "10.0.0.6"
	)
);
is($packet->header->adcount, 2, 'Second push into additional section worked'); #15

my $data = $packet->data;

my $packet2 = Net::DNS::Packet->new(\$data);

ok($packet2, 'new() from data buffer works');   #16

is($packet->string, $packet2->string, 'string () works correctly');  #17


my $string = $packet2->string;
for (1 .. 6) {
	my $ip = "10.0.0.$_";
	ok($string =~ m/\Q$ip/,  "Found $ip in packet");  # 18 though 23
}

is($packet2->header->qdcount, 1, 'header question count correct');   #24
is($packet2->header->ancount, 2, 'header answer count correct');     #25
is($packet2->header->nscount, 2, 'header authority count correct');  #26 
is($packet2->header->adcount, 2, 'header additional count correct'); #27



# Test using a predefined answer. This is an answer that was generated by a bind server.
#

$data=pack("H*","22cc85000001000000010001056461636874036e657400001e0001c00c0006000100000e100025026e730472697065c012046f6c6166c02a7754e1ae0000a8c0000038400005460000001c2000002910000000800000050000000030");
my $packet3 = Net::DNS::Packet->new(\$data);
ok($packet3,                                 'new(\$data) returned something');         #28

is($packet3->header->qdcount, 1, 'header question count in syntetic packet correct');   #29
is($packet3->header->ancount, 0, 'header answer count in syntetic packet correct');     #30
is($packet3->header->nscount, 1, 'header authority count in syntetic packet  correct'); #31 
is($packet3->header->adcount, 1, 'header additional in sytnetic  packet correct');      #32

my @rr=$packet3->additional;

is($rr[0]->type, "OPT", "Additional section packet is EDNS0 type");                         #33
is($rr[0]->class, "4096", "EDNS0 packet size correct");                                     #34