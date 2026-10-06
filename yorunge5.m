function [q, qd, qdd] = yorunge5(q0, q1, T, t)
% Noktadan noktaya yumuşak yörünge: beşinci derece polinom; başta ve sonda hız ve ivme sıfır.
% q0, q1: başlangıç ve hedef (1×n satır) · T: hareket süresi [s] · t: zaman (sütun vektör)
% q, qd, qdd: konum, hız, ivme (numel(t)×n). T'den sonra hedefte bekler.
s   = min(max(t(:) / T, 0), 1);
q   = q0 + (q1 - q0) .* (10*s.^3 - 15*s.^4 + 6*s.^5);
qd  = (q1 - q0) .* (30*s.^2 - 60*s.^3 + 30*s.^4) / T;
qdd = (q1 - q0) .* (60*s - 180*s.^2 + 120*s.^3) / T^2;
end
