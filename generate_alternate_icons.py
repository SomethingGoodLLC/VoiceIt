#!/usr/bin/env python3
"""
Generate alternate app icons for VoiceIt stealth mode
Creates Calculator, Weather, Notes, and Wellness icons
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

def draw_calculator_icon(draw, center_x, center_y, size, color):
    """Draw calculator symbol (grid + display)"""
    # Display area at top
    display_height = size // 5
    display_width = int(size * 0.8)
    display_x = center_x - display_width // 2
    display_y = center_y - size // 2 + size // 10
    
    draw.rounded_rectangle(
        [display_x, display_y, display_x + display_width, display_y + display_height],
        radius=size // 30,
        fill=color,
        outline=color
    )
    
    # Button grid (3x3)
    button_size = size // 7
    button_spacing = size // 15
    start_y = display_y + display_height + button_spacing * 2
    
    for row in range(3):
        for col in range(3):
            x = center_x - button_size - button_spacing + col * (button_size + button_spacing)
            y = start_y + row * (button_size + button_spacing)
            draw.rounded_rectangle(
                [x, y, x + button_size, y + button_size],
                radius=button_size // 4,
                fill=color
            )

def draw_weather_icon(draw, center_x, center_y, size, color):
    """Draw weather symbol (cloud with sun)"""
    # Sun rays
    ray_length = size // 6
    ray_width = size // 40
    num_rays = 8
    
    for i in range(num_rays):
        angle = (i * 45) * 3.14159 / 180
        import math
        x1 = center_x + math.cos(angle) * (size // 4)
        y1 = center_y - size // 6 + math.sin(angle) * (size // 4)
        x2 = center_x + math.cos(angle) * (size // 4 + ray_length)
        y2 = center_y - size // 6 + math.sin(angle) * (size // 4 + ray_length)
        draw.line([x1, y1, x2, y2], fill=color, width=ray_width)
    
    # Sun circle
    sun_radius = size // 8
    draw.ellipse(
        [center_x - sun_radius, center_y - size // 6 - sun_radius,
         center_x + sun_radius, center_y - size // 6 + sun_radius],
        fill=color
    )
    
    # Cloud (three overlapping circles)
    cloud_y = center_y + size // 10
    
    # Left circle
    draw.ellipse(
        [center_x - size // 4, cloud_y - size // 10,
         center_x, cloud_y + size // 10],
        fill=color
    )
    
    # Middle circle (larger)
    draw.ellipse(
        [center_x - size // 6, cloud_y - size // 6,
         center_x + size // 6, cloud_y + size // 8],
        fill=color
    )
    
    # Right circle
    draw.ellipse(
        [center_x, cloud_y - size // 10,
         center_x + size // 4, cloud_y + size // 10],
        fill=color
    )

def draw_notes_icon(draw, center_x, center_y, size, color):
    """Draw notes symbol (lines on paper)"""
    # Paper outline
    paper_width = int(size * 0.65)
    paper_height = int(size * 0.8)
    paper_x = center_x - paper_width // 2
    paper_y = center_y - paper_height // 2
    
    draw.rounded_rectangle(
        [paper_x, paper_y, paper_x + paper_width, paper_y + paper_height],
        radius=size // 30,
        fill=color
    )
    
    # Horizontal lines (to create contrast, draw slightly darker rectangles)
    # Since we're drawing on white/colored background, just draw the outline
    line_spacing = size // 8
    line_width = int(paper_width * 0.8)
    line_height = size // 40
    line_x = paper_x + paper_width // 10
    
    # Make lines by drawing thin rectangles in background color
    # We'll use a darker shade of the background
    for i in range(4):
        line_y = paper_y + paper_height // 4 + i * line_spacing
        # Draw white lines to create appearance of text
        draw.rectangle(
            [line_x, line_y, line_x + line_width, line_y + line_height],
            fill=(255, 255, 255, 180)
        )

def draw_wellness_icon(draw, center_x, center_y, size, color):
    """Draw wellness symbol (heart)"""
    # Draw heart using circles and polygon
    heart_size = int(size * 0.6)
    
    # Left circle
    left_center_x = center_x - heart_size // 4
    left_center_y = center_y - heart_size // 6
    circle_radius = heart_size // 3
    
    draw.ellipse(
        [left_center_x - circle_radius, left_center_y - circle_radius,
         left_center_x + circle_radius, left_center_y + circle_radius],
        fill=color
    )
    
    # Right circle
    right_center_x = center_x + heart_size // 4
    right_center_y = center_y - heart_size // 6
    
    draw.ellipse(
        [right_center_x - circle_radius, right_center_y - circle_radius,
         right_center_x + circle_radius, right_center_y + circle_radius],
        fill=color
    )
    
    # Bottom triangle
    draw.polygon(
        [
            (left_center_x - circle_radius, left_center_y),
            (right_center_x + circle_radius, right_center_y),
            (center_x, center_y + heart_size // 2)
        ],
        fill=color
    )
    
    # Fill the gap in the middle
    draw.rectangle(
        [left_center_x, left_center_y - circle_radius,
         right_center_x, center_y + heart_size // 4],
        fill=color
    )

def draw_crossstitch_icon(draw, center_x, center_y, size, color):
    """Draw cross-stitch symbol (grid pattern with X stitches)"""
    # Draw a 3x3 grid with cross-stitch X patterns
    grid_size = int(size * 0.8)
    cell_size = grid_size // 3
    start_x = center_x - grid_size // 2
    start_y = center_y - grid_size // 2
    line_width = max(2, size // 30)
    
    # Draw cross stitches in alternating cells
    for row in range(3):
        for col in range(3):
            cell_x = start_x + col * cell_size
            cell_y = start_y + row * cell_size
            padding = cell_size // 6
            
            # Draw X in each cell
            draw.line(
                [cell_x + padding, cell_y + padding,
                 cell_x + cell_size - padding, cell_y + cell_size - padding],
                fill=color, width=line_width
            )
            draw.line(
                [cell_x + cell_size - padding, cell_y + padding,
                 cell_x + padding, cell_y + cell_size - padding],
                fill=color, width=line_width
            )
    
    # Draw grid lines
    thin_width = max(1, size // 60)
    for i in range(4):
        # Vertical lines
        x = start_x + i * cell_size
        draw.line([x, start_y, x, start_y + grid_size], fill=color, width=thin_width)
        # Horizontal lines
        y = start_y + i * cell_size
        draw.line([start_x, y, start_x + grid_size, y], fill=color, width=thin_width)

def create_alternate_icon(icon_type, output_dir, size=180):
    """Create an alternate app icon"""
    
    # Define icon styles
    icon_configs = {
        'Calculator': {
            'colors': ((100, 120, 140), (140, 160, 180)),  # Gray-blue gradient
            'draw_func': draw_calculator_icon
        },
        'Weather': {
            'colors': ((70, 130, 200), (100, 180, 255)),  # Blue gradient
            'draw_func': draw_weather_icon
        },
        'Notes': {
            'colors': ((255, 200, 80), (255, 220, 100)),  # Yellow gradient
            'draw_func': draw_notes_icon
        },
        'Wellness': {
            'colors': ((200, 100, 150), (230, 130, 180)),  # Pink gradient
            'draw_func': draw_wellness_icon
        },
        'CrossStitch': {
            'colors': ((80, 150, 150), (100, 180, 180)),  # Teal gradient
            'draw_func': draw_crossstitch_icon
        }
    }
    
    if icon_type not in icon_configs:
        print(f"❌ Unknown icon type: {icon_type}")
        return
    
    config = icon_configs[icon_type]
    color1, color2 = config['colors']
    draw_func = config['draw_func']
    
    # Create gradient background
    img = create_gradient(size, size, color1, color2)
    draw = ImageDraw.Draw(img, 'RGBA')
    
    # Draw icon symbol in white
    symbol_size = int(size * 0.5)
    draw_func(draw, size // 2, size // 2, symbol_size, (255, 255, 255, 255))
    
    # Determine filename suffix
    scale = size // 60
    if scale == 1:
        suffix = ""  # Base filename for 1x
    else:
        suffix = f"@{scale}x"
        
    # Save the icon
    output_path = os.path.join(output_dir, f"{icon_type}{suffix}.png")
    img.save(output_path, 'PNG')
    print(f"✅ Created {icon_type} icon: {output_path}")

def main():
    """Generate all alternate app icons"""
    # Create Icons directory in VoiceIt/
    output_dir = 'VoiceIt/Icons'
    os.makedirs(output_dir, exist_ok=True)
    
    icon_types = ['Calculator', 'Weather', 'Notes', 'Wellness', 'CrossStitch']
    
    # Generate @1x (60x60), @2x (120x120) and @3x (180x180) for each icon
    for icon_type in icon_types:
        # @1x version (60x60) - base size
        create_alternate_icon(icon_type, output_dir, 60)
        
        # @2x version (120x120)
        create_alternate_icon(icon_type, output_dir, 120)
        
        # @3x version (180x180)
        create_alternate_icon(icon_type, output_dir, 180)
    
    print(f"\n🎉 All alternate icons generated successfully!")
    print(f"📁 Icons saved to: {output_dir}/")
    print(f"\n⚠️  IMPORTANT: You need to add these files to your Xcode project:")
    print(f"   1. In Xcode, right-click on 'VoiceIt' folder")
    print(f"   2. Select 'Add Files to VoiceIt...'")
    print(f"   3. Navigate to the Icons/ folder")
    print(f"   4. Select all .png files")
    print(f"   5. Ensure 'Copy items if needed' is checked")
    print(f"   6. Ensure 'VoiceIt' target is selected")
    print(f"   7. Click 'Add'")
    print(f"\n   Then rebuild the app and upload to App Store Connect.")

if __name__ == '__main__':
    try:
        main()
    except ImportError:
        print("❌ Error: PIL (Pillow) is not installed")
        print("\n💡 To fix this, install Pillow:")
        print("   pip3 install Pillow")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()


