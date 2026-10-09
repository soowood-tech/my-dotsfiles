#!/usr/bin/env python3
import sys
import os
import io
import zipfile
import re
import colorsys
from pathlib import Path
from PIL import Image

def rgb_to_hex(r, g, b):
    return f"#{int(r):02x}{int(g):02x}{int(b):02x}"

def get_color_vibrancy(rgb):
    r, g, b = [x / 255.0 for x in rgb]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    # Prefer moderate to high saturation and decent brightness
    score = s * 1.5 + (v if v < 0.9 else (1.8 - v))
    return score, (h, s, v)

def extract_palette(image_path):
    try:
        img = Image.open(image_path).convert("RGB")
        img.thumbnail((200, 200))
        # Quantize to 16 colors
        q = img.quantize(colors=16, method=Image.Quantize.FASTOCTREE)
        palette = q.getpalette()[:48] # 16 colors * 3
        colors = [palette[i:i+3] for i in range(0, len(palette), 3)]
        
        # Sort colors by vibrancy
        scored_colors = []
        for c in colors:
            score, hsv = get_color_vibrancy(c)
            # filter out near-blacks and near-whites for accents
            if hsv[1] > 0.2 and 0.15 < hsv[2] < 0.95:
                scored_colors.append((score, c))
        
        scored_colors.sort(reverse=True, key=lambda x: x[0])
        
        if len(scored_colors) >= 2:
            accent = scored_colors[0][1]
            accent2 = scored_colors[1][1]
        elif len(scored_colors) == 1:
            accent = scored_colors[0][1]
            accent2 = [min(255, int(c * 1.2)) for c in accent]
        else:
            # Fallback cyan / purple
            accent = [80, 190, 250]
            accent2 = [200, 90, 240]
            
        return accent, accent2
    except Exception as e:
        print(f"Error extracting colors: {e}", file=sys.stderr)
        return [80, 190, 250], [200, 90, 240]

def generate_telegram_theme(img_path, hex_accent, hex_accent2, hex_fg):
    palette_file = Path(os.path.expanduser("~/.config/hypr/scripts/night.palette"))
    if not palette_file.exists():
        return
    base_palette = {}
    for line in palette_file.read_text().splitlines():
        m = re.match(r"\s*([A-Za-z]\w*)\s*:\s*(#[0-9a-fA-F]{6,8})\s*;", line)
        if m:
            base_palette[m.group(1)] = m.group(2).lower()

    def parse_rgb(h):
        h = h.lstrip("#")
        return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))

    def format_hex(c, alpha=""):
        return "#" + "".join(f"{max(0, min(255, round(v * 255))):02x}" for v in c) + alpha

    def mix_rgb(a, b, t):
        return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))

    def calc_lum(c):
        return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]

    def calc_chroma(c):
        return max(c) - min(c)

    s = {
        "deep": parse_rgb("#050508"),
        "desk": parse_rgb("#0b0b0f"),
        "face": parse_rgb("#121217"),
        "faceAlt": parse_rgb("#181820"),
        "hover": parse_rgb("#1f1f28"),
        "line": parse_rgb("#272733"),
        "textDim": parse_rgb("#888899"),
        "text": parse_rgb(hex_fg),
        "accent": parse_rgb(hex_accent),
        "accentText": parse_rgb(hex_accent2),
        "onAccent": parse_rgb("#ffffff"),
    }
    ramp = [(0.0, s["deep"]), (0.085, s["desk"]), (0.125, s["face"]), (0.18, s["faceAlt"]),
            (0.26, s["line"]), (0.5, s["textDim"]), (0.93, s["text"]), (1.0, mix_rgb(s["text"], (1, 1, 1), 0.5))]
    ref_dark = parse_rgb(base_palette.get("windowBgActive", "#5288c1"))
    ref_light = parse_rgb(base_palette.get("windowActiveTextFg", "#6ab3f3"))

    def neutral(c):
        y = calc_lum(c)
        for (y0, c0), (y1, c1) in zip(ramp, ramp[1:]):
            if y <= y1:
                return mix_rgb(c0, c1, 0 if y1 == y0 else (y - y0) / (y1 - y0))
        return ramp[-1][1]

    tgt_dark = colorsys.rgb_to_hls(*s["accent"])
    tgt_light = colorsys.rgb_to_hls(*s["accentText"])
    src_dark = colorsys.rgb_to_hls(*ref_dark)
    src_light = colorsys.rgb_to_hls(*ref_light)

    def accent_fn(c):
        h, l, sat = colorsys.rgb_to_hls(*c)
        lo, hi = sorted((src_dark[1], src_light[1]))
        w = 0.5 if hi == lo else min(1.0, max(0.0, (l - lo) / (hi - lo)))
        if src_dark[1] > src_light[1]:
            w = 1.0 - w
        src = tuple(src_dark[i] + (src_light[i] - src_dark[i]) * w for i in range(3))
        tgt = tuple(tgt_dark[i] + (tgt_light[i] - tgt_dark[i]) * w for i in range(3))
        nh = (tgt[0] + (h - src[0]) * 0.3) % 1.0
        nl = min(0.96, max(0.04, l + (tgt[1] - src[1])))
        ns = min(1.0, max(0.0, sat * (tgt[2] / src[2] if src[2] > 0.01 else 1.0)))
        return colorsys.hls_to_rgb(nh, nl, ns)

    out = {}
    for key, val in base_palette.items():
        c, alpha = parse_rgb(val[:7]), val[7:9]
        h = colorsys.rgb_to_hls(*c)[0] * 360
        if val[:7] == "#ffffff" and re.search(r"Active|activeButton|Unread|Badge", key) and not re.search(r"Bg(Over|Ripple|Active)?$", key):
            n = s["onAccent"]
        elif key in ("imageBg", "imageBgTransparent") or (val[:7] == "#000000" and alpha):
            n = c
        elif calc_chroma(c) < 0.22:
            n = neutral(c)
        elif 180 <= h <= 245:
            n = accent_fn(c)
        else:
            n = c
        out[key] = format_hex(n, alpha)

    head = "// Telegram theme generated dynamically from wallpaper\n"
    text = head + "".join(f"{k}: {v};\n" for k, v in out.items())

    buf_bg = io.BytesIO()
    if img_path and os.path.exists(img_path):
        try:
            im = Image.open(img_path).convert("RGB")
            im.thumbnail((1920, 1080), Image.Resampling.LANCZOS)
            im.save(buf_bg, "JPEG", quality=85)
            bg_bytes = buf_bg.getvalue()
        except Exception:
            bg_bytes = None
    else:
        bg_bytes = None

    buf_zip = io.BytesIO()
    with zipfile.ZipFile(buf_zip, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("colors.tdesktop-theme", text.encode("utf-8"))
        if bg_bytes:
            z.writestr("background.jpg", bg_bytes)

    theme_bytes = buf_zip.getvalue()

    targets = [
        os.path.expanduser("~/.config/hypr/theme.tdesktop-theme"),
        os.path.expanduser("~/.local/share/angelos/telegram/angelOS.tdesktop-theme"),
    ]
    for target in targets:
        try:
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with open(target, "wb") as f:
                f.write(theme_bytes)
        except Exception as e:
            print(f"Warning: could not write {target}: {e}", file=sys.stderr)

def main():
    if len(sys.argv) > 1:
        img_path = sys.argv[1]
    else:
        # Default wallpaper search
        pixel_dir = os.path.expanduser("~/Pictures/Pixel")
        if os.path.isdir(pixel_dir):
            files = [os.path.join(pixel_dir, f) for f in os.listdir(pixel_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp'))]
            if files:
                img_path = sorted(files)[0]
            else:
                img_path = ""
        else:
            img_path = ""

    if not img_path or not os.path.exists(img_path):
        print("No valid wallpaper image specified or found, using defaults.")
        accent = [80, 190, 250]
        accent2 = [200, 90, 240]
    else:
        accent, accent2 = extract_palette(img_path)

    hex_accent = rgb_to_hex(*accent)
    hex_accent2 = rgb_to_hex(*accent2)
    hex_bg = "#000000"
    hex_bg_alt = "#0d0d11"
    hex_fg = "#e6e6ec"
    hex_muted = "#555566"

    # Hyprland rgba strings
    hypr_accent = f"rgba({accent[0]:02x}{accent[1]:02x}{accent[2]:02x}ee)"
    hypr_accent2 = f"rgba({accent2[0]:02x}{accent2[1]:02x}{accent2[2]:02x}ee)"

    # 1. Waybar colors.css
    waybar_dir = os.path.expanduser("~/.config/waybar")
    os.makedirs(waybar_dir, exist_ok=True)
    with open(os.path.join(waybar_dir, "colors.css"), "w") as f:
        f.write(f"""/* Dynamic colors generated from wallpaper */
@define-color bg {hex_bg};
@define-color bg-alt {hex_bg_alt};
@define-color fg {hex_fg};
@define-color muted {hex_muted};
@define-color accent {hex_accent};
@define-color accent2 {hex_accent2};
@define-color border-active {hex_accent};
@define-color border-inactive rgba(35, 35, 45, 0.6);
""")

    # 2. Hyprland colors.conf and colors.lua
    hypr_dir = os.path.expanduser("~/.config/hypr")
    os.makedirs(hypr_dir, exist_ok=True)
    with open(os.path.join(hypr_dir, "colors.conf"), "w") as f:
        f.write(f"""# Dynamic colors generated from wallpaper
$accent = {hypr_accent}
$accent2 = {hypr_accent2}
$accent_inactive = rgba(25253555)
$bg = rgba(000000ee)
""")

    with open(os.path.join(hypr_dir, "colors.lua"), "w") as f:
        f.write(f"""-- Dynamic colors generated from wallpaper
return {{
    accent = "{hypr_accent}",
    accent2 = "{hypr_accent2}",
    accent_inactive = "rgba(25253555)",
    bg = "rgba(000000ee)",
}}
""")

    # 3. Kitty colors.conf
    kitty_dir = os.path.expanduser("~/.config/kitty")
    os.makedirs(kitty_dir, exist_ok=True)
    with open(os.path.join(kitty_dir, "colors.conf"), "w") as f:
        f.write(f"""# Dynamic colors generated from wallpaper
background #000000
foreground {hex_fg}
cursor {hex_accent}
cursor_text_color #000000
selection_background {hex_accent}
selection_foreground #000000

# Black
color0 #141419
color8 #444452

# Red
color1 #f44747
color9 #ff6b6b

# Green
color2 #4ec9b0
color10 #6ae2c8

# Yellow
color3 #ce9178
color11 #e5b597

# Blue (Primary Accent)
color4 {hex_accent}
color12 {hex_accent}

# Magenta (Secondary Accent)
color5 {hex_accent2}
color13 {hex_accent2}

# Cyan
color6 {hex_accent}
color14 {hex_accent}

# White
color7 #d4d4d4
color15 #ffffff
""")

    # 4. Foot colors.ini
    foot_dir = os.path.expanduser("~/.config/foot")
    os.makedirs(foot_dir, exist_ok=True)
    with open(os.path.join(foot_dir, "colors.ini"), "w") as f:
        f.write(f"""# Dynamic colors generated from wallpaper
[colors-dark]
alpha=0.80
blur=yes
background={hex_bg.lstrip('#')}
foreground={hex_fg.lstrip('#')}
cursor=000000 {hex_accent.lstrip('#')}
selection-foreground=000000
selection-background={hex_accent.lstrip('#')}

regular0=141419
regular1=f44747
regular2=4ec9b0
regular3=ce9178
regular4={hex_accent.lstrip('#')}
regular5={hex_accent2.lstrip('#')}
regular6={hex_accent.lstrip('#')}
regular7=d4d4d4

bright0=444452
bright1=ff6b6b
bright2=6ae2c8
bright3=e5b597
bright4={hex_accent.lstrip('#')}
bright5={hex_accent2.lstrip('#')}
bright6={hex_accent.lstrip('#')}
bright7=ffffff
""")

    # 5. Cava color snippet
    cava_dir = os.path.expanduser("~/.config/cava")
    os.makedirs(cava_dir, exist_ok=True)
    with open(os.path.join(cava_dir, "colors.cava"), "w") as f:
        f.write(f"""[color]
gradient = 1
gradient_count = 6
gradient_color_1 = '{hex_accent}'
gradient_color_2 = '{hex_accent}'
gradient_color_3 = '{hex_accent2}'
gradient_color_4 = '{hex_accent2}'
gradient_color_5 = '#ff5599'
gradient_color_6 = '#ff2255'
""")

    # 6. Rofi colors.rasi
    rofi_dir = os.path.expanduser("~/.config/rofi")
    os.makedirs(rofi_dir, exist_ok=True)
    with open(os.path.join(rofi_dir, "colors.rasi"), "w") as f:
        f.write(f"""* {{
    bg: #000000dd;
    bg-alt: #111116cc;
    fg: {hex_fg};
    accent: {hex_accent};
    accent2: {hex_accent2};
    border-col: {hex_muted};
}}
""")

    # 7. SDDM theme config (Dynamic colors synced to SDDM)
    username = os.environ.get("USER", "")
    sddm_content = f"""[General]
background=wallpaper.jpg
accent={hex_accent}
accent2={hex_accent2}
bg=#0a0c14
fg={hex_fg}
muted={hex_muted}
font=JetBrainsMono Nerd Font
dimOpacity=0.65
defaultUser={username}
"""
    sddm_user_dir = os.path.expanduser("~/.config/sddm-theme")
    os.makedirs(sddm_user_dir, exist_ok=True)
    with open(os.path.join(sddm_user_dir, "theme.conf"), "w") as f:
        f.write(sddm_content)

    sddm_sys_dir = "/usr/share/sddm/themes/hypr-sync"
    if os.path.isdir(sddm_sys_dir) and os.access(sddm_sys_dir, os.W_OK):
        try:
            with open(os.path.join(sddm_sys_dir, "theme.conf"), "w") as f:
                f.write(sddm_content)
        except Exception as e:
            print(f"Warning: could not write to {sddm_sys_dir}: {e}", file=sys.stderr)

    # 8. Dunst configuration
    dunst_dir = os.path.expanduser("~/.config/dunst")
    os.makedirs(dunst_dir, exist_ok=True)
    with open(os.path.join(dunst_dir, "dunstrc"), "w") as f:
        f.write(f"""[global]
    monitor = 0
    follow = none
    width = 330
    height = (60, 250)
    origin = top-right
    offset = (15, 52)
    scale = 0
    notification_limit = 10

    progress_bar = true
    progress_bar_height = 8
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    progress_bar_corner_radius = 4

    indicate_hidden = yes
    transparency = 10
    separator_height = 2
    padding = 12
    horizontal_padding = 16
    text_icon_padding = 12
    frame_width = 2
    frame_color = "{hex_accent}"
    gap_size = 8
    separator_color = frame
    sort = yes

    font = JetBrainsMono Nerd Font 10
    line_height = 3
    markup = full
    format = "<b>%s</b>\\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes

    enable_recursive_icon_lookup = true
    icon_theme = "Papirus,Adwaita,hicolor"
    icon_position = left
    min_icon_size = 24
    max_icon_size = 48

    sticky_history = yes
    history_length = 20

    corner_radius = 12
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "{hex_bg_alt}ee"
    foreground = "{hex_fg}"
    frame_color = "{hex_muted}"
    timeout = 3

[urgency_normal]
    background = "{hex_bg_alt}ee"
    foreground = "{hex_fg}"
    frame_color = "{hex_accent}"
    timeout = 5

[urgency_critical]
    background = "#1a0508ee"
    foreground = "#ffffff"
    frame_color = "#f44747"
    timeout = 0
""")
    os.system("systemctl --user restart dunst 2>/dev/null || dunstctl reload 2>/dev/null")

    # 9. Telegram Desktop theme
    generate_telegram_theme(img_path, hex_accent, hex_accent2, hex_fg)

    print(f"Colors generated from: {img_path or 'default'}")
    print(f"Accent: {hex_accent} | Accent2: {hex_accent2}")

if __name__ == "__main__":
    main()

