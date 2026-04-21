#!/usr/bin/env python3
"""
Convert logocpl.png to app_icon.ico for Windows application
"""

from PIL import Image
import os

def convert_png_to_ico():
    # Paths
    input_png = r'e:\1. S2 Fisika\5. Tesis\Flutter\chili_app\CPL\cpl\assets\logocpl.png'
    output_ico = r'e:\1. S2 Fisika\5. Tesis\Flutter\chili_app\CPL\cpl\windows\runner\resources\app_icon.ico'
    
    try:
        # Open the PNG image
        img = Image.open(input_png)
        
        # Convert RGBA to RGB if necessary
        if img.mode == 'RGBA':
            # Create a white background
            background = Image.new('RGB', img.size, (255, 255, 255))
            background.paste(img, mask=img.split()[3])  # Use alpha channel as mask
            img = background
        
        # Create icon with multiple sizes (standard Windows icon sizes)
        sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        
        # Resize image to 256x256 as base
        img_resized = img.resize((256, 256), Image.Resampling.LANCZOS)
        
        # Create icon list
        icon_list = []
        for size in sizes:
            resized = img_resized.resize(size, Image.Resampling.LANCZOS)
            icon_list.append(resized)
        
        # Save as ICO
        img_resized.save(
            output_ico,
            format='ICO',
            sizes=[(img.size) for img in icon_list]
        )
        
        print(f'✓ Icon conversion successful!')
        print(f'  Source: {input_png}')
        print(f'  Output: {output_ico}')
        print(f'  Sizes: {sizes}')
        
        return True
        
    except FileNotFoundError as e:
        print(f'✗ File not found: {e}')
        return False
    except Exception as e:
        print(f'✗ Error converting image: {e}')
        return False

if __name__ == '__main__':
    convert_png_to_ico()
