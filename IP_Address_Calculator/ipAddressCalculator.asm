include "emu8086.inc"

NAM MACRO array, p1, p2, p3, p4 ,p5
    
    mov loopCon, 0
    mov si, 0
    mov al, array[si]
    sub al, 30h
    mov bl, 2
	
    p1:
    mov ah, 0
    mul bl
    inc si
    cmp array[si], '.'
    je p2
    add al, array[si]
    sub al, 30h
    mov dl, al
    
    add loopCon, 1
    cmp loopCon, 31
    jne p1
    jmp p5
	
    p2:
    mov ah, 0
    mov al, dl
    call print_num
    cmp loopCon, 1Ah
    jle p4
	
    p3:
    inc si
    mov al, array[si]
    mov ah, 0
    add loopCon, 1
    jmp p1
	
    p4:
    putc '.'
    jmp p3
	
    p5:
    mov al, dl
    mov ah, 0
    call print_num
	
ENDM

.model small
.stack 100h

.data

ipbinary db 35 dup('0')
netbin db 35 dup('0')
brdbin db 35 dup('1')
subnet db 35 dup('0')
wildmask db 35 dup('1')
mask db 2 dup(?)
ip db 4 dup(?)

loopCon db 0
dot dw 8
c dw 0
e dw 0
f dw 0
g db 10
prefix db 0

.code
main proc
    mov ax, @data
    mov ds, ax

    define_scan_num
    define_print_string

    define_print_num
    define_print_num_uns
    define_clear_screen

;================== Welcome page ======================
    GOTOXY 34, 10
    print "Hello "
    putc 1h
    GOTOXY 23, 13
    printn "Welcome to our IP calculator"
    mov cx, 10
    space:
    printn ""
    loop space
    
    call clear_screen
    mov cx, 0

    GOTOXY 0, 1
    
;================= Taking octet number =====================
    start:
    print "Enter octet: "
    call    scan_num
    printn ""
    
    mov ip[si], cl  ;shifting numbers from cl to array
    inc si
    inc e           ;e is counting the loop iterations/ip array cell
    cmp e, 4
    jne start       ;loop breaks when e is 4
    
;============= Takes prefix mask and calculation ===================    
    printn ""
    print "Prefix: "
    
    mov cx, 2                ;taking prefix in array
    mov si, 0
    prefixing:
    mov ah, 1
    int 21h
    cmp al, 13              ;checks if enter pressed
    je calc
    mov mask[si],al
    inc si
    loop prefixing

    calc:
    cmp si, 1                ;checks if only 1element in array
    je line1
	
    ;if 2 element, then this executes
    mov dx, 0
    mov cx, si
    mov si,0
    multiple:
    mov al, mask[si]
    sub al, 30h             ;converting to decimal
    mov bl, g
    mul bl
    add dx, ax              ;saving the sum of prefix
    mov g,1
    inc si
    loop multiple
    
    mov prefix, dl          ;storing result in prefix
    mov dx, 0
    mov ax, 0
    
    jmp print
    
    line1:                 ;when only one element
    mov si, 0
    mov al, mask[si]
    mov prefix, al
    sub prefix, 30h
    
;==================== IP printing ===========================
    print:
    mov e, 0
    printn ""
    printn ""
    print "IP Address: "     ;prints new line
    mov cx, 3                 ;to avoid last dot, running 3 times
    mov si, 0
    
    move:
    mov al, ip[si]
    mov ah, 0
    call print_num
    mov dl, '.'               ;printing manual dot
    mov ah, 2
    int 21h
    inc si
    loop move
    mov al, ip[si]
    mov ah, 0
    call print_num
	
;================== Binary calculation of IP ===========================
    mov c, 7                      ;pointing the 7th cell of array
    mov si, 0
    mov f, 4                      ;iteration counter
    
    moving:
    mov ah, 0
    mov al, ip[si]                ;saves the first element e.g -192
    mov e, si
    mov bh, 0
    
    MOV bl, 2                     ;dividing by 2
    mov si, c
    
    calcbinary:
    div bl                        ;ah stores the vagshesh
    add ah, '0'                    ;zero saves in the array, not the ascii
    mov ipbinary[si], ah           ;storing from last position
    mov ah, 00                     ;deletes previous data to avoid collision
    dec si
    cmp al, 00                     ;vagfol zero hoile ber hoye jabe
    jne calcbinary
	
    mov si, dot
    mov ipbinary[si], '.'          ;manual dot
    mov netbin[si], '.'
    mov brdbin[si], '.'
    ;mov frsthst[si], '.'
    ;mov lsthst[si], '.'
    mov subnet[si], '.'
    mov wildmask[si], '.'
    
    add e, 1                      ;counting the position of ip array
    mov si, e
    
    add c, 9                      ;f0 array position counter, starts inserting bin from that position
    add dot, 9                    ;determines the position of dot
        
    sub f, 1
    cmp f, 0                       ;checks for 4 octets, last octet a loop break
    
    jne loop moving

;=================== Network address calculation =========================
    ;checks for the dot, if found add total dot no
    cmp prefix, 8
    jle netpart1
    cmp prefix, 16
    jle part1
    jmp check1
    
    part1:
    add prefix, 1
    jmp netpart1
     
    check1:
    cmp prefix, 24
    jle part2
    jmp check2
    part2:
    add prefix, 2
    jmp netpart1
    
    check2:
    add prefix, 3
    
    netpart1:
    mov si, 0
    add cl, prefix
    mov ch, 0
    networking:
    mov bl, ipbinary[si]
    mov netbin[si], bl
    inc si
    loop networking
    
    ;printing netwrk address  
    printn ""
    printn ""
    print "Network Address: "
    NAM netbin, n1 ,n2, n3, n4, n5
    
;=================== Broadcast address calculation =========================
    brdcast:
    mov cl, prefix
    mov ch, 0
    mov si, 0
    brdcalc:
    mov al, netbin[si]
    mov brdbin[si], al
    inc si
    loop brdcalc
    
    ;printing broadcast addrss
    printn ""
    printn ""
    print "Broadcast Address: "
    NAM brdbin , b1, b2, b3, b4, b5
   
;=================== Subnet Mask calculation =========================
    mov cl, prefix
    mov ch, 0
    mov si, 0
    mov subnet[si], 31h
    sub cl, 1
    mov si, 1
    subcalc:
    cmp subnet[si], 46
    je temp
    mov subnet[si], 31h
    temp:
    inc si
    loop subcalc
    
    ;printing subnet mask addrss
    printn ""
    printn ""
    print "Subnet Mask Address: "
    NAM subnet, s1, s2, s3, s4, s5
        
;=================== First host address calculation =========================
    mov si, 34
    add netbin[si], 1
    
    ;printing first host addrss
    printn ""
    printn ""
    print "First Host Address: "
    NAM netbin, f1, f2, f3, f4, f5

;=================== Last host address calculation =========================
    mov si, 34
    mov brdbin[si], 30h
    
    ;printing last host addrss
    printn ""
    printn ""
    print "Last Host Address: "
    NAM brdbin, l1, l2, l3, l4, l5

;=================== Wild mask calculation =========================
    mov cl, prefix
    mov ch, 0
    mov si, 0
    mov wildmask[si], 30h
    sub cl, 1
    mov si, 1
    
    wildcalc:
    cmp wildmask[si], 46
    je temp1
    mov wildmask[si], 30h
    temp1:
    inc si
    loop wildcalc
    
    ;printing wild mask addrss
    printn ""
    printn ""
    print "Wild Mask Address: "
    NAM wildmask, w1, w2, w3, w4, w5
	
;===================================================================    
    printn ""
    printn ""
    print "Press any key.."
    mov ah, 0
    int 16h

;==================== Credit ========================= 
    call clear_screen
    
    GOTOXY 36, 2
    printn "Credits"
    GOTOXY 34, 3
    print "-----------"
    
    GOTOXY 6, 6
    printn "Mahfuzur Rahman"
    GOTOXY 7, 8
    printn "ID: ****1135"
    GOTOXY 2, 10
    printn "Email: emailaddress@domain.suffix"
    
    GOTOXY 47, 6
    printn "Abdullah Umar Nasib"
    GOTOXY 50, 8
    printn "ID: ****1115"
    GOTOXY 43, 10
    printn "Email: emailaddress@domain.suffix"
    
    GOTOXY 30, 14
    printn "Ajmain Inqiad Alam"
    GOTOXY 33, 16
    printn "ID: ****1054"
    GOTOXY 23, 18
    printn "Email: emailaddress@domain.suffix"
    
    GOTOXY 27, 23
    print "Press any key to exit.."
    mov ah, 0
    int 16h
    mov ah, 4ch
    int 21h 

end main
