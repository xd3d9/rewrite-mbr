typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
volatile uint8_t* video_memory;
inline int abs(int x) {
    return (x < 0) ? -x : x;
}

enum Ferebi {
    Shavi,
    Lurji,
    Mwvane,
    Cisferi,
    Witeli,
    Iasamnisferi,
    Yavisferi,
    Nacrisferi,
    MuqiNacrisferi,
    GhiaLurji,
    GhiaMwvane,
    GhiaCisferi,
    GhiaWiteli,
    GhiaIasamnisferi,
    Yviteli,
    Tetri
};
/*
* text modestvis iko
void print_c(int colour, const char* string)
{
    while (*string != 0)
    {
        *vga++ = *string++;
        *vga++ = colour;
    }
}
*/

void set_pixel(int x, int y, uint8_t color) {
    uint16_t offset = y * 320 + x;
    video_memory[offset] = color;
}

void draw_line(int x1, int y1, int x2, int y2, uint8_t color) {
    int dx = abs(x2 - x1);
    int dy = abs(y2 - y1);
    int sx = x1 < x2 ? 1 : -1;
    int sy = y1 < y2 ? 1 : -1;
    int err = dx - dy;

    while (true) {
        set_pixel(x1, y1, color);
        if (x1 == x2 && y1 == y2) break;
        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x1 += sx;
        }
        if (e2 < dx) {
            err += dx;
            y1 += sy;
        }
    }
}


extern "C" void main() {
    video_memory = (uint8_t*)0xA0000;
    draw_line(180, 90, 90, 180, Tetri);
    return;
}