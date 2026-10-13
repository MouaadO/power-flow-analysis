function Zk = impedance_bus_bus(k, connectedBus, linedata)
    for i = 1:size(linedata, 1)
        if (linedata(i, 1) == k && linedata(i, 2) == connectedBus) || (linedata(i, 1) == connectedBus && linedata(i, 2) == k)
            Zk = (linedata(i, 3) + 1i * linedata(i, 4));
            return;
        end
    end
end

