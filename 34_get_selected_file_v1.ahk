#Include ./lib/get_selected_file_v1.ahk

F1::
    sel:=GetSelectedFile()
    MsgBox % sel
return
