# Simulink ile Robot Kolu Kontrolü — kurs dosyaları

Forenly AI Academy'deki **Simulink ile Robot Kolu Kontrolü** kursunun laboratuvar dosyaları. Derslerde ekranda gördüğünüz her komut, grafik ve Simulink modeli bu betiklerle üretildi.

Ön koşul kurs: **MATLAB ve Simulink 101** ([kurs dosyaları](https://github.com/ForenlyAI/matlab-simulink-kurs)). Aynı yardımcılar (`komut`, `sekil`, `model_ciz`, `olc`) burada da kullanılır.

## Gerekenler

- **MATLAB R2026b ve Simulink.** Ek araç kutusu gerekmez.
- MATLAB ücretli bir yazılımdır. Kendi lisansınızla ya da MathWorks'ün [30 günlük ücretsiz denemesiyle](https://www.mathworks.com/campaigns/products/trials.html) çalışabilirsiniz. Deneme hesabıyla [MATLAB Online](https://matlab.mathworks.com/) da kullanılabilir: bu klasörü yükleyip aynı betikleri çalıştırın.

## Nasıl çalıştırılır

1. Bu depoyu indirin (Code → Download ZIP) ve MATLAB'da klasörü açın.
2. Tek bir haftayı çalıştırmak için komut penceresine `hafta1` yazın (`hafta2`, `hafta3`, `hafta4`). Haftalar sırayla çalıştırılmalıdır: sonraki hafta öncekinin kurduğu modelleri kullanır.
3. Hepsini sırayla çalıştırmak için `lab_calistir` yazın. Bittiğinde `cikti/BITTI.txt` oluşur; dört haftanın da `TAMAM` yazması gerekir.

Betikler çalışınca şu klasörler oluşur: `ekran/` (grafikler ve komut kayıtları), `modeller/` (Simulink modelleri), `cikti/` (sonuç dosyaları ve otomatik rapor), `OLCUMLER.json` (ölçülen sayılar).

Linux'ta kurulumdan koşuma kadar her şeyi tek komutla yapmak için: `bash ortam/kur.sh` (MathWorks hesabınızla lisans gerekir).

## Sonucunuzu karşılaştırın

`beklenen/OLCUMLER.json` ekibimizin 2026-10-06 koşumunda ölçtüğü sayılardır. Kendi `OLCUMLER.json` dosyanızla karşılaştırın. `beklenen/ayar_secimi.csv` Ders 4.2'deki taramanın seçtiği ayardır; `beklenen/test_*.csv` Ders 4.1'deki otomatik testin sonuçlarıdır.

Bitirme projesi (Ders 4.4) geçme ölçütü: her eklemde karesel ortalama hata 1,5 dereceden az ve en büyük tork eklem kartındaki sınırın altında.

## Dosyalar

| Dosya | İçerik |
|---|---|
| `hafta1.m` … `hafta4.m` | Her haftanın dört dersi, sırayla |
| `kol_parametre.m`, `kol_hazirla.m` | Eklem kartını ve benzetim kaydını okur |
| `kol_model.m` | Dört eklemli Simulink modelini kuran fonksiyon (seçeneklerle: ayrık zaman, gürültü, gecikme, sürtünme) |
| `yorunge5.m` | Beşinci dereceden yumuşak yörünge (Ders 2.1) |
| `bilek_konumu.m`, `bilek_konumu_tam.m`, `bilek_fcn_ifadeleri.m` | Bilek konumu hesabı (Ders 2.3–2.4) |
| `kol_testi.m`, `izleme_hatasi.m`, `rapor_yaz.m` | Otomatik test, hata ölçümü ve rapor (Hafta 4) |
| `adim_bilgi.m` | Aşım, yerleşme süresi ve kalıcı hata ölçümü |
| `komut.m`, `sekil.m`, `yeni_sekil.m`, `model_ciz.m`, `olc.m`, `lab_kok.m`, `dizi.m`, `ornekle.m` | Kayıt, çizim ve veri yardımcıları |
| `komut_ciz.py` | Komut kayıtlarını resme çizer (isteğe bağlı, Python 3) |
| `veri/cay_servisi_kd_v017_81_0013.hdf5` | Çay servisi benzetim kaydı: 53 eklemin açısı ve hızı × 5666 örnek, sağ bilek duruşu, başarı bilgisi |
| `veri/g1_sag_kol_parametre.csv` | Dört eklem: kayıttaki satır, kazançlar, sınırlar, yerçekimi katsayıları |
| `veri/g1_sag_kol_kutle.csv` | Kolun parçaları: kütle ve eklem eksenlerine uzaklık |
| `ortam/` | Sürüm bilgisi ve temiz kurulum betiği |

## Veri hakkında

Robot verisinin tamamı **benzetim kaydıdır**, gerçek robot ölçümü değildir. Kayıt, Forenly AI'nin [kafe projesinde](https://forenly.ai/work/cafe) Unitree G1 insansı robotunun çay servisini benzetimde yaptığı bir bölümden alınmıştır. Model basitleştirilmiştir: dört eklem birbirinden bağımsız ele alınır. Kayıttan ya da eklem kartından gelmeyen değerler betiklerde **ÖRNEK** diye işaretlidir.

Dosyalar yalnız eğitim amacıyla paylaşılmıştır. © Forenly AI
