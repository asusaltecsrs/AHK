Hotkey "^b",biedianbaifangkuai
Return
biedianbaifangkuai(thishotkey)
{
    x1 := 725, y1 := 761
    x2 := 889, y2 := 761
    x3 := 1050, y3 := 761
    x4 := 1216, y4 := 761
    x5 := 1216, y5 := 761
    Loop
    {
        color1 := PixelGetColor(x1, y1)
        if (color1 == "0x333333")
        {
            ; Click %x1%,%y1%
            MouseClick("Left", x1, y1, 1, 0)
            Continue
        }
        color2 := PixelGetColor(x2, y2)
        if (color2 == "0x333333")
        {
            ; Click %x2%,%y2%
            MouseClick("Left", x2, y2, 1, 0)
            Continue
        }
        color3 := PixelGetColor(x3, y3)
        if (color3 == "0x333333")
        {
            ; Click %x3%,%y3%
            MouseClick("Left", x3, y3, 1, 0)
            Continue
        }
        color4 := PixelGetColor(x4, y4)
        if (color4 == "0x333333")
        {
            ; Click %x4%,%y4%
            MouseClick("Left", x4, y4, 1, 0)
            Continue
        }
        color5 := PixelGetColor(x5, y5)
        if (color5 == "0x58DD00" or color5 == "0x0000FF")
        {
            Break
        }
        ; Break
    }
}
