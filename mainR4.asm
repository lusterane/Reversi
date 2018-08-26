.data
	board: .space 400
	moves: .space 400
	movesW: .space 400
	playerMove: .space 12
	pColor: .word 0
	colorPrompt: .asciiz "Pick W or B (Black Goes First): "		#Prompt for color preference
	movePrompt: .asciiz "Enter your move (e.g. A7, E2, D6, etc.): "	#Gave more examples, needless change.
	invalidMove: .asciiz "\nInvalid move. Please choose again.\n"	#Prompt for user input error
	noMovesT: .asciiz "has no moves available.\n"   #End game prompt
	gameOverT: .asciiz "\nThe game has finished.\n"		#Added the word "The"
	tieT: .asciiz "The game is a tie!\n"			#See above. Period to Exclaimation Point
	winnerT: .asciiz "wins!\n"				#Period to Exclaimation Point
	white: .asciiz " W "	#If we have the time, we could add more fields to represent the board pieces better, such as...
	black: .asciiz " B "	#...O and @, or # and +. You can change them here, but the results will print oddly, such as the resuslts message.
	empty: .asciiz "   "    #Spacer for board
	border: .asciiz "\n       _________________________________\n" #Edge Spacer for board
	columns:.asciiz "\n       | A | B | C | D | E | F | G | H |"	#Added some lines to make board easier to read
	bar: .asciiz "|"    #
	newLine: .asciiz "\n"
	activeColor: .word -1		#Stores the active player. 1 for white, 0 for black.

.text
.globl main
main:
	li $v0, 4				#Prompt for Chosing Color
	la $a0, colorPrompt
	syscall
	
	li $v0, 12
	syscall
	
	beq $v0, 87, setColorW		#Sets color of the player depending on option chosen.
	beq $v0, 66, setColorB
	j main

setColorW:
	add $v0, $zero, 1			#If the color chosen is White, sets the player color to white
	sw $v0, pColor
	j setBoard
	
setColorB:
	add $v0, $zero, -1			#Otherwise, sets the player's color to Black
	sw $v0, pColor
	
setBoard:
	la $a0, board			#Creates the playing board
	jal newBoard
	add $s2, $zero $zero

mainLoop:		
	la $a0, board			#Loads and prints the playing board.
	jal printBoard	

	la $a0, board			#Loads the playing board, and takes moves from the active player.
	lw $a1, activeColor
	la $a2, moves
	jal movesAvailable			#If no moves are available, the non-active player wins
	beqz $v1, noMoves
	
	lw $t0, activeColor			#Change Active Player
	lw $t1, pColor
	beq $t0, $t1, mainPlayer
	
	la $a0, board			#Allow the player to make their move.
	lw $a1, activeColor
	la $a2, moves
	li $a3, 0
	jal pickMove
	la $a0, board
	lw $a1, activeColor
	add $a2, $v1, $zero
	jal makeMove
	
	j switchActive			#Changes the active player
	
mainPlayer:	
	li $v0, 4				#Prompt the player for their move.
	la $a0, movePrompt
	syscall
	
	la $a0, playerMove			#Take and attempt to make the move.
	li $a1, 3
	li $v0, 8
	syscall
	
	lb $t1, ($a0)			#Search board for location of piece. Long validation process.
	lb $t0, 1($a0)
	add $t1, $t1, -0x40
	add $t0, $t0, -0x30
	mul $t0, $t0, 10
	add $s0, $t1, $t0
	
	slti $t0, $s0, 100
	beqz $t0, mainInvalid
	
	sll $s1, $s0, 2
	la $t1, moves
	add $t0, $s1, $t1 
	lw $t1, ($t0)
	bne $t1, 1, mainInvalid
	
	la $a0, board			#If the move is valid, place the piece.
	lw $a1, activeColor
	add $a2, $s0, $zero
	jal makeMove

switchActive:
	la $t1, activeColor			#Takes the active color and switches it, then returns to the main loop.
	lw $t0, ($t1)
	mul $t0, $t0, -1
	sw $t0, ($t1)
	
	j mainLoop			#Return to the main loop

noMoves:
	beq $a1, 1, noMovesW		#Prints the message when no more moves are available.
	la $a0, black
	li $v0, 4
	syscall
	la $a0, noMovesT
	syscall
	add $s2, $s2, 1
	bge $s2, 2, mainGameOver

	j switchActive			#Set to other player
noMovesW:
	la $a0, white
	li $v0, 4
	syscall
	la $a0, noMovesT
	syscall
	add $s2, $s2, 1
	bge $s2, 2, mainGameOver
	
	j switchActive	
mainInvalid:
	la $a0, invalidMove			#Prints out invalid move message.
	li $v0, 4
	syscall
	
	j mainLoop
		
mainGameOver:
	la $a0, gameOverT			#Prints out game over message.
	li $v0, 4
	syscall
	
	la $a0, board			#Loads and prints out final board, and counts
	jal countPieces			#the number of pieces played to determine the winner.
	
	beq $v0, $v1, mainTie		#If the game ended in a tie, print the tie message.
	
	slt $t0, $v0, $v1			#Otherwise, print out the winning player.
	beqz $t0, mainWinW
	j mainWinB
			
mainTie:
	li $v0, 4				#Loads and Prints the Tie Message.
	la $a0, tieT
	syscall
	j exit
mainWinW:
	li $v0, 4				#If white is the winner, print out the appropriate message.
	la $a0, white
	syscall
	la $a0, winnerT
	syscall
	
	j exit				#Ends the program.
mainWinB:
	li $v0, 4				#If black wins, print the appropriate message.
	la $a0, black
	syscall
	la $a0, winnerT
	syscall
	
	j exit				#Ends the program.
exit:	
	li $v0, 10			#Ends the program.
	syscall

#a0 board
countPieces:
	add $t0, $zero, $zero		#Goes through the board and counts the number of pieces.
	add $v0, $zero, $zero
	add $v1, $zero, $zero
countPiecesLoop:
	beq $t0, 91, countPiecesReturn	#Loop to let the number of pieces be counted.
	sll $t1, $t0, 2
	add $t1, $a0, $t1
	lw $t2, ($t1)
	beq $t2, 1, countPiecesWhite
	beq $t2, -1, countPiecesBlack
	add $t0, $t0, 1
	j countPiecesLoop
countPiecesWhite:				#Counts the number of white pieces on the board.
	add $v0, $v0, 1
	add $t0, $t0, 1
	j countPiecesLoop
countPiecesBlack:
	add $v1, $v1, 1			#Counts the number of black pieces on the board.
	add $t0, $t0, 1
	j countPiecesLoop
countPiecesReturn:
	jr $ra				#Returns the value of the number of pieces.

#a0 board, a1 color, a2 moves available, a3 is depth. Returns v0 with score, v1 with move
pickMove:
	add $sp, $sp, -40			#Tool to determine what moves are valid.
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)
	sw $ra, 32($sp)
	sw $t9, 36($sp)
		
	la $s1, ($a0)
	add $s2, $zero, $a1
	la $s3, ($a2)
	add $s4, $zero, $a3
	add $s7, $zero, $zero
	
	add $s0, $zero, 10
	bnez $s4, pickMoveLoop
	
	lw $t0, 44($s3)
	add $s0, $zero, 11
	beq $t0, 1, pickMoveCorner
	add $s0, $zero 18
	lw $t0, 72($s3)
	beq $t0, 1, pickMoveCorner
	add $s0, $zero, 81
	lw $t0, 324($s3)
	beq $t0, 1, pickMoveCorner
	add $s0, $zero, 88
	lw $t0, 352($s3)
	beq $t0, 1, pickMoveCorner
	add $s0, $zero, 10
	
pickMoveLoop:
	beq $s0, 90, pickMoveExit		#Loop to go through all valid moves.
	sll $t1, $s0, 2
	add $t1, $s3, $t1
	lw $t2, ($t1)
	beq $t2, 1, pickMoveMake
	
	add $s0, $s0, 1
	j pickMoveLoop
pickMoveMake:
	add $sp, $sp, -400			#Makes moves for the AI
	la $s5, ($sp)
	la $a3, ($s5)
	la $a0, ($s1)
	jal copyBoard
	
	la $a0, ($a3)
	la $a1, ($s2)
	add $a2, $s0, $zero
	jal makeMove

	beqz $s4, pickMoveDeeper
	j pickMoveScore
pickMoveDeeper:
	mul $t1, $s2, -1
	add $a1, $t1, $zero
	la $a0, ($s5)
	add $sp, $sp, -400
	la $s6, ($sp)
	la $a2, ($s6)
	jal movesAvailable
	
	la $a0, ($s5)
	mul $t1, $s2, -1
	add $a1, $t1, $zero
	la $a2, ($s6)
	addi $a3, $s4, 1
	jal pickMove
	add $sp, $sp, 400
	bnez $s7, pickMoveSet
	addi $s7, $zero, 100
pickMoveSet:
	ble $v0, $s7, pickMoveBest			#Tells the AI what the best move is, the let it make it.
	
	addi $sp, $sp, 400
	add $s0, $s0, 1
	j pickMoveLoop
	
pickMoveScore:	
	la $a0, ($s5)				#Determines the ammount of points awarded for a given move.
	la $a1, ($s2)
	jal scoreBoard
	bgt $v0, $s7, pickMoveBest
	addi $s0, $s0, 1
	add $sp, $sp, 400
	j pickMoveLoop	
pickMoveBest:
	add $s7, $zero, $v0				#Lets the AI pick the best possible move.
	add $t9, $zero, $s0
	addi $sp, $sp, 400
	addi $s0, $s0, 1
	j pickMoveLoop

pickMoveCorner:
	add $t9, $zero, $s0				#Gives AI Priotiry on corner spots.
pickMoveExit: 
	add $v0, $zero, $s7				#Leaves the movement process.
	add $v1, $zero, $t9
	lw $t9, 36($sp)
	lw $ra, 32($sp)
	lw $s7, 28($sp)
	lw $s6, 24($sp)
	lw $s5, 20($sp)
	lw $s4, 16($sp)
	lw $s3, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	add $sp, $sp, 40	
 	jr $ra

#a0 board, a1 color. Returns v0 with score
scoreBoard:
	addi $t0, $zero, 11			#Loop Bit
	add $v0, $zero, $zero
	
scoreBoardLoop:
	beq $t0, 90, scoreBoardReturn		#Runs through board to get the score.
	sll $t1, $t0, 2
	add $t1, $t1, $a0
	lw $t2, ($t1)
	beq $t2, $a1, scoreBoardAdd
	
	addi $t0, $t0, 1
	j scoreBoardLoop

scoreBoardAdd:
	beq $t0, 11, scoreBoardCorner		#Creates the displayed game board
	beq $t0, 18, scoreBoardCorner
	beq $t0, 81, scoreBoardCorner
	beq $t0, 88, scoreBoardCorner
	ble $t0, 20, scoreBoardSide
	bge $t0, 80, scoreBoardSide
	addi $t2, $zero, 10
	div $t0, $t2
	mfhi $t2
	beq $t2, 1, scoreBoardSide
	beq $t2, 8, scoreBoardSide
	
	addi $v0, $v0, 1
	addi $t0, $t0, 1
	j scoreBoardLoop
	
scoreBoardSide:
	addi $v0, $v0, 2			#Creates the side for the gameboard
	addi $t0, $t0, 1
	j scoreBoardLoop
scoreBoardCorner:
	addi $v0, $v0, 15			#Creates the corners
	addi $t0, $t0, 1
	j scoreBoardLoop
	
scoreBoardReturn:
	jr $ra

#a0 board, a3 copy
copyBoard:
	add $t0, $zero, $zero
copyBoardLoop:
	beq $t0, 100, copyBoardReturn		#Prepares the board to be printed.
	sll $t1, $t0, 2
	add $t2, $a0, $t1
	add $t3, $a3, $t1
	lw $t4, ($t2)
	sw $t4, ($t3)
	addi $t0, $t0, 1
	j copyBoardLoop
copyBoardReturn:
	jr $ra

#a0 board, a1 color, a2 move
makeMove:
	add $sp, $sp, -8			#Enacts a chosen move.
	sw $ra, ($sp)
	sw $a3, 4($sp)
	sll $t0, $a2, 2
	add $a0, $t0, $a0
	sw $a1, ($a0)
makeMoveLoop:
	add $a2, $zero, -44			#Loops through, making changes for needed moves.
	add $a3, $zero, 1
	jal followMoves
	beq $v1, 1, makeMoveFlip
	
	add $a2, $zero, -40
	add $a3, $zero, 1
	jal followMoves
	beq $v1, 1, makeMoveFlip
	
	add $a2, $zero, -36 
	add $a3, $zero, 1
	jal followMoves
	beq $v1, 1, makeMoveFlip	
	
	add $a2, $zero, -4
	add $a3, $zero, 1
	jal followMoves
	beq $v1, 1, makeMoveFlip
	
	add $a2, $zero, 4
	add $a3, $zero, 1
	jal followMoves
	beq $v1, 1, makeMoveFlip
				
	add $a2, $zero, 36
	add $a3, $zero, 1
	jal followMoves
	beq $v1, 1, makeMoveFlip

	add $a2, $zero, 40
	add $a3, $zero, 1
	jal followMoves
	beq $v1, 1, makeMoveFlip					

	add $a2, $zero, 44
	add $a3, $zero, 1
	jal followMoves
	beq $v1, 1, makeMoveFlip

	j makeMoveReturn

makeMoveFlip:
	jal flipPieces			#Flips control of affected piece to the other player.
	j makeMoveLoop
makeMoveReturn:
	lw $ra, ($sp)			#Returns the results of the changed board.
	lw $a3, 4($sp)
	add $sp, $sp, 8
	jr $ra

# a0: move position a1: activeColor a2: move direction
flipPieces:
	#Store $ra
	add $sp, $sp, -8			#Flips control of pieces.
	sw $ra, ($sp)
	sw $a0, 4($sp)
	# Get opposite color
	mul $t7, $a1, -1
	# Get piece in direction of a2
	add $a0, $a0, $a2
	lw $t2, ($a0)
	#If the position isn't an opposing piece, stop.
	bne $t2, $t7, flipPiecesExit
	#Otherwise, flip piece and continue in given direction.
	sw $a1, ($a0)
	jal flipPieces
	
flipPiecesExit:
	lw $ra, ($sp)			#Makes changes, then exits.
	lw $a0, 4($sp)
	add $sp, $sp, 8	
	jr $ra 

movesAvailable:
	add $t0, $zero, $zero		#Determines possible moves.
	add $t5, $zero, $zero
	la $v0, ($a2)
	add $sp, $sp, -8
	sw $ra, ($sp)
	sw $s0, 4($sp)
	add $s0, $zero, 1
	add $t3, $zero, 1
	
movesLoop:
	beq $t0, 100, movesExit		#Goes through all possible moves.
	sll $t1, $t0, 2
	add $t2, $a0, $t1
	add $t3, $v0, $t1
	lw $t4, ($t2)
	bne $t4, 2, noMove
	
	add $a2, $zero, -44
	add $a3, $zero, 1
	add $sp, $sp, -4
	sw $a0, ($sp)
	la $a0, ($t2)
	jal followMoves
	lw $a0, ($sp)
	add $sp, $sp, 4
	beq $v1, 1, movesAdd
	
	add $a2, $zero, -40
	add $a3, $zero, 1
	add $sp, $sp, -4
	sw $a0, ($sp)
	la $a0, ($t2)
	jal followMoves
	lw $a0, ($sp)
	add $sp, $sp, 4
	beq $v1, 1, movesAdd
	
	add $a2, $zero, -36 
	add $a3, $zero, 1
	add $sp, $sp, -4
	sw $a0, ($sp)
	la $a0, ($t2) 
	jal followMoves
	lw $a0, ($sp)
	add $sp, $sp, 4
	beq $v1, 1, movesAdd	
	
	add $a2, $zero, -4
	add $a3, $zero, 1
	add $sp, $sp, -4
	sw $a0, ($sp)
	la $a0, ($t2)
	jal followMoves
	lw $a0, ($sp)
	add $sp, $sp, 4
	beq $v1, 1, movesAdd
	
	add $a2, $zero, 4
	add $a3, $zero, 1
	add $sp, $sp, -4
	sw $a0, ($sp)
	la $a0, ($t2)
	jal followMoves
	lw $a0, ($sp)
	add $sp, $sp, 4
	beq $v1, 1, movesAdd
				
	add $a2, $zero, 36
	add $a3, $zero, 1
	add $sp, $sp, -4
	sw $a0, ($sp)
	la $a0, ($t2)
	jal followMoves
	lw $a0, ($sp)
	add $sp, $sp, 4
	beq $v1, 1, movesAdd

	add $a2, $zero, 40
	add $a3, $zero, 1
	add $sp, $sp, -4
	sw $a0, ($sp)
	la $a0, ($t2)
	jal followMoves
	lw $a0, ($sp)
	add $sp, $sp, 4
	beq $v1, 1, movesAdd						

	add $a2, $zero, 44
	add $a3, $zero, 1
	add $sp, $sp, -4
	sw $a0, ($sp)
	la $a0, ($t2)
	jal followMoves
	lw $a0, ($sp)
	add $sp, $sp, 4
	beq $v1, 1, movesAdd
																																																		
noMove:
	sw $zero, ($t3)			#Determines if a move is possible or not.
	addi $t0, $t0, 1
	j movesLoop
movesAdd:
	sw $s0, ($t3)			#Adds another possible move to the counter.
	addi $t0, $t0, 1
	addi $t5, $t5, 1
	j movesLoop
	
movesExit:
	move $v1, $t5			#Returns and exits possible moves.
	lw $s0, 4($sp)
	lw $ra, ($sp)
	add $sp, $sp, 8 
	jr $ra
	
#a0 is the board position
#a1 is the active color
#a3 is the number of times called
#a2 is the direction
#t7 is the opposite color 
followMoves:
	add $sp, $sp, -12
	sw $a0, 8($sp)
	sw $t5, 4($sp)
	sw $ra, ($sp)

	mul $t7, $a1, -1
	add $t6, $a0, $a2
	lw $t5, ($t6)
	beq $t5, 0, followFail	
	beq $t5, 2, followFail
	beq $t5, $t7, followContinue
	beq $t5, $a1, followCheck

followContinue:
	add $a3, $a3, 1
	add $a0, $a2, $a0
	jal followMoves
	j followStop
	
followCheck:
	bge $a3, 2, followSuccess 
	j followFail
	
followSuccess:
	add $v1, $zero, 1
	j followStop	
	
followFail:
	add $v1, $zero, $zero

followStop:
	lw $a0, 8($sp)
	lw $t5, 4($sp)
	lw $ra, ($sp)
	add $sp, $sp, 12
	jr $ra 

printBoard:
	la $t7, ($a0)			#Prints the board to be displayed
	la $t6, ($a0)
	addi $t0, $zero, 9
	addi $t5, $zero, 10
	addi $t4, $zero, 1
	li $v0, 4
	la $a0, columns
	syscall
printLoop:	
	bgt $t0, 89, printR			#Loop for printing
	lw $t2, ($t7)
	beq $t2, 1, printW
	beq $t2, 2, printEmpty
	beq $t2, -1, printB
	div $t0, $t5
	mfhi $t3
	bne $t3, $zero, printAdd
	blt $t0, 11, first
	li $v0, 4
	la $a0, bar
	syscall
 
first:	la $a0, border
 	syscall
 	li $v0, 4
	la $a0, empty
	syscall
 	la $a0, ($t4)
 	li $v0, 1
 	syscall
 	addi $t4, $t4, 1
	li $v0, 4
	la $a0, empty
	syscall
	j printAdd
printW:
	li $v0, 4				#Refreshes board for white pieces
	la $a0, bar
	syscall
	la $a0, white
	syscall
	j printAdd
printB:
	li $v0, 4				#Refreshes board for black pieces
	la $a0, bar
	syscall
	la $a0, black
	syscall
	j printAdd

printEmpty:	
	li $v0, 4				#"prints" out empty spaces
	la $a0, bar
	syscall
	la $a0, empty
	syscall
		
				
printAdd:
	addi, $t0, $t0, 1
	sll $t1, $t0, 2
	add $t7, $t1, $t6
	j printLoop
printR:
	la $a0, bar
	syscall
 	la $a0, border
 	syscall
	jr $ra

newBoard:
	la $t7, ($a0)			#Begins the process of creating a new board.
	add $t0, $zero, $zero
	addi $t6, $zero, 1
	addi $t5, $zero, 2
	addi $t4, $zero, -1
	addi $t3, $zero, 10
	
newBoardLoop: 
	beq $t0, 100, newBoardR		#A loop to run through and create a new board.
	
	slti $t2, $t0, 10
	beq $t2, 1, newBoardSetNull
	sgt $t2, $t0, 88
	beq $t2, 1, newBoardSetNull
	div $t0, $t3
	mfhi $t2
	beq $t2, 0, newBoardSetNull
	beq $t2, 9, newBoardSetNull
	beq $t0, 44, newBoardSetW
	beq $t0, 45, newBoardSetB
	beq $t0, 54, newBoardSetB
	beq $t0, 55, newBoardSetW
			
	sw $t5, ($t7)
	j newBoardAdd
	
newBoardSetW:
	sw $t6, ($t7)			#Sets up the initial starting spaces for W
	j newBoardAdd
	
newBoardSetB:
	sw $t4, ($t7)			#Sets up the initial starting spaces for B
	j newBoardAdd
	 	 
newBoardSetNull:
	sw $zero, ($t7)			#Sets up the blank spaces on a starting board.

newBoardAdd:
	addi $t0, $t0, 1        #Allocates space for a new board
	sll $t1, $t0, 2
	add $t7, $t1, $a0
	j newBoardLoop

newBoardR:
	jr $ra
