
% SYSTEM DATA "system10bus.m"
% ***********************
%
nbus=10; %Nombre total de noeuds
npq=8;  %Nombre de noeuds PQ
npv=1;  %Nombre de noeuds PV
ns=1;   %Num�ro du noeud slack bus
nbr=9;  %Nombre total de branches

basemva = 100;  accuracy = 0.001; accel = 1.8; maxiter = 100;
%
%	Donnees de noeuds
%	-----------------
%          No Code  VMag  Vangle   Pg      Qg     Pl     Ql  
%        Bus Bus Voltage Angle    --Load--     --Generator--      Injected
%        No Code   Mag. degree   MW     Mvar    MW     Mvar  Qmin Qmax Mvar
busdata=[1   0   1.000   0.00   57.00   37.00   0.00   0.00    0    0    0 
         2   0   1.000   0.00  -93.00   30.00   0.00   0.00    0    0    0 
         3   0   1.000   0.00   70.00   30.00   0.00   0.00    0    0    0 
         4   0   1.000   0.00   -4.00  -40.00   0.00   0.00    0    0    0 
         5   0   1.000   0.00    2.40   48.00   0.00   0.00    0    0    0 
         6   0   1.000   0.00   25.00   -1.30   0.00   0.00    0    0    0 
         7   0   1.000   0.00   41.00  -18.00   0.00   0.00    0    0    0 
         8   0   1.000   0.00   -6.30   11.00   0.00   0.00    0    0    0 
         9   2   0.960   0.00    0.00    0.00  36.00   0.00    0    0    0 
         10  1   0.980   0.00    0.00    0.00   0.00   0.00    0    0    0];
      
%      
%	Donnees de lignes
%	-----------------
%        Bus Bus   R     X      B/2  1 for line code or
%        nl  nr   pu     pu      pu  tap setting value
linedata=[1  2   0.002  0.009  0.014   1.000
          1  10  0.008  0.032  0.029   1.000
          2  3   0.003  0.009  0.014   1.000
          4  5   0.020  0.070  0.000   0.967
          5  6   0.040  0.096  0.210   1.000
          6  9   0.030  0.067  0.004   1.000
          7  8   0.007  0.016  0.012   1.000
          7  9   0.090  0.270  0.000   0.917
          8  10  0.018  0.036  0.014   1.000];
  
%
%	Donnees de machines
%	-------------------
%         Gen.  Ra   Xd'    H
gendata=[ 9     0   0.20   20
          10    0   0.25    5];

