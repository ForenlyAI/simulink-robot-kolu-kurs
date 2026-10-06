% Hafta 3 — Gerçeğe Yakınlık. Ayrık zamanlı denetleyici (50 Hz), ölçüm gürültüsü ve ayrık filtre, gecikme, sürtünme.
% Veri: Forenly kıraathane projesi, G1 çay servisi BENZETİM KAYDI. Model BASİTLEŞTİRİLMİŞ: eklemler birbirinden bağımsız.
% ÖRNEK etiketli değerler (gürültü, gecikme, sürtünme) kayıttan ya da karttan gelmez; etkiyi göstermek için seçilmiştir.
format short g; md = fullfile(lab_kok, 'modeller'); cd(md); bdclose all;
[P, t, Q, Qd] = kol_hazirla; assignin('base', 't', t); assignin('base', 'Q', Q);
adlar = cellstr(P.ad); renk = lines(4); uzanma = Q(475, :);
[~, im] = max(abs(Qd(:, 4))); tw = t(im) + [-0.4 0.4];     % dirseğin en hızlı döndüğü an
[~, im2] = max(abs(Qd(:, 2))); tw2 = t(im2) + [-1 1.5];    % omuz roll'un en hızlı döndüğü an

%% 3.1 Ayrık zamanlı denetleyici: kayıt hızı 50 Hz
kol_model('kol_ileri', 'kaynak', 'kayit', 'ileri', true, 'sure', '113.3'); oS = sim('kol_ileri'); kokS = izleme_hatasi(t, Q, oS.aci);
kol_model('kol_ayrik', 'kaynak', 'kayit', 'ileri', true, 'ayrik', true, 'sure', '113.3'); model_ciz('kol_ayrik', '3.1', 'ayrik-model');
oA = sim('kol_ayrik'); kokA = izleme_hatasi(t, Q, oA.aci);
fig = yeni_sekil;
subplot(2, 1, 1); plot(oA.aci.Time, rad2deg(oA.aci.Data(:, 4))); hold on; stairs(oA.olcum.Time, rad2deg(oA.olcum.Data(:, 4)), 'LineWidth', 1.2);
grid on; xlim(tw); ylabel('dirsek [°]'); legend('eklemin açısı (sürekli)', 'denetleyicinin gördüğü (0,02 s''de bir)', 'Location', 'best');
title('Ayrık zamanlı denetleyici: ölç, hesapla, 0,02 saniye tut');
subplot(2, 1, 2); plot(oS.tork.Time, oS.tork.Data(:, 4)); hold on; stairs(oA.tork.Time, oA.tork.Data(:, 4), 'LineWidth', 1.2);
grid on; xlim(tw); ylabel('dirsek torku [N·m]'); xlabel('zaman [s]'); legend('sürekli denetleyici', 'ayrık denetleyici (50 Hz)', 'Location', 'best');
sekil(fig, '3.1', 'ayrik-tork');
% örnekleme yavaşlarsa: uzanma duruşuna basamak, dört örnekleme aralığı
kol_model('kol_ayrik_basamak', 'kaynak', 'basamak', 'ileri', true, 'ayrik', true, 'sure', '2');
Tsl = [0.005 0.02 0.03 0.04]; in = repmat(Simulink.SimulationInput('kol_ayrik_basamak'), 1, 4);
for i = 1:4, in(i) = in(i).setVariable('Ts', Tsl(i)); in(i) = in(i).setVariable('aci0', zeros(1, 4)); end
outs = sim(in, 'ShowProgress', 'off'); salinim = zeros(4, 4); fig = yeni_sekil; hold on;
for i = 1:4
    x = outs(i).aci; plot(x.Time, rad2deg(x.Data(:, 2))); son = x.Time > 1.5;
    salinim(i, :) = rad2deg(max(x.Data(son, :), [], 1) - min(x.Data(son, :), [], 1));
end
yline(rad2deg(uzanma(2)), '--', 'hedef', 'FontSize', 13); grid on; ylim(rad2deg(uzanma(2)) + [-25 25]); xlabel('zaman [s]'); ylabel('omuz roll [°]');
legend(arrayfun(@(v) sprintf('%g Hz (Ts = %g s)', 1 / v, v), Tsl, 'UniformOutput', false), 'Location', 'southoutside', 'Orientation', 'horizontal', 'NumColumns', 2);
title('Aynı kazançlar, dört örnekleme hızı: yavaşladıkça salınım başlar'); sekil(fig, '3.1', 'ornekleme-hizi');
komut('3.1', 'ornekleme', {'Ts', 'frekans_Hz = 1 / Ts', 'o = sim("kol_ayrik");', 'kok_hata = izleme_hatasi(t, Q, o.aci)', 'tork_max = max(abs(o.tork.Data))'});
olc('d3_1_kok_surekli', round(kokS, 2)); olc('d3_1_kok_ayrik', round(kokA, 2)); olc('d3_1_tork_max', round(max(abs(oA.tork.Data), [], 1), 2));
olc('d3_1_Ts', Tsl); olc('d3_1_salinim_derece', round(salinim, 2));
close_system('kol_ileri', 0); close_system('kol_ayrik', 0); close_system('kol_ayrik_basamak', 0);

%% 3.2 Ölçüm gürültüsü ve ayrık filtre
% Gürültü: standart sapması 0,3° (ÖRNEK). Filtre: y_f[k] = y_f[k-1] + alfa·(y[k] − y_f[k-1]); alfa = 1 filtre yok demek.
assignin('base', 'sigma', deg2rad(0.3));
kol_model('kol_gurultu', 'kaynak', 'kayit', 'ileri', true, 'ayrik', true, 'gurultu', true, 'filtre', true, 'sure', '113.3');
model_ciz('kol_gurultu', '3.2', 'gurultu-model');
try model_ciz('kol_gurultu/Ayrık filtre', '3.2', 'ayrik-filtre'); catch e, fprintf('3.2: filtre alt sistemi çizilemedi (%s)\n', e.message); end
alfal = [1 0.8 0.6 0.5]; in = repmat(Simulink.SimulationInput('kol_gurultu'), 1, 4);
for i = 1:4, in(i) = in(i).setVariable('alfa', alfal(i)); end
outs = sim(in, 'ShowProgress', 'off'); kokG = zeros(4, 4); titreme = zeros(4, 4);
for i = 1:4
    kokG(i, :) = izleme_hatasi(t, Q, outs(i).aci); titreme(i, :) = mean(abs(diff(ornekle(outs(i).tork, t))), 1);   % torkun bir örnekten ötekine ortalama sıçraması
end
fig = yeni_sekil;
subplot(2, 1, 1); plot(outs(1).aci.Time, rad2deg(outs(1).aci.Data(:, 4)), 'k'); hold on;
plot(outs(1).olcum.Time, rad2deg(outs(1).olcum.Data(:, 4)), '.', 'MarkerSize', 12); stairs(outs(3).olcum.Time, rad2deg(outs(3).olcum.Data(:, 4)), 'LineWidth', 1.2);
grid on; xlim(tw); ylabel('dirsek [°]'); legend('eklemin açısı', 'gürültülü ölçüm (0,3°, ÖRNEK)', 'filtreli ölçüm (alfa = 0,6)', 'Location', 'best');
title('Ölçüm gürültüsü ve ayrık filtre');
subplot(2, 1, 2); stairs(t, ornekle(outs(1).tork, t) * [0; 0; 0; 1]); hold on; stairs(t, ornekle(outs(3).tork, t) * [0; 0; 0; 1], 'LineWidth', 1.2);
grid on; xlim(tw); ylabel('dirsek torku [N·m]'); xlabel('zaman [s]'); legend('filtresiz', 'alfa = 0,6', 'Location', 'best'); sekil(fig, '3.2', 'gurultu-olcum');
fig = yeni_sekil;
subplot(1, 2, 1); bar(titreme); set(gca, 'XTickLabel', compose('%g', alfal)); grid on; xlabel('filtre katsayısı alfa'); ylabel('tork sıçraması [N·m]'); title('torktaki titreme');
subplot(1, 2, 2); bar(kokG); set(gca, 'XTickLabel', compose('%g', alfal), 'YScale', 'log'); grid on; xlabel('filtre katsayısı alfa'); ylabel('karesel ortalama hata [°]');
yline(1.5, '--r', 'ölçüt 1,5°', 'FontSize', 13); legend(adlar, 'Location', 'northwest'); title('izleme hatası');
sgtitle('Filtre takası: titreme azalır, gecikme artar'); sekil(fig, '3.2', 'filtre-takas');
tablo = array2table([alfal' round(kokG, 2) round(max(titreme, [], 2), 2)], 'VariableNames', {'alfa', 'omuz_pitch', 'omuz_roll', 'omuz_yaw', 'dirsek', 'tork_sicramasi_Nm'});
assignin('base', 'tablo', tablo); komut('3.2', 'filtre-tablosu', {'sigma_derece = rad2deg(sigma)', 'tablo'});
olc('d3_2_sigma_derece', 0.3); olc('d3_2_alfa', alfal); olc('d3_2_kok', round(kokG, 2)); olc('d3_2_titreme_Nm', round(titreme, 2));
close_system('kol_gurultu', 0); assignin('base', 'sigma', 0);

%% 3.3 Gecikme ve kararlılık sınırı: tarama ile
kol_model('kol_gecikme', 'kaynak', 'kayit', 'ileri', true, 'ayrik', true, 'gecikme', true, 'sure', '113.3'); model_ciz('kol_gecikme', '3.3', 'gecikme-model');
komut('3.3', 'gecikme-taramasi', {'gecikmeler = [0 5 10 15 20] / 1000;', 'in = repmat(Simulink.SimulationInput("kol_gecikme"), 1, 5);', ...
    'for i = 1:5, in(i) = in(i).setVariable("gecikme", gecikmeler(i)); end', 'outs = sim(in, "ShowProgress", "off");', ...
    'kok = zeros(5, 4);', 'for i = 1:5, kok(i, :) = izleme_hatasi(t, Q, outs(i).aci); end', 'kok'});
outs = evalin('base', 'outs'); kokD = evalin('base', 'kok'); gl = [0 5 10 15 20];
sinir = nan(1, 4); for j = 1:4, k = find(kokD(:, j) > 1.5, 1); if ~isempty(k), sinir(j) = gl(k); end, end
fig = yeni_sekil; semilogy(gl, kokD, '-o', 'MarkerSize', 8, 'MarkerFaceColor', 'w'); grid on; yline(1.5, '--r', 'ölçüt 1,5°', 'FontSize', 13);
xlabel('tork gecikmesi [ms] (ÖRNEK)'); ylabel('karesel ortalama hata [°]'); legend(adlar, 'Location', 'northwest');
title('Gecikme taraması: her eklemin kararlılık sınırı farklı'); sekil(fig, '3.3', 'gecikme-taramasi');
fig = yeni_sekil; plot(t, rad2deg(Q(:, 2)), 'k', 'LineWidth', 1); hold on;
for i = 1:3, plot(outs(i).aci.Time, rad2deg(outs(i).aci.Data(:, 2))); end
grid on; xlim(tw2); ylim(rad2deg([min(Q(:, 2)) max(Q(:, 2))]) + [-15 15]); xlabel('zaman [s]'); ylabel('omuz roll [°]');
legend('kayıt (benzetim)', 'gecikme yok', '5 ms', '10 ms', 'Location', 'best'); title('Omuz roll: gecikme büyüdükçe salınım'); sekil(fig, '3.3', 'gecikme-roll');
olc('d3_3_gecikme_ms', gl); olc('d3_3_kok', round(kokD, 2)); olc('d3_3_sinir_ms', sinir);
close_system('kol_gecikme', 0);

%% 3.4 Sürtünme ve duyarlılık taraması
% Model parametreleri yanlışsa ne olur? Eylemsizlik çarpanı Jk = 0,7 / 1 / 1,3 ve üç sürtünme düzeyi (ÖRNEK): yok, az, çok.
kol_model('kol_surtunme', 'kaynak', 'kayit', 'ileri', true, 'ayrik', true, 'surtunme', true, 'sure', '113.3'); model_ciz('kol_surtunme', '3.4', 'surtunme-model');
Jl = [0.7 1 1.3]; Sl = [0 0; 0.1 0.2; 0.3 0.6];   % [viskoz N·m·s/rad, kuru N·m] — ÖRNEK
in = repmat(Simulink.SimulationInput('kol_surtunme'), 1, 9); n = 0;
for a = 1:3
    for b = 1:3
        n = n + 1; in(n) = in(n).setVariable('Jk', Jl(a)); in(n) = in(n).setVariable('bv', Sl(b, 1)); in(n) = in(n).setVariable('fc', Sl(b, 2));
    end
end
outs = sim(in, 'ShowProgress', 'off'); kokF = zeros(3, 3, 4); n = 0;
for a = 1:3, for b = 1:3, n = n + 1; kokF(a, b, :) = izleme_hatasi(t, Q, outs(n).aci); end, end
enk = max(kokF, [], 3);
fig = yeni_sekil; plot(t, rad2deg(Q(:, 4)), 'k', 'LineWidth', 1); hold on;
for b = 1:3, plot(outs(3 + b).aci.Time, rad2deg(outs(3 + b).aci.Data(:, 4))); end
grid on; xlim(tw + [-1 1]); xlabel('zaman [s]'); ylabel('dirsek [°]');
legend('kayıt (benzetim)', 'sürtünme yok', 'az (0,1 · 0,2)', 'çok (0,3 · 0,6)', 'Location', 'best'); title('Sürtünme (ÖRNEK değerler): dirsek hedefin gerisinde kalır');
sekil(fig, '3.4', 'surtunme-etkisi');
fig = yeni_sekil; imagesc(enk); colorbar; set(gca, 'XTick', 1:3, 'XTickLabel', {'sürtünme yok', 'az', 'çok'}, 'YTick', 1:3, 'YTickLabel', compose('J × %g', Jl));
for a = 1:3, for b = 1:3, text(b, a, sprintf('%.2f°', enk(a, b)), 'HorizontalAlignment', 'center', 'FontSize', 18, 'Color', 'w', 'FontWeight', 'bold'); end, end
title('Duyarlılık: en kötü eklemin karesel ortalama hatası'); sekil(fig, '3.4', 'duyarlilik');
tablo = array2table(round(enk, 2), 'VariableNames', {'surtunme_yok', 'surtunme_az', 'surtunme_cok'}, 'RowNames', compose('J x %g', Jl));
assignin('base', 'tablo', tablo); komut('3.4', 'duyarlilik-tablosu', {'tablo'});
olc('d3_4_J_carpani', Jl); olc('d3_4_surtunme', Sl); olc('d3_4_en_kotu_kok', round(enk, 2)); olc('d3_4_kok_dirsek', round(kokF(:, :, 4), 2));
close_system('kol_surtunme', 0); disp('HAFTA3 TAMAM');
