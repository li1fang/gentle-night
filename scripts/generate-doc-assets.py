#!/usr/bin/env python3
"""Generate original documentation artwork, not screenshots or panel measurements.
Optional docs-only dependency: Pillow. Runtime app has no Python dependency.
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs' / 'assets'
OUT.mkdir(parents=True, exist_ok=True)

def font(size):
    return ImageFont.load_default(size=size)

def hash32(value):
    value &= 0xffffffff
    value ^= value >> 16
    value = value * 0x7feb352d & 0xffffffff
    value ^= value >> 15
    value = value * 0x846ca68b & 0xffffffff
    return (value ^ (value >> 16)) & 0xffffffff

# Same survival law and coordinate-hash family as the Metal renderer. This is
# deliberately an illustrated, enlarged-pixel preview, not runtime footage.
W, H = 360, 180
source = Image.new('RGB', (W,H), '#eae8ef')
d = ImageDraw.Draw(source)
d.rectangle((0,0,W,14), fill='#343047')
d.text((9,2), 'Workspace', fill='#eae8ef', font=font(9))
d.rounded_rectangle((10,25,222,169),radius=5,fill='#29263a')
d.text((21,34), 'a quiet place to build',fill='#ded8f3',font=font(11))
for i, length in enumerate([110,140,90,155,120,65,100,135]):
    y=58+i*11
    d.rectangle((21,y,21+length,y+3),fill=['#ab9be5','#7d9fa2','#beb7c9'][i%3])
d.rounded_rectangle((234,25,349,169),radius=5,fill='#faf8f4')
d.text((244,37),'Notes',fill='#343047',font=font(12))
for i,length in enumerate([80,70,85,60,78,65]):
    d.rectangle((244,63+i*12,244+length,65+i*12),fill='#b6afc2')
base = list(source.get_flattened_data()) if hasattr(source, "get_flattened_data") else list(source.getdata())
fields=[]
for y in range(H):
    for x in range(W):
        r2=((x+.5-W/2)**2+(y+.5-H/2)**2)/((W/2)**2+(H/2)**2)
        q=((hash32(x*0x9e3779b9 ^ y*0x85ebca6b ^ 42)>>9)+.5)/8388608
        fields.append((r2,q))

def masked(u,mode='probabilistic'):
    if u<=0:return source.copy()
    if u>=1:return Image.new('RGB',(W,H),'black')
    data=[]
    for rgb,(r2,q) in zip(base,fields):
        if mode=='probabilistic':
            lit=q<(1-u)*math.exp(-3*r2*u/(1-u))
            data.append(rgb if lit else (0,0,0))
        else:
            a=u
            if mode=='iris':
                radius=1-u;inner=max(0,radius-.08)
                t=max(0,min(1,(math.sqrt(r2)-inner)/(radius-inner)))
                a=t*t*(3-2*t)
            data.append(tuple(round(c*(1-a)) for c in rgb))
    image=Image.new('RGB',(W,H));image.putdata(data);return image

def frame(u,label):
    canvas=Image.new('RGB',(800,486),'#11101b')
    draw=ImageDraw.Draw(canvas)
    draw.text((40,25),'PROBABILISTIC DISAPPEARANCE',font=font(17),fill='#c5b7ef')
    draw.text((40,53),'The desktop stays live. The visible pixels become fewer.',font=font(16),fill='#e8e2f0')
    canvas.paste(masked(u).resize((720,360),Image.Resampling.NEAREST),(40,89))
    draw.text((40,461),label,font=font(13),fill='#c3bccf')
    draw.text((496,461),'Accelerated illustration / enlarged pixels',font=font(12),fill='#aaa1b9')
    return canvas

frames=[frame(0,'10 min / begin')];durations=[1000]
for step in range(1,31):
    u=step/30
    frames.append(frame(u,f'{10+50*u:.0f} min / '+('black' if step==30 else 'fading')))
    durations.append(700 if step==30 else 110)
for step in range(1,9):
    frames.append(frame(1-step/8,'Activity / reverse the same pattern'))
    durations.append(100)
frames[0].save(OUT/'probabilistic-demo.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=True,disposal=2)
frame(.5,'35 min / halfway through the fade').save(OUT/'demo-poster.png')

# A static comparison remains usable when animation is disabled.
comparison=Image.new('RGB',(1200,314),'#11101b');draw=ImageDraw.Draw(comparison)
for i,(mode,label) in enumerate([('uniform','Uniform'),('iris','Soft iris'),('probabilistic','Pixel dissolve')]):
    x=24+i*396
    draw.text((x,20),label,font=font(23),fill='#e8e2f0')
    comparison.paste(masked(.5,mode).resize((360,180),Image.Resampling.NEAREST),(x,64))
    desc=['Every pixel grows darker.','A soft edge closes inward.','Original colors, fewer pixels.'][i]
    draw.text((x,263),desc,font=font(16),fill='#bfb4d1')
comparison.save(OUT/'effect-comparison.png')

stars=[]
for i in range(220):
    x=860+(hash32(i+1)%330);y=40+(hash32(i+300)%220)
    r2=((x-1000)/160)**2+((y-150)/110)**2
    if hash32(i+600)/0xffffffff < .7*math.exp(-r2):
        stars.append(f'<rect x="{x}" y="{y}" width="3" height="3" fill="#c4b2ef" opacity="{.3+(i%6)/10}"/>')
hero=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="300" viewBox="0 0 1280 300" role="img" aria-labelledby="title desc">
<title id="title">Gentle Night</title><desc id="desc">A gentle fade to black for your Mac and OLED display. Original artwork of a crescent moon dissolving into pixels.</desc>
<defs><linearGradient id="bg" x2="1" y2="1"><stop stop-color="#171224"/><stop offset="1" stop-color="#0b101b"/></linearGradient><mask id="moon"><rect width="1280" height="300" fill="white"/><circle cx="1049" cy="101" r="64" fill="black"/></mask></defs>
<rect width="1280" height="300" rx="20" fill="url(#bg)"/>
<text x="64" y="67" fill="#b9a4d9" font-family="Arial,sans-serif" font-size="15" letter-spacing="4">A LITTLE LESS LIGHT</text>
<text x="60" y="159" fill="#f1eaf8" font-family="Arial,sans-serif" font-size="76" font-weight="600">Gentle Night</text>
<text x="64" y="205" fill="#c4b7d5" font-family="Arial,sans-serif" font-size="23">A gentle fade to black for your Mac.</text>
<text x="64" y="252" fill="#9685ae" font-family="Arial,sans-serif" font-size="16">macOS · OLED · Swift + Metal · MIT</text>
<circle cx="1013" cy="136" r="78" fill="#d4c4ec" mask="url(#moon)"/>{''.join(stars)}
</svg>'''
(OUT/'hero.svg').write_text(hero)
print('Generated:',', '.join(p.name for p in OUT.iterdir()))
