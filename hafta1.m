% Hafta 1 — Çok Eklemli Model. G1 sağ kolunun dört eklemi (omuz pitch, omuz roll, omuz yaw, dirsek) tek Simulink modelinde.
% Veri: Forenly kıraathane projesi, G1 çay servisi BENZETİM KAYDI (gerçek robot ölçümü değil) + benzetimin eklem kartı.
% Model BASİTLEŞTİRİLMİŞ: eklemler birbirinden bağımsız (kol_parametre.m ve kol_model.m başlıklarına bakın).
format short g; V = fullfile(lab_kok, 'veri'); md = fullfile(lab_kok, 'modeller'); cd(md); bdclose all;
[P, t, Q] = kol_hazirla; assignin('base', 't', t); assignin('base', 'Q', Q);
adlar = cellstr(P.ad); renk = lines(4);

%% 1.1 Dört eklemi tek modelde kurmak: vektör sinyal, Mux ve Demux
% Hedef: kayıtta robotun bardağa uzandığı duruş (9,48. saniye). Dört Step bloğu Mux ile tek vektör sinyale toplanır.
assignin('base', 'aci0', zeros(1, 4));
kol_model('kol_dort', 'kaynak', 'basamak', 'demux', true); model_ciz('kol_dort', '1.1', 'dort-eklem-model');
o = sim('kol_dort'); hd = rad2deg(Q(475, :)); son = rad2deg(o.aci.Data(end, :));
fig = yeni_sekil; hold on;
for i = 1:4, plot(o.aci.Time, rad2deg(o.aci.Data(:, i)), 'Color', renk(i, :)); end
for i = 1:4, yline(hd(i), '--', 'Color', renk(i, :), 'LineWidth', 1); end
grid on; xlabel('zaman [s]'); ylabel('açı [°]'); legend(adlar, 'Location', 'southoutside', 'Orientation', 'horizontal');
title('Dört eklem, tek model: uzanma duruşuna basamak (kesikli: hedef)'); sekil(fig, '1.1', 'dort-eklem-basamak');
komut('1.1', 'vektor-sinyal', {'hedef_derece = rad2deg(hedef)', 'o = sim("kol_dort");', 'size(o.aci.Data)', ...
    'son_derece = rad2deg(o.aci.Data(end, :))', 'kalan = hedef_derece - son_derece', 'size(o.omuz.Data)', 'size(o.dirsek.Data)'});
olc('d1_1_hedef_derece', round(hd, 2)); olc('d1_1_son_derece', round(son, 2)); olc('d1_1_kalan_derece', round(hd - son, 2));
olc('d1_1_boyut', size(o.aci.Data, 2)); olc('d1_1_tork_max', round(max(abs(o.tork.Data), [], 1), 2));

%% 1.2 Parametreleri eklem kartından almak: tablo -> yapı (struct) -> model
cd(V);
komut('1.2', 'eklem-karti', {'K = readtable("g1_sag_kol_parametre.csv");', 'K(:, ["ad" "kayit_sutunu" "kp" "kd" "efor_Nm"])', ...
    'M = readtable("g1_sag_kol_kutle.csv");', 'M(:, ["parca" "kutle_kg"])', 'uzaklik = M{:, 3:6}'});
komut('1.2', 'eylemsizlik', {'J = M.kutle_kg'' * M{:, 3:6}.^2 + K.armatur''', 'P = kol_parametre;', 'P.J', ...
    'dogal_frekans = sqrt(P.kp ./ P.J)', 'sonum_orani = P.kd ./ (2 * sqrt(P.kp .* P.J))'});
cd(md);
wn = sqrt(P.kp ./ P.J); zeta = P.kd ./ (2 * sqrt(P.kp .* P.J));
fig = yeni_sekil;
subplot(1, 3, 1); bar(P.J); set(gca, 'XTickLabel', adlar); xtickangle(30); grid on; ylabel('kg·m^2'); title('eylemsizlik J');
subplot(1, 3, 2); bar(wn); set(gca, 'XTickLabel', adlar); xtickangle(30); grid on; ylabel('rad/s'); title('doğal frekans');
subplot(1, 3, 3); bar(zeta); set(gca, 'XTickLabel', adlar); xtickangle(30); grid on; title('sönüm oranı');
sgtitle('Eklem kartı + parça kütleleri -> dört eklemin parametreleri (basitleştirilmiş model)'); sekil(fig, '1.2', 'eklem-parametreleri');
% yapıdaki tek sayı değişince model değişir: dirsek kp 40 -> 80
load_system('kol_dort'); o1 = sim('kol_dort'); P2 = P; P2.kp(4) = 80; assignin('base', 'P', P2); o2 = sim('kol_dort'); assignin('base', 'P', P);
fig = yeni_sekil; plot(o1.aci.Time, rad2deg(o1.aci.Data(:, 4))); hold on; plot(o2.aci.Time, rad2deg(o2.aci.Data(:, 4))); yline(hd(4), '--', 'hedef', 'FontSize', 14);
grid on; xlabel('zaman [s]'); ylabel('dirsek [°]'); legend('P.kp(4) = 40 (kart)', 'P.kp(4) = 80', 'Location', 'northeast');
title('Yapıdaki tek sayı değişti, model değişti'); sekil(fig, '1.2', 'kp-degisimi');
komut('1.2', 'struct-model', {'get_param("kol_dort/kp", "Gain")', 'get_param("kol_dort/Ters eylemsizlik", "Gain")', 'P.kp(4) = 80;', ...
    'o = sim("kol_dort");', 'dirsek_son = rad2deg(o.aci.Data(end, 4))', 'P.kp(4) = 40;'});
olc('d1_2_J', round(P.J, 4)); olc('d1_2_dogal_frekans', round(wn, 2)); olc('d1_2_sonum_orani', round(zeta, 3));
olc('d1_2_dirsek_son_kp40_kp80', round(rad2deg([o1.aci.Data(end, 4) o2.aci.Data(end, 4)]), 2));
close_system('kol_dort', 0);

%% 1.3 Dört eklemle kaydı izlemek: eklem başına karesel ortalama hata
assignin('base', 'aci0', Q(1, :));
kol_model('kol_izle', 'kaynak', 'kayit', 'sure', '113.3'); model_ciz('kol_izle', '1.3', 'izleme-model');
o = sim('kol_izle'); [kok1, enb1] = izleme_hatasi(t, Q, o.aci);
fig = yeni_sekil;
for i = 1:4
    subplot(2, 2, i); plot(t, rad2deg(Q(:, i)), 'k', 'LineWidth', 1); hold on; plot(o.aci.Time, rad2deg(o.aci.Data(:, i)), 'Color', renk(i, :), 'LineWidth', 1.2);
    grid on; xlim([0 113.3]); ylabel('[°]'); title(sprintf('%s — hata %.2f°', adlar{i}, kok1(i)));
    if i > 2, xlabel('zaman [s]'); end
end
sgtitle('Çay servisi benzetim kaydı (siyah) ve dört eklemli model — kart kazançlarıyla PD'); sekil(fig, '1.3', 'dort-eklem-izleme');
fig = yeni_sekil; b = bar(kok1); b.FaceColor = 'flat'; b.CData = renk; set(gca, 'XTickLabel', adlar); grid on; ylabel('karesel ortalama hata [°]');
yline(1.5, '--r', 'ölçüt 1,5°', 'FontSize', 14); title('Eklem başına izleme hatası — yalnız PD'); sekil(fig, '1.3', 'eklem-hatalari');
komut('1.3', 'hata-hesabi', {'o = sim("kol_izle");', 'hata = rad2deg(interp1(t, Q, o.aci.Time) - o.aci.Data);', 'size(hata)', ...
    'kok_hata = sqrt(mean(hata.^2))', 'en_buyuk = max(abs(hata))', 'tork_max = max(abs(o.tork.Data))'});
olc('d1_3_kok_hata', round(kok1, 2)); olc('d1_3_en_buyuk', round(enb1, 2)); olc('d1_3_tork_max', round(max(abs(o.tork.Data), [], 1), 2));
oPD = o; close_system('kol_izle', 0);

%% 1.4 Yerçekimi için ileri besleme: hata ne kadar düşüyor
kol_model('kol_ileri', 'kaynak', 'kayit', 'ileri', true, 'sure', '113.3'); model_ciz('kol_ileri', '1.4', 'ileri-besleme-model');
o = sim('kol_ileri'); [kok2, enb2] = izleme_hatasi(t, Q, o.aci);
fig = yeni_sekil; bar([kok1; kok2]'); set(gca, 'XTickLabel', adlar); grid on; ylabel('karesel ortalama hata [°]');
yline(1.5, '--r', 'ölçüt 1,5°', 'FontSize', 14); legend('yalnız PD', 'PD + yerçekimi ileri beslemesi', 'Location', 'north');
title('İleri besleme yerçekimini karşılıyor'); sekil(fig, '1.4', 'ileri-besleme-hata');
fig = yeni_sekil; sec = [1 4];
for k = 1:2
    i = sec(k); subplot(2, 1, k); plot(t, rad2deg(Q(:, i)), 'k', 'LineWidth', 1); hold on;
    plot(oPD.aci.Time, rad2deg(oPD.aci.Data(:, i)), '--'); plot(o.aci.Time, rad2deg(o.aci.Data(:, i)));
    grid on; xlim([25 60]); ylabel([adlar{i} ' [°]']);
end
xlabel('zaman [s]'); subplot(2, 1, 1); legend('kayıt (benzetim)', 'yalnız PD', 'PD + ileri besleme', 'Location', 'northeast');
title('Bardağı kaldırıp taşırken: omuz pitch ve dirsek'); sekil(fig, '1.4', 'ileri-besleme-yakin');
komut('1.4', 'yercekimi-torku', {'tasima_derece = rad2deg(Q(3001, :))', 'G = P.gc .* cos(Q(3001, :)) + P.gs .* sin(Q(3001, :))', ...
    'beklenen_hata = rad2deg(G ./ P.kp)', 'o = sim("kol_ileri");', 'kok_hata = izleme_hatasi(t, Q, o.aci)'});
G = P.gc .* cos(Q(3001, :)) + P.gs .* sin(Q(3001, :));
olc('d1_4_kok_hata', round(kok2, 2)); olc('d1_4_en_buyuk', round(enb2, 2)); olc('d1_4_dusus_yuzde', round(100 * (1 - kok2 ./ kok1), 0));
olc('d1_4_G_tasima_Nm', round(G, 2)); olc('d1_4_tork_max', round(max(abs(o.tork.Data), [], 1), 2));
save(fullfile(lab_kok, 'cikti', 'hafta1.mat'), 'kok1', 'kok2');
close_system('kol_ileri', 0); disp('HAFTA1 TAMAM');
