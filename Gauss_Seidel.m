YBus = zeros(nbus, nbus);

for k = 1:size(linedata, 1)
    from = linedata(k, 1);  
    to = linedata(k, 2);    
    R = linedata(k, 3);     
    X = linedata(k, 4);     
    B = linedata(k, 5);     
    m = linedata(k, 6);     
    
    Z = R + 1j * X;
    Y_series = 1 / Z;
    
    if m ~= 1
        % Transformer case
        Y_series = Y_series / m;
        Yshunt_from = (1/m)*((1/m)-1)*B*1j;
        Yshunt_to = (1-1/m)*B*1j;
    else
        % Regular line case (apply full B at both ends)
        Yshunt_from = B*1j;
        Yshunt_to = B*1j;
    end
    
    % Off-diagonal elements
    YBus(from, to) = YBus(from, to) - Y_series;
    YBus(to, from) = YBus(to, from) - Y_series;
    
    % Diagonal elements
    YBus(from, from) = YBus(from, from) + Y_series + Yshunt_from;
    YBus(to, to) = YBus(to, to) + Y_series + Yshunt_to;
end
tic;

% 1st Step: Per Unit Transformation
for j = 5:11
    busdata(:, j) = busdata(:, j) ./ basemva;
end

% 2nd Step: System Parameter Definition
V = busdata(:, 3);                        % Voltage magnitude
delta = busdata(:, 4) * (pi / 180);       % Voltage angle in radians
Vcompl = V .* (cos(delta) + sin(delta) * 1i);  % Complex voltage form
Pload = busdata(:, 5);                    % Active power load
Qload = busdata(:, 6);                    % Reactive power load
Pgen = busdata(:, 7);                     % Active power generation
Qgen = busdata(:, 8);                     % Reactive power generation
Qmin = busdata(:, 9);                     % Minimum reactive power limit (PV and Slack buses)
Qmax = busdata(:, 10);                    % Maximum reactive power limit (PV and Slack buses)
Qcomp = busdata(:, 11);                   % Reactive power compensation

% 3rd Step: Calculate Line Power
P = Pgen - Pload;
Q = Qgen - Qload + Qcomp;
S = P + Q * 1i;

% 4th Step: Calculation Process (Gauss-Seidel Method)
k = 0;
maxerror = 1;
% Initialize vector to store convergence history (preallocated for maxiter)
error_history = zeros(maxiter+1, 1);

while (maxerror >= accuracy) && (k < maxiter)
    Vold = Vcompl;
    
    for i = 1:nbus
        S1 = YBus(i, 1:i-1) * Vcompl(1:i-1);
        S2 = YBus(i, i+1:nbus) * Vcompl(i+1:nbus);
        
        % PHASE 1: PQ Buses
        if busdata(i, 2) == 0
            I = conj(S(i)) / conj(Vcompl(i));
            Vcompl(i) = (1 / YBus(i, i)) * (I - S1 - S2);
            Vcompl(i) = Vold(i) + accel * (Vcompl(i) - Vold(i));  % Convergence acceleration
            V = abs(Vcompl(i));
            delta = angle(Vcompl(i));
            
        % PHASE 2: PV Buses
        elseif busdata(i, 2) == 2
            Q(i) = -imag(conj(Vcompl(i)) * (YBus(i, :) * Vcompl));
            S(i) = P(i) + Q(i) * 1i;
            I(i) = conj(S(i)) / conj(Vcompl(i));
            delta(i) = angle((1 / YBus(i, i)) * (I(i) - S1 - S2));
            Vcompl(i) = abs(Vold(i)) * (cos(delta(i)) + 1i * sin(delta(i)));
            
        % PHASE 3: Slack Bus
        elseif busdata(i, 2) == 1
            Sc = conj(V(i)) * conj(Vcompl(i)) * (YBus(i, :) * Vcompl(i, :));
            Sc = conj(Sc);
        end
    end
    
    maxerror = max(abs(abs(Vcompl) - abs(Vold)));
    error_history(k+1) = maxerror;  % store error at iteration k
    k = k + 1;
end

% 6th Step: Final Power Calculations
for i = 1:nbus
    S(i) = conj(Vcompl(i)) * (YBus(i, :) * Vcompl);
    P(i) = real(S(i));
    Q(i) = -imag(S(i));
end

% 5th Step: Calculate Missing Parameters for Each Bus
for i = 1:nbus
    % PV Bus
    if busdata(i, 2) == 2
        Qgen(i) = Q(i) + Qload(i) - Qcomp(i);
        
    % PQ Bus: All data already calculated
    % Slack Bus
    elseif busdata(i, 2) == 1
        Pgen(i) = P(i) + Pload(i);
        Qgen(i) = Q(i) + Qload(i);
    end
end

% 7th Step: Update busdata Matrix
busdata(:, 3) = abs(Vcompl);
busdata(:, 4) = angle(Vcompl) * (180 / pi);
busdata(:, 7) = Pgen;
busdata(:, 8) = Qgen;

% 8th Step: Reverse Per Unit Transformation
for j = 5:11
    busdata(:, j) = busdata(:, j) * basemva;
end

% 9th Step: Loss Calculations
PgenTot = sum(busdata(:, 7));
QgenTot = sum(busdata(:, 8));
PloadTot = sum(busdata(:, 5));
QloadTot = sum(busdata(:, 6));
pertes = PgenTot - PloadTot;       % Active power losses
pertesR = QgenTot - QloadTot;      % Reactive power losses
p = (pertes / PgenTot) * 100;      % Percentage of active power losses
busdata = abs(busdata);

% 10th Step: Display Results
fprintf('Le nombre d''itérations : %8.4g \n\n\n', k);

disp(' ||  Bus  ||  Code  ||    V    ||   Angle   ||         Load         ||        Generator      ||');
disp(' ||  N    ||        ||   pu    ||   Degree  ||     MW   |   MVAR    ||     MW     |   MVAR   ||');

for i = 1:nbus
    fprintf('    %3g         %g    %8.4f    %8.4f     %8.3f   %8.3f      %8.3f    %8.3f\n', ...
            busdata(i, 1), busdata(i, 2), busdata(i, 3), busdata(i, 4), ...
            busdata(i, 5), busdata(i, 6), busdata(i, 7), busdata(i, 8));
end

fprintf('\nTotal                              %8.3f   %8.3f      %8.3f    %8.3f\n\n\n', ...
        abs(PloadTot), abs(QloadTot), abs(PgenTot), abs(QgenTot));

fprintf('Les pertes actives %8.4f Mw\n', abs(pertes));
fprintf('Les pertes reactives: %8.2f MVAr\n', abs(pertesR));
fprintf('Le pourcentage des pertes active:%8.2f %%\n', abs(p));
disp('--------------------------------------------------------------------------------------------------------------');
disp('--------------------------------------------------------------------------------------------------------------');

elapsedTime = toc;
fprintf('Le temps de calcul est de %.6f secondes.\n', elapsedTime);

% Figure 1: Bus voltage bar plot
figure(1);
bar(busdata(:,1), busdata(:,3), 'FaceColor', [0.3, 0.75, 0.93]);
grid on;
title('Bus Voltage Profile');
xlabel('Bus Number');
ylabel('Voltage (p.u.)');

% Figure 2: Convergence plot
figure(2);
semilogy(1:k, error_history(1:k), 'b-o', 'LineWidth', 2);
grid on;
title('Convergence Gauss Seidel');
xlabel('Iteration');
ylabel('Max Voltage Error');
xlim([1, length(error_history)]);