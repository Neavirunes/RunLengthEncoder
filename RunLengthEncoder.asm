; File:		RunLengthEncoder.asm
; Author:	Neavirunes
; Version:	1.0.0
; Date:		Summer 2018
;			Compresses files with RLE

global WinMain
extern CloseHandle
extern CreateFileW
extern FreeLibrary
extern GetCommandLineW
extern GetFileSizeEx
extern GetProcAddress
extern GetStdHandle
extern GetSystemInfo
extern HeapAlloc
extern HeapCreate
extern HeapDestroy
extern HeapFree
extern LoadLibraryExW
extern ReadFileEx
extern WriteFileEx

section .text
WinMain:
	push		rbp
	mov			rbp,					rsp
	sub			rsp,					40h

	xor			r8d,					r8d							; dwFlags
	xor			rdx,					rdx							; hFile
	mov			rcx,					GecverranLib				; lpLibFileName
	call		LoadLibraryExW
	mov			[GecHandle],			rax

	mov			rdx,					gecverranIntN				; lpProcName
	mov			rcx,					[GecHandle]					; hModule
	call		GetProcAddress
	mov			[gecverranIntA],		rax

	mov			ecx,					0fffffff6h					; nStdHandle
	call		GetStdHandle
	mov			[IHandle],				rax

	mov			ecx,					0fffffff5h					; nStdHandle
	call		GetStdHandle
	mov			[OHandle],				rax

	call		GetCommandLineW
	mov			rdi,					rax
	mov			rsi,					rax

	mov			rax,					2dh
	mov			rcx,					0ffh
	repne		scasw

	cmp			rcx,					00h
	je			ERRORSkipBytes

	cmp			word [rdi + 00h],		73h
	jne			ERRORSkipBytes

	cmp			word [rdi + 02h],		00h
	je			ERRORSkipBytes

	mov			qword [IntRaw],			00h
	mov			r15,					IntRaw
	add			rdi,					04h
	align 16, nop
GetNumber:
	mov			al,						[rdi]
	cmp			al,						20h
	je			ConvertNumber

	mov			[r15],					al

	inc			r15
	add			rdi,					02h
	jmp			GetNumber
ConvertNumber:
	mov			rcx,					IntRaw
	call		[gecverranIntA]
	mov			[IntFinal],				rax

	mov			rax,					2dh
	mov			rcx,					0ffh
	repne		scasw

	cmp			rcx,					00h
	je			ERRORInputFile

	cmp			word [rdi + 00h],		69h
	jne			ERRORInputFile

	cmp			word [rdi + 02h],		00h
	je			ERRORInputFile

	mov			rsi,					rdi
	mov			rax,					2eh
	mov			rcx,					0ffh
	repne		scasw

	add			rdi,					06h
	mov			byte [rdi],				00h
	mov			rdi,					rsi

	add			rdi,					04h
	mov			qword [rsp + 30h],		00h							; hTemplateFile
	mov			dword [rsp + 28h],		41000080h					; dwFlagsAndAttributes
	mov			dword [rsp + 20h],		03h							; dwCreationDisposition
	xor			r9,						r9							; lpSecurityAttributes
	mov			r8d,					01h							; dwShareMode
	mov			edx,					10000000h					; dwDesiredAccess
	mov			rcx,					rdi							; lpFileName
	call		CreateFileW
	mov			[CFile],				rax

	cmp			eax,					0ffh
	je			ERRORCreateInput

	mov			rax,					2dh
	mov			rcx,					0ffh
	repne		scasw

	cmp			rcx,					00h
	je			ERROROutputFile

	cmp			word [rdi + 00h],		6fh
	jne			ERROROutputFile

	cmp			word [rdi + 02h],		00h
	je			ERROROutputFile

	mov			rsi,					rdi
	mov			rax,					2eh
	mov			rcx,					0ffh
	repne		scasw

	add			rdi,					06h
	mov			byte [rdi],				00h
	mov			rdi,					rsi

	add			rdi,					04h
	mov			qword [rsp + 30h],		00h							; hTemplateFile
	mov			dword [rsp + 28h],		41000080h					; dwFlagsAndAttributes
	mov			dword [rsp + 20h],		02h							; dwCreationDisposition
	xor			r9,						r9							; lpSecurityAttributes
	mov			r8d,					01h							; dwShareMode
	mov			edx,					10000000h					; dwDesiredAccess
	mov			rcx,					rdi							; lpFileName
	call		CreateFileW
	mov			[OFile],				rax

	cmp			eax,					0ffh
	je			ERRORCreateOutput

	mov			rdx,					LargeInteger				; lpFileSize
	mov			rcx,					[CFile]						; hFile
	call		GetFileSizeEx

	mov			rcx,					SystemInfo					; lpSystemInfo
	call		GetSystemInfo

	mov			rax,					[LowPart1]
	mov			rbx,					[PageSize]
	xor			rdx,					rdx
	div			rbx

	inc			rax
	xor			rdx,					rdx
	mul			rbx
	mov			r15,					rax

	xor			r8d,					r8d							; dwMaximumSize
	xor			edx,					edx							; dwInitialSize
	mov			ecx,					04h							; flOptions
	call		HeapCreate
	mov			[CHeap],				rax

	xor			r8d,					r8d							; dwMaximumSize
	xor			edx,					edx							; dwInitialSize
	mov			ecx,					04h							; flOptions
	call		HeapCreate
	mov			[OHeap],				rax

	mov			r8d,					r15d						; dwBytes
	mov			edx,					08h							; dwFlags
	mov			rcx,					[CHeap]						; hHeap
	call		HeapAlloc
	mov			[CPointer],				rax

	add			r15,					r15

	mov			r8d,					r15d						; dwBytes
	mov			edx,					08h							; dwFlags
	mov			rcx,					[OHeap]						; hHeap
	call		HeapAlloc
	mov			[OPointer],				rax

	mov			qword [rsp + 20h],		00h							; lpCompletionRoutine
	mov			r9,						ROverlapped					; lpOverlapped
	mov			r8d,					[LowPart1]					; nNumberOfBytesToRead
	mov			rdx,					[CPointer]					; lpBuffer
	mov			rcx,					[CFile]						; hFile
	call		ReadFileEx

	mov			rsi,					[CPointer]
	mov			r15,					[LowPart1]
	add			r15,					rsi
	sub			r15,					[IntFinal]
SkipBytes:
	mov			rcx,					[IntFinal]
	mov			rdi,					[OPointer]
	rep			movsb

	mov			r14,					rdi
	inc			rdi

	mov			r13b,					00h
	mov			r12b,					0ffh
	mov			r8d,					01h
	align 16, nop
Encode:
	cmp			rsi,					r15
	jg			Output

	mov			al,						[rsi]
	cmp			al,						[rsi + 01h]
	je			Same1

	mov			[rdi],					al

	inc			r13b
	inc			r8d
	inc			rdi
	inc			rsi
	jmp			Encode
Same1:
	cmp			r13b,					00h
	je			Same2

	mov			[r14],					r13b
	mov			r14,					rdi
	inc			rdi
Same2:
	xchg		rdi,					rsi
	mov			rcx,					0ffh
	repe		scasb
	xchg		rdi,					rsi

	sub			r12b,					cl
	add			r12b,					7eh

	mov			[r14],					r12b
	mov			[rdi],					al

	add			r14,					02h
	mov			r13b,					00h
	mov			r12b,					0ffh
	add			r8d,					03h
	add			rdi,					02h
	dec			rsi

	jmp			Encode
Output:
	mov			[r14],					r13b
	sub			r8d,					03h

	mov			qword [rsp + 20],		00h							; lpCompletionRoutine
	mov			r9,						WOverlapped					; lpOverlapped
																	; nNumberOfBytesToWrite
	mov			rdx,					[OPointer]					; lpBuffer
	mov			rcx,					[OFile]						; hFile
	call		WriteFileEx

	jmp			ExitProgram
align 16, int3
ERRORCreateInput:
	mov			qword [rsp + 20],		00h							; lpCompletionRoutine
	mov			r9,						WOverlapped					; lpOverlapped
	mov			r8d,					26h							; nNumberOfBytesToWrite
	mov			rdx,					ErrorCInput					; lpBuffer
	mov			rcx,					[OHandle]					; hFile
	call		WriteFileEx

	jmp			ExitProgram
align 16, int3
ERRORCreateOutput:
	mov			qword [rsp + 20],		00h							; lpCompletionRoutine
	mov			r9,						WOverlapped					; lpOverlapped
	mov			r8d,					27h							; nNumberOfBytesToWrite
	mov			rdx,					ErrorCOutput				; lpBuffer
	mov			rcx,					[OHandle]					; hFile
	call		WriteFileEx

	jmp			ExitProgram
align 16, int3
ERRORInputFile:
	mov			qword [rsp + 20],		00h							; lpCompletionRoutine
	mov			r9,						WOverlapped					; lpOverlapped
	mov			r8d,					1fh							; nNumberOfBytesToWrite
	mov			rdx,					ErrorIFile					; lpBuffer
	mov			rcx,					[OHandle]					; hFile
	call		WriteFileEx

	jmp			ExitProgram
align 16, int3
ERROROutputFile:
	mov			qword [rsp + 20],		00h							; lpCompletionRoutine
	mov			r9,						WOverlapped					; lpOverlapped
	mov			r8d,					20h							; nNumberOfBytesToWrite
	mov			rdx,					ErrorOFile					; lpBuffer
	mov			rcx,					[OHandle]					; hFile
	call		WriteFileEx

	jmp			ExitProgram
align 16, int3
ERRORSkipBytes:
	mov			qword [rsp + 20],		00h							; lpCompletionRoutine
	mov			r9,						WOverlapped					; lpOverlapped
	mov			r8d,					28h							; nNumberOfBytesToWrite
	mov			rdx,					ErrorSBytes					; lpBuffer
	mov			rcx,					[OHandle]					; hFile
	call		WriteFileEx

	jmp			ExitProgram
align 16, int3
ExitProgram:
	mov			rcx,					[GecHandle]					; hLibModule
	call		FreeLibrary

	mov			r8,						[CPointer]					; lpMem
	xor			edx,					edx							; dwFlags
	mov			rcx,					[CHeap]						; hHeap
	call		HeapFree

	mov			r8,						[OPointer]					; lpMem
	xor			edx,					edx							; dwFlags
	mov			rcx,					[OHeap]						; hHeap
	call		HeapFree

	mov			rcx,					[CHeap]						; hHeap
	call		HeapDestroy

	mov			rcx,					[OHeap]						; hHeap
	call		HeapDestroy

	mov			rcx,					[CFile]						; hObject
	call		CloseHandle

	mov			rcx,					[OFile]						; hObject
	call		CloseHandle

	add			rsp,					40h
	pop			rbp
	ret

section .data
ErrorCInput:	db		'ERROR : Failed to create input file!', 0dh, 0ah, 00h
				align 16, db 00h
ErrorCOutput:	db		'ERROR : Failed to create output file!', 0dh, 0ah, 00h
				align 16, db 00h
ErrorIFile:		db		'ERROR : Input file not given!', 0dh, 0ah, 00h
				align 16, db 00h
ErrorOFile:		db		'ERROR : Output file not given!', 0dh, 0ah, 00h
				align 16, db 00h
ErrorSBytes:	db		'ERROR : Skip bytes argument not given!', 0dh, 0ah, 00h
				align 16, db 00h
gecverranIntN:	db		'gecverranInt', 00h
				align 16, db 00h
GecverranLib:	dw		__utf16__'C:\Program Files\Neavirunes\Windows\Gecverran\Gecverran.dll', 00h
				align 16, db 00h

section .bss
; - Large Integer Structure -----------------------------------------
LargeInteger:
LowPart1:		resd	01h											; LowPart
HighPart1:		resd	01h											; HighPart
LowPart2:		resd	01h											; LowPart
HightPart2:		resd	01h											; HighPart
QuadPart:		resq	01h											; QuadPart
; -------------------------------------------------------------------
Pad1:			resq	01h

; - Overlapped Structure (Reading) ----------------------------------
ROverlapped:
ROInternal:		resq	01h											; Internal
ROInternalHigh:	resq	01h											; InternalHigh
ROOffset:		resd	01h											; Offset
ROOffsetHigh:	resd	01h											; OffsetHigh
ROPointer:		resq	01h											; Pointer
ROHEvent:		resq	01h											; hEvent
; -------------------------------------------------------------------
Pad2:			resq 	01h

; - Overlapped Structure (Writing) ----------------------------------
WOverlapped:
WOInternal:		resq	01h											; Internal
WOInternalHigh:	resq	01h											; InternalHigh
WOOffset:		resd	01h											; Offset
WOOffsetHigh:	resd	01h											; OffsetHigh
WOPointer:		resq	01h											; Pointer
WOHEvent:		resq	01h											; hEvent
; -------------------------------------------------------------------
Pad3:			resq 	01h

; - System Info Structure -------------------------------------------
SystemInfo:
OEMID:			resd	01h											; dwOemId
Architecture:	resw	01h											; wProcessorArchitecture
SInfoReserved1:	resw	01h											; wReserved
PageSize:		resd	01h											; dwPageSize
MinAppAddress:	resq	01h											; lpMinimumApplicationAddress
MaxAppAddress:	resq	01h											; lpMaximumApplicationAddress
AProcessorMask:	resd	01h											; dwActiveProcessorMask
NumProcessors:	resd	01h											; dwNumberOfProcessors
ProcessorType:	resd	01h											; dwProcessorType
AllocGran:		resd	01h											; dwAllocationGranularity
ProcessorLevel:	resw	01h											; wProcessorLevel
ProcessorRev:	resw	01h											; wProcessorRevision
; -------------------------------------------------------------------
Pad4:			resq	02h

CFile:			resq	01h
CHeap:			resq	01h

CPointer:		resq	01h
GecHandle:		resq	01h

gecverranIntA:	resq	01h
IHandle:		resq	01h

IntFinal:		resq	01h
IntRaw:			resq	01h

OFile:			resq	01h
OHandle:		resq	01h

OHeap:			resq	01h
OPointer:		resq	01h
