import os
from PIL import Image, ImageDraw

def create_cinema_logo_image(size=512):
    # Create high-res image with dark OLED background
    img = Image.new("RGBA", (size, size), (5, 5, 5, 255))
    draw = ImageDraw.Draw(img)

    scale = size / 24.0
    
    def sc(val):
        return val * scale

    # Left film strip
    draw.rectangle([sc(3), sc(4), sc(7), sc(20)], fill=(9, 9, 11, 255), outline=(228, 228, 231, 255), width=max(1, int(1.3 * scale)))
    for y in [6.0, 9.0, 12.0, 15.0, 18.0]:
        draw.rounded_rectangle([sc(4), sc(y - 0.5), sc(6), sc(y + 0.5)], radius=sc(0.2), fill=(228, 228, 231, 255))

    # Right film strip
    draw.rectangle([sc(17), sc(4), sc(21), sc(20)], fill=(9, 9, 11, 255), outline=(228, 228, 231, 255), width=max(1, int(1.3 * scale)))
    for y in [6.0, 9.0, 12.0, 15.0, 18.0]:
        draw.rounded_rectangle([sc(18), sc(y - 0.5), sc(20), sc(y + 0.5)], radius=sc(0.2), fill=(228, 228, 231, 255))

    # Center screen frame
    draw.rounded_rectangle([sc(8), sc(5), sc(16), sc(19)], radius=sc(1.2), fill=(9, 9, 11, 255), outline=(228, 228, 231, 255), width=max(1, int(1.3 * scale)))
    draw.line([sc(8), sc(9), sc(16), sc(9)], fill=(82, 82, 91, 255), width=max(1, int(0.8 * scale)))
    draw.line([sc(8), sc(15), sc(16), sc(15)], fill=(82, 82, 91, 255), width=max(1, int(0.8 * scale)))

    # Red accent center play triangle
    draw.polygon([(sc(10.5), sc(9.5)), (sc(14.5), sc(12.0)), (sc(10.5), sc(14.5))], fill=(229, 9, 20, 255), outline=(228, 228, 231, 255))

    return img

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    web_dir = os.path.join(root_dir, "web")
    icons_dir = os.path.join(web_dir, "icons")
    os.makedirs(icons_dir, exist_ok=True)

    # 1. Favicon (64x64)
    fav = create_cinema_logo_image(64)
    fav.save(os.path.join(web_dir, "favicon.png"), "PNG")

    # 2. Icon-192
    i192 = create_cinema_logo_image(192)
    i192.save(os.path.join(icons_dir, "Icon-192.png"), "PNG")
    i192.save(os.path.join(icons_dir, "Icon-maskable-192.png"), "PNG")

    # 3. Icon-512
    i512 = create_cinema_logo_image(512)
    i512.save(os.path.join(icons_dir, "Icon-512.png"), "PNG")
    i512.save(os.path.join(icons_dir, "Icon-maskable-512.png"), "PNG")

    print("Generated Pure Cinema Logo icons successfully!")

if __name__ == "__main__":
    main()
