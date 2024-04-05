
#Requires Autohotkey v2
;AutoGUI 2.5.8 creator: Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter creator: github.com/mmikeww/AHK-v2-script-converter
;Easy_AutoGUI_for_AHKv2 github.com/samfisherirl/Easy-Auto-GUI-for-AHK-v2

f12::
{
    myGui := Gui()
    myGui.Opt("-MinimizeBox -MaximizeBox +AlwaysOnTop")
    ogcButton1 := myGui.Add("Button", "x5 y5 w80 h25", "1")
    ogcButton2 := myGui.Add("Button", "x90 y5 w80 h25", "2")
    ogcButton3 := myGui.Add("Button", "x175 y5 w80 h25", "3")
    ogcButton1.OnEvent("Click", ogcButton1Func)
    ogcButton2.OnEvent("Click", ogcButton2Func)
    ogcButton3.OnEvent("Click", ogcButton3Func)
    myGui.OnEvent('Close', (*) => ExitApp())
    myGui.Title := "Window"
    myGui.Show("w260 h35")
}

ogcButton1Func(*)
{
	MsgBox 1
}

ogcButton2Func(*)
{
	MsgBox 2
}

ogcButton3Func(*)
{
	MsgBox 3
}
