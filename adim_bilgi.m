function [asim, yerlesme, kalici] = adim_bilgi(t, y, r)
% Basamak cevabı ölçütleri (araç kutusu gerektirmez): aşım %, %2 yerleşme süresi s, kalıcı hata %
asim = max(0, (max(y) - r) / r * 100);
dis = find(abs(y - r) > 0.02 * abs(r));
if isempty(dis), yerlesme = 0; elseif dis(end) == numel(t), yerlesme = Inf; else, yerlesme = t(dis(end) + 1); end
kalici = abs(r - y(end)) / abs(r) * 100;
end
