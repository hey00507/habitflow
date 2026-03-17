"""HabitFlow App Icon Generator — Sprout growing from heatmap grid"""

from PIL import Image, ImageDraw
import random
import math

SIZE = 1024
CORNER_RADIUS = 180

# Colors
BG_COLOR = (15, 23, 42)
TEAL_SHADES = [
    (30, 41, 59),      # Level 0 - empty
    (22, 78, 99),      # Level 1 - faint
    (8, 145, 178),     # Level 2 - medium
    (0, 188, 212),     # Level 3 - bright
    (0, 229, 255),     # Level 4 - vivid
]
STEM_COLOR = (0, 188, 212)         # Teal
LEAF_COLOR_L = (0, 210, 230)       # Left leaf - brighter
LEAF_COLOR_R = (0, 172, 193)       # Right leaf - slightly darker
LEAF_HIGHLIGHT = (100, 255, 255)   # Highlight on leaf


def generate_heatmap_data(rows, cols):
    """Bottom rows are brighter, top rows are dimmer."""
    random.seed(42)
    data = []
    for row in range(rows):
        row_data = []
        for col in range(cols):
            # Bottom rows more active
            prob = 0.2 + (row / rows) * 0.6
            if col in (0, cols - 1):
                prob *= 0.5
            if random.random() < prob:
                weights = [0.1, 0.25, 0.3, 0.25, 0.1]
                if row >= rows - 2:
                    weights = [0.05, 0.1, 0.15, 0.35, 0.35]
                level = random.choices(range(5), weights=weights)[0]
            else:
                level = 0
            row_data.append(level)
        data.append(row_data)
    return data


def draw_leaf(draw, cx, cy, angle_deg, length, width, color):
    """Draw a leaf shape using a polygon."""
    angle = math.radians(angle_deg)
    perp = angle + math.pi / 2

    # Tip of the leaf
    tip_x = cx + math.cos(angle) * length
    tip_y = cy - math.sin(angle) * length

    # Control points for leaf width
    mid_x = cx + math.cos(angle) * length * 0.45
    mid_y = cy - math.sin(angle) * length * 0.45

    left_x = mid_x + math.cos(perp) * width
    left_y = mid_y - math.sin(perp) * width

    right_x = mid_x - math.cos(perp) * width
    right_y = mid_y + math.sin(perp) * width

    # Second set of control points closer to tip
    mid2_x = cx + math.cos(angle) * length * 0.7
    mid2_y = cy - math.sin(angle) * length * 0.7

    left2_x = mid2_x + math.cos(perp) * width * 0.6
    left2_y = mid2_y - math.sin(perp) * width * 0.6

    right2_x = mid2_x - math.cos(perp) * width * 0.6
    right2_y = mid2_y + math.sin(perp) * width * 0.6

    points = [
        (cx, cy),
        (left_x, left_y),
        (left2_x, left2_y),
        (tip_x, tip_y),
        (right2_x, right2_y),
        (right_x, right_y),
    ]
    draw.polygon(points, fill=color)


def main():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=CORNER_RADIUS, fill=BG_COLOR)

    # === Heatmap Grid (bottom half) ===
    grid_cols = 7
    grid_rows = 4
    gap = 14
    cell_size = 80
    total_w = grid_cols * cell_size + (grid_cols - 1) * gap
    total_h = grid_rows * cell_size + (grid_rows - 1) * gap
    grid_x = (SIZE - total_w) // 2
    grid_y = SIZE - total_h - 130  # Bottom area

    data = generate_heatmap_data(grid_rows, grid_cols)

    # Glow layer
    glow_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)

    for row in range(grid_rows):
        for col in range(grid_cols):
            x = grid_x + col * (cell_size + gap)
            y = grid_y + row * (cell_size + gap)
            level = data[row][col]
            color = TEAL_SHADES[level]
            draw.rounded_rectangle((x, y, x + cell_size, y + cell_size), radius=14, fill=color)

            # Glow for bright cells
            if level >= 3:
                glow_size = 6
                glow_color = (*TEAL_SHADES[level], 35)
                glow_draw.rounded_rectangle(
                    (x - glow_size, y - glow_size, x + cell_size + glow_size, y + cell_size + glow_size),
                    radius=18, fill=glow_color
                )

    # === Sprout (upper-center, growing from grid) ===
    stem_x = SIZE // 2
    stem_bottom = grid_y - 10
    stem_top = 200
    stem_width = 14

    # Stem (slightly curved)
    for y in range(int(stem_top), int(stem_bottom)):
        # Gentle S-curve
        t = (y - stem_top) / (stem_bottom - stem_top)
        offset_x = math.sin(t * math.pi * 0.3) * 15
        x = stem_x + offset_x
        w = stem_width * (0.6 + 0.4 * t)  # Thicker at bottom
        alpha = int(255 * (0.7 + 0.3 * (1 - t)))  # Slightly fade at top
        draw.ellipse((x - w/2, y - 1, x + w/2, y + 1), fill=(*STEM_COLOR, alpha))

    # Left leaf
    leaf_base_y = stem_top + 100
    leaf_base_x = stem_x + math.sin(0.3 * math.pi * 0.3) * 15 - 5
    draw_leaf(draw, leaf_base_x, leaf_base_y, 140, 160, 65, LEAF_COLOR_L)
    # Leaf vein
    vein_angle = math.radians(140)
    for i in range(5, 130, 2):
        vx = leaf_base_x + math.cos(vein_angle) * i
        vy = leaf_base_y - math.sin(vein_angle) * i
        alpha = int(255 * (1 - i / 160) * 0.3)
        draw.ellipse((vx - 1, vy - 1, vx + 1, vy + 1), fill=(*LEAF_HIGHLIGHT, alpha))

    # Right leaf
    draw_leaf(draw, leaf_base_x + 10, leaf_base_y - 60, 40, 140, 55, LEAF_COLOR_R)
    # Leaf vein
    vein_angle = math.radians(40)
    for i in range(5, 110, 2):
        vx = leaf_base_x + 10 + math.cos(vein_angle) * i
        vy = leaf_base_y - 60 - math.sin(vein_angle) * i
        alpha = int(255 * (1 - i / 140) * 0.3)
        draw.ellipse((vx - 1, vy - 1, vx + 1, vy + 1), fill=(*LEAF_HIGHLIGHT, alpha))

    # Small budding leaf at top
    top_x = stem_x + math.sin(0.1 * math.pi * 0.3) * 15
    draw_leaf(draw, top_x, stem_top + 20, 80, 70, 30, (0, 229, 255))

    # === Composite ===
    result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    result = Image.alpha_composite(result, glow_img)
    result = Image.alpha_composite(result, img)

    # Save
    output_path = "HabitFlow/Resources/AppIcon.png"
    result.save(output_path, "PNG")
    print(f"Icon saved to {output_path} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
