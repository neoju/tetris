#!/usr/bin/env python3
"""
Generate 32x32 pixel art block sprites for Tetris
Creates 8 PNG files (7 colors + ghost) with beveled edges
"""

from PIL import Image, ImageDraw
import os

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "blocks")

# Block size
BLOCK_SIZE = 32

# Color definitions (Tetris Guideline standard colors)
COLORS = {
    "cyan": "#00F0F0",  # I-piece
    "blue": "#0000FF",  # J-piece
    "orange": "#FFA500",  # L-piece
    "yellow": "#FFFF00",  # O-piece
    "green": "#00FF00",  # S-piece
    "purple": "#800080",  # T-piece
    "red": "#FF0000",  # Z-piece
}


def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))


def lighten_color(rgb, amount=80):
    """Lighten an RGB color by adding white"""
    return tuple(min(c + amount, 255) for c in rgb)


def darken_color(rgb, amount=60):
    """Darken an RGB color by subtracting from each channel"""
    return tuple(max(c - amount, 0) for c in rgb)


def create_beveled_block(base_color_hex, output_path):
    """Create a 32x32 beveled block sprite"""
    # Create image with transparency
    img = Image.new("RGBA", (BLOCK_SIZE, BLOCK_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Convert hex to RGB
    base_color = hex_to_rgb(base_color_hex)
    light_color = lighten_color(base_color, 80)
    dark_color = darken_color(base_color, 60)

    # Draw main block body (with 2px border for bevel)
    draw.rectangle([0, 0, BLOCK_SIZE - 1, BLOCK_SIZE - 1], fill=base_color)

    # Top edge
    draw.rectangle([0, 0, BLOCK_SIZE - 1, 1], fill=light_color)

    # Bottom edge
    draw.rectangle([0, BLOCK_SIZE - 2, BLOCK_SIZE - 1, BLOCK_SIZE - 1], fill=dark_color)

    # Left edge
    draw.rectangle([0, 0, 1, BLOCK_SIZE - 1], fill=light_color)

    # Right edge
    draw.rectangle([BLOCK_SIZE - 2, 0, BLOCK_SIZE - 1, BLOCK_SIZE - 1], fill=dark_color)

    # Save the image
    img.save(output_path, "PNG")
    print(f"Created: {output_path}")


def create_ghost_block(output_path):
    """Create a 32x32 ghost block (white with 30% opacity and outline)"""
    img = Image.new("RGBA", (BLOCK_SIZE, BLOCK_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # White with 30% opacity (alpha = 77 out of 255)
    ghost_color = (255, 255, 255, 77)
    outline_color = (255, 255, 255, 128)

    # Draw filled rectangle with transparency
    draw.rectangle([1, 1, BLOCK_SIZE - 2, BLOCK_SIZE - 2], fill=ghost_color)

    # Draw outline for visibility
    draw.rectangle([0, 0, BLOCK_SIZE - 1, BLOCK_SIZE - 1], outline=outline_color)

    # Save the image
    img.save(output_path, "PNG")
    print(f"Created: {output_path}")


def main():
    """Generate all block sprites"""
    # Create output directory if it doesn't exist
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print(f"Generating block sprites in: {OUTPUT_DIR}")
    print(f"Block size: {BLOCK_SIZE}x{BLOCK_SIZE}")
    print("-" * 50)

    # Generate colored blocks
    for color_name, hex_color in COLORS.items():
        output_path = os.path.join(OUTPUT_DIR, f"block_{color_name}.png")
        create_beveled_block(hex_color, output_path)

    # Generate ghost block
    ghost_path = os.path.join(OUTPUT_DIR, "block_ghost.png")
    create_ghost_block(ghost_path)

    print("-" * 50)
    print(f"✓ Successfully generated {len(COLORS) + 1} block sprites")


if __name__ == "__main__":
    main()
