
%	system9bus.m
%

nbus=9; %Nombre totale de noeuds
npq=6;  %Nombre de noeuds PQ
npv=2;  %Nombre de noeuds PV
ns=1;   %Num�ro du noeud slack bus
nbr=9;  %Nombre totale de branches

%    Puissance de base et Tol�rances
%    -------------------------------
basemva = 100;  accuracy = 0.001; accel = 1.8; maxiter = 100;

%    Donn�es de noeuds
%    
 
 %                                   - Load -        - Gen -               Injected
 %      Bus  Bus   Voltage Angle    Pl      Ql      Pg      Qg 
 %      No   Code   Mag.   degree   MW     MVAR     MW     MVAR  Qmin  Qmax  MVAR
busdata=[1    1    1.040   0.00    0.00    0.00     0.00    0.00   0    0     0
         2    2    1.025   9.30    0.00    0.00   163.00    6.70   0    0     0
         3    2    1.025   4.70    0.00    0.00    85.00  -10.90   0    0     0
         4    0    1.000   0.00    0.00    0.00     0.00    0.00   0    0     0
         5    0    1.000   0.00  125.00   50.00     0.00    0.00   0    0     0
         6    0    1.000   0.00   90.00   30.00     0.00    0.00   0    0     0
         7    0    1.000   0.00    0.00    0.00     0.00    0.00   0    0     0
         8    0    1.000   0.00  100.00   35.00     0.00    0.00   0    0     0
         9    0    1.000   0.00    0.00    0.00     0.00    0.00   0    0     0] ;
 
%    Donn�es des lignes
% 
%        Bus Bus  R       X      B/2    1 for line code or
%         nl nr   pu      pu      pu    tap setting value
linedata=[1  4  0.0000  0.0576  0.0000   0.920
          2  7  0.0000  0.0625  0.0000   0.921
          3  9  0.0000  0.0586  0.0000   0.940
          4  5  0.0100  0.0850  0.0880   1.000
          4  6  0.0170  0.0920  0.0790   1.000
          5  7  0.0320  0.1610  0.1530   1.000
          6  9  0.0390  0.1700  0.1790   1.000
          7  8  0.0085  0.0720  0.0745   1.000
          8  9  0.0119  0.1008  0.1045   1.000];

 %    Donn�es de Machines
 % 
 %                 Gen.     Ra    Xd'        H        
 %                  #       pu    pu         s      
          gendata=[ 1       0     0.0668    23.64 
                    2       0     0.1198     6.4   
                    3       0     0.1813     3.01 ];