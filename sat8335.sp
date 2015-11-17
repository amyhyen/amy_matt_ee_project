
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
   .param W1_val = 20u
.param L1_val = 5u
.param W2_val = 10u 
.param L2_val = 2u
.param W3_val = 20u
.param L3_val = 10u
.param W4_val = 2u
.param L4_val = 2u
.param W5_val = 20u
.param L5_val = 2u
.param W6_val = 7u
.param L6_val = 3u
.param W7_val = 2u
.param L7_val = 2u
.param W8_val = 20u
.param L8_val = 2u
.param W9_val = 20u
.param L9_val = 2u
.param W10_val = 9u
.param L10_val = 2u
.param R1_val = 60k
.param R2_val = 50k
.param R3_val = 100k
.param R4_val = 600k
.param Vbias_n_val = -1.600000
.param Vbias_p_val = 1.20

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
   Cin    n_in    0    'p_Cin'
   
   * Defining the load 
   RL    n_vout     0          'p_RL'
   CL    n_vout     0          'p_CL'
   
   *** Your Trans-impedance Amplifier here ***
   ***     d       g       s       b       n/pmos114       w       l
   * nmos b tied to lowest voltage
   * pmos b tied to highest voltage (or s)
   *** Vx/Iin = V(n_x) / Iin, use "n_x" as the node label for Vx ***
   MN1    n_in    n_nbias      n_vss    n_vss    nmos114 w='W1_val'  l='L1_val'
   MN2    n_x     0         n_in     n_vss    nmos114 w='W2_val'  l='L2_val'
   MP3    n_x    n_pbias      n_vdd    n_vdd    pmos114 w='W3_val'  l='L3_val'
   R1     n_x    n_vdd      'R1_val'
   R2     n_x    0          'R2_val'
   
   *** Vy/Vx = V(n_y) / V(n_x) use "n_y" as the node label for Vy ***
   MP4    n_4d    n_x      n_vdd    n_vdd    pmos114 w='W4_val'  l='L4_val'
   MP5    n_y    0          n_4d    n_4d    pmos114 w='W5_val'  l='L5_val'
   MN6    n_y    n_nbias      n_vss    n_vss    nmos114 w='W6_val'  l='L6_val'
   R3     n_y    0          'R3_val'
   R4     n_y    n_vss      'R4_val'
   
   *** Vz/Vy = V(n_z) / V(n_y) use "n_z"" as the node label for Vz ***
   MN7    n_z    n_y      n_vss    n_vss    nmos114 w='W7_val'  l='L7_val'
   MP8    n_z    n_z      n_vdd    n_vdd    pmos114 w='W8_val'  l='L8_val'
   
   *** Vout/Vz = V(n_vout) / V(n_z) use "n_vout" as the node label for Vout ***
   MN9    n_vout    n_nbias  n_vss    n_vss        nmos114 w='W9_val'  l='L9_val'
   MN10   n_vdd    n_z      n_vout    n_vss    nmos114 w='W10_val'  l='L10_val'
   
   *** Your Bias Circuitry goes here ***
   * TBD: ideal current source for now
   * TBD: fill in the bias current value from calculating Ids through M3 and M1,6,9 in saturation
   Vbn n_nbias 0 dc='Vbias_n_val'
   VBp n_pbias 0 dc='Vbias_p_val'
   
   *** defining the analysis ***
   .op
   .option post brief nomod
   
   ** For ac simulation uncomment the following line** 
   .ac dec 1k 100 1g
   .measure ac gainmax_vout max vdb(n_vout)
   .measure ac f3db_vout when vdb(n_vout)='gainmax_vout-3'
   
   .measure ac gainmax_vx max vdb(n_x)
   .measure ac f3db_vx when vdb(n_x)='gainmax_vx-3'
   
   .measure ac gainmax_vy max vdb(n_y)
   .measure ac f3db_vy when vdb(n_y)='gainmax_vy-3'
   
   .measure ac gainmax_vz max vdb(n_z)
   .measure ac f3db_vz when vdb(n_z)='gainmax_vz-3'
   
   ** For transient simulation uncomment the following line **
   *.tran 0.01u 4u 
   
   .end
   
