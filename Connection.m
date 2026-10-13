% Chercher les bus connectee
function connectedBus = Connection(k, linedata)
    % Initialize output
    connectedBus = [];
    for i = 1:size(linedata, 1)
        if linedata(i, 1) == k
            connectedBus = linedata(i, 2);
            return;
        elseif linedata(i, 2) == k
            connectedBus = linedata(i, 1);
            return;
        end
    end
end

