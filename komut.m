function komut(ders, ad, satirlar)
% Komut penceresi kaydı: her satır ">> satır" + MATLAB'ın gerçek çıktısı → ekran/<ders>/<ad>.txt
d = fullfile(lab_kok, 'ekran', ders); if ~exist(d,'dir'), mkdir(d); end
f = fopen(fullfile(d, [ad '.txt']), 'w', 'n', 'UTF-8');
for i = 1:numel(satirlar)
    s = satirlar{i};
    fprintf(f, '>> %s\n', s);
    o = evalin('base', sprintf('evalc(%s)', mat2str(s)));
    o = regexprep(o, '\n{3,}', '\n\n');
    fprintf(f, '%s', o);
end
fclose(f);
end
