
#Include ./lib/FindText-9.4-V2.ahk

;win prtscsysrq截图全屏进行查看
!q::
{
    MouseClick "right"
    Sleep 1000
    ;通过Code打开
    Text:="|<>*146$87.HyE4000080103zlD20U3k01009z483y/z0V00807kUV0GE0U8001008448vyu410D3sw10bztGF8U834X8UC448/y8Y10EY9y70UV1GF0U824V808448+S8s1VMYN410VV303003lsT7084M8bzbz00000077a14"

    if (ok:=FindText(&X, &Y, 110-150000, 203-150000, 110+150000, 203+150000, 0, 0, Text))
    {
        FindText().Click(X, Y, "L")
    }

}
