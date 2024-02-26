^r::
    ;Click ;在当前位置点击
    ;Click 500 500 ;在指定位置点击
    ;Click Relative 100 100 ;当前位置右100，下100
    ; Click 2 ;点击两次
    ; Click Right ;右键
    ; Click, 922 393
    ; Click, 930 401 ;window比较准吗？
    ; Click, 922 370
    Click, 1627 1050 0

    
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
