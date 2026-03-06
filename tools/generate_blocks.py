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

# Color definitions (dimmed from Tetris Guideline standard)
COLORS = {
    "cyan": "#00B0B0",  # I-piece
    "blue": "#0000C0",  # J-piece
    "orange": "#C07800",  # L-piece
    "yellow": "#C0C000",  # O-piece
    "green": "#00B000",  # S-piece
    "purple": "#600060",  # T-piece
    "red": "#C00000",  # Z-piece
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
    """Create a 32x32 inset square block sprite with professional pixel-art beveling"""
    # Create image with transparency
    img = Image.new("RGBA", (BLOCK_SIZE, BLOCK_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Convert hex to RGB
    base_color = hex_to_rgb(base_color_hex)

    # Generate palette
    highlight = lighten_color(base_color, 60)
    shadow = darken_color(base_color, 60)
    deep_shadow = darken_color(base_color, 120)
    inner_shadow = darken_color(base_color, 30)
    inner_highlight = lighten_color(base_color, 30)

    # 1. Base fill
    draw.rectangle([0, 0, BLOCK_SIZE - 1, BLOCK_SIZE - 1], fill=base_color)

    # 2. Outer Bevel (4px wide)
    bw = 4

    # Top edge (highlight)
    draw.rectangle([1, 1, BLOCK_SIZE - 2, bw], fill=highlight)
    # Left edge (highlight)
    draw.rectangle([1, 1, bw, BLOCK_SIZE - 2], fill=highlight)

    # Bottom edge (shadow)
    draw.rectangle(
        [1, BLOCK_SIZE - 1 - bw, BLOCK_SIZE - 2, BLOCK_SIZE - 2], fill=shadow
    )
    # Right edge (shadow)
    draw.rectangle(
        [BLOCK_SIZE - 1 - bw, 1, BLOCK_SIZE - 2, BLOCK_SIZE - 2], fill=shadow
    )

    # Corners to smooth the bevel
    draw.rectangle(
        [1, BLOCK_SIZE - 1 - bw, bw, BLOCK_SIZE - 2], fill=base_color
    )  # Bottom-left mix
    draw.rectangle(
        [BLOCK_SIZE - 1 - bw, 1, BLOCK_SIZE - 2, bw], fill=base_color
    )  # Top-right mix

    # 3. Inner Square (Inset)
    inset = bw + 1
    # Fill the inner square with base color
    draw.rectangle(
        [inset, inset, BLOCK_SIZE - 1 - inset, BLOCK_SIZE - 1 - inset], fill=base_color
    )

    # Inner shadow (top and left) to create recessed look
    draw.line(
        [(inset, inset), (BLOCK_SIZE - 1 - inset, inset)], fill=inner_shadow, width=1
    )
    draw.line(
        [(inset, inset), (inset, BLOCK_SIZE - 1 - inset)], fill=inner_shadow, width=1
    )

    # Inner highlight (bottom and right) to complete recessed look
    draw.line(
        [
            (inset, BLOCK_SIZE - 1 - inset),
            (BLOCK_SIZE - 1 - inset, BLOCK_SIZE - 1 - inset),
        ],
        fill=inner_highlight,
        width=1,
    )
    draw.line(
        [
            (BLOCK_SIZE - 1 - inset, inset),
            (BLOCK_SIZE - 1 - inset, BLOCK_SIZE - 1 - inset),
        ],
        fill=inner_highlight,
        width=1,
    )

    # 4. Outer outline (1px deep shadow) for crisp edge
    draw.rectangle([0, 0, BLOCK_SIZE - 1, BLOCK_SIZE - 1], outline=deep_shadow, width=1)

    # Save the image
    img.save(output_path, "PNG")
    print(f"Created: {output_path}")


def create_ghost_block(output_path):
    """Create a 32x32 ghost block (white with 30% opacity and outline)"""
    img = Image.new("RGBA", (BLOCK_SIZE, BLOCK_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    ghost_color = (255, 255, 255, 38)
    outline_color = (255, 255, 255, 77)

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
