^b::
    MouseGetPos, xpos, ypos
    MsgBox, X:%xpos% Y:%ypos%
    PixelGetColor, color1, xpos, ypos
    ; MsgBox, %color1%
Return
