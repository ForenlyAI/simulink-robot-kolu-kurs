function [T, gecti, o] = kol_testi(mdl, t, Q, P, olcut_derece)
% Modeli çalıştırır ve ölçütleri otomatik sınar (Ders 4.1). Her eklem için iki ölçüt:
%   1) karesel ortalama izleme hatası < olcut_derece (varsayılan 1,5°)
%   2) en büyük tork eklem kartındaki sınırın altında (tork doyuma girmedi)
% T: eklem başına sonuç tablosu · gecti: bütün eklemler geçtiyse true · o: benzetim çıktısı
if nargin < 5, olcut_derece = 1.5; end
o = sim(mdl);
[kok, enb] = izleme_hatasi(t, Q, o.aci);
tmax = max(abs(o.tork.Data), [], 1);
hata_tamam = kok < olcut_derece;
tork_tamam = tmax < P.efor;
T = table(P.ad', round(kok', 2), round(enb', 2), round(tmax', 2), P.efor', ...
    hata_tamam', tork_tamam', (hata_tamam & tork_tamam)');
T.Properties.VariableNames = {'eklem', 'kok_hata_derece', 'en_buyuk_derece', ...
    'tork_max_Nm', 'sinir_Nm', 'hata_tamam', 'tork_tamam', 'gecti'};
gecti = all(T.gecti);
end
