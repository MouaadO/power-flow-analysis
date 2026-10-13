function invYbus = final_form(linedata, nbus)
%BUILD_INV_YBUS Constructs the Ybus matrix and returns its inverse.
%
%   invYbus = BUILD_INV_YBUS(linedata, nbus)
%   Inputs:
%     - linedata: [n x 6] matrix with columns:
%         [from_bus, to_bus, R, X, B, tap_ratio]
%     - nbus: number of buses
%   Output:
%     - invYbus: inverse of the Ybus admittance matrix

    % Initialization
    Ybus = zeros(nbus, nbus);
    
    % Extract data
    bus_depart = linedata(:, 1);
    bus_arrive = linedata(:, 2);
    R = linedata(:, 3);
    X = linedata(:, 4);
    B = linedata(:, 5);
    tap_setting = linedata(:, 6);
    
    nbr = size(linedata, 1);  % number of branches
    Z = R + 1j * X;
    Y = 1 ./ (Z .* tap_setting);
    
    % Off-diagonal elements
    for k = 1:nbr
        i = bus_depart(k);
        j = bus_arrive(k);
        Ybus(i, j) = Ybus(i, j) - Y(k);
        Ybus(j, i) = Ybus(j, i) - Y(k);
    end
    
    % Diagonal elements
    for i = 1:nbus
        condition = (bus_depart == i) | (bus_arrive == i);
        shunt = sum(1j * B .* condition);
        
        % Transformer correction
        mask = (tap_setting ~= 1);
        Z_masked = Z(mask);
        tap_masked = tap_setting(mask);
        from_masked = bus_depart(mask);
        to_masked = bus_arrive(mask);
        
        trans_corr = sum((1 ./ Z_masked) .* ...
            ((to_masked == i) .* (-1 ./ tap_masked + 1) + ...
             (from_masked == i) .* ((1 ./ tap_masked - 1) ./ tap_masked)));
        
        Ybus(i, i) = -sum(Ybus(:, i)) + shunt + trans_corr;
    end

    % Return the inverse (use \ instead of inv() if solving equations)
    if rcond(Ybus) < 1e-12
        warning('Ybus is nearly singular or ill-conditioned. Consider using pinv() instead.');
        invYbus = pinv(Ybus);
    else
        invYbus = inv(Ybus);
    end
end
