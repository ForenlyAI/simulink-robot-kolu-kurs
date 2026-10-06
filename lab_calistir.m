% Tüm laboratuvarı koşar (Simulink ile Robot Kolu Kontrolü): hafta1–4.m sırayla.
% Günlük cikti/kosum.log, bitince cikti/BITTI.txt; ölçümler OLCUMLER.json; ekranlar ekran/<ders>/.
% Klasörün yeri fark etmez: yol bu dosyanın konumundan bulunur.
lab_k = fileparts(mfilename('fullpath')); addpath(lab_k); cd(lab_k);
for lab_d = {'cikti', 'modeller', 'ekran'}
    if ~exist(fullfile(lab_k, lab_d{1}), 'dir'), mkdir(fullfile(lab_k, lab_d{1})); end
end
if exist(fullfile(lab_k, 'cikti', 'BITTI.txt'), 'file'), delete(fullfile(lab_k, 'cikti', 'BITTI.txt')); end
if exist(fullfile(lab_k, 'OLCUMLER.json'), 'file'), delete(fullfile(lab_k, 'OLCUMLER.json')); end
diary(fullfile(lab_k, 'cikti', 'kosum.log')); diary on;
fprintf('%s\n%s\n', version, char(datetime('now')));
lab_durum = strings(1, 4);
for lab_h = 1:4
    lab_k = fileparts(mfilename('fullpath'));
    try
        run(fullfile(lab_k, sprintf('hafta%d.m', lab_h))); lab_durum(lab_h) = "TAMAM";
    catch lab_e
        fprintf(2, 'HAFTA%d HATA: %s\n', lab_h, getReport(lab_e, 'extended', 'hyperlinks', 'off')); lab_durum(lab_h) = "HATA";
    end
    lab_k = fileparts(mfilename('fullpath')); cd(lab_k); bdclose all; close all force;
end
fprintf('SONUÇ: %s\n', join("hafta" + (1:4) + " " + lab_durum, " · "));
diary off;
lab_f = fopen(fullfile(lab_k, 'cikti', 'BITTI.txt'), 'w', 'n', 'UTF-8');
fprintf(lab_f, 'bitti %s — %s\n', char(datetime('now')), join("hafta" + (1:4) + " " + lab_durum, " · ")); fclose(lab_f);
