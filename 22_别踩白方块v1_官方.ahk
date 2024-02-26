;别踩白方块
;loop
;Hotkey
;PixelGetColor
;CoordMode
;^b::
;1,记数方式
    ;loop 10
    ;{
        ;Send w
        ;Sleep 30
    ;}
;2,条件判断
    ;loop
    ;{
        ;send w
        ;if(A_Index>10)
        ;{
            ;Break
        ;}
    ;}
;return
;主干程序
Hotkey ^b ,biedianbaifangkuai
return
biedianbaifangkuai:
    x1:=724 ,y1:=587 ,x2:=883 ,y2:=587 ,x3:=1045 ,y3:=587 ,x4:=1219 ,y4:=587,x:=752 ,y:=160
;1.条件判断的循环，判定什么时候停止
    loop
    {
        ;2.取四个点判断颜色
        PixelGetColor yanse1,x1,y1
        if(yanse1=="0x333333")
        {
            Click %x1%,%y1%
            Continue
        }
        PixelGetColor yanse2,x2,y2
        if(yanse2=="0x333333")
        {
            Click %x2%,%y2%
            Continue
        }
        PixelGetColor yanse3,x3,y3
        if(yanse3=="0x333333")
        {
            Click %x3%,%y3%
            Continue
        }
        PixelGetColor yanse4,x4,y4
        if(yanse4=="0x333333")
        {
            Click %x4%,%y4%
            Continue
        }
        ;停止条件
        PixelGetColor yanse,x,y
        if(yanse=="0x0000FF" or yanse=="0x58DD00")
        {
            Break
        }
    }
return
