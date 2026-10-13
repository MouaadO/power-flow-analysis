% system3bus.m
% DONNEES DU RESEAU ETUDIE
%
nbus=3; %Nombre total de noeuds
npq=1;  %Nombre de noeuds PQ
npv=1;  %Nombre de noeuds PV
ns=1;   %Num�ro du noeud slack bus
nbr=3;  %Nombre total de branches

basemva = 100;  accuracy = 0.0001;  accel = 1.8; maxiter = 100;
%
%
% Donnees de noeuds
%      Bus Bus Voltage Angle --Load--        --Generator--      Injected
%       No Code Mag. degree MW       Mvar    MW       Mvar   Qmin Qmax Mvar
busdata=[1  1  1.05   0.0  00.00    00.00    0.00    00.00     0     0    0
         2  0  1.00   0.0 400.00   250.00   00.00    00.00     0     0    0
         3  2  1.04   0.0  00.00    00.00  200.00    00.00     0     0    0];

% Donnees de lignes
%        Bus Bus  R      X       B/2   1 for line code or
%        nl  nr   pu     pu       pu    tap setting value
linedata=[1  2  0.020   0.040   0.0000   1.0
          1  3  0.010   0.030   0.0000   1.0
          2  3  0.0125  0.025   0.0000   1.0];


   