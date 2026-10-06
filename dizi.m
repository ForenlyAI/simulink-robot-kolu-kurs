function X = dizi(ts)
% To Workspace çıktısını (timeseries) N×k matrise çevirir (sütun vektör sinyaller k×1×N gelir).
X = ts.Data;
if ndims(X) == 3, X = squeeze(X).'; end
if size(X, 1) ~= numel(ts.Time), X = X.'; end
end
