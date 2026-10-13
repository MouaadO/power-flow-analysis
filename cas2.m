function Zbus = cas2(Zbus_old, bus, Zb)
    [n, ~] = size(Zbus_old);
    Zbus = zeros(n+1, n+1);
    Zbus(1:n,1:n) = Zbus_old;
    for i=1:n
        Zbus(n+1,i) = Zbus(i,bus);
        Zbus(i,n+1) = Zbus(bus,i);
    end
    Zbus(n+1,n+1) = Zbus(bus,bus)+(Zb);
end
