function kol_model(mdl, varargin)
% G1 sağ kolunun dört eklemi tek modelde (vektör sinyal: omuz pitch, omuz roll, omuz yaw, dirsek).
% BASİTLEŞTİRİLMİŞ MODEL — eklemler birbirinden bağımsız:  J·θ'' = τ − G(θ) − sürtünme,  G(θ) = gc·cos θ + gs·sin θ
% Denetleyici benzetimdeki gibi PD:  τ = kp·(hedef − ölçüm) − kd·hız   (+ seçeneğe göre ileri besleme, integral)
% Parametreler taban çalışma alanından okunur: P (kol_parametre), ref, refhiz, hedef, aci0, Ts, kpk, kdk, ki, Tt, hizlim,
% sigma, alfa, gecikme, Jk, bv, fc  (kol_hazirla hepsini yazar).
%
% Seçenekler (ad, değer):
%   'kaynak'    'basamak' (dört Step + Mux) | 'kayit' | 'yorunge'  (From Workspace: ref = [t q1 q2 q3 q4])
%   'demux'     true: açı sinyalini Demux ile omuz (3) ve dirsek (1) diye ayırır            (Ders 1.1)
%   'ileri'     true: yerçekimi ileri beslemesi G(hedef)                                    (Ders 1.4)
%   'hizsiniri' true: hedefe Rate Limiter (±hizlim rad/s)                                   (Ders 2.2)
%   'integral'  'yok' | 'sarmali' (korumasız) | 'korumali' (geri hesaplamalı sarma koruması) (Ders 2.2)
%   'kinematik' true: MATLAB Function bloğu ile bilek konumu (olmazsa üç Fcn bloğu) | 'fcn': doğrudan Fcn yolu (Ders 2.3)
%   'ayrik'     true: ölçüm Ts ile örneklenir, hız ayrık türevle bulunur, tork Ts boyunca tutulur (Ders 3.1)
%   'gurultu'   true: ölçüme rastgele gürültü (standart sapma sigma)                        (Ders 3.2)
%   'filtre'    true: ayrık alçak geçiren filtre (katsayı alfa) — 'ayrik' ile birlikte      (Ders 3.2)
%   'gecikme'   true: torka Transport Delay (gecikme s)                                     (Ders 3.3)
%   'surtunme'  true: viskoz (bv) ve kuru (fc) sürtünme                                     (Ders 3.4)
%   'hizref'    true: hız hatası kayıttaki hıza göre (refhiz) — isteğe bağlı, derslerde kullanılmaz
%   'adim'      basamak zamanı [s] (metin, varsayılan '0'); Rate Limiter ilk adımda girişi doğrudan geçirir,
%               hız sınırının görünmesi için basamak t > 0 olmalı                            (Ders 2.2)
%   'sure'      benzetim süresi (metin)
S = struct('kaynak','basamak','demux',false,'ileri',false,'hizsiniri',false,'integral','yok','kinematik',false, ...
    'ayrik',false,'gurultu',false,'filtre',false,'gecikme',false,'surtunme',false,'hizref',false,'adim','0','sure','2');
for i = 1:2:numel(varargin), S.(varargin{i}) = varargin{i+1}; end
if S.filtre && ~S.ayrik, error('kol_model: filtre seçeneği ayrik ile birlikte kullanılır'); end
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl);
L = 'simulink/'; EW = {'Multiplication', 'Element-wise(K.*u)'};
gruplar = {};   % {bloklar, ad}: bütün bağlantılar kurulduktan sonra alt sisteme toplanır

% ---- hedef
if strcmp(S.kaynak, 'basamak')
    adlar = {'omuz pitch', 'omuz roll', 'omuz yaw', 'dirsek'};
    ekle([L 'Signal Routing/Mux'], 'Mux', [110 40 115 180], 'Inputs', '4');
    for i = 1:4
        ekle([L 'Sources/Step'], ['Hedef ' adlar{i}], [30 30+38*(i-1) 60 56+38*(i-1)], 'Time', S.adim, ...
            'Before', sprintf('aci0(%d)', i), 'After', sprintf('hedef(%d)', i));
        bagla(['Hedef ' adlar{i} '/1'], sprintf('Mux/%d', i));
    end
    hed = 'Mux/1';
else
    if strcmp(S.kaynak, 'kayit'), ad = 'Kayıt (dört eklem)'; else, ad = 'Yörünge (dört eklem)'; end
    ekle([L 'Sources/From Workspace'], ad, [20 93 115 127], 'VariableName', 'ref', 'Interpolate', 'on');
    hed = [ad '/1'];
end
if S.hizsiniri
    ekle([L 'Discontinuities/Rate Limiter'], 'Hız sınırı', [150 95 190 125], 'RisingSlewLimit', 'hizlim', 'FallingSlewLimit', '-hizlim', 'InitialCondition', '0');
    bagla(hed, 'Hız sınırı/1'); hed = 'Hız sınırı/1';
    ekle([L 'Sinks/To Workspace'], 'hedefk', [150 150 210 175], 'VariableName', 'hedefk', 'SaveFormat', 'Timeseries');
    bagla(hed, 'hedefk/1');
end

% ---- denetleyici (ileri yol)
ekle([L 'Math Operations/Sum'], 'Hata', [230 95 250 125], 'Inputs', '+-', 'IconShape', 'rectangular');
ekle([L 'Math Operations/Gain'], 'kp', [285 95 335 125], 'Gain', 'kpk.*P.kp', EW{:});
isaret = '+-';
if S.ileri, isaret = [isaret '+']; end
if ~strcmp(S.integral, 'yok'), isaret = [isaret '+']; end
ekle([L 'Math Operations/Sum'], 'Tork toplamı', [375 85 395 85+25*numel(isaret)], 'Inputs', isaret, 'IconShape', 'rectangular');
bagla(hed, 'Hata/1'); bagla('Hata/1', 'kp/1'); bagla('kp/1', 'Tork toplamı/1');
istek = 'Tork toplamı/1';
if S.ayrik
    ekle([L 'Discrete/Zero-Order Hold'], 'Tork tutucu', [425 95 460 125], 'SampleTime', 'Ts');
    bagla(istek, 'Tork tutucu/1'); istek = 'Tork tutucu/1';
end
ekle([L 'Discontinuities/Saturation'], 'Tork sınırı', [490 95 530 125], 'UpperLimit', 'P.efor', 'LowerLimit', '-P.efor');
bagla(istek, 'Tork sınırı/1'); uygulanan = 'Tork sınırı/1';
if S.gecikme
    ekle([L 'Continuous/Transport Delay'], 'Gecikme', [560 95 600 125], 'DelayTime', 'max(gecikme, 1e-9)', 'InitialOutput', '0');   % gecikme = 0 da verilebilsin
    bagla(uygulanan, 'Gecikme/1'); uygulanan = 'Gecikme/1';
end

% ---- eklem (dört bağımsız eklem, vektör)
if S.surtunme, ni = '+--'; else, ni = '+-'; end
ekle([L 'Math Operations/Sum'], 'Net tork', [640 90 660 90+22*numel(ni)], 'Inputs', ni, 'IconShape', 'rectangular');
ekle([L 'Math Operations/Gain'], 'Ters eylemsizlik', [695 95 765 125], 'Gain', '1./(Jk.*P.J)', EW{:});
ekle([L 'Continuous/Integrator'], 'Açısal hız', [800 95 830 125], 'InitialCondition', 'zeros(1,4)');
ekle([L 'Continuous/Integrator'], 'Açı', [865 95 895 125], 'InitialCondition', 'aci0');
ekle([L 'Sinks/To Workspace'], 'aci', [960 95 1020 125], 'VariableName', 'aci', 'SaveFormat', 'Timeseries');
ekle([L 'Sinks/To Workspace'], 'tork', [560 30 620 60], 'VariableName', 'tork', 'SaveFormat', 'Timeseries');
bagla(uygulanan, 'Net tork/1'); bagla('Net tork/1', 'Ters eylemsizlik/1'); bagla('Ters eylemsizlik/1', 'Açısal hız/1');
bagla('Açısal hız/1', 'Açı/1'); bagla('Açı/1', 'aci/1'); bagla('Tork sınırı/1', 'tork/1');

% yerçekimi torku G(θ) = gc·cos θ + gs·sin θ
bagla(yercekimi('Açı/1', 'Yerçekimi torku', 'G ', 290, 'left'), 'Net tork/2');
if S.surtunme
    ekle([L 'Math Operations/Gain'], 'Viskoz sürtünme', [700 400 750 430], 'Gain', 'bv', 'Orientation', 'left', EW{:});
    ekle([L 'Math Operations/Gain'], 'Hız ölçeği', [780 450 820 480], 'Gain', '1/0.05', 'Orientation', 'left');
    ekle([L 'Math Operations/Trigonometric Function'], 'tanh', [720 450 750 480], 'Operator', 'tanh', 'Orientation', 'left');
    ekle([L 'Math Operations/Gain'], 'Kuru sürtünme', [650 450 690 480], 'Gain', 'fc', 'Orientation', 'left', EW{:});
    ekle([L 'Math Operations/Sum'], 'Sürtünme torku', [600 410 620 470], 'Inputs', '++', 'IconShape', 'rectangular', 'Orientation', 'left');
    bagla('Açısal hız/1', 'Viskoz sürtünme/1'); bagla('Açısal hız/1', 'Hız ölçeği/1'); bagla('Hız ölçeği/1', 'tanh/1');
    bagla('tanh/1', 'Kuru sürtünme/1'); bagla('Viskoz sürtünme/1', 'Sürtünme torku/1'); bagla('Kuru sürtünme/1', 'Sürtünme torku/2');
    bagla('Sürtünme torku/1', 'Net tork/3');
    gruplar(end+1, :) = {{'Viskoz sürtünme', 'Hız ölçeği', 'tanh', 'Kuru sürtünme', 'Sürtünme torku'}, 'Sürtünme'};
end

% ---- ölçüm yolu (geri besleme)
olcum = 'Açı/1';
if S.gurultu
    ekle([L 'Sources/Random Number'], 'Rastgele sayı', [960 215 1000 245], 'Mean', '0', 'Variance', '1', ...
        'Seed', '[11 22 33 44]', 'SampleTime', 'Ts', 'Orientation', 'left');
    ekle([L 'Math Operations/Gain'], 'Ölçüm gürültüsü', [890 215 930 245], 'Gain', 'sigma', 'Orientation', 'left');
    ekle([L 'Math Operations/Sum'], 'Gürültülü ölçüm', [840 170 860 210], 'Inputs', '++', 'IconShape', 'rectangular', 'Orientation', 'left');
    bagla('Rastgele sayı/1', 'Ölçüm gürültüsü/1'); bagla(olcum, 'Gürültülü ölçüm/1'); bagla('Ölçüm gürültüsü/1', 'Gürültülü ölçüm/2'); olcum = 'Gürültülü ölçüm/1';
end
if S.ayrik
    ekle([L 'Discrete/Zero-Order Hold'], 'Örnekleme', [770 175 805 205], 'SampleTime', 'Ts', 'Orientation', 'left');
    bagla(olcum, 'Örnekleme/1'); olcum = 'Örnekleme/1';
end
if S.filtre
    % y_f[k] = y_f[k-1] + alfa·(y[k] − y_f[k-1])
    ekle([L 'Math Operations/Sum'], 'Filtre farkı', [710 175 730 205], 'Inputs', '+-', 'IconShape', 'rectangular', 'Orientation', 'left');
    ekle([L 'Math Operations/Gain'], 'alfa', [655 175 690 205], 'Gain', 'alfa', 'Orientation', 'left');
    ekle([L 'Math Operations/Sum'], 'Filtre çıkışı', [610 175 630 205], 'Inputs', '++', 'IconShape', 'rectangular', 'Orientation', 'left');
    ekle([L 'Discrete/Unit Delay'], 'Filtre belleği', [655 225 690 255], 'SampleTime', 'Ts', 'InitialCondition', 'aci0');
    bagla(olcum, 'Filtre farkı/1'); bagla('Filtre farkı/1', 'alfa/1'); bagla('alfa/1', 'Filtre çıkışı/1');
    bagla('Filtre çıkışı/1', 'Filtre belleği/1'); bagla('Filtre belleği/1', 'Filtre farkı/2'); bagla('Filtre belleği/1', 'Filtre çıkışı/2');
    olcum = 'Filtre çıkışı/1';
    gruplar(end+1, :) = {{'Filtre farkı', 'alfa', 'Filtre çıkışı', 'Filtre belleği'}, 'Ayrık filtre'};
end
if S.gurultu || S.ayrik
    ekle([L 'Sinks/To Workspace'], 'olcum', [520 235 580 265], 'VariableName', 'olcum', 'SaveFormat', 'Timeseries', 'Orientation', 'left');
    bagla(olcum, 'olcum/1');
end
bagla(olcum, 'Hata/2');

% hız: sürekli modelde açısal hızın kendisi (benzetimdeki gibi), ayrık modelde ölçümün ayrık türevi
if S.ayrik
    ekle([L 'Discrete/Unit Delay'], 'Önceki örnek', [520 175 555 205], 'SampleTime', 'Ts', 'InitialCondition', 'aci0', 'Orientation', 'left');
    ekle([L 'Math Operations/Sum'], 'Fark', [475 165 495 205], 'Inputs', '+-', 'IconShape', 'rectangular', 'Orientation', 'left');
    ekle([L 'Math Operations/Gain'], 'Bölü Ts', [425 170 460 200], 'Gain', '1/Ts', 'Orientation', 'left');
    bagla(olcum, 'Önceki örnek/1'); bagla(olcum, 'Fark/1'); bagla('Önceki örnek/1', 'Fark/2'); bagla('Fark/1', 'Bölü Ts/1');
    hiz = 'Bölü Ts/1';
    gruplar(end+1, :) = {{'Önceki örnek', 'Fark', 'Bölü Ts'}, 'Ayrık türev'};
else
    hiz = 'Açısal hız/1';
end
if S.hizref
    ekle([L 'Sources/From Workspace'], 'Kayıt hızı', [230 235 310 265], 'VariableName', 'refhiz', 'Interpolate', 'on');
    ekle([L 'Math Operations/Sum'], 'Hız farkı', [390 225 410 265], 'Inputs', '+-', 'IconShape', 'rectangular', 'Orientation', 'left');
    bagla(hiz, 'Hız farkı/1'); bagla('Kayıt hızı/1', 'Hız farkı/2'); hiz = 'Hız farkı/1';
end
ekle([L 'Math Operations/Gain'], 'kd', [300 170 350 200], 'Gain', 'kdk.*P.kd', 'Orientation', 'left', EW{:});
bagla(hiz, 'kd/1'); bagla('kd/1', 'Tork toplamı/2');

% ---- ileri besleme ve integral
n = 3;
if S.ileri
    bagla(yercekimi(hed, 'Yerçekimi ileri beslemesi', 'İB ', 0, 'right'), sprintf('Tork toplamı/%d', n)); n = n + 1;
end
if ~strcmp(S.integral, 'yok')
    ekle([L 'Math Operations/Gain'], 'ki', [285 330 335 360], 'Gain', 'ki', EW{:});
    ekle([L 'Continuous/Integrator'], 'İntegral', [420 330 450 360], 'InitialCondition', 'zeros(1,4)');
    bagla('Hata/1', 'ki/1');
    if strcmp(S.integral, 'korumali')
        % geri hesaplama: integral girişine (sınırlanmış tork − istenen tork)/Tt eklenir; doyumda integral büyümez
        ekle([L 'Math Operations/Sum'], 'İntegral girişi', [370 325 390 365], 'Inputs', '++', 'IconShape', 'rectangular');
        ekle([L 'Math Operations/Sum'], 'Doyum farkı', [490 380 510 420], 'Inputs', '+-', 'IconShape', 'rectangular', 'Orientation', 'left');
        ekle([L 'Math Operations/Gain'], 'Sarma koruması', [420 385 460 415], 'Gain', '1/Tt', 'Orientation', 'left');
        bagla('ki/1', 'İntegral girişi/1'); bagla('İntegral girişi/1', 'İntegral/1');
        bagla('Tork sınırı/1', 'Doyum farkı/1'); bagla(istek, 'Doyum farkı/2');
        bagla('Doyum farkı/1', 'Sarma koruması/1'); bagla('Sarma koruması/1', 'İntegral girişi/2');
    else
        bagla('ki/1', 'İntegral/1');
    end
    bagla('İntegral/1', sprintf('Tork toplamı/%d', n));
end

% ---- ek çıktılar
if S.demux
    ekle([L 'Signal Routing/Demux'], 'Demux', [940 150 945 210], 'Outputs', '[3 1]');
    ekle([L 'Sinks/To Workspace'], 'omuz', [990 145 1050 170], 'VariableName', 'omuz', 'SaveFormat', 'Timeseries');
    ekle([L 'Sinks/To Workspace'], 'dirsek', [990 190 1050 215], 'VariableName', 'dirsek', 'SaveFormat', 'Timeseries');
    bagla('Açı/1', 'Demux/1'); bagla('Demux/1', 'omuz/1'); bagla('Demux/2', 'dirsek/1');
end
if ~isequal(S.kinematik, false)
    yontem = bilek_blogu;
    ekle([L 'Sinks/To Workspace'], 'bilek', [1090 35 1150 65], 'VariableName', 'bilek', 'SaveFormat', 'Timeseries');
    bagla('Bilek konumu/1', 'bilek/1');
    assignin('base', 'bilek_yontemi', yontem);
end
for g = 1:size(gruplar, 1), alt_sistem(gruplar{g, 1}, gruplar{g, 2}); end
set_param(mdl, 'Solver', 'ode45', 'MaxStep', '0.002', 'StopTime', S.sure, 'ReturnWorkspaceOutputs', 'on');
save_system(mdl);

% =================== yardımcılar (iç içe fonksiyonlar) ===================
    function ekle(kutuphane, ad, konum, varargin)
        add_block(kutuphane, [mdl '/' ad], 'Position', konum, varargin{:});
    end

    function bagla(nereden, nereye)
        add_line(mdl, nereden, nereye, 'autorouting', 'on');
    end

    function cikis = yercekimi(giris, ad, o, y, yon)
        % G = gc·cos(giriş) + gs·sin(giriş) — beş blok (ön ek o), sonunda "ad" adlı alt sisteme toplanır
        if strcmp(yon, 'left'), x = [800 720 640]; else, x = [150 230 310]; end
        ekle([L 'Math Operations/Trigonometric Function'], [o 'cos'], [x(1) y x(1)+30 y+30], 'Operator', 'cos', 'Orientation', yon);
        ekle([L 'Math Operations/Trigonometric Function'], [o 'sin'], [x(1) y+50 x(1)+30 y+80], 'Operator', 'sin', 'Orientation', yon);
        ekle([L 'Math Operations/Gain'], [o 'gc'], [x(2) y x(2)+45 y+30], 'Gain', 'P.gc', 'Orientation', yon, EW{:});
        ekle([L 'Math Operations/Gain'], [o 'gs'], [x(2) y+50 x(2)+45 y+80], 'Gain', 'P.gs', 'Orientation', yon, EW{:});
        ekle([L 'Math Operations/Sum'], [o 'toplam'], [x(3) y+15 x(3)+20 y+65], 'Inputs', '++', 'IconShape', 'rectangular', 'Orientation', yon);
        bagla(giris, [o 'cos/1']); bagla(giris, [o 'sin/1']); bagla([o 'cos/1'], [o 'gc/1']); bagla([o 'sin/1'], [o 'gs/1']);
        bagla([o 'gc/1'], [o 'toplam/1']); bagla([o 'gs/1'], [o 'toplam/2']);
        gruplar(end+1, :) = {{[o 'cos'], [o 'sin'], [o 'gc'], [o 'gs'], [o 'toplam']}, ad};
        cikis = [o 'toplam/1'];
    end

    function alt_sistem(bloklar, ad)
        % Blokları tek alt sisteme toplar ve adlandırır. Olmazsa model düz kalır (çalışması değişmez).
        once = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'SubSystem');
        try
            h = cellfun(@(b) get_param([mdl '/' b], 'Handle'), bloklar);
            Simulink.BlockDiagram.createSubsystem(h);
            yeni = setdiff(find_system(mdl, 'SearchDepth', 1, 'BlockType', 'SubSystem'), once);
            set_param(yeni{1}, 'Name', ad);
        catch e
            fprintf('kol_model: "%s" alt sisteme toplanamadı (%s) — bloklar düz bırakıldı\n', ad, e.message);
        end
    end

    function yontem = bilek_blogu
        % Bilek konumu modelin içinde: önce MATLAB Function bloğu (kod bilek_konumu.m dosyasından), olmazsa üç Fcn bloğu.
        kod = fileread(fullfile(lab_kok, 'bilek_konumu.m'));
        blok = [mdl '/Bilek konumu'];
        try
            if ischar(S.kinematik) && strcmp(S.kinematik, 'fcn'), error('kol_model:fcn', 'Fcn yolu istendi'); end
            add_block([L 'User-Defined Functions/MATLAB Function'], blok, 'Position', [960 30 1050 70]);
            try
                cfg = get_param(blok, 'MATLABFunctionConfiguration'); cfg.FunctionScript = kod;
            catch
                kok = sfroot; ch = kok.find('-isa', 'Stateflow.EMChart', 'Path', blok); ch.Script = kod;
            end
            bagla('Açı/1', 'Bilek konumu/1');
            yontem = 'MATLAB Function bloğu';
        catch e
            fprintf('kol_model: MATLAB Function bloğu kurulamadı (%s) — Fcn bloklarıyla yedek yol\n', e.message);
            if getSimulinkBlockHandle(blok) > 0, delete_block(blok); end
            ifade = bilek_fcn_ifadeleri; eksen = {'x', 'y', 'z'};
            ekle([L 'Signal Routing/Mux'], 'Bilek konumu', [1045 20 1050 110], 'Inputs', '3');
            for k = 1:3
                ekle([L 'User-Defined Functions/Fcn'], ['Bilek ' eksen{k}], [940 15+32*(k-1) 1010 39+32*(k-1)], 'Expr', ifade{k});
                bagla('Açı/1', ['Bilek ' eksen{k} '/1']); bagla(['Bilek ' eksen{k} '/1'], sprintf('Bilek konumu/%d', k));
            end
            yontem = 'Fcn blokları (yedek yol)';
        end
    end
end
