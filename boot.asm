[org 0x7c00]
[bits 16]

mov [MAIN_DISK], dl ; Guardamos el disco primario

mov bp, 0x1000
mov sp, bp ; Colocamos un stack en 0x1000

mov bx, PROMPT
call print_string

mov dl, [MAIN_DISK]
mov ah, 0x02 ; lectura
mov al, 0x01 ; # de sectores
mov ch, 0x00 ; Cilindro = 0
mov dh, 0x00 ; Cabezal = 0
mov cl, 0x02 ; Sector = 2
mov bx, 0x8000 ; Y lo guardamos en 0x8000
int 0x13 ; llamada a la BIOS

mov ax, handler_kbd
call install_keyboard


call second_stage

install_keyboard:
    push word 0
    pop ds
    cli
    mov [4 * KEYBOARD_INTER], word keyboardDriver
    mov  [4 * KEYBOARD_INTER + 2], cs
    mov word [HANDLER], ax
    sti
    ret




handler_kbd:
    mov al, [bx]
    cmp al, 'h'
    je .hola
    cmp al, 'a' 
    je .adios
    cmp al, 'r'
    je .read
    mov bx, INVALID
    call print_string
.hola:
    mov bx, HOLA
    call print_string
    ret
.adios: 
    mov bx, ADIOS
    call print_string
    ret
.read:
    mov dl, [MAIN_DISK]
    mov ah, 0x02 ; lectura
    mov al, 0x01 ; # de sectores
    mov ch, 0x00 ; Cilindro = 0
    mov dh, 0x00 ; Cabezal = 0
    mov cl, 0x03 ; Sector = 3
    mov bx, 0x9000 ; Y lo guardamos en 0x9000
    int 0x13 ; llamada a la BIOS
    call  print_string
    ret






keyboardDriver:
    pusha
    in al, 0x60
    test al, 0x80
    jnz .end ; no leimos nada
    mov bl, al
    xor bh, bh
    mov al, [cs:bx + keymap]
    cmp al, 13
    je .enter
    mov bl, [WORD_SIZE]
    mov [WRD+bx], al
    inc bx
    mov [WORD_SIZE], bl
    mov ah,  0x0e
    int  0x10
.end:
    mov  al, 0x61
    out 0x20, al
    popa 
    iret
.enter:
    mov bx, WRD
    mov cl, [WORD_SIZE]
    mov dx, [HANDLER]
    call dx
    mov byte [WORD_SIZE], 0
    jmp .end


print_string:
    pusha
    xor si, si ; si = 0
.loop:
    mov al, byte [bx+si]
    inc si
    cmp al, 0
    je .end
    call  print_char
    jmp .loop
.end:
    popa
    ret

print_char:
    push ax
    mov ah, 0x0e
    int 0x10
    pop ax
    ret


HANDLER: dw 0
WRD: times 64 db 0
WORD_SIZE: db 0
MAIN_DISK: db 0
INVALID: db "COMANDO INVALIDO", 0x0A, 0x0
PROMPT: db "Hola desde mi primer OS",  0x0A, 0x0
HOLA:  db "Bienvenido a NOMBREENPROCESP", 0x0A, 0x0
ADIOS: db "Adios, vuelva pronto", 0x0A, 0x0
KEYBOARD_INTER EQU 9





keymap:
    %include "keymap.inc"


times 510-($-$$) db 0
dw 0xaa55

second_stage:
    jmp $ ; Aqui va el código de la segunda etapa
times 1024-($-$$) db 0



db "En un lugar de la mancha de cuyo nombre no quiero acordarme", 0x0

times 2048-($-$$) db 0