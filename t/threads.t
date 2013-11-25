#!/usr/bin/perl

use strict;
use warnings;

my $Have_Threads;
BEGIN {
    $Have_Threads = eval {
        require threads;
        require threads::shared;
        threads::shared->import;
        1;
    };
    require Test::More;
    Test::More->import;
}

plan skip_all => "Needs threads" unless $Have_Threads;

use UUID::Tiny qw(:std);

my $Num_Threads = 10;
my $noise_thread_run :shared;
my $noise_thread;
my @threads;

# UUID V3 

@threads = ();
my $expected_v3_uuid = create_uuid_as_string(UUID_V3, UUID_NS_DNS, 'cpan.org');
$noise_thread_run = 1;
$noise_thread = threads->create(sub {
    # This thread exists to exercise the underlying code and expose any 
    # thread-safety issues. A thread-safety issue may manifest by generating 
    # the improper UUID.
    my $text = 'foobar.com';
    while($noise_thread_run) {
      $text = create_uuid_as_string(UUID_V3, UUID_NS_DNS, $text);
    }
  });

for(1..$Num_Threads) {
    my $thr = threads->create(sub {
      my $uuid = create_uuid_as_string(UUID_V3, UUID_NS_DNS, 'cpan.org');
      is($uuid, $expected_v3_uuid, "All v3 uuids should generate the same across threads");
    });
    push(@threads, $thr);
}

note "All UUID_V3 threads started";
$_->join for @threads;
$noise_thread_run = 0;
$noise_thread->join;
note "All UUID_V3 threads joined";

# UUID V4 

@threads = ();

my %uuids : shared;
$uuids{create_uuid_as_string(UUID_V4)} = 1;

for(1..$Num_Threads) {
    my $thr = threads->create(sub {
        my $u = create_uuid_as_string(UUID_V4);
        lock(%uuids);
        ok(!exists($uuids{$u}), "All v4 uuids should be unique per thread"); 
        $uuids{$u} = 1;
    });
    push(@threads, $thr);
}

note "All UUID_V4 threads started";
$_->join for @threads;
note "All UUID_V4 threads joined";

# UUID V5 

@threads = ();
my $expected_v5_uuid = create_uuid_as_string(UUID_V5, UUID_NS_DNS, 'cpan.org');

$noise_thread_run = 1;
$noise_thread = threads->create(sub {
    # This thread exists to exercise the underlying code and expose any 
    # thread-safety issues. A thread-safety issue may manifest by generating 
    # the improper UUID.
    my $text = 'foobar.com';
    while($noise_thread_run) {
      $text = create_uuid_as_string(UUID_V5, UUID_NS_DNS, $text);
    }
  });


for(1..$Num_Threads) {
    my $thr = threads->create(sub {
      my $uuid = create_uuid_as_string(UUID_V5, UUID_NS_DNS, 'cpan.org');
      is($uuid, $expected_v5_uuid, "All v5 uuids should generate the same across threads");
    });
    push(@threads, $thr);
}

note "All UUID_V5 threads started";
$_->join for @threads;
$noise_thread_run = 0;
$noise_thread->join;
note "All UUID_V5 threads joined";

done_testing;
