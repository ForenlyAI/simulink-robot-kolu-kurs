#!/usr/bin/env python3
"""MATLAB komut penceresi kaydını (ekran/<ders>/<ad>.txt — gerçek koşum çıktısı) 1920×1080 PNG'ye çizer.
  python3 komut_ciz.py            → tüm .txt dosyaları"""
import pathlib, re
from PIL import Image, ImageDraw, ImageFont
LAB = pathlib.Path(__file__).resolve().parent
F = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"; FB = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
FS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
W, H = 1920, 1080
def ciz(txt):
    satir = [re.sub(r"<[^>]+>", "", l).rstrip() for l in txt.read_text(encoding="utf-8").splitlines()]
    satir = [l for l in satir if l.strip()]
    while satir and not satir[-1]: satir.pop()
    # boş satırları sıkıştır
    s2 = []
    for l in satir:
        if l == "" and s2 and s2[-1] == "": continue
        s2.append(l)
    satir = s2
    boy = 34
    while boy > 18 and (len(satir) * boy * 1.32 > H - 150 or max((len(l) for l in satir), default=0) * boy * 0.61 > W - 100): boy -= 1
    f, fb = ImageFont.truetype(F, boy), ImageFont.truetype(FB, boy)
    im = Image.new("RGB", (W, H), "#ffffff"); dr = ImageDraw.Draw(im)
    dr.rectangle([0, 0, W, 64], fill="#0b3d6b"); dr.text((30, 32), "MATLAB R2026b — Komut Penceresi (Command Window)", font=ImageFont.truetype(FS, 26), fill="#ffffff", anchor="lm")
    dr.text((W - 30, 32), f"ders {txt.parent.name} · gerçek koşum", font=ImageFont.truetype(FS, 22), fill="#c7d7ea", anchor="rm")
    y = 90
    for l in satir:
        if l.startswith(">> ") or l.startswith("   ") and satir and False:
            dr.text((40, y), ">>", font=fb, fill="#0b6e2b"); dr.text((40 + dr.textlength(">> ", font=fb), y), l[3:], font=fb, fill="#111111")
        else:
            dr.text((40, y), l, font=f, fill="#333333")
        y += int(boy * 1.32)
        if y > H - 40: break
    out = txt.with_suffix(".png"); im.save(out); return out, boy, len(satir)
for t in sorted((LAB / "ekran").glob("*/*.txt")):
    print(*ciz(t))
