Hotkey ^b, biedianbaifangkuai
Return
biedianbaifangkuai:
x1 := 725, y1 := 761
x2 := 889, y2 := 761
x3 := 1050, y3 := 761
x4 := 1216, y4 := 761
x5 := 1216, y5 := 761
Loop
{
    PixelGetColor color1, x1, y1
    if (color1 == "0x333333")
    {
        ; Click %x1%,%y1%
        MouseClick, left, %x1%, %y1%, 1, 0
        Continue
    }
    PixelGetColor color2, x2, y2
    if (color2 == "0x333333")
    {
        ; Click %x2%,%y2%
        MouseClick, left, %x2%, %y2%, 1, 0
        Continue
    }
    PixelGetColor color3, x3, y3
    if (color3 == "0x333333")
    {
        ; Click %x3%,%y3%
        MouseClick, left, %x3%, %y3%, 1, 0
        Continue
    }
    PixelGetColor color4, x4, y4
    if (color4 == "0x333333")
    {
        ; Click %x4%,%y4%
        MouseClick, left, %x4%, %y4%, 1, 0
        Continue
    }
    PixelGetColor color5, x5, y5
    if (color5 == "0x58DD00" or color5 == "0x0000FF")
    {
        Break
    }
    ; Break
}
Return
