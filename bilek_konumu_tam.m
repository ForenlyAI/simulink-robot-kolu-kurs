function p = bilek_konumu_tam(q, bel, bilek)
% Bilek konumu [m], pelvis çerçevesinde — bel ve bilek eklemleri de hesaba katılır (Ders 2.4: hata nereden geliyor?).
% q = dört kol eklemi, bel = [yaw roll pitch], bilek = [roll pitch yaw] (radyan). bilek_konumu ile aynı ölçüler (G1 URDF).
% bel ve bilek sıfır verilirse sonuç bilek_konumu(q) ile aynıdır. Bilek yaw ekseni bileğin içinden geçtiği için konumu değiştirmez.
a  = 0.2793;
b0 = [-0.0040; 0; 0.0440];        % pelvis -> bel roll ekseni
s0 = [0.0040; -0.1002; 0.2478];   % gövde -> omuz pitch ekseni
d1 = [0; -0.0380; -0.0138]; d2 = [0; -0.0062; -0.1032]; d3 = [0.0158; 0; -0.0805];
e1 = [0.1000; -0.0019; -0.0100];  % dirsek -> bilek roll
e2 = [0.0380; 0; 0];              % bilek roll -> bilek pitch
e3 = [0.0460; 0; 0];              % bilek pitch -> bilek yaw (kayıttaki "bilek" noktası)
on_kol = e1 + Rx(bilek(1)) * (e2 + Ry(bilek(2)) * e3);
kol = d1 + Rx(a) * Rx(q(2)) * (d2 + Rz(q(3)) * (d3 + Ry(q(4)) * on_kol));
p = Rz(bel(1)) * (b0 + Rx(bel(2)) * Ry(bel(3)) * (s0 + Rx(-a) * Ry(q(1)) * kol));
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
