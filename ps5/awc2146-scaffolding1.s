count_char:
	li $v0, 0 # initialize counter to 0

count_char_top:
        lbu $t0, 0($a1) # $t0 = char from string at $a0
        beqz $t0, count_char_return # if char == 0, then EOF
        bne $t0, $a0, count_char_adv_ptr # do not increment counter if not equivalent
        addi $v0, $v0, 1 # increment counter bc equivalent
count_char_adv_ptr:
        addi $a1, $a1, 1 # advance pointer
        b count_char_top # restart loop

count_char_return:
	jr $ra

######################################################## DO NOT REMOVE THIS SEPARATOR

minmax_chars:
	li $v0, 0
	li $v1, 0
       
        lbu $v0, 0($a0)   # first char is the starting min
        lbu $v1, 0($a0)   # first char is the starting max

minmax_chars_top:
        lbu $t0, 0($a0) # $t0 = char from string at $a0
        beqz $t0, minmax_chars_return # if char == 0, then EOF

        bgt $t0, $v1, minmax_chars_maxreplace # branch if curr char > max
        blt $t0, $v0, minmax_chars_minreplace # branch if curr char < min 

minmax_chars_bot:
        addi $a0, $a0, 1   # increment ptr to string
        b minmax_chars_top # restart loop

minmax_chars_maxreplace:
        move $v1, $t0        # char becomes new max
        b minmax_chars_bot   # return to primary body of func

minmax_chars_minreplace:
        move $v0, $t0        # char becomes new min
        b minmax_chars_bot   # return to primary body of func

minmax_chars_return:
	jr $ra
######################################################## DO NOT REMOVE THIS SEPARATOR


make_leaf:
	
        sw $a0 0($a2) # take char in $a0 and stick into $a2
        sw $a1 4($a2) # take weight in $a1 and stick it 4B offset from $a2
        sw $zero 8($a2) # no parent, 8B offset from $a2
        sw $zero 12($a2) # left
        sw $zero 16($a2) # right
        
        jr $ra

######################################################## DO NOT REMOVE THIS SEPARATOR

merge_roots:
	li $v0, 0

        sw $a0 12($a2) # left child connected
        sw $a1 16($a2) # right child connected
        sw $zero 0($a2) # parent char zeroed out

        lw $t0, 4($a0) # $t0 = left child weight
        lw $t1, 4($a1) # $t1 = right child weight
        add $t2, $t0, $t1 # add weights together for parent
        sw $t2, 4($a2)

        sw $zero 8($a2) # parent->has_parent = 0
        li $t3, 1 # prepare a 1 for use
        sw $t3, 8($a0) # left->has_parent = 1
        sw $t3, 8($a1) # right->has_parent = 1

	jr $ra

######################################################## DO NOT REMOVE THIS SEPARATOR

count_roots:
	li $v0, 0
	move $t0, $a0 # Tracks current address
count_roots_top:
        bge $t0, $a1, count_roots_return # if ptr >= end ptr, return
	lw $t1, 8($t0) # load has_parent of node
        bne $t1, $zero, count_roots_next # if has_parent = 1, skip to next
        addi $v0, $v0, 1 # increment $v0 if $t0 is 0
count_roots_next:
        addi $t0, $t0, 20 # advance by 20 to look at next node
        b count_roots_top
count_roots_return:
	jr $ra

######################################################## DO NOT REMOVE THIS SEPARATOR

lightest_roots:
	li $t6, 0 # Initialize state variable for when first weight is found (init 1 flag)
	li $t7, 0 # Initialize state variable for when second weight is found (init 2 flag)
	move $t0, $a0 # $t0 : Current address, initialized to $a0
lightest_roots_top:
        bge $t0, $a1, lightest_roots_return # if ptr > end ptr, return
	lw $t1, 8($t0) # $t1 : Contains either has_parent or a weight, assigned has_parent here
        bne $t1, $zero, lightest_roots_next # if has_parent = 1, skip to next
	lw $t1, 4($t0) # load weight of node
	beqz $t7, lightest_roots_init # If second initial weight hasn't been found (i.e. $t7 = 0), initialize
	bgt $t1, $t2, lightest_roots_not_lightest # if current weight > lightest, check if it's possibly second lightest
	move $t3, $t2 # Lightest becomes second lightest
	move $v1, $v0 # Lightest address becomes second lightest address
	move $t2, $t1 # Saves new lightest
	move $v0, $t0 # Saves new lightest address
	b lightest_roots_next
lightest_roots_not_lightest:
	bge $t1, $t3, lightest_roots_next
	move $t3, $t1 # Saves new second lightest
	move $v1, $t0 # Saves new second lightest address
	b lightest_roots_next
lightest_roots_init:
	bgtz $t6, lightest_roots_init_stage_two # If first initial weight has been found (i.e. $t6 = 1), initialize stage two
	addi $t6, $t6, 1 # Set init 1 flag
	move $t2, $t1 # Saves new lightest
	move $v0, $t0 # Saves new lightest address
	b lightest_roots_next
lightest_roots_init_stage_two:
	addi $t7, $t7, 1 # Set init 2 flag
	move $t3, $t1 # Saves new second lightest
	move $v1, $t0 # Saves new second lightest address
	ble $t2, $t3, lightest_roots_next # If $t2 <= $t3, no reordering necessary; go next
	move $t5, $t2 # Swap $t2 and $t3
	move $t2, $t3
	move $t3, $t5
	move $t5, $v0 # Swap $v0 and $v1
	move $v0, $v1
	move $v1, $t5
	b lightest_roots_next
lightest_roots_next:
        addi $t0, $t0, 20 # advance by 20 to look at next node
        b lightest_roots_top
lightest_roots_return:
	jr $ra

######################################################## DO NOT REMOVE THIS SEPARATOR

build_tree:
	li $v0, 0
	sw $ra, 20($sp) # Save return address
	sw $a1, 0($sp) # Save original tree address
	sw $a1, 4($sp) # Save current tree address
	sw $a0, 8($sp) # Save string address
	jal minmax_chars # $a0 already contains string address
	move $t1, $v0
	move $t2, $v1
build_tree_make_leaves_top:
	bgt $t1, $t2, build_tree_merge_roots # If we've gone through all chars (inclusive), proceed
	sw $t1, 12($sp) # Save counter
	sw $t2, 16($sp) # Save predicate value
	move $a0, $t1 # Search for current char
	lw $t7, 8($sp) # Reload string address
	move $a1, $t7
	jal count_char # Search within provided string
	beqz $v0, build_tree_make_leaves_next # If none of current char exists, skip to next char
	move $a1, $v0 # Set character weight
	lw $a2, 4($sp) # Reload current address
	jal make_leaf
	lw $t0, 4($sp) # Reload current address
	addi $t0, $t0, 20 # Point to next address for a leaf
	sw $t0, 4($sp) # Save current address
build_tree_make_leaves_next:
	lw $t1, 12($sp) # Restore counter
	lw $t2, 16($sp) # Restore predicate value
	addi $t1, $t1, 1
	j build_tree_make_leaves_top
build_tree_merge_roots:
	lw $t0, 4($sp)
	addi $t0, $t0, -20
	sw $t0, 4($sp)
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	jal count_roots
	move $t0, $v0 # Number of roots
	#addi $t0, $t0, -1 # Since a tree will ultimately have one root, we will merge roots until n-1 == 0
build_tree_merge_roots_top:
	beqz $t0, build_tree_return
	sw $t0, 12($sp)
	lw $a0, 0($sp) # Reload start and end of tree
	lw $a1, 4($sp)
	jal lightest_roots
	move $a0, $v0
	move $a1, $v1
	lw $a2, 4($sp)
	addi $a2, $a2, 20
	sw $a2, 4($sp)
	jal merge_roots
	lw $t0, 12($sp)
	addi $t0, $t0, -1
	b build_tree_merge_roots_top	
build_tree_return:
	lw $v0, 4($sp)
	lw $ra, 20($sp)
	jr $ra

	#la $a0, debug_prefix_msg
	#jal print_string
	#move $a0, $v0
	#jal print_int
######################################################## DO NOT REMOVE THIS SEPARATOR

main:
	# save regs
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $a0, count_char_test1_in
	la $a1, count_char_test1_out
	jal count_char_tester
 
	la $a0, count_char_test2_in
	la $a1, count_char_test2_out
	jal count_char_tester
 
	la $a0, minmax_chars_test1_in
	la $a1, minmax_chars_test1_out 
	jal minmax_chars_tester
 
	la $a0, minmax_chars_test2_in
	la $a1, minmax_chars_test2_out
	jal minmax_chars_tester
	
	la $a0, make_leaf_test1_in
	la $a1, make_leaf_test1_out
	jal make_leaf_tester
 
	la $a0, make_leaf_test2_in
	la $a1, make_leaf_test2_out
	jal make_leaf_tester
	
	la $a0, count_roots_test1_in
	la $a1, count_roots_test1_out
	jal count_roots_tester
 
	la $a0, count_roots_test2_in
	la $a1, count_roots_test2_out
	jal count_roots_tester
	jal print_newline
 
	la $a0, merge_roots_test1_in
	la $a1, merge_roots_test1_out	
	jal merge_roots_tester
 
	la $a0, merge_roots_test2_in
	la $a1, merge_roots_test2_out	
	jal merge_roots_tester

	la $a0, lightest_roots_test1_in
	la $a1, lightest_roots_test1_out	
 	jal lightest_roots_tester

	la $a0, lightest_roots_test2_in
	la $a1, lightest_roots_test2_out	
 	jal lightest_roots_tester

	la $a0, build_tree_test1_in
	la $a1, build_tree_test1_out
	jal build_tree_tester

	jal print_newline
	jal print_newline

	# one last test, build the abc_string tree again and decompress a tiny string
	# should see 'cab' print to screen
	la $a0, abc_string
	la $a1, free_space
	jal build_tree
	move $a0, $v0
	la $a1, cab_message
	li $a2, 6
	jal decompress
	jal print_newline
	
	# now, build the final tree, and use to decompress message
	la $a0, english_frequency_string 
	la $a1, free_space
	jal build_tree
 	move $a0, $v0
	la $a1, final_message
	li $a2, 70
	jal decompress
	
	# restore regs
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# and return
	jr $ra

count_char_tester:
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case and inputs
	la $a0, count_char_tester_msg
	jal print_string
	lw $a0, 0($s0)
	jal print_char
	jal print_comma
	lw $a0, 4($s0)
	jal print_string
	jal print_newline

	# print expected output
	la $a0, tester_expecting_msg
	jal print_string
	lw $a0, 0($s1)
	jal print_int
	jal print_newline
  
	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)
	jal count_char
 
	# check result against expected
	lw $t0, 0($s1)
	beq $v0, $t0, count_char_tester_pass

	# error, save result
	move $s0, $v0
	
	# print error message and result
	la $a0, tester_error_msg
	jal print_string	
	move $a0, $s0
	jal print_int
	jal print_newline
 
	# exit
	li $v0, 10 
	syscall

count_char_tester_pass:
	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	

minmax_chars_tester:	
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case and inputs
	la $a0, minmax_chars_tester_msg
	jal print_string
	lw $a0, 0($s0)
	jal print_string
	jal print_newline

	# print expected result
	la $a0, tester_expecting_msg
	jal print_string
	lw $a0, 0($s1)
	jal print_char
	jal print_comma
	lw $a0, 4($s1)
	jal print_char	
	jal print_newline

	# run test!
	lw $a0, 0($s0)
	jal minmax_chars

	# check result
	lw $t0, 0($s1)
	bne $v0, $t0, minmax_chars_tester_fail
	lw $t0, 4($s1)
	bne $v1, $t0, minmax_chars_tester_fail

	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

minmax_chars_tester_fail:
	# error, save result
	move $s0, $v0
	move $s1, $v1

	# print error message and result
	la $a0, tester_error_msg
	jal print_string
	move $a0, $s0
	jal print_char
	jal print_comma
	move $a0, $s1
	jal print_char
	jal print_newline

	# exit
	li $v0, 10 
	syscall

make_leaf_tester:
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	# save args
	move $s0, $a0
	move $s1, $a1
	
	# print test case and inputs
	la $a0, make_leaf_tester_msg
	jal print_string
	lw $a0, 0($s0)
	jal print_char
	jal print_comma
	lw $a0, 4($s0)
	jal print_int
	jal print_comma
	la $a0, free_space_msg
	jal print_string
	jal print_newline

	# print expected result	
	la $a0, tester_expecting_msg
	jal print_string
	move $a0, $s1
	jal print_tree

	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)
	la $a2, free_space
	jal make_leaf
	
	# check result
	la $a0, free_space
	move $a1, $s1
	jal tree_match
	bnez $v0, make_leaf_tester_pass
 
	# print error
	la $a0, tester_error_msg
	jal print_string
	la $a0, free_space
	jal print_tree
	jal print_newline
 
	# exit
	li $v0, 10 
	syscall

make_leaf_tester_pass:
	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

merge_roots_tester:	
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	# save args
	move $s0, $a0
	move $s1, $a1
	
	# print test case and inputs
	la $a0, merge_roots_tester_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s0)
	jal print_tree
	lw $a0, 4($s0)
	jal print_tree
	la $a0, free_space_msg
	jal print_string
	jal print_newline

	# print expected result	
	la $a0, tester_expecting_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s1)
	jal print_tree

	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)
	la $a2, free_space
	jal merge_roots
 	
 	# check result
 	la $a0, free_space
 	lw $a1, 0($s1)
 	jal tree_match
 	bnez $v0, merge_roots_tester_pass

	# print error
	la $a0, tester_error_msg
	jal print_string
	la $a0, free_space
	jal print_tree
	jal print_newline
 
	# exit
	li $v0, 10 
	syscall

merge_roots_tester_pass:
	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

count_roots_tester:
	# save regs
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)

	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case and inputs
	la $a0, count_roots_tester_msg
	jal print_string
	jal print_newline

	# s2: pointer to current node in array
	lw $s2, 0($s0)
count_roots_tester_loop_top:
	lw $t0, 4($s0)
	beq $s2, $t0, count_roots_tester_loop_exit
	# print node
	move $a0, $s2
	jal print_tree
	addi $s2, $s2, 20
	b count_roots_tester_loop_top

count_roots_tester_loop_exit:	
	# print expected output
	la $a0, tester_expecting_msg
	jal print_string
	lw $a0, 0($s1)
	jal print_int
	jal print_newline
  
	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)	
	jal count_roots
 
	# check result against expected
	lw $t0, 0($s1)
	beq $v0, $t0, count_roots_tester_pass
 
	# error, save result
	move $s0, $v0
	
	# print error message and result
	la $a0, tester_error_msg
	jal print_string	
	move $a0, $s0
	jal print_int
	jal print_newline
 
	# exit
	li $v0, 10 
	syscall
	
count_roots_tester_pass:
	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 16($sp)
	addi $sp, $sp, 16
	jr $ra
lightest_roots_tester:	
	# save regs
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)

	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case and inputs
	la $a0, lightest_roots_tester_msg
	jal print_string
	jal print_newline

	# s2: pointer to current node in array
	lw $s2, 0($s0)
lightest_roots_tester_loop_top:
	lw $t0, 4($s0)
	beq $s2, $t0, lightest_roots_tester_loop_exit
	# print node
	move $a0, $s2
	jal print_tree
	addi $s2, $s2, 20
	b lightest_roots_tester_loop_top

lightest_roots_tester_loop_exit:	
	# print expected result
	la $a0, tester_expecting_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s1)
	jal print_tree
	lw $a0, 4($s1)
	jal print_tree	

	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)
	jal lightest_roots

	# save returned pointers 
	move $s0, $v0
	move $s2, $v1
	
	# check if lightest matches expecting
 	move $a0, $s0
 	lw $a1, 0($s1)
 	jal tree_match
 	beqz $v0, lightest_roots_tester_fail	

	# lightest matches, check second lightest
	move $a0, $s2
	lw $a1, 4($s1)
	jal tree_match
	beqz $v0, lightest_roots_tester_fail	

	# passed, so print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra
	
lightest_roots_tester_fail:
 
 	# print error message and result
 	la $a0, tester_error_msg
 	jal print_string
	jal print_newline
 	move $a0, $s0
 	jal print_tree
 	move $a0, $s2
 	jal print_tree

	# exit
 	li $v0, 10 
 	syscall

build_tree_tester:	
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case
	la $a0, build_tree_tester_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s0)
	jal print_string
	jal print_newline
	la $a0, free_space_msg
	jal print_string
	jal print_newline

	# print expected output
	la $a0, tester_expecting_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s1)
	jal print_tree
 
	# run test!
	lw $a0, 0($s0)
	la $a1, free_space
	jal build_tree
	move $s0, $v0
	
  	# check result
  	move $a0, $s0
  	lw $a1, 0($s1)
  	jal tree_match 
  	bnez $v0, build_tree_tester_pass
  
  	# print error
  	la $a0, tester_error_msg
  	jal print_string
  	jal print_newline
  	move $a0, $s0
  	jal print_tree
  
  	# exit
  	li $v0, 10 
  	syscall
  	
build_tree_tester_pass:	
  	# print pass message
  	la $a0, tester_pass_msg
  	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	# a0 root
	# a1 other root	
	# return 0 if not matching, 1 otherwise
tree_match:	
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	# save arguments
	move $s0, $a0
	move $s1, $a1

	# if both pointers null, return true
	or $t0, $s0, $s1
	beqz $t0, tree_match_exit_true

	# know one or the other is non-null, so if either one is null, have mismatch
	beqz $s0, tree_match_exit_false
	beqz $s1, tree_match_exit_false

	# now know both are non-null, so going to recurse

	# check if left children match
	lw $a0, 12($s0)
	lw $a1, 12($s1)
	jal tree_match
	beqz $v0, tree_match_exit_false # if false, return false from whole thing

	# check if right children match
	lw $a0, 16($s0)
	lw $a1, 16($s1)
	jal tree_match
	beqz $v0, tree_match_exit_false # if false, return false from whole thing
	
	# children match, now compare contents of the node
	lw $t0, 0($s0)
	lw $t1, 0($s1)
	bne $t0, $t1, tree_match_exit_false
	lw $t0, 4($s0)
	lw $t1, 4($s1)
	bne $t0, $t1, tree_match_exit_false
	lw $t0, 8($s0)
	lw $t1, 8($s1)
	bne $t0, $t1, tree_match_exit_false

tree_match_exit_true:
	li $v0, 1
	b tree_match_exit	

tree_match_exit_false:
	li $v0, 0
	
tree_match_exit:	
	# restore regs
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra	


	# a0: tree root
	# a1: pointer to compressed text
	# a2: num bits compressed
decompress:	
	addi $sp, $sp, -28
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	
	# save args
	move $s0, $a0 # s0: root of tree
	move $s1, $a1 # s1: curr spot in compressed words
	move $s2, $a2 # s2: num bits to decompress
	              # s4: going to hold word of bits
	move $s5, $a0 # s5: curr position in tree

	# load first word of bits
	lw $s4, 0($s1)
	addi $s1, $s1, 4
	
decompress_top:
	# if processed all bits, done
	beqz $s2, decompress_exit

	# decrement bits to decompress
	addi $s2, $s2, -1
	
	# t0: bitmask for this bit
	li $t0, 1
	sllv $t0, $t0, $s2

	# t1: extracted bit 
	and $t1, $s4, $t0
	
	# if that was last bit in word, need to load new word
	li $t2, 1
	bne $t2, $t0, decompress_use_extracted_bit

	# load new word
	lw $s4, 0($s1)
	addi $s1, $s1, 4

decompress_use_extracted_bit:	
	# descend left or right
	beqz $t1, decompress_descend_left

	# descend right
	lw $s5, 16($s5)
	b decompress_leaf_check
	
decompress_descend_left:	
	lw $s5, 12($s5)

decompress_leaf_check:
	# if child pointer, not at leaf
	lw $t0, 12($s5)
	bnez $t0, decompress_done_with_bit

	# else at leaf, print char and reset to root
	lw $a0, 0($s5)
	jal print_char
	move $s5, $s0
	
decompress_done_with_bit:
#	jal print_newline
	b decompress_top

decompress_exit:
	jal print_newline
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)	
	lw $s5, 24($sp)
	addi $sp, $sp, 28
	jr $ra

print_tree:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $a1, 0
	jal __print_tree
	lw $ra, 0($sp)
	addi $sp, $sp, 4
        jr $ra
	
	
	# a0 root
	# a1 depth
__print_tree:
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)	

	# save arguments
	move $s0, $a0
	move $s1, $a1

	# if has right child, recurse
	lw $a0, 16($s0)
	beqz $a0, __print_tree_node
	addi $a1, $s1, 2
	jal __print_tree
	
	# print this node info
__print_tree_node:
	move $a0, $s1
	jal print_spaces
	li $a0, '*'
	jal print_char
	jal print_space
	jal print_lbracket
	lw $a0, 0($s0)
	jal print_char
	jal print_comma
	lw $a0, 4($s0)
	jal print_int
	jal print_comma
	lw $a0, 8($s0)
	jal print_int
	jal print_rbracket	
 	jal print_newline

	# if has left child, recurse
	lw $a0, 12($s0)
	beqz $a0, __print_tree_exit
	addi $a1, $s1, 2
	jal __print_tree

__print_tree_exit:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)		
	addi $sp, $sp, 12
	jr $ra

print_int:
	li $v0, 1
	syscall
	jr $ra

print_char:
	li $v0, 11
	syscall
	jr $ra
	
print_newline:
 	li $v0, 11
 	li $a0, '\n'
 	syscall
	jr $ra

print_plus:
 	li $v0, 11
 	li $a0, '+'
 	syscall
	jr $ra

print_colon:
 	li $v0, 11
 	li $a0, ':'
 	syscall
	jr $ra
	
print_equals:
 	li $v0, 11
 	li $a0, '='
 	syscall
	jr $ra

print_comma:
 	li $v0, 11
 	li $a0, ','
 	syscall
 	li $v0, 11
 	li $a0, ' '
 	syscall
	jr $ra

print_lbracket:
 	li $v0, 11
 	li $a0, '['
 	syscall
	jr $ra

print_rbracket:
 	li $v0, 11
 	li $a0, ']'
 	syscall
	jr $ra
	
print_dash:
 	li $v0, 11
 	li $a0, '-'
 	syscall
	jr $ra
	
print_space:
 	li $v0, 11
 	li $a0, ' '
 	syscall
	jr $ra

print_spaces:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	move $s0, $a0
print_spaces_top:
	beqz $s0, print_spaces_exit
	jal print_space
	addi $s0, $s0, -1
	b print_spaces_top
print_spaces_exit:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)	
	addi $sp, $sp, 8
	jr $ra
	
print_string:
	li $v0, 4
	syscall
	jr $ra

print_hexword:
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	# s0: hexword
	move $s0, $a0
	# s1: nibble mask
	li $s1, 0xf0000000

	# print 0
	li $a0, 0
	li $v0, 1
	syscall
 
	# print x
	li $a0, 'x'
	li $v0, 11
	syscall

	# print nibble
	and $a0, $s0, $s1
	srl $a0, $a0, 28
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 24
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 20
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 16
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 12
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 8
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 4
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 0
	jal print_hexchar
	
	# restore regs
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12

 	jr $ra

print_hexchar:
	la $t0, hexchars
	add $t0, $t0, $a0
	lbu $a0, 0($t0)
	li $v0, 11
	syscall
	jr $ra
	
.data

hexchars:			.asciiz "0123456789abcdef"
tester_on_msg:			.asciiz "On: "
tester_expecting_msg:		.asciiz "Expecting: "
tester_pass_msg:		.asciiz "PASS!"
tester_error_msg:		.asciiz "ERROR! Got: "
count_char_tester_msg:		.asciiz "\n\nTesting count_char()\nOn: "
minmax_chars_tester_msg:	.asciiz "\n\nTesting minmax_chars()\nOn: "
count_roots_tester_msg:		.asciiz "\n\nTesting count_roots()\nOn: "
merge_roots_tester_msg:		.asciiz "\n\nTesting merge_roots()\nOn: "
make_leaf_tester_msg:		.asciiz "\n\nTesting make_leaf()\nOn: "
lightest_roots_tester_msg:	.asciiz "\n\nTesting lightest_roots()\nOn: "
build_tree_tester_msg:		.asciiz "\n\nTesting build_tree()\nOn: "
free_space_msg:			.asciiz "<pointer to free space>"
				 
abc_string:			.asciiz "aaaaabbbbccd"
some_good_string:		.asciiz "There is some good in this world, and it's worth fighting for."

array_of_nodes1_begin:	
array_of_nodes1_first:
	.word 'a', 120, 0, 0, 0
	.word 'b', 220, 1, 0, 0
array_of_nodes1_second:
	.word 'y', 320, 0, 0, 0
	.word 'c', 420, 1, 0, 0
	.word 'x', 520, 0, 0, 0
array_of_nodes1_end:	

array_of_nodes2_begin:	
	.word 'm', 20, 1, 0, 0
	.word '0', 20, 0, 0, 0
	.word ',', 20, 1, 0, 0
	.word '-', 20, 0, 0, 0
array_of_nodes2_end:	

array_of_nodes3_begin:
	.word 'm', 45, 1, 0, 0
	.word 'p', 93, 0, 0, 0
array_of_nodes3_second:
	.word 'x', 23, 0, 0, 0
	.word 'q', 25, 1, 0, 0
array_of_nodes3_first:	
	.word 'y', 18, 0, 0, 0
array_of_nodes3_end:	
	
count_char_test1_in:	.word 'a', abc_string
count_char_test1_out:	.word 5
count_char_test2_in:	.word 'i', some_good_string
count_char_test2_out:	.word 6

minmax_chars_test1_in:	.word abc_string
minmax_chars_test1_out:	.word 'a', 'd'

minmax_chars_test2_in:	.word some_good_string
minmax_chars_test2_out:	.word ' ', 'w'
	
make_leaf_test1_in:	.word 'b', 200, 0
make_leaf_test1_out:	.word 'b', 200, 0, 0, 0

make_leaf_test2_in:	.word 'x', 125, 0
make_leaf_test2_out:	.word 'x', 125, 0, 0, 0

count_roots_test1_in: 	.word array_of_nodes1_begin, array_of_nodes1_end
count_roots_test1_out:	.word 3

count_roots_test2_in: 	.word array_of_nodes2_begin, array_of_nodes2_end
count_roots_test2_out:	.word 2

lightest_roots_test1_in:	.word array_of_nodes1_begin, array_of_nodes1_end
lightest_roots_test1_out:	.word array_of_nodes1_first, array_of_nodes1_second

lightest_roots_test2_in:	.word array_of_nodes3_begin, array_of_nodes3_end
lightest_roots_test2_out:	.word array_of_nodes3_first, array_of_nodes3_second
	
test_node1:	.word 'b', 200, 0, 0, 0
test_node2:	.word 'c', 300, 0, 0, 0	

test_tree1:		.word 0, 500, 0, test_tree1_left, test_tree1_right
test_tree1_left:	.word 'b', 200, 1, 0, 0
test_tree1_right:	.word 'c', 300, 1, 0, 0	

merge_roots_test1_in:	.word test_node1, test_node2
merge_roots_test1_out:	.word test_tree1

	

abc_string_subtree_5: .word 'a', 5, 1, 0, 0
abc_string_subtree_4: .word 'b', 4, 1, 0, 0
abc_string_subtree_2: .word 'c', 2, 1, 0, 0
abc_string_subtree_1: .word 'd', 1, 1, 0, 0
abc_string_subtree_3: .word 0, 3, 1, abc_string_subtree_1, abc_string_subtree_2
abc_string_subtree_7: .word 0, 7, 1, abc_string_subtree_3, abc_string_subtree_4

abc_string_tree_5: .word 'a', 5, 1, 0, 0
abc_string_tree_4: .word 'b', 4, 1, 0, 0
abc_string_tree_2: .word 'c', 2, 1, 0, 0
abc_string_tree_1: .word 'd', 1, 1, 0, 0
abc_string_tree_3: .word 0, 3, 1, abc_string_tree_1, abc_string_tree_2
abc_string_tree_7: .word 0, 7, 1, abc_string_tree_3, abc_string_tree_4
abc_string_tree_12: .word 0, 12, 0, abc_string_tree_5, abc_string_tree_7

merge_roots_test2_in:	.word abc_string_subtree_5, abc_string_subtree_7
merge_roots_test2_out:	.word abc_string_tree_12
	
build_tree_test1_in:	.word abc_string
build_tree_test1_out:	.word abc_string_tree_12

cab_message:	.word 0x0000002b

final_message:	.word 0x0000003f, 0x725e14d8, 0x5e63b1da
	
free_space: .space 20000
	
english_frequency_string:	.asciiz "LOOCAIESPNNOCIDTASAPGISAATLBYUCICFODPADSIINLIARVWOHHPOCEYLSLASIMEIIRBNDPAEHOAKEELUZUDTHERTAERGEAANWYLAGRSOEMLOEUTDETEULPPEEEOOCTIEIVNOTURINTRNGHRNAPTRTTMRIBHFTOMNCMPIEIFOCBFOROTHAYIDOGEGTAHEEIETLODKNSEISSYMRYOOUMOGPYLHECEMEAYETNISTFCOYNRINEIHHIRDEEULASSRHPECSSESYEADDPEDYFSNBOLILORLNJNIILOETLSWTOIINRSCABAAAECWNTYPTAEYKERIMFEANTURTHETNOAEKPRRGHSUKDNYHEHNCLTPEIBPNYMNMHEGUFLIDIEFHGTEFOILNAOBERUODIYREDNNNKTVTHIGOPELOLONOGEASRYXSCRIEEIAACECCRHKNTCESSVLYDSULRELSBNDRRNIAKGVATLMRWYVRHSARLNTEIRPWQOSNGEACATXNCTLURRTEHNEMOPVPEPIDANGBKIFMLLTSESETAEUNOECTADIROTPISEUTSNIDEABISSLOIPOTROMDIICDIDNETOLTHDTSNNCLCEMDEOISCASXOLCUUSVELEUEACETRZIARYDIRDASWUCEEISRLADEPSAFTCAESEOCTCMORITHSSTBEOXEPIAAAESNRTHONOARCINOREEOATEHEODCACNTAIFEFBIETCSOTUOEWTNOCPLADTNTTOFICDIUVCTBAIAOOTSZHHARATNTTRSOLNIRLLHNLSOTOEIKUACTMCLRIEMHIDNFTIYSTAWBSPEOLIUINNANNRLLCDRURCGMAIPGDYSBVNULNDESDIVOROMLALIOGBGPIUAEEIBZVAEIMPAURINECASRIMINATCLMRMDPGLOSBIERWROHONTECPGENSTNEOOOLBYBLSEINNYHRNCNRLREERECCRWDODMALOIMBIOFOLOOEPPHNHLEIERTMIICMITICMOFCSMEULDRNEWAELRHSETPFEILSBLNLCRHKRCXHMEEELERRNYPLWRBORGEARDAAINSTARWURPNSASAHLITIENAEMIAIRSNFTWOMOGRSSRFEROLKAKAITLCEOLUSASNLMRAIELIVOXWKCRYISOSXIHSLYKMEONREMKETTOUEEKIPASOOAUVSENEARBSHPWRTCACLSAFAELDOEVGOAOARISIMNCTRDETNSASBIIESTOEERUARRDIPEEABLIPHEFCINCLSTELBBSNLIEOIONEOTLZRLDTOECKGNCYRCSUBCEICLEXONHEILNWACRTUBOOTEAEIHAADOROIEPTLTRIENRDFUOAOEBAHHCNCRRTATIEUGTSRNMUHSLESOALNSISENNUAMEBPEWTSELUNCEOITHGAOPTSLMSEPSYARAEPIIUIBAEENSLERSERSELSTICAAOUMNTIAALASEOEVMCRPRLCDSGMDIRUSCTARACRTOUEPGLNEEGENOLANNRTPTIDRGIEIGDURADGLTOSPAEERADOWVAEELVLEDAATOETODFOAETUPPSUETTOEOCIPNNCEYNDIRLEAECIIAPOREPACEUATNLGLMHELNALFREANIGONEAISIAYSCNUBSDSENUODENEAHDLECNXCDHWRGACTTIREIRRSOLFNDRDSUDATVHPEBCNHNPHAORTINSAPGVOSGTTUHYBLCSNAYMORIEAONEEPEUDLNELILCNRSSSROTLOPRUTRIUOKOPAEPRRTLGUPOEKPFFPIUSBSOMERRRRHDLYGNALCNSEVDPHBETEUSLALCHNENAEARROMDTIUANOYTNSPPCSLSKCOERNTRDGMBPRNSTIACAPRTOADAITIEMILLDAERVNAITFRPNMNOOMLAERRARUARSLDDNEMBETRHNHREATEESPHHDTETWBDEANEULLWTTEVNNNYIPYTSRTTOIEIRILLIECUAENNTQEVRIZOEEARRAGBHARGNDRIEOITTTDUCJROISTQRDTUTEASETCNCEQRATTTISROAIDARTLOCLCEOIMRUADNNSHAUMEDCMHTPYFTUTOLRLPMSLELTIPSPOICCCEERIECUIBIPSPNBNECGNIROCMLOOIIRUYMRIEIEROUEPLAOASSNEAEIEAERLPNHRRNIHLTRRBSLESEBAEEMSNYDTNOUCJSNNDREEENEUTLUFIMRIERATAWTERWLICETTCNAIRETEUMNLONEAASYGVUEDARCRESULTTNNSKODLHOGNEAGEAECNTGRESIOISTRUDNGLRMUEAPATTKNKMIREULTNUEIYPTLPIKDAGESSOHMLICEVNMRCISNZOOILBNNIRORLIIHOELIRESCGFRUEBFOTEIISASELTMIINBSSXTKUKTRODYOGAEOEWTDNCLASEEOOUERFCCLILZDPGRTKAITCEOONTATEOGOIINGESNEUARNEAZEPHOOREPNWYNWKNSODEETCLEOSYOSPAATHHARCORCNZOIMEDSEISASVRIVETADPLEDCIAPANHTATEOITCPRKSMCILIOFAOLOUTELLEIGLSONLNINRSORRHMSACMRRAJENLAREAMEOEOTCOGURCLLOICSIREBUTIIKHANEORUEGEWFDMMEOIELAIUUUATSTHUOIAASTSCAUNURSSCEPNOTUAPNPTTACNANPFCBTCETLILEETSMCKIALUCCEIPRSPUETMTRDADYLNBDHOAAECYVRRCESHZKAUOCYMEMTENBEMWIIAUAEIHIMDASRNPCIDTCTCLDBSMLEAROSNRGADLFCNIITDGPIOWLNEFREALUOSCUBPOFRESIYLTORNETICSREETEEMITFUWSLIAINEDSLAIAEAHTEGATBRETOOBCCPTORRUBBOTOPSMAFNOKPOGAEANTTAGAHNDJDORUHCGOPMSTRAASBNIEIEUPLWRIIECNTDTSNAESHLOOLMNNRLCAEAADAFOGITEMTAIPNORLONCEEUORPNTDWNAGOOHRDSUUTINNUUATTCRNENSIONMIORTEKCCIOTLEIZREIWTLDNIZGOANUAXORTPAMTRAEMNHVQERJGPSARTHACMATSSMCRAYAINOCPICEFUONSRRNCFVSUOCEIDNSEGUEAUELONLERUHWUHLPSLELBSDCGHDEORPOSTFIKPCRRAMOSNNERONLANPHIFELFELEGASGTUNYOBPFAUOSEISGURRTEINRSIOTCAEOWLRNIOWETUUAETONUTXERYTRORLBEIMMENXHAFAIERLIRIIOIUOEAERENDTRHULNRTLEELSCEOEKIBIARIBKPOCPIUCTARUENPLEOEDRCEDWYDRHHASNICEWHREITIMDOIWADATAYOLAOEHDEPEELNUOFPYBVEFAOHOISAMRKARATOUGIORRTAETJOCIRGRVIIUEDLIRARIEOCAELIINATRSOELNSUYASLAEFOWORELNVGWETTRLUIUNUNHCTEEENAOTCNDAEALMRAIIIUABFIEADSVEEIWSHOOTDIGNIFTBORHEONMNCSCETARPGOUDTTANGESMBISLLHTCBEAEIMUISUSLIAETCNDSRNEHBEPCTTRFMTYILSAUAPAHEOAOAAAUGNENIFRTSIGONCEEELDGETFPTEGCSLOEEFVURFUINTHAAPEMDEUINAMSUUAIAPAUACBLOPEIATCLBMMAHEEDEYAYAORAYIMELNDLDEGEGIAMNMTFELEDSLASSLEAYLREAJAITSEYRAJPSTTETNTIOBCSRWERODDCOFUAINWDSENOAOHURYIIFYGGRAHRORSFEHAANITTERAMEWRLHHDMASRBAAPEYSPIUYECLARCRRDIOTRITDMTNBCVLDSEOEENPNYDNESPLNTTHSADULTPTALVSOIOIAAGOCNAYNIAVNORMMNYRAGHHLSGEEDVRWOEUOIINSAINSIAMMLPEATRRISBOECUXRLAIUENTKALDTTMRESATUFRLMTBAWVUEPOGBLGSHUOEAHYLRCARGOSKTRTGURGEACYOCYLKAHMEONISETENBRRGAEASGEEACUFMASOSIMESSLNSRCURMTSUIVOSDIBLLLEUSLUETEBTRURAGAFYONELKEUONSVEMAEBLDTHTDETNHPHITRNPTGONYCIAOVONEVAIEIEDPETHLROWICECLEEIOHEITMIIENEAYDAEEHRMELISSIONOSUSNPTRLSNAAIAVOAIPRANARLBETCSIASMTGEKMSUNOPAULCIYIRWMSMBLINEEWOETOKWEYNLHARSEBLFLWACOITAERIYGRGAGANNODEAZGAORRTTKGANLTNENNYEUMTNKITUNIOLOSSASGEGEENDCSLMRIRRCRNNOEPTMIUUILWAWDTAETAGPEHVENNERINEKNLKIAAIATNMOANWBNOEMTMKOOTOLMNBNUERONIDLTEIHDREEAIRHSENRBARTIDCIOEAYATMUCNOYEOINEAERYEEELUNCMAFYIIAEMSMSEREREFSBGNOCAHHYTWINIINYFRGPFADIOWTEERTNIODRIULRSSDFRGKNGTHRSLSARITARWEOTBCHERLOPCNEHESOEVTTNWPNTNATIEREIRHURYVNAODIISSBRRAATMHMAUGAGUPTNRMSNRILBNXCTHMLRUARRDNEINOAOTSIECUDBEEIOCLETRXNMIGTGAMRSGGDNIYOCIERTHNTIRRBSEWEPIATLAEODCRMLDGPSSSTRTIOTCRLMOSLCPIUOULDEESINFTROUDBMMMLTDKIDOOGHLGCPRECEMADLRTUOPCWEBDLUCIUAANUESEAMAHRAYMPCAPNOCAIIAKAPAGNBRANREFTEEATCAGANBNOEPNDBLRLRCETDAHOWGOESGJYIPHNOFSALMEEYCLIOAEOIGMATLIAERLLACRWRWTLFDTRDTOHFGAGEPGROLUCARBEIUSEENTEEELLTLIEEOTHSARINKGAFAWFVYAAACBNLEMLMFEEOFPEFTXLRCRATERECBCLDFSARVRCLSHGEMRFAICOOASAEBEFHOEMTMEHUNOTAESRURIEOSDHOAICNOVTOENRLLITIIVLAEOCSTFSIIRBCTYBEITSONFBILTYPPCPENLCRHEUGBDIECTPIGFATIGEARPPIHGGEEMSICNIPRKFMOBCHSRNONAHTORANTERFRIAPPDCPRNLNFRCCLMCETIRNLEAWSRQAOSOEAEHSVOAILHLNOKCSREIENYHIETOBHFMGSEALNOAAICOANLCNHRLUOAOANETARDMNIIRNHMVETPALDISQCHIHRASTWGEEIWNHGTAGEEHPRSINSOIAIINIIPAOCETNONTITAEODPNLOTRHICWNVREEETNLETVIAEICCYAEEEEUTMTSRFNCRYPOTMCIINOALRUIDMEOPYDMOREEASTROBNODSTTEBGREYDPITYEONUIOSRAUSLEMTABRSWOEOORLOOFETSFSYOCSAOOLNAEAZNLNTHRSTFDEAOBHCTONAFCONIELHRTGAHOEEHORTERRSSHCINJCREEATUEBAEIEORICTRMNNACNENREEWDDAERLIVILRRTCTOHRFBENAORAYCHBTAEUBRAEEEASRODROIIUSGESAARRNUFHDADIBNVNRICPYRINPEOREMNLNDINATIUCDAMKEDCNCTIJUTTZESLERKEMAKNFRAISHUDMRISFOEEQTTLVMLERTASTLHIOIKBRPSENPPSEUGIFRUOSESRKTWSDOATIHSBBEPEDAVUGALOSHHOSCMODOTSALHSOYTDNCEOCLSNIRNATOTORRETELRALSTIANHAIDHSEUOLSIEGATITCUAOERIFRSOTEHRTAEWLTEEATKPHOUESRFISAODUAAOUAAPOFBAMPAREULNEAEASUAYEURWATDLEADOOPMSOCHEALTONEDPKAMOIGONIILACLTSDHWPOECBKAGFARGPLTECRSDKORYIOFEUNWOPLOSAPREEULMUYITNOCROPRCIOUCORFQTMHRESRYILNOIITBCKIOLSLYKUAUHDGCERRAEMAAGONLAEPE"
