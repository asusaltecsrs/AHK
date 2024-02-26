;别踩白方块
;主干程序
Hotkey "^b" ,biedianbaifangkuai
return
biedianbaifangkuai(thishotkey)
{
    x1:=724 ,y1:=587 ,x2:=883 ,y2:=587 ,x3:=1045 ,y3:=587 ,x4:=1219 ,y4:=587,x:=752 ,y:=160
;1.条件判断的循环，判定什么时候停止
    loop
    {
        ;2.取四个点判断颜色
        yanse1:=PixelGetColor(x1,y1)
        if(yanse1=="0x333333")
        {
            Click x1,y1
            Continue
        }
        yanse2:=PixelGetColor(x2,y2)
        if(yanse2=="0x333333")
        {
            Click x2,y2
            Continue
        }
        yanse3:=PixelGetColor(x3,y3)
        if(yanse3=="0x333333")
        {
            Click x3,y3
            Continue
        }
        yanse4:=PixelGetColor(x4,y4)
        if(yanse4=="0x333333")
        {
            Click x4,y4
            Continue
        }
        ;停止条件
        yanse:=PixelGetColor(x,y)
        if(yanse=="0x0000FF" or yanse=="0x58DD00")
        {
            Break
        }
    }   
}
