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
: cells ( cells -- bytes )
  cell * ;
: /cell ( bytes -- cells )
  2 rshift ;

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

( compile an immediate word )
: \ immediate
  word find >cfa call, ;

: compile immediate
  \ ' ' call, call, ;

: go immediate
  \ ] \ [ ;

: (does>) ( branch-addr -- )
  \ [ latest @ >cfa cell + swap over - 'call swap ! ;

( word should be defined by 'define' instead of 'create' )
: does> immediate
  here @ 3 cells + lit, compile (does>) compile exit
  docol , compile r> ;

: define
  \ ] word create docol , 0 , ;

: reserve immediate
  define does> ;

: allot ( size -- )
  here @ + here ! ;

: constant immediate ( value -- )
  define , does> @ ;

: variable immediate ( -- )
  define 0 , does> ;

( assemble a branch instruction )
: 'branch ( offset -- instruction )
  cell - 6 lshift 8 rshift $EA000000 or ;

: recurse immediate
  latest @ >cfa call, ;

: if immediate ( cond -- )
  compile 0branch here @ 0 , ;

: then immediate
  dup here @ swap - swap ! ;

: else immediate ( TODO: use 'branch single instruction? )
  compile branch here @ 0 , swap \ then ;

: begin immediate
  here @ ;

: until immediate
  compile 0branch here @ - , ;

: while immediate ( cond -- )
  \ if ;

: repeat immediate
  compile branch swap here @ - , \ then ;

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

: is immediate ( cfa -- )
  \ go word find >cfa swap over - cell - 'branch swap ! ;

( terminal output )

: char immediate ( -- c )
  word drop c@ lit, ;

: cr ( -- )
  10 emit ;

: space ( -- )
  32 emit ;

: c, ( byte -- )
  here @ swap over c! 1 + here ! ;

: align ( size -- )
  dup dup here @ + 1 - swap mod - 1 - here @ + here ! ;

cell 1 - invert constant cellmask

: readstr, ( -- )
  begin key dup char " = if drop exit then c, again ;

( warning: does not null terminate, does not align! )
: " immediate
  \ ] readstr, \ [ ;

: (.")
  r> begin dup c@ dup while emit 1 + repeat drop
  cell + cellmask and >r ;

: ." immediate ( -- )
  compile (.") readstr, 0 c, cell align ;

: abort" immediate ( -- )
  \ ." compile quit ;

: hexchar ( value -- char )
  dup 9 > if [ char A 10 - lit, ] else char 0 then + ;

: $. ( value -- )
  8 for dup 28 rshift hexchar emit 4 lshift next drop space ;

: $c. ( value -- )
  $FF and dup 4 rshift hexchar emit $F and hexchar emit ;

( TODO: use u/mod )
: u. ( value -- )
  10 /mod dup if recurse else drop then char 0 + emit ;

: u.
  u. space ;

: . ( value -- )
  dup 0 < if char - emit negate then u. ;

( development tools )

: eval ( addr len -- )
  over + buftop ! curkey ! interpret ."  done" quit ;

( debugging tools )

: .s ( -- )
  s0 @ cell - dsp@ ( top cur )
  begin over over > while dup @ . cell + repeat drop drop ;

: (dump1) ( addr -- )
  dup $7 and 0= if dup $. else space then c@ $c. ;

: dump ( addr len -- end-addr )
  for dup (dump1) 1 + next ;

( Timer )

$840000 $0400010C ! ( start timer 3 with count-up timing )
$830000 $04000108 ! ( start timer 2 with prescaler f/1024 )

( precision: 32,768.5 / second )
( will overflow after 36.5 hours )
: uptime ( -- time )
  $0400010C h@ 16 lshift $04000108 h@ or ; 

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

( editor )

: sectors ( sectors -- bytes )
  512 * ;

reserve buf 64 sectors allot

( welcome )

.s

cr ." hi :3" cr
