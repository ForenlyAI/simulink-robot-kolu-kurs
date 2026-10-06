function dosya = rapor_yaz(klasor, baslik, T, figurler, notlar)
% Raporu otomatik üretir (Ders 4.3): klasor/rapor.html (başlık + notlar + tablo + figürler) ve klasor/sonuc.csv.
% T: sonuç tablosu · figurler: PNG dosya adları (klasor içinde) · notlar: metin satırları (hücre dizisi)
if ~exist(klasor, 'dir'), mkdir(klasor); end
writetable(T, fullfile(klasor, 'sonuc.csv'));
dosya = fullfile(klasor, 'rapor.html');
f = fopen(dosya, 'w', 'n', 'UTF-8');
fprintf(f, '<!doctype html>\n<html lang="tr"><head><meta charset="utf-8"><title>%s</title>\n', baslik);
fprintf(f, '<style>body{font-family:sans-serif;max-width:960px;margin:24px auto}table{border-collapse:collapse}td,th{border:1px solid #999;padding:4px 10px;text-align:right}img{max-width:100%%}</style></head><body>\n');
fprintf(f, '<h1>%s</h1>\n<p>Üretim: %s · MATLAB %s</p>\n', baslik, char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')), version('-release'));
for i = 1:numel(notlar), fprintf(f, '<p>%s</p>\n', notlar{i}); end
ad = T.Properties.VariableNames;
fprintf(f, '<table>\n<tr>'); fprintf(f, '<th>%s</th>', ad{:}); fprintf(f, '</tr>\n');
for r = 1:height(T)
    fprintf(f, '<tr>');
    for c = 1:width(T)
        v = T{r, c};
        if islogical(v)
            if v, s = 'GEÇTİ'; else, s = 'KALDI'; end
        elseif isnumeric(v)
            s = num2str(v);
        else
            s = char(string(v));
        end
        fprintf(f, '<td>%s</td>', s);
    end
    fprintf(f, '</tr>\n');
end
fprintf(f, '</table>\n');
for i = 1:numel(figurler), fprintf(f, '<p><img src="%s" alt="%s"></p>\n', figurler{i}, figurler{i}); end
fprintf(f, '</body></html>\n'); fclose(f);
end
