function P = kol_parametre(veri)
% G1 sağ kolunun dört ekleminin parametreleri: eklem kartı + parça kütleleri -> tek yapı (struct). Model P.kp, P.J ... diye okur.
% BASİTLEŞTİRİLMİŞ MODEL — eklemler birbirinden bağımsız:  J(i)·θ''(i) = τ(i) − G(i)
%   kp, kd, efor (tork sınırı), hız ve açı sınırı : benzetimin eklem kartından (veri/g1_sag_kol_parametre.csv)
%   J(i) = Σ kütle·uzaklık² + armatür : uzaklık = parçanın kütle merkezinin eklem eksenine dik uzaklığı (G1 URDF, bütün eklemler
%          sıfırken: üst kol aşağı, ön kol ileri). Kurs 1'deki dirsek hesabının (J ≈ 0,0975) dört ekleme genişletilmişi.
%   G(i) = gc(i)·cos θ + gs(i)·sin θ : yerçekimi torku, aynı duruşta ve yalnız eklemin kendi açısına bağlı (veri/turet.py).
% YAKLAŞIK VARSAYIMLAR: parçalar nokta kütle; el 0,4 kg ve dirsekten 0,30 m ileride; öbür eklemlerin açısı J ve G'yi değiştirmez.
if nargin < 1, veri = fullfile(lab_kok, 'veri'); end
K = readtable(fullfile(veri, 'g1_sag_kol_parametre.csv'), 'TextType', 'string', 'Encoding', 'UTF-8');
M = readtable(fullfile(veri, 'g1_sag_kol_kutle.csv'), 'TextType', 'string', 'Encoding', 'UTF-8');
P.ad      = K.ad';             % "omuz pitch" "omuz roll" "omuz yaw" "dirsek"
P.sutun   = K.kayit_sutunu';   % benzetim kaydındaki satır numarası (h5read ile okunan 53×N matriste)
P.kp      = K.kp';
P.kd      = K.kd';
P.armatur = K.armatur';
P.efor    = K.efor_Nm';
P.hiz     = K.hiz_rad_s';
P.alt     = K.alt_rad';
P.ust     = K.ust_rad';
P.gc      = K.yercekimi_cos_Nm';
P.gs      = K.yercekimi_sin_Nm';
P.J       = M.kutle_kg' * M{:, 3:6}.^2 + P.armatur;
end
