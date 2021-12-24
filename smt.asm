%include "macros.inc"

section .data
   NUL       equ  0
   SYS_EXIT  equ  1
   SYS_FORK  equ  2
   SYS_READ  equ  3
   SYS_WRITE equ  4
   SYS_OPEN  equ  5
   SYS_CLOSE equ  6
   SYS_CREAT equ  8
   SYS_LSEEK equ  19

   newline db 0xa 	;новая линия
   len_newline equ $ - newline

   num0 db '00000', 0xa 	;убывающая штука (кол-во символов в строке и столбце для свапа)
   len0 equ $ - num0
   num1 db '00000', 0xa 	;количество элементов матрицы
   len1 equ $ - num1
   num2 db '00001', 0xa 	;инкремент/дектремент
   len2 equ $ - num2
   num3 db '00000', 0xa 	;шаг и идентификатор конца
   len3 equ $ - num3

   ;-_-_-_-_-_-_-_-_-_-_-_-_-_-_Работа с матрицей внутри cycle3-_-_-_-_-_-_-_-_-_-_-_-_-_-_
   idx1 db '00000', 0xa 	;число цифр в строке/в столбце, которе каждый раз убывает внутри cycle2
   len_of_idx1 equ $ - idx1

   idx2 db '00000', 0xa 	;cмещение внутри угла на n символов пока не равно числу символов в строке
   len_of_idx2 equ $ - idx2

   variable1 db '00000', 0xa
   len_of_variable equ $ - variable1

   variable2 db '00000', 0xa
   len_of_variable equ $ - variable2

   comp1 db '00001', 0xa 	;просто строка для сравнения
   len_of_comp1 equ $ - comp1

   comp2 db '00000', 0xa 	;просто строка для сравнения
   len_of_comp2 equ $ - comp2

   offset1 db '00000', 0xa 		;смещение по столбцу для начала работы с даными
   len_of_offset1 equ $ - offset1

   offset2 db '00000', 0xa 		;смещение по строке для начала работы с даными
   len_of_offset2 equ $ - offset2

   offset_for_string db '00000', 0xa 		;смещение по строке для начала работы с даными
   len_of_offset_for_string equ $ - offset_for_string
   
section .bss
   info resb  1
   exchange_buf1 resb  1
   exchange_buf2 resb  1
   offset_file resb 4
   fd_in resb 1

section .text
    global _start

_start:
   	pop ebx ; argc
   	pop ebx ; argv [0]
   	pop ebx ; argv [1]

   	open_file ebx, 2
   
   	mov  [ fd_in ], eax

  	read:	;считаем сколько цифр в строке
      	; Считываем данные из файла
      	read_file [ fd_in ], info, 1

      	mov al, [ info ]
      	cmp al, 0xA      ; 0xA - окончание файла
      	je conitnue1     ; если равен 0xA переходим в conitnue1

      	cmp al, '0'
      	jl read

      	cmp al, '9'
      	jg read

      	mov esi, 4       ; считаем кол-во цифр в строке
      	mov ecx, 5       ; с учётом того, что матрица квадратная получаем кол-во столбцов в матрице
      	clc

      	add_loop:
         	mov al, [ num1 + esi ]
         	adc al, [ num2 + esi ]
         	aaa

         	pushf
         	or al, 0x30
         	popf
            
         	mov [ num1 + esi ], al
         	dec esi
      	loop add_loop

      	clone_of_string len1, num1, num0 	; приравниваем пустое значение num0 к num1 = количеству цифр в строке

    jmp read    ; возвращаемся к read

    conitnue1:

    	cycle1:

	      	comparison_of_strings num0, comp1, len0	;сравниваем число цифр в строке с 00001 и если они равны то последний шаг не выполняем и выходим из программы
			jecxz exit

			jmp cycle2

			exit:
				; Закрываем файл
				close_file [ fd_in ] ;4-th MACROS

				mov eax, SYS_EXIT
				mov ebx, NUL
				int 0x80

		cycle2:	;цикл который по идее должен читать цифру кидать её в буфер, читать вторую цифру, кидать ее на место перовой
					;и из буффера кидать циру на место второй

			fseek_file [fd_in], 0, 0	;возвращаемся в начало файла

			clone_of_string len3, num3, offset1 	;смещение по столбцам

			clone_of_string len3, num3, offset2 	;смещение по строкам

			clone_of_string len_of_offset1, offset1, offset_for_string
			cycle3:
				comparison_of_strings offset1, comp2, len_of_offset1 	;сравниваем смещение с 00000
				jecxz cycle4

				read_file [ fd_in ], info, 1

				mov al, [ info ]
				cmp al, 0xA      ; 0xA - окончание строки
				jne cycle3

				mov esi, 4
			    mov ecx, 5
			    clc

		    	sub_loop_23:
			        mov al, [ offset1 + esi ]
			        sbb al, [ num2 + esi ]
			        aas

			        pushf
			        or al, 0x30
			        popf
			            
			        mov [ offset1 + esi ], al
			        dec esi
			    loop sub_loop_23
			jmp cycle3

			cycle4:
				comparison_of_strings offset2, comp2, len_of_offset2 	;сравниваем смещение с 00000
				jecxz continue5

				read_file [ fd_in ], info, 1

				mov al, [ info ]

				cmp al, '0'
				jl cycle4

				cmp al, '9'
				jg cycle4

				mov esi, 4
				mov ecx, 5
				clc

			    sub_loop_33:
				    mov al, [ offset2 + esi ]
				    sbb al, [ num2 + esi ]
				    aas

				    pushf
				    or al, 0x30
				    popf
				            
				    mov [ offset2 + esi ], al
				    dec esi
				loop sub_loop_33

			jmp cycle4

		continue5:

			read888:
				read_file [ fd_in ], info, 1

				mov al, [ info ]

				cmp al, '0'
				jl read888

				cmp al, '9'
				jg read888

				fseek_file [ fd_in ], -1, 1
			
			mov [ offset_file ], eax
			clone_of_string len0, num0, idx1

			cycle34:
				fseek_file [fd_in], [ offset_file ], 0

				;-_-_-_-_-_-_-_-_-_-_-_-_все операции делать тут-_-_-_-_-_-_-_-_-_-_-_-_
				read101:
					read_file [ fd_in ], info, 1

					mov al, [ info ]

			      	cmp al, '0'
			      	jl read101

			      	cmp al, '9'
			      	jg read101

			      	mov esi, 4	;смещаемся по строке вправо/по столбцу вниз и сравниваем с самим смещением
					mov ecx, 5
					clc

				    add_loop_34:
					    mov al, [ variable1 + esi ]
					    adc al, [ num2 + esi ]
					    aaa

					    pushf
					    or al, 0x30
					    popf
					            
					    mov [ variable1 + esi ], al
					    dec esi
					loop add_loop_34

					comparison_of_strings variable1, idx1, len_of_idx1
					jecxz continue10

				jmp read101

				continue10:
				mov al, [ info ]
				mov [ exchange_buf1 ], al
				;write_consol info, 1		;---------------------------------OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
				clone_of_string len_of_comp2, comp2, variable1
				fseek_file [ fd_in ], [ offset_file ], 0

				read102:
					read_file [ fd_in ], info, 1
					comparison_of_strings variable1, comp2, len_of_comp2
					jecxz continue101

					mov al, [ info ]

			      	cmp al, 0xA
			      	jne read102

			      	read4646:
			      		read_file [ fd_in ], info, 1

						mov al, [ info ]

				      	cmp al, '0'
				      	jl read4646

				      	cmp al, '9'
				      	jg read4646

				      	comparison_of_strings variable2, offset_for_string, len_of_offset_for_string
						jecxz continue101

						mov esi, 4	;смещаемся по строке вправо/по столбцу вниз и сравниваем с самим смещением
						mov ecx, 5
						clc

					    add_loop_3454:
						    mov al, [ variable2 + esi ]
						    adc al, [ num2 + esi ]
						    aaa

						    pushf
						    or al, 0x30
						    popf
						            
						    mov [ variable2 + esi ], al
						    dec esi
						loop add_loop_3454
			      	jmp read4646

			      	continue101:

			      	clone_of_string len_of_comp2, comp2, variable2

			      	mov esi, 4	;смещаемся по строке вправо/по столбцу вниз и сравниваем с самим смещением
					mov ecx, 5
					clc

				    add_loop_344:
					    mov al, [ variable1 + esi ]
					    adc al, [ num2 + esi ]
					    aaa

					    pushf
					    or al, 0x30
					    popf
					            
					    mov [ variable1 + esi ], al
					    dec esi
					loop add_loop_344
					
					comparison_of_strings variable1, idx1, len_of_idx1
					jecxz continue11

				jmp read102

				continue11:

				clone_of_string len_of_comp2, comp2, variable1
				mov al, [ info ]
				mov [ exchange_buf2 ], al
				;write_consol info, 1	;---------------------------------OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
				fseek_file [ fd_in ], -1, 1
				write_file [ fd_in ], exchange_buf1, 1

				fseek_file [fd_in], [ offset_file ], 0
				read103:
					read_file [ fd_in ], info, 1

					mov al, [ info ]

			      	cmp al, '0'
			      	jl read103

			      	cmp al, '9'
			      	jg read103

			      	mov esi, 4	;смещаемся по строке вправо/по столбцу вниз и сравниваем с самим смещением
					mov ecx, 5
					clc

				    add_loop_3465:
					    mov al, [ variable1 + esi ]
					    adc al, [ num2 + esi ]
					    aaa

					    pushf
					    or al, 0x30
					    popf
					            
					    mov [ variable1 + esi ], al
					    dec esi
					loop add_loop_3465

					;write_consol info, 1
					;write_consol idx2, len_of_idx2

					comparison_of_strings variable1, idx1, len_of_idx1
					jecxz continue1010

				jmp read103

				continue1010:
				clone_of_string len_of_comp2, comp2, variable1
				fseek_file [ fd_in ], -1, 1
				write_file [ fd_in ], exchange_buf2, 1
				
				;-_-_-_-_-_-_-_-_-_-_-_-_все операции делать тут-_-_-_-_-_-_-_-_-_-_-_-_

				mov esi, 4	;увеличиваем смещение по строке вправо/по столбцу вниз
				mov ecx, 5
				clc

			    add_loop_38:
				    mov al, [ idx2 + esi ]
				    adc al, [ num2 + esi ]
				    aaa

				    pushf
				    or al, 0x30
				    popf
				            
				    mov [ idx2 + esi ], al
				    dec esi
				loop add_loop_38

				mov esi, 4	;ведём счёт сколько цифр до конца строки осталось
				mov ecx, 5
				clc

			    sub_loop_34:
				    mov al, [ idx1 + esi ]
				    sbb al, [ num2 + esi ]
				    aas

				    pushf
				    or al, 0x30
				    popf
				            
				    mov [ idx1 + esi ], al
				    dec esi
				loop sub_loop_34

				comparison_of_strings idx1, comp2, len_of_idx1
				jecxz continue7

			jmp cycle34

			continue7:
			clone_of_string len_of_comp2, comp2, idx2
			pop eax

    		mov esi, 4		;считаем сколько шагов сделали
	      	mov ecx, 5
	      	clc

    		add_loop_1:
	         	mov al, [ num3 + esi ]
	         	adc al, [ num2 + esi ]
	         	aaa

	         	pushf
	         	or al, 0x30
	         	popf
	            
	         	mov [ num3 + esi ], al
	         	dec esi
	      	loop add_loop_1

    		conitnue2:

    		mov esi, 4		;считаем сколько цифр надо менять местами
	      	mov ecx, 5
	      	clc

    		sub_loop_3:
	         	mov al, [ num0 + esi ]
	         	sbb al, [ num2 + esi ]
	         	aas

	         	pushf
	         	or al, 0x30
	         	popf
	            
	         	mov [ num0 + esi ], al
	         	dec esi
	      	loop sub_loop_3
    	jmp cycle1

;4 5 4 1 9 4 4 6 4 7 4 9 4 5 0 5 0 5 0 4 0 2 6
;4 5 5 1 6 1 2 7 7 8 4 9 1 5 3 5 2 5 7 4 3 2 6
;5 5 5 1 2 4 5 6 7 7 8 9 1 5 3 5 2 5 7 4 3 2 6
;4 5 5 1 2 4 5 6 7 7 8 9 1 5 3 5 2 5 7 4 3 2 6
;2 0 4 5 6 7 8 9 0 1 4 3 9 0 9 0 7 0 6 0 5 0 4
;1 3 9 8 7 6 5 4 3 2 1 0 2 3 4 5 3 1 2 7 8 9 0
;5 5 5 1 2 4 5 6 7 7 8 9 1 5 3 5 2 5 7 4 3 2 6
;9 0 4 5 6 7 8 9 0 1 4 3 9 0 9 0 7 0 6 0 5 0 4
;7 4 4 4 4 4 4 4 4 4 4 4 6 7 6 7 6 7 6 7 6 7 6
;1 3 9 8 7 6 5 4 3 2 1 0 2 3 4 5 3 1 2 7 8 9 0
;8 5 5 4 3 2 1 0 2 1 2 3 1 5 3 5 2 5 7 4 3 2 6
;9 0 4 5 6 7 8 9 0 1 4 3 9 0 9 0 7 0 6 0 5 0 4
;1 4 4 4 4 4 4 4 4 4 4 4 6 7 6 7 6 7 6 7 6 7 6
;0 9 8 9 8 9 8 9 8 9 8 9 1 3 9 8 7 6 5 1 3 9 8
;0 0 1 2 4 5 3 6 9 3 2 1 4 4 4 4 2 4 5 4 5 3 9
;0 0 0 1 2 4 5 3 6 9 3 2 5 8 4 9 2 3 9 7 7 1 2
;0 0 0 0 1 2 4 5 3 6 9 3 3 6 9 3 2 5 8 4 9 2 3
;0 0 0 0 0 1 2 4 5 3 6 9 9 8 9 8 9 8 9 8 9 0 0
;0 0 0 0 0 0 1 2 4 5 3 6 4 5 6 7 8 9 0 8 8 8 9
;0 0 0 0 0 0 0 1 2 4 5 3 0 0 0 0 0 0 0 0 6 6 6
;0 0 0 0 0 0 0 0 1 2 4 5 5 6 7 8 9 0 7 7 7 0 1
;0 0 0 0 0 0 0 0 0 1 2 4 5 5 6 7 8 9 0 7 7 7 0
;0 0 0 0 0 0 0 0 0 0 1 2 4 5 5 6 7 8 9 0 7 7 7
