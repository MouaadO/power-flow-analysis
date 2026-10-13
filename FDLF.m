%FAST DECOUPLED LOAD FLOW 

Ybus = zeros(nbus, nbus);
% Extraction des données
bus_depart = linedata(:,1);
bus_arrive = linedata(:,2);
R = linedata(:,3);
X = linedata(:,4);
B = linedata(:,5);
tap_setting = linedata(:,6);
Z = R + 1j * X;
Y = 1 ./ (Z .* tap_setting);
% les elements non diagonaux Yij= -yij
for k = 1:nbr
    i = bus_depart(k);
    j = bus_arrive(k);
    Ybus(i, j) =- Y(k);
    Ybus(j, i) =- Y(k);
end
% Les elements diagonaux 
for i = 1:nbus
    condition = (bus_depart == i) | (bus_arrive == i);
    shunt = sum(1j * B .* condition);
    
    trans_corr = sum((1 ./ Z(tap_setting ~= 1)) .* ...
        ((bus_arrive(tap_setting ~= 1) == i) .* (-1 ./ tap_setting(tap_setting ~= 1) + 1) + ...
         (bus_depart(tap_setting ~= 1) == i) .* ((1 ./ tap_setting(tap_setting ~= 1) - 1) ./ tap_setting(tap_setting ~= 1))));
    
    Ybus(i, i) = -sum(Ybus(:, i)) + shunt + trans_corr;
end
clc;
% Réorganisation des données : Slack → PV → PQ
SlackBus = find(busdata(:,2) == 1);
PVbus   = find(busdata(:,2) == 2);
PQbus   = find(busdata(:,2) == 0);

% Create a reordered list of buses
bus_order = [SlackBus; PVbus; PQbus];

% Reorder data
Nbusdata = busdata(bus_order,:);

% Reorder Ybus
Ybus_new = Ybus(bus_order, bus_order);

% Update bus numbers
nbus_new = length(bus_order);  % Use actual number of buses after reordering
Ybus = Ybus_new;
nbus = nbus_new;% Conversion en pu
for j = 5:11
    Nbusdata(:,j) = Nbusdata(:,j) ./ basemva;
end

% Initialisation des variables
V = Nbusdata(:,3);
delta = Nbusdata(:,4)*(pi/180);
Vcompl = V .* (cos(delta) + 1i*sin(delta));

Pload = Nbusdata(:,5);
Qload = Nbusdata(:,6);
Pgen  = Nbusdata(:,7);
Qgen  = Nbusdata(:,8);
Qmin  = Nbusdata(:,9);
Qmax  = Nbusdata(:,10);
Qcomp = Nbusdata(:,11);

G = real(Ybus);
B = -imag(Ybus);
% Pour traçage
liste_erreurs = [];    % Pour convergence

Pspec = Pgen(2:end) - Pload(2:end);
Qspec = Qgen(npv+2:end) - Qload(npv+2:end) + Qcomp(npv+2:end);
Vspec = Vcompl(2:npv+1);
Fspec = [Pspec; Qspec; Vspec];
tic;  % Début du chronomètre
% Initialisations pour l'algorithme
P = zeros(nbus,1); Q = zeros(nbus,1);
Pcal = zeros(nbus-1,1); Qcal = zeros(npq,1); vcal = zeros(npv,1);
F = zeros(2*(npv+npq),1);

% Jacobiennes
J1 = B(2:nbus, 2:nbus);
J4 = B(npv+2:nbus, npv+2:nbus);
invJ1 = inv(J1); invJ4 = inv(J4);

maxerreur = 1; k = 0;

while (maxerreur > 0.001 && k < maxiter)
    for i = 1:nbus
        P(i) = V(i) * sum( V .* (G(i,:)'.*cos(delta - delta(i)) + B(i,:)'.*sin(delta - delta(i))) );
        Q(i) = -V(i) * sum( V .* (G(i,:)'.*sin(delta - delta(i)) - B(i,:)'.*cos(delta - delta(i))) );
    end

    Pcal = P(2:nbus);
    Qcal = Q(npv+2:nbus);
    vcal = V(2:npv+1);
    Fcal = [Pcal; Qcal; vcal];
    F = Fspec - Fcal;

    % Correction vectorielle
    delta_corr = invJ1 * ((Pspec - Pcal) ./ V(2:end));
    dV_corr = invJ4 * ((Qspec - Qcal) ./ V(npv+2:end));

    % Mise à jour
    delta(2:end) = delta(2:end) + delta_corr;
    V(npv+2:end) = V(npv+2:end) + dV_corr;

    maxerreur = max(abs(F));
    liste_erreurs = [liste_erreurs; maxerreur];

    k = k + 1;
end

Vcompl = V .* (cos(delta) + 1i*sin(delta));

% Mise à jour des puissances générées
Pgen(1) = real(conj(Vcompl(1)) * Ybus(1,:) * Vcompl);
Qgen(1) = -imag(conj(Vcompl(1)) * Ybus(1,:) * Vcompl);

Qgen(2:(npv+1)) = Qload(2:(npv+1)) - imag(conj(Vcompl(2:(npv+1))) .* (Ybus(2:(npv+1), :) * Vcompl));

% Mise à jour finale de Nbusdata
Nbusdata(:,3) = abs(Vcompl);
Nbusdata(:,4) = delta * (180/pi);
Nbusdata(:,7) = Pgen;
Nbusdata(:,8) = Qgen;
Nbusdata(:,5) = Pload;
Nbusdata(:,6) = Qload;

% Retour à MW et MVAr
for j = 5:11
    Nbusdata(:,j) = Nbusdata(:,j) * basemva;
end
% === Tracé de la convergence ===
figure;
plot(1:k, liste_erreurs, '-o', 'LineWidth', 2);
xlabel('Itération');
ylabel('Erreur maximale');
title('Convergence de la méthode FDLF');
grid on;

% === Profil de tension ===
figure;
bar(abs(V), 'FaceColor', [0.2 0.6 0.8]);
xlabel('Bus');
ylabel('Tension (pu)');
title('Profil de tension des bus');
grid on;
ylim([0.9 1.1]);  % Plage normale

% Calcul des pertes
PgenTot = sum(Nbusdata(:,7));
QgenTot = sum(Nbusdata(:,8));
PloadTot = sum(Nbusdata(:,5));
QloadTot = sum(Nbusdata(:,6));

Pertes = PgenTot - PloadTot;
Pertesr = QgenTot - QloadTot;
Ppercent = (Pertes / PgenTot) * 100;

% Affichage des résultats
fprintf('Nombre d''itérations: %d\n', k);
disp(' ||  Bus  ||  Code  ||    V    ||   Angle   ||         Load         ||        Generator      ||');
disp(' ||  N    ||        ||   pu    ||   Degree  ||     MW   |   MvAR    ||     MW     |   MvAR   ||');
for i = 1:nbus
    fprintf('    %3g    %3g    %8.4f    %8.4f    %8.3f   %8.3f      %8.3f    %8.3f\n', ...
        Nbusdata(i,1), Nbusdata(i,2), Nbusdata(i,3), Nbusdata(i,4), ...
        Nbusdata(i,5), Nbusdata(i,6), Nbusdata(i,7), Nbusdata(i,8));
end

fprintf('\nTotal                          %8.3f   %8.3f      %8.3f    %8.3f\n', PloadTot, QloadTot, PgenTot, QgenTot);

fprintf('\n==========================================================================================================\n');
fprintf('Les pertes actives                       %8.4f MW\n', abs(Pertes));
fprintf('Les pertes réactives                     %8.2f MvAr\n', abs(Pertesr));
% === POWER BALANCE ===
fprintf('\n=== POWER BALANCE ===\n');
fprintf('Total Generation:   P = %6.2f MW,   Q = %6.2f MVar\n', PgenTot, QgenTot);
fprintf('Total Load:         P = %6.2f MW,   Q = %6.2f MVar\n', PloadTot, QloadTot);
fprintf('Total Losses:       P = %6.2f MW,   Q = %6.2f MVar\n', Pertes, Pertesr);

% Vérification de l'équilibre de puissance
power_balance_P = PgenTot - PloadTot - Pertes;
power_balance_Q = QgenTot - QloadTot - Pertesr;

fprintf('\nPower Balance Verification:\n');
fprintf('Generation - Load - Losses = %5.2f MW (should be 0)\n', power_balance_P);
fprintf('Generation - Load - Losses = %5.2f MVar (should be 0)\n', power_balance_Q);
temps_calcul = toc;  % Arrêt du chronomètre et récupération du temps écoulé

% Ajoutez cette ligne pour afficher le temps de calcul
fprintf('\nTemps de calcul: %f secondes\n', temps_calcul);
