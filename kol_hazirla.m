function [P, t, Q, Qd] = kol_hazirla
% Ortak hazırlık: P = kol parametreleri · t = zaman [s] · Q = kayıttaki dört eklem açısı (N×4, rad) · Qd = açısal hızları.
% Model değişkenlerini taban çalışma alanına yazar. Veri: G1 çay servisi BENZETİM KAYDI (gerçek robot ölçümü değil).
V = fullfile(lab_kok, 'veri'); P = kol_parametre(V);
H = fullfile(V, 'cay_servisi_kd_v017_81_0013.hdf5');
q  = h5read(H, '/data/demo_0/states/articulation/robot/joint_position');
qd = h5read(H, '/data/demo_0/states/articulation/robot/joint_velocity');
Q = double(q(P.sutun, :))'; Qd = double(qd(P.sutun, :))'; t = (0:size(Q, 1) - 1)' / 50;   % kayıt 50 Hz (0,02 s aralık)
D = struct('P', P, 'ref', [t Q], 'refhiz', [t Qd], 'aci0', Q(1, :), 'hedef', Q(475, :), ...
    'Ts', 0.02, ...      % denetleyici örnekleme aralığı = kayıt aralığı (50 Hz)
    'kpk', 1, 'kdk', 1, ...  % kart kazançlarının çarpanı (tarama için)
    'ki', 0, 'Tt', 0.05, ... % integral kazancı ve sarma koruması zaman sabiti (ÖRNEK değerler, Ders 2.2)
    'hizlim', 2, ...     % hedef hız sınırı [rad/s] (ÖRNEK servis hızı; kartın eklem hız sınırı 37 rad/s)
    'sigma', 0, ...      % ölçüm gürültüsü standart sapması [rad] (ÖRNEK, Ders 3.2)
    'alfa', 1, ...       % ayrık filtre katsayısı (1 = filtre yok)
    'gecikme', 0, ...    % tork gecikmesi [s] (ÖRNEK, Ders 3.3)
    'Jk', 1, 'bv', 0, 'fc', 0);  % eylemsizlik çarpanı, viskoz ve kuru sürtünme (ÖRNEK, Ders 3.4)
for f = fieldnames(D)', assignin('base', f{1}, D.(f{1})); end
end
