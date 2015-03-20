#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use POSIX;
use List::Util 'shuffle';

#use Math::Random::MT::Auto qw(rand);

if(scalar @ARGV != 1){
    print "Usage: ./RC_shuffler file\n";
    exit;
}

my $file = $ARGV[0];
open F, $file or die "Unable to open file $file";
my @origEdges = <F>;
close F;

my %nodes;
foreach(@origEdges){
    my ($a, $b) = split '\s', $_;
    $nodes{$a} = $nodes{$b} = 1;
}
my $nNodes = scalar(keys %nodes);


my $out = $file;
$out =~ s/\.pairs/\_m0.pairs/;
system("cp $file $out");

for(my $i = 10; $i <= 90; $i += 10){
    my @edges = shuffle(@origEdges);

    # Remove edges
    my $links2del = floor(scalar @edges * $i /100);
    for(my $x = 0; $x < $links2del; $x++){
	shift @edges; # comment this line if you don't want any link removed
    }

    # Create hash
    my %e;
    foreach(@edges){
	my($a, $b) = split '\s', $_;
	$e{$a}{$b} = $e{$b}{$a} = 1;
    }

    # Shuffle edges
    my $links2shuffle = floor(scalar @edges * $i/100);
    for(my $x = 0; $x < $links2shuffle; $x++){
	my($a, $b);
	do{
	    $a = floor(rand($nNodes));
	    do{
		$b = floor(rand($nNodes));
	    }while($a eq $b);
	}while(defined($e{$a}{$b}) || defined($e{$b}{$a}));
	my $deleted = shift @edges;
	my($x,$y) = split '\s', $deleted;
	undef($e{$x}{$y});
	push @edges, "$a\t$b\n";
    }
    my $o = $file;
    $o =~ s/\.pairs/\_m$i\.pairs/;
    open O, ">$o";
    foreach(@edges){
	print O "$_";
    }
    close O;
}

