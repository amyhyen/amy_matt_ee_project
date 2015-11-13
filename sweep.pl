# process variables
$kp_p = 50e-6;
$kp_n = 25e-6;
$vt_p = 0.5;
$vt_n = 0.5;
$cox_n = 2.3e-15;
$cox_p = 2.3e-15;
$Cov = 0.5e-15;

# Design spec
$Vdd = 2.5;
$Vss = -2.5;
$R_L = 20e3;
$C_L = 250e-15;
$C_in = 220e-15;

# Design requirement
$max_power_total = 2e-3;
#Power <= 2 mW, Vdd to Vss = 5V => Ids_tot = 2mW/5V = 400uA
$Ids_total = 400e-6;
$min_gain = 30e3;
$min_bandwidth = 90e6;

# Design choice
$Ls = [undef, 2e-6, 2e-6, 2e-6, 2e-6, 2e-6, 2e-6, 2e-6, 2e-6, 2e-6, 2e-6]; # all xtors length = 2 to start with
$Vovs = [undef, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]; # pick a typical one, > spec's 150mV requirement

# Design parameters
$Ids_distribution_percent = [undef, 25e-2, 25e-2, 25e-2, 25e-2];
$Ids_branch = [undef];
# % of $Ids_total through each of the 4 branches
push @$Ids_branch, ($Ids_total * $Ids_distribution_percent->[1]);
push @$Ids_branch, ($Ids_total * $Ids_distribution_percent->[2]);
push @$Ids_branch, ($Ids_total * $Ids_distribution_percent->[3]);
push @$Ids_branch, ($Ids_total * $Ids_distribution_percent->[4]);
$A_cg = 5000;
$A_cascode = 5;
$A_CS = 1.2;
$A_CD = 1;

# calculation for M1
$gm1 = compute_gm($Ids_branch->[1], $Vovs->[1]);
$W1 = compute_w($Ids_branch->[1], $kp_n, $Ls->[1], $Vovs->[1]);

# calculation for M2
$gm2 = compute_gm($Ids_branch->[1], $Vovs->[2]);
$W2 = compute_w($Ids_branch->[1], $kp_n, $Ls->[2], $Vovs->[2]);
$Cgs2 = 0; # estimate to be << Cin
$tau_in = ($C_in + $Cgs2) / $gm2;

# calculation for M3
$gm3 = compute_gm($Ids_branch->[1], $Vovs->[3]);
$W3 = compute_w($Ids_branch->[1], $kp_n, $Ls->[3], $Vovs->[3]);

# R1,R2
# R2/R1 < 4, ratio calculated from a voltage divider of Vdd into gate of M4 to keep M4 in saturation
#A_cg = (R1*R2) / (R1 + R2)
$R1 = $A_cg * 5/4;
$R2 = 4 * $R1;

# calculation for M4
$gm4 = compute_gm($Ids_branch->[2], $Vovs->[4]);
$W4 = compute_w($Ids_branch->[2], $kp_p, $Ls->[4], $Vovs->[4]);

# R3/R4 < 4
# A_cascode = - (gm4*R3*R4)/(R3+R4) 
# - sign here, next stage is - again; so overall positive; so just take the magnitude here
$R4 = 25/4 * $gm4;
$R3 = 4 * $R4;

# calculation for M4
$Cgs4 = compute_Cgs($W4, $Ls->[4], $cox_p, $Cov);
$tau_x = ($R1*$R2*$Cgs4) / ($R1 + $R2);

# calculation for M5,M6
$gm5 = compute_gm($Ids_branch->[2], $Vovs->[5]);
$W5 = compute_w($Ids_branch->[2], $kp_p, $Ls->[5], $Vovs->[5]);
$gm6 = compute_gm($Ids_branch->[2], $Vovs->[6]);
$W6 = compute_w($Ids_branch->[2], $kp_n, $Ls->[6], $Vovs->[6]);

# calculation for M7
$gm7 = compute_gm($Ids_branch-[3], $Vovs->[7]);
$W7 = compute_w($Ids_branch->[3], $kp_n, $Ls->[7], $Vovs->[7]);
$tau_y = ($R3*$R4*$Cgs7)/($R3+$R4);

# calculation for M8, M9, M10
$gm8 = compute_gm($Ids_branch-[3], $Vovs->[8]);
$W8 = compute_w($Ids_branch->[3], $kp_p, $Ls->[8], $Vovs->[8]);
$gm10 = compute_gm($Ids_branch-[4], $Vovs->[10]);
$W10 = compute_w($Ids_branch->[4], $kp_n, $Ls->[10], $Vovs->[10]);
$Cgs8 = compute_Cgs($W8, $L8, $cox_p, $Cov);
$tau_z = ($Cgs8 + $Cgs10*(1+$gm10*$R_L))/$gm8;
$tau_out = ($R_L * ($C_L + $Cgs10*(1+(1/$gm10*$R_L)))) / (1 + $gm10*$R_L);

$gm9 = compute_gm($Ids_branch-[4], $Vovs->[9]);
$W9 = compute_w($Ids_branch->[4], $kp_n, $Ls->[9], $Vovs->[9]);

# total tau
$tau_total = $tau_in + $tau_x + $tau_y + $tau_z + $tau_out;
$f_3db = 1/ (2*3.14*$tau_total);

# print summary for this sweep 
print "=======================================================================\n";
printf ("Ids: %22s, %22s, %22s, %22s\n", $Ids_branch->[1],$Ids_branch->[2],$Ids_branch->[3],$Ids_branch->[4]); 
#print "Ids1 = $Ids_branch->[1], Ids2 = $Ids_branch->[2], Ids3 = $Ids_branch->[3], Ids4 = $Ids_branch->[4]\n";
printf ("As: %22s, %22s, %22s, %22s\n", $A_cg, $A_cascode, $A_cs, $A_cd);
#print "A_cg = $A_cg, A_cascode = $A_cascode, A_cs = $A_cs, A_cd = $A_cd\n";
printf ("Ws: %22s, %22s, %22s, %22s, %22s\n", $W1, $W2, $W3, $W4, $W5);
printf ("Ws: %22s, %22s, %22s, %22s, %22s\n", $W6, $W7, $W8, $W9, $W10);
#print "Ws = $W1, $W2, $W3, $W4, $W5, $W6, $W7, $W8, $W9, $W10";
printf ("Rs: %22s, %22s, %22s, %22s\n",$R1, $R2, $R3, $R4);
#print "R1 = $R1, R2 = $R2, R3 = $R3, R4 = $R4\n";
print "f_3db = $f_3db\n";

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

sub compute_w {
   my ($Ids, $kp, $L, $Vov) = @_;
   my $w = 2*$Ids/($kp/$L*($Vov**2));
   return $w;
}
