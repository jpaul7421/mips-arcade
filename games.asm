# MIPS Game Project - Tic-Tac-Toe, Blackjack, T-Rex Runner
# Target: original MARS 4.5, default memory configuration, delayed branching OFF.
# Use supplied MIPSArcade.jar: Tools > Arcade Display and Input > Connect to MIPS.
# Its bitmap is 512x512 (8x8 units), base 0x10008000. Click directly in it.
# All game rules, button hit tests, physics, and artwork execute in MIPS.
# AI disclosure: ChatGPT assisted with design, source, tests, and documentation.
# All artwork is drawn by this program; no external game source was copied.
# Convention: a0-a3 arguments, v0 result; t0-t9 caller-saved.
# draw_rect additionally takes RGB color in t9. Nonleaf routines save ra.

.eqv FB 0x10008000
.eqv KEY_CTRL 0xffff0000
.eqv KEY_DATA 0xffff0004
.eqv CLICK_CTRL 0xffff0100
.eqv HELD_KEYS 0xffff010c
.eqv FRAME_READY 0xffff0110
# Runner tuning: quarter-pixel velocity/gravity, milliseconds between frames.
.eqv JUMP_SPEED -17
.eqv GRAVITY 2
.eqv FRAME_MS 50
.eqv WHITE 0x00e9eef4
.eqv BG 0x00131e2c
.eqv BLUE 0x0068bdff
.eqv GREEN 0x005de2a5
.eqv RED 0x00ff7777

.macro text (%str, %x, %y)
    la $a0, %str
    li $a1, %x
    li $a2, %y
    jal draw_text
.end_macro
.macro button (%str, %x, %y, %width)
    la $a0, %str
    li $a1, %x
    li $a2, %y
    li $a3, %width
    jal draw_button
.end_macro
.macro box (%x, %y, %w, %h, %rgb)
    li $a0, %x
    li $a1, %y
    li $a2, %w
    li $a3, %h
    li $t9, %rgb
    jal draw_rect
.end_macro

.data
menu_title: .asciiz "MIPS ARCADE"
menu_ttt: .asciiz "1 TIC TAC TOE"
menu_bj: .asciiz "2 BLACKJACK"
menu_dino: .asciiz "3 T-REX RUNNER"
menu_quit: .asciiz "Q QUIT"
menu_hint: .asciiz "CLICK A GAME"
invalid: .asciiz "INVALID KEY"
ttt_title: .asciiz "TIC TAC TOE"
turn_x: .asciiz "TURN X"
turn_o: .asciiz "TURN O"
win_x: .asciiz "X WINS"
win_o: .asciiz "O WINS"
tie_text: .asciiz "DRAW"
occupied: .asciiz "CELL TAKEN"
move_hint: .asciiz "CLICK A CELL"
end_hint: .asciiz "R REPLAY Q MENU"
btn_menu: .asciiz "MENU"
btn_replay: .asciiz "REPLAY"
btn_hit: .asciiz "HIT"
btn_stand: .asciiz "STAND"
btn_start: .asciiz "START"
black_title: .asciiz "BLACKJACK"
dealer_label: .asciiz "DEALER"
player_label: .asciiz "PLAYER"
hit_hint: .asciiz "YOUR TURN"
q_hint: .asciiz "Q MENU"
player_win: .asciiz "PLAYER WINS"
dealer_win: .asciiz "DEALER WINS"
player_bust: .asciiz "PLAYER BUST"
dealer_bust: .asciiz "DEALER BUST"
natural_text: .asciiz "BLACKJACK WIN"
push_text: .asciiz "PUSH"
limit_text: .asciiz "HAND LIMIT"
hidden_text: .asciiz "?"
trex_title: .asciiz "T-REX RUNNER"
score_label: .asciiz "SCORE"
jump_hint: .asciiz "W: JUMP"
duck_hint: .asciiz "S: CROUCH"
start_hint: .asciiz "SPACE START"
game_over_text: .asciiz "GAME OVER"
dino_win: .asciiz "10 CLEARED WIN"
rank_chars: .asciiz "A23456789TJQK"
glyph: .space 2
number_buf: .space 12
.align 2
board: .space 36
current_player: .word 1
move_count: .word 0
ttt_result: .word 0
win_lines: .word 0,1,2, 3,4,5, 6,7,8, 0,3,6, 1,4,7, 2,5,8, 0,4,8, 2,4,6
deck: .space 208
deck_left: .word 52
player_hand: .space 64
dealer_hand: .space 64
player_count: .word 0
dealer_count: .word 0
revealed: .word 0
bj_status: .word 0
cactus_x: .word 60
dino_y: .word 47
dino_y_quarters: .word 188
velocity: .word 0
score: .word 0
tick: .word 0
dino_status: .word 0
obstacle_type: .word 0
crouching: .word 0
jump_previous: .word 0
input_mode: .word -1
# Input modes: 0 menu, 1 board, 2 blackjack, 3 runner, 4 end, 5 runner start.
circle_rows: .half 56,198,130,257,257,257,130,198,56
# ASCII 32..90; five rows of three bits per glyph. Unsupported glyphs blank.
font:
.byte 0,0,0,0,0, 2,2,2,0,2, 5,5,0,0,0, 0,0,0,0,0
.byte 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 2,2,0,0,0
.byte 1,2,2,2,1, 4,2,2,2,4, 0,0,0,0,0, 0,2,7,2,0
.byte 0,0,0,2,4, 0,0,7,0,0, 0,0,0,0,2, 1,1,2,4,4
.byte 7,5,5,5,7, 2,6,2,2,7, 7,1,7,4,7, 7,1,7,1,7
.byte 5,5,7,1,1, 7,4,7,1,7, 7,4,7,5,7, 7,1,2,2,2
.byte 7,5,7,5,7, 7,5,7,1,7, 0,2,0,2,0, 0,0,0,0,0
.byte 1,2,4,2,1, 0,7,0,7,0, 4,2,1,2,4, 7,1,2,0,2
.byte 0,0,0,0,0, 2,5,7,5,5, 6,5,6,5,6, 3,4,4,4,3
.byte 6,5,5,5,6, 7,4,6,4,7, 7,4,6,4,4, 3,4,5,5,3
.byte 5,5,7,5,5, 7,2,2,2,7, 1,1,1,5,2, 5,5,6,5,5
.byte 4,4,4,4,7, 5,7,7,5,5, 5,7,7,7,5, 2,5,5,5,2
.byte 6,5,6,4,4, 2,5,5,7,3, 6,5,6,5,5, 3,4,2,1,6
.byte 7,2,2,2,2, 5,5,5,5,7, 5,5,5,5,2, 5,5,7,7,5
.byte 5,5,2,5,5, 5,5,2,2,2, 7,1,2,4,7

.text
.globl main
main:
    li $v0, 30
    syscall
    move $a1, $a0
    li $a0, 0
    li $v0, 40
    syscall
menu:
    li $a0, 0
    jal set_input_mode
    jal clear_screen
    text (menu_title, 10, 5)
    button (menu_ttt, 2, 17, 60)
    button (menu_bj, 2, 27, 60)
    button (menu_dino, 2, 37, 60)
    button (menu_quit, 2, 47, 60)
    text (menu_hint, 4, 58)
    jal present_frame
menu_key:
    jal wait_key
    beq $v0, 49, play_ttt
    beq $v0, 50, play_blackjack
    beq $v0, 51, play_dino
    beq $v0, 113, quit
    text (invalid, 4, 12)
    jal present_frame
    j menu_key
quit:
    li $v0, 10
    syscall

# Leaf: return a keyboard character or a MIPS-decoded click; 0 if none.
poll_key:
    li $t0, KEY_CTRL
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    move $v0, $zero
    beqz $t1, poll_mouse
    lw $v0, 4($t0)
    andi $v0, $v0, 255
    blt $v0, 65, poll_done
    bgt $v0, 90, poll_done
    addiu $v0, $v0, 32
poll_done:
    jr $ra

# Mouse publication: tool writes x/y BEFORE ready=1; MIPS snapshots before ack.
# All coordinates are logical 0..63. Outside/border clicks return -1.
poll_mouse:
    li $t0, CLICK_CTRL
    lw $t1, 0($t0)
    beqz $t1, poll_done
    lw $t2, 4($t0)
    lw $t3, 8($t0)
    sw $zero, 0($t0)
    li $v0, -1
    bltz $t2, poll_done
    bltz $t3, poll_done
    bge $t2, 64, poll_done
    bge $t3, 64, poll_done
    lw $t4, input_mode
    beqz $t4, mouse_menu
    beq $t4, 4, mouse_end
    beq $t4, 1, mouse_board
    beq $t4, 2, mouse_blackjack
    beq $t4, 5, mouse_start
    # Runner only has Menu during active play.
    blt $t3, 56, poll_done
    blt $t2, 34, poll_done
    li $v0, 113
    jr $ra
mouse_end:
    blt $t3, 56, poll_done
    bge $t2, 34, mouse_q
    bge $t2, 30, poll_done
    li $v0, 114
    jr $ra
mouse_q:
    li $v0, 113
    jr $ra
mouse_start:
    blt $t3, 56, poll_done
    bge $t2, 34, mouse_q
    bge $t2, 30, poll_done
    li $v0, 32
    jr $ra
mouse_blackjack:
    blt $t3, 56, poll_done
    bge $t2, 44, mouse_q
    blt $t2, 14, mouse_hit
    blt $t2, 16, poll_done
    bge $t2, 40, poll_done
    li $v0, 115
    jr $ra
mouse_hit:
    li $v0, 104
    jr $ra
mouse_board:
    blt $t3, 56, mouse_cell
    bge $t2, 34, mouse_q
    jr $ra
mouse_cell:
    blt $t2, 10, poll_done
    bge $t2, 52, poll_done
    blt $t3, 9, poll_done
    bge $t3, 51, poll_done
    addiu $t2, $t2, -10
    addiu $t3, $t3, -9
    li $t5, 14
    div $t2, $t5
    mflo $t6
    mfhi $t7
    beqz $t2, mouse_row
    beqz $t7, poll_done
mouse_row:
    div $t3, $t5
    mflo $t8
    mfhi $t7
    beqz $t3, mouse_cell_result
    beqz $t7, poll_done
mouse_cell_result:
    mul $t8, $t8, 3
    addu $v0, $t8, $t6
    addiu $v0, $v0, 49
    jr $ra
mouse_menu:
    blt $t2, 2, poll_done
    bge $t2, 62, poll_done
    blt $t3, 17, poll_done
    addiu $t3, $t3, -17
    li $t5, 10
    div $t3, $t5
    mflo $t6
    mfhi $t7
    bge $t7, 8, poll_done
    bgt $t6, 3, poll_done
    beq $t6, 3, mouse_q
    addiu $v0, $t6, 49
    jr $ra

# Change input context; discard an old pending click when changing screens.
set_input_mode:
    lw $t0, input_mode
    beq $t0, $a0, mode_done
    sw $a0, input_mode
    li $t0, CLICK_CTRL
    sw $zero, 0($t0)
mode_done:
    jr $ra

# The Java tool presents completed MIPS frames, avoiding clear/redraw flicker.
present_frame:
    li $t0, FRAME_READY
    li $t1, 1
    sw $t1, 0($t0)
    jr $ra
wait_key:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
wait_loop:
    jal poll_key
    beqz $v0, wait_loop
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

# Leaf: fill all 4096 framebuffer words, safely below data at 0x10010000.
clear_screen:
    li $t0, FB
    li $t1, 4096
    li $t2, BG
clear_loop:
    sw $t2, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    bnez $t1, clear_loop
    jr $ra

# Leaf: clipped rectangle at (a0,a1), size(a2,a3), color t9.
draw_rect:
    blez $a2, rect_done
    blez $a3, rect_done
    move $t0, $zero
rect_row:
    addu $t1, $a1, $t0
    bltz $t1, rect_next_row
    bge $t1, 64, rect_next_row
    move $t2, $zero
rect_col:
    addu $t3, $a0, $t2
    bltz $t3, rect_next_col
    bge $t3, 64, rect_next_col
    sll $t4, $t1, 6
    addu $t4, $t4, $t3
    sll $t4, $t4, 2
    li $t5, FB
    addu $t4, $t4, $t5
    sw $t9, 0($t4)
rect_next_col:
    addiu $t2, $t2, 1
    blt $t2, $a2, rect_col
rect_next_row:
    addiu $t0, $t0, 1
    blt $t0, $a3, rect_row
rect_done:
    jr $ra

# Leaf: white 3x5 text; a0 string, a1 x, a2 y. Transparent background.
draw_text:
    move $t0, $a0
    move $t1, $a1
text_char:
    lbu $t2, 0($t0)
    beqz $t2, text_done
    blt $t2, 32, text_advance
    bgt $t2, 90, text_advance
    addiu $t2, $t2, -32
    mul $t2, $t2, 5
    la $t3, font
    addu $t3, $t3, $t2
    li $t4, 0
text_row:
    lbu $t5, 0($t3)
    li $t6, 0
text_col:
    li $t7, 4
    srlv $t7, $t7, $t6
    and $t7, $t7, $t5
    beqz $t7, text_next_col
    addu $t7, $t1, $t6
    bltz $t7, text_next_col
    bge $t7, 64, text_next_col
    addu $t8, $a2, $t4
    bltz $t8, text_next_col
    bge $t8, 64, text_next_col
    sll $t8, $t8, 6
    addu $t8, $t8, $t7
    sll $t8, $t8, 2
    li $t7, FB
    addu $t8, $t8, $t7
    li $t7, WHITE
    sw $t7, 0($t8)
text_next_col:
    addiu $t6, $t6, 1
    blt $t6, 3, text_col
    addiu $t3, $t3, 1
    addiu $t4, $t4, 1
    blt $t4, 5, text_row
text_advance:
    addiu $t0, $t0, 1
    addiu $t1, $t1, 4
    j text_char
text_done:
    jr $ra

# Convert nonnegative a0 to decimal, then draw at (a1,a2).
draw_number:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    la $t0, number_buf
    addiu $t0, $t0, 11
    sb $zero, 0($t0)
    li $t1, 10
number_loop:
    divu $a0, $t1
    mflo $a0
    mfhi $t2
    addiu $t2, $t2, 48
    addiu $t0, $t0, -1
    sb $t2, 0($t0)
    bnez $a0, number_loop
    move $a0, $t0
    jal draw_text
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

# ---------------------- TIC-TAC-TOE ----------------------
# Reusable button: a0 label; a1 x; a2 y; a3 width. Height is 8 cells.
draw_button:
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    move $a0, $s1
    move $a1, $s2
    move $a2, $s3
    li $a3, 8
    li $t9, BLUE
    jal draw_rect
    addiu $a0, $s1, 1
    addiu $a1, $s2, 1
    addiu $a2, $s3, -2
    li $a3, 6
    li $t9, BG
    jal draw_rect
    move $a0, $s0
    addiu $a1, $s1, 2
    addiu $a2, $s2, 2
    jal draw_text
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addiu $sp, $sp, 24
    jr $ra

draw_end_buttons:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    button (btn_replay, 0, 56, 30)
    button (btn_menu, 34, 56, 30)
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

# Leaf: dedicated 9x9 marks. X has equal diagonals; O is a hollow circle.
# a0 player (1 X, 2 O), a1 x, a2 y. Empty cells draw no mark.
draw_mark:
    li $t0, 0
mark_row:
    li $t1, 0
    la $t2, circle_rows
    sll $t3, $t0, 1
    addu $t2, $t2, $t3
    lhu $t2, 0($t2)
mark_col:
    beq $a0, 1, mark_x
    li $t3, 256
    srlv $t3, $t3, $t1
    and $t3, $t3, $t2
    beqz $t3, mark_next
    li $t7, GREEN
    j mark_pixel
mark_x:
    beq $t0, $t1, mark_x_pixel
    addu $t3, $t0, $t1
    bne $t3, 8, mark_next
mark_x_pixel:
    li $t7, BLUE
mark_pixel:
    addu $t4, $a2, $t0
    sll $t4, $t4, 6
    addu $t5, $a1, $t1
    addu $t4, $t4, $t5
    sll $t4, $t4, 2
    li $t5, FB
    addu $t4, $t4, $t5
    sw $t7, 0($t4)
mark_next:
    addiu $t1, $t1, 1
    blt $t1, 9, mark_col
    addiu $t0, $t0, 1
    blt $t0, 9, mark_row
    jr $ra

# Main game controllers never return; leaf helpers still use jr ra.
play_ttt:
    la $t0, board
    li $t1, 9
ttt_reset_loop:
    sw $zero, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    bnez $t1, ttt_reset_loop
    li $t0, 1
    sw $t0, current_player
    sw $zero, move_count
    sw $zero, ttt_result
ttt_turn:
    jal draw_ttt
ttt_input:
    jal wait_key
    beq $v0, 113, menu
    blt $v0, 49, ttt_bad
    bgt $v0, 57, ttt_bad
    addiu $t0, $v0, -49
    sll $t0, $t0, 2
    la $t1, board
    addu $t1, $t1, $t0
    lw $t2, 0($t1)
    bnez $t2, ttt_taken
    lw $t2, current_player
    sw $t2, 0($t1)
    lw $t0, move_count
    addiu $t0, $t0, 1
    sw $t0, move_count
    jal check_winner
    sw $v0, ttt_result
    bnez $v0, ttt_end
    lw $t0, move_count
    beq $t0, 9, ttt_draw
    lw $t0, current_player
    li $t1, 3
    subu $t0, $t1, $t0
    sw $t0, current_player
    j ttt_turn
ttt_bad:
    box (0, 51, 64, 5, BG)
    text (invalid, 4, 51)
    jal present_frame
    j ttt_input
ttt_taken:
    box (0, 51, 64, 5, BG)
    text (occupied, 4, 51)
    jal present_frame
    j ttt_input
ttt_draw:
    li $t0, 3
    sw $t0, ttt_result
ttt_end:
    jal draw_ttt
ttt_end_input:
    jal wait_key
    beq $v0, 114, play_ttt
    beq $v0, 113, menu
    j ttt_end_input

# Leaf: v0=0 none, 1 X, 2 O. Scan eight winning triplets.
check_winner:
    la $t0, win_lines
    li $t1, 8
    la $t2, board
    move $v0, $zero
winner_loop:
    lw $t3, 0($t0)
    sll $t3, $t3, 2
    addu $t3, $t3, $t2
    lw $t4, 0($t3)
    beqz $t4, winner_next
    lw $t3, 4($t0)
    sll $t3, $t3, 2
    addu $t3, $t3, $t2
    lw $t5, 0($t3)
    bne $t4, $t5, winner_next
    lw $t3, 8($t0)
    sll $t3, $t3, 2
    addu $t3, $t3, $t2
    lw $t5, 0($t3)
    bne $t4, $t5, winner_next
    move $v0, $t4
    jr $ra
winner_next:
    addiu $t0, $t0, 12
    addiu $t1, $t1, -1
    bnez $t1, winner_loop
    jr $ra

draw_ttt:
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    li $a0, 1
    lw $t0, ttt_result
    beqz $t0, ttt_mode_ready
    li $a0, 4
ttt_mode_ready:
    jal set_input_mode
    jal clear_screen
    text (ttt_title, 10, 2)
    box (24, 9, 1, 42, WHITE)
    box (38, 9, 1, 42, WHITE)
    box (10, 23, 42, 1, WHITE)
    box (10, 37, 42, 1, WHITE)
    li $s0, 0
ttt_cell:
    li $t0, 3
    div $s0, $t0
    mflo $t1
    mfhi $t2
    mul $s1, $t2, 14
    addiu $s1, $s1, 13
    mul $s2, $t1, 14
    addiu $s2, $s2, 12
    sll $t0, $s0, 2
    la $t1, board
    addu $t0, $t0, $t1
    lw $t0, 0($t0)
    beqz $t0, ttt_next_cell
    move $a0, $t0
    move $a1, $s1
    move $a2, $s2
    jal draw_mark
ttt_next_cell:
    addiu $s0, $s0, 1
    blt $s0, 9, ttt_cell
    lw $t0, ttt_result
    beq $t0, 1, ttt_show_x
    beq $t0, 2, ttt_show_o
    beq $t0, 3, ttt_show_draw
    lw $t0, current_player
    la $a0, turn_x
    beq $t0, 1, ttt_status
    la $a0, turn_o
    j ttt_status
ttt_show_x:
    la $a0, win_x
    j ttt_status
ttt_show_o:
    la $a0, win_o
    j ttt_status
ttt_show_draw:
    la $a0, tie_text
ttt_status:
    li $a1, 4
    li $a2, 51
    jal draw_text
    lw $t0, ttt_result
    bnez $t0, ttt_replay_hint
    button (btn_menu, 34, 56, 30)
    j ttt_draw_done
ttt_replay_hint:
    jal draw_end_buttons
ttt_draw_done:
    jal present_frame
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addiu $sp, $sp, 24
    jr $ra

# ------------------------ BLACKJACK ------------------------
# One 52-card deck per round, no replacement. A=1/11; J,Q,K=10.
# Dealer stands on ALL 17s (including soft 17). No bets/splits/doubles.
# bj_status: 0 playing, 1 win, 2 lose, 3 push, 4 bust, 5 dealer bust,
# 6 player natural, 7 safety capacity reached.
play_blackjack:
    sw $zero, player_count
    sw $zero, dealer_count
    sw $zero, revealed
    sw $zero, bj_status
    li $t0, 52
    sw $t0, deck_left
    li $t0, 0
    la $t1, deck
deck_init_loop:
    li $t2, 13
    div $t0, $t2
    mfhi $t2
    addiu $t2, $t2, 1
    sw $t2, 0($t1)
    addiu $t1, $t1, 4
    addiu $t0, $t0, 1
    blt $t0, 52, deck_init_loop
    la $a0, player_hand
    la $a1, player_count
    jal deal_card
    la $a0, dealer_hand
    la $a1, dealer_count
    jal deal_card
    la $a0, player_hand
    la $a1, player_count
    jal deal_card
    la $a0, dealer_hand
    la $a1, dealer_count
    jal deal_card
    la $a0, player_hand
    lw $a1, player_count
    jal hand_total
    move $s0, $v0
    la $a0, dealer_hand
    lw $a1, dealer_count
    jal hand_total
    beq $s0, 21, bj_player_natural
    beq $v0, 21, bj_lose
bj_player_turn:
    jal draw_blackjack
bj_read:
    jal wait_key
    beq $v0, 113, menu
    beq $v0, 115, bj_dealer_turn
    bne $v0, 104, bj_invalid
    la $a0, player_hand
    la $a1, player_count
    jal deal_card
    beqz $v0, bj_capacity
    la $a0, player_hand
    lw $a1, player_count
    jal hand_total
    bgt $v0, 21, bj_bust
    beq $v0, 21, bj_dealer_turn
    j bj_player_turn
bj_invalid:
    box (0, 51, 64, 5, BG)
    text (invalid, 2, 51)
    jal present_frame
    j bj_read
bj_player_natural:
    beq $v0, 21, bj_push
    li $t0, 6
    j bj_finish
bj_dealer_turn:
    li $t0, 1
    sw $t0, revealed
bj_dealer_loop:
    la $a0, dealer_hand
    lw $a1, dealer_count
    jal hand_total
    bgt $v0, 21, bj_dealer_bust
    bge $v0, 17, bj_compare
    la $a0, dealer_hand
    la $a1, dealer_count
    jal deal_card
    beqz $v0, bj_capacity
    j bj_dealer_loop
bj_compare:
    move $s0, $v0
    la $a0, player_hand
    lw $a1, player_count
    jal hand_total
    bgt $v0, $s0, bj_win
    beq $v0, $s0, bj_push
bj_lose:
    li $t0, 2
    j bj_finish
bj_win:
    li $t0, 1
    j bj_finish
bj_push:
    li $t0, 3
    j bj_finish
bj_bust:
    li $t0, 4
    j bj_finish
bj_dealer_bust:
    li $t0, 5
    j bj_finish
bj_capacity:
    li $t0, 7
bj_finish:
    sw $t0, bj_status
    li $t0, 1
    sw $t0, revealed
    jal draw_blackjack
bj_end_input:
    jal wait_key
    beq $v0, 114, play_blackjack
    beq $v0, 113, menu
    j bj_end_input

# a0 hand base, a1 address of count. v0=1 success, 0 capacity/deck empty.
# Random index selects remaining card; swap last into selected slot.
deal_card:
    move $t6, $a0
    move $t7, $a1
    lw $t8, 0($t7)
    move $v0, $zero
    bge $t8, 16, deal_done
    lw $t0, deck_left
    blez $t0, deal_done
    move $a1, $t0
    li $a0, 0
    li $v0, 42
    syscall
    sll $t1, $a0, 2
    la $t2, deck
    addu $t1, $t1, $t2
    lw $t3, 0($t1)
    addiu $t0, $t0, -1
    sw $t0, deck_left
    sll $t4, $t0, 2
    addu $t4, $t4, $t2
    lw $t5, 0($t4)
    sw $t5, 0($t1)
    sll $t4, $t8, 2
    addu $t4, $t4, $t6
    sw $t3, 0($t4)
    addiu $t8, $t8, 1
    sw $t8, 0($t7)
    li $v0, 1
deal_done:
    jr $ra

# Leaf: sum all cards with aces=1, then promote ONE ace by 10 if safe.
hand_total:
    move $v0, $zero
    li $t0, 0
    li $t1, 0
hand_loop:
    bge $t0, $a1, hand_promote
    sll $t2, $t0, 2
    addu $t2, $t2, $a0
    lw $t2, 0($t2)
    bne $t2, 1, hand_face
    li $t1, 1
hand_face:
    ble $t2, 10, hand_add
    li $t2, 10
hand_add:
    addu $v0, $v0, $t2
    addiu $t0, $t0, 1
    j hand_loop
hand_promote:
    beqz $t1, hand_done
    bgt $v0, 11, hand_done
    addiu $v0, $v0, 10
hand_done:
    jr $ra

# a0 hand, a1 count, a2 top y, a3 hide second card (dealer only).
draw_hand:
    addiu $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)
    sw $s4, 8($sp)
    sw $s5, 4($sp)
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    li $s4, 0
draw_hand_loop:
    bge $s4, $s1, draw_hand_done
    li $t0, 8
    div $s4, $t0
    mflo $t1
    mfhi $t2
    mul $t1, $t1, 8
    addu $t1, $t1, $s2
    mul $s5, $t2, 8
    addiu $s5, $s5, 1
    sw $t1, 0($sp)
    move $a0, $s5
    move $a1, $t1
    li $a2, 6
    li $a3, 7
    li $t9, BLUE
    jal draw_rect
    beqz $s3, draw_rank
    beq $s4, 1, draw_hidden
draw_rank:
    sll $t0, $s4, 2
    addu $t0, $t0, $s0
    lw $t0, 0($t0)
    addiu $t0, $t0, -1
    la $t1, rank_chars
    addu $t0, $t0, $t1
    lbu $t0, 0($t0)
    sb $t0, glyph
    la $a0, glyph
    j draw_rank_text
draw_hidden:
    la $a0, hidden_text
draw_rank_text:
    addiu $a1, $s5, 1
    lw $a2, 0($sp)
    addiu $a2, $a2, 1
    jal draw_text
    addiu $s4, $s4, 1
    j draw_hand_loop
draw_hand_done:
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    lw $s3, 12($sp)
    lw $s2, 16($sp)
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    addiu $sp, $sp, 32
    jr $ra

draw_blackjack:
    addiu $sp, $sp, -8
    sw $ra, 4($sp)
    li $a0, 2
    lw $t0, bj_status
    beqz $t0, bj_mode_ready
    li $a0, 4
bj_mode_ready:
    jal set_input_mode
    jal clear_screen
    text (black_title, 12, 1)
    text (dealer_label, 2, 8)
    lw $t0, revealed
    beqz $t0, bj_hidden_total
    la $a0, dealer_hand
    lw $a1, dealer_count
    jal hand_total
    move $a0, $v0
    li $a1, 34
    li $a2, 8
    jal draw_number
    j bj_dealer_cards
bj_hidden_total:
    text (hidden_text, 34, 8)
bj_dealer_cards:
    la $a0, dealer_hand
    lw $a1, dealer_count
    li $a2, 14
    lw $t0, revealed
    xori $a3, $t0, 1
    jal draw_hand
    text (player_label, 2, 30)
    la $a0, player_hand
    lw $a1, player_count
    jal hand_total
    move $a0, $v0
    li $a1, 34
    li $a2, 30
    jal draw_number
    la $a0, player_hand
    lw $a1, player_count
    li $a2, 36
    li $a3, 0
    jal draw_hand
    lw $t0, bj_status
    bnez $t0, bj_result_text
    text (hit_hint, 2, 51)
    button (btn_hit, 0, 56, 14)
    button (btn_stand, 16, 56, 24)
    button (btn_menu, 44, 56, 20)
    j bj_draw_done
bj_result_text:
    la $a0, player_win
    beq $t0, 1, bj_show_result
    la $a0, dealer_win
    beq $t0, 2, bj_show_result
    la $a0, push_text
    beq $t0, 3, bj_show_result
    la $a0, player_bust
    beq $t0, 4, bj_show_result
    la $a0, dealer_bust
    beq $t0, 5, bj_show_result
    la $a0, natural_text
    beq $t0, 6, bj_show_result
    la $a0, limit_text
bj_show_result:
    li $a1, 2
    li $a2, 51
    jal draw_text
    jal draw_end_buttons
bj_draw_done:
    jal present_frame
    lw $ra, 4($sp)
    addiu $sp, $sp, 8
    jr $ra

# ----------------------- T-REX RUNNER -----------------------
# 50ms requested sleep/frame (MARS speed must be unlimited).
# Dino bounding box x=8..15, y=dino_y..dino_y+6; ground top y=54.
# Cactus: x..x+2,y48..53; bird: x..x+5,y46..49.
# Quarter-pixel physics: jump -17 (-4.25 px), gravity +2 (+0.5 px).
# 18-frame jump cycle: between the original 13 and the overlong 25-frame arc.
# Standing dinosaur: x8..15,y..y+6. Crouched: x8..17,y51..53.
# HELD_KEYS bit0 jump, bit1 duck. Jump on press, duck while held on ground.
play_dino:
    li $t0, 60
    sw $t0, cactus_x
    li $t0, 47
    sw $t0, dino_y
    li $t0, 188
    sw $t0, dino_y_quarters
    sw $zero, velocity
    sw $zero, score
    sw $zero, tick
    sw $zero, dino_status
    sw $zero, obstacle_type
    sw $zero, crouching
    sw $zero, jump_previous
    jal draw_dino_scene
    li $a0, 5
    jal set_input_mode
    button (btn_start, 0, 56, 30)
    jal present_frame
dino_start:
    jal wait_key
    beq $v0, 113, menu
    beq $v0, 32, dino_frame
    text (invalid, 2, 39)
    jal present_frame
    j dino_start
dino_frame:
    jal poll_key
    beq $v0, 113, menu
    li $t0, HELD_KEYS
    lw $t0, 0($t0)
    andi $t1, $t0, 1
    lw $t2, jump_previous
    sw $t1, jump_previous
    beqz $t1, dino_jump_event
    bnez $t2, dino_jump_event
    li $v0, 119
dino_jump_event:
    beq $v0, 32, dino_try_jump
    beq $v0, 119, dino_try_jump
    beqz $v0, dino_update
    beq $v0, 115, dino_update
    j dino_bad_key
dino_try_jump:
    andi $t1, $t0, 2
    bnez $t1, dino_update
    lw $t0, dino_y
    bne $t0, 47, dino_update
    li $t0, JUMP_SPEED
    sw $t0, velocity
    j dino_update
dino_bad_key:
    # Invalid keys are harmless: no state mutation; show one-frame notice.
    li $t0, 3
    sw $t0, dino_status
dino_update:
    lw $t0, dino_y_quarters
    lw $t1, velocity
    addu $t0, $t0, $t1
    bge $t0, 188, dino_land
    addiu $t1, $t1, GRAVITY
    j dino_store_y
dino_land:
    li $t0, 188
    li $t1, 0
dino_store_y:
    sw $t0, dino_y_quarters
    sra $t0, $t0, 2
    sw $t0, dino_y
    sw $t1, velocity
    # Recompute after physics so a held duck takes effect on the landing frame.
    sw $zero, crouching
    bne $t0, 47, dino_move_obstacle
    li $t2, HELD_KEYS
    lw $t2, 0($t2)
    andi $t2, $t2, 2
    beqz $t2, dino_move_obstacle
    li $t2, 1
    sw $t2, crouching
dino_move_obstacle:
    lw $t0, cactus_x
    addiu $t0, $t0, -1
    sw $t0, cactus_x
    jal check_collision
    bnez $v0, dino_crash
    lw $t0, cactus_x
    lw $t1, obstacle_type
    beqz $t1, dino_cactus_extent
    addiu $t0, $t0, 5
    j dino_score_check
dino_cactus_extent:
    addiu $t0, $t0, 2
dino_score_check:
    bgez $t0, dino_no_score
    lw $t0, score
    addiu $t0, $t0, 1
    sw $t0, score
    beq $t0, 10, dino_victory
    # Random restart 60..63; enough time to recover after previous jump.
    li $a0, 0
    li $a1, 4
    li $v0, 42
    syscall
    addiu $t0, $a0, 60
    sw $t0, cactus_x
    li $a0, 0
    li $a1, 2
    li $v0, 42
    syscall
    sw $a0, obstacle_type
dino_no_score:
    lw $t0, tick
    addiu $t0, $t0, 1
    sw $t0, tick
    jal draw_dino_scene
    sw $zero, dino_status
dino_delay:
    li $a0, FRAME_MS
    li $v0, 32
    syscall
    j dino_frame
dino_crash:
    li $t0, 1
    sw $t0, dino_status
    j dino_end
dino_victory:
    li $t0, 2
    sw $t0, dino_status
dino_end:
    jal draw_dino_scene
dino_end_input:
    jal wait_key
    beq $v0, 114, play_dino
    beq $v0, 113, menu
    j dino_end_input

# Leaf: standing/crouched and cactus/bird bounding boxes must overlap on x/y.
check_collision:
    move $v0, $zero
    lw $t0, cactus_x
    li $t2, 15
    lw $t3, crouching
    beqz $t3, collision_width
    li $t2, 17
collision_width:
    bgt $t0, $t2, collision_done
    lw $t4, obstacle_type
    li $t5, 48
    li $t6, 53
    beqz $t4, collision_cactus
    li $t5, 46
    li $t6, 49
    addiu $t0, $t0, 5
    j collision_left
collision_cactus:
    addiu $t0, $t0, 2
collision_left:
    blt $t0, 8, collision_done
    lw $t1, dino_y
    beqz $t3, collision_standing
    li $t1, 51
    li $t2, 53
    j collision_vertical
collision_standing:
    addiu $t1, $t1, 6
    move $t2, $t1
    addiu $t1, $t1, -6
collision_vertical:
    bgt $t1, $t6, collision_done
    blt $t2, $t5, collision_done
    li $v0, 1
collision_done:
    jr $ra

draw_dino_scene:
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    li $a0, 3
    lw $t0, dino_status
    beq $t0, 1, dino_end_mode
    bne $t0, 2, dino_mode_ready
dino_end_mode:
    li $a0, 4
dino_mode_ready:
    jal set_input_mode
    jal clear_screen
    text (trex_title, 10, 2)
    text (score_label, 2, 11)
    lw $a0, score
    li $a1, 28
    li $a2, 11
    jal draw_number
    box (0, 54, 64, 1, WHITE)
    # Moving ground markers.
    lw $t0, tick
    andi $t0, $t0, 7
    li $s0, 8
    subu $s0, $s0, $t0
ground_marks:
    move $a0, $s0
    li $a1, 55
    li $a2, 3
    li $a3, 1
    li $t9, BLUE
    jal draw_rect
    addiu $s0, $s0, 12
    blt $s0, 64, ground_marks
    # Dino: head, neck/body, tail, two feet, and contrasting eye.
    lw $s0, dino_y
    lw $t0, crouching
    bnez $t0, draw_ducking_dino
    li $a0, 12
    move $a1, $s0
    li $a2, 4
    li $a3, 3
    li $t9, GREEN
    jal draw_rect
    li $a0, 10
    addiu $a1, $s0, 2
    li $a2, 4
    li $a3, 3
    li $t9, GREEN
    jal draw_rect
    li $a0, 8
    addiu $a1, $s0, 3
    li $a2, 3
    li $a3, 1
    li $t9, GREEN
    jal draw_rect
    li $a0, 10
    addiu $a1, $s0, 5
    li $a2, 1
    li $a3, 2
    li $t9, GREEN
    jal draw_rect
    li $a0, 13
    addiu $a1, $s0, 5
    li $a2, 1
    li $a3, 2
    li $t9, GREEN
    jal draw_rect
    li $a0, 14
    addiu $a1, $s0, 1
    li $a2, 1
    li $a3, 1
    li $t9, BG
    jal draw_rect
    j draw_obstacle
draw_ducking_dino:
    box (8, 52, 8, 2, GREEN)
    box (14, 51, 4, 2, GREEN)
    box (16, 51, 1, 1, BG)
draw_obstacle:
    # Cactus fits entirely inside its 3x6 collision box.
    lw $s1, cactus_x
    lw $t0, obstacle_type
    bnez $t0, draw_bird
    addiu $a0, $s1, 1
    li $a1, 48
    li $a2, 1
    li $a3, 6
    li $t9, RED
    jal draw_rect
    move $a0, $s1
    li $a1, 50
    li $a2, 3
    li $a3, 2
    li $t9, RED
    jal draw_rect
    j draw_obstacle_done
draw_bird:
    move $a0, $s1
    li $a1, 47
    li $a2, 6
    li $a3, 2
    li $t9, RED
    jal draw_rect
    addiu $a0, $s1, 2
    lw $t0, tick
    andi $t0, $t0, 2
    li $a1, 46
    beqz $t0, bird_wing
    li $a1, 49
bird_wing:
    li $a2, 2
    li $a3, 1
    li $t9, RED
    jal draw_rect
draw_obstacle_done:
    lw $t0, dino_status
    beq $t0, 1, dino_show_loss
    beq $t0, 2, dino_show_win
    bne $t0, 3, dino_show_controls
    text (invalid, 2, 39)
dino_show_controls:
    text (jump_hint, 2, 23)
    text (duck_hint, 2, 31)
    button (btn_menu, 34, 56, 30)
    j dino_draw_done
dino_show_loss:
    text (game_over_text, 2, 32)
    jal draw_end_buttons
    j dino_draw_done
dino_show_win:
    text (dino_win, 2, 32)
    jal draw_end_buttons
dino_draw_done:
    jal present_frame
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addiu $sp, $sp, 16
    jr $ra
