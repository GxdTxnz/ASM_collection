section .bss	; open_text_file cipher_text_file key_file -e - шифрование
		; cipher_text_file open_text_file key_file -d - дешифрование
	fd1 resb 4; open_text
	fd2 resb 4; cipher_text
	fd3 resb 4; key
	key resb 32
	reverse_key resb 4
	left_buf resb 4
	right_buf resb 4
	str1 resb 2
section .data
	pi0 db 'c462a5b9e8d703f1' ; pi-подстановки
	len0 equ $ - pi0
	pi1 db '68239a5c1e47bd0f'
	len1 equ $ - pi1
	pi2 db 'b3582fade174c960'
	len2 equ $ - pi2
	pi3 db 'c821d4f670a53e9b'
	len3 equ $ - pi3
	pi4 db '7f5a816d093eb42c'
	len4 equ $ - pi4
	pi5 db '5df692cab78143e0'
	len5 equ $ - pi5
	pi6 db '8e25691cf4b0da37'
	len6 equ $ - pi6
	pi7 db '17ed05834fa69cb2'
	len7 equ $ - pi7
	encr db '-e', 0
	lenencr equ $ - encr
	decr db '-d', 0
	lendecr equ $ - decr
	done db 'Done. Check your second file.',  0xa, 0xd
	lendone equ $ - done
	strerror db 'Error! Please, use parameters "-d" for decrypting or "-e" for encrypting.', 0xa, 0xd
	lenerror equ $ - strerror
	str_out db 'Please, enter encrypting or decrypting parameter: ', 0
	len_out equ $ - str_out
	keyerror db 'From key_file read less than 32 bytes.', 0xa, 0xd
	key_len equ $ - keyerror
section .text
	global _start
_start:
	pop ebx; argc
	pop ebx; argv[0]
	pop ebx; argv[1]
	mov eax, 5
	mov ecx, 0; O_RDWR
	mov edx, 0
	int 0x80

	mov [fd1], eax

	pop ebx; argv[2]
	mov eax, 8;	 - создаем файл для удаления предыдущих результатов
	mov ecx, 420
	int 0x80

	mov [fd2], eax

	mov eax, 5;	 - открываем файл на чтение, где будет записан результат работы программы
	mov ecx, 1; O_WRONLY
	mov edx, 0
	int 0x80

	mov [fd2], eax

	pop ebx			; argv[3]
	mov eax, 5
	mov ecx, 0; O_RDONLY
	mov edx, 0
	int 0x80

	mov [fd3], eax
	
	mov eax, 3
	mov ebx, [fd3]; Считываем ключ из файла
	mov ecx, key
	mov edx, 32
	int 0x80

	cmp eax, 32; Если из ключ-файла считалось менее 32 байт, то выходим из программы с соответствующим выводом
	jl Nope
	jmp Norm
Nope:
	mov eax, 4
	mov ebx, 1
	mov ecx, keyerror
	mov edx, key_len
	int 0x80
	
	jmp Err2
Norm:
	mov eax, 6
	mov ebx, [fd3] ; Закрываем файл с ключом
	int 0x80

	mov eax, 4
	mov ebx, 1
	mov ecx, str_out
	mov edx, len_out
	int 0x80

	mov eax, 3	
	mov ebx, 1
	mov ecx, str1	; Ввод параметра шифрования/дешифрования
	mov edx, 2
	int 0x80
read:
	mov eax, 3	; Считываем левый блок открытого текста
	mov ebx, [fd1]
	mov ecx, left_buf
	mov edx, 4
	int 0x80

	cmp eax, 0	; Если в левом блоке 0 байт, то это значит, что мы находимся в конце файла, а значит, выходим из программы
	je exit

	cmp eax, 4	; Если в блоке ровно 4 байта, то переходим к считыванию следующего блока, иначе добиваем его тем байтом, равным недостающим
	je shit1
	mov esi, eax
	mov ebx, 4
	sub ebx, eax
	mov eax, ebx
	call Fix1	; Вызов функции добивания байт в левом блоке
	xor esi, esi	; Обнуляем индекс строки, т.к. в правом блоке ничего нет, значит, заполняем его полностью
	call Fix2	; Вызов функции добивания байт в правом блоке
	jmp shit
shit1:
	mov eax, 3
	mov ebx, [fd1]
	mov ecx, right_buf
	mov edx, 4
	int 0x80

	cmp eax, 4
	je shit
	mov esi, eax
	mov ebx, 4
	sub ebx, eax
	mov eax, ebx
	call Fix2
shit:
	mov esi, str1	; Сравниваем строки для определения параметра
	mov edi, encr
	mov ecx, lenencr
	cld
	repe cmpsb
	jecxz enc

	mov esi, str1
	mov edi, decr
	mov ecx, lenencr
	cld
	repe cmpsb
	jecxz dec
	
	mov eax, 4	; Если введен иной параметр, то выходим из программы
	mov ebx, 1
	mov ecx, strerror
	mov edx, lenerror
	int 0x80

	jmp End
dec:
	mov edi, 0
	mov ecx, 31	; Обратный порядок развертывания ключей
	jmp G
enc:
	mov edi, 0
	mov ecx, 0
G:
	push edi
	mov esi, ecx
	call Switch_key ; Развертка
	mov eax, esi
	mov ebx, 4
	mul ebx
	mov esi, eax
	xor eax, eax
	xor ebx, ebx
	mov eax, dword[key+esi]
	mov dword[reverse_key], eax
	push ecx
	mov eax, dword[right_buf]
	push eax
	g:
		mov ecx, 2
		mov esi, 0	; Цыганские фокусы с перестановкой байт в строках для сложения в кольце 2^32
		mov edi, 3
		add_ing:
			mov al, byte[right_buf+esi]
			mov dl, byte[right_buf+edi]
			mov bl, byte[reverse_key+esi]
			mov byte[right_buf+esi], dl
			mov byte[right_buf+edi], al
			xor edx, edx
			mov dl, byte[reverse_key+edi]
			mov byte[reverse_key+esi], dl
			mov byte[reverse_key+edi], bl
			inc esi
			dec edi
			xor edx, edx
			xor ebx, ebx
			xor eax, eax
			loop add_ing
		mov eax, dword[right_buf]
		mov edx, dword[reverse_key]
		add eax, edx	; Сложение в кольце
		mov dword[right_buf], eax
		xor eax, eax
		xor edx, edx
		mov ecx, 2
		mov esi, 0
		mov edi, 3
		call Add_ing	; Выполняем обратные цыганские фокусы
		mov esi, 0
		mov ecx, 0
		t:		; t-преобразование
			mov al, byte[right_buf+esi]
			and al, 0xf0
			ror al, 4
			jmp obama
		aboba:
			mov dl, al
			rol dl, 4
			mov al, byte[right_buf+esi]
			and al, 0x0f
		obama:
			cmp cl, 0
			je p7
			cmp cl, 1
			je p6
			cmp cl, 2
			je p5
			cmp cl, 3
			je p4
			cmp cl, 4
			je p3
			cmp cl, 5
			je p2
			cmp cl, 6
			je p1
			cmp cl, 7
			je p0
			jmp ex_t
			p7:
				mov ebx, pi7
				jmp kh
			p6:
				mov ebx, pi6
				jmp kh
			p5:
				mov ebx, pi5
				jmp kh
			p4:
				mov ebx, pi4
				jmp kh
			p3:
				mov ebx, pi3
				jmp kh
			p2:
				mov ebx, pi2
				jmp kh
			p1:
				mov ebx, pi1
				jmp kh
			p0:
				mov ebx, pi0
				jmp kh
			kh:
				xlatb
			inc ecx
			cmp al, 96
			jl less
			jmp more
			less:
				sub al, 0x30
				jmp nm
			more:
				sub al, 0x57
			nm:
			test ecx, 1
			jnz aboba
			or al, dl
			mov byte[right_buf+esi], al
			inc esi
			jmp t
		ex_t:
		mov ecx, 2
		mov esi, 0
		mov edi, 3
		call Add_ing	; Снова цыганские фокусы для грамотного роллинга
		mov eax, dword[right_buf]
		rol eax, 11	; Циклический сдвиг влево на 11 бит
		mov dword[right_buf], eax
		xor eax, eax
		mov ecx, 2
		mov esi, 0
		mov edi, 3
		call Add_ing	; Опять 25!!!!
	mov eax, dword[right_buf]
	mov ebx, dword[left_buf]
	xor ebx, eax		; Ксорим все это добро
	pop eax
	mov dword[left_buf], eax; Фейстелируемся!!!
	mov dword[right_buf], ebx

	mov esi, str1		; Снова сравниваем строки для того, чтобы определить, что делать с регистром ecx
	mov edi, encr
	mov ecx, lenencr
	cld
	repe cmpsb
	jecxz enk
	
	pop ecx
	dec ecx 
	jmp sk
enk:
	pop ecx
	inc ecx
sk:
	pop edi
	inc edi
	cmp edi, 32		; Проверка на то, что мы бахнули 32 раза
	jne G

	mov eax, 4
	mov ebx, [fd2]
	mov ecx, right_buf	; Выводим блоки в ином порядке по ФЕЙСТЕЛЮ!!!
	mov edx, 4
	int 0x80

	mov eax, 4
	mov ebx, [fd2]
	mov ecx, left_buf
	mov edx, 4
	int 0x80

	jmp read		; Прыгаем для чтения нового блока открытого текста
exit:
	mov eax, 4
	mov ebx, 1
	mov ecx, done
	mov edx, lendone
	int 0x80

	jmp End
Err2:
	mov eax, 6
	mov ebx, [fd3]		; Закрываем файлики
	int 0x80
End:
	mov eax, 6
	mov ebx, [fd1]
	int 0x80

	mov eax, 6
	mov ebx, [fd2]
	int 0x80

	mov eax, 1		; Конец
	mov ebx, 0
	int 0x80

Switch_key:
	cmp ecx, 8
	jl kick
	cmp ecx, 16
	jl k_2
	cmp ecx, 24
	jl k_3
	jmp k_4
k_2:
	sub esi, 8
	jmp kick
k_3:
	sub esi, 16
	jmp kick
k_4:
	mov esi, 31
	sub esi, ecx
kick:
	ret
Add_ing:
	mov al, byte[right_buf+esi]
	mov dl, byte[right_buf+edi]
	mov byte[right_buf+esi], dl
	mov byte[right_buf+edi], al
	inc esi
	dec edi
	xor edx, edx
	xor eax, eax
	loop Add_ing
	ret
Fix1:
	mov byte[left_buf+esi], al
	inc esi
	cmp esi, 4
	jne Fix1
	ret
Fix2:
	mov byte[right_buf+esi], al
	inc esi
	cmp esi, 4
	jne Fix2
	ret		
