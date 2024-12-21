extern "C" void main() {
    volatile char* vga = (char*)0xb8000; // VGA buferis misamarti https://en.m.wikipedia.org/wiki/VGA_text_mode
    vga[0] = 'Z'; // Aso
    vga[1] = 0x07; // Misi atributi: tetri teksti shav fonze
    vga[2] = 'E'; // Aso
    vga[3] = 0x07; // Misi atributi: tetri teksti shav fonze
    vga[4] = 'R'; // Aso
    vga[5] = 0x07; // Misi atributi: tetri teksti shav fonze
    vga[6] = 'O'; // Aso
    vga[7] = 0x07; // Misi atributi: tetri teksti shav fonze
    return;
}
