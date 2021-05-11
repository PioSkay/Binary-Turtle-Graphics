#file size of 600x50 pixels
.eqv HEADER_SIZE 122
.eqv BMP_FILE_SIZE 90122
.eqv BMP_IMG_SIZE 90000
.eqv BYTES_PER_ROW 1800

.data 
	.eqv BUFFOR_SIZE 1024
	#buffer
	buf: .space BUFFOR_SIZE
	#constant variables
	inputfile: .asciiz "input.bin"
	outputfile: .asciiz "output.bmp"
	enter: .asciiz "\n"
	#error msg
	readerr: .asciiz "Could not load the file!\n"
	conerr: .asciiz "There was an error in the conditions!\n"
	#---output-buffer---
		.space 2
	image:	.byte 0x42,0x4d,0x0a,0x60,0x01,0,0,0,0,0,0x7a,0,0,0,0x6c,0,0,0,0x58,0x02,0,0,0x32,0,0,0,0x01,0,0x18,0,0,0,0,0,0x90,0x5f,0x01,0,0x13,0x0b,0,0,0x13,0x0b,0,0,0,0,0,0,0,0,0,0,0x42,0x47,0x52,0x73,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0x02,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.space BMP_IMG_SIZE
	#-------------------
	RGB: .word 1 #R/G/B 8bit values
	posX: .word 1  #x position
	posY: .word 1 #y position
	direction: .space 1 #direction of the turtle
	move_blocks: .word 1 #number of block to move
	penState: .word 1 #state of the pen
	stringX: .asciiz "Position X: "
	stringY: .asciiz "Position Y: "
	stringAmount: .asciiz "Amount: "
	stringpenstate: .asciiz "Pen State: "
	stringcolor: .asciiz "Color: "
	stringdirection: .asciiz "Direction: "
.text
main:
	# $s7 - register controling the loop logic
	#0 -> loop is not processing any commands
	#1 -> first bit is 0
	#2 -> first bit is 1
	#3 -> second bit is 0
	#4 -> second bit is 1
	#5 -> 00 command
	#6 -> 01 command
	#7 -> 10 command
	#8 -> 11 command
	# $s6 -> clock 0 by default
	li 	$s7, 0
	li	$s6, 0
	#file reading mode of syscall (load immediate)
	li 	$v0, 13
	#loading input file (load address)
	la 	$a0, inputfile
	#setting the read flag (load immediate)
	li 	$a1, 0
	li 	$a2, 0
	syscall
	#saving the file descriptor
	move 	$s1, $v0
	#checking the errors (branch if less then zero)
	bltz 	$s1, read_error
load_from_file:
	#file read mode (load immediate)
	li 	$v0, 14
	#moving the file descriptor 
	move 	$a0, $s1
	#buffer of the string
	la 	$a1, buf
	#amount of bytes to read
	li 	$a2, BUFFOR_SIZE
	syscall
	#moving number of bytes
	move 	$t6, $v0
	li 	$t1, 0
	#wypisywanie znaków
	move 	$s4, $a1 
	jal close

# ============================================================================
#This method fill the pixels with with color.
fill_white:
	li	$t9, 0
	loop_white:
	li	$t8, 0
		subloop_white:
        	move  	$a0, $t9
       		move    $a1, $t8
        	li    	$a2, 0x00FFFFFF    #li     $a2, 0x00FF0000    #color - 00RRGGBB
       		jal    	put_pixel
       		add     $t8, $t8, 1
       		ble	$t8, 49, subloop_white 
	add     $t9, $t9, 1
    	ble	$t9, 599, loop_white
# ============================================================================
	move 	$t0, $t6
	li 	$t1, 0
#---------------main-loop-----------------------------------------------
outputloop:
	beq 	$t1, $t0, final_save
	lbu 	$a0, ($s4)
	#running the bit analizing tools
	j 	print_binary
read_error:
	#loading message to the address
	la 	$a0, readerr
	#changing the syscall to 4
	li 	$v0, 4
	syscall
	#terminating the program
	j 	end
print_binary:
	# Description:	takes an integer as input and prints as binary
	# Arguments:	a0:	an integer
	# Destroys:	s0,s1,s2,s3,a0,v0
	move	$s0, $a0
	addi	$s1, $zero, 31	# constant shift amount
	addi	$s2, $zero, 24	# variable shift amount
	addi	$s3, $zero, 32	# exit condition
print_binary_loop:
	beq	$s2, $s3, outputlooplogic
	sllv	$a0, $s0, $s2
	srlv	$a0, $a0, $s1
	addi	$s2, $s2, 1
	#load the cache
	bgt	$s6, 0, loading_cache
	#analize the first bit of the command
	ble	$s7, 2, first_bit
loading_cache:
	#saving a0 state
	move 	$t4, $a0
	jal logic_operations
loopafterlogic:
	move	$a0, $t4	
	sub 	$s6, $s6, 1
	#if after substraction our clock is zero we have to zero the command
	beq	$s6, 0, reinit
print_element:
	#li	$v0, 1
	#syscall
	j	print_binary_loop
outputlooplogic:
	addiu 	$s4, $s4, 1
	addiu 	$t1, $t1, 1
	j 	outputloop
reinit:
	#we do need to preceed logic operations in 0 bit
	jal logic_operations
	#loading 0 to the command register
	li 	$s7, 0
	j	print_element
#---------------main-loop-----------------------------------------------
logic_operations:
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, ($sp)
	
	move $t4, $a0
	#when clock is set our command was initialized
	beq	$s7, 5, zz_logic
	#when clock is set our command was initialized
	beq	$s7, 6, zb_logic
	#when clock is set our command was initialized
	beq	$s7, 7, bz_logic
	#when clock is set our command was initialized
	beq	$s7, 8, bb_logic
logic_done:
	move $a0, $t4
	jr $ra
#---------------commnads-pickup-----------------------------------------
first_bit:
	#this is not first bit first is zero
	beq $s7, 1, second_bit_z
	#this is not first bit first is one
	beq $s7, 2, second_bit_b
	add $s7, $s7, $a0
	add $s7, $s7, 1
	j print_element
second_bit_z:
	#00 case
	beq $a0, 0, command_zz
	#01 case
	beq $a0, 1, command_zb
	j con_error
second_bit_b:
	#case 10
	beq $a0, 0, command_bz
	#case 11
	beq $a0, 1, command_bb
	j con_error
command_zz:
	# Description:		changes the command to 00
	# Arguments:	a0:	an integer
	# Updates:	s7, s6
	#setting the clock
	li 	$s6, 14
	#setting the command
	li	$s7, 5 #00 mode
	li	$t9, 0
	#setting the address of direction to zero
	la	$a0, direction
	sb	$t9, ($a0)
	#exiting the init method
	li	$a0, 0
	j print_element
command_bz:
	# Description:		changes the command to 10
	# Arguments:	a0:	an integer
	# Updates:	s7, s6
	#setting the clock
	li 	$s6, 14
	#init value
	li	$t9, 0
	#setting the address of direction to zero
	la	$a0, RGB
	sw	$t9, ($a0)
	
	la	$a0, penState
	sw	$t9, ($a0)
		
	li	$a0, 0
	#setting the command
	li	$s7, 7 #10 mode 
	j print_element
command_zb:
	# Description:		changes the command to 01
	# Arguments:	a0:	an integer
	# Updates:	s7, s6
	#setting the clock
	li 	$s6, 30
	#setting the command
	li	$s7, 6 #01 mode 
	#init value
	li	$t9, 0
	#setting the address of direction to zero
	la	$a0, posX
	sw	$t9, ($a0)
	
	#setting the address of direction to zero
	la	$a0, posY
	sw	$t9, ($a0)
	#exiting the init method
	li	$a0, 1
	
	j print_element
command_bb:
	# Description:		changes the command to 11
	# Arguments:	a0:	an integer
	# Updates:	s0,s1,s2,s3,a0,v0
	#setting the clock
	li 	$s6, 14
	#setting the command
	li	$s7, 8 #01 mode 
	#init value
	li	$t9, 0
	#setting the address of direction to zero
	la	$a0, move_blocks
	sw	$t9, ($a0)
	li	$a0, 1
	j print_element
con_error:
	#loading message to the address
	la 	$a0, conerr
	#changing the syscall to 4
	li 	$v0, 4
	syscall
	#terminating the program
	j 	end
#---------------commnads-pickup-----------------------------------------
pow:
	#$a0 -> power
	# breaks $a1
	#$v0 -> output
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, ($sp)
	
	ble	$a0, -1, endpow
	
	li	$v0, 1
	#output 1 when power is 0
	beq	$a0, 0, endpow
	subpow:
		beq	$a0, 0, endpow
		mul	$v0, $v0, 2
		sub	$a0, $a0, 1
		j	subpow
endpow:
	jr	$ra
#---------------simple-debug--------------------------------------------
debug:
	#$a0 -> power
	# breaks $a1
	#$v0 -> output
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, ($sp)
	#--posX--
	la	$a0, stringX
	li	$v0, 4
	syscall
	la	$t8, posX
	lw	$a3, ($t8)
	move	$a0, $a3
	li	$v0, 1
	syscall
	la	$a0, enter
	li	$v0, 4
	syscall
	#--------
	#--posY--
	la	$a0, stringY
	li	$v0, 4
	syscall
	la	$t8, posY
	lw	$a3, ($t8)
	move	$a0, $a3
	li	$v0, 1
	syscall
	la	$a0, enter
	li	$v0, 4
	syscall
	#--------
	#--posY--
	la	$a0, stringAmount
	li	$v0, 4
	syscall
	la	$t8, move_blocks
	lw	$a3, ($t8)
	move	$a0, $a3
	li	$v0, 1
	syscall
	la	$a0, enter
	li	$v0, 4
	syscall
	#--------
	#--color--
	la	$a0, stringcolor
	li	$v0, 4
	syscall
	la	$t8, RGB
	lw	$a3, ($t8)
	move	$a0, $a3
	li	$v0, 1
	syscall
	la	$a0, enter
	li	$v0, 4
	syscall
	#--------
	#--penstate--
	la	$a0, stringpenstate
	li	$v0, 4
	syscall
	la	$t8, penState
	lw	$a3, ($t8)
	move	$a0, $a3
	li	$v0, 1
	syscall
	la	$a0, enter
	li	$v0, 4
	syscall
	#--------
	#--direction--
	la	$a0, stringdirection
	li	$v0, 4
	syscall
	la	$t8, direction
	lw	$a3, ($t8)
	move	$a0, $a3
	li	$v0, 1
	syscall
	la	$a0, enter
	li	$v0, 4
	syscall
	#--------
	jr	$ra
#----------------------------------------------------------------------
#---------------commands-logic------------------------------------------
#---------------zz_logic------------------------------------------------
zz_logic:
	#Saving the return address of previous method.
	#Here we have a jal in jal
	move 	$t9, $ra
	#current bit
	#move	$a1, $a0
	#current direction value
	beq	$s6, 0, zz_final_operation
	bge	$s6, 3, zz_logic_done
	beq	$a0, 0, zz_logic_done
	#li 	$v0, 1
	#syscall
	la	$t8, direction
	lb	$a3, ($t8)
	move	$a0, $s6 
	sub	$a0, $a0, 1
	#power
	jal 	pow
	move	$a0, $v0
	add	$a0, $a0, $a3
	sb	$a0, ($t8)
	#changing the syscall to 4
	#li 	$v0, 1
	#syscall
	j 	zz_logic_done
zz_final_operation:
	
zz_logic_done:
	move	$ra, $t9
	j logic_done
#---------------zz_logic------------------------------------------------
#---------------bz_logic------------------------------------------------
bz_logic:
	#Saving the return address of previous method.
	#Here we have a jal in jal
	move 	$t9, $ra
	#save the value of a0 register
	move	$t7, $a0
	beq	$s6, 0, bz_final_operation
	#a3 -> current power
	beq	$s6, 8, bz_G_bits
	beq	$s6, 4, bz_B_bits
	ble	$s6, 11, bz_x
	beq	$s6, 12, bz_x_init
	beq	$s6, 13, bz_init_pen
	j 	bz_logic_done
#skips 4 bits and enters bz_x
bz_init_pen:
	beq	$t7, 0, skip_pen_init
	li	$t8, 1
	la	$a0, penState
	sw	$t8, ($a0)
	skip_pen_init:
	j	bz_logic_done
bz_G_bits:
	li	$a3, 15
	j	bz_x
bz_B_bits:
	li	$a3, 23
	j	bz_x
bz_x_init:
	li	$a3, 9 #11 + 12
	j 	bz_x
bz_x:		
	beq	$t7, 0, bz_final
	#reading the posX from the memory
	la	$t8, RGB
	lw	$a2, ($t8)
	
	#current power
	move	$a0, $a3
	jal 	pow

	add	$a2, $a2, $v0
	sw	$a2, ($t8)
	
	#-------------
bz_final:
	sub	$a3, $a3, 1
	j bz_logic_done
bz_final_operation:

bz_logic_done:
	move	$ra, $t9
	j logic_done
#---------------bz_logic------------------------------------------------
#---------------zb_logic------------------------------------------------
zb_logic:
	#Saving the return address of previous method.
	#Here we have a jal in jal
	move 	$t9, $ra
	beq	$s6, 0, zb_final_operation
	#save the value of a0 register
	move	$t7, $a0
	#a3 -> current power
	ble	$s6, 9, zb_x
	beq	$s6, 10, zb_x_init
	ble	$s6, 15, zb_y
	beq	$s6, 16, zb_y_init
	j 	zb_logic_done
zb_y_init:
	li	$a3, 5
	j 	zb_y
zb_x_init:
	li	$a3, 9
	j 	zb_x
zb_y:
	beq	$t7, 0, zb_final
	#reading the posX from the memory
	la	$t8, posY
	lw	$a2, ($t8)
	
	#current power
	move	$a0, $a3
	jal 	pow
	add	$a2, $a2, $v0
	sw	$a2, ($t8)
	#-------------
	j	zb_final
zb_x:	
	beq	$t7, 0, zb_final
	#reading the posX from the memory
	la	$t8, posX
	lw	$a2, ($t8)
	
	#current power
	move	$a0, $a3
	jal 	pow

	add	$a2, $a2, $v0
	sw	$a2, ($t8)
	#-------------
zb_final:
	sub	$a3, $a3, 1
	j zb_logic_done
zb_final_operation:

zb_logic_done:
	move	$ra, $t9
	j logic_done
#---------------bb_logic------------------------------------------------
#this is the same code as shown above
bb_logic:
	#Saving the return address of previous method.
	#Here we have a jal in jal
	move 	$t9, $ra
	#save the value of a0 register
	move	$t7, $a0
	beq	$s6, 0, bb_final_operation
	#a3 -> current power
	ble	$s6, 9, bb_x
	beq	$s6, 10, bb_x_init
	j 	bb_logic_done
bb_x_init:
	li	$a3, 9
	j 	bb_x
bb_x:	
	#move	$a0, $s6
	#li	$v0, 1
	#syscall
	
	beq	$t7, 0, bb_final
	#reading the posX from the memory
	la	$t8, move_blocks
	lw	$a2, ($t8)
	
	#current power
	move	$a0, $a3
	jal 	pow

	add	$a2, $a2, $v0
	sw	$a2, ($t8)
	
	#move	$a0, $a2
	#li	$v0, 1
	#yscall
	#-------------
bb_final:
	sub	$a3, $a3, 1
	j bb_logic_done
bb_final_operation:
	jal	debug
	jal	draw
bb_logic_done:
	move	$ra, $t9
	j logic_done
#------------------draw-------------------------------------------------
draw:
	la 	$a0, enter
	li	$v0, 4
	syscall
	# This function draw the file.
	# Breaks $a0, $a1, $a2, $t7, $t8, $t9, $t6, $t5, $t0
	move	$s1, $ra
	
	#pen state
	la	$a0, penState
	lw	$t8, ($a0)
	#x possition	($t8)
	la	$a0, posX
	lw	$t7, ($a0)
	#y possition	($t7)
	la	$a0, posY
	lw	$t6, ($a0)
	#direaction	($t6)
	la	$a0, direction
	lw	$t5, ($a0)
	#movement	($t5)
	la	$a0, move_blocks
	lw	$t4, ($a0)
	#color		($t5)
	la	$a0, RGB
	lw	$t3, ($a0)
	#input check if position is within the border of a file
	#grater then 600x50
	bge	$t7, 600, end
	bge	$t6, 50, end
	#lower than 0x0
	blt	$t7, 0, end
	blt	$t6, 0, end
	#number of block to move cannot be lower than
	blt	$t4, 0, end
	#when pen is raised so we need to skip drowing
	beq	$t8, 1, skip_draw
#--------
#logic
	#clock
	li	$a3, 0
	#moving the color
	move	$a2, $t3
	beq	$t5, 0, draw_up
	beq	$t5, 1, draw_left
	beq	$t5, 2, draw_down
	beq	$t5, 3, draw_right
	j	end_draw
draw_up:
	beq	$a3, $t4, draw_up_finish
	bge	$t6, 50, draw_up_finish
	
	la	$a0, RGB
	lw	$a2, ($a0)
	
	move	$a0, $t7
	move	$a1, $t6
	#we need to keep track of t registers
	move 	$t5, $t0
	move 	$s7, $t1
	#--
	jal 	put_pixel
	#we need to keep track of t registers
	move 	$t5, $s6
	move 	$t1, $s7
	#--
	add	$t6, $t6, 1
	add	$a3, $a3, 1
	j	draw_up
draw_up_finish:
	la	$a0, posY
	sw	$t6, ($a0)
	j	end_draw
draw_down:
	beq	$a3, $t4, draw_down_finish
	ble	$t6, 0, draw_down_finish
	
	la	$a0, RGB
	lw	$a2, ($a0)
	
	move	$a0, $t7
	move	$a1, $t6
	#we need to keep track of t registers
	move 	$t5, $t0
	move 	$s7, $t1
	#--
	jal 	put_pixel
	#we need to keep track of t registers
	move 	$t5, $s6
	move 	$t1, $s7
	#--
	sub	$t6, $t6, 1
	add	$a3, $a3, 1
	j	draw_down
draw_down_finish:
	la	$a0, posY
	sw	$t6, ($a0)
	j	end_draw
draw_left:
	beq	$a3, $t4, draw_left_finish
	ble	$t7, 0, draw_left_finish
	
	la	$a0, RGB
	lw	$a2, ($a0)
	
	move	$a0, $t7
	move	$a1, $t6
	#we need to keep track of t registers
	move 	$t5, $t0
	move 	$s7, $t1
	#--
	jal 	put_pixel
	#we need to keep track of t registers
	move 	$t5, $s6
	move 	$t1, $s7
	#--
	sub	$t7, $t7, 1
	add	$a3, $a3, 1
	j	draw_left
draw_left_finish:
	la	$a0, posX
	sw	$t7, ($a0)
	j	end_draw
draw_right:
	beq	$a3, $t4, draw_right_finish
	bge	$t7, 599, draw_right_finish
	
	la	$a0, RGB
	lw	$a2, ($a0)
	
	move	$a0, $t7
	move	$a1, $t6
	#we need to keep track of t registers
	move 	$t5, $t0
	move 	$s7, $t1
	#--
	jal 	put_pixel
	#we need to keep track of t registers
	move 	$t5, $s6
	move 	$t1, $s7
	#--
	add	$t7, $t7, 1
	add	$a3, $a3, 1
	j	draw_right
draw_right_finish:
	la	$a0, posX
	sw	$t7, ($a0)
	j	end_draw
skip_draw:
	#skiping /\
	beq	$t5, 0, skip_up
	#skiping <
	beq	$t5, 1, skip_left
	#skiping \/
	beq	$t5, 2, skip_down
	#skiping >
	beq	$t5, 3, skip_right
	j	end_draw
skip_up:
#----skip-up-------------------
	add	$t6, $t6, $t4
	blt	$t6, 50, skip_up_done
	li	$t6, 49
skip_up_done:	
	la	$a0, posY
	sw	$t6, ($a0)
	j 	end_draw
#----skip-up-------------------
skip_left:
#----skip-left-----------------
	sub	$t7, $t7, $t4
	bgt	$t7, -1, skip_left_done
	li	$t7, 0
skip_left_done:	
	la	$a0, posX
	sw	$t7, ($a0)
	j 	end_draw
#----skip-left-----------------
skip_down:
#----skip-up-------------------
	sub	$t6, $t6, $t4
	bgt	$t6, -1, skip_down_done
	li	$t6, 0
skip_down_done:	
	la	$a0, posY
	sw	$t6, ($a0)
	j 	end_draw
#----skip-up-------------------
skip_right:
#----skip-right-----------------
	add	$t7, $t7, $t4
	blt	$t7, 600, skip_right_done
	li	$t7, 599
skip_right_done:	
	la	$a0, posX
	sw	$t7, ($a0)
	j 	end_draw
#----skip-right-----------------
end_draw:
	move	$ra, $s1
	jr	$ra
#------------------draw-------------------------------------------------	
#-----------------------------------------------------------------------
save_file:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none

	li $v0, 13
        la $a0, outputfile		#file name 
        li $a1, 1		#flags: 1-write file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
	li $v0, 15
	move $a0, $s1
	la $a1, image
	li $a2, BMP_FILE_SIZE
	syscall
	
	li $v0, 16
	move $a0, $s1
        syscall
        j end
        
close:
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, ($sp)
	#closing a file
	li 	$v0, 16
	syscall
	jr $ra
end:
	#setting exit mode to v0 register
	li 	$v0, 10
	syscall

final_save:
	jal save_file
	j end
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0RGB - pixel color
#breaks:
#	$t0, $t1, $t2. $t3
#return value: none

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#set new color
	sb $a2,($t2)		#store B
	srl $a2,$a2,8
	sb $a2,1($t2)		#store G
	srl $a2,$a2,8
	sb $a2,2($t2)		#store R

	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
# ============================================================================
