function sekil(fig, ders, ad)
% Gerçek MATLAB figürünü 1920x1080 PNG olarak kaydeder
d = fullfile(lab_kok, 'ekran', ders); if ~exist(d,'dir'), mkdir(d); end
exportgraphics(fig, fullfile(d, [ad '.png']), 'Resolution', 192, 'BackgroundColor', 'white');
close(fig);
end
