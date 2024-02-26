^r::
    ; MouseClick
    ; MouseMove, 10, 0, 0, Right
    ; MouseClick
    ; MouseMove, 10, 0, 0, Right
    ; MouseClick
    ; MouseMove, 10, 0, 0, Right

    MouseClick, Left, 500, 500
    MouseClick, Left, 500, 600
    MouseClick, Left, 500, 800

    ;Click Relative 100 100 ;当前位置右100，下100
    ; Click 2 ;点击两次
    ; Click Right ;右键

    
    ; Click
    ; MouseMove 50,0,0,R ;x 50 y 50 Speed 0 R relative
    ; Click

    ; Loop,10
    ; {
    ;     Click
    ;     MouseMove 50,0,0,R ;x 50 y 50 Speed 0 R relative
    ; }

    ; Loop,10
    ; {
    ;     Loop,10
    ;     {
    ;         Click
    ;         MouseMove 50,0,0,R ;x 50 y 50 Speed 0 R relative
    ;     }
    ;     MouseMove -500,50,0,R
    ; }
Return
