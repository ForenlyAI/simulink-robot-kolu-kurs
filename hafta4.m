% Hafta 4 — Doğrulama ve Bitirme. Otomatik test, parametre taramasıyla ayar, otomatik rapor, bitirme projesi.
% Veri: Forenly kıraathane projesi, G1 çay servisi BENZETİM KAYDI. Model BASİTLEŞTİRİLMİŞ: eklemler birbirinden bağımsız.
% Bitirme senaryosu (ÖRNEK değerler): ölçüm gürültüsü 0,3° standart sapma, tork gecikmesi 10 ms, denetleyici 50 Hz.
% Geçme ölçütü: her eklemde karesel ortalama hata < 1,5° ve en büyük tork eklem kartındaki sınırın altında.
format short g; md = fullfile(lab_kok, 'modeller'); cd(md); bdclose all; ck = fullfile(lab_kok, 'cikti');
[P, t, Q, Qd] = kol_hazirla; assignin('base', 't', t); assignin('base', 'Q', Q);
adlar = cellstr(P.ad); renk = lines(4); OLCUT = 1.5; GURULTU = deg2rad(0.3); GECIKME = 0.010;
[~, im2] = max(abs(Qd(:, 2))); tw2 = t(im2) + [-1 1.5];
kol_model('kol_bitirme', 'kaynak', 'kayit', 'ileri', true, 'ayrik', true, 'gurultu', true, 'filtre', true, 'gecikme', true, 'sure', '113.3');

%% 4.1 Ölçütleri otomatik sınayan test betiği
komut('4.1', 'test-fonksiyonu', {'type kol_testi'});
komut('4.1', 'test-ideal', {'sigma = 0; gecikme = 0;', '[T, gecti] = kol_testi("kol_bitirme", t, Q, P)'});
T1 = evalin('base', 'T'); g1 = evalin('base', 'gecti');
komut('4.1', 'test-gurultu-gecikme', {'sigma = deg2rad(0.3); gecikme = 0.010;', '[T, gecti] = kol_testi("kol_bitirme", t, Q, P)', ...
    'kalan_eklemler = T.eklem(~T.gecti)''', 'try, assert(gecti, "Kol testi KALDI"), catch e, disp(e.message), end'});
T2 = evalin('base', 'T'); g2 = evalin('base', 'gecti');
fig = yeni_sekil; b = bar([T1.kok_hata_derece T2.kok_hata_derece]); set(gca, 'XTickLabel', adlar, 'YScale', 'log'); grid on; ylabel('karesel ortalama hata [°]');
yline(OLCUT, '--r', 'ölçüt 1,5°', 'FontSize', 13); legend(b, {['gürültüsüz, gecikmesiz — ' gk(g1)], ['gürültü 0,3° + gecikme 10 ms — ' gk(g2)]}, 'Location', 'northwest');
title('Aynı test, iki koşul: kart kazançlarıyla'); sekil(fig, '4.1', 'test-sonucu');
writetable(T1, fullfile(ck, 'test_ideal.csv')); writetable(T2, fullfile(ck, 'test_gurultu_gecikme.csv'));
olc('d4_1_ideal', table2struct(T1)); olc('d4_1_ideal_gecti', g1); olc('d4_1_gurultu_gecikme', table2struct(T2)); olc('d4_1_gurultu_gecikme_gecti', g2);

%% 4.2 Parametre taraması ile ayar seçmek
% Kart kazançlarının çarpanları taranır (4 × 4 = 16 koşu). Eklemler bağımsız olduğu için her eklem kendi en iyi hücresini seçer.
kpl = [0.5 0.75 1 1.5]; kdl = [0.25 0.5 0.75 1]; assignin('base', 'sigma', GURULTU); assignin('base', 'gecikme', GECIKME);
in = repmat(Simulink.SimulationInput('kol_bitirme'), 1, 16); n = 0;
for a = 1:4, for b = 1:4, n = n + 1; in(n) = in(n).setVariable('kpk', kpl(a)); in(n) = in(n).setVariable('kdk', kdl(b)); end, end
outs = sim(in, 'ShowProgress', 'off'); kokT = zeros(4, 4, 4); torkT = zeros(4, 4, 4); n = 0;
for a = 1:4
    for b = 1:4
        n = n + 1; kokT(a, b, :) = izleme_hatasi(t, Q, outs(n).aci); torkT(a, b, :) = max(abs(outs(n).tork.Data), [], 1);
    end
end
kpk = ones(1, 4); kdk = ones(1, 4); kokS = zeros(1, 4); sec = zeros(4, 2);
for j = 1:4
    M = kokT(:, :, j); M(torkT(:, :, j) >= P.efor(j)) = Inf;      % torku sınıra dayanan hücreler elenir
    [kokS(j), k] = min(M(:)); [a, b] = ind2sub([4 4], k); sec(j, :) = [a b]; kpk(j) = kpl(a); kdk(j) = kdl(b);
end
fig = yeni_sekil;
for j = 1:4
    subplot(2, 2, j); imagesc(min(kokT(:, :, j), 3), [0 3]); colorbar; hold on; plot(sec(j, 2), sec(j, 1), 'ws', 'MarkerSize', 26, 'LineWidth', 3);
    set(gca, 'XTick', 1:4, 'XTickLabel', compose('%g', kdl), 'YTick', 1:4, 'YTickLabel', compose('%g', kpl)); xlabel('kd çarpanı'); ylabel('kp çarpanı');
    title(sprintf('%s: kp×%g, kd×%g → %.2f°', adlar{j}, kpk(j), kdk(j), kokS(j)));
end
sgtitle('Tarama: karesel ortalama hata [°] (3° ve üstü aynı renk) — beyaz kare: seçilen ayar'); sekil(fig, '4.2', 'ayar-haritasi');
secim = table(P.ad', kpk', kdk', (kpk .* P.kp)', (kdk .* P.kd)', round(squeeze(kokT(3, 4, :)), 2), round(kokS', 2), ...
    'VariableNames', {'eklem', 'kp_carpani', 'kd_carpani', 'kp', 'kd', 'kart_ayari_hata', 'secilen_ayar_hata'});
assignin('base', 'secim', secim); assignin('base', 'kokT', kokT);
komut('4.2', 'ayar-secimi', {'size(kokT)', 'omuz_roll_haritasi = round(kokT(:, :, 2), 2)', 'secim'});
fig = yeni_sekil; plot(t, rad2deg(Q(:, 2)), 'k', 'LineWidth', 1); hold on; i1 = 12; i2 = (sec(2, 1) - 1) * 4 + sec(2, 2);
plot(outs(i1).aci.Time, rad2deg(outs(i1).aci.Data(:, 2))); plot(outs(i2).aci.Time, rad2deg(outs(i2).aci.Data(:, 2)));
grid on; xlim(tw2); ylim(rad2deg([min(Q(:, 2)) max(Q(:, 2))]) + [-15 15]); xlabel('zaman [s]'); ylabel('omuz roll [°]');
legend('kayıt (benzetim)', 'kart ayarı (kp×1, kd×1)', sprintf('seçilen ayar (kp×%g, kd×%g)', kpk(2), kdk(2)), 'Location', 'best');
title('Omuz roll: gürültü ve gecikme altında ayardan önce ve sonra'); sekil(fig, '4.2', 'ayar-once-sonra');
writetable(secim, fullfile(ck, 'ayar_secimi.csv')); save(fullfile(ck, 'ayar_secimi.mat'), 'kpk', 'kdk', 'kokT', 'torkT', 'kpl', 'kdl');
olc('d4_2_kp_carpani', kpk); olc('d4_2_kd_carpani', kdk); olc('d4_2_kok_secilen', round(kokS, 2)); olc('d4_2_kok_kart', round(squeeze(kokT(3, 4, :))', 2));
olc('d4_2_kok_omuz_roll', round(kokT(:, :, 2), 2));

%% 4.3 Raporu otomatik üretmek: figür + tablo
assignin('base', 'kpk', kpk); assignin('base', 'kdk', kdk);
[T3, g3, o3] = kol_testi('kol_bitirme', t, Q, P, OLCUT); rk = fullfile(ck, 'rapor'); if ~exist(rk, 'dir'), mkdir(rk); end
fig = yeni_sekil;
for i = 1:4
    subplot(2, 2, i); plot(t, rad2deg(Q(:, i)), 'k', 'LineWidth', 1); hold on; plot(o3.aci.Time, rad2deg(o3.aci.Data(:, i)), 'Color', renk(i, :), 'LineWidth', 1.2);
    grid on; xlim([0 113.3]); ylabel('[°]'); title(sprintf('%s — hata %.2f°', adlar{i}, T3.kok_hata_derece(i)));
end
sgtitle('Çay servisi kaydı (siyah) ve model — seçilen ayar, gürültü + gecikme');
exportgraphics(fig, fullfile(rk, 'izleme.png'), 'Resolution', 120, 'BackgroundColor', 'white'); sekil(fig, '4.3', 'rapor-izleme');
fig = yeni_sekil; b = bar(T3.kok_hata_derece); b.FaceColor = 'flat'; b.CData = renk; set(gca, 'XTickLabel', adlar); grid on; ylabel('karesel ortalama hata [°]');
yline(OLCUT, '--r', 'ölçüt 1,5°', 'FontSize', 13); title(['Ölçüt sonucu: ' gk(g3)]);
exportgraphics(fig, fullfile(rk, 'olcut.png'), 'Resolution', 120, 'BackgroundColor', 'white'); close(fig);
notlar = {'Veri: G1 çay servisi benzetim kaydı (113,3 s, 50 Hz) — gerçek robot ölçümü değildir.', ...
    'Model basitleştirilmiştir: dört eklem birbirinden bağımsız; yerçekimi yalnız eklemin kendi açısına bağlı.', ...
    'Senaryo (ÖRNEK değerler): ölçüm gürültüsü 0,3°, tork gecikmesi 10 ms, denetleyici 50 Hz.', ...
    sprintf('Ölçüt: her eklemde karesel ortalama hata < %.1f° ve tork sınırın altında. Sonuç: %s', OLCUT, gk(g3))};
assignin('base', 'rapor_klasoru', rk); assignin('base', 'T', T3);
komut('4.3', 'rapor', {'help rapor_yaz', 'help kol_testi'});
assignin('base', 'baslik', 'Kol izleme raporu — seçilen ayar');
komut('4.3', 'rapor-dosyalari', {'dosya = rapor_yaz(rapor_klasoru, baslik, T, {''izleme.png'', ''olcut.png''}, {});', ...
    'd = dir(rapor_klasoru); {d(~[d.isdir]).name}''', 'readtable(fullfile(rapor_klasoru, "sonuc.csv"))'});
rapor_yaz(rk, 'Kol izleme raporu — seçilen ayar', T3, {'izleme.png', 'olcut.png'}, notlar);   % notlarla birlikte son hâli
% raporun tek sayfalık özeti (videoda gösterilen): solda ölçüt grafiği, sağda tablo
fig = yeni_sekil; subplot(1, 2, 1); b = bar(T3.kok_hata_derece); b.FaceColor = 'flat'; b.CData = renk; set(gca, 'XTickLabel', adlar); xtickangle(30); grid on;
ylabel('karesel ortalama hata [°]'); yline(OLCUT, '--r', 'ölçüt 1,5°', 'FontSize', 13); title('izleme hatası');
ax = subplot(1, 2, 2); axis(ax, 'off'); y = 0.95;
text(ax, 0, y, sprintf('%-11s %7s %8s %6s', 'eklem', 'hata°', 'tork', 'sonuç'), 'FontName', 'DejaVu Sans Mono', 'FontSize', 15, 'FontWeight', 'bold', 'Units', 'normalized');
for i = 1:4
    y = y - 0.11;
    text(ax, 0, y, sprintf('%-11s %7.2f %8.2f %6s', adlar{i}, T3.kok_hata_derece(i), T3.tork_max_Nm(i), gk(T3.gecti(i))), 'FontName', 'DejaVu Sans Mono', 'FontSize', 15, 'Units', 'normalized');
end
text(ax, 0, y - 0.16, ['Genel sonuç: ' gk(g3)], 'FontSize', 20, 'FontWeight', 'bold', 'Units', 'normalized');
text(ax, 0, y - 0.30, 'cikti/rapor/rapor.html + sonuc.csv', 'FontSize', 13, 'Units', 'normalized', 'Interpreter', 'none');
sgtitle('Otomatik rapor özeti — seçilen ayar, gürültü 0,3° + gecikme 10 ms'); sekil(fig, '4.3', 'rapor-ozet');
d = dir(rk); olc('d4_3_rapor_dosyalari', {d(~[d.isdir]).name}); olc('d4_3_gecti', g3); olc('d4_3_sonuc', table2struct(T3));

%% 4.4 Bitirme: dört eklemle çay servisi kaydını gürültü ve gecikme altında izlemek
model_ciz('kol_bitirme', '4.4', 'bitirme-model');
ayar = {'kart ayarı', ones(1, 4), ones(1, 4); 'taramayla seçilen ayar', kpk, kdk}; S = cell(1, 2); gec = false(1, 2); O = cell(1, 2);
for i = 1:2
    assignin('base', 'kpk', ayar{i, 2}); assignin('base', 'kdk', ayar{i, 3});
    [S{i}, gec(i), O{i}] = kol_testi('kol_bitirme', t, Q, P, OLCUT);
end
fig = yeni_sekil;
for j = 1:4
    subplot(2, 2, j); plot(t, rad2deg(Q(:, j)), 'k', 'LineWidth', 1); hold on;
    plot(O{1}.aci.Time, rad2deg(O{1}.aci.Data(:, j)), 'Color', [0.6 0.6 0.6]); plot(O{2}.aci.Time, rad2deg(O{2}.aci.Data(:, j)), 'Color', renk(j, :), 'LineWidth', 1.2);
    grid on; xlim([0 113.3]); ylim(rad2deg([min(Q(:, j)) max(Q(:, j))]) + [-10 10]); ylabel('[°]');
    title(sprintf('%s: %.2f° → %.2f°', adlar{j}, S{1}.kok_hata_derece(j), S{2}.kok_hata_derece(j)));
end
sgtitle(sprintf('Bitirme — kart ayarı (gri): %s · seçilen ayar (renkli): %s', gk(gec(1)), gk(gec(2)))); sekil(fig, '4.4', 'bitirme-izleme');
fig = yeni_sekil;
subplot(1, 2, 1); bar([S{1}.kok_hata_derece S{2}.kok_hata_derece]); set(gca, 'XTickLabel', adlar, 'YScale', 'log'); xtickangle(30); grid on; ylabel('karesel ortalama hata [°]');
yline(OLCUT, '--r', 'ölçüt 1,5°', 'FontSize', 13); legend('kart ayarı', 'seçilen ayar', 'Location', 'northwest'); title('izleme hatası');
subplot(1, 2, 2); bar([S{1}.tork_max_Nm S{2}.tork_max_Nm]); set(gca, 'XTickLabel', adlar); xtickangle(30); grid on; ylabel('en büyük tork [N·m]');
yline(P.efor(1), '--r', 'kart sınırı 25 N·m', 'FontSize', 13); title('tork');
sgtitle('Bitirme ölçütleri: hata < 1,5° ve tork sınırın altında'); sekil(fig, '4.4', 'bitirme-olcut');
sonuc = table({ayar{1, 1}; ayar{2, 1}}, [max(S{1}.kok_hata_derece); max(S{2}.kok_hata_derece)], [max(S{1}.tork_max_Nm); max(S{2}.tork_max_Nm)], gec', ...
    'VariableNames', {'ayar', 'en_kotu_eklem_hata_derece', 'en_buyuk_tork_Nm', 'gecti'});
assignin('base', 'sonuc', sonuc); assignin('base', 'eklemler', S{2});
komut('4.4', 'bitirme-test', {'sonuc', 'eklemler'});
bk = fullfile(ck, 'bitirme'); if ~exist(bk, 'dir'), mkdir(bk); end
fig = yeni_sekil; bar([S{1}.kok_hata_derece S{2}.kok_hata_derece]); set(gca, 'XTickLabel', adlar, 'YScale', 'log'); grid on; yline(OLCUT, '--r'); legend('kart ayarı', 'seçilen ayar');
ylabel('karesel ortalama hata [°]'); exportgraphics(fig, fullfile(bk, 'olcut.png'), 'Resolution', 120, 'BackgroundColor', 'white'); close(fig);
rapor_yaz(bk, 'Bitirme: çay servisi kaydını izlemek — seçilen ayar', S{2}, {'olcut.png'}, ...
    {'Veri: G1 çay servisi benzetim kaydı. Model basitleştirilmiştir (eklemler bağımsız).', 'Senaryo (ÖRNEK): gürültü 0,3°, gecikme 10 ms, denetleyici 50 Hz.', ...
    sprintf('Kart ayarı: %s · seçilen ayar: %s', gk(gec(1)), gk(gec(2)))});
writetable(sonuc, fullfile(bk, 'bitirme_sonuc.csv'));
olc('d4_4_sonuc', table2struct(sonuc)); olc('d4_4_kart_ayari', table2struct(S{1})); olc('d4_4_secilen_ayar', table2struct(S{2}));
olc('d4_4_senaryo', struct('gurultu_derece', 0.3, 'gecikme_ms', 10, 'ornekleme_Hz', 50, 'olcut_derece', OLCUT));
close_system('kol_bitirme', 0); disp('HAFTA4 TAMAM');

function s = gk(g)
if g, s = 'GEÇTİ'; else, s = 'KALDI'; end
end
