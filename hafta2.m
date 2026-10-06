% Hafta 2 — Yörünge ve Sınırlar. Yumuşak yörünge, hız sınırı, tork doyumu ve integral sarması, modelin içinde ileri kinematik.
% Veri: Forenly kıraathane projesi, G1 çay servisi BENZETİM KAYDI. Model BASİTLEŞTİRİLMİŞ: eklemler birbirinden bağımsız.
% ÖRNEK etiketli değerler kayıttan ya da karttan gelmez; yöntemi göstermek için seçilmiştir.
format short g; V = fullfile(lab_kok, 'veri'); md = fullfile(lab_kok, 'modeller'); cd(md); bdclose all;
H = fullfile(V, 'cay_servisi_kd_v017_81_0013.hdf5');
[P, t, Q] = kol_hazirla; assignin('base', 't', t); assignin('base', 'Q', Q); assignin('base', 'dosya', H);
adlar = cellstr(P.ad); renk = lines(4); uzanma = Q(475, :);

%% 2.1 Noktadan noktaya yumuşak yörünge: beşinci derece polinom
assignin('base', 'aci0', zeros(1, 4));
ty = (0:0.002:2.5)'; [qy, qdy, qddy] = yorunge5(zeros(1, 4), uzanma, 1.5, ty);
komut('2.1', 'yorunge-fonksiyonu', {'type yorunge5', 'ty = (0:0.002:2.5)'';', '[q, qd, qdd] = yorunge5(zeros(1, 4), hedef, 1.5, ty);', ...
    'size(q)', 'en_buyuk_hiz = max(abs(qd))', 'son_derece = rad2deg(q(end, :))'});
fig = yeni_sekil;
subplot(3, 1, 1); plot(ty, rad2deg(qy)); grid on; ylabel('konum [°]'); title('Beşinci derece polinom: 1,5 saniyede uzanma duruşuna');
legend(adlar, 'Location', 'eastoutside');
subplot(3, 1, 2); plot(ty, qdy); grid on; ylabel('hız [rad/s]');
subplot(3, 1, 3); plot(ty, qddy); grid on; ylabel('ivme [rad/s^2]'); xlabel('zaman [s]');
sekil(fig, '2.1', 'yorunge-egrileri');
kol_model('kol_basamak', 'kaynak', 'basamak', 'ileri', true, 'sure', '2.5');
kol_model('kol_yorunge', 'kaynak', 'yorunge', 'ileri', true, 'sure', '2.5'); model_ciz('kol_yorunge', '2.1', 'yorunge-model');
assignin('base', 'ref', [ty qy]);
oB = sim('kol_basamak'); oY = sim('kol_yorunge');
asB = 100 * (max(oB.aci.Data ./ uzanma, [], 1) - 1); asY = 100 * (max(oY.aci.Data ./ uzanma, [], 1) - 1);
fig = yeni_sekil;
subplot(2, 1, 1); plot(oB.aci.Time, rad2deg(oB.aci.Data(:, 1))); hold on; plot(oY.aci.Time, rad2deg(oY.aci.Data(:, 1))); plot(ty, rad2deg(qy(:, 1)), 'k:');
grid on; ylabel('omuz pitch [°]'); legend('basamak hedef', 'yumuşak yörünge', 'yörüngenin kendisi', 'Location', 'northeast');
title(sprintf('Basamak: aşım %%%.0f, tork %.0f N·m — yumuşak: aşım %%%.1f, tork %.1f N·m', asB(1), max(abs(oB.tork.Data(:, 1))), asY(1), max(abs(oY.tork.Data(:, 1)))));
subplot(2, 1, 2); plot(oB.tork.Time, oB.tork.Data(:, 1)); hold on; plot(oY.tork.Time, oY.tork.Data(:, 1)); yline(-25, '--r', 'tork sınırı', 'FontSize', 13);
grid on; ylabel('tork [N·m]'); xlabel('zaman [s]'); xlim([0 2.5]); sekil(fig, '2.1', 'basamak-yumusak');
olc('d2_1_hiz_max', round(max(abs(qdy), [], 1), 3)); olc('d2_1_tork_max_basamak', round(max(abs(oB.tork.Data), [], 1), 2));
olc('d2_1_tork_max_yumusak', round(max(abs(oY.tork.Data), [], 1), 2)); olc('d2_1_asim_basamak', round(asB, 1)); olc('d2_1_asim_yumusak', round(asY, 2));
close_system('kol_yorunge', 0);

%% 2.2 Hız sınırı, tork doyumu ve integral sarması (anti-windup)
% (a) Rate Limiter: hedef en çok hizlim = 2 rad/s hızla değişir (ÖRNEK servis hızı; kartın eklem hız sınırı 37 rad/s)
kol_model('kol_hizsinir', 'kaynak', 'basamak', 'ileri', true, 'hizsiniri', true, 'sure', '2.5');
oH = sim('kol_hizsinir'); asH = 100 * (max(oH.aci.Data ./ uzanma, [], 1) - 1);
fig = yeni_sekil;
subplot(2, 1, 1); plot(oB.aci.Time, rad2deg(oB.aci.Data(:, 1))); hold on; plot(oH.aci.Time, rad2deg(oH.aci.Data(:, 1))); plot(oH.hedefk.Time, rad2deg(oH.hedefk.Data(:, 1)), 'k:');
grid on; ylabel('omuz pitch [°]'); legend('basamak hedef', 'hız sınırlı hedef (2 rad/s, ÖRNEK)', 'sınırlanmış hedef', 'Location', 'northeast');
title('Rate Limiter: hedef basamak yerine rampa olur');
subplot(2, 1, 2); plot(oB.tork.Time, oB.tork.Data(:, 1)); hold on; plot(oH.tork.Time, oH.tork.Data(:, 1)); yline(-25, '--r', 'tork sınırı', 'FontSize', 13);
grid on; ylabel('tork [N·m]'); xlabel('zaman [s]'); xlim([0 2.5]); sekil(fig, '2.2', 'hiz-siniri');
olc('d2_2_tork_max_hizsinir', round(max(abs(oH.tork.Data), [], 1), 2)); olc('d2_2_asim_hizsinir', round(asH, 1));
% (b) İntegral sarması: büyük bir hareket (ÖRNEK), ileri besleme yok, integral var; tork doyumdayken integral birikir
buyuk = deg2rad([-90 -60 60 90]); assignin('base', 'hedef', buyuk); assignin('base', 'ki', 2 * P.kp);
kol_model('kol_sarma', 'kaynak', 'basamak', 'integral', 'sarmali', 'sure', '4');
kol_model('kol_koruma', 'kaynak', 'basamak', 'integral', 'korumali', 'sure', '4'); model_ciz('kol_koruma', '2.2', 'sarma-koruma-model');
o1 = sim('kol_sarma'); o2 = sim('kol_koruma');
as1 = 100 * (max(o1.aci.Data ./ buyuk, [], 1) - 1); as2 = 100 * (max(o2.aci.Data ./ buyuk, [], 1) - 1);
fig = yeni_sekil;
subplot(2, 1, 1); plot(o1.aci.Time, rad2deg(o1.aci.Data(:, 1))); hold on; plot(o2.aci.Time, rad2deg(o2.aci.Data(:, 1))); yline(-90, '--', 'hedef', 'FontSize', 13);
grid on; ylabel('omuz pitch [°]'); legend(sprintf('korumasız: aşım %%%.0f', as1(1)), sprintf('sarma korumalı: aşım %%%.0f', as2(1)), 'Location', 'northeast');
title('Tork doyumdayken integral birikir: sarma (windup)');
subplot(2, 1, 2); plot(o1.tork.Time, o1.tork.Data(:, 1)); hold on; plot(o2.tork.Time, o2.tork.Data(:, 1)); yline(-25, '--r', 'tork sınırı', 'FontSize', 13);
grid on; ylabel('tork [N·m]'); xlabel('zaman [s]'); sekil(fig, '2.2', 'sarma');
komut('2.2', 'sarma-olcum', {'ki = 2 * P.kp', 'hedef = deg2rad([-90 -60 60 90]);', 'o1 = sim("kol_sarma"); o2 = sim("kol_koruma");', ...
    'asim_korumasiz = 100 * (max(o1.aci.Data ./ hedef) - 1)', 'asim_korumali = 100 * (max(o2.aci.Data ./ hedef) - 1)', ...
    'son_hata_derece = rad2deg(hedef - o2.aci.Data(end, :))'});
olc('d2_2_asim_korumasiz', round(as1, 1)); olc('d2_2_asim_korumali', round(as2, 1));
olc('d2_2_son_hata_korumali', round(rad2deg(buyuk - o2.aci.Data(end, :)), 3));
assignin('base', 'hedef', uzanma); assignin('base', 'ki', 0);
close_system('kol_basamak', 0); close_system('kol_hizsinir', 0); close_system('kol_sarma', 0); close_system('kol_koruma', 0);

%% 2.3 MATLAB Function bloğu ile ileri kinematik: bilek konumu modelin içinde
komut('2.3', 'bilek-fonksiyonu', {'type bilek_konumu'});
komut('2.3', 'bilek-hesap', {'p_sifir = bilek_konumu([0; 0; 0; 0])''', 'p_uzanma = bilek_konumu(Q(475, :)'')''', 'p_tasima = bilek_konumu(Q(3001, :)'')'''});
assignin('base', 'aci0', Q(1, :)); assignin('base', 'ref', [t Q]);
kol_model('kol_bilek', 'kaynak', 'kayit', 'ileri', true, 'kinematik', true, 'sure', '113.3');
try
    o = sim('kol_bilek');
catch e   % MATLAB Function bloğu derlenemezse (ör. derleyici yok) aynı hesap Fcn bloklarıyla yapılır
    fprintf('2.3: MATLAB Function bloğuyla benzetim olmadı (%s) — Fcn bloklarıyla yeniden kuruluyor\n', e.message);
    kol_model('kol_bilek', 'kaynak', 'kayit', 'ileri', true, 'kinematik', 'fcn', 'sure', '113.3'); o = sim('kol_bilek');
end
model_ciz('kol_bilek', '2.3', 'bilek-model'); yontem = evalin('base', 'bilek_yontemi');
B = dizi(o.bilek); A = o.aci.Data; Bf = zeros(size(A, 1), 3);
for k = 1:size(A, 1), Bf(k, :) = bilek_konumu(A(k, :)')'; end
blok_fark = max(abs(B(:) - Bf(:)));
fig = yeni_sekil; plot3(B(:, 1), B(:, 2), B(:, 3), 'LineWidth', 1.5); hold on;
plot3(B(1, 1), B(1, 2), B(1, 3), 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'g'); plot3(B(end, 1), B(end, 2), B(end, 3), 's', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
grid on; axis equal; view(35, 20); xlabel('x ileri [m]'); ylabel('y sola [m]'); zlabel('z yukarı [m]'); legend('bilek yolu (model)', 'başlangıç', 'bitiş', 'Location', 'northeast');
title('Modelin içinde hesaplanan bilek konumu — çay servisi boyunca'); sekil(fig, '2.3', 'bilek-yolu');
fig = yeni_sekil; plot(o.bilek.Time, B); grid on; xlim([0 113.3]); xlabel('zaman [s]'); ylabel('bilek konumu [m]'); legend('x (ileri)', 'y (sola)', 'z (yukarı)', 'Location', 'eastoutside');
title(sprintf('Bilek konumu — %s', yontem)); sekil(fig, '2.3', 'bilek-xyz');
p0 = bilek_konumu([0; 0; 0; 0])';
olc('d2_3_yontem', yontem); olc('d2_3_blok_fonksiyon_fark_m', blok_fark); olc('d2_3_p_sifir', round(p0, 4));
olc('d2_3_p_uzanma', round(bilek_konumu(Q(475, :)')', 4)); olc('d2_3_p_tasima', round(bilek_konumu(Q(3001, :)')', 4));
olc('d2_3_bilek_aralik_m', round(max(B, [], 1) - min(B, [], 1), 3));

%% 2.4 Modelin bilek konumunu kayıttaki bilek konumuyla karşılaştırmak
% Kayıttaki bilek: pelvis çerçevesinde 4×4 dönüşüm matrisi (bilek yaw parçası). h5read 4×4×N verir; her matris devrik gelir (kurs 1, Ders 1.2).
T = h5read(H, '/data/demo_0/obs/right_wrist_pose_pelvis_frame'); pk = squeeze(double(T(4, 1:3, :)))';
q = h5read(H, '/data/demo_0/states/articulation/robot/joint_position');
bel = double(q([3 6 9], :))'; bil = double(q([25 27 29], :))';   % bel: yaw, roll, pitch · bilek: roll, pitch, yaw (kayıttaki satır numaraları)
pkm = interp1(t, pk, o.bilek.Time, 'linear', 'extrap'); hata_cm = 100 * sqrt(sum((B - pkm).^2, 2)); model_kayit = sqrt(mean(hata_cm.^2));
durum = {'dört eklem', '+ bel', '+ bilek', '+ bel + bilek'}; kb = [0 1 0 1]; kw = [0 0 1 1]; kokcm = zeros(1, 4); Pd = zeros(numel(t), 3, 4);
for d = 1:4
    for k = 1:numel(t), Pd(k, :, d) = bilek_konumu_tam(Q(k, :), kb(d) * bel(k, :), kw(d) * bil(k, :))'; end
    kokcm(d) = 100 * sqrt(mean(sum((Pd(:, :, d) - pk).^2, 2)));
end
payi = 100 * sqrt(mean(sum((B - interp1(t, Pd(:, :, 1), o.bilek.Time, 'linear', 'extrap')).^2, 2)));   % denetleyicinin payı: model bileği − hedef açılarının bileği
fig = yeni_sekil; ek = {'x (ileri)', 'y (sola)', 'z (yukarı)'};
for i = 1:3
    subplot(3, 1, i); plot(t, pk(:, i), 'k', 'LineWidth', 1); hold on; plot(o.bilek.Time, B(:, i), 'Color', renk(i, :)); grid on; xlim([0 113.3]); ylabel([ek{i} ' [m]']);
end
xlabel('zaman [s]'); subplot(3, 1, 1); legend('kayıt (benzetim)', 'model (dört eklem)', 'Location', 'eastoutside');
title(sprintf('Bilek konumu: model ile kayıt arasında karesel ortalama fark %.1f cm', model_kayit)); sekil(fig, '2.4', 'bilek-karsilastirma');
fig = yeni_sekil; b = bar(kokcm); b.FaceColor = 'flat'; b.CData = renk; set(gca, 'XTickLabel', durum); grid on; ylabel('kayıtla fark [cm]');
text(1:4, kokcm, compose('%.2f cm', kokcm), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 15);
title('Fark nereden geliyor? Kayıttaki açılarla, eksik eklemleri ekleyerek'); sekil(fig, '2.4', 'hata-kaynagi');
tablo = table(durum', round(kokcm', 2), 'VariableNames', {'hesaba_katilan', 'kayitla_fark_cm'}); assignin('base', 'tablo', tablo);
komut('2.4', 'bilek-okuma', {'T = h5read(dosya, "/data/demo_0/obs/right_wrist_pose_pelvis_frame");', 'size(T)', ...
    'kayit_bilek = squeeze(T(4, 1:3, :))'';', 'kayit_bilek(3001, :)', 'model_bilek = bilek_konumu(Q(3001, :)'')''', ...
    'fark_cm = 100 * norm(model_bilek - double(kayit_bilek(3001, :)))'});
komut('2.4', 'hata-tablosu', {'tablo'});
olc('d2_4_model_kayit_cm', round(model_kayit, 2)); olc('d2_4_kok_cm', round(kokcm, 2)); olc('d2_4_denetleyici_payi_cm', round(payi, 2));
olc('d2_4_en_buyuk_cm', round(max(hata_cm), 2));
close_system('kol_bilek', 0); disp('HAFTA2 TAMAM');
