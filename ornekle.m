function X = ornekle(ts, ti)
% To Workspace çıktısını (timeseries) verilen zamanlarda okur: her an için o andaki (en son) değer. Tekrarlı zamanlara dayanıklıdır.
[tu, iu] = unique(ts.Time, 'last'); D = ts.Data;
X = interp1(tu, D(iu, :), ti, 'previous', 'extrap');
end
