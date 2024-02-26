^r::
    MouseGetPos, nx, ny
    PixelGetColor, nc, nx, ny
    MsgBox,  鼠标下的颜色  %nc%
Return
