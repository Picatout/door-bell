\ ****************
\ **  DOOR-BELL **
\ ****************

\ avant d'installer ce programme 
\ sur le stm8l151k6 les programmes 
\ suivants doivent-être isntallés 
\ dans l'ordre 
\    forth/exist.f 
\    forth/w25q_prog.f
\    forth/play_wav.f 
   
DECIMAL 
FORGET ODE-JOIE 

\ ODE À LA JOIE, HYMNE DE L'UNION EUROPÉENNE
: ODE-JOIE 
    CR ." ODE A LA JOIE"
    0 0 PLAY_WAV 
;

\ CODE ENVOYÉ PAR LES EXTRA-TERRESTRE 
\ DANS LE FILM RENCONTRE DU 3IÈME TYPE 
: CODE-ET 
    CR ." CODE RENCONTRE DU 3IEME TYPE"
    $9000 2 PLAY_WAV  
;

\ WESTMINSTER TOWER QUATER CHIME 
: BIG-BEN 
    CR ." WESTMINSTER CHIME"
    $6000 4 PLAY_WAV 
; 

\ THÈME MUSICAL ORIGINAL DU
\ JEU TETRIS
: KORO
    CR ." TETRIS, KOROBEINIKI"
    $B000 6 PLAY_WAV
;

\ SON DE GONG 
\ PROVIENT DE LIBRE OFFICE 
: GONG 
    CR ." GONG" 
    $8000 8 PLAY_WAV 
;

\ THÈME DU FILM 
\ LES JEUX INTERDITS
: J-INTERD
    CR ." LES JEUX INTERDITS
    $7000 $B PLAY_WAV
;

\  KONGAS 
\ PROVIENT DE LIBRE OFFICE 
: KONGAS 
    CR ." KONGAS" 
    $2000 $D PLAY_WAV
;

\ TROMPETTES ROMAINES
: TROMPETTE
    CR ." TROMPETTES ROMAINES"
    0 $E PLAY_WAV
;

\ UART registre d'état 
$5230 CONST USART1_SR

\ registre de configuration
\ des interruptions externes
$50A5 CONST EXTI_CONF1 \ activation de l'interruption
$50A0 CONST EXTI_CR1 \  configuration type de transition 
$50A3 CONST EXTI_CR3 
$50A4 CONST EXTI_SR2 \ indicateurs d'interruptions
6 CONST EXTIB \ numéro du vecteur d'interruption 

\ gpio port A 
$5000 CONST PA_ODR 
$5001 CONST PA_IDR 
$5002 CONST PA_DDR  
$5003 CONST PA_CR1 
$5004 CONST PA_CR2 

\ gpio port B 
$5005 CONST PB_ODR 
$5006 CONST PB_IDR 
$5007 CONST PB_DDR  
$5008 CONST PB_CR1 
$5009 CONST PB_CR2 
3 CONST SHUTDOWN \ lm6841 shutdown
2 CONST LED \ play LED control 

\ gpio port D    
$500F CONST PD_ODR
$5010 CONST PD_IDR
$5011 CONST PD_DDR
$5012 CONST PD_CR1
$5013 CONST PD_CR2


\ création d'un tableau
\ de n élément  
: ARRAY ( n -- )
    CREATE 
    2* ALLOT
    DOES>
    SWAP 2* +  
; 

8 ARRAY TUNES  

: [']
    ' 
; IMMEDIATE COMPILE-ONLY 


: RING_TONES 
    ['] ODE-JOIE LITERAL 0 TUNES !
    ['] CODE-ET LITERAL 1 TUNES ! 
    ['] BIG-BEN LITERAL 2 TUNES  ! 
    ['] KORO LITERAL 3 TUNES ! 
    ['] GONG LITERAL 4 TUNES ! 
    ['] KONGAS LITERAL 5 TUNES ! 
    ['] J-INTERD LITERAL 6 TUNES ! 
    ['] TROMPETTE LITERAL 7 TUNES ! 
; 


: HALT 
    [ $8E C, ]
; 

\ attend que 
\ le bouton sonnette 
\ soit relaché 
: DEBOUNCE 
    0 
    BEGIN
        10000 FOR NEXT \ delais 
        PB_IDR C@
        2 AND 
        IF 1+ ELSE 1- THEN
        20 > 
    UNTIL  
; 

EXTIB I:
    DEBOUNCE
    0 EXTI_SR2 SETBIT \ rst intr flag
I; 

\ activation du LM4861 
: AMP_ON
    SHUTDOWN PB_ODR RSTBIT 
; 

\ LM4861 en basse consommation
: AMP_OFF 
    SHUTDOWN PB_ODR SETBIT 
; 
\ PLAY DOOR-BELL WAV 
\ n is TUNES index  
: PLAY ( n -- )
    LED PB_ODR RSTBIT 
    AMP_ON 
    TUNES @EXECUTE 
    AMP_OFF 
    LED PB_ODR SETBIT
; 

: DOOR-BELL
\ configure PB3 pour contrôler 
\ la broche (1) shutdown du lm4861
    SHUTDOWN PB_CR1 SETBIT 
    SHUTDOWN PB_DDR SETBIT 
    AMP_OFF 
\ set LED pin as output 
    LED PB_ODR SETBIT 
    LED PB_DDR SETBIT     
\ config EXTIB sur PB1, bouton sonette 
    0 EXTI_CONF1 SETBIT \ active intr sur PB[0..3] 
    3 EXTI_CR1 SETBIT \ transition descendante sur PB1  
    1 PB_CR1 SETBIT \ pullup sur PB1 
    1 PB_CR2 SETBIT \ active intr sur PB1
    RING_TONES \ build ring tones array 
    CR ." DOOR-BELL RUNNING, KEY TO ABORT (4 SEC.)" CR 
    TMR-RST  
    BEGIN 
        KEY? IF 
                KEY ABORT" aborted" 
            THEN 
        TIMER 4000 > 
    UNTIL 
    ." TOO LATE" 
    BEGIN USART1_SR C@ $40 AND  UNTIL \ test TC bit  
    TIM4_IER_UIE TIM4_IER RSTBIT \ désactive timer4 
    5 CLK_PCKENR1 RSTBIT \ désactive le UART  
    5 PLAY  
    BEGIN 
        HALT 
        PA_IDR C@ 
        2* $F8 XOR \ bits 3...7 inversés  
        $F8 AND \ garde les bits 3...7  
        PD_IDR C@ 7 XOR \ bits 0...2 inversés  
        7 AND \ garde les bits 0...2   
        OR \ fusionne 0...2 et 3...7 
        -1 SWAP 
        BEGIN \ quelle mélodie est sélectionnée 
            DUP WHILE
            2/ 
            SWAP 1+ SWAP  
        REPEAT
        DROP  \ 0...7  
        PLAY  
    AGAIN 
; 






