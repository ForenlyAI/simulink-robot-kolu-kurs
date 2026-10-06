function [kok, enb, h] = izleme_hatasi(t, Q, aci)
% Eklem başına izleme hatası [derece]: kok = karesel ortalama hata (1×n), enb = en büyük hata, h = hata dizisi.
% t, Q: hedef (kayıt) zamanı ve açıları [rad] · aci: modelin To Workspace çıktısı (timeseries)
h = rad2deg(interp1(t, Q, aci.Time, 'linear', 'extrap') - aci.Data);
kok = sqrt(mean(h.^2, 1)); enb = max(abs(h), [], 1);
end
