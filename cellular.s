########################################################################
#
# Written by <<Shree Nath>>, July 2020.


# Maximum and minimum values for the 3 parameters.

MIN_WORLD_SIZE	=    1
MAX_WORLD_SIZE	=  128
MIN_GENERATIONS	= -256
MAX_GENERATIONS	=  256
MIN_RULE	=    0
MAX_RULE	=  255

# Characters used to print alive/dead cells.

ALIVE_CHAR	= '#'
DEAD_CHAR	= '.'

# Maximum number of bytes needs to store all generations of cells.

MAX_CELLS_BYTES	= (MAX_GENERATIONS + 1) * MAX_WORLD_SIZE

	.data

# `cells' is used to store successive generations.  Each byte will be 1
# if the cell is alive in that generation, and 0 otherwise.

cells:	.space MAX_CELLS_BYTES


# Some strings you'll need to use:

prompt_world_size:	.asciiz "Enter world size: "
error_world_size:	.asciiz "Invalid world size\n"
prompt_rule:		.asciiz "Enter rule: "
error_rule:		.asciiz "Invalid rule\n"
prompt_n_generations:	.asciiz "Enter how many generations: "
error_n_generations:	.asciiz "Invalid number of generations\n"
new_line:   .asciiz "\n"
tab_space: .asciiz "\t"

	.text
# Frame: $ra
# Uses: $a0, $a1, $a2, $a3, $t0, $t1, $t2, $t3, 
# $t4, $s0, $s1, $s2, $s3, $s4, $s5
# Clobbers: $at, $a0, $a1, $a2, $a3 

# Locals:
#       - 'world_size' in $s0
#       - 'rule' in $s1
#       - 'n_generations' in $s2
#       - '&cells' in $s3
#       - 'g' in $s4
#       - 'reverse' in $s5

# Structure:
#       main
#       -> [prologue]
#       -> read world_size
#       -> read rule
#       -> read n_generations
#       -> run_generation
#       -> reverse_condition
#           ->print_generation reversed
#           ->print_generation
#       -> [epilogue]
main:

    sub  $sp, $sp, 4                # move stack pointer down to make room
    sw   $ra, 0($sp)                # save $ra on $stack


	la   $a0, prompt_world_size     # get address of prompt_world_size
    li   $v0, 4       			    # 4 is print string syscall
    syscall

	li $v0, 5           		    # scanf("%d", &world_size);
    syscall
    
    move $s0, $v0                   # $s0 = world_size
	li $t0, MIN_WORLD_SIZE          # $t0 = MIN_WORLD_SIZE
	li $t1, MAX_WORLD_SIZE          # $t1 = MAX_WORLD_SIZE
	blt		$v0, $t0, if0	        # if $t0 < $t1 then if0
	ble		$v0, $t1, endif0	    # if $t0 <= $t1 then endif0
	
if0:

	la   $a0, error_world_size      # get address of error_world_size
    li   $v0, 4       			    # 4 is print string syscall
    syscall
    
    jr   $ra                        
    
endif0:
	la   $a0, prompt_rule           # get address of prompt_rule
    li   $v0, 4       			    # 4 is print string syscall
    syscall
    
	li $v0, 5           		    # scanf("%d", &rule);
    syscall
    
    move $s1, $v0                   # $s1 = rule
    li $t0, MIN_RULE                # $t0 = MIN_RULE
    li $t1, MAX_RULE                # $t1 = MAX_RULE
    blt		$v0, $t0, if1	        # if $t0 < $t1 then if1
	ble		$v0, $t1, endif1	    # if $t0 <= $t1 then endif1
	
if1:
    la   $a0, error_rule            # get address of error_rule
    li   $v0, 4       			    # 4 is print string syscall
    syscall
    
    jr   $ra                        

endif1:
	la   $a0, prompt_n_generations  # get address of prompt_n_generations
    li   $v0, 4       			    # 4 is print string syscall
    syscall
    
	li $v0, 5           		    # scanf("%d", &n_generations);
    syscall
    
    move $s2, $v0                   # $s2 = n_generations
    li $t0, MIN_GENERATIONS         # t0 = MIN_GENERATIONS
    li $t1, MAX_GENERATIONS         # t1 = MAX_GENERATIONS
    blt		$v0, $t0, if2	        # if $t0 < $t1 then if2
	ble		$v0, $t1, endif2	    # if $t0 <= $t1 then endif2
	
if2:
    la   $a0, error_n_generations   # get address of error_n_generations
    li   $v0, 4       			    # 4 is print string syscall
    syscall
    
    jr   $ra   
                         
endif2:
    la $a0, new_line                # putchar('\n');
    li $v0, 4
    syscall 

    li $s5, 0                       # int reverse = 0, stored in $s5
if3:
    bge $s2, $0, endif3             # goto endif3, if n_generations >= 0 
    li $s5, 1                       # reverse = 1
    sub $s2, $0, $s2                # n_generations = -n_generations
    
endif3:
    li $t1, 1                       # set the middle cell of the first gen
    la $s3, cells                   # load the base address of cells
    li $t2, 2                       # calculate the offset for the middle cell
    div $s0, $t2                    # world_size/2 stored in lo register
    mflo $t3                        # $t3 = lo register
     
    add $t4, $s3, $t3               # calculate &cells[0][world_size / 2]
    sb $t1, 0($t4)                  # $t1 contains 1 already,so we can place it in the cell

    li $s4, 1                       # $s4 = g = 1
forloop0:
    bgt $s4, $s2, endforloop0       # loop until g > n_generations
    move $a1, $s0                   # $a1 = world_size
    move $a2, $s4                   # $a2 = g
    move $a3, $s1                   # $a3 = rule
    jal run_generation              # uses arguments world_size, g, rule
    
    add $s4, $s4, 1                 # g++
    b forloop0
endforloop0:

if4:
    beq $s5, $0, elseif4            # if(reverse)

    move $s4, $s2                   # $s4 = g = n_generations
forloop1:
    blt $s4, $0, endforloop1        # loop until g < 0
    move $a1, $s0                   # $a1 = world_size
    move $a2, $s4                   # $a2 = g
    jal print_generation            # uses arguments world_size, g
    
    sub $s4, $s4, 1                 # g--
    b forloop1              
endforloop1:
    b endif4                        # skip the else case, because we followed the if case


elseif4:

    move $s4, $0                    # $s4 = g = 0
forloop2:
    bgt $s4, $s2, endforloop2       # loop until g > n_generations
    move $a1, $s0                   # $a1 = world_size
    move $a2, $s4                   # $a2 = g
    jal print_generation            # uses arguments world_size, g
    
    add $s4, $s4, 1                 # g++
    b forloop2
endforloop2:

endif4:


    lw   $ra, 0($sp)                # recover $ra from $stack
    addi  $sp, $sp, 4               # move stack pointer back up to what it was when main called
    
    li  $v0, 0
    jr	$ra



run_generation:
    move $t0, $0                    # $t0 = x, the iterator for run_generation_forloop0
    
run_generation_forloop0:
    bge $t0, $a1, endrun_generation_forloop0       
    #loop until x >= world_size

    li $t1, 0                       # int left = 0
    li $t2, 1                       # $t2 = 1
    sub $t3, $a2, $t2               # $t3 = g - 1
    sub $t4, $t0, $t2               # $t4 = x - 1
    mul $t5,$a1, $t3                # $t5 = world_size * (g - 1)
    la $t6, cells                   # $t6 = base address
    add $t6, $t6, $t5               # $t6 = base + world_size*(g-1)
    add $t6, $t6, $t4               # $t6 = base + world_size*(g-1) + (x-1)
    
run_generation_if_0:
    ble $t0, $0, endrun_generation_if_0
    
    lb $t1, ($t6)		            # left = cells[which_generation - 1][x - 1]   
endrun_generation_if_0:

    #add 1 to address
    lb $t8, 1($t6)                  # int centre = cells[which_generation - 1][x]
    li $t9, 0                       # int right = 0
run_generation_if_1:
    sub $t7, $a1, 1                 # $t7 = world_size - 1
    bge $t0, $t7, endrun_generation_if_1    #skip if x >= world_size - 1
    lb $t9, 2($t6)                  # right = cells[which_generation - 1][x + 1]


endrun_generation_if_1:
    sll $t1, $t1, 2                 # $t1 = left << 2
    sll $t8, $t8, 1                 # $t8 = centre << 1
    sll $t9, $t9, 0                 # $t9 = right << 0
    or $t3, $t1, $t8
    or $t3, $t3, $t9                # $t3 = state = left << 2 | centre << 1 | right << 0
    sllv $t3, $t2, $t3              # $t3 = bit = 1 << state
    and $t4, $a3, $t3               # $t4 = set = rule & bit

run_generation_if_2:
    beq $t4, $0, run_generation_ifelse_2
    mul $t5,$a1, $a2                # $t5 = world_size * g
    la $t6, cells                   # $t6 = base address
    add $t6, $t6, $t5               # $t6 = base + world_size*g
    add $t6, $t6, $t0               # $t6 = base + world_size*g + x
    sb $t2, ($t6)		            # cells[which_generation][x] = 1

    b endrun_generation_if_2
run_generation_ifelse_2:
    mul $t5,$a1, $a2                # $t5 = world_size * g
    la $t6, cells                   # $t6 = base address
    add $t6, $t6, $t5               # $t6 = base + world_size*g
    add $t6, $t6, $t0               # $t6 = base + world_size*g + x
    sb $0, ($t6)		            # cells[which_generation][x] = 0
endrun_generation_if_2:


    addi $t0, $t0, 1                # x++
    b run_generation_forloop0
endrun_generation_forloop0:

    jr	$ra



print_generation:
    move $a0, $a2                   # print which_generation
    li $v0, 1
    syscall

    la $a0, tab_space               # print a tab space
    li $v0, 4
    syscall

    move $t0, $0                    # $t0 = int x 
print_generation_forloop0:
    
    beq $t0, $a1, endprint_generation_forloop0  
    #branch if x >= world_size

print_generation_forloop_if0:
    la $t1, cells                   # $t1 = base address
    mul $t2, $a1, $a2               # $t2 = world_size * g
    add $t3, $t1, $t2               # $t3 = base address + world_size * g
    add $t4, $t3, $t0               # $t4 = base address + world_size * g + x
    lb $t5, ($t4)                   # $t5 = byte value at ($t4)
    beq $t5, $0, print_generation_forloop_ifelse0

    li $a0, ALIVE_CHAR              # print ALIVE_CHAR
    li $v0, 11
    syscall

    b endprint_generation_forloop_if0    
    # skip the else case

print_generation_forloop_ifelse0:
    li $a0, DEAD_CHAR               # print DEAD_CHAR
    li $v0, 11
    syscall

endprint_generation_forloop_if0:

    add $t0, $t0, 1                 # x++
    b print_generation_forloop0 

endprint_generation_forloop0:
    la $a0, new_line                # print a new line
    li $v0, 4
    syscall

    jr	$ra

