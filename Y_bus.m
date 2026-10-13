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
disp("La matrice d'admettance est :");
disp(Ybus)