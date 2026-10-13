function Zbus = cas3(Zbus, bus, Zb)
Zbus = Zbus - Zbus(:, bus) * Zbus(bus, :) / (Zbus(bus, bus) + Zb);
end
