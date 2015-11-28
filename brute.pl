$W1 = [15];
$L1 = [2];
$W2 = [19];
$L2 = [2];
$W3 = [28];
$L3 = [2];
$W4 = [6];
$L4 = [2];
$W5 = [4];
$L5 = [2];
$W6 = [2];
$L6 = [2];
$W7 = [2];
$L7 = [2];
$W8 = [3];
$L8 = [2];
$W9 = [30];
$L9 = [2];
$W10 = [30];
$L10 = [2];
$R1 = [22000];
$R2 = [24000];
$R3 = [55000];
$R4 = [96500];
$Vp = [1.4];
$Vn = [-1.3425];

# Init things
$W = [undef, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
$L = [undef, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
$R = [1000, 1000, 1000, 1000];
$iter = 0;

# Delete old files
system ("rm -rf lis*");
system ("rm -rf iter*");
system ("rm -rf archive_brute");
system ("rm -rf results.csv");
system ("touch results.csv");


foreach (@$Vn) {
 my $vn = $_;
 foreach (@$Vp) {
  my $vp = $_;
  foreach (@$R4) {
   my $r4 = $_;
   foreach (@$R3) {
    my $r3 = $_;
    foreach (@$R2) {
     my $r2 = $_;
     foreach (@$R1) {
      my $r1 = $_;
      foreach (@$L10) {
       my $l10 = $_;
       foreach (@$W10) {
        my $w10 = $_;
        foreach (@$L9) {
         my $l9 = $_;
         foreach (@$W9) {
          my $w9 = $_;
          foreach (@$L8) {
           my $l8 = $_;
           foreach (@$W8) {
            my $w8 = $_;
            foreach (@$L7) {
             my $l7 = $_;
             foreach (@$W7) {
              my $w7 = $_;
              foreach (@$L6) {
               my $l6 = $_;
               foreach (@$W6) {
                my $w6 = $_;
                foreach (@$L5) {
                 my $l5 = $_;
                 foreach (@$W5) {
                  my $w5 = $_;
                  foreach (@$L4) {
                   my $l4 = $_;
                   foreach (@$W4) {
                    my $w4 = $_;
                    foreach (@$L3) {
                     my $l3 = $_;
                     foreach (@$W3) {
                      my $w3 = $_;
                      foreach (@$L2) {
                       my $l2 = $_;
                       foreach (@$W2) {
                        my $w2 = $_;
                        foreach (@$L1) {
                         my $l1 = $_;
                         foreach (@$W1) {
                          my $w1 = $_;
                          $W = [undef, $w1, $w2, $w3, $w4, $w5, $w6, $w7, $w8, $w9, $w10];
                          $L = [undef, $l1, $l2, $l3, $l4, $l5, $l6, $l7, $l8, $l9, $l10];
                          $R = [undef, $r1, $r2, $r3, $r4];
                          test($W, $L, $R, $vp, $vn, $iter);
                          evaluate($iter);
                          $iter++;
                         }
                        }
                       }
                      }
                     }
                    }
                   }
                  }
                 }
                }
               }
              }
             }
            }
           }
          }
         }
        }
       }
      }
     }
    }
   }
  }
 }
}

system ("mkdir archive_brute");
system ("mv lis* archive_brute");
system ("mv iter* archive_brute");

sub test {
   my ($W, $L, $R, $Vp, $Vn, $iter) = @_;
   
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
   $str .= sprintf("\n");
   for (my $i = 1; $i <= 10 ; $i++) {
   	$str .= sprintf(".param W%i_val = %iu\n", $i, sprintf($W->[$i]));
   	$str .= sprintf (".param L%i_val = %iu\n", $i, sprintf($L->[$i]));
   }
   $str .= sprintf(".param R1_val = %ik\n", sprintf($R->[1]/1000));
   $str .= sprintf(".param R2_val = %ik\n", sprintf($R->[2]/1000));
   $str .= sprintf(".param R3_val = %ik\n", sprintf($R->[3]/1000));
   $str .= sprintf(".param R4_val = %ik\n", sprintf($R->[4]/1000));
   
   $str .= sprintf(".param Vbias_p_val = %f\n", sprintf($Vp));
   $str .= sprintf(".param Vbias_n_val = %f\n", sprintf($Vn));
   
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
   
   * Bias Circuitry - Vb_p
   .param W11_val = 30u
   .param L11_val = 2u
   .param W12_val = 30u
   .param L12_val = 2u
   .param W13_val = 2u
   .param L13_val = 7u
   .param R11_val = 500k
   .param R12_val = 650k
   MN11   b_n_d11       b_n_g11       0     0  nmos114 w=\'W11_val\' l=\'L11_val\'
   MN12   n_pbias_float b_n_d11       b_n_g11   0  nmos114 w=\'W12_val\' l=\'L12_val\'
   MP13   n_pbias_float n_pbias_float n_vdd     n_vdd  pmos114 w=\'W13_val\' l=\'L13_val\'
   R11    n_vdd         b_n_d11       \'R11_val\'
   R12    b_n_g11       0         \'R12_val\'
   
   * Bias Circuitry - Vb_n
   .param W14_val = 30u
   .param L14_val = 2u
   .param W15_val = 20u
   .param L15_val = 2u
   .param W16_val = 2u
   .param L16_val = 2u
   .param R13_val = 50k
   .param R14_val = 500k
   MP14   b_n_d14       b_n_g14       0     n_vdd  pmos114 w=\'W14_val\' l=\'L14_val\'
   MP15   n_nbias_float b_n_d14       b_n_g14   n_vdd  pmos114 w=\'W15_val\' l=\'L15_val\'
   MN16   n_nbias_float n_nbias_float n_vss     n_vss  nmos114 w=\'W16_val\' l=\'L16_val\'
   R13    b_n_d14       n_vss       \'R13_val\'
   R14    0             b_n_g14         \'R14_val\'

   
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
   my $cmd = `hspice iter${iter}.sp >& lis${iter}`;
}

sub evaluate {
   my ($iter) = @_; 
    # Count up sats
   $sats = count_sat($iter);
   if ($sats==16) {
	print_stats($iter);
   }
   else {
	system ("rm iter${iter}.*");
        system ("rm lis${iter}");
   }
   
   
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

sub count_sat {
  my ($iter) = @_;
  my $count = `grep -o \'Saturati\' lis${iter} | wc -l`;
  return $count;
}

sub print_stats {
   my ($iter) = @_;
   my $gain = `cat lis${iter} | grep gainmax_vout | awk -F\"vout=\" \'{print substr(\$2,3,14)}\' | tr -d \'\\012\\015\'`;
   my $BW = `cat lis${iter} | grep f3db_vout | awk -F\"vout=\" \'{print substr(\$2,3,14)}\' | tr -d \'\\012\\015\'`;
   my $pwr = `cat lis${iter} | grep \'total voltage source power dissipation\' | awk -F"=" '{print substr(\$2,3,14)}' | tr -d \'\\012\\015\'`;
   $gain =~ s/at$//;
   $pwr =~ s/m/E-3/;
   $BW =~ s/x/E6/;
   my $n_vout = `cat lis${iter} | grep n_vout | awk -F"n_vout  =" '{print substr(\$2,3,10)}' | tr -d \'\\012\\015\'`;
   $n_vout =~ s/m/E-3/;
# `cat lis${iter} | grep n_vout | sed -e 's/.\+n_vout\s\+=\(.\+\)m/\1E-3/'`;

   my $log = "gain, ${gain}, BW, ${BW}, pwr, ${pwr}, n_vout, ${n_vout}, iter, ${iter}\n";
   print $log;
   open(my $file, ">>results.csv");
   print $file "${log}";
   
   return;
   
}

sub parse_spice_output {
   my ($iter) = @_;
   my $spice_ids = [];
   open (F, "<", "lis${iter}") || die "cannot open lis${iter} for read\n";
   my @lines = <F>; my $line;
   for (my $i = 0; $i < scalar (@lines); $i++) {
      $line = $lines[$i];
      chomp $line;
      if ($line =~ /^\s+\*+\s+mosfets$/) {
          $i++;
          $line = $lines[$i];
          chomp $line;
          while ($line !~ /^\s+\*+\s+$/) {
             if ($line =~ /\s+id\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
                $spice_ids->[1] = $1;
                $spice_ids->[2] = $2;
                $spice_ids->[3] = $3;
                $spice_ids->[4] = $4;
                $spice_ids->[5] = $5;
                $spice_ids->[6] = $6;
             }
             $i++;
             $line = $lines[$i];
             chomp $line;
          }
      }
   }
   return $spice_ids;
}
sub compute_w {
   my ($Ids, $kp, $L, $Vov) = @_;
   my $w = 2*$Ids / ($kp/$L*($Vov**2));
   if ($w < 2e-6 || $w > 1e-2) {
       return 0;
   }
   return $w;
}
