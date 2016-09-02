#!/usr/bin/perl

use lib '.'; use lib 't';
use SATest; sa_t_init("prefs_include");
use Test; BEGIN { plan tests => 2 };

$ENV{'LANGUAGE'} = $ENV{'LC_ALL'} = 'C';             # a cheat, but we need the patterns to work

# ---------------------------------------------------------------------------

%patterns = (

    q{X-Spam-Report: =?ISO-8859-1?Q? }, 'qp-encoded-hdr',
    q{ Invalid Date: header =ae =af =b0 foo }, 'qp-encoded-desc',

);

tstprefs ("
        $default_cf_lines
        include prefs_include.inc
        ");

open (OUT, ">log/prefs_include.inc") or die "open log/prefs_include.inc failed";
print OUT "
        report_safe 0
	describe INVALID_DATE	Invalid Date: header \xae \xaf \xb0 foo
	";
close OUT;

sarun ("-L -t < data/spam/001", \&patterns_run_cb);
ok_all_patterns();

