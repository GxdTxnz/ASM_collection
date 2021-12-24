# собираете:
	1. nasm -felf32 magma.asm
	2. ld -m elf_i386 magma.o -o magma
# команды: 
	~./magma MSG.txt RES1.txt Key.txt(потом пишите "-e", когда прога попросит) шифр
	~./magma RES1.txt MSG.txt Key.txt( -d соотвественно) дешифр
# когда дешифруете, то заранее откройте файл MSG.txt, чтобы вы видели, что файл был перезаписан
