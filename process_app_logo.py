import os
from PIL import Image

src_img_path = r"C:\Users\lenovo\.gemini\antigravity\brain\a9ae67c6-ac3e-4261-838d-beac41ddfc7f\.user_uploaded\media_1787920410591.jpg"
app_root = r"e:\sih\smart_mess_app"

img = Image.open(src_img_path)
print(f"Source Image loaded: {img.size}")

# Define Android mipmap sizes
sizes = {
    'mipmap-mdpi': (48, 48),
    'mipmap-hdpi': (72, 72),
    'mipmap-xhdpi': (96, 96),
    'mipmap-xxhdpi': (144, 144),
    'mipmap-xxxhdpi': (192, 192),
}

# 1. Update Android mipmap icons
for folder, size in sizes.items():
    dir_path = os.path.join(app_root, "android", "app", "src", "main", "res", folder)
    os.makedirs(dir_path, exist_ok=True)
    
    resized = img.resize(size, Image.LANCZOS)
    
    icon_path = os.path.join(dir_path, "ic_launcher.png")
    resized.save(icon_path, "PNG")
    print(f"Saved: {icon_path} ({size})")

# 2. Save high-res copies in assets/images/
assets_dir = os.path.join(app_root, "assets", "images")
os.makedirs(assets_dir, exist_ok=True)

logo_512 = img.resize((512, 512), Image.LANCZOS)
logo_512.save(os.path.join(assets_dir, "logo.png"), "PNG")
logo_512.save(os.path.join(assets_dir, "app_logo.png"), "PNG")
print("Saved assets/images/logo.png and app_logo.png (512x512)")

print("All app icons updated successfully!")
