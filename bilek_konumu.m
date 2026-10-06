function p = bilek_konumu(q)
% G1 sağ kolunun ileri kinematiği (BASİTLEŞTİRİLMİŞ): dört eklem açısından bileğin konumu [m], pelvis çerçevesinde.
% q = [omuz pitch; omuz roll; omuz yaw; dirsek] (radyan). Bel ve bilek eklemleri sıfır sayılır.
% Ölçüler G1 URDF'inden (eklem başlangıç noktaları, 0,1 mm'ye yuvarlandı): x ileri, y sola, z yukarı.
a  = 0.2793;                      % omuz pitch ekseninin yana eğimi [rad]
p0 = [0; -0.1002; 0.2918];        % pelvis -> omuz pitch ekseni
d1 = [0; -0.0380; -0.0138];       % omuz pitch -> omuz roll
d2 = [0; -0.0062; -0.1032];       % omuz roll -> omuz yaw
d3 = [0.0158; 0; -0.0805];        % omuz yaw -> dirsek
d4 = [0.1840; -0.0019; -0.0100];  % dirsek -> bilek (bilek eklemleri sıfırken)
p = p0 + Rx(-a) * Ry(q(1)) * (d1 + Rx(a) * Rx(q(2)) * (d2 + Rz(q(3)) * (d3 + Ry(q(4)) * d4)));
end

function R = Rx(t)
R = [1 0 0; 0 cos(t) -sin(t); 0 sin(t) cos(t)];
end

function R = Ry(t)
R = [cos(t) 0 sin(t); 0 1 0; -sin(t) 0 cos(t)];
end

function R = Rz(t)
R = [cos(t) -sin(t) 0; sin(t) cos(t) 0; 0 0 1];
end
