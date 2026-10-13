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
% Get original bus numbers before reorganization
original_bus_numbers = busdata(:,1);

% Reorganize bus data by type (Slack, PV, PQ)
SB = find(busdata(:,2) == 1);
PV = find(busdata(:,2) == 2);
PQ = find(busdata(:,2) == 0);

% Create the new order
ordre = [SB; PV; PQ];
Newbusdata = busdata(ordre,:);

% CRITICAL FIX: Reorganize YBus according to the new bus order
% Map original bus numbers to new positions
bus_mapping = zeros(max(original_bus_numbers), 1);
for i = 1:length(ordre)
    original_bus_num = original_bus_numbers(ordre(i));
    bus_mapping(original_bus_num) = i;
end

% Reorganize YBus matrix according to the new bus order
YBus_reordered = zeros(size(YBus));
for i = 1:length(ordre)
    for j = 1:length(ordre)
        original_i = original_bus_numbers(ordre(i));
        original_j = original_bus_numbers(ordre(j));
        YBus_reordered(i,j) = YBus(original_i, original_j);
    end
end
YBus = YBus_reordered;

% Convert to per unit values
Newbusdata(:,5:11) = Newbusdata(:,5:11) ./ basemva;

% Initialize voltage phasors
delta = Newbusdata(:,4) * (pi/180);
Vcompl = Newbusdata(:,3) .* (cos(delta) + 1i*sin(delta));

% Extract YBus components
G = real(YBus);
B = -imag(YBus);

% Load and generation data
Pload = Newbusdata(:,5);
Qload = Newbusdata(:,6);
Pgen = Newbusdata(:,7);
Qgen = Newbusdata(:,8);
Qmin = Newbusdata(:,9);
Qmax = Newbusdata(:,10);
Qcomp = Newbusdata(:,11);

% Specified values for power flow
Pspec = Pgen(2:end) - Pload(2:end);
Qspec = Qgen(npv+2:end) - Qload(npv+2:end) + Qcomp(npv+2:end);
V2spec = abs(Vcompl(2:npv+1)).^2;
Fspec = [Pspec; Qspec; V2spec];

% Initialize variables
e = real(Vcompl);
f = imag(Vcompl);
delta_e = zeros(nbus-1,1);
delta_f = zeros(nbus-1,1);
Pcal = zeros(nbus-1,1);
Qcal = zeros(npq,1);
V2cl = zeros(npv,1);
Fcal = zeros(2*(npq+npv));
F = zeros(2*(npv+npq));

% Initialize Jacobian submatrices
J1 = zeros(nbus,nbus);
J2 = zeros(nbus,nbus);
J3 = zeros(nbus,nbus);
J4 = zeros(nbus,nbus);
J5 = zeros(nbus,nbus);
J6 = zeros(nbus,nbus);

% Newton-Raphson iteration
erreur = 10;
k = 0;
mismatch_history = [];  % Array to track convergence
while (erreur > accuracy && k < maxiter)
    % Calculate power injections
    for i = 2:nbus
        Pcal(i-1) = e(i)*(G(i,:)*e + B(i,:)*f) + f(i)*(G(i,:)*f - B(i,:)*e);
    end
    
    for i = (npv+2):nbus
        Qcal(i-(npv+1)) = f(i)*(G(i,:)*e + B(i,:)*f) - e(i)*(G(i,:)*f - B(i,:)*e);
    end
    
    for i = 2:npv+1
        V2cl(i-1) = e(i)^2 + f(i)^2;
    end
      % Calculate mismatches
    Fcal = [Pcal; Qcal; V2cl];
    F = Fspec - Fcal;
    
    % Store current mismatch for convergence plot
    current_mismatch = max(abs(F));
    mismatch_history = [mismatch_history; current_mismatch];
    
    % Build Jacobian matrix
    for i = 1:nbus
        for j = 1:nbus
            if i == j
                J1(i,j) = e(i)*G(i,i) - f(i)*B(i,i) + G(i,:)*e + B(i,:)*f;
                J2(i,j) = e(i)*B(i,i) + f(i)*G(i,i) + G(i,:)*f - B(i,:)*e;
                J3(i,j) = e(i)*B(i,i) + f(i)*G(i,i) - (G(i,:)*f - B(i,:)*e);
                J4(i,j) = -(e(i)*G(i,i) - f(i)*B(i,i)) + G(i,:)*e + B(i,:)*f;
                J5(i,j) = 2*e(i);
                J6(i,j) = 2*f(i);
            else
                J1(i,j) = e(i)*G(i,j) - f(i)*B(i,j);
                J2(i,j) = e(i)*B(i,j) + f(i)*G(i,j);
                J3(i,j) = e(i)*B(i,j) + f(i)*G(i,j);
                J4(i,j) = -(e(i)*G(i,j) - f(i)*B(i,j));
                J5(i,j) = 0;
                J6(i,j) = 0;
            end
        end
    end
    
    % Extract relevant parts of Jacobian
    J1 = J1(2:nbus, 2:nbus);
    J2 = J2(2:nbus, 2:nbus);
    J3 = J3((npv+2):nbus, 2:nbus);
    J4 = J4((npv+2):nbus, 2:nbus);
    J5 = J5(2:(npv+1), 2:nbus);
    J6 = J6(2:(npv+1), 2:nbus);
    
    % Solve for voltage updates
    J = [J1 J2; J3 J4; J5 J6];
    K = J\F;
    
    delta_e = K(1:(nbus-1));
    delta_f = K(nbus:(2*(nbus-1)));
    
    % Update voltages
    e(2:nbus) = e(2:nbus) + delta_e;
    f(2:nbus) = f(2:nbus) + delta_f;
    
    k = k + 1;
    erreur = max(abs(F));
end

% Final voltage phasors
Vcompl = e + 1i*f;

% CORRECTED: Calculate power injections for all buses using the unified method
S_inj = Vcompl .* conj(YBus * Vcompl);
Pgen = real(S_inj) + Pload;
Qgen = imag(S_inj) + Qload - Qcomp;

% Update angles
delta = angle(Vcompl);

% Update Newbusdata with results
Newbusdata(:,3) = abs(Vcompl);
Newbusdata(:,4) = delta * (180/pi);
Newbusdata(:,7) = Pgen;
Newbusdata(:,8) = Qgen;
Newbusdata(:,5) = Pload;
Newbusdata(:,6) = Qload;

% Convert back to original units
Newbusdata(:,5:11) = Newbusdata(:,5:11) .* basemva;

% Calculate power losses
PgenTot = sum(Newbusdata(:,7));
QgenTot = sum(Newbusdata(:,8));
PloadTot = sum(Newbusdata(:,5));
QloadTot = sum(Newbusdata(:,6));

pertes = PgenTot - PloadTot;        % Active power losses
pertesR = QgenTot - QloadTot;       % Reactive power losses
p = (pertes/PgenTot)*100;           % Percentage of active power losses

% Display results
fprintf('Nombre d\\''itérations : %8.4g \n\n\n', k);
disp(' ||  Noeud  ||  Type  ||    V    ||   Angle   ||         Charge         ||        Génération      ||');
disp(' ||  N      ||        ||   pu    ||   Degré   ||     MW   |   MVAR    ||     MW     |   MVAR   ||');

for i = 1:nbus
    fprintf('    %3g', Newbusdata(i,1));
    fprintf('         %g', Newbusdata(i,2));
    fprintf('    %8.4f', Newbusdata(i,3));
    fprintf('    %8.4f', Newbusdata(i,4));
    fprintf('     %8.3f', Newbusdata(i,5));
    fprintf('   %8.3f', Newbusdata(i,6));
    fprintf('      %8.3f', Newbusdata(i,7));
    fprintf('    %8.3f', Newbusdata(i,8));
    fprintf('\n');
end

fprintf('\nTotal                          ');
fprintf('               %8.3f', abs(PloadTot));
fprintf('   %8.3f', abs(QloadTot));
fprintf('      %8.3f', abs(PgenTot));
fprintf('    %8.3f', abs(QgenTot));
fprintf('\n\n\n');

fprintf('Pertes actives : %8.4f MW\n', abs(pertes));
fprintf('Pertes réactives : %8.2f MVAr\n', abs(pertesR));
fprintf('Pourcentage de pertes actives : %8.2f%%\n', abs(p));
disp('--------------------------------------------------------------------------------------------------------------');
disp('--------------------------------------------------------------------------------------------------------------');

elapsedTime = toc;
fprintf('Temps de calcul : %.6f secondes.\n', elapsedTime);

% Create figure for bus voltage profile
figure;
bar(Newbusdata(:,1), Newbusdata(:,3), 'FaceColor', [0.2 0.6 0.8]);
xlabel('Bus Number');
ylabel('Voltage Magnitude (p.u.)');
title('Bus Voltage Profile');
grid on;
ylim([min(Newbusdata(:,3))*0.95, max(Newbusdata(:,3))*1.05]);  % Set y-axis limits with 5% margin

% Create figure for convergence
figure;
semilogy(1:length(mismatch_history), mismatch_history, '-o', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Maximum Mismatch |ΔP, ΔQ|');
title('Newton-Raphson Convergence');
grid on;