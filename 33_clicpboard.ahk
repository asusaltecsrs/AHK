; ahkVersion: 2.0-a133-9819cb2d
; autor: fwt
; date: 2021-05-12
; descript: 用 html 写剪贴板，可同时放入图片、文字、表格
; test begin =============================
test := "
(
<b>This is a test. 这是一个测试。</b>
<hr>
<li>entry 1</li>
<li>entry 2</li>
<table border="1">
  <tr>
    <td>row 1, cell 1</td>
    <td>row 1, cell 2</td>
  </tr>
  <tr>
    <td>row 2, cell 1</td>
    <td>row 2, cell 2</td>
  </tr>
</table>
<img src="c:UserschnfwPicturesSketchpad.png" />
)"
htmlClip(test)
; test end =============================
htmlClip(userhtml){
  basehtml := "
  (
  Version:0.9
  StartHTML:10000000
  EndHTML:20000000
  StartFragment:30000000
  EndFragment:40000000
  <!DOCTYPE>
  <html><body>
  <!--StartFragment-->
  {:s}
  <!--EndFragment-->
  </body></html>
  )"
  html          := toUTF8(Format(basehtml, userhtml))
  StartHTML     := strstr(html, toUTF8("<html>")) - html.ptr
  StartFragment := strstr(html, toUTF8("<!--StartFragment-->")) - html.ptr
  EndFragment   := strstr(html, toUTF8("<!--EndFragment-->")) - html.ptr
  EndHTML       := html.size
  ptr := strstr(html, toUTF8("StartHTML"))
  StrPut(Format("{:08u}", StartHTML), ptr+10, 8, "UTF-8")
  ptr := strstr(html, toUTF8("StartFragment"))
  StrPut(Format("{:08u}", StartFragment), ptr+14, 8, "UTF-8")
  ptr := strstr(html, toUTF8("EndFragment"))
  StrPut(Format("{:08u}", EndFragment), ptr+12, 8, "UTF-8")
  ptr := strstr(html, toUTF8("EndHTML"))
  StrPut(Format("{:08u}", EndHTML), ptr+8, 8, "UTF-8")
  if(DllCall("OpenClipboard", "ptr", 0)){
    DllCall("EmptyClipboard")
    cfid := DllCall("RegisterClipboardFormat", "Str", "HTML Format")
    DllCall("SetClipboardData", "UINT", cfid, "ptr", html)
    DllCall("CloseClipboard")
  }
  ObjSetCapacity(html, 0)
}
strstr(haystack, needle){
  return DllCall("msvcrtstrstr", "ptr", haystack, "ptr", needle, "Cdecl UINT")
}
toUTF8(str){
  size := StrPut(str, "UTF-8")
  buf := Buffer(size)
  StrPut(str, buf, , "UTF-8")
  return buf
}
