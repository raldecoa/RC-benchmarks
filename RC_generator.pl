#!/usr/bin/perl

$|++;
use warnings;
use strict;
use Getopt::Long;

#use Math::Random::MT::Auto qw(rand);



use vars qw( $help $nNodes $nClusters $pIndex $pisTimes);


&GetOptions( "h|help" => \$help,
	     "n|nNodes=i" => \$nNodes,
	     "c|nClusters=i" => \$nClusters,
	     "p|pIndex=f" => \$pIndex,
	     "t|pisTimes=i" => \$pisTimes
    );

my $Usage = <<END_USAGE;

Usage:
    $0: [options]
Options:
    -h   --help           this message
    -n   --nNodes         number of nodes
    -c   --nClusters      number of clusters
    -p   --pIndex         Pielou\'s index
    -t   --pisTimes       (Optional) Number of attempts to reach that value of PI

END_USAGE
    ;

if ( $help || !$nNodes || !$nClusters || !$pIndex )
{
    die $Usage;
}

if( $pIndex <= 0 && $pIndex > 1 ){
    print "Pielou's Index must be between 0 and 1\n";
    die $Usage;
}

if( $nNodes < $nClusters * 2 ){
    my $tmp = $nNodes / 2;
    print "No singletons are allowed. Add more nodes or ";
    print "set a lower number of clusters (max = $tmp)(\n";
    die;
}

$pisTimes = 100000 unless $pisTimes;

my @clusters;
# Special case for PI = 1
if( $pIndex == 1 ){
    if ( $nNodes % $nClusters != 0 ){
	print "$nNodes is not multiple of $nClusters.  ";
	print "No equal-sized communities can be built\n";
	die;
    }
    else{
	my $n = $nNodes / $nClusters;
	for(my $i = 0; $i < $nClusters; $i++){
	    push @clusters, $n;
	}
    }
}
else{  # Broken stick model
    my $pi;
    my $pis = 0;
    my $maxPI = 0;
    my $minPI = 1;
    my ( @maxClusters, @minClusters );
    print "Computing";
    do{
	my $isOk;
	my @indexes;
	my $times = 0;
	do{
	    # Compute intermediate points
	    @indexes = ();
	    for(my $i = 0; $i < $nClusters - 1; $i++){
		my $index = int( rand($nNodes) );
		push @indexes, $index;
	    }
	    
	    $isOk = &checkPoints(\@indexes);
	    $times++;
	}while (!$isOk && $times < 1000000 );
	
	if(!$isOk){
	    die "Took too much time. Try a lower number of clusters";
	}
	else{
	    push @indexes, 0;
	    push @indexes, $nNodes;
	    @indexes = sort { $a <=> $b} @indexes;
	    @clusters = ();
	    for(my $i = 0; $i < scalar @indexes -1; $i++){
		push @clusters, $indexes[$i+1] - $indexes[$i];
	    }
	    $pi = &calcPI(\@clusters);
	    $pis++;
	    if($pi > $maxPI){
		$maxPI = $pi;
		@maxClusters = @clusters;
	    }
	    if($pi < $minPI){
		$minPI = $pi;
		@minClusters = @clusters;
	    }
	}
	if($pis % 1000 == 0) { print "."; }
    }while($pi != $pIndex && $pis < $pisTimes);


    if($pi != $pIndex){
	print "$maxPI    ------         $minPI\n";
	if($maxPI < $pIndex){
	    print "\n\nPI $pIndex too high, not reached. Returning PI = $maxPI";
	    $pIndex = $maxPI;
	    @clusters = @maxClusters;
	}
	else{
	    print "\n\nPI = PI $pIndex too low, not reached. Returning PI = $minPI";
	    $pIndex = $minPI;
	    @clusters = @minClusters;
	}
    }
}


@clusters = sort {$a <=> $b} (@clusters);
my $graph = &computeRC(\@clusters);

&comm2file(\@clusters);
&graph2file($graph);
print "\nNetwork generation OK\n";



sub checkPoints{ # Check intermediate points

    my $array = $_[0];
    for(my $i = 0; $i < $nClusters - 1; $i++){
	if( $array->[$i] < 2 || $array->[$i] > $nNodes - 2 ){ 
	    return 0; 
	}
	for(my $j = $i+1; $j < $nClusters - 1; $j++){
	    if( $array->[$j] < 2 || $array->[$i] > $nNodes - 2 ){ 
		return 0; 
	    }
	    if( abs($array->[$i] - $array->[$j]) < 2 ){
		return 0;
	    }
	}
    }
    return 1;
}

sub calcPI{ # Compute Pielou's Index

    my $array = $_[0];

    my $total = 0;
    for ( my $i = 0; $i < $nClusters; $i++ ){
	$total += $array->[$i];
    }

    my $e = 0;
    for ( my $i = 0; $i < $nClusters; $i++ ){
	my $p_i = $array->[$i] / $total;
	$e -= $p_i * log ( $p_i );
    }

    my $se = $e / log ( $nClusters );
    $se = sprintf( "%.2f", $se );

    return $se;
}


sub computeRC{

    my @graph;

    my $clusters = $_[0];
    my $min = 0;
    foreach(@$clusters){
	for(my $i = $min; $i < $min + $_; $i++){
	    for(my $j = $i+1; $j < $min + $_; $j++){
		push @graph, [$i,$j];
	    }
	}
	$min += $_;
    }
    return \@graph;
}


sub comm2file{

    my @c = @{ $_[0] };

    open(O, ">RC_PI-$pIndex.comm");
    my $index = 0;
    for(my $cl = 0; $cl < scalar @c; $cl++){
	for(my $i = 0; $i < $c[$cl]; $i++){
	    print O "$index\t$cl\n";
	    $index++;
	}
    }
    close O;
}

sub graph2file{

    my @g = @{ $_[0] };

    open(O, ">RC_PI-$pIndex.pairs");
    foreach my $e (@g){
	print O $e->[0]."\t".$e->[1]."\n";
    }
    close O;
}
