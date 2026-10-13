function Zbus = cas4(Zbus, bus1, bus2, Zb)
Zbus = Zbus - (Zbus(:, bus1) - Zbus(:, bus2)) * (Zbus(bus1, :) - Zbus(bus2, :)) / (Zbus(bus1, bus1) + Zbus(bus2, bus2) - 2 * Zbus(bus1, bus2) + Zb);
end

