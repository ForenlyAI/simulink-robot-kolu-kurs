function model_ciz(mdl, ders, ad)
% Simulink model çizimini (gerçek Simulink görüntüsü) PNG olarak kaydeder
d = fullfile(lab_kok, 'ekran', ders); if ~exist(d,'dir'), mkdir(d); end
print(['-s' mdl], '-dpng', '-r200', fullfile(d, [ad '.png']));
end
