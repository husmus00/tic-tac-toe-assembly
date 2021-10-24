org 100h

;
; Initialise
;
                   
; Set video mode
mov AL, 03h
mov AH, 0
int 10h

; Set cursor position
mov DH, 1
mov DL, 1
mov BH, 0
mov AH, 2
int 10h

; Set attribute to white foreground, black background
mov BL, 0Fh

;
; ----------
;

game_loop:
    ; Main loop body
    call print_grid
    call print_current_player
    call print_message
    call get_input
    call set_chosen_position
    call check_victory
    
    ; Check if any player has won (player_has_won variable will be 1)
    cmp player_has_won, 1
    je player_won
    
    ; Switching current player
    cmp current_player, 0 ; 0 if X, 1 if O
    je is_x_gl
    
    ; is_o_gl:
        mov current_player, 0        
        jmp game_loop
    
    is_x_gl:
        mov current_player, 1
        jmp game_loop

; Sets the correct attribute and prints the character
print_char PROC
                                                         
    mov AH, 09h ; Set interrupt to print
    mov CX, 1 ; So that the character is only printed once
    
    ; Set the correct attribute
    cmp AL, "X"
    je is_x_pc
    cmp AL, "O"
    je is_o_pc
    ; is something other than X or O
    ; Set attribute to white foreground, black background
    mov BL, 0Fh
    jmp print_char_interrupt
    
    is_x_pc:
        mov BL, 09h ; 9h is the light blue attribute
        jmp print_char_interrupt
        
    is_o_pc:
        mov BL, 0Ch ; Ch is the light red attribute
    
    print_char_interrupt:
    int 10h
    
    inc DL ; Incrementing the cursor position horizontally
    mov AH, 2h ; Set interrupt to set cursor position
    int 10h
      
    ret
print_char ENDP

carriage_return PROC
    inc DH ; Incrementing the cursor position vertically
    mov DL, 1 ; Resetting horizontal cursor position
    mov AH, 2h ; Set interrupt to set cursor position
    int 10h
    
    ret
    
carriage_return ENDP

; Prints the grid to the screen
print_grid PROC
    
    ; Set video mode to clear screen
    mov AL, 03h
    mov AH, 0
    int 10h
    
    ; reset cursor position
    mov DL, 1
    mov DH, 1
    mov AH, 2h ; Set interrupt to set cursor position
    int 10h
    
    ; Row 1
    
    mov AL, pos[0]
    call print_char
    
    mov AL, '|'
    call print_char
    
    mov AL, pos[1]
    call print_char
    
    mov AL, '|'
    call print_char
    
    mov AL, pos[2]
    call print_char
    
    call carriage_return
    
    ; Row 2
    
    mov AL, '-'
    call print_char
    
    mov AL, '+'
    call print_char
    
    mov AL, '-'
    call print_char
    
    mov AL, '+'
    call print_char
    
    mov AL, '-'
    call print_char
    
    call carriage_return
    
    ; Row 3
    
    mov AL, pos[3]
    call print_char
    
    mov AL, '|'
    call print_char
    
    mov AL, pos[4]
    call print_char
    
    mov AL, '|'
    call print_char
    
    mov AL, pos[5]
    call print_char
    
    call carriage_return
    
    ; Row 4
    
    mov AL, '-'
    call print_char
    
    mov AL, '+'
    call print_char
    
    mov AL, '-'
    call print_char
    
    mov AL, '+'
    call print_char
    
    mov AL, '-'
    call print_char
    
    call carriage_return
    
    ; Row 5
    
    mov AL, pos[6]
    call print_char
    
    mov AL, '|'
    call print_char
    
    mov AL, pos[7]
    call print_char
    
    mov AL, '|'
    call print_char
    
    mov AL, pos[8]
    call print_char
    
    call carriage_return
    call carriage_return
    
    ret
print_grid ENDP
                         
; Print X or O with styling depending on turn                         
print_current_player PROC
    mov AH, 09h
    
    cmp current_player, 0 ; 0 if X, 1 if O
    je is_x
    
    ; is O
        mov AL, "O"
        mov BL, 0Ch ; C is the light red colour attribute
        jmp end_pcp
    
    is_x:
        mov AL, "X"
        mov BL, 09h ; 9 is the light blue colour attribute
    
    end_pcp:
        int 10h
        
        inc DL ; Incrementing the cursor position horizontally
        mov AH, 2h ; Set interrupt to set cursor position
        int 10h
        
        ret
print_current_player ENDP

print_message PROC
    ; BL will be used to as the index into the string
    mov BX, 0
    
    text_loop:
        mov AH, 0Ah ; Write character without attribute
        mov AL, message[BX]
        cmp AL, "$" ; Check for sentinel
        je end_text_loop ; End if sentinel is found
        int 10h
        inc BX
        
        inc DL ; Incrementing the cursor position horizontally
        mov AH, 2h ; Set interrupt to set cursor position
        int 10h
        
        jmp text_loop
        
    end_text_loop:
        call carriage_return
        ret
print_message ENDP

get_input PROC
    mov AH, 1 ; DOS interrupt to get character from keyboard
    int 21h
    
    ; AL will contain the inputted character
    
    ret
get_input ENDP
        
set_chosen_position PROC
    ; AL will contain the inputted value
    ; But we must subtract 31h to convert the ASCII input into a numerical value between 1 and 9, (31h and not 30h to account for 0-index)
    ; (assuming that the inputted value was between 1 and 9)
    
    SUB AL, 31h
    mov BL, AL ; Because we must use BX to index pos
    mov BH, 0
    
    cmp current_player, 0
    je is_x_scp
    
    ; is_O
        mov pos[BX], "O"
        jmp end_scp
    
    is_x_scp:
        mov pos[BX], "X"
    
    end_scp:
        ret
set_chosen_position ENDP

check_victory PROC
    ; First, we load the current player's letter (X or O) into AL.
    ; Then, for each row, column or diagonal to check, compare each of the 3 positions with AL.
    ; If all the comparisons are true, then we have a winner. This will be based on the current player since, if player X plays and
    ; a victory condition is found, it must have been X
    ; If the first position is a space " ", abort immediately since the line can't be a victory condition
    
    ; First, load AL with X or O depending on current turn
    cmp current_player, 0
    je is_x_cv
    
    ; is_o_cv
        mov AL, "O"
        jmp continue_check_victory
        
    is_x_cv:
        mov AL, "X"
    
    continue_check_victory:
    
    ; Row 1, 2, 3
    cmp pos[0], " "
    je continue_456 ; Check for " " empty position
    
    cmp AL, pos[0]
    jne continue_456
    cmp AL, pos[1]
    jne continue_456
    cmp AL, pos[2]
    jne continue_456   
    jmp victory
    
    ; Row 4, 5, 6
    continue_456:
    cmp pos[3], " "
    je continue_789 ; Check for " " empty position
    
    cmp AL, pos[3]
    jne continue_789
    cmp AL, pos[4]
    jne continue_789
    cmp AL, pos[5]
    jne continue_789    
    jmp victory
    
    ; Row 7, 8, 9
    continue_789:
    cmp pos[6], " "
    je continue_147 ; Check for " " empty position
    
    cmp AL, pos[6]
    jne continue_147
    cmp AL, pos[7]
    jne continue_147
    cmp AL, pos[8]
    jne continue_147    
    jmp victory
    
    ; Column 1, 4, 7
    continue_147:
    cmp pos[0], " "
    je continue_258 ; Check for " " empty position
    
    cmp AL, pos[0]
    jne continue_258
    cmp AL, pos[3]
    jne continue_258
    cmp AL, pos[6]
    jne continue_258    
    jmp victory
    
    ; Column 2, 5, 8
    continue_258:
    cmp pos[1], " "
    je continue_369 ; Check for " " empty position
    
    cmp AL, pos[1]
    jne continue_369
    cmp AL, pos[4]
    jne continue_369
    cmp AL, pos[7]
    jne continue_369    
    jmp victory
    
    ; Column 3, 6, 9
    continue_369:
    cmp pos[2], " "
    je continue_159 ; Check for " " empty position
    
    cmp AL, pos[2]
    jne continue_159
    cmp AL, pos[5]
    jne continue_159
    cmp AL, pos[8]
    jne continue_159    
    jmp victory
    
    ; Diagonal 1, 5, 9
    continue_159:
    cmp pos[0], " "
    je continue_357 ; Check for " " empty position
    
    cmp AL, pos[0]
    jne continue_357
    cmp AL, pos[4]
    jne continue_357
    cmp AL, pos[8]
    jne continue_357    
    jmp victory
    
    ; Diagonal 3, 5, 7
    continue_357:
    cmp pos[2], " "
    je no_victory ; Check for " " empty position
    
    cmp AL, pos[2]
    jne no_victory
    cmp AL, pos[4]
    jne no_victory
    cmp AL, pos[6]
    jne no_victory    
    jmp victory
    
    victory:
    mov player_has_won, 1
    
    no_victory:
    ret
check_victory ENDP

print_victory_message PROC
    ; BL will be used to as the index into the string
    mov BX, 0
    
    victory_text_loop:
        mov AH, 0Ah ; Write character without attribute
        mov AL, victory_message[BX]
        cmp AL, "$" ; Check for sentinel
        je end_victory_text_loop ; End if sentinel is found
        int 10h
        inc BX
        
        inc DL ; Incrementing the cursor position horizontally
        mov AH, 2h ; Set interrupt to set cursor position
        int 10h
        
        jmp victory_text_loop
        
    end_victory_text_loop:
        call carriage_return
        ret
print_victory_message ENDP

player_won:
call print_grid
call print_current_player
call print_victory_message

end_program:
ret

; 20H is the space character, duplicate 20H 9 times (for 9 positions)  
pos DB 9 DUP(20H) ; Array for the 9 grid positions

message DB ", choose position$" ; $ is the terminating character (sentinel character)

current_player DB 0 ; 0 for X and 1 for O

player_has_won DB 0 ; 0 if a player has not yet won, 1 if otherwise

victory_message DB " has won!$" ; $ is the terminating character (sentinel character)



