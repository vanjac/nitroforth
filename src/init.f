
( display initialize )

( set Engine A to mode 1 (graphics display) )
$00010000 $04000000 ! ( DISPCNT A )
( set Engine B to mode 1 (graphics display). enable BG0+OBJ )
$00011100 $04001000 ! ( DISPCNT B )
( enable BG0 )
    $0400 $04001008 ! ( BG0CNT )


( -- addr )
: palette-b $05000400 ;

( set initial palette colors )
$54DF480B palette-b !        ( output text, background )
$7F4D0000 palette-b $20 + !  ( input text )
$0EFF0000 palette-b $200 + ! ( cursor )
