# process variables
$kp_p = 50e-6;
$kp_n = 25e-6;
$cox_n = 2.3e-15;
$cox_p = 2.3e-15;
$Cov = 0.5e-15;

# pmos/nmos masks
#$pmos = [undef, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0];
$nmos = [undef, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1];

# Design spec
$Vdd = 2.5;
$Vss = -2.5;
$R_L = 20e3;
$C_L = 250e-15;
$C_in = 220e-15;

# Design requirement
$max_power_total = 2e-3;

# Resistor ratios
$R2R1_ratio = 4; 
$R4R3_ratio = 3; 

## Property initializations
# Design choice
$L = [undef, 2e-6, 2e-6, 20e-6, 2e-6, 2e-6, 2e-6, 2e-6, 10e-6, 2e-6, 4e-6]; # all xtors length = 2 to start with
$W = [undef, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; # to be calculated
$Vov = [undef, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; # will be calculated
my $gm = [undef, 0.0002, 0.0003, 0.0001, 0, 0.0003, 0.0001, 0.0001, 0, 0.0001, 0]; # 4, 8, 10 will be calculated later
$Cgs = [undef, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; # start with 0
$Ids = [undef, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; # Will set based on branch allocation below

## Design parameters
# Id distributions
my $Ids_distribution_percent = [undef, 30, 30, 10, 30]; # In %
$sum = $Ids_distribution_percent->[1] + $Ids_distribution_percent->[2] + $Ids_distribution_percent->[3] + $Ids_distribution_percent->[4];
if ($sum != 100) {
	print " ******** ERROR: Id allocation does not add to 100%!\n";
	return;
}
## Gain allocations
# Do this in log scale
my $A_cg = 10000;
my $A_cascode = 60;
my $A_cs = 2.5;
my $A_cd = .7;
$gain_total = $A_cg * $A_cascode * $A_cs * $A_cd; 

if ($gain_total < 30000) {
	print $gain_total;
	print " ******** ERROR: Gain is not > 30k!\n";
	# return;
}

# tuning parameters
my $R3R2_ratios = [0.1,0.5, 0.001, 10, 50, 100];
my $all_stage_gains = [[300, 300, 4.2, 0.7], [5000, 5, 1.2, 0.9]];
my $Ids_distribution_percents = [[undef, 30, 30, 10, 30], [undef, 20, 30, 20, 30]];
# start iterations
my $iter = 0; 
foreach (@$R3R2_ratios) {
    my $R3R2_ratio = $_;
    foreach (@${all_stage_gains}) {
	my $all_stage_gain = $_;
	foreach (@$Ids_distribution_percents) {
	    $Ids_distribution_percent = $_;
	    iterate($iter, $R3R2_ratio,$gm, $all_stage_gain->[0],
		    $all_stage_gain->[1], $all_stage_gain->[2], $all_stage_gain->[3],
		    $Ids_distribution_percent);
	    $iter++;
	}
    }
}


sub iterate {
    my ($iter, $R3R2_ratio, $gm, $A_cg, $A_cascode, $A_cs, $A_cd, $Ids_distribution_percent) = @_;
    
    print "iteration $iter: R3R2_ratio = $R3R2_ratio\n";
    print "gm = @$gm\n";
    print "gains = $A_cg, $A_cascode, $A_cs, $A_cd\n";
    print "Ids distribution:  @$Ids_distribution_percent\n";

   ## Calculate gm's
   # First resistor divider
   $R1 = (1 + $R2R1_ratio) * $A_cg / $R2R1_ratio;
   $R2 = $R2R1_ratio * $R1;
   
   # Second resistor divider
   $R3 = $R3R2_ratio*$R2;
   $R4 = $R4R3_ratio * $R3;
   $gm->[4] = ( ($R3 + $R4) * $A_cascode ) / ($R3 * $R4);
   
   # First xtor stack: tau = (Cin + Cgs2)/gm2, assume Cgs2 ~ Cin
   #$gm->[2] = $A_cg / (2 * $C_in);

   # Third xtor stack
   $gm->[8] = $gm->[7] / $A_cs;
   
   # Fourth xtor stack
   $gm->[10] = $A_cd / ($R_L * (1 - $A_cd) );
   
   ## Calculate I's
   #Power <= 2 mW, Vdd to Vss = 5V => Ids_tot = (2mW - P_res)/5V
   # P_res is power dissipated over resistor stacks, assuming no current leaks from resistor stack into xtor stacks
   $P_res = ($Vdd ** 2 / ($R1 + $R2)) + ($Vss ** 2 / ($R3 + $R4));
   if (($max_power_total - $P_res) < 0) {
   	print " ******** ERROR: Resistor stacks consume entire power budget!\n";
   	return;
   }
   $Ids_total = ($max_power_total - $P_res) / 5;
   
   # % of $Ids_total through each of the 4 branches
   $Ids_branch = [undef];
   push @$Ids_branch, ($Ids_total * (1/100) * $Ids_distribution_percent->[1]);
   push @$Ids_branch, ($Ids_total * (1/100) * $Ids_distribution_percent->[2]);
   push @$Ids_branch, ($Ids_total * (1/100) * $Ids_distribution_percent->[3]);
   push @$Ids_branch, ($Ids_total * (1/100) * $Ids_distribution_percent->[4]);
   $Ids->[1] = @$Ids_branch[1];
   $Ids->[2] = @$Ids_branch[1];
   $Ids->[3] = @$Ids_branch[1];
   $Ids->[4] = @$Ids_branch[2];
   $Ids->[5] = @$Ids_branch[2];
   $Ids->[6] = @$Ids_branch[2];
   $Ids->[7] = @$Ids_branch[3];
   $Ids->[8] = @$Ids_branch[3];
   $Ids->[9] = @$Ids_branch[4];
   $Ids->[10] = @$Ids_branch[4];
   
   
   ## Calculate widths and Vov
   for (my $i = 1; $i <=10 ; $i++){
   	$Vov->[$i] = compute_Vov($Ids->[$i], $gm->[$i]);
   	if ($nmos->[$i] == 1) {
   		$W->[$i] = compute_w($Ids->[$i], $kp_n, $L->[$i], $Vov->[$i]);
   	} else {
   		$W->[$i] = compute_w($Ids->[$i], $kp_p, $L->[$i], $Vov->[$i]);		
   	}
	if ($W->[$i] == 0) {
	    # W outside tech allowed range, skip this iter
	    print "WARNING: W${i} < min allowed, skip this iteration!\n";
	    return;
	}
   }
   # correct Vov dependencies: MN1, MN6, MN9 have same Vov
    $Vov->[6] = $Vov->[1];
    $Vov->[9] = $Vov->[1];
    $W->[9] = compute_w($Ids->[9], $kp_n, $L->[9], $Vov->[9]);
    $W->[6] = compute_w($Ids->[6], $kp_n, $L->[6], $Vov->[6]);
   
   ## Calculate Cgs values
   for (my $i = 1; $i <=10 ; $i++){
   	if ($nmos->[$i] == 1) {
   		$Cgs->[$i] = compute_Cgs($W->[$i], $L->[$i], $cox_n, $Cov);
   	} else {
   		$Cgs->[$i] = compute_Cgs($W->[$i], $L->[$i], $cox_p, $Cov);
   	}
   }
   
   ## Calculate time constants
   $tau_in = ($C_in + $Cgs->[2]) / $gm->[2];
   $tau_x = ($R1*$R2*$Cgs->[4]) / ($R1 + $R2);
   $tau_y = ($R3*$R4*$Cgs->[7])/($R3+$R4);
   $tau_z = ($Cgs->[8] + $Cgs->[10]*(1+$gm->[10]*$R_L))/$gm->[8];
   $tau_out = ($R_L * ($C_L + $Cgs->[10]*(1+(1 / ($gm->[10]*$R_L))))) / (1 + $gm->[10]*$R_L);
   
   $f_in = 1 / (2*3.14159*$tau_in);
   $f_x = 1 / (2*3.14159*$tau_x);
   $f_y = 1 / (2*3.14159*$tau_y);
   $f_z = 1 / (2*3.14159*$tau_z);
   $f_out = 1 / (2*3.14159*$tau_out);
   
    $tau_total = $tau_in + $tau_x + $tau_y + $tau_z + $tau_out;
    $f_3db = 1/ (2*3.14*$tau_total);
   
   print "f_3db = $f_3db\n";

   # write out spice deck
   open (F, ">iter${iter}.sp") || die "failed to open \n";
   my $str = '
   * Design Problem, ee114/214A-2015
   * Team Member 1 Name: Matthew Feldman
   * Team Member 2 Name: Amy Yen
   * Please fill in the specification achieved by your circuit 
   * before you submit the netlist.
   **************************************************************
   * sunetids of team members = mattfel, htyen
   * The specifications that this script achieves are: 
   * Power       <= 2.00 mW
   * Gain        >= 30.0 kOhm
   * BandWidth   >= 90.0 MHz
   * FOM         >= 1350
   ***************************************************************
   ';
   for (my $i = 1; $i <= 10 ; $i++) {
   	$str .= sprintf(".param W%i_val = %iu\n", $i, sprintf($W->[$i]*1000000));
   	$str .= sprintf (".param L%i_val = %iu\n", $i, sprintf($L->[$i]*1000000));
   }
   $str .= sprintf(".param R1_val = %ik\n", sprintf($R1/1000));
   $str .= sprintf(".param R2_val = %ik\n", sprintf($R2/1000));
   $str .= sprintf(".param R3_val = %ik\n", sprintf($R3/1000));
   $str .= sprintf(".param R4_val = %ik\n", sprintf($R4/1000));
   
   $str .= sprintf(".param Vbias_p_val = %f\n", sprintf($Vdd - .5 - $Vov->[3]));
   $str .= sprintf(".param Vbias_n_val = %f\n", sprintf($Vss + $Vov->[1] + .5));
   
   $str .= '
   ** Including the model file
   .include /usr/class/ee114/hspice/ee114_hspice.sp
   
   * Defining Top level circuit parameters
   .param p_Cin = 220f
   .param p_CL  = 250f
   .param p_RL  = 20k
   
   
   * defining the supply voltages
   vdd n_vdd 0 2.5
   vss n_vss 0 -2.5
   
   * Defining the input current source
   ** For ac simulation uncomment the following 2 lines**
   Iin    n_in    0    ac    1
   
   ** For transient simulation uncomment the following 2 lines**
   *Iin    n_in    0    sin(0 0.5u 1e6)
   
   * Defining Input capacitance
   Cin    n_in    0    \'p_Cin\'
   
   * Defining the load 
   RL    n_vout     0          \'p_RL\'
   CL    n_vout     0          \'p_CL\'
   
   *** Your Trans-impedance Amplifier here ***
   ***     d       g       s       b       n/pmos114       w       l
   * nmos b tied to lowest voltage
   * pmos b tied to highest voltage (or s)
   *** Vx/Iin = V(n_x) / Iin, use "n_x" as the node label for Vx ***
   MN1    n_in    n_nbias      n_vss    n_vss    nmos114 w=\'W1_val\'  l=\'L1_val\'
   MN2    n_x     0         n_in     n_vss    nmos114 w=\'W2_val\'  l=\'L2_val\'
   MP3    n_x    n_pbias      n_vdd    n_vdd    pmos114 w=\'W3_val\'  l=\'L3_val\'
   R1     n_x    n_vdd      \'R1_val\'
   R2     n_x    0          \'R2_val\'
   
   *** Vy/Vx = V(n_y) / V(n_x) use "n_y" as the node label for Vy ***
   MP4    n_4d    n_x      n_vdd    n_vdd    pmos114 w=\'W4_val\'  l=\'L4_val\'
   MP5    n_y    0          n_4d    n_4d    pmos114 w=\'W5_val\'  l=\'L5_val\'
   MN6    n_y    n_nbias      n_vss    n_vss    nmos114 w=\'W6_val\'  l=\'L6_val\'
   R3     n_y    0          \'R3_val\'
   R4     n_y    n_vss      \'R4_val\'
   
   *** Vz/Vy = V(n_z) / V(n_y) use "n_z"" as the node label for Vz ***
   MN7    n_z    n_y      n_vss    n_vss    nmos114 w=\'W7_val\'  l=\'L7_val\'
   MP8    n_z    n_z      n_vdd    n_vdd    pmos114 w=\'W8_val\'  l=\'L8_val\'
   
   *** Vout/Vz = V(n_vout) / V(n_z) use "n_vout" as the node label for Vout ***
   MN9    n_vout    n_nbias  n_vss    n_vss        nmos114 w=\'W9_val\'  l=\'L9_val\'
   MN10   n_vdd    n_z      n_vout    n_vss    nmos114 w=\'W10_val\'  l=\'L10_val\'
   
   *** Your Bias Circuitry goes here ***
   * TBD: ideal current source for now
   * TBD: fill in the bias current value from calculating Ids through M3 and M1,6,9 in saturation
   Vbn n_nbias 0 dc=\'Vbias_n_val\'
   VBp n_pbias 0 dc=\'Vbias_p_val\'
   
   *** defining the analysis ***
   .op
   .option post brief nomod
   
   ** For ac simulation uncomment the following line** 
   .ac dec 1k 100 1g
   .measure ac gainmax_vout max vdb(n_vout)
   .measure ac f3db_vout when vdb(n_vout)=\'gainmax_vout-3\'
   
   .measure ac gainmax_vx max vdb(n_x)
   .measure ac f3db_vx when vdb(n_x)=\'gainmax_vx-3\'
   
   .measure ac gainmax_vy max vdb(n_y)
   .measure ac f3db_vy when vdb(n_y)=\'gainmax_vy-3\'
   
   .measure ac gainmax_vz max vdb(n_z)
   .measure ac f3db_vz when vdb(n_z)=\'gainmax_vz-3\'
   
   ** For transient simulation uncomment the following line **
   *.tran 0.01u 4u 
   
   .end
   ';
   print F $str;
   
   close(F);
   
   # run hspice sim
   my $cmd = "hspice iter${iter}.sp > lis${iter}";
   print "Running: $cmd\n";
   system ($cmd) == 0 || die "failed to run $cmd\n";
   
   # print summary for this sweep 
   print "=======================================================================\n";
   printf ("Ids (uA):  %10.1f, %10.1f, %10.1f, %10.1f\n", $Ids_branch->[1] * 1000000, $Ids_branch->[2] * 1000000, $Ids_branch->[3] * 1000000, $Ids_branch->[4] * 1000000) ; 
   printf ("IRs (uA):  %10.1f, %10.1f\n", $Vdd / ($R1+$R2) * 1000000, -$Vss / ($R3+$R4) * 1000000) ; 
   printf ("As:        %10.1f, %10.1f, %10.1f, %10.1f\n", $A_cg, $A_cascode, $A_cs, $A_cd);
   printf ("Gain (k):  %10.1f\n", $gain_total/1000);
   printf ("Rs (k):    %10.1f, %10.1f, %10.1f, %10.1f\n",$R1 / 1000, $R2 / 1000, $R3 / 1000, $R4 / 1000);
   printf "===== Sizing =====\n";
   printf ("Ws (um):   %10.1f, %10.1f, %10.1f, %10.1f, %10.1f, %10.1f, %10.1f, %10.1f, %10.1f, %10.1f\n", $W->[1]*1000000, $W->[2]*1000000, $W->[3]*1000000, $W->[4]*1000000, $W->[5]*1000000,  $W->[6]*1000000, $W->[7]*1000000, $W->[8]*1000000, $W->[9]*1000000, $W->[10]*1000000);
   printf "===== BW =====\n";
   printf ("BWs (Mhz): %10.1f, %10.1f, %10.1f, %10.1f, %10.1f\n",$f_in / 1000000, $f_x / 1000000, $f_y / 1000000, $f_z / 1000000, $f_out / 1000000);
}

sub compute_Cgs {
   my ($W, $L, $Cox, $Cov) = @_;
   my $Cgs = 2/3 * $W * $L * $Cox + $Cov;
   return $Cgs;
}

sub compute_gm {
   my ($Ids, $Vov) = @_;
   my $gm = 2*$Ids/$Vov;
   return $gm;
}

sub compute_Vov {
   my ($Ids, $gm) = @_;
   my $Vov = 2*$Ids/$gm;
   return $Vov;
}

sub compute_w {
   my ($Ids, $kp, $L, $Vov) = @_;
   my $w = 2*$Ids / ($kp/$L*($Vov**2));
   if ($w < 2e-6 || $w > 1e-2) {
       return 0;
   }
   return $w;
}
