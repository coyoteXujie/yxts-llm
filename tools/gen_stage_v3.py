#!/usr/bin/env python3
"""
v3 — 高质量横版舞台批量生成器
目标：每张 80-300KB，5000+ 色，接近手绘质感
"""
from __future__ import annotations
import math, random, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
DATA = PROJECT / "data"
LAYER = PROJECT / "assets" / "world" / "stage_layers"
SCENE = PROJECT / "assets" / "world" / "scenes"
W, H = 1672, 941

PAL = {
    "plain":((182,202,218),(132,152,168),(148,128,78),(108,90,50),(60,120,130),(100,80,55)),
    "field":((192,210,205),(145,165,145),(160,145,75),(120,108,48),(55,115,110),(105,90,50)),
    "town":((188,200,208),(140,148,152),(140,115,78),(100,80,48),(55,110,115),(108,85,52)),
    "city":((182,196,206),(135,142,148),(135,110,75),(95,75,45),(55,110,115),(115,90,55)),
    "water":((168,192,215),(115,148,172),(118,98,68),(82,65,38),(42,108,135),(90,75,48)),
    "river":((165,190,212),(110,140,165),(112,92,62),(78,60,36),(38,105,138),(88,72,45)),
    "lake":((160,188,212),(105,138,165),(108,88,58),(75,58,34),(35,100,138),(85,70,42)),
    "mountain":((155,170,190),(105,120,140),(110,90,60),(78,58,34),(45,95,108),(85,68,42)),
    "forest":((175,200,190),(125,155,135),(108,118,55),(70,85,30),(42,98,102),(88,80,38)),
    "bamboo":((180,205,190),(130,160,135),(112,120,55),(75,88,30),(48,102,108),(90,82,40)),
    "desert":((215,195,165),(178,155,120),(170,138,78),(138,108,50),(55,98,108),(120,95,55)),
    "snow":((208,212,222),(175,185,200),(165,158,152),(132,126,120),(95,125,145),(140,130,120)),
    "sect":((178,190,200),(128,138,148),(125,105,72),(92,72,42),(50,100,112),(110,85,50)),
    "marsh":((168,188,178),(118,142,132),(105,108,58),(72,78,32),(40,95,95),(85,80,42)),
    "gorge":((140,158,178),(90,108,128),(100,82,58),(68,50,30),(36,85,105),(80,65,38)),
    "shadow_sect":((135,135,150),(85,85,100),(82,72,56),(56,46,30),(36,76,86),(70,58,42)),
    "daoist_sect":((178,195,200),(132,148,155),(125,108,72),(92,78,44),(50,102,112),(105,85,50)),
    "snow_sect":((208,212,222),(175,185,200),(165,158,152),(132,126,120),(95,125,145),(140,130,120)),
    "lake_palace":((175,195,215),(125,148,175),(118,102,70),(88,72,42),(45,108,130),(100,82,48)),
}
def rgbo(r,g,b,a=255): return (max(0,min(255,r)),max(0,min(255,g)),max(0,min(255,b)),max(0,min(255,a)))
def xy(x,y): return (round(x),round(y))
def box(x0,y0,x1,y1): return (round(x0),round(y0),round(x1),round(y1))

def pal(terrain):
    for k,v in PAL.items():
        if k in terrain: return v
    return PAL["plain"]

def sky(d, top, bot):
    for y in range(H):
        t=y/max(1,H-1)
        d.line([(0,y),(W,y)],fill=rgbo(round(top[0]+(bot[0]-top[0])*t),round(top[1]+(bot[1]-top[1])*t),round(top[2]+(bot[2]-top[2])*t)))

def mtn(d, by, bh, col, rng, seed):
    r=random.Random(seed)
    pts=[(0,by+bh*0.3)]
    for i in range(24):
        x=W*i/24
        y=by-bh*(0.3+r.random()*0.5)+math.sin(i*1.37)*bh*0.06
        pts.append((x,y))
    pts.append((W,by+bh*0.3))
    d.polygon([(round(px),round(py)) for px,py in pts],fill=col)

def bldg(d, x, y, w, h, col, a, rng):
    r=random.Random(str(x)+str(y)+str(w))
    d.rectangle(box(x-w//2,y-h,x+w//2,y),fill=rgbo(*col,round(a*0.9)))
    rw=int(w*0.75)
    d.polygon([(x-rw,y-h*0.88),(x,y-h*1.18),(x+rw,y-h*0.88)],fill=rgbo(*col,round(a*0.85)))
    for wi in range(2):
        wx=x+(-1 if wi==0 else 1)*w//4
        wy=y-h*0.55
        d.rectangle(box(wx-3,wy-8,wx+3,wy+8),fill=rgbo(200,180,140,round(a*0.7)))
    d.rectangle(box(x-4,y-h*0.15,x+4,y),fill=rgbo(*[c//2 for c in col],round(a*0.9)))

def tree(d, x, y, h, cr, tc, cc, a):
    tw=max(2,round(cr*0.4))
    d.line([xy(x,y),xy(x,y-h)],fill=rgbo(*tc,round(a*0.85)),width=tw)
    for b in range(3):
        bx=x+(-1 if b==0 else 1)*random.Range(8,18)
        by=y-h*random.uniform(0.3,0.7)
        d.line([xy(x,y-h*0.85),xy(bx,by-h*0.15)],fill=rgbo(*tc,round(a*0.5)),width=1)
    d.ellipse(box(x-cr,y-h-cr*0.5,x+cr,y-h+cr*0.5),fill=rgbo(*cc,round(a*0.85)))

# === 地面层 ===
def gen_floor(t, rng):
    skt,skb,gd,ac,wat,bc=pal(t)
    img=Image.new("RGBA",(W,H),(0,0,0,0))
    d=ImageDraw.Draw(img)
    gt=int(H*0.52)
    iw="water" in t or "river" in t or "lake" in t or "canal" in t or "marsh" in t or "ford" in t
    sn="snow" in t
    ds="desert" in t
    sky(d,skt,skb)
    for _ in range(8):
        d.ellipse(box(rng.uniform(-100,W+100),rng.uniform(20,H*0.22),rng.uniform(-50,W+50),rng.uniform(15,H*0.18)),fill=rgbo(255,255,255,round(rng.uniform(30,90))))
    for b in range(3):
        by=gt-H*(0.18+b*0.06);bh=H*(0.06+b*0.03);dim=0.25+b*0.22
        mtn(d,by,bh,rgbo(round(skt[0]*dim),round(skt[1]*dim),round(skt[2]*dim)),rng,f"m{b}")
    if iw:
        d.rectangle(box(0,gt,W,H),fill=rgbo(*wat,255))
        for _ in range(40):
            y=rng.uniform(gt,H);ww=rng.uniform(40,120)
            d.line([(rng.uniform(0,W),y),(rng.uniform(0,W),y+rng.uniform(-3,3))],fill=rgbo(*wat,round(rng.uniform(25,55))),width=rng.randint(1,2))
        for _ in range(15):
            d.ellipse(box(rng.uniform(0,W),rng.uniform(gt+10,H-10),rng.uniform(2,6),rng.uniform(1,3)),fill=rgbo(255,255,255,round(rng.uniform(40,90))))
    elif sn:
        d.rectangle(box(0,gt,W,H),fill=rgbo(215,210,205,255))
        for _ in range(30):
            y=rng.uniform(gt,H)
            d.line([(0,y),(W,y+rng.uniform(-3,3))],fill=rgbo(225,220,215,round(rng.uniform(30,70))),width=rng.randint(2,5))
    elif ds:
        d.rectangle(box(0,gt,W,H),fill=rgbo(*gd,255))
        for _ in range(40):
            y=rng.uniform(gt,H)
            d.line([(0,y),(W,y+rng.uniform(-6,6))],fill=rgbo(*ac,round(rng.uniform(15,30))),width=rng.randint(1,2))
    else:
        d.rectangle(box(0,gt,W,H),fill=rgbo(*gd,255))
        for _ in range(50):
            y=rng.uniform(gt,H)
            d.line([(0,y),(W,y)],fill=rgbo(*ac,round(rng.uniform(10,25))),width=rng.randint(1,3))
        for _ in range(8):
            y=rng.uniform(gt+20,H-20);pw=rng.uniform(60,180)
            d.line([(W//2-pw,y),(W//2+pw,y+rng.uniform(-4,4))],fill=rgbo(*ac,round(rng.uniform(15,35))),width=3)
    if not iw and not sn:
        for _ in range(6):
            tree(d,rng.uniform(-40,W+40),H,rng.uniform(100,180),rng.uniform(18,30),(60,45,30),(50,85,45),rng.uniform(80,140))
    d.rectangle(box(0,H-60,W,H),fill=rgbo(0,0,0,40))
    d.rectangle(box(0,0,W,6),fill=rgbo(0,0,0,30))
    return img

# === 中景层 ===
def gen_mid(t, rt, rng):
    skt,skb,gd,ac,wat,bc=pal(t)
    img=Image.new("RGBA",(W,H),(0,0,0,0))
    d=ImageDraw.Draw(img)
    gt=int(H*0.52)
    im="mountain" in t or "cliff" in t or "pass" in t or "gorge" in t
    ifs="forest" in t or "bamboo" in t or "garden" in t
    ic=rt in("city","town")
    isc=rt=="sect"
    sn="snow" in t
    if im or sn:
        for b in range(3):
            by=gt-H*(0.10+b*0.08);bh=H*(0.08+b*0.05);dim=0.4+b*0.25
            mtn(d,by,bh,rgbo(round(ac[0]*dim),round(ac[1]*dim),round(ac[2]*dim),round(160-b*25)),rng,f"mg{b}")
    if ifs:
        for b in range(2):
            by=gt-H*(0.08+b*0.05);bh=H*(0.06+b*0.04)
            mtn(d,by,bh,rgbo(round(gd[0]*0.5),round(gd[1]*0.7),round(gd[2]*0.5),round(120-b*30)),rng,f"fr{b}")
        for _ in range(10):
            tree(d,rng.uniform(30,W-30),gt+5,rng.uniform(80,140),rng.uniform(18,30),(70,55,35),(55,95,48),rng.uniform(80,150))
    if ic:
        for _ in range(10):
            x=rng.uniform(50,W-50);bw=rng.uniform(45,85);bh=rng.uniform(60,120)
            bldg(d,x,gt,bw,bh,bc,rng.uniform(140,200),rng)
    if isc:
        cx=W//2
        bldg(d,cx,gt,100,140,bc,230,rng)
        for _ in range(4):
            x=cx+(-1 if _<2 else 1)*rng.uniform(100,200);bw=rng.uniform(45,75);bh=rng.uniform(70,100)
            bldg(d,x,gt,bw,bh,bc,rng.uniform(130,180),rng)
        d.rectangle(box(cx-25,gt-80,cx+25,gt),fill=rgbo(*bc,200))
        d.rectangle(box(cx-12,gt-40,cx+12,gt),fill=rgbo(0,0,0,140))
        d.polygon([(cx-35,gt-68),(cx,gt-90),(cx+35,gt-68)],fill=rgbo(*bc,180))
    if sn:
        d.rectangle(box(0,gt,W,H),fill=rgbo(200,195,190,35))
    return img

# === 前景层 ===
def gen_fore(t, rng):
    skt,skb,gd,ac,wat,bc=pal(t)
    img=Image.new("RGBA",(W,H),(0,0,0,0))
    d=ImageDraw.Draw(img)
    ifs="forest" in t or "bamboo" in t or "garden" in t
    im="mountain" in t or "cliff" in t or "pass" in t or "gorge" in t
    ds="desert" in t
    if ifs:
        for _ in range(5):
            x=rng.uniform(-60,W+60)
            if x<100 or x>W-100 or _<2:
                tree(d,x,H,rng.uniform(120,200),rng.uniform(22,35),(50,38,28),(45,78,40),rng.uniform(100,160))
    if im:
        for _ in range(3):
            x=rng.uniform(-30,W+30);rh=rng.uniform(60,120);rw=rng.uniform(30,60)
            d.polygon([(x,H),(x-rw//2,H-rh),(x+rw//2,H-round(rh*0.7))],fill=rgbo(*ac,round(rng.uniform(80,140))))
    if ds:
        for _ in range(4):
            x=rng.uniform(-40,W+40);dh=rng.uniform(25,50);dw=rng.uniform(60,120)
            d.polygon([(x-dw,H),(x,H-dh),(x+dw,H)],fill=rgbo(*ac,round(rng.uniform(50,100))))
    d.rectangle(box(0,H-80,W,H),fill=rgbo(0,0,0,50))
    d.rectangle(box(0,0,10,H),fill=rgbo(0,0,0,35))
    d.rectangle(box(W-10,0,W,H),fill=rgbo(0,0,0,35))
    return img

def gen_scene(t, rng):
    skt,skb,gd,ac,wat,bc=pal(t)
    img=Image.new("RGBA",(W,H),(0,0,0,0))
    d=ImageDraw.Draw(img)
    sky(d,skt,skb)
    for _ in range(6):
        d.ellipse(box(rng.uniform(-50,W+50),rng.uniform(20,H*0.2),rng.uniform(-20,W+20),rng.uniform(15,H*0.16)),fill=rgbo(255,255,255,round(rng.uniform(40,90))))
    gt=int(H*0.52)
    for b in range(3):
        by=gt-H*(0.22+b*0.07);bh=H*(0.07+b*0.04);dim=0.2+b*0.2
        mtn(d,by,bh,rgbo(round(skt[0]*dim),round(skt[1]*dim),round(skt[2]*dim)),rng,f"sc{b}")
    d.rectangle(box(0,gt,W,H),fill=rgbo(*gd,255))
    for _ in range(20):
        y=rng.uniform(gt,H)
        d.line([(0,y),(W,y)],fill=rgbo(*ac,round(rng.uniform(8,20))),width=1)
    d.rectangle(box(0,H-40,W,H),fill=rgbo(0,0,0,30))
    return img

def gen(rid, t, rt):
    p=pal(t);rng=random.Random(f"v3-{rid}")
    f=gen_floor(t,rng);m=gen_mid(t,rt,rng);g=gen_fore(t,rng);s=gen_scene(t,rng)
    LAYER.mkdir(exist_ok=True);SCENE.mkdir(exist_ok=True)
    sl=f"v3_{rid}"
    f.save(LAYER/f"{sl}_floor.png");m.save(LAYER/f"{sl}_midground.png")
    g.save(LAYER/f"{sl}_foreground.png");s.save(SCENE/f"scene_{rid}_v3.png")
    return {"floor":f"res://assets/world/stage_layers/{sl}_floor.png",
            "midground":f"res://assets/world/stage_layers/{sl}_midground.png",
            "foreground":f"res://assets/world/stage_layers/{sl}_foreground.png"}

def main():
    with open(DATA/"regions.json") as f: rs=json.load(f)
    regions=list(rs.values()) if isinstance(rs,dict) else rs
    with open(DATA/"stage_layer_assets.json") as f: stages=json.load(f)
    with open(DATA/"scene_background_assets.json") as f: scenes=json.load(f)
    gs=[]
    for i,r in enumerate(regions):
        rid=r["id"];ex=stages.get(rid,{})
        if isinstance(ex,dict) and "_dnf_" in ex.get("floor",""):
            gs.append(f"  [{i+1}] {r.get('name',rid)}: 跳过(手绘)")
            continue
        print(f"  [{i+1}] {r.get('name',rid)} ({rid})...",end=" ",flush=True)
        try:
            p=gen(rid,r.get("terrain","plain"),r.get("type","wild"))
            stages[rid]=p
            scenes[rid]=f"res://assets/world/scenes/scene_{rid}_v3.png"
            gs.append(f"  [{i+1}] {r.get('name',rid)} ✅")
        except Exception as e:
            gs.append(f"  [{i+1}] {r.get('name',rid)} ❌ {e}")
        print("ok")
    json.dump(stages,open(DATA/"stage_layer_assets.json","w"),indent=2,ensure_ascii=False)
    json.dump(scenes,open(DATA/"scene_background_assets.json","w"),indent=2,ensure_ascii=False)
    for g in gs: print(g)
    sizes=[f.stat().st_size/1024 for f in sorted(LAYER.glob("v3_*.png"))]
    if sizes: print(f"\nv3平均: {sum(sizes)/len(sizes):.0f}KB, 范围: {min(sizes):.0f}-{max(sizes):.0f}KB")

if __name__=="__main__":
    main()