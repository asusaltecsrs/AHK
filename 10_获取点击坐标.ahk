xpos:=0
ypos:=0

^r::
{
    CoordMode, Mouse, Screen ;设置坐标模式为相对于屏幕左上角
    MouseGetPos, xpos, ypos ;将鼠标当前位置存入变量xpos和ypos
    MsgBox,鼠标当前坐标：x:%xpos%,y:%ypos%
    Return
}
