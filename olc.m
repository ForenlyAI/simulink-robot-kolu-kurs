function olc(anahtar, deger)
% Ölçümü OLCUMLER.json'a yazar
f = fullfile(lab_kok, 'OLCUMLER.json');
if exist(f,'file'), S = jsondecode(fileread(f)); else, S = struct; end
S.(matlab.lang.makeValidName(anahtar)) = deger;
fid = fopen(f,'w'); fprintf(fid,'%s', jsonencode(S, 'PrettyPrint', true)); fclose(fid);
end
