% 	DONNEES DU RESEAU ETUDIE ; Filename : "system11bus.m"
%
nbus=11; %Nombre total de noeuds
npq=8;  %Nombre de noeuds PQ
npv=2;  %Nombre de noeuds PV
ns=1;   %Num�ro du noeud slack bus
nbr=14;  %Nombre total de branches

basemva = 100;  accuracy = 0.001; accel = 1.8; maxiter = 100;

%   
%	Donnees de noeuds
%	-----------------
%      Bus Bus Voltage Angle --Load--        --Generator--      Injected
%       No Code Mag. degree MW       Mvar    MW       Mvar   Qmin Qmax Mvar
busdata=[1  1  1.040   0.0    0.00    0.00    0.00   0.00   0    0  0
         2  0  1.0     0.0    0.00    0.00    0.00   0.00   0    0  0
         3  0  1.0     0.0  150.00  120.00    0.00   0.00   0    0  0
         4  0  1.0     0.0    0.00    0.00    0.00   0.00   0    0  0
         5  0  1.0     0.0  120.00   60.00    0.00   0.00   0    0  0
         6  0  1.0     0.0  140.00   90.00    0.00   0.00   0    0  0
         7  0  1.0     0.0    0.00    0.00    0.00   0.00   0    0  0
         8  0  1.0     0.0  110.00   90.00    0.00   0.00   0    0  0
         9  0  1.0     0.0   80.00   50.00    0.00   0.00   0    0  0
         10 2  1.035   0.0    0.00    0.00  200.00   0.00   0  180  0
         11 2  1.030   0.0    0.00    0.00  160.00   0.00   0  120  0];
%
%	Donnees de lignes
%	-----------------
%        Bus Bus  R      X       B/2    1 for line code or
%        nl  nr   pu     pu       pu    tap setting value
linedata=[1  2   0.000   0.006   0.000   1.0
          2  3   0.008   0.030   0.004   1.0
          2  5   0.004   0.015   0.002   1.0
          2  6   0.012   0.045   0.005   1.0
          3  4   0.010   0.040   0.005   1.0
          3  6   0.004   0.040   0.005   1.0
          4  6   0.015   0.060   0.008   1.0
          4  9   0.018   0.070   0.009   1.0
          4  10  0.000   0.008   0.000   1.0
          5  7   0.005   0.043   0.003   1.0
          6  8   0.006   0.048   0.000   1.0
          7  8   0.006   0.035   0.004   1.0
          7  11  0.000   0.010   0.000   1.0
          8  9   0.005   0.048   0.000   1.0];
%
%	Donnees de machines
%	-------------------
%         Gen.  Ra   Xd'    H
gendata=[ 1     0   0.20    12
          10    0   0.15    10
          11    0   0.25    9 ];

