[org 0x7c00]                         ; Vakenebt sawkiss 0x7C00 ze, ak tvirtavs BIOS-i bootloaders
KERNEL_LOCATION equ 0x1000           ; Vakenebt konstants sadac aris kernelis chatvirtvis lokacia

mov [BOOT_DISK], dl                  ; Vinakhavt chatvirtvis diskis nomeri romelic motsodebulia BIOS-is mier DL-shi cvlad BOOT_DISK shi

; Segmentebis, registrebis da stekis konfigi
xor ax, ax                           ; Asuftavebs/Aqlearebs AX registrs
mov es, ax                           ; Ayenebs ES damatebit segments 0ze
mov ds, ax                           ; Ayenebs DS monacemta segments 0ze
mov bp, 0x8000                       ; Ayenebs BP dziritad pointers 0x8000ze
mov sp, bp                           ; Ayenebs SP stekis pointers BP dziritad pointeris mnishnvelobaze

; Diskidan kernelis chasatvirtad parametrebis konfigi
mov bx, KERNEL_LOCATION              ; Itvirteba kernelis chatvirtvis misamarti BXshi
mov dh, 2                            ; Sektorebis raodenoba romelic unda chaitvirtos

mov ah, 0x02                         ; BIOS INT 13h: funqcia 2 - diskidan sektorebis wakitxva.
mov al, dh                           ; AL shi itvirteba chasatvirti sektorebis raodenoba
mov ch, 0x00                         ; Tsilindris nomeri, CHS misamartis maghali baiti
mov dh, 0x00                         ; Tavakis nomeri, CHS misamartis sashualo baiti
mov cl, 0x02                         ; Sawkisi sekciis nomeri, CHS misamartis dabali baiti
mov dl, [BOOT_DISK]                  ; Itvirteba chatvirtvis diskis nomeri DLshi
int 0x13                             ; BIOS-is interfeisis gamodzakheba kernelis chasatvirtad

; Switch to text mode.
mov ah, 0x0                          ; BIOS INT 10h: fuqncia 0 - video rejimis dakeneba.
mov al, 0x3                          ; Ayenebs 80x25 teqstur rejimshi.
int 0x10                             ; BIOS-is interfeisis gamodzakheba video rejimis shesatsvlelad

; Prepare for protected mode.
CODE_SEG equ GDT_code - GDT_start    ; Kodis segmentis ofseti globaluri aghtserilebis cxrilshi GDT-shi.
DATA_SEG equ GDT_data - GDT_start    ; Monacemta segmentis ofseti GDT-shi.

cli                                  ; Tskvetebis gatishva.
lgdt [GDT_descriptor]                ; Globaluri aghtseriloba cxrilis GDT chatvirtva
mov eax, cr0                         ; Itvirteba CR0 registris mnishvneloba
or eax, 1                            ; CR0 shi itsvleba Protected Mode Enable PE biti
mov cr0, eax                         ; Chatsera CR0 shi proteqtuli rejimis gasaaktiureblad
jmp CODE_SEG:start_protected_mode    ; Shoreuli gadakhtoma proteqtul rejimshi gadasasvlelad da paiplainis gasasuftaveblad

jmp $                                ; Usasrulo tsikli, shemdgomi kodis pleisholderi

BOOT_DISK: db 0                      ; Tsvladi romelic inakhavs chatvirtvis diskis nomers

; Globarluri aghtserilebis ckhrili GDTs gansazghvra
GDT_start:
    GDT_null:                        ; NULL aghweriloba, sachiro CPUstvis
        dd 0x0                       ; NULL segmentis bazis da zomis
        dd 0x0

    GDT_code:                        ; Kodis segmentis aghweriloba
        dw 0xffff                    ; Segmentis zoma, dabali 16 biti
        dw 0x0                       ; Segmentis baza, dabali 16 biti
        db 0x0                       ; Segmentis baza, shemdegi 8 biti
        db 0b10011010                ; Dashvebis baiti: mexsierebashi, rgoli 0, shesrulebadi, wakitxvadi
        db 0b11001111                ; Flagebi: granularoba da segmentis zoma, maghali 4 biti
        db 0x0                       ; Segmentis baza, maghali 8 biti

    GDT_data:                        ; Monatsemta segmentis aghweriloba
        dw 0xffff                    ; Segmentis zoma, dabali 16 biti
        dw 0x0                       ; Segmentis baza, dabali 16 biti
        db 0x0                       ; Segmentis baza, shemdegi 8 biti
        db 0b10010010                ; Dashvebis baiti: mexsierebashi, rgoli 0, chaweradi
        db 0b11001111                ; Flagebi: granularoba da segmentis zoma, maghali 4 biti
        db 0x0                       ; Segmentis baza, maghali 8 biti

GDT_end:

; GDT aghweriloba LGDT instrukciistvis
GDT_descriptor:
    dw GDT_end - GDT_start - 1       ; GDT-is zoma, limiti
    dd GDT_start                     ; GDT-is misamarti.

[bits 32]                            ; 32-bitiani proteqtuli rejimis kodi.
start_protected_mode:
    mov ax, DATA_SEG                 ; Itvirteba monatsemta segmentis seleqtori AXshi
    mov ds, ax                       ; Akenebs DS monatsemta segments axal segmentze
    mov ss, ax                       ; Akenebs SS stekis segments axal segmentze
    mov es, ax                       ; Akenebs ES damatebit segments axal segmentze
    mov fs, ax                       ; Akenebs FS zogadi danishnulebis segments axal segmentze
    mov gs, ax                       ; Akenebs GS zogadi danishnulebis segments axal segmentze

    mov ebp, 0x90000                 ; Akenebs stekis bazis pointers 32-bitian rejimshi
    mov esp, ebp                     ; Akenebs stekis pointers 32-bitian rejimshi

    jmp KERNEL_LOCATION              ; Gadakhtoma kernelis sawkis misamartze

; Boot sector padding and signature.
times 510-($-$$) db 0                ; Shevseba nulebit, rata butseqtori iyos 512 baiti
dw 0xaa55                            ; Butis khelmotsera, BIOSistvis autsilebelia