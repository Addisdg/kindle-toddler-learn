#!/usr/bin/env python3
"""
generate_assets.py
Generates high-contrast grayscale PNG assets for the Toddler Learn plugin.
All images are 400x400px, black on white, bold outlines — optimised for e-ink.
"""

from PIL import Image, ImageDraw, ImageFont
import os, math

OUT = os.path.expanduser(
    "~/workspace/kindle-toddler-learn/plugins/toddlerlearn.koplugin/assets"
)
SIZE = 400
BG   = 255   # white
FG   = 0     # black

def new_img():
    img = Image.new("L", (SIZE, SIZE), BG)
    return img, ImageDraw.Draw(img)

def save(img, folder, name):
    path = os.path.join(OUT, folder, f"{name}.png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  saved {folder}/{name}.png")

# ── NUMBERS ────────────────────────────────────────────────────────────────

def draw_number(n):
    img, d = new_img()
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 280)
    except:
        font = ImageFont.load_default()
    text = str(n)
    bbox = d.textbbox((0, 0), text, font=font)
    x = (SIZE - (bbox[2] - bbox[0])) // 2 - bbox[0]
    y = (SIZE - (bbox[3] - bbox[1])) // 2 - bbox[1]
    d.text((x, y), text, fill=FG, font=font)
    save(img, "numbers", str(n))

for n in range(1, 6):
    draw_number(n)

# ── LETTERS ────────────────────────────────────────────────────────────────

def draw_letter(c):
    img, d = new_img()
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 280)
    except:
        font = ImageFont.load_default()
    bbox = d.textbbox((0, 0), c.upper(), font=font)
    x = (SIZE - (bbox[2] - bbox[0])) // 2 - bbox[0]
    y = (SIZE - (bbox[3] - bbox[1])) // 2 - bbox[1]
    d.text((x, y), c.upper(), fill=FG, font=font)
    save(img, "letters", c)

for c in "abcdefghijklmnopqrstuvwxyz":
    draw_letter(c)

# ── ANIMALS ────────────────────────────────────────────────────────────────

def draw_cat():
    img, d = new_img()
    # body
    d.ellipse([100,180,300,340], outline=FG, width=8)
    # head
    d.ellipse([120,80,280,220], outline=FG, width=8)
    # ears
    d.polygon([(130,110),(110,50),(170,95)], outline=FG, fill=FG)
    d.polygon([(270,110),(290,50),(230,95)], outline=FG, fill=FG)
    # eyes
    d.ellipse([148,130,172,154], fill=FG)
    d.ellipse([228,130,252,154], fill=FG)
    # nose
    d.polygon([(193,168),(207,168),(200,178)], fill=FG)
    # whiskers
    d.line([(120,172),(188,168)], fill=FG, width=3)
    d.line([(120,180),(188,176)], fill=FG, width=3)
    d.line([(212,168),(280,172)], fill=FG, width=3)
    d.line([(212,176),(280,180)], fill=FG, width=3)
    # tail
    d.arc([280,240,360,360], start=200, end=320, fill=FG, width=8)
    save(img, "animals", "cat")

def draw_dog():
    img, d = new_img()
    # body
    d.ellipse([90,190,310,350], outline=FG, width=8)
    # head
    d.ellipse([110,70,290,220], outline=FG, width=8)
    # floppy ears
    d.ellipse([80,100,150,200], outline=FG, width=6)
    d.ellipse([250,100,320,200], outline=FG, width=6)
    # eyes
    d.ellipse([145,120,170,145], fill=FG)
    d.ellipse([230,120,255,145], fill=FG)
    # snout
    d.ellipse([160,165,240,210], outline=FG, width=5)
    # nose
    d.ellipse([183,162,217,182], fill=FG)
    # tail
    d.arc([295,150,370,280], start=250, end=360, fill=FG, width=8)
    save(img, "animals", "dog")

def draw_bird():
    img, d = new_img()
    # body
    d.ellipse([100,150,300,320], outline=FG, width=8)
    # head
    d.ellipse([150,60,270,170], outline=FG, width=8)
    # wing
    d.arc([60,160,200,300], start=200, end=340, fill=FG, width=8)
    # beak
    d.polygon([(265,110),(310,125),(265,140)], fill=FG)
    # eye
    d.ellipse([215,90,240,115], fill=FG)
    # tail feathers
    d.line([(105,280),(50,340)], fill=FG, width=8)
    d.line([(110,290),(60,360)], fill=FG, width=8)
    d.line([(120,298),(80,370)], fill=FG, width=8)
    save(img, "animals", "bird")

def draw_fish():
    img, d = new_img()
    # body
    d.ellipse([80,140,310,270], outline=FG, width=8)
    # tail
    d.polygon([(310,150),(380,100),(380,310),(310,260)], outline=FG, fill=BG, width=8)
    # eye
    d.ellipse([110,170,145,205], outline=FG, width=6)
    d.ellipse([120,180,135,195], fill=FG)
    # fin
    d.arc([150,80,260,180], start=180, end=360, fill=FG, width=7)
    # scales suggestion
    d.arc([130,170,200,230], start=0, end=180, fill=FG, width=4)
    d.arc([190,170,260,230], start=0, end=180, fill=FG, width=4)
    save(img, "animals", "fish")

def draw_cow():
    img, d = new_img()
    # body
    d.ellipse([70,190,330,360], outline=FG, width=8)
    # head
    d.ellipse([110,70,290,210], outline=FG, width=8)
    # ears
    d.ellipse([70,110,130,160], outline=FG, width=6)
    d.ellipse([270,110,330,160], outline=FG, width=6)
    # horns
    d.line([(130,80),(110,30)], fill=FG, width=7)
    d.line([(270,80),(290,30)], fill=FG, width=7)
    # eyes
    d.ellipse([145,115,172,142], fill=FG)
    d.ellipse([228,115,255,142], fill=FG)
    # snout
    d.ellipse([148,160,252,215], outline=FG, width=6)
    d.ellipse([165,175,190,195], fill=FG)
    d.ellipse([210,175,235,195], fill=FG)
    # spots
    d.ellipse([100,230,165,285], fill=FG)
    d.ellipse([240,270,300,320], fill=FG)
    save(img, "animals", "cow")

draw_cat()
draw_dog()
draw_bird()
draw_fish()
draw_cow()

# ── FRUIT (fixed) ──────────────────────────────────────────────────────────

def draw_apple():
    img, d = new_img()
    # main body - large and centered
    d.ellipse([60,100,340,360], outline=FG, width=10)
    # white indent at top center
    d.rectangle([155,90,245,130], fill=BG)
    d.ellipse([155,95,245,135], fill=BG)
    # stem - thick and visible
    d.line([(200,98),(220,45)], fill=FG, width=10)
    # leaf - simple oval off stem
    d.ellipse([218,30,295,72], outline=FG, width=8)
    save(img, "fruit", "apple")

def draw_banana():
    img, d = new_img()
    # draw as a thick crescent using two offset ellipses
    # outer ellipse
    d.ellipse([40,60,360,340], outline=FG, width=0, fill=FG)
    # inner ellipse slightly offset to create crescent
    d.ellipse([80,100,360,310], outline=FG, width=0, fill=BG)
    # tips
    d.ellipse([30,185,65,220], fill=FG)
    d.ellipse([185,30,220,65], fill=FG)
    # clean up with white rectangles outside the crescent shape
    d.rectangle([0,0,50,SIZE], fill=BG)
    d.rectangle([0,0,SIZE,50], fill=BG)
    d.rectangle([0,330,SIZE,SIZE], fill=BG)
    # redraw outline
    d.ellipse([40,60,360,340], outline=FG, width=6)
    save(img, "fruit", "banana")

def draw_grapes():
    img, d = new_img()
    positions = [
        (200,100),
        (155,155),(245,155),
        (110,210),(200,210),(290,210),
        (155,265),(245,265),
        (200,320)
    ]
    for (x,y) in positions:
        d.ellipse([x-38,y-38,x+38,y+38], outline=FG, fill=BG, width=7)
    d.line([(200,62),(200,100)], fill=FG, width=8)
    d.arc([165,42,235,82], start=0, end=180, fill=FG, width=7)
    save(img, "fruit", "grapes")

def draw_strawberry():
    img, d = new_img()
    d.polygon([(200,350),(55,140),(345,140)], outline=FG, fill=BG, width=9)
    d.ellipse([55,90,345,210], outline=FG, fill=BG, width=9)
    for sx,sy in [(160,190),(230,190),(195,250),(150,255),(255,245)]:
        d.ellipse([sx-7,sy-10,sx+7,sy+10], fill=FG)
    d.arc([130,55,195,120], start=180, end=360, fill=FG, width=8)
    d.arc([205,55,270,120], start=180, end=360, fill=FG, width=8)
    d.line([(200,55),(200,100)], fill=FG, width=8)
    save(img, "fruit", "strawberry")

def draw_orange():
    img, d = new_img()
    d.ellipse([60,60,340,340], outline=FG, width=10)
    for angle in range(0, 180, 30):
        r = math.radians(angle)
        x1 = 200 + int(140*math.cos(r))
        y1 = 200 + int(140*math.sin(r))
        x2 = 200 - int(140*math.cos(r))
        y2 = 200 - int(140*math.sin(r))
        d.line([(x1,y1),(x2,y2)], fill=FG, width=4)
    d.ellipse([160,160,240,240], fill=BG, outline=FG, width=4)
    d.line([(200,60),(207,30)], fill=FG, width=8)
    save(img, "fruit", "orange")

draw_apple()
draw_banana()
draw_grapes()
draw_strawberry()
draw_orange()

# ── COLORS ─────────────────────────────────────────────────────────────────

def draw_color(name, pattern):
    """pattern: 'fill', 'stripes', 'dots', 'checkers', 'empty' """
    img, d = new_img()
    # outer circle
    d.ellipse([60,60,340,340], outline=FG, width=10)
    if pattern == "fill":
        d.ellipse([70,70,330,330], fill=FG)
    elif pattern == "stripes":
        for y in range(70, 330, 20):
            d.line([(70,y),(330,y)], fill=FG, width=8)
        # clip to circle by drawing white outside
        mask = Image.new("L", (SIZE,SIZE), BG)
        md = ImageDraw.Draw(mask)
        md.ellipse([70,70,330,330], fill=0)
        img = Image.composite(img, Image.new("L",(SIZE,SIZE),BG), mask)
        d = ImageDraw.Draw(img)
        d.ellipse([60,60,340,340], outline=FG, width=10)
    elif pattern == "dots":
        for dy in range(90, 330, 45):
            for dx in range(90, 330, 45):
                if (dx-200)**2 + (dy-200)**2 < 130**2:
                    d.ellipse([dx-12,dy-12,dx+12,dy+12], fill=FG)
    elif pattern == "checkers":
        sq = 40
        for row in range(8):
            for col in range(8):
                if (row+col) % 2 == 0:
                    x1,y1 = 60+col*sq, 60+row*sq
                    x2,y2 = x1+sq, y1+sq
                    cx,cy = (x1+x2)//2, (y1+y2)//2
                    if (cx-200)**2+(cy-200)**2 < 135**2:
                        d.rectangle([x1,y1,x2,y2], fill=FG)
        d.ellipse([60,60,340,340], outline=FG, width=10)
    # label inside
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 48)
    except:
        font = ImageFont.load_default()
    save(img, "colors", name)

draw_color("red",    "fill")       # solid = darkest = red
draw_color("blue",   "stripes")    # stripes = medium = blue
draw_color("green",  "dots")       # dots = medium = green
draw_color("yellow", "checkers")   # checkers = light = yellow
draw_color("white",  "empty")      # empty circle = white

# ── SHAPES ────────────────────────────────────────────────────────────────

def draw_shapes():
    img, d = new_img()
    d.ellipse([70,70,330,330], outline=FG, width=14)
    save(img, "shapes", "circle")

    img, d = new_img()
    d.rectangle([80,80,320,320], outline=FG, width=14)
    save(img, "shapes", "square")

    img, d = new_img()
    d.polygon([(200,55),(55,335),(345,335)], outline=FG, fill=BG)
    d.line([(200,55),(55,335),(345,335),(200,55)], fill=FG, width=14)
    save(img, "shapes", "triangle")

    img, d = new_img()
    points = []
    for i in range(10):
        r = 150 if i % 2 == 0 else 65
        angle = math.radians(-90 + i * 36)
        points.append((200 + int(math.cos(angle) * r), 200 + int(math.sin(angle) * r)))
    d.polygon(points, outline=FG, fill=BG)
    d.line(points + [points[0]], fill=FG, width=12)
    save(img, "shapes", "star")

    img, d = new_img()
    d.ellipse([70,80,210,230], outline=FG, width=12)
    d.ellipse([190,80,330,230], outline=FG, width=12)
    d.polygon([(76,175),(324,175),(200,345)], outline=FG, fill=BG)
    d.line([(76,175),(200,345),(324,175)], fill=FG, width=12)
    save(img, "shapes", "heart")

draw_shapes()

# ── VEHICLES ──────────────────────────────────────────────────────────────

def draw_vehicles():
    img, d = new_img()
    d.rounded_rectangle([65,165,335,280], radius=20, outline=FG, width=10)
    d.polygon([(115,165),(155,105),(255,105),(295,165)], outline=FG, fill=BG)
    d.line([(155,105),(255,105),(295,165),(115,165),(155,105)], fill=FG, width=10)
    d.ellipse([100,255,155,310], outline=FG, width=10)
    d.ellipse([245,255,300,310], outline=FG, width=10)
    save(img, "vehicles", "car")

    img, d = new_img()
    d.rounded_rectangle([55,95,345,290], radius=18, outline=FG, width=10)
    for x in [85,155,225]:
        d.rectangle([x,125,x+55,180], outline=FG, width=7)
    d.line([(80,215),(320,215)], fill=FG, width=8)
    d.ellipse([95,270,145,320], outline=FG, width=9)
    d.ellipse([255,270,305,320], outline=FG, width=9)
    save(img, "vehicles", "bus")

    img, d = new_img()
    for x in [55,150,245]:
        d.rounded_rectangle([x,145,x+95,265], radius=12, outline=FG, width=9)
        d.rectangle([x+18,165,x+58,205], outline=FG, width=6)
    d.line([(50,285),(350,285)], fill=FG, width=8)
    for x in [85,180,275]:
        d.ellipse([x,255,x+45,300], outline=FG, width=7)
    save(img, "vehicles", "train")

    img, d = new_img()
    d.arc([55,125,345,355], start=0, end=180, fill=FG, width=12)
    d.line([(65,240),(335,240)], fill=FG, width=12)
    d.polygon([(120,235),(190,115),(260,235)], outline=FG, fill=BG)
    d.line([(120,235),(190,115),(260,235)], fill=FG, width=10)
    d.arc([95,260,305,345], start=0, end=180, fill=FG, width=7)
    save(img, "vehicles", "boat")

    img, d = new_img()
    d.polygon([(45,210),(355,145),(355,205),(45,260)], outline=FG, fill=BG)
    d.line([(45,210),(355,145),(355,205),(45,260),(45,210)], fill=FG, width=10)
    d.polygon([(175,190),(230,70),(265,175)], outline=FG, fill=BG)
    d.line([(175,190),(230,70),(265,175)], fill=FG, width=9)
    d.polygon([(160,235),(235,325),(255,220)], outline=FG, fill=BG)
    d.line([(160,235),(235,325),(255,220)], fill=FG, width=9)
    save(img, "vehicles", "plane")

draw_vehicles()

# ── BODY ─────────────────────────────────────────────────────────────────

def draw_body():
    img, d = new_img()
    d.line([(130,330),(130,170)], fill=FG, width=28)
    for x, top in [(165,95),(200,80),(235,100),(270,135)]:
        d.line([(x,250),(x,top)], fill=FG, width=24)
    d.arc([100,210,300,365], start=190, end=15, fill=FG, width=24)
    save(img, "body", "hand")

    img, d = new_img()
    d.ellipse([105,80,260,350], outline=FG, width=12)
    d.ellipse([225,245,350,335], outline=FG, width=12)
    for x in [245,275,305,335]:
        d.ellipse([x,220,x+30,250], outline=FG, width=6)
    save(img, "body", "foot")

    img, d = new_img()
    d.ellipse([60,130,340,270], outline=FG, width=12)
    d.ellipse([145,95,255,305], outline=FG, width=10)
    d.ellipse([175,160,225,210], fill=FG)
    save(img, "body", "eye")

    img, d = new_img()
    d.arc([105,60,310,340], start=90, end=275, fill=FG, width=18)
    d.arc([145,125,260,290], start=90, end=285, fill=FG, width=12)
    d.arc([175,175,235,255], start=90, end=285, fill=FG, width=9)
    save(img, "body", "ear")

    img, d = new_img()
    d.line([(205,80),(165,235)], fill=FG, width=16)
    d.arc([130,200,250,310], start=340, end=175, fill=FG, width=14)
    d.ellipse([135,260,175,300], outline=FG, width=8)
    d.ellipse([205,260,245,300], outline=FG, width=8)
    save(img, "body", "nose")

draw_body()

# ── HOUSEHOLD ────────────────────────────────────────────────────────────

def draw_household():
    img, d = new_img()
    d.rounded_rectangle([110,90,265,320], radius=18, outline=FG, width=11)
    d.arc([235,145,340,245], start=270, end=90, fill=FG, width=11)
    d.line([(130,340),(245,340)], fill=FG, width=10)
    save(img, "household", "cup")

    img, d = new_img()
    d.ellipse([140,45,260,165], outline=FG, width=10)
    d.line([(200,165),(200,355)], fill=FG, width=18)
    save(img, "household", "spoon")

    img, d = new_img()
    d.rectangle([65,180,340,285], outline=FG, width=11)
    d.rectangle([65,125,145,180], outline=FG, width=11)
    d.line([(80,285),(80,340)], fill=FG, width=11)
    d.line([(320,285),(320,340)], fill=FG, width=11)
    d.line([(60,165),(345,165)], fill=FG, width=11)
    save(img, "household", "bed")

    img, d = new_img()
    d.rectangle([120,75,285,180], outline=FG, width=11)
    d.rectangle([105,180,305,260], outline=FG, width=11)
    d.line([(135,260),(100,345)], fill=FG, width=10)
    d.line([(275,260),(310,345)], fill=FG, width=10)
    save(img, "household", "chair")

    img, d = new_img()
    d.ellipse([70,70,330,330], outline=FG, width=12)
    d.arc([95,95,305,305], start=25, end=155, fill=FG, width=8)
    d.arc([95,95,305,305], start=205, end=335, fill=FG, width=8)
    d.line([(200,70),(200,330)], fill=FG, width=7)
    save(img, "household", "ball")

draw_household()

# ── EMOTIONS ─────────────────────────────────────────────────────────────

def draw_face(name, mouth):
    img, d = new_img()
    d.ellipse([65,65,335,335], outline=FG, width=12)
    d.ellipse([135,145,170,180], fill=FG)
    d.ellipse([230,145,265,180], fill=FG)
    if mouth == "smile":
        d.arc([125,170,275,285], start=20, end=160, fill=FG, width=12)
    elif mouth == "sad":
        d.arc([125,235,275,340], start=200, end=340, fill=FG, width=12)
    elif mouth == "sleepy":
        d.line([(125,235),(275,235)], fill=FG, width=12)
        d.line([(115,125),(180,140)], fill=FG, width=8)
        d.line([(220,140),(285,125)], fill=FG, width=8)
    elif mouth == "surprised":
        d.ellipse([165,215,235,295], outline=FG, width=11)
    save(img, "emotions", name)

draw_face("happy", "smile")
draw_face("sad", "sad")
draw_face("sleepy", "sleepy")
draw_face("surprised", "surprised")

print("\nDone! All assets generated.")
