function Zbus = cas1(Zbus_old, Zb)
    [n, m] = size(Zbus_old);
    Zbus = zeros(n+1, m+1);
    Zbus(1:n, 1:m) = Zbus_old;
    Zbus(n+1, m+1) = Zb;
end

