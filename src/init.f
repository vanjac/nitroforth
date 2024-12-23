( display initialize )

( set Engine A to mode 1 (graphics display) )
$00010000 $04000000 ! ( DISPCNT A )
( set Engine B to mode 1. enable BG0+OBJ )
$00011100 $04001000 ! ( DISPCNT B )
( enable BG0 )
    $0400 $04001008 ! ( BG0CNT )

: palette-b $05000400 ;

( set initial palette colors )
$54DF480B palette-b !        ( output text, background )
$7F4D0000 palette-b $20 + !  ( input text )
$0EFF0000 palette-b $200 + ! ( cursor )

( TODO: these constants are duplicated in assembly )
: f-immed
  $80 ;
: docol
  $E92D4000 ;

: cell
  4 ;
: cells
  cell * ;

: / ( a b -- a/b )
  /mod swap drop ;

: mod ( a b -- a%b )
  /mod drop ;

( make the most recently defined word immediate )
: immediate ( -- )
  latest @ cell + dup c@ f-immed xor swap c! ;
  immediate ( immediate is immediate! )

: ' immediate ( -- )
  word find >cfa lit, ;

: [compile] immediate
  word find >cfa call, ;

: compile immediate
  [compile] ' ' call, call, ;

: (does>) ( branch-addr -- )
  latest @ >cfa cell + swap over - 'call swap ! ;

( word should be defined by 'define' instead of 'create' )
: does> immediate
  here @ 3 cells + lit, compile (does>) compile exit
  docol , compile r> ;

( adds default behavior which can be replaced by 'does>' )
: define
  word create docol , 0 , does> ;

: allot ( size -- )
  here @ + here ! ;

: constant ( value -- )
  define , does> @ ;

: variable ( -- )
  define 0 , ;

( assemble a branch instruction )
: 'branch ( offset -- instruction )
  cell - 6 lshift 8 rshift $EA000000 or ;

: if immediate ( cond -- )
  compile 0branch here @ 0 , ;

: then immediate
  dup here @ swap - swap ! ;

: else immediate ( TODO: use 'branch single instruction? )
  compile branch here @ 0 , swap [compile] then ;

( new definition which supports interpret mode )
: ' immediate ( -- )
  word find >cfa state @ if lit, then ;

: begin immediate
  here @ ;

: until immediate
  compile 0branch here @ - , ;

: while immediate ( cond -- )
  [compile] if ;

: repeat immediate
  compile branch swap here @ - , [compile] then ;

: again immediate
  compile branch here @ - , ;

: (for) ( start -- )
  1 - r> swap >r >r ;

: for immediate ( start -- )
  compile (for) here @ ;

: (next)
  rsp@ cell + dup @ dup ( i-addr i i )
  if 1 - swap ! r> dup @ + >r
  else drop drop r> rdrop cell + >r then ;

: next immediate ( -- )
  compile (next) here @ - , ;

: i ( -- i )
  rsp@ cell + @ ;

: j ( -- j )
  rsp@ [ 2 cells lit, ] + @ ;

: is ( cfa -- )
  word find >cfa swap over - cell - 'branch swap ! ;

: char ( -- c )
  word drop c@ ;

: [char] immediate
  char lit, ;

: cr ( -- )
  10 emit ;

: space ( -- )
  32 emit ;

: c, ( byte -- )
  here @ swap over c! 1 + here ! ;

: align ( size -- )
  dup dup here @ + 1 - swap mod - 1 - here @ + here ! ;

cell 1 - invert constant cellmask

( warning: does not null terminate, does not align! )
: " ( -- size )
  begin key dup [char] " = if drop exit then c, again ;

: (.")
  r> begin dup c@ dup while emit 1 + repeat drop
  cell + cellmask and >r ;

: ." immediate ( -- )
  state @ if
    compile (.") [compile] " 0 c, cell align
  else
    begin key dup [char] " = if drop exit then emit again
  then ;

: abort" immediate ( -- )
  [compile] ." compile quit ;

: hexchar ( value -- char )
  dup 9 > if [ char A 10 - lit, ] else [char] 0 then + ;

: $. ( value -- )
  8 begin
    swap dup 28 rshift hexchar emit 4 lshift swap 1 - dup 0=
  until drop drop space ;

: $c. ( value -- )
  $FF and dup 4 rshift hexchar emit $F and hexchar emit ;

( debugging tools )

: $.s ( -- )
  s0 @ 4 - dsp@ ( top cur )
  begin over over > while dup @ $. 4 + repeat drop drop ;

: (dump1) ( addr -- )
  dup $7 and 0= if dup $. else space then c@ $c. ;

: dump ( addr len -- end-addr )
  over + swap ( end-addr cur-addr )
  begin over over > while dup (dump1) 1 + repeat drop ;

( DLDI )

: dldi-init ( -- status )
  dldi $68 + @ c-call0 ;

: dldi-inserted ( -- inserted )
  dldi $6C + @ c-call0 ;

: dldi-read ( sector numsectors buf -- status )
  dldi $70 + @ c-call3 ;

: dldi-write ( sector numsectors buf -- status )
  dldi $74 + @ c-call3 ;

: dldi-reset ( -- status )
  dldi $78 + @ c-call0 ;

: dldi-shutdown ( -- status )
  dldi $7C + @ c-call0 ;

( set GBA/NDS slot access to ARM9 )
$4000204 ( EXMEMCNT ) dup h@ $880 invert and swap h!

." DLDI: " dldi $10 + ztype drop cr

( welcome )

$.s

cr ." hi :3" cr
