#!/usr/bin/env bash
# Temiz kurulum (Linux): MATLAB R2026b + Simulink, ardından dört haftanın tamamını çalıştırır.
# Lisans gerekir: kendi MATLAB lisansınız ya da MathWorks'ün 30 günlük denemesi. Ek araç kutusu gerekmez.
# Kullanım: bash ortam/kur.sh [kurulum_klasörü]
set -euo pipefail
HEDEF="${1:-$HOME/MATLAB/R2026b}"
KOK="$(cd "$(dirname "$0")/.." && pwd)"
if [ ! -x "$HEDEF/bin/matlab" ]; then
  wget -q https://www.mathworks.com/mpm/glnxa64/mpm -O /tmp/mpm && chmod +x /tmp/mpm
  /tmp/mpm install --release=R2026b --destination="$HEDEF" --products MATLAB Simulink
fi
cd "$KOK" && "$HEDEF/bin/matlab" -batch "lab_calistir"
cat cikti/BITTI.txt
python3 komut_ciz.py
