GetSelectedFile(hwnd="")
{
	hwnd := hwnd ? hwnd : WinExist("A")
	WinGetClass class, ahk_id %hwnd%
	if (class="CabinetWClass" or class="ExploreWClass")
	{
		try for window in ComObjCreate("Shell.Application").Windows
				if (window.hwnd==hwnd)
					sel := window.Document.SelectedItems
		for item in sel
			ToReturn .= item.path "`n"
	}
	else if(WinActive("ahk_class Progman") || WinActive("ahk_class WorkerW"))
	{
		ControlGet, selectedFiles, List, Selected Col1, SysListView321, A
		; 如果多个项目被选中
		if InStr(selectedFiles, "`n")
		{
			these_files := ""
			loop, Parse, selectedFiles, `n, `r
				ToReturn .= A_Desktop . "" . A_LoopField . "`n"
		}
		else
			ToReturn:= A_Desktop . "" . selectedFiles
	}
	else
		return false
	return Trim(ToReturn,"`n")
}
