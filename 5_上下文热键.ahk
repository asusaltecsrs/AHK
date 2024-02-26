;放在状态栏上滚动鼠标
#If MouseIsOver("ahk_class Shell_TrayWnd")
WheelUp::Send {Volume_Up}
WheelDown::Send {Volume_Down}
#If

;最大化最小化窗口
#If WinActive("ahk_exe Code.exe")
WheelUp::WinMaximize, ahk_exe Code.exe
WheelDown::WinMinimize, ahk_exe Code.exe
#If

MouseIsOver(WinTitle)
{
    MouseGetPos ,,, Win
    return WinExist(WinTitle . " ahk_id " . Win)
}
