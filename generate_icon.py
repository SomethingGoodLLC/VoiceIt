#!/usr/bin/env python3
"""
Generate VoiceIt app icon with waveform symbol
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_gradient(width, height, color1, color2):
    """Create a vertical gradient"""
    base = Image.new('RGB', (width, height), color1)
    top = Image.new('RGB', (width, height), color2)
    mask = Image.new('L', (width, height))
    mask_data = []
    for y in range(height):
        mask_data.extend([int(255 * (y / height))] * width)
    mask.putdata(mask_data)
    base.paste(top, (0, 0), mask)
    return base

def draw_waveform(draw, center_x, center_y, size, color):
    """Draw a simple waveform icon"""
    bar_width = size // 10
    spacing = size // 12
    
    # 5 vertical bars of varying heights
    bars = [
        (center_x - 2 * (bar_width + spacing), center_y, 0.5),  # Left
        (center_x - (bar_width + spacing), center_y, 0.7),
        (center_x, center_y, 1.0),  # Center (tallest)
        (center_x + (bar_width + spacing), center_y, 0.7),
        (center_x + 2 * (bar_width + spacing), center_y, 0.5),  # Right
    ]
    
    for x, y, height_ratio in bars:
        bar_height = size * height_ratio
        top = y - bar_height // 2
        bottom = y + bar_height // 2
        draw.rounded_rectangle(
            [x - bar_width // 2, top, x + bar_width // 2, bottom],
            radius=bar_width // 2,
            fill=color
        )

def create_app_icon(output_path, size=1024):
    """Create the VoiceIt app icon"""
    # Purple gradient colors (matching app theme)
    color1 = (124, 58, 237)  # #7C3AED (voiceitPurple)
    color2 = (167, 85, 255)  # Lighter purple
    
    # Create gradient background (RGB, fully opaque - iOS adds rounded corners automatically)
    img = create_gradient(size, size, color1, color2)
    draw = ImageDraw.Draw(img)
    
    # Draw waveform symbol in white
    waveform_size = size // 2
    draw_waveform(draw, size // 2, size // 2, waveform_size, (255, 255, 255))
    
    # Save as PNG without alpha channel (fully opaque)
    img.save(output_path, 'PNG')
    print(f"✅ Created app icon: {output_path}")

if __name__ == '__main__':
    # Generate the 1024x1024 icon required by iOS
    icon_path = 'VoiceIt/Assets.xcassets/AppIcon.appiconset/icon-1024.png'
    
    # Check if PIL is installed
    try:
        create_app_icon(icon_path, 1024)
        print(f"\n🎉 App icon generated successfully!")
        print(f"📱 The icon will appear when you build the app.")
    except Exception as e:
        print(f"❌ Error: {e}")
        print(f"\n💡 To fix this, install Pillow:")
        print(f"   pip3 install Pillow")

