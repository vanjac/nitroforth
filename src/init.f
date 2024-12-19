( TODO: these constants are duplicated in assembly )
: f-immed
  $80 ;
: docol
  $E92D4000 ;

: cell
  4 ;
: cells
  cell * ;

( make the most recently defined word immediate )
: immediate ( -- )
  latest @ cell + dup c@ f-immed xor swap c! ;
  immediate ( immediate is immediate! )

: ' immediate ( -- ) ( TODO: only works when compiled )
  word find >cfa lit, ;

: [compile] immediate
  word find >cfa call, ;

: (does>) ( branch-addr -- )
  latest @ >cfa cell + swap over - 'call swap ! ;

( word should be defined by 'define' instead of 'create' )
: does> immediate
  here @ 3 cells + lit, ' (does>) call, ' exit call,
  docol , ' r> call, ;

( adds default behavior which can be replaced by 'does>' )
: define
  word create docol , 0 , does> ;

: constant ( value -- )
  define , does> @ ;

: variable ( -- )
  define 0 , ;

( assemble a branch instruction )
: 'branch ( offset -- instruction )
  cell - 6 lshift 8 rshift $EA000000 or ;

: if immediate ( cond -- )
  ' 0branch call, here @ 0 , ;

: then immediate
  dup here @ swap - swap ! ;

: else immediate ( TODO: use 'branch single instruction? )
  ' branch call, here @ 0 , swap [compile] then ; 

: begin immediate
  here @ ;

: until immediate
  ' 0branch call, here @ - , ;

: while immediate ( cond -- )
  [compile] if ;

: repeat immediate
  ' branch call, swap here @ - , [compile] then ;

: again immediate
  ' branch call, here @ - , ;

: char ( -- c )
  word drop c@ ;

: [char] immediate
  char lit, ;

: cr ( -- )
  10 emit ;

: space ( -- )
  32 emit ;

: ." ( -- ) ( TODO: make immediate! )
  begin key dup [char] " = if drop exit then emit again ;

: hexchar ( value -- char )
  dup 9 > if [ char A 10 - lit, ] else [char] 0 then + ;

: $. ( value -- )
  8 begin
    swap dup 28 rshift hexchar emit 4 lshift swap 1 - dup 0=
  until drop drop space ;

( display initialize )

( set Engine A to mode 1 (graphics display) )
$00010000 $04000000 ! ( DISPCNT A )
( set Engine B to mode 1. enable BG0+OBJ )
$00011100 $04001000 ! ( DISPCNT B )
( enable BG0 )
    $0400 $04001008 ! ( BG0CNT )

$05000400 constant palette-b

( set initial palette colors )
$54DF480B palette-b !        ( output text, background )
$7F4D0000 palette-b $20 + !  ( input text )
$0EFF0000 palette-b $200 + ! ( cursor )

." hello :3" cr
." DLDI: " dldi $10 + ztype drop cr
