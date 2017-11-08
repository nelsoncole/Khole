; "stage1.asm"
;
; "Projecto KholeOS. Bootloader" 
; Nelson Sapalo da Silva Cole (nelsoncole72@gmail.com  +244-948-833-132)
; Lubango 16 de Julho de 2017
;
;
;
;
;
;
;
; Vamos inicializar com o FAT16



bits 16			; diz ao nosso nasm que usaremos endereçamento de 16 -bits
org 0x7c00		; nosso offset



; Vamos inicializar com o FAt12 ou FAT16


    db 0xEB,0x3C,0x90  
	BS_OEMName DB "KHOLE0.3"	;10-3	char [8] 
	BPB_BytsPerSec DW 512		;12-11
	BPB_SecPerClus DB 8 		;13
	BPB_RsvdSecCnt DW 4		;15-14
	BPB_NumFATs DB 2		;16
	BPB_RootEntCnt DW 0x200		;18-17 Em FAT32 valor e sempre 0
	BPB_TotSec16 DW 0		;20-19   se o valor for zero significa que temos mais de 65535
	BPB_Media DB 0xf8			;21
	BPB_FATSz16 DW 0		;23-22
	BPB_SecPertrk DW 0x3f	;25-24
	BPB_NumHeads DW 0		;27-26
	BPB_HiddSec DD 0		;31-28
	BPB_TotSec32 DD 0		;35-32	
	BS_DrvNum DB 0x80			;36
	BS_Reserved1 DB 0		;37
	BS_BootSig DB 0x29			;38
	BS_VolID DD 0x20bccd50			;42-39
	BS_VolLab DB "Nelson Cole"	;53-43, sao char[11]
	BS_FilSysType DB "FAT12/16"	;61-54, sao char[8]


code:
	cli		; desabilita interrupções
    push cs
    pop ds
	;mov es,ax
	;mov ss,ax
	;mov sp,0x1000	; 4KB, pilha
	sti		; habilita interrupções



; Salvar o Device Drive do BIOS

    mov BYTE [BS_DrvNum],dl



; Definir modo de video, modo texto
    mov ax,3
    int 0x10


; Verifica presença de extensão BIOS EDDs
    
    mov bx,0x55AA
	mov dl,BYTE [BS_DrvNum]
	mov ah,0x41
	int 0x13
	jc ERRO1
	cmp bx,0xAA55
	jne ERRO1



; Calculando o Root_Dir_Sectors


    xor dx,dx
    mov ax,32
    mul WORD [BPB_RootEntCnt]
    mov bx, WORD [BPB_BytsPerSec]
    sub bx,1
    add ax,bx
    xor dx,dx
    div WORD [BPB_BytsPerSec]
    mov WORD [Root_Dir_Sectors],ax   


; Calculando o 1º sector de dados, First_Data_Sector

    xor bx,bx
    xor dx,dx
	mov ax,WORD [BPB_FATSz16]
	mov bl,BYTE [BPB_NumFATs]
	mul bx
	add ax,WORD [BPB_RsvdSecCnt]
    add ax,WORD [Root_Dir_Sectors]
	mov WORD [First_Data_Sector],ax
	

; Calculando o 1º sector do Root Directory, First_Root_Directory_Sector
    

    mov ax,WORD [First_Data_Sector]
    sub ax,WORD [Root_Dir_Sectors]
    mov WORD [First_Root_Directory_Sector],ax
    

; Carregando o Root Directory na memorio


    xor eax,eax

	mov cx,WORD [Root_Dir_Sectors]
    mov ax,WORD [First_Root_Directory_Sector]
	xor di,di
	mov bx,0x7E00
	call read_sectors

    
	
; Aqui vamos nalizar todas as entradas no Root Dir ate achar o arquivo de nome 8.3 "stage2.bin"
	

    mov cx,512
    lea bx,[0x7E00]
.goto_1:
    pusha 

	cmp BYTE [bx],0	;Se for 0 entrada nao usada
	je .goto_3
	cmp BYTE [bx+11],0x20	; Se for 0x20 arquivo de nome 8.3
	jne .goto_3

	mov cx,11
	lea di,[bx]
	mov si,Name_stage2
	rep cmpsb
	jne .goto_3
    lea si,[bx]
    call puts
	jmp .arquivo_encontrado
	


.goto_3:
    popa

	dec cx	
	jcxz .arquivo_nao_encontrado
	add bx,32
	jmp .goto_1


.arquivo_nao_encontrado:
    popa	
	mov si,msg2
	call puts
	xor ax,ax
	int 0x16
	int 0x19
	

.arquivo_encontrado:
    popa


    xor ax,ax
    int 0x16
  
; Lendo o stage2.bin

    xor cx,cx
    xor esi,esi

	mov ax, WORD [bx + 26]
	sub ax,2

	mov cl,BYTE[BPB_SecPerClus]
	mul cx

    add ax,WORD [First_Data_Sector] 
	xchg si,ax  ; pega o First_Sector_Of_Cluster e põe em si

   

	xor ax,ax
	xor cx,cx
	

	xor edx,edx
    movzx ecx,WORD [BPB_BytsPerSec]
	mov eax,DWORD[bx + 28]
	div ecx
    cmp edx,0
    je .pula
    add eax,1 ; Isto para evitar não ler todo arquivo

.pula:
	
	xchg cx,ax
	mov eax,esi
	mov bx,0x8000
	xor di,di
	call read_sectors



; Executa o stage2.bin


    mov ax,3
    int 0x10

	xor dx,dx
	mov dl,BYTE[BS_DrvNum]
	push dx			; empura dl na pilha
	jmp 0x0000:0x8000


ERRO:
; desempilha todos registradores de uso geral
	popa
    mov si,msg1
    jmp ERRO_START
ERRO1:
    mov si,msg0
ERRO_START:
    call puts
	xor ax,ax
	int 0x16
	int 0x19	; reboot






; Função imprime string na tela

puts:
	pusha		; empilha todos os registradores de uso geral
.next:
	cld 		; flag de direcção
	lodsb		; a cada loop carrega si p --> al, actualizando si
	cmp al,0	; compara al com o 0
	je  .end	; se al for 0 pula para o final do programa	
	mov ah,0x0e	; função TTY da BIOS imprime caracter na tela
	int 0x10	; interrupção de vídeo
	jmp .next	; próximo caracter
.end:
	popa	; desempilha todos os registradores de uso geral
	ret	; retorna




; Função read sectores

read_sectors:
	; cx --> count
	; di --> Segmento
	; bx --> Offset
	; eax --> Starting sector LBA47
	


.loop:
	pusha
	mov [si+0], BYTE 0x10	; Tamanho da DAP
	mov [si+1], BYTE 0	; reservado
	mov [si+2], WORD 1	; Sector count
	mov [si+4], bx		; Offset
	mov [si+6], di		; Segment
	mov [si+8], eax		; Start sector LBA47
	mov [si+12], DWORD 0	; Starting sector LBA47
	mov dl,BYTE [BS_DrvNum]
	mov ah,0x42
	int 0x13
	jc ERRO	
	popa
	
	dec cx
	jcxz .end	
	add bx,0x200
	cmp bx,0xFFFF		; 64KB
	jne .goto_1
	add di,0x1000		; 4 KB
	xor bx,bx
.goto_1:
	inc eax
	jmp .loop
.end:
	
	ret



; Algumas variaveis


Root_Dir_Sectors dw 0
First_Data_Sector dw 0
First_Root_Directory_Sector dw 0

Name_stage2 db "STAGE2  BIN"  
msg0 db "[ Erro No BIOS EDDs ]",0
msg1 db "[ Erro ao ler sector ]",0
msg2 db "[ No boot ]",0



times 510 - ($-$$) nop	; esta rotina fará com que o código tenha 512 Bytes - os 2
					; últimos Bytes da assinatura 
dw 0xaa55	; Assinatura de boot
