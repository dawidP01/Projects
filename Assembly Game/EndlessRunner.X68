*-----------------------------------------------------------
* Author:           Dawid Pionk
* Date:             24/02/2023
* Title of Game:    Space Invaders 
*-----------------------------------------------------------
    ORG    $1000
START:
;COLOURS
WHITE       EQU         $00FFFFFF
RED         EQU         $000000FF
BLACK       EQU         $00000000
BLUE        EQU         $00FF0000
GREEN       EQU         $0000FF00
ORANGE      EQU         $00005AFF
GREY        EQU         $00808080

;KEYS
SPACEBAR    EQU         $20         ; Spacebar ASCII Keycode
ESCAPE      EQU         27         ; Escape ASCII Keycode
RIGHT_KEY   EQU         68
LEFT_KEY    EQU         $41
UP_KEY      EQU         $57
DOWN_KEY    EQU         $53
ENTER       EQU         13
E           EQU         69
Q           EQU         $51
R           EQU         82

; Other
TC_SCREEN   EQU         33          ; Screen size information trap code
TC_S_SIZE   EQU         0           ; Places 0 in D1.L to retrieve Screen width and height in D1.L
                                    ; First 16 bit Word is screen Width and Second 16 bits is screen Height
TC_KEY_CODE EQU         19          ; Check for pressed keys

; Branches to init section
    BRA INITIALISE
    
;------------------------------------------------------
;------------------------------------------------------
;    INITLIALISATION OF GAME
;------------------------------------------------------
;------------------------------------------------------
INITIALISE:
    ;Screen Size
    MOVE.B  #TC_SCREEN,       D0         
    MOVE.L  #TC_S_SIZE,       D1       
    TRAP    #15                     
    MOVE.W  D1,               SCREEN_HEIGHT   
    SWAP    D1                      
    MOVE.W  D1,               SCREEN_WIDTH 
    
    ; Place Player centre of screen
    CLR.L   D1                      
    MOVE.L  #25,              START_X        
    MOVE.L  START_X,          PLAYER_X

    CLR.L   D1                     
    MOVE.W  SCREEN_HEIGHT,    D1          
    DIVU    #2,               D1          
    MOVE.L  D1,               PLAYER_Y   
    
    ; INITIALISE OBSTACLES
    CLR.L                     D1
    MOVE.L  #400,             D1          
    MOVE.L  D1,               OBSTACLE1_X 
    MOVE.L  D1,               OBSTACLE2_X
    

    CLR.L   D1                      
    MOVE.W  SCREEN_HEIGHT,    D1        
    DIVU    #2,               D1          
    MOVE.L  D1,               OBSTACLE1_Y
    DIVU    #2,               D1
    MOVE.L  D1,               OBSTACLE2_Y 
    
;   init HEALTH and SCORE
    MOVE.L  #100,             HEALTH
    MOVE.L  #0,               SCORE

;   INIT enemies
    MOVE.L  #800,             ENEMY1_X
    MOVE.L  #800,             ENEMY2_X

    CLR.L   D1                           
    MOVE.W  SCREEN_HEIGHT,    D1       
    DIVU    #2,               D1          
    MOVE.L  D1,               ENEMY2_Y
    DIVU    #2,               D1
    MOVE.L  D1,               ENEMY1_Y

****INIT BULLETS*****
    MOVE.L  #3,               BULLETS_LEFT
    MOVE.L  #0,               PLAYER_BULLET1_FIRED             
    MOVE.L  #0,               PLAYER_BULLET2_FIRED
    MOVE.L  #0,               PLAYER_BULLET3_FIRED
    MOVE.L  #0,               ENEMY1_BULLET_FIRED
    MOVE.L  #0,               ENEMY2_BULLET_FIRED
    
; INITS THE BULLETS X AND Y POSITIONS AT THE START
    MOVE.L  ENEMY1_Y,         D1
    MOVE.L  ENEMY1_X,         ENEMY1_BULLET_X
    MOVE.L  ENEMY2_Y,         D2
    MOVE.L  ENEMY2_X,         ENEMY2_BULLET_X
    MOVE.L  #ENEMY_H_INIT,    D3
    DIVU    #2,               D3
    ADD.L   D3,               D1
    ADD.L   D3,               D2
    MOVE.L  D1,               ENEMY1_BULLET_Y
    MOVE.L  D2,               ENEMY2_BULLET_Y
    
; SETS THE DELAY OF THE TIMER   
    MOVE.L  #6,               TIMER_DELAY         
; INIT SOUNDS
    JSR     STOP_MUSIC
    JSR     SHOOT_SOUND_LOAD
    JSR     EXPLOSION_SOUND_LOAD
    JSR     DEATH_SOUND_LOAD
    JSR     DAMAGE_SOUND_LOAD
    JSR     HEAL_SOUND_LOAD
    JSR     MUSIC_LOAD
    JSR     PLAY_MUSIC
    
; INITS ENEMIES Y DIRECTIONS
    MOVE.L  #0,               ENEMY1_Y_DIRECTION
    MOVE.L  #0,               ENEMY2_Y_DIRECTION
; Opens up the title menu
    BRA     TITLE_MENU_INIT
   
;------------------------------------------------------   
;------------------------------------------------------
;           TITLE MENU SECTION
;------------------------------------------------------
;------------------------------------------------------ 

; Inits the title menu screen
TITLE_MENU_INIT:
    BSR     DRAW_MENU
    BSR     DRAW_MENU_INSTRUCTIONS
    BRA     TITLE_LOOP

;   Draws the titlebox and continue text at the bottom
DRAW_MENU:  
    MOVE.L  #220,       D1
    MOVE.L  #65,        D2
    MOVE.L  #380,       D3
    MOVE.L  #100,       D4    
    MOVE.B  #87,        D0
    TRAP    #15
    MOVE.B  #11,        D0
    MOVE.W  #$1F05,     D1 
    TRAP    #15
    LEA     TITLE,      A1
    MOVE    #14,        D0
    TRAP    #15
    
;BEGIN INSTRUCTION
    MOVE.B  #11,                D0
    MOVE.W  #$1A19,             D1 
    TRAP    #15
    LEA     START_INSTRUCTION,  A1
    MOVE    #14,                D0
    TRAP    #15
    RTS

; Shows the instructions for the game
DRAW_MENU_INSTRUCTIONS:
    MOVE.L  #11,                D0
    MOVE.L  #$000B,             D1
    TRAP    #15
    LEA     TITLE_INSTRUCTIONS, A1
    MOVE.L  #13,                D0
    TRAP    #15
    RTS

; Sets up the loop for the users input to start the game
TITLE_LOOP:
    BSR TITLE_INPUT
    BRA TITLE_LOOP

; Takes input in from the keyboard
TITLE_INPUT:
    CLR.L   D1
    CLR.L   D2
    MOVE.B  #19,        D0
    TRAP    #15
    MOVE.B  D1,         D2
    CMP.B   #0,         D2
    BEQ     PROCESS_TITLE_INPUT
    TRAP    #15
    CMP.B   #$FF,       D1
    BEQ     PROCESS_TITLE_INPUT
    RTS

; Checks whether the user pressed enter
PROCESS_TITLE_INPUT:
    MOVE.B  D2,             CURRENT_KEY
    CMP.B   #ENTER,         CURRENT_KEY
    BEQ     QUIT_TITLE
    RTS

; Quits the title screen
QUIT_TITLE:
    BRA     GAME_LOOP
;------------------------------------------------------   
;------------------------------------------------------
;           MAIN GAME SECTION
;------------------------------------------------------
;------------------------------------------------------

; Main loop for the game
GAME_LOOP:  
    JSR     SET_TIMER
    JSR     DRAW
    JSR     COLLISION_CHECKER
    JSR     UPDATE
    JSR     INPUT
    JSR     CHECK_HEALTH
    JSR     TIMER
    BRA     GAME_LOOP
    

;           DRAW SECTION BELOW
;------------------------------------------------------
DRAW:
    JSR     SET_PEN_BLACK
    JSR     CLEAR_SCREEN
    JSR     DRAW_HEALTH
    JSR     DRAW_SCORE
    JSR     DRAW_BULLET_COUNT
    JSR     DRAW_LINE
    JSR     DRAW_PLAYER
    JSR     DRAW_ENEMY1
    JSR     DRAW_ENEMY2
    JSR     DRAW_OBSTACLE1
    JSR     DRAW_OBSTACLE2
    JSR     CHECK_ENEMY_BULLETS
    RTS
****************DRAW TOPBAR************************
; Draws Health
DRAW_HEALTH:
    CLR.L   D0
    CLR.L   D1
    MOVE.B  #11,            D0
    MOVE.W  #$4001,         D1
    TRAP    #15
    LEA     HEALTH_STRING,  A1
    MOVE.B  #14,            D0
    TRAP    #15
    CLR.L   D0
    CLR.L   D1
    MOVE.B  #3,             D0
    MOVE.L  HEALTH,         D1
    TRAP    #15 
    RTS

; Draws Score
DRAW_SCORE:
    MOVE.B  #11,            D0
    MOVE.W  #$0601,         D1
    TRAP    #15
    LEA     SCORE_STRING,   A1
    MOVE.B  #14,            D0
    TRAP    #15
    CLR.L   D1
    MOVE.B  #3,             D0
    MOVE.L  SCORE,          D1
    TRAP    #15 
    RTS

; Shows the amount of bullets the player has left
DRAW_BULLET_COUNT:
    MOVE.B  #11,                  D0
    MOVE.W  #$2001,               D1
    TRAP    #15
    LEA     BULLETS_LEFT_STRING,  A1
    MOVE.B  #14,                  D0
    TRAP    #15
    CLR.L   D1
    MOVE.B  #3,                   D0
    MOVE.L  BULLETS_LEFT,         D1
    TRAP    #15 
    RTS

; Draws a dividing line between the topbar and game
DRAW_LINE:
    JSR     SET_PEN_WHITE
    MOVE.L  #84,                D0
    MOVE.L  #0,                 D1
    MOVE.L  #50,                D2
    MOVE.L  #800,               D3
    MOVE.L  #50,                D4
    TRAP    #15
    RTS

;draws player
DRAW_PLAYER:
    JSR     SET_PEN_BLUE
    MOVE.L  #WHITE,         D1
    MOVE.B  #80,            D0
    TRAP    #15 
    MOVE.L  PLAYER_X,       D1
    MOVE.L  PLAYER_Y,       D2
    MOVE.L  PLAYER_X,       D3
    ADD.L   #PLAYER_W_INIT, D3
    MOVE.L  PLAYER_Y,       D4 
    ADD.L   #PLAYER_H_INIT, D4
    MOVE.B  #87,            D0
    TRAP    #15
    RTS

; Draws players first bullet 
DRAW_PLAYER_BULLET1:
    JSR         PLAY_SHOOT_SOUND
    JSR         SET_PEN_GREEN
    MOVE.L      PLAYER_X,            D1
    MOVE.L      PLAYER_Y,            D2
    MOVE.L      D1,                  PLAYER_BULLET1_X
    MOVE.L      D2,                  PLAYER_BULLET1_Y
    MOVE.L      PLAYER_BULLET1_X,    D1
    MOVE.L      PLAYER_BULLET1_Y,    D2
    MOVE.L      PLAYER_BULLET1_X,    D3
    MOVE.L      PLAYER_BULLET1_Y,    D4
    ADD.L       #BULLET_W_INIT,      D3
    ADD.L       #BULLET_H_INIT,      D4
    MOVE.B      #87,                 D0
    TRAP        #15
    MOVE.L      #1,                  PLAYER_BULLET1_FIRED
    RTS

; Draws players second bullet    
DRAW_PLAYER_BULLET2:
    JSR         PLAY_SHOOT_SOUND
    JSR         SET_PEN_GREEN
    MOVE.L      PLAYER_X,            D1
    MOVE.L      PLAYER_Y,            D2
    MOVE.L      D1,                  PLAYER_BULLET2_X
    MOVE.L      D2,                  PLAYER_BULLET2_Y
    MOVE.L      PLAYER_BULLET2_X,    D1
    MOVE.L      PLAYER_BULLET2_Y,    D2
    MOVE.L      PLAYER_BULLET2_X,    D3
    MOVE.L      PLAYER_BULLET2_Y,    D4
    ADD.L       #BULLET_W_INIT,      D3
    ADD.L       #BULLET_H_INIT,      D4
    MOVE.B      #87,                 D0
    TRAP        #15
    MOVE.L      #1,                  PLAYER_BULLET2_FIRED
    RTS

; Draws players third bullet
DRAW_PLAYER_BULLET3:
    JSR         PLAY_SHOOT_SOUND
    JSR         SET_PEN_GREEN
    MOVE.L      PLAYER_X,            D1
    MOVE.L      PLAYER_Y,            D2
    MOVE.L      D1,                  PLAYER_BULLET3_X
    MOVE.L      D2,                  PLAYER_BULLET3_Y
    MOVE.L      PLAYER_BULLET3_X,    D1
    MOVE.L      PLAYER_BULLET3_Y,    D2
    MOVE.L      PLAYER_BULLET3_X,    D3
    MOVE.L      PLAYER_BULLET3_Y,    D4
    ADD.L       #BULLET_W_INIT,      D3
    ADD.L       #BULLET_H_INIT,      D4
    MOVE.B      #87,                 D0
    TRAP        #15
    MOVE.L      #1,                  PLAYER_BULLET3_FIRED
    RTS


    
        ****ENEMIES****
        
; Draws the first enemy
DRAW_ENEMY1:
    JSR     SET_PEN_ORANGE
    MOVE.L  ENEMY1_X,       D1
    MOVE.L  ENEMY1_Y,       D2
    MOVE.L  ENEMY1_X,       D3
    ADD.L   #ENEMY_W_INIT,  D3
    MOVE.L  ENEMY1_Y,       D4 
    ADD.L   #ENEMY_H_INIT,  D4
    MOVE.B  #87,            D0
    TRAP    #15
    RTS

; Draws the second Enemy
DRAW_ENEMY2: 
    JSR     SET_PEN_ORANGE
    MOVE.L  ENEMY2_X,       D1
    MOVE.L  ENEMY2_Y,       D2
    MOVE.L  ENEMY2_X,       D3
    ADD.L   #ENEMY_W_INIT,  D3
    MOVE.L  ENEMY2_Y,       D4 
    ADD.L   #ENEMY_H_INIT,  D4
    MOVE.B  #87,            D0
    TRAP    #15
    RTS
    
; Draws the first enemies bullet
DRAW_ENEMY1_BULLET:
    JSR         SET_PEN_RED
    MOVE.L      ENEMY1_X,            D1
    MOVE.L      ENEMY1_Y,            D2
    MOVE.L      ENEMY1_BULLET_X,     D1
    MOVE.L      ENEMY1_BULLET_Y,     D2
    MOVE.L      ENEMY1_BULLET_X,     D3
    MOVE.L      ENEMY1_BULLET_Y,     D4
    ADD.L       #BULLET_W_INIT,      D3
    ADD.L       #BULLET_H_INIT,      D4
    MOVE.B      #87,                 D0
    TRAP        #15
    RTS
 
; Draws enemies second bullet   
DRAW_ENEMY2_BULLET:
    JSR         SET_PEN_RED
    MOVE.L      ENEMY2_BULLET_X,     D1
    MOVE.L      ENEMY2_BULLET_Y,     D2
    MOVE.L      ENEMY2_BULLET_X,     D3
    MOVE.L      ENEMY2_BULLET_Y,     D4
    ADD.L       #BULLET_W_INIT,      D3
    ADD.L       #BULLET_H_INIT,      D4
    MOVE.B      #87,                 D0
    TRAP        #15
    RTS

; Calls the draw enemy bullets methods
DRAW_ENEMY_BULLETS:
    BSR         DRAW_ENEMY1_BULLET
    BSR         DRAW_ENEMY2_BULLET
    MOVE.L      #1,                 ENEMY1_BULLET_FIRED
    MOVE.L      #1,                 ENEMY2_BULLET_FIRED
    RTS
    
; Checks whether enemy bullets were fired already
CHECK_ENEMY_BULLETS:
    MOVE.L     ENEMY1_BULLET_FIRED,  D1
    CMP        #0,                   D1
    BEQ        CHECK_ENEMY_BULLET2
    RTS
    CHECK_ENEMY_BULLET2:
        MOVE.L     ENEMY2_BULLET_FIRED,  D1
        CMP        #0,                   D1
        BEQ        DRAW_ENEMY_BULLETS
        RTS

        ****OBSTACLES****
; Draws the first obstacle
DRAW_OBSTACLE1:        
    JSR     SET_PEN_GREY
    MOVE.L  OBSTACLE1_X,        D1
    MOVE.L  OBSTACLE1_Y,        D2
    MOVE.L  OBSTACLE1_X,        D3
    ADD.L   #OBSTACLE_W_INIT,   D3
    MOVE.L  OBSTACLE1_Y,        D4 
    ADD.L   #OBSTACLE_H_INIT,   D4
    MOVE.B  #87,                D0
    TRAP    #15
    RTS

; Draws the Second obstacle
DRAW_OBSTACLE2:        
    JSR     SET_PEN_GREY
    MOVE.L  OBSTACLE2_X,        D1
    MOVE.L  OBSTACLE2_Y,        D2
    MOVE.L  OBSTACLE2_X,        D3
    ADD.L   #OBSTACLE_W_INIT,   D3
    MOVE.L  OBSTACLE2_Y,        D4 
    ADD.L   #OBSTACLE_H_INIT,   D4
    MOVE.B  #87,                D0
    TRAP    #15
    RTS

        ****OTHER STUFF****
; Below set the fill and pen colours
SET_PEN_BLACK:
    CLR.L       D1
    MOVE.L      #BLACK,         D1
    MOVE.B      #80,            D0
    TRAP        #15
    MOVE.B      #81,            D0
    TRAP        #15
    RTS
    
SET_PEN_RED:
    CLR.L       D1
    MOVE.L      #RED,           D1
    MOVE.B      #80,            D0
    TRAP        #15
    MOVE.B      #81,            D0
    TRAP        #15
    RTS
    
SET_PEN_BLUE:
    CLR.L       D1
    MOVE.L      #BLUE,          D1
    MOVE.B      #80,            D0
    TRAP        #15
    MOVE.B      #81,            D0
    TRAP        #15
    RTS
    
SET_PEN_GREEN:
    CLR.L       D1
    MOVE.L      #GREEN,         D1
    MOVE.B      #80,            D0
    TRAP        #15
    MOVE.B      #81,            D0
    TRAP        #15
    RTS
    
SET_PEN_ORANGE:
    CLR.L       D1
    MOVE.L      #ORANGE,        D1
    MOVE.B      #80,            D0
    TRAP        #15
    MOVE.B      #81,            D0
    TRAP        #15
    RTS

SET_PEN_GREY:
    CLR.L       D1
    MOVE.L      #GREY,          D1
    MOVE.B      #80,            D0
    TRAP        #15
    MOVE.B      #81,            D0
    TRAP        #15
    RTS

SET_PEN_WHITE:
    CLR.L       D1
    MOVE.L      #WHITE,         D1
    MOVE.B      #80,            D0
    TRAP        #15
    MOVE.B      #81,            D0
    TRAP        #15
    RTS

SET_PEN_TEXT_COLOUR:
    CLR.L       D1
    MOVE.L      #WHITE,         D1
    MOVE.B      #80,            D0
    TRAP        #15
    MOVE.L      #BLACK,         D1
    MOVE.B      #81,            D0
    TRAP        #15
    RTS      
    
; Empties the screen
CLEAR_SCREEN:  
    MOVE.L      #92,            D0
    MOVE.L      #17,            D1
    TRAP        #15
    MOVE.B      #94,            D0
    TRAP        #15
    MOVE.B	    #11,            D0
	MOVE.W	    #$FF00,         D1
    TRAP        #15
    RTS
  
;                   INPUT SECTION
;-------------------------------------------------
; Checks the users input
INPUT:
    ; Process Input
    CLR.L   D1
    MOVE.B  #19,        D0
    TRAP    #15
    MOVE.B  D1,         D2
    CMP.B   #0,         D2
    BEQ     PROCESS_INPUT
    TRAP    #15
    ; Check if key still pressed
    CMP.B   #$FF,       D1
    BEQ     PROCESS_INPUT
    RTS

; Checks if the input matched one of the commands
PROCESS_INPUT:
    MOVE.B  D2,             CURRENT_KEY
    CMP.B   #ESCAPE,        CURRENT_KEY
    BEQ     PAUSE_MENU_INIT
    
    CMP.B   #UP_KEY,        CURRENT_KEY
    BEQ     PLAYER_UP
    
    CMP.B   #DOWN_KEY,      CURRENT_KEY
    BEQ     PLAYER_DOWN
    
    CMP.B   #SPACEBAR,      CURRENT_KEY
    BEQ     SHOOT
    
    CMP.B   #Q,             CURRENT_KEY
    BEQ     CHECK_HEAL
    
    BRA     IDLE


            ****PLAYER*****
PLAYER_UP:
    MOVE.L      PLAYER_Y,       D1
    CMP.L       #58,             D1
    BGT         MOVE_UP
    RTS
    MOVE_UP:
        ADD.L   #-10,            PLAYER_Y
        RTS
        
PLAYER_DOWN:
    MOVE.L      PLAYER_Y,       D1
    CMP.L       #465,           D1
    BLT         MOVE_DOWN
    RTS
    MOVE_DOWN:
        ADD.L   #10,           PLAYER_Y
        RTS

;Player Shoots
SHOOT:
    MOVE.L  PLAYER_BULLET1_FIRED,   D1
    MOVE.L  PLAYER_BULLET2_FIRED,   D2
    MOVE.L  PLAYER_BULLET3_FIRED,   D3
    CMP #0,                         D1
    BEQ DRAW_PLAYER_BULLET1
    CMP #0,                         D2
    BEQ DRAW_PLAYER_BULLET2
    CMP #0,                         D3
    BEQ DRAW_PLAYER_BULLET3
    RTS

;Checks if player can heal
CHECK_HEAL:
    MOVE.L  SCORE,                  D1
    CMP #999,                       D1
    BGT HEAL
    RTS

;Player Heals
HEAL:
    JSR     PLAY_HEAL_SOUND
    SUB.L   #1000,                  SCORE
    ADD.L   #10,                    HEALTH
    RTS             
    
; The player does nothing
IDLE:
    RTS
;      COLLISSION SECTION  (NOT FINISHED)
;-------------------------------------------------
COLLISION_CHECKER:
    JSR OBSTACLE1_COLLISION
    JSR OBSTACLE2_COLLISION
    
    JSR PLAYER_BULLET1_COLLSION_E1
    JSR PLAYER_BULLET2_COLLSION_E1
    JSR PLAYER_BULLET3_COLLSION_E1
    
    JSR PLAYER_BULLET1_COLLSION_E2
    JSR PLAYER_BULLET2_COLLSION_E2
    JSR PLAYER_BULLET3_COLLSION_E2
    
    JSR ENEMY1_BULLET_COLLISION
    JSR ENEMY2_BULLET_COLLISION
    RTS

***********OBSTACLE COLLISION****************

; Checks for players collisions with obstacle 1
OBSTACLE1_COLLISION:    
    MOVE.L  OBSTACLE1_X,            D1
    MOVE.L  PLAYER_X,               D2
    MOVE.L  #PLAYER_W_INIT,         D3
    ADD.L   D3,                     D2
    CMP     D2,                     D1
    BLT     O1_CHECK_X2
    RTS
    O1_CHECK_X2:
        MOVE.L  #OBSTACLE_W_INIT,   D3
        MOVE.L  PLAYER_X,           D2
        ADD.L   D3,                 D1
        CMP     D2,                 D1
        BGE     O1_CHECK_Y1
        RTS
    O1_CHECK_Y1:
        MOVE.L  PLAYER_Y,           D1
        MOVE.L  OBSTACLE1_Y,        D2
        MOVE.L  #OBSTACLE_H_INIT,   D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     O1_CHECK_Y2
        RTS
    O1_CHECK_Y2:
        MOVE.L  PLAYER_Y,           D1
        MOVE.L  OBSTACLE1_Y,        D2
        MOVE.L  #PLAYER_H_INIT,     D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     OBSTACLE1_COLLISION_DETECTED
        RTS

    
; Checks for players collisions with obstacle 2
OBSTACLE2_COLLISION:  
    MOVE.L  OBSTACLE2_X,            D1
    MOVE.L  PLAYER_X,               D2
    MOVE.L  #PLAYER_W_INIT,         D3
    ADD.L   D3,                     D2
    CMP     D2,                     D1
    BLT     O2_CHECK_X2
    RTS
    O2_CHECK_X2:
        MOVE.L  #OBSTACLE_W_INIT,   D3
        MOVE.L  PLAYER_X,           D2
        ADD.L   D3,                 D1
        CMP     D2,                 D1
        BGE     O2_CHECK_Y1
        RTS
    O2_CHECK_Y1:
        MOVE.L  PLAYER_Y,           D1
        MOVE.L  OBSTACLE2_Y,        D2
        MOVE.L  #OBSTACLE_H_INIT,   D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     O2_CHECK_Y2
        RTS
    O2_CHECK_Y2:
        MOVE.L  PLAYER_Y,           D1
        MOVE.L  OBSTACLE2_Y,        D2
        MOVE.L  #PLAYER_H_INIT,     D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     OBSTACLE2_COLLISION_DETECTED
        RTS

; Takes away players health after an obstacle collision
OBSTACLE1_COLLISION_DETECTED:  
    JSR      PLAY_DAMAGE_SOUND
    CLR.L    D3
    MOVE.L   HEALTH,            D3
    SUB.L    #10,               D3
    MOVE.L   D3,                HEALTH
    JSR      RESET_OBSTACLE1
    RTS
OBSTACLE2_COLLISION_DETECTED:  
    JSR      PLAY_DAMAGE_SOUND
    CLR.L    D3
    MOVE.L   HEALTH,            D3
    SUB.L    #10,               D3
    MOVE.L   D3,                HEALTH
    JSR      RESET_OBSTACLE2
    RTS
        
***********PLAYER BULLET COLLISION****************

; Checks for player bullet 1 collision with enemy 1 
PLAYER_BULLET1_COLLSION_E1:
    MOVE.L  PLAYER_BULLET1_X,       D1
    MOVE.L  #BULLET_W_INIT,         D3
    MOVE.L  ENEMY1_X,               D2
    ADD.L   D3,                     D1
    CMP     D2,                     D1
    BGE     PB1E1_CHECK_X2
    RTS
    PB1E1_CHECK_X2:
        MOVE.L  PLAYER_BULLET1_X,   D1      
        MOVE.L  ENEMY1_X,           D2
        MOVE.L  #ENEMY_W_INIT,      D3
        ADD.L   D3,                 D2
        CMP     D2,                 D1
        BLT     PB1E1_CHECK_Y1
        RTS 
    PB1E1_CHECK_Y1:
        MOVE.L  ENEMY1_Y,           D1
        MOVE.L  PLAYER_BULLET1_Y,   D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     PB1E1_CHECK_Y2
        RTS
    PB1E1_CHECK_Y2:
        MOVE.L  ENEMY1_Y,           D1
        MOVE.L  PLAYER_BULLET1_Y,   D2
        MOVE.L  #ENEMY_H_INIT,      D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     PB1_ENEMY1_COLLISION
        RTS

; Checks for player bullet 2 collision with enemy 1         
PLAYER_BULLET2_COLLSION_E1:
    MOVE.L  PLAYER_BULLET2_X,       D1
    MOVE.L  #BULLET_W_INIT,         D3
    MOVE.L  ENEMY1_X,               D2
    ADD.L   D3,                     D1
    CMP     D2,                     D1
    BGE     PB2E1_CHECK_X2
    RTS
    PB2E1_CHECK_X2:
        MOVE.L  PLAYER_BULLET2_X,   D1   
        MOVE.L  ENEMY1_X,           D2
        MOVE.L  #ENEMY_W_INIT,      D3
        ADD.L   D3,                 D2
        CMP     D2,                 D1
        BLT     PB2E1_CHECK_Y1
        RTS 
    PB2E1_CHECK_Y1:
        MOVE.L  ENEMY1_Y,           D1
        MOVE.L  PLAYER_BULLET2_Y,   D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     PB2E1_CHECK_Y2
        RTS
    PB2E1_CHECK_Y2:
        MOVE.L  ENEMY1_Y,           D1
        MOVE.L  PLAYER_BULLET2_Y,   D2
        MOVE.L  #ENEMY_H_INIT,      D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     PB2_ENEMY1_COLLISION
        RTS

; Checks for player bullet 3 collision with enemy 1 
PLAYER_BULLET3_COLLSION_E1:
    MOVE.L  PLAYER_BULLET3_X,       D1
    MOVE.L  #BULLET_W_INIT,         D3
    MOVE.L  ENEMY1_X,               D2
    ADD.L   D3,                     D1
    CMP     D2,                     D1
    BGE     PB3E1_CHECK_X2
    RTS
    PB3E1_CHECK_X2:
        MOVE.L  PLAYER_BULLET3_X,   D1      
        MOVE.L  ENEMY1_X,           D2
        MOVE.L  #ENEMY_W_INIT,      D3
        ADD.L   D3,                 D2
        CMP     D2,                 D1
        BLT     PB3E1_CHECK_Y1
        RTS 
    PB3E1_CHECK_Y1:
        MOVE.L  ENEMY1_Y,           D1
        MOVE.L  PLAYER_BULLET3_Y,   D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     PB3E1_CHECK_Y2
        RTS
    PB3E1_CHECK_Y2:
        MOVE.L  ENEMY1_Y,           D1
        MOVE.L  PLAYER_BULLET3_Y,   D2
        MOVE.L  #ENEMY_H_INIT,      D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     PB3_ENEMY1_COLLISION
        RTS
    
; Checks for player bullet 1 collision with enemy 2 
PLAYER_BULLET1_COLLSION_E2: 
    MOVE.L  PLAYER_BULLET1_X,       D1
    MOVE.L  #BULLET_W_INIT,         D3
    MOVE.L  ENEMY2_X,               D2
    ADD.L   D3,                     D1
    CMP     D2,                     D1
    BGE     PB1E2_CHECK_X2
    RTS
    PB1E2_CHECK_X2:
        MOVE.L  PLAYER_BULLET1_X,   D1      
        MOVE.L  ENEMY2_X,           D2
        MOVE.L  #ENEMY_W_INIT,      D3
        ADD.L   D3,                 D2
        CMP     D2,                 D1
        BLT     PB1E2_CHECK_Y1
        RTS 
    PB1E2_CHECK_Y1:
        MOVE.L  ENEMY2_Y,           D1
        MOVE.L  PLAYER_BULLET1_Y,   D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     PB1E2_CHECK_Y2
        RTS
    PB1E2_CHECK_Y2:
        MOVE.L  ENEMY2_Y,           D1
        MOVE.L  PLAYER_BULLET1_Y,   D2
        MOVE.L  #ENEMY_H_INIT,      D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     PB1_ENEMY2_COLLISION
        RTS
        
; Checks for player bullet 2 collision with enemy 2         
PLAYER_BULLET2_COLLSION_E2:
    MOVE.L  PLAYER_BULLET2_X,       D1
    MOVE.L  #BULLET_W_INIT,         D3
    MOVE.L  ENEMY2_X,               D2
    ADD.L   D3,                     D1
    CMP     D2,                     D1
    BGE     PB2E2_CHECK_X2
    RTS
    PB2E2_CHECK_X2:
        MOVE.L  PLAYER_BULLET2_X,   D1      
        MOVE.L  ENEMY2_X,           D2
        MOVE.L  #ENEMY_W_INIT,      D3
        ADD.L   D3,                 D2
        CMP     D2,                 D1
        BLT     PB2E2_CHECK_Y1
        RTS 
    PB2E2_CHECK_Y1:
        MOVE.L  ENEMY2_Y,           D1
        MOVE.L  PLAYER_BULLET2_Y,   D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     PB2E2_CHECK_Y2
        RTS
    PB2E2_CHECK_Y2:
        MOVE.L  ENEMY2_Y,           D1
        MOVE.L  PLAYER_BULLET2_Y,   D2
        MOVE.L  #ENEMY_H_INIT,      D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     PB2_ENEMY2_COLLISION
        RTS
        
; Checks for player bullet 3 collision with enemy 2 
PLAYER_BULLET3_COLLSION_E2:
    MOVE.L  PLAYER_BULLET3_X,       D1
    MOVE.L  #BULLET_W_INIT,         D3
    MOVE.L  ENEMY2_X,               D2
    ADD.L   D3,                     D1
    CMP     D2,                     D1
    BGE     PB3E2_CHECK_X2
    RTS
    PB3E2_CHECK_X2:
        MOVE.L  PLAYER_BULLET3_X,   D1      
        MOVE.L  ENEMY2_X,           D2
        MOVE.L  #ENEMY_W_INIT,      D3
        ADD.L   D3,                 D2
        CMP     D2,                 D1
        BLT     PB3E2_CHECK_Y1
        RTS 
    PB3E2_CHECK_Y1:
        MOVE.L  ENEMY2_Y,           D1
        MOVE.L  PLAYER_BULLET3_Y,   D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     PB3E2_CHECK_Y2
        RTS
    PB3E2_CHECK_Y2:
        MOVE.L  ENEMY2_Y,           D1
        MOVE.L  PLAYER_BULLET3_Y,   D2
        MOVE.L  #ENEMY_H_INIT,      D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     PB3_ENEMY2_COLLISION
        RTS

; A bullet has collided with enemy 1
PB1_ENEMY1_COLLISION:
    JSR     RESET_ENEMY1
    ADD.L   #100,                   SCORE
    JSR     PLAY_EXPLOSION_SOUND
    JSR                             MOVE_BULLET1
    RTS
PB2_ENEMY1_COLLISION:
    JSR     RESET_ENEMY1
    ADD.L   #100,                   SCORE
    JSR     PLAY_EXPLOSION_SOUND
    JSR                             MOVE_BULLET2
    RTS
PB3_ENEMY1_COLLISION:
    JSR     RESET_ENEMY1
    ADD.L   #100,    SCORE
    JSR     PLAY_EXPLOSION_SOUND
    JSR                             MOVE_BULLET3
    RTS
; A bullet has collided with enemy 2
PB1_ENEMY2_COLLISION:
    JSR     RESET_ENEMY2
    ADD.L   #100,    SCORE
    JSR     PLAY_EXPLOSION_SOUND
    JSR                             MOVE_BULLET1
    RTS
PB2_ENEMY2_COLLISION:
    JSR     RESET_ENEMY2
    ADD.L   #100,    SCORE
    JSR     PLAY_EXPLOSION_SOUND
    JSR                             MOVE_BULLET2
    RTS
PB3_ENEMY2_COLLISION:
    JSR     RESET_ENEMY2
    ADD.L   #100,    SCORE
    JSR     PLAY_EXPLOSION_SOUND
    JSR                             MOVE_BULLET3
    RTS
    
***********ENEMY BULLET COLLISION****************
; Checks whether player has collided with enemy 1 bullet
ENEMY1_BULLET_COLLISION:
    MOVE.L  ENEMY1_BULLET_X,        D1
    MOVE.L  PLAYER_X,               D2
    MOVE.L  #PLAYER_W_INIT,         D3
    ADD.L   D3,                     D2
    CMP     D2,                     D1
    BLT     EB1_CHECK_X2
    RTS
    EB1_CHECK_X2:
        MOVE.L  #BULLET_W_INIT,     D3
        MOVE.L  PLAYER_X,           D2
        ADD.L   D3,                 D1
        CMP     D2,                 D1
        BGE     EB1_CHECK_Y1
        RTS
    EB1_CHECK_Y1:
        MOVE.L  PLAYER_Y,           D1
        MOVE.L  ENEMY1_BULLET_Y,    D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     EB1_CHECK_Y2
        RTS
    EB1_CHECK_Y2:
        MOVE.L  PLAYER_Y,           D1
        MOVE.L  ENEMY1_BULLET_Y,    D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     ENEMY1_BULLET_COLLISION_DETECTED
        RTS

; Checks whether player has collided with enemy 2 bullet
ENEMY2_BULLET_COLLISION:
    MOVE.L  ENEMY2_BULLET_X,        D1
    MOVE.L  PLAYER_X,               D2
    MOVE.L  #PLAYER_W_INIT,         D3
    ADD.L   D3,                     D2
    CMP     D2,                     D1
    BLT     EB2_CHECK_X2
    RTS
    EB2_CHECK_X2:
        MOVE.L  #BULLET_W_INIT,     D3
        MOVE.L  PLAYER_X,           D2
        ADD.L   D3,                 D1
        CMP     D2,                 D1
        BGE     EB2_CHECK_Y1
        RTS
    EB2_CHECK_Y1:
        MOVE.L  PLAYER_Y,           D1
        MOVE.L  ENEMY2_BULLET_Y,    D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D2
        CMP.L   D2,                 D1
        BLT     EB2_CHECK_Y2
        RTS
    EB2_CHECK_Y2:
        MOVE.L  PLAYER_Y,           D1
        MOVE.L  ENEMY2_BULLET_Y,    D2
        MOVE.L  #BULLET_H_INIT,     D3
        ADD.L   D3,                 D1
        CMP.L   D2,                 D1
        BGE     ENEMY2_BULLET_COLLISION_DETECTED
        RTS

; Takes away players health after an enemy bullet collision
ENEMY1_BULLET_COLLISION_DETECTED:       
    CLR.L    D3
    MOVE.L   HEALTH,            D3
    SUB.L    #10,               D3
    MOVE.L   D3,                HEALTH
    JSR      PLAY_DAMAGE_SOUND
    JSR      UPDATE_ENEMY1_BULLET_POSITION
    RTS
ENEMY2_BULLET_COLLISION_DETECTED:       
    CLR.L    D3
    MOVE.L   HEALTH,            D3
    SUB.L    #10,               D3
    MOVE.L   D3,                HEALTH
    JSR      PLAY_DAMAGE_SOUND
    JSR      UPDATE_ENEMY2_BULLET_POSITION
    RTS
;               UPDATE SECTION
;-------------------------------------------------
; Calls various update methods
UPDATE:
    BSR UPDATE_PLAYER_BULLET1
    BSR UPDATE_PLAYER_BULLET2
    BSR UPDATE_PLAYER_BULLET3
    BSR UPDATE_OBSTACLE1
    BSR UPDATE_OBSTACLE2
    BSR UPDATE_ENEMY1
    BSR UPDATE_ENEMY2
    BSR UPDATE_ENEMY1_BULLET
    BSR UPDATE_ENEMY2_BULLET
    BSR ADD_BULLETS
    RTS

*****PLAYER BULLETS BELOW************
; Checks whether player bullet 1 has been fired
UPDATE_PLAYER_BULLET1:
    MOVE.L      PLAYER_BULLET1_FIRED,    D1
    CMP         #1,                      D1
    BEQ         CHECK_PLAYER_BULLET1_POSITION
    RTS
    ; Checks if player bullet 1 is off screen
    CHECK_PLAYER_BULLET1_POSITION:
    MOVE.L      PLAYER_BULLET1_X,        D1
    CMP         #700,                    D1
    BLE         UPDATE_PLAYER_BULLET1_POSITION
    BGT         MOVE_BULLET1
    RTS
    
; Checks whether player bullet 2 has been fired    
UPDATE_PLAYER_BULLET2:
    MOVE.L      PLAYER_BULLET2_FIRED,    D1
    CMP         #1,                      D1
    BEQ         CHECK_PLAYER_BULLET2_POSITION
    RTS
    ; Checks if player bullet 2 is off screen
    CHECK_PLAYER_BULLET2_POSITION:
    MOVE.L      PLAYER_BULLET2_X,        D1
    CMP         #700,                    D1
    BLE         UPDATE_PLAYER_BULLET2_POSITION
    BGT         MOVE_BULLET2
    RTS
    
; Checks whether player bullet 3 has been fired    
UPDATE_PLAYER_BULLET3:
    MOVE.L      PLAYER_BULLET3_FIRED,    D1
    CMP         #1,                      D1
    BEQ         CHECK_PLAYER_BULLET3_POSITION
    RTS
    ; Checks if player bullet 3 is off screen
    CHECK_PLAYER_BULLET3_POSITION:
    MOVE.L      PLAYER_BULLET3_X,        D1
    CMP         #700,                    D1
    BLE         UPDATE_PLAYER_BULLET3_POSITION
    BGT         MOVE_BULLET3
    RTS

; Moves player bullet 1 to the right  
UPDATE_PLAYER_BULLET1_POSITION:
    JSR         SET_PEN_GREEN
    ADD.L       #50,                 PLAYER_BULLET1_X
    MOVE.L      PLAYER_BULLET1_X,    D1
    MOVE.L      PLAYER_BULLET1_Y,    D2
    MOVE.L      PLAYER_BULLET1_X,    D3
    MOVE.L      PLAYER_BULLET1_Y,    D4
    ADD.L       #BULLET_W_INIT,      D3
    ADD.L       #BULLET_H_INIT,      D4
    MOVE.B      #87,                 D0
    TRAP        #15
    RTS
    
; Moves player bullet 2 to the right      
UPDATE_PLAYER_BULLET2_POSITION:
    JSR         SET_PEN_GREEN
    ADD.L       #50,                 PLAYER_BULLET2_X
    MOVE.L      PLAYER_BULLET2_X,    D1
    MOVE.L      PLAYER_BULLET2_Y,    D2
    MOVE.L      PLAYER_BULLET2_X,    D3
    MOVE.L      PLAYER_BULLET2_Y,    D4
    ADD.L       #BULLET_W_INIT,      D3
    ADD.L       #BULLET_H_INIT,      D4
    MOVE.B      #87,                 D0
    TRAP        #15
    RTS  
    
; Moves player bullet 3 to the right     
UPDATE_PLAYER_BULLET3_POSITION:
    JSR         SET_PEN_GREEN
    ADD.L       #50,                 PLAYER_BULLET3_X
    MOVE.L      PLAYER_BULLET3_X,    D1
    MOVE.L      PLAYER_BULLET3_Y,    D2
    MOVE.L      PLAYER_BULLET3_X,    D3
    MOVE.L      PLAYER_BULLET3_Y,    D4
    ADD.L       #BULLET_W_INIT,      D3
    ADD.L       #BULLET_H_INIT,      D4
    MOVE.B      #87,                 D0
    TRAP        #15
    RTS

; Moves player bullet 1 out of the way for enemies
MOVE_BULLET1:
    MOVE.L  #0,     PLAYER_BULLET1_FIRED
    MOVE.L  #800,   PLAYER_BULLET1_Y
    MOVE.L  #400,   PLAYER_BULLET1_X
    RTS
 
; Moves player bullet 2 out of the way for enemies   
MOVE_BULLET2:
    MOVE.L  #0,     PLAYER_BULLET2_FIRED
    MOVE.L  #800,   PLAYER_BULLET2_Y
    MOVE.L  #400,   PLAYER_BULLET2_X
    RTS 
  
; Moves player bullet 3 out of the way for enemies  
MOVE_BULLET3:
    MOVE.L  #0,     PLAYER_BULLET3_FIRED
    MOVE.L  #800,   PLAYER_BULLET3_Y
    MOVE.L  #400,   PLAYER_BULLET3_X
    RTS    
     
; Sets the amount of bullets left   
ADD_BULLETS:
    CLR.L   D4
    MOVE.L  PLAYER_BULLET1_FIRED,           D1
    MOVE.L  PLAYER_BULLET2_FIRED,           D2
    MOVE.L  PLAYER_BULLET3_FIRED,           D3
    CMP.L   #0,                             D1
    BEQ     BULLET1_ADD
    CHECK_BULLET2:
    CMP.L   #0,                             D2
    BEQ     BULLET2_ADD
    CHECK_BULLET3:
    CMP.L   #0,                             D3
    BEQ     BULLET3_ADD
    ENTER_BULLETS_COUNT:
    MOVE.L  D4,                             BULLETS_LEFT
    RTS
    BULLET1_ADD:
        ADD.L        #1,         D4
        BRA          CHECK_BULLET2
    BULLET2_ADD:
        ADD.L        #1,         D4
        BRA          CHECK_BULLET3
    BULLET3_ADD:
        ADD.L        #1,         D4
        BRA          ENTER_BULLETS_COUNT
            

*****OBSTACLE UPDATE BELOW************
; Moves obstacle 1 to the left
UPDATE_OBSTACLE1:
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    MOVE.L  #OBSTACLE_SPEED,    D1
    MOVE.L  OBSTACLE1_X,        D2
    SUB.L   D1,                 D2
    MOVE.L  D2,                 OBSTACLE1_X
    MOVE.L  #0,                 D3
    ADD.L   #OBSTACLE_W_INIT,   D2
    CMP.L   D2,                 D3
    BGT     RESET_OBSTACLE1
    RTS

; Resets Obstacle 1 position on the right of the screen
RESET_OBSTACLE1:
    CLR.L   D1
    MOVE.L  #800,               D1                   
    MOVE.L  D1,                 OBSTACLE1_X
    JSR     RANDOM_NUMBER_OBSTACLE
    ADD.L   #50,                D1
    MOVE.L  D1,                 OBSTACLE1_Y
    RTS
    
; Moves obstacle 2 to the left
UPDATE_OBSTACLE2:
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    MOVE.L  #OBSTACLE_SPEED,    D1
    MOVE.L  OBSTACLE2_X,        D2
    SUB.L   D1,                 D2
    MOVE.L  D2,                 OBSTACLE2_X
    MOVE.L  #0,                 D3
    ADD.L   #OBSTACLE_W_INIT,   D2
    CMP.L   D2,                 D3
    BGT     RESET_OBSTACLE2
    RTS

; Resets Obstacle 2 position on the right of the screen
RESET_OBSTACLE2:
    CLR.L   D1
    MOVE.L  #800,               D1                  
    MOVE.L  D1,                 OBSTACLE2_X
    JSR     RANDOM_NUMBER_OBSTACLE
    ADD     #250,               D1
    MOVE.L  D1,                 OBSTACLE2_Y
    RTS
    
*****ENEMY UPDATE BELOW************ 

; Moves enemy 1 up or down, and calls other update methods for enemy 1
UPDATE_ENEMY1:
    CLR.L   D1
    CLR.L   D3
    BSR     CHECK_ENEMY1_POSITION
    MOVE.L  ENEMY1_X,           D1
    MOVE.L  #500,               D3
    CMP.L   D3,                 D1
    BGT     MOVE_ENEMY1
    MOVE.L  ENEMY1_Y_DIRECTION, D1
    CMP.L   #0,                 D1
    BEQ     MOVE_ENEMY1_YUP
    BNE     MOVE_ENEMY1_YDOWN
    RTS
    MOVE_ENEMY1_YUP:
        ADD.L       #-ENEMY_Y_SPEED,       ENEMY1_Y
        RTS
    MOVE_ENEMY1_YDOWN:
        ADD.L       #ENEMY_Y_SPEED,       ENEMY1_Y
        RTS
   
; Sets whether enemy 1 should move up or down     
CHECK_ENEMY1_POSITION:
    MOVE.L  ENEMY1_Y,           D1
    CMP.L   #60,                D1
    BLT     SET_ENEMY1_YDOWN
    ADD.L   #ENEMY_H_INIT,      D1
    CMP.L   #230,               D1
    BGT     SET_ENEMY1_YUP
    RTS
    SET_ENEMY1_YUP:
        MOVE.L      #0,             ENEMY1_Y_DIRECTION
        RTS
    SET_ENEMY1_YDOWN:
        MOVE.L      #1,             ENEMY1_Y_DIRECTION
        RTS

; Moves enemy 1 to the left
MOVE_ENEMY1:
    CLR.L   D1
    CLR.L   D2
    MOVE.L  #ENEMY_SPEED,       D1
    MOVE.L  ENEMY1_X,           D2
    SUB.L   D1,                 D2
    MOVE.L  D2,                 ENEMY1_X
    RTS

; Resets enemy 1 position after death
RESET_ENEMY1:
    CLR.L   D1
    MOVE.L  #1000,               D1                
    MOVE.L  D1,                 ENEMY1_X
    JSR     RANDOM_NUMBER_OBSTACLE
    ADD.L   #50,               D1
    MOVE.L  D1,                 ENEMY1_Y
    RTS
    
; Moves enemy 2 up or down, and calls other update methods for enemy 2    
UPDATE_ENEMY2:
    CLR.L   D1
    CLR.L   D3
    BSR     CHECK_ENEMY2_POSITION
    MOVE.L  ENEMY2_X,           D1
    MOVE.L  #500,               D3
    CMP.L   D3,                 D1
    BGT     MOVE_ENEMY2
    MOVE.L  ENEMY2_Y_DIRECTION, D1
    CMP.L   #0,                 D1
    BEQ     MOVE_ENEMY2_YUP
    BNE     MOVE_ENEMY2_YDOWN
    RTS
    MOVE_ENEMY2_YUP:
        ADD.L       #-ENEMY_Y_SPEED,       ENEMY2_Y
        RTS
    MOVE_ENEMY2_YDOWN:
        ADD.L       #ENEMY_Y_SPEED,        ENEMY2_Y
        RTS
        
; Sets whether enemy 2 should move up or down        
CHECK_ENEMY2_POSITION:
    MOVE.L  ENEMY2_Y,           D1
    CMP.L   #250,               D1
    BLT     SET_ENEMY2_YDOWN
    MOVE.L  ENEMY2_Y,           D2
    ADD.L   #ENEMY_H_INIT,      D2
    CMP.L   #450,               D2
    BGT     SET_ENEMY2_YUP
    RTS
    SET_ENEMY2_YUP:
        MOVE.L      #0,             ENEMY2_Y_DIRECTION
        RTS
    SET_ENEMY2_YDOWN:
        MOVE.L      #1,             ENEMY2_Y_DIRECTION
        RTS
        
; Moves enemy 2 to the left       
MOVE_ENEMY2:
    CLR.L   D1
    CLR.L   D2
    MOVE.L  #ENEMY_SPEED,       D1
    MOVE.L  ENEMY2_X,           D2
    SUB.L   D1,                 D2
    MOVE.L  D2,                 ENEMY2_X
    RTS
 
; Resets enemies 2 position after death 
RESET_ENEMY2:
    CLR.L   D1
    MOVE.L  #1000,               D1                  
    MOVE.L  D1,                 ENEMY2_X
    JSR     RANDOM_NUMBER_OBSTACLE
    ADD     #220,               D1
    MOVE.L  D1,                 ENEMY2_Y
    RTS
    
; Updates enemy 1 bullet
UPDATE_ENEMY1_BULLET:
    MOVE.L  ENEMY1_BULLET_X,     D1
    ADD.L   #BULLET_W_INIT,      D1
    MOVE.L  #0,                  D3
    CMP     D1,                  D3
    BGT     UPDATE_ENEMY1_BULLET_POSITION
    SUB.L   #BULLET_SPEED,       ENEMY1_BULLET_X
    BSR     DRAW_ENEMY1_BULLET
    RTS
    UPDATE_ENEMY1_BULLET_POSITION:
    MOVE.L  #0,                 ENEMY1_BULLET_FIRED
    MOVE.L  ENEMY1_X,           ENEMY1_BULLET_X
    MOVE.L  ENEMY1_Y,           D1
    MOVE.L  #ENEMY_H_INIT,      D2
    DIVU    #2,                 D2
    ADD.L   D2,                 D1
    MOVE.L  D1,                 ENEMY1_BULLET_Y
    RTS
    
; Updates enemy 2 bullet    
UPDATE_ENEMY2_BULLET:
    MOVE.L  ENEMY2_BULLET_X,     D1
    ADD.L   #BULLET_W_INIT,      D1
    MOVE.L  #0,                  D3
    CMP     D1,                  D3
    BGT     UPDATE_ENEMY2_BULLET_POSITION
    SUB.L   #BULLET_SPEED,       ENEMY2_BULLET_X
    BSR     DRAW_ENEMY2_BULLET
    RTS
    UPDATE_ENEMY2_BULLET_POSITION:
    MOVE.L  #0,                 ENEMY2_BULLET_FIRED
    MOVE.L  ENEMY2_X,           ENEMY2_BULLET_X
    MOVE.L  ENEMY2_Y,           D1
    MOVE.L  #ENEMY_H_INIT,      D2
    DIVU    #2,                 D2
    ADD.L   D2,                 D1
    MOVE.L  D1,                 ENEMY2_BULLET_Y
    RTS


;-------------------------------------------------
;-------------------------------------------------
;        PAUSE MENU SECTION 
;-------------------------------------------------
;-------------------------------------------------
; Inits the pause screen
PAUSE_MENU_INIT:
    JSR     MENU_CLEAR_SCREEN
    BSR     PAUSE_MENU_DRAW
    BRA     PAUSE_MENU_INPUT

; Gets the input from user
PAUSE_MENU_INPUT:
    ; Process Input
    CLR.L   D1
    CLR.L   D2
    MOVE.B  #19,        D0
    TRAP    #15
    MOVE.B  D1,         D2
    CMP.B   #0,         D2
    BEQ     PROCESS_INPUT
    TRAP    #15
    ; Check if key still pressed
    CMP.B   #$FF,       D1
    BEQ     PAUSE_MENU_PROCESS_INPUT
    BRA     PAUSE_MENU_INPUT

; Processes input from user or loops
PAUSE_MENU_PROCESS_INPUT:
    MOVE.B  D2,             CURRENT_KEY
    CMP.B   #E,             CURRENT_KEY
    BEQ     QUIT
        
    CMP.B   #ENTER,         CURRENT_KEY
    BEQ     GAME_LOOP
    
    BRA     PAUSE_MENU_INPUT

; Draws the pause menu screen   
PAUSE_MENU_DRAW:
    JSR     SET_PEN_TEXT_COLOUR
    BSR     DRAW_TITLE
    BSR     DRAW_PAUSE_OPTIONS
    RTS
    
; Clears the screen without double buffering
MENU_CLEAR_SCREEN:
    MOVE.L  #92,        D0
    MOVE.L  #16,        D1
    TRAP    #15
    MOVE.L  #11,        D0
    MOVE.L  #$FF00,     D1
    TRAP    #15
    RTS
; Draws the title 
DRAW_TITLE:
    ;Position title box
    MOVE.L #220,D1
    MOVE.L #65,D2
    MOVE.L #380,D3
    MOVE.L #100,D4    
    MOVE.B #87,D0
    TRAP #15
    
    ;Write Title
    MOVE.B  #11,    D0
    MOVE.W  #$1F05, D1   ;Title Location
    TRAP    #15
    LEA     TITLE,  A1
    MOVE    #14,    D0
    TRAP    #15
    RTS     
   
; Draws the instructions 
DRAW_PAUSE_OPTIONS:
    MOVE.B  #11,                D0
    MOVE.W  #$161D,             D1   ;Title Location
    TRAP    #15
    LEA     CONTINUE_OPTIONS,   A1
    MOVE    #14,                D0
    TRAP    #15
    RTS


;-------------------------------------------------
;-------------------------------------------------
;        GAME OVER SECTION   
;-------------------------------------------------
;-------------------------------------------------

; Checks whether health is over 0
CHECK_HEALTH:
    MOVE.L  HEALTH,         D1
    CMP     #0,             D1
    BLE     GAME_OVER_INIT
    RTS
   
; Inits the game over section 
GAME_OVER_INIT:
    JSR     CLEAR_SCREEN
    JSR     STOP_MUSIC
    JSR     PLAY_DEATH_SOUND
    BSR     GAME_OVER_DRAW
    BSR     GAME_OVER_MENU_INPUT
    RTS

; Takes the input from user
GAME_OVER_MENU_INPUT:
    ; Process Input
    CLR.L   D1
    CLR.L   D2
    MOVE.B  #19,        D0
    TRAP    #15
    MOVE.B  D1,         D2
    CMP.B   #0,         D2
    BEQ     PROCESS_INPUT
    TRAP    #15
    ; Check if key still pressed
    CMP.B   #$FF,       D1
    BEQ     GAME_OVER_PROCESS_INPUT
    BRA     GAME_OVER_MENU_INPUT
 
; Process input from user or loop
GAME_OVER_PROCESS_INPUT:
    MOVE.B  D2,             CURRENT_KEY
    CMP.B   #E,             CURRENT_KEY
    BEQ     QUIT
        
    CMP.B   #R,             CURRENT_KEY
    BEQ     RESTART
    BRA     PAUSE_MENU_INPUT

; Draws the game over screen
GAME_OVER_DRAW:
    JSR     SET_PEN_TEXT_COLOUR
    BSR     DRAW_GAME_OVER_STRING
    BSR     DRAW_GAME_OVER_OPTIONS
    RTS
    
; Draws the game over at the top of the screen
DRAW_GAME_OVER_STRING:
    ;Position title box
    MOVE.L #240,D1
    MOVE.L #65,D2
    MOVE.L #380,D3
    MOVE.L #100,D4    
    MOVE.B #87,D0
    TRAP #15
    
    ;Write Title
    MOVE.B  #11,    D0
    MOVE.W  #$2205, D1   ;Title Location
    TRAP    #15
    LEA     END_STRING ,  A1
    MOVE    #14,    D0
    TRAP    #15
    RTS

; Draws the game over instructions at the bottom
DRAW_GAME_OVER_OPTIONS:
    MOVE.B  #11,    D0
    MOVE.W  #$161D, D1   ;Title Location
    TRAP    #15
    LEA     END_OPTIONS,  A1
    MOVE    #14,    D0
    TRAP    #15
    RTS
    RTS

; Restarts the game 
RESTART:
    JSR     CLEAR_SCREEN
    JSR     START
    
;-------------------------------------------------
;-------------------------------------------------
;        SOUND EFFECTS SECTION   
;-------------------------------------------------
;-------------------------------------------------

; Loads the shoot sound
SHOOT_SOUND_LOAD:
    LEA     SHOOT_WAV,      A1
    MOVE.L  #SHOOT_INDEX,   D1
    MOVE.L  #74,            D0
    TRAP    #15
    RTS
    
; Plays the shoot sound
PLAY_SHOOT_SOUND:
    MOVE.L  #SHOOT_INDEX,   D1
    MOVE.L  #0,             D2
    MOVE.L  #77,            D0
    TRAP    #15
    RTS

; Loads death sound
DEATH_SOUND_LOAD:
    LEA     DEATH_WAV,      A1
    MOVE.L  #DEATH_INDEX,   D1
    MOVE.L  #74,            D0
    TRAP    #15
    RTS

; Plays the death sound
PLAY_DEATH_SOUND:
    MOVE.L  #DEATH_INDEX,   D1
    MOVE.L  #0,             D2
    MOVE.L  #77,            D0
    TRAP    #15
    RTS

; Explosion sound is loaded
EXPLOSION_SOUND_LOAD:
    LEA     EXPLOSION_WAV,      A1
    MOVE.L  #EXPLOSION_INDEX,   D1
    MOVE.L  #74,                D0
    TRAP    #15
    RTS
    
; Plays the explosion sound
PLAY_EXPLOSION_SOUND:
    MOVE.L  #EXPLOSION_INDEX,   D1
    MOVE.L  #0,                 D2
    MOVE.L  #77,                D0
    TRAP    #15
    RTS

; Damge sound is loaded
DAMAGE_SOUND_LOAD:
    LEA     DAMAGE_WAV,         A1
    MOVE.L  #DAMAGE_INDEX,      D1
    MOVE.L  #74,                D0
    TRAP    #15
    RTS

; Damage sound is played
PLAY_DAMAGE_SOUND:
    MOVE.L  #DAMAGE_INDEX,      D1
    MOVE.L  #0,                 D2
    MOVE.L  #77,                D0
    TRAP    #15
    RTS
    
; Music is loaded
MUSIC_LOAD:
    LEA     MUSIC_WAV,          A1
    MOVE.L  #MUSIC_INDEX,       D1
    MOVE.L  #74,                D0
    TRAP    #15
    RTS

; Plays music
PLAY_MUSIC:
    MOVE.L  #MUSIC_INDEX,       D1
    MOVE.L  #1,                 D2
    MOVE.L  #77,                D0
    TRAP    #15
    RTS

;Stops all sound effects
STOP_MUSIC:
    MOVE.L  #77,                D0
    MOVE.L  #3,                 D2
    TRAP    #15

; Loads heal sound
HEAL_SOUND_LOAD:
    LEA     HEAL_WAV,           A1
    MOVE.L  #HEAL_INDEX,        D1
    MOVE.L  #74,                D0
    TRAP    #15
    RTS

; Plays the heal sound
PLAY_HEAL_SOUND:
    MOVE.L  #HEAL_INDEX,        D1
    MOVE.L  #0,                 D2
    MOVE.L  #77,                D0
    TRAP    #15
    RTS
 
;-------------------------------------------------
;-------------------------------------------------
;                   Other Methods   
;-------------------------------------------------
;-------------------------------------------------
*******************HIGH SCORE SECTION*****************************
; Timer that delays the game
SET_TIMER:
    MOVE.B #08,     D0
    TRAP #15
    MOVE.L  D1,     ORIGINAL_TIME
    RTS

TIMER:
    MOVE.B  #08, D0     
    TRAP    #15         
    MOVE.L  D1, D3      
    MOVE.L  ORIGINAL_TIME,  D2 
    SUB.L   D2, D3     
    CMP.L   TIMER_DELAY, D3   
    BLE     TIMER 
    RTS    

RETURN:
    RTS
; Generates a random number   
RANDOM_NUMBER_OBSTACLE:     
    CLR.L               D1
    MOVE.B  #8,         D0 
    TRAP    #15 
    AND.L               #$5FFFFF,     D1
    DIVU                #200,         D1 
    SWAP                D1 
    ADDQ.W  #1,         D1 
    MOVE.W  D1,         D2 
    CLR.L   D1
    MOVE.W  D2,         D1 
    RTS   

    SIMHALT  
ORIGINAL_TIME       DS.L    1
;Reserve Space  
;----------------------------OTHER VARIABLES--------------------------------------         
SCREEN_WIDTH        DS.W    1       ; Holds screen width
SCREEN_HEIGHT       DS.W    1       ; Holds screen height
TIME1               DS.L    1       ; Variable for the timer
TIME2               DS.L    1       ; Variable for the timer

TIMER_DELAY         DS.L    1       ; Stores the delay for the time
CURRENT_KEY         DS.L    1
SCORE               DS.L    1       ; Stores the score
HEALTH              DS.L    1       ; Stores health
BULLETS_LEFT        DS.L    1       ; Stores the amount of bullets held by the player
BULLET_SPEED        EQU     25      ; Stores the speed of the bullet
;-----------------------------BULLET VARIABLES------------------------------------
; Stores the players bullets locations for X and Y
PLAYER_BULLET1_X     DS.L    1
PLAYER_BULLET1_Y     DS.L    1
PLAYER_BULLET2_X     DS.L    1
PLAYER_BULLET2_Y     DS.L    1
PLAYER_BULLET3_X     DS.L    1
PLAYER_BULLET3_Y     DS.L    1

; Used to detect whether the bullet was fired
PLAYER_BULLET1_FIRED DS.L    1      
PLAYER_BULLET2_FIRED DS.L    1
PLAYER_BULLET3_FIRED DS.L    1

BULLET_W_INIT        EQU     30      ; Initial width of bullets
BULLET_H_INIT        EQU     8       ; Initial height of bullets
;-----------------------------PLAYER VARIABLES------------------------------------
PLAYER_X            DS.L    1       ; Stores the location of the player for X
PLAYER_Y            DS.L    1       ; Stores the location of the player for Y

PLAYER_SPEED        EQU    10       ; Stores the speed of the player

PLAYER_W_INIT       EQU     8       ; Initial width of the player
PLAYER_H_INIT       EQU     8       ; Initial height of the player

START_X             DS.L    1       ; Initial X position of the player

;-----------------------------ENEMY VARIABLES-------------------------------------
; Stores the X and Y position of the enemies
ENEMY1_X            DS.L    1
ENEMY1_Y            DS.L    1
ENEMY2_X            DS.L    1
ENEMY2_Y            DS.L    1

; Stores whether the enemy should move up or down
ENEMY1_Y_DIRECTION  DS.L    1
ENEMY2_Y_DIRECTION  DS.L    1

; Stores the enemy bullets position
ENEMY1_BULLET_X     DS.L    1
ENEMY1_BULLET_Y     DS.L    1
ENEMY2_BULLET_X     DS.L    1
ENEMY2_BULLET_Y     DS.L    1

ENEMY1_BULLET_FIRED DS.L    1   ; Stores whether enemy bullets were fired
ENEMY2_BULLET_FIRED DS.L    1

ENEMY_W_INIT       EQU     20   ; Stores the width of the enemy
ENEMY_H_INIT       EQU     40   ; Stores the height of the enemy
ENEMY_SPEED        EQU     25   ; Stores the speed for enemies
ENEMY_Y_SPEED      EQU     10   ;SETS THE SPEED FOR THE ENEMIES IN THE Y DIRECTION
;----------------------------OBSTACLE VARIABLES------------------------------------
; Stores obstacle positions of X and Y
OBSTACLE1_X         DS.L    1
OBSTACLE1_Y         DS.L    1
OBSTACLE2_X         DS.L    1
OBSTACLE2_Y         DS.L    1

OBSTACLE_SPEED      EQU     15  ; Stores the speed of obstacles

OBSTACLE_W_INIT     EQU     25  ; Stores the width of the obstacles
OBSTACLE_H_INIT     EQU     25  ; Stores the height of the obstacles

;----------------------------SOUND EFFECTS---------------------------------------
; Stores the sound files
SHOOT_WAV           DC.B    'Shoot.wav',0
EXPLOSION_WAV       DC.B    'Explosion.wav',0
DEATH_WAV           DC.B    'Death.wav',0
DAMAGE_WAV          DC.B    'Damage.wav',0
MUSIC_WAV           DC.B    'Music.wav',0
HEAL_WAV            DC.B    'Heal.wav',0

; Stores the index positions for the sound effects
SHOOT_INDEX         EQU     00
EXPLOSION_INDEX     EQU     01
DEATH_INDEX         EQU     02
DAMAGE_INDEX        EQU     03
MUSIC_INDEX         EQU     04
HEAL_INDEX          EQU     05

;----------------------------STRING VARIABLES------------------------------------
CLRF                    DC.B    $0D,$0A,0
TITLE                   DC.B    'SPACE INVADERS',0
START_INSTRUCTION       DC.B    'PRESS ENTER,TO START',0
END_STRING              DC.B    'GAME OVER',0
END_OPTIONS             DC.B    'PRESS R TO RESTART, E TO QUIT',0
CONTINUE_OPTIONS        DC.B    'PRESS ENTER TO CONTINUE, E TO QUIT',0
SCORE_STRING            DC.B    'SCORE: ',0
HEALTH_STRING           DC.B    'HEALTH: ',0
BULLETS_LEFT_STRING     DC.B    'BULLETS lEFT: ',0
HIGHSCORE_STRING        DC.B    'HIGHSCORE: ',0
TITLE_INSTRUCTIONS      DC.B    '                                W - MOVE UP'
                        DC.B    $0D,$0A
                        DC.B    '                                S - MOVE DOWN'
                        DC.B    $0D,$0A
                        DC.B    '                                Q - HEAL'
                        DC.B    $0D,$0A
                        DC.B    '                         SPACEBAR - SHOOT'
                        DC.B    $0D,$0A
                        DC.B    '                              ESC - PAUSE'
                        DC.B    $0D,$0A
                        DC.B    $0D,$0A
                        DC.B    $0D,$0A
                        DC.B    '                     ONCE YOUR HEALTH REACHES ZERO YOU LOSE'
                        DC.B    $0D,$0A
                        DC.B    '                    YOU CAN SPEND 1000 SCORE TO HEAL 10 HEALTH'
                        DC.B    $0D,$0A
                        DC.B    '                    YOU GAIN A 100 SCORE FOR EACH ALIEN KILLED'
                        DC.B    $0D,$0A
                        DC.B    '             YOUR LASER IS NOT POWERFUL ENOUGH TO DESTROY AN ASTEROID',0   
; Ends the program
QUIT:
    END    START        ; last line of source














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
