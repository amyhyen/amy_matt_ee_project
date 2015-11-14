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
$R4R3_ratio = 4; 

## Property initializations
# Design choice
$L = [undef, 2e-6, 2e-6, 20e-6, 2e-6, 2e-6, 2e-6, 2e-6, 10e-6, 2e-6, 4e-6]; # all xtors length = 2 to start with
$W = [undef, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; # to be calculated
$Vov = [undef, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; # will be calculated
$gm = [undef, 0.0002, 0.0003, 0.0001, 0, 0.0003, 0.0001, 0, 0, 0.0001, 0]; # 4, 7, 8, 10 will be calculated later
$Cgs = [undef, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; # start with 0
$Ids = [undef, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; # Will set based on branch allocation below

## Design parameters
# Id distributions
$Ids_distribution_percent = [undef, 40, 25, 10, 25]; # In %
$sum = $Ids_distribution_percent->[1] + $Ids_distribution_percent->[2] + $Ids_distribution_percent->[3] + $Ids_distribution_percent->[4];
if ($sum != 100) {
	print " ******** ERROR: Id allocation does not add to 100%!\n";
	return;
}
## Gain allocations
# Do this in log scale
$A_cg = 5050;
$A_cascode = 30;
$A_cs = 2.5;
$A_cd = .7;
$gain_total = $A_cg * $A_cascode * $A_cs * $A_cd; 

if ($gain_total < 30000) {
	print $gain_total;
	print " ******** ERROR: Gain is not > 30k!\n";
	# return;
}

## Calculate gm's
# First resistor divider
$R1 = (1 + $R2R1_ratio) * $A_cg / $R2R1_ratio;
$R2 = $R2R1_ratio * $R1;

# Second resistor divider
$R3 = 10*$R2;
$R4 = $R4R3_ratio * $R3;
$gm->[4] = ( ($R3 + $R4) * $A_cascode ) / ($R3 * $R4);

# Third xtor stack
$gm->[7] = .0001;
$gm->[8] = $gm->[7] / $A_cs;

# Fourth xtor stack
$gm->[10] = $A_cd / ($R_L * (1 - $A_cd) );

## Calculate I's
#Power <= 2 mW, Vdd to Vss = 5V => Ids_tot = (2mW - P_res)/5V = 400uA 
# P_res is power dissipated over resistor stacks, assuming no current leaks from resistor stack into xtor stacks
$P_res = ($Vdd ** 2 / ($R1 + $R2)) + ($Vss ** 2 / ($R3 + $R4));
if ((2e-3 - $P_res) < 0) {
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
}

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

# $tau_total = $tau_in + $tau_x + $tau_y + $tau_z + $tau_out;
# $f_3db = 1/ (2*3.14*$tau_total);

for (my $i = 1; $i <= 10 ; $i++) {
	printf (".param W%i_val = %iu\n", $i, sprintf($W->[$i]*1000000));
	printf (".param L%i_val = %iu\n", $i, sprintf($L->[$i]*1000000));
}
printf (".param R1_val = %ik\n", sprintf($R1/1000));
printf (".param R2_val = %ik\n", sprintf($R2/1000));
printf (".param R3_val = %ik\n", sprintf($R3/1000));
printf (".param R4_val = %ik\n", sprintf($R4/1000));

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
   return $w;
}
