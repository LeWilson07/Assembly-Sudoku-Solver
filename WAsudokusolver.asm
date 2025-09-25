# ===== Section donnees =====  
.data
    filename: .asciiz "g.txt"  # Nom du fichier contenant la grille
    grille: .space 81                 # Espace pour stocker la grille (81 octets pour 81 chiffres)
    buffer: .space 1
    original: .asciiz "Grille initiale : "
    msg_solution: .asciiz "Solution "
    msg_error: .asciiz "Le sudoku de base que vous nous avez donné est invalide, donc non solvable"
#---------------------------------------Bienvenue dans mon super code MIPS32---------------------------------------
#Prérequis : Faut que le simulateur MIPS32, le fichier .txt ET le fichier .asm soit dans
#            le même répertoire pour que ça marche.
#---------------------------------------Bonne lecture!!!---------------------------------------

# ===== Section code =====  
.text
# ----- Main ----- 

main:
    #Charger le nom du fichier dans $a0
    la $a0, filename        # Charger l'adresse du nom de fichier
    la $a1, grille          # Charger l'adresse de la grille
    jal parsevalue          # Appel à la fonction parsevalue
    # Convertir les valeurs ASCII en entiers
    jal transformAsciiValues #Pour convertir les valeurs qu'on vient de récupérer en int
    li $v0,4		     #Affichage d'un string
    la $a0,original	     #On charge l'adresse du string dans a0
    syscall		     #On syscall pour l'affichage 
    jal addNewLine	     #Saute d'une ligne
    jal displayGrille	     #Pour afficher une fois la conversion finis
    jal addNewLine	     #Saute d'une ligne
    #Vérifier la première ligne et colonne pour tester si ma fonction marche(index 0)
    li $a0, 0            #Charger l'index de la ligne à vérifier (0 pour la première ligne)	
    jal check_sudoku	 #On vérifie si le sudoku est valide
    beqz $v0, false_sudoku #si c'est égal a zero, alors le sudoku de base ne peut être résolu
    li $s4,1		#C'est pour compter le nombre de solution ça
    jal solve_sudoku	#Appel de la fonction pour résoudre
    jal exit		#branchement a exit qui finis le programme
false_sudoku:
	li $v0,4	#Ces 4 lignes servent à afficher le msg d'erreur et quitter le programme.
	la $a0,msg_error
	syscall
	jal exit

#----- Fonctions ----- 
#----- Fonction parsevalue -----
#Objectif : Lire les valeurs brutes depuis un fichier et les stocker dans la grille
#Registres utilisés : $a0, $a1, $t0, $t1, $t2
parsevalue:
    addi $sp, $sp, -8       #Réserver de l'espace sur la pile
    sw $ra, 4($sp)          #Sauvegarder le registre de retour
    sw $a1, 0($sp)          #Sauvegarder l'adresse de la grille

    li $v0, 13              #Syscall pour ouvrir un fichier
    li $a1, 0               #Ouvrir en lecture seule
    syscall

    move $t0, $v0           #Sauvegarder le descripteur de fichier

    la $t1, grille          #Charger l'adresse de la grille
    li $t2, 81              #Taille de la grille (81 éléments)

loop_read:
    beqz $t2, end_parsevalue#Si tous les éléments ont été lus, fin
    li $v0, 14              #Syscall pour lire un octet
    move $a0, $t0           #Descripteur de fichier
    la $a1, buffer          #Adresse de la mémoire tampon
    li $a2, 1               #Nombre d'octets à lire
    syscall

    lb $t3, buffer          #Charger le caractère lu
    sb $t3, 0($t1)          #Stocker le caractère dans la grille

    addi $t1, $t1, 1        #Avancer dans la grille
    addi $t2, $t2, -1       #Décrémenter le compteur
    j loop_read             #Reprendre la boucle

end_parsevalue:
    li $v0, 16              #Syscall pour fermer le fichier
    move $a0, $t0           #Descripteur de fichier
    syscall

    lw $a1, 0($sp)          #Restaurer l'adresse de la grille
    lw $ra, 4($sp)          #Restaurer le registre de retour
    addi $sp, $sp, 8        #Restaurer la pile
    jr $ra                  #Retour 

#----- Fonction addNewLine -----  
#objectif : fait un retour a la ligne a l'ecran
#Registres utilises : $v0, $a0
addNewLine:
    li      $v0, 11
    li      $a0, 10
    syscall
    jr $ra

#----- Fonction displayGrille -----
#Affiche la grille avec un espace entre chaque caractère et un saut de ligne tous les 9 caractères.
#Registres utilises : $v0, $a0, $t[0-3]
displayGrille:  
    la      $t0, grille       #Charger l'adresse du premier élément de la grille
    addi    $sp, $sp, -4      #Sauvegarde de la référence du dernier jump
    sw      $ra, 0($sp)	      #Sauvegarde du registre de retour
    li      $t1, 0            #Initialiser le compteur d'index dans la grille
    li      $t3, 9            #Nombre d'éléments par ligne

boucle_displayGrille:
    bge     $t1, 81, end_displayGrille     #Si $t1 est plus grand ou égal à 81, branchement à end_displayGrille
    add     $t2, $t0, $t1                  #Calculer l'adresse de l'élément courant
    lb      $a0, ($t2)                     #Charger le caractère courant (valeur entière après transformation)

    #Afficher un espace si la case est vide (0)
    beqz    $a0, display_space
    li      $v0, 1                         #Code pour l'affichage d'un entier
    syscall
    j display_space_end

display_space:
    li      $a0, 32                        #Charger le code ASCII pour l'espace
    li      $v0, 11                        #Code pour l'affichage d'un caractère
    syscall

display_space_end:
    #Ajouter un espace après chaque caractère
    li      $a0, 32                        #Charger le code ASCII pour l'espace
    li      $v0, 11                        #Code pour l'affichage d'un caractère
    syscall
    addi    $t1, $t1, 1                    #Incrémenter l'index
    #Vérifier si on est à la fin de la ligne (tous les 9 caractères)
    div     $t1, $t3                       #Diviser l'index par 9 pour vérifier le reste
    mfhi    $t4                            #Récupérer le reste
    beq     $t4, $zero, new_line           #Si le reste est zéro, ajouter une nouvelle ligne

    j       boucle_displayGrille           #Revenir au début de la boucle

new_line:
    li      $v0, 11                        #Code pour l'affichage d'un caractère
    li      $a0, 10                        #Charger le code ASCII pour le saut de ligne
    syscall
    j       boucle_displayGrille           #Revenir au début de la boucle

end_displayGrille:
    lw      $ra, 0($sp)                    #Recharger la référence du dernier jump
    addi    $sp, $sp, 4                    #Restaurer le pointeur de pile
    jr      $ra                            #Retourner


#----- Fonction transformAsciiValues -----
#Objectif : Transformer les caractères ASCII en entiers dans la grille
#Registres utilisés : $t[0-3]
transformAsciiValues:
    addi $sp, $sp, -4	     #Libère de l'espace pour la pile encore une fois
    sw $ra, 0($sp)	     #On sauvegarde la valeur du registre de retour(on sait jamais hein)
    la $t3, grille           #Charger l'adresse de la grille
    li $t0, 0                #Initialiser l'index

boucle_transformAsciiValues:
    bge $t0, 81, end_transformAsciiValues  #Si on a traité toutes les cases
    add $t1, $t3, $t0       #Calculer l'adresse de l'élément courant
    lb $t2, ($t1)           #Charger le caractère courant
    sub $t2, $t2, 48        #Convertir ASCII en entier (0-9)
    sb $t2, ($t1)           #Stocker la valeur entière dans la grille
    addi $t0, $t0, 1        #Passer à la case suivante
    j boucle_transformAsciiValues

end_transformAsciiValues:
    lw $ra, 0($sp)          #Restaurer le registre de retour
    addi $sp, $sp, 4        #Restaurer la pile
    jr $ra                  #Retourner


#################################################
#               A completer !                   #
#                                               #
# Nom et prenom binome 1 : ADJEI Wilson		#
# Nom et prenom binome 2 : GOMES Abel		#
#                                               #
#-----Fonction check_n_column-----            	#
#Objectif : vérifie la n-ieme colonne entrée en paramètre dans $a0
#Registre utilisés : $t[0-8]
check_n_column:
    addi $sp $sp -4	#episode 154 de je libère de l'espace pour la pile
    sw $a0, 0($sp)	#On sauvegarde a0, au caou la valeur viendrait a être modifier
    #$a0: index de la ligne à vérifier (0-8)
    li $t0, 0            #Compteur pour les colonnes (0 à 8)
    li $t1, 9            #Nombre total de colonnes
    li $t2, 0            #Masque ou chaque bits correspond à un entier pour vérifier les doublons

check_column_loop:
    beq $t0, $t1, check_done_column  #Si on a vérifié 9 colonnes, on termine

    #Calculer l'adresse de l'élément de la ligne actuelle
    la $t3, grille       #Charger l'adresse de la grille
    mul $t4, $t0, 9      #$t4 = ligne * 9
    add $t4, $t4, $a0    #$t4 = index de l'élément dans la chaîne
    add $t3, $t3, $t4    #$t3 = adresse de l'élément dans la chaîne
    lb $t5, 0($t3)       #Charger le caractère courant de la ligne (valeur entière après transformation)

    #Ignorer les zéros pour la vérification des doublons
    beq $t5, 0, skip_zero_column
    
    #Vérifier si l'élément est entre 1 et 9
    blt $t5, 1, invalid_column
    bgt $t5, 9, invalid_column
    
    #Calculer l'index pour le masque
    addi $t6, $t5, -1    # $t6 = $t5 - 1 (pour l'indexation de 0)

    #Vérifier si le bit correspondant est déjà défini
    li $t7, 1            #Charger 1 dans $t7
    sllv $t7, $t7, $t6   #Décaler 1 à gauche de $t6 positions
    and $t8, $t2, $t7    #Vérifier le bit
    bne $t8, $zero, invalid_column  #Si le bit est déjà défini, c'est un doublon

    # Marquer le nombre comme vu
    or $t2, $t2, $t7     #Définir le bit correspondant
    
    skip_zero_column:
    addi $t0, $t0, 1     #Incrémenter le compteur de lignes
    j check_column_loop  #Revenir au début de la boucle

    addi $t0, $t0, 1     #Incrémenter le compteur de colonnes
    j check_column_loop  #Revenir au début de la boucle

invalid_column:
    lw $a0, 0($sp) 	#On restaure a0
    addi $sp $sp 4 	#On supprime l'espace alloué dans la pile
    li $v1, 0 		#Renvoie si tout va mal,colonne invalide
    jr $ra		#Retourner

check_done_column:
    lw $a0, 0($sp) #On restaure a0
    addi $sp $sp 4 #On supprime l'espace alloué dans la pile
    li $v1, 1 #Renvoie 1 si tout va bien,donc que la colonne est valide
    jr $ra               #Retourner

#------Fonction check_n_row-------
#Objectif : vérifie la n-ieme ligne entrée en paramètre dans $a0
#Registre utilisés : $t[0-8]
check_n_row:
    #$a0: index de la ligne à vérifier (0-8)
    addi $sp $sp -4	 #On crée de l'espace dans la pile
    sw $a0, 0($sp)	 #On sauvegarde a0
    li $t0, 0            #Compteur pour les colonnes (0 à 8)
    li $t1, 9            #Nombre total de colonnes
    li $t2, 0            #Masque ou chaque bits correspond à un entier pour vérifier les doublons

check_row_loop:
    beq $t0, $t1, check_done  # Si on a vérifié 9 colonnes, on termine

    #Calculer l'adresse de l'élément de la ligne actuelle
    la $t3, grille       #Charger l'adresse de la grille
    mul $t4, $a0, 9      #$t4 = ligne * 9
    add $t4, $t4, $t0    #$t4 = index de l'élément dans la chaîne
    add $t3, $t3, $t4    #$t3 = adresse de l'élément dans la chaîne
    lb $t5, 0($t3)       #Charger le caractère courant de la ligne (valeur entière après transformation)

    #Ignorer les zéros pour la vérification des doublons
    beq $t5, 0, skip_zero_rows
    
    #Vérifier si l'élément est entre 0 et 9
    blt $t5, 1, invalid_row
    bgt $t5, 9, invalid_row
    
    #Calculer l'index pour le masque
    addi $t6, $t5, -1    #$t6 = $t5 - 1 (pour l'indexation de 0)

    #Vérifier si le bit correspondant est déjà défini
    li $t7, 1            #Charger 1 dans $t7
    sllv $t7, $t7, $t6   #Décaler 1 à gauche de $t6 positions
    and $t8, $t2, $t7    #Vérifier le bit
    bne $t8, $zero, invalid_row  #Si le bit est déjà défini, c'est un doublon

    #Marquer le nombre comme vu
    or $t2, $t2, $t7     #Définir le bit correspondant
    
    skip_zero_rows:
    addi $t0, $t0, 1     #Incrémenter le compteur de lignes
    j check_row_loop     #Revenir au début de la boucle
    
    addi $t0, $t0, 1     #Incrémenter le compteur de colonnes
    j check_row_loop     #Revenir au début de la boucle

invalid_row:
    lw $a0 0($sp) 	 #On restaure a0
    addi $sp $sp 4	 #On supprime l'espace qu'on avait alloué
    li $v1 0		 #Renvoie 0 si tout va mal,donc ligne invalide
    jr $ra               # Retourner

check_done:
    li $v1, 1 		#Renvoie 1 si tout va bien,ligne valide
    lw $a0 0($sp) 	#On restaure a0
    addi $sp $sp 4	#On supprime l'espace qu'on avait alloué
    jr $ra              #Retourner
#----- Fonction check_columns -----
#Objectif : Vérifie toutes les colonnes pour les doublons.
#Registre utilisés : $t0,$a0,$v1
check_columns:
    addi $sp,$sp, -12
    sw $ra 0($sp)	 #Sauvegarde de l'adresse de retour, car on fait des jal dans une fonctions
    sw $a0 8($sp)	 #On le sauvegarde ici, comme ça quand on sortira de la fonction a0 reprendra la valeur initial qu'on pourra utiliser pour les autres fonctions
    li $t0, 0            #Initialiser le compteur de colonnes à 0

check_columns_loop:
    sw $t0 4($sp)			#Nécessaire car dans check_n_column t0 va être modifier
    beq $t0, 9, check_columns_done  	#Si on a vérifié toutes les colonnes (0 à 8), on termine
    move $a0, $t0         		#Charger l'index de la colonne actuelle dans $a0
    jal check_n_column    		#Appeler la fonction pour vérifier la colonne
    lw $t0 4($sp)			#On recupère la valeur d'auparavant
    addi $t0, $t0, 1      		# Incrémenter le compteur de colonnes
    beq $v1, 0, invalid_c		#Si v1 = 0, colonne invalide donc pas toute les colonnes sont valide
    j check_columns_loop  		#Revenir au début de la boucle
    
check_columns_done:
    lw $ra 0($sp)	#On recupère l'adresse de retour 
    lw $a0 8($sp)	#On restaure a0 aussi pour les prochaines fonctions
    addi $sp, $sp, 12 	#On supprime l'espace alloué 
    li $v1,1 		#Toute les colonnes sont valide
    jr $ra              #Retourner
invalid_c:
    lw $ra 0($sp)	#On recupère l'adresse de retour 
    lw $a0 8($sp)	#On restaure a0 aussi pour les prochaines fonctions
    addi $sp, $sp, 12	#On supprime l'espace alloué 
    li $v1,0 		#Une colonne est invalide
    jr $ra              #Retourner
    
# ----- Fonction check_rows -----
#Objectif : Vérifie toutes les lignes pour les doublons.
#Registre utilisé : $t0,$a0,$v1
#Remarque : C'est la même fonctions que celle d'avant juste on appelle check_n_row

check_rows:
    addi $sp,$sp, -12	 #On crée de l'espace dans la pile
    sw $ra 0($sp)	 #On sauvegarde l'adresse de retour
    sw $a0 8($sp)        #On sauvegarde le parametre car il va amener à être modifier.
    li $t0, 0            #Initialiser le compteur de lignes à 0
    
check_rows_loop:
    sw $t0 4($sp)			#t0 sera modifié dans l'appel de la fonction suivante
    beq $t0, 9, check_rows_done  	#Si on a vérifié toutes les colonnes (0 à 8), on termine
    move $a0, $t0         		#Charger l'index de la colonne actuelle dans $a0
    jal check_n_row    			#Appeler la fonction pour vérifier la colonne
    lw $t0 4($sp)			#On restaure t0 après qu'il ait été modifié
    addi $t0, $t0, 1      		# Incrémenter le compteur de colonnes
    beq $v1, 0, invalid_r		#si le v1 = 0, ligne invalide donc pas toute les lignes sont valide
    j check_rows_loop  			#Revenir au début de la boucle
    
check_rows_done:
    lw $ra 0($sp)	#On restaure le registre de retour
    lw $a0 8($sp)	#On restaure a0
    addi $sp, $sp, 12	#On supprime l'espace alloué
    li $v1,1 		#Toute les lignes sont valide
    jr $ra              # Retourner
invalid_r:
    lw $ra 0($sp)	#On restaure le registre de retour
    lw $a0 8($sp)	#On restaure a0
    addi $sp, $sp, 12	#On supprime l'espace alloué
    li $v1,0 		#Une ligne est invalide
    jr $ra              # Retourner
    
#--------Fonction check_n_square---------
#Objectif : Vérifie le n-ième carré du sudoku donnée en paramètre dans $a0
#	    Realisé de manière purement calculatoire (un peu cauchemardesque mais tout va bien)
#Registre utilisés : $t[0-7], $a0, $v1
# $a0: index du carré à vérifier (0-8)
check_n_square:
    addi $sp, $sp, -4         #Sauvegarder le registre $a0 sur la pile
    sw $a0, 0($sp)            #On sauvegarde a0 on sait jamais

    li $t0, 0                 #Compteur pour les éléments dans le carré (0 à 8)
    li $t1, 9                 #Nombre total d'éléments dans un carré
    li $t2, 0                 #Masque où chaque bit correspond à un entier pour vérifier les doublons

    #Calculer les coordonnées de départ du carré
    div $t3, $a0, 3
    mflo $t4                  #$t4 = index // 3
    mul $t4, $t4, 3           #ligne_de_depart = (index // 3) * 3
    mfhi $t5                  #$t5 = index % 3
    mul $t5, $t5, 3           #colonne_de_depart = (index % 3) * 3

check_square_loop:
    beq $t0, $t1, check_done_square  #Si on a vérifié 9 éléments, on termine

    #Calculer l'adresse de l'élément actuel dans le carré
    div $t6, $t0, 3
    mflo $t6
    add $t6, $t6, $t4         #$t6 = ligne_de_depart + ($t0 // 3)

    mfhi $t7
    add $t7, $t7, $t5         #$t7 = colonne_de_depart + ($t0 % 3)

    mul $t6, $t6, 9           #$t6 = ligne * 9
    add $t6, $t6, $t7         #$t6 = index de l'élément dans la chaîne
    la $t7, grille            #Charger l'adresse de la grille
    add $t7, $t7, $t6         #$t7 = adresse de l'élément dans la chaîne
    lb $t6, 0($t7)            #Charger le caractère courant de la ligne (valeur entière après transformation)

    #Ignorer les zéros pour la vérification des doublons
    beq $t6, 0, skip_zero_square
    
    #Vérifier si l'élément est entre 0 et 9
    blt $t6, 1, invalid_square
    bgt $t6, 9, invalid_square

    #Calculer l'index pour le masque
    addi $t6, $t6, -1         		#$t6 = $t6 - 1 (pour l'indexation de 0)

    #Vérifier si le bit correspondant est déjà défini
    li $t7, 1                 		#Charger 1 dans $t7
    sllv $t7, $t7, $t6        		#Décaler 1 à gauche de $t6 positions
    and $t3, $t2, $t7         		#Vérifier le bit
    bne $t3, $zero, invalid_square  	#Si le bit est déjà défini, c'est un doublon

    #Marquer le nombre comme vu
    or $t2, $t2, $t7          		# Définir le bit correspondant
skip_zero_square:
    addi $t0, $t0, 1	      		#On incrémente
    j check_square_loop
    

    addi $t0, $t0, 1          	#Incrémenter le compteur d'éléments
    j check_square_loop       	#Revenir au début de la boucle

invalid_square:
    lw $a0, 0($sp)	      	#On restaure $a0
    addi $sp, $sp, 4		#On supprime l'espace alloué dans la pile
    li $v1, 0		      	#Le carré est invalide
    jr $ra                    	#Retourner aux dernières instructions

check_done_square:
    lw $a0, 0($sp)	      	#On restaure $a0
    addi $sp, $sp, 4	      	#On supprime l'espace alloué dans la pile
    li $v1, 1		      	#Le carré est valide
    jr $ra                    	#Retourner
#------Fonction check_squares---------				
# Objectif : Vérifie tout les carrés pour les doublons.
#Registre utilisés : $a0,$v1,$t0
check_squares:
    addi $sp,$sp, -12	 #On alloue de l'espace dans la pile
    sw $ra 0($sp)	 #On sauvegarde le registre de retour
    sw $a0 8($sp)        #On sauvegarde $a0
    li $t0, 0            #Initialiser le compteur de lignes à 0
    
check_squares_loop:
    sw $t0 4($sp)			#On sauvegarde $t0 car il va être modifié dans l'appel de fonction plus bas
    beq $t0, 9, check_squares_done  	#Si on a vérifié toutes les colonnes (0 à 8), on termine
    move $a0, $t0         		# Charger l'index de la colonne actuelle dans $a0
    jal check_n_square    		# Appeler la fonction pour vérifier la colonne
    lw $t0 4($sp)			#On restaure $t0 avant de continuer
    addi $t0, $t0, 1      		#Incrémenter le compteur de colonnes
    beq $v1, 0, invalid_s		#Si v1 = 0, carré invalide donc branchement
    j check_squares_loop  		#Revenir au début de la boucle
    
check_squares_done:
    lw $ra 0($sp)	#On restaure le registre de retour
    lw $a0 8($sp)	#On restaure $a0
    addi $sp, $sp, 12	#On supprime l'espace alloué
    li $v1,1		#Toute les lignes sont valide
    jr $ra              #Retourner
invalid_s:
    lw $ra 0($sp)	#On restaure le registre de retour
    lw $a0 8($sp)	#On restaure $a0
    addi $sp, $sp, 12	#On supprime l'espace alloué
    li $v1,0 		#Une ligne est invalide
    jr $ra              #Retourner
#----Fonction check_sudoku----
#Objectif : verifier la validité d'un sudoku (case vide compris, important pour la résolution)
#Registre utilisés : $v1,$v0,$a0
check_sudoku:
    addi $sp, $sp, -8    #Alloué de l'espace sur la pile episode 1545
    sw $a0, 0($sp)	 #Sauvegarder $a0 sur la pile
    sw $ra, 4($sp)	 #Sauvegarder le registre de retour

    # Vérifier les lignes
    jal check_rows			#Fonction vérfiant toutes les lignes
    beq $v1, $zero, invalid_sudoku	#Si une ligne est invalide, aller à invalid_sudoku

    # Vérifier les colonnes
    jal check_columns			#Fonction vérfiant toutes les colonnes
    beq $v1, $zero, invalid_sudoku  	#Si une colonne est invalide, aller à invalid_sudoku

    # Vérifier les carrés
    jal check_squares			#Fonction vérfiant toutes les carrés
    beq $v1, $zero, invalid_sudoku  	#Si un carré est invalide, aller à invalid_sudoku

    # Si tout est valide
    li $v0, 1                     #Indiquer que la grille est valide
    j end_check_sudoku

invalid_sudoku:
    li $v0, 0                     #Indiquer que la grille est invalide

end_check_sudoku:
    lw $a0, 0($sp)                #Restaurer  $a0
    lw $ra, 4($sp)                #Restaurer le registre de retour
    addi $sp, $sp, 8              #On supprime l'espace alloué
    jr $ra                        #Retourner
#------Fonction solve_sudoku-----
#Objectif : résoudre un sudoku par bruteforce (basé sur le pseudo-code données dans le moodle
#	    de la SAE
#Registre utilisés : $s[0-4]
solve_sudoku:
    add $sp, $sp, -24       #Sauvegarder les registres sur la pile
    sw $ra, 16($sp)         #Sauvegarder le retour
    sw $s0, 12($sp)         #Sauvegarder $s0
    sw $s1, 8($sp)          #Sauvegarder $s1
    sw $s2, 4($sp)          #Sauvegarder $s2
    sw $s3, 0($sp)          #Sauvegarder $s3
    sw $s4, 20($sp)	    #Sauvegarder $s34
    
    #Trouver une case vide dans la grille
    la $s0, grille          #Charger l'adresse de la grille
    li $s1, 0               #Index pour parcourir la grille
    li $s2, 81              #Nombre total de cases dans la grille
find_empty:
    bge $s1, $s2, no_empty  #Si toutes les cases sont parcourues, pas de case vide
    lb $t0, 0($s0)          #Charger la valeur de la case courante
    beq $t0, $zero, found_empty  # Si la case est vide, brancher à found_empty
    addi $s0, $s0, 1        #Passer à la case suivante
    addi $s1, $s1, 1	    #On incrémente l'index
    j find_empty

found_empty:
    #Essayer chaque chiffre de 1 à 9 dans cette case
    li $s3, 1               #Initialiser le chiffre à essayer (1 à 9)

try_numbers:
    bgt $s3, 9, backtrack   #Si tous les chiffres ont été essayés, backtrack
    sb $s3, 0($s0)          #Placer le chiffre dans la case

    #Vérifier si la grille est valide après l'insertion
    jal check_sudoku
    beq $v0, 1, continue_solving  #Si valide, continuer à résoudre

    #Si invalide, essayer le chiffre suivant
    sb $zero, 0($s0) 
    addi $s3, $s3, 1        #Incrémenter le chiffre à essayer
    j try_numbers

continue_solving:
    #Appeler solve_sudoku récursivement pour résoudre les cases suivantes
    jal solve_sudoku
    sb $zero, 0($s0) #Si on en est là, il y'a eu backtracking,il faut alors reset la case pour essayer un autre chiffre
    addi $s3, $s3, 1  #Incrémenter le chiffre à essayer
    #Continuer à essayer d'autres chiffres après avoir affiché la solution
    j try_numbers

display_solution:
    li $v0,4		     #Afficher le message "Solution" avec le code 4
    la $a0,msg_solution	     #On charge l'adresse du string
    syscall		     #Affichage réalisé
    li $v0,1		     #Meme processus mais pour un integer
    move $a0,$s4
    syscall
    jal addNewLine	     #Ajouter une nouvelle ligne			
    jal displayGrille        #Afficher la grille
    jal addNewLine           #Ajouter une nouvelle ligne
    j backtrack              #Retourner à la rétro-propagation

backtrack:
    sb $zero, 0($s0)    #Réinitialiser la case vide avant de revenir
    lw $ra, 16($sp)     #Restaurer les registres depuis la pile
    lw $s0, 12($sp)	#Restaurer $s0
    lw $s1, 8($sp)	#Restaurer $s1
    lw $s2, 4($sp)	#Restaurer $s2
    lw $s3, 0($sp)	#Restaurer $s3
    lw $s4, 20($sp)	#Restaurer $s4
    addi $sp, $sp, 24	#Supprimer l'espace alloué dans la pile
    addi $s4,$s4,1      #On incrémente le nombre de solution trouvé
    jr $ra                 # Retourner

no_empty:
    # Si aucune case vide n'est trouvée, la grille est résolue
    li $v0, 1              # Indiquer qu'une solution a été trouvée
    jal display_solution
    j return

return:
    # Restaurer les registres et retourner
    lw $ra, 16($sp)        # Restaurer le retour
    lw $s0, 12($sp)        # Restaurer $s0
    lw $s1, 8($sp)         # Restaurer $s1
    lw $s2, 4($sp)         # Restaurer $s2
    lw $s3, 0($sp)         # Restaurer $s3
    sw $s4, 20($sp)	    # Sauvegarder $s34
    addi $sp, $sp, 24
    jr $ra                 # Retourner

###################################################################
#Remarques : 							  #
#-Suppresion des fonctions GetModulo,LoadFile			  #
#  et CloseFile, nous n'avons pas eu besoin de les utiliser	  #
#-Pour DisplaySudoku et zeroToSpace j'ai modifié directement	  #
#  displayGrille,ça me semblait plus simple			  #	
#-J'ai améliorer l'affichage du résultat demandé, la grille	  #
# initiale ainsi que les solutions sont affichées en matrices	  #
###################################################################




exit: 
    li $v0, 10
    syscall
