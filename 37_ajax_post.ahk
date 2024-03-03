#SingleInstance, Force
key := 123
write := "hhh"
userid := "ddsds"
; json_msg := "{""username"":""" key """,""info"":""" write """,""userid"":" userid "}"
s=
{
    name: BeJson
}

; s := json2obj(s)
; s:=obj2json(json2obj(s))

responseData := JSONPOST("http://192.168.3.2:3000/user", s)
; tro := json2obj(responseData)
; MsgBox, %tro.username%
; city := json(responseData, "cityInfo.city")
city := json(responseData, "username")
MsgBox, %city%

JSONPOST(url, Encoding = "utf-8",postData=""){ ;网址，编码, post JSON数据
    hObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
    Try
    {
        hObject.Open("POST",url,False)
        hObject.SetRequestHeader("Content-Type", "application/json")
        hObject.Send(postData)
    }
    catch e
        return -1
 
    if (Encoding && hObject.ResponseBody)
    {
        oADO := ComObjCreate("adodb.stream")
        oADO.Type := 1
        oADO.Mode := 3
        oADO.Open()
        oADO.Write(hObject.ResponseBody)
        oADO.Position := 0
        oADO.Type := 2
        oADO.Charset := Encoding
        return oADO.ReadText(), oADO.Close()
    }
    return hObject.ResponseText
}


json(ByRef js, s, v = "") 
{
	j = %js%
	Loop, Parse, s, .
	{
		p = 2
		RegExMatch(A_LoopField, "([+\-]?)([^[]+)((?:\[\d+\])*)", q)
		Loop {
			If (!p := RegExMatch(j, "(?<!\\)(""|')([^\1]+?)(?<!\\)(?-1)\s*:\s*((\{(?:[^{}]++|(?-1))*\})|(\[(?:[^[\]]++|(?-1))*\])|"
				. "(?<!\\)(""|')[^\7]*?(?<!\\)(?-1)|[+\-]?\d+(?:\.\d*)?|true|false|null?)\s*(?:,|$|\})", x, p))
				Return
			Else If (x2 == q2 or q2 == "*") {
				j = %x3%
				z += p + StrLen(x2) - 2
				If (q3 != "" and InStr(j, "[") == 1) {
					StringTrimRight, q3, q3, 1
					Loop, Parse, q3, ], [
					{
						z += 1 + RegExMatch(SubStr(j, 2, -1), "^(?:\s*((\[(?:[^[\]]++|(?-1))*\])|(\{(?:[^{\}]++|(?-1))*\})|[^,]*?)\s*(?:,|$)){" . SubStr(A_LoopField, 1) + 1 . "}", x)
						j = %x1%
					}
				}
								
								
				Break
			}
			Else p += StrLen(x)
		}
	}
	If v !=
	{
		vs = "
		If (RegExMatch(v, "^\s*(?:""|')*\s*([+\-]?\d+(?:\.\d*)?|true|false|null?)\s*(?:""|')*\s*$", vx)
			and (vx1 + 0 or vx1 == 0 or vx1 == "true" or vx1 == "false" or vx1 == "null" or vx1 == "nul"))
			vs := "", v := vx1
		StringReplace, v, v, ", \", All
		js := SubStr(js, 1, z := RegExMatch(js, ":\s*", zx, z) + StrLen(zx) - 1) . vs . v . vs . SubStr(js, z + StrLen(x3) + 1)
	}
	Return, j == "false" ? 0 : j == "true" ? 1 : j == "null" or j == "nul"
		? "" : SubStr(j, 1, 1) == """" ? SubStr(j, 2, -1) : j
}


json2obj(s)  ; Json字符串转AHK对象
{
  static rep:={"\""":"""", "\r":"`r", "\n":"`n", "\t":"`t"}
  if !(p:=RegExMatch(s, "[\{\[]", r))
    return
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  obj:=[], stack:=[], arr:=obj, flag:=r, key:="", keyok:=0
  While p:=RegExMatch(s, "\S", r, p+StrLen(r))
  {
    if (r="{" or r="[")       ; 如果是 左括号
    {
      v:=[], (flag="{" ? (arr[key]:=v) : arr.Push(v))
      , stack.Push(arr, flag), arr:=v, flag:=r
      , key:="", keyok:=0, v:=""
    }
    else if (r="}" or r="]")  ; 如果是 右括号
    {
      if !stack.MaxIndex()
        Break
      flag:=stack.Pop(), arr:=stack.Pop(), key:="", keyok:=0
    }
    else if (r=",")           ; 如果是 逗号
    {
      key:="", keyok:=0
    }
    else if (flag="{" and keyok=0)  ; 如果是 键名
    {
      if !(RegExMatch(s, "([^\s:]*)\s*:", r, p)=p)
        Break
      key:=Trim(r1,""""), keyok:=1
    }               ; 如果是 数字、true、false、null
    else if RegExMatch(s, "[\w\+\-\.]+", r, p)=p
    {
      (flag="{" ? (arr[key]:=r) : arr.Push(r))
    }
    else            ; 如果是 字符串
    {
      v:=""
      Loop
      {
        if !(RegExMatch(s, """([^""]*)""", r, p)=p)
          Break, 2
        if !(SubStr(StrReplace(r1,"\\"),0)="\")
          Break
        p+=StrLen(r)-1, v.=r1 . """"
      }
      if InStr(r1:=v . r1, "\")
      {
        r1:=StrReplace(r1, "\\", "\0")
        For k,v in rep
          r1:=StrReplace(r1, k, v)
        r1:=StrReplace(r1, "\0", "\")
      }
      (flag="{" ? (arr[key]:=r1) : arr.Push(r1))
    }
  }
  SetBatchLines, %bch%
  return obj
}
obj2json(obj)  ; AHK对象转Json字符串
{
  static rep:={"\""":"""", "\r":"`r", "\n":"`n", "\t":"`t"}
  if !IsObject(obj)
  {
    if obj is Number
      return obj
    if (obj="true" or obj="false" or obj="null")
      return obj
    obj:=StrReplace(obj, "\", "\\")
    For k,v in rep
      obj:=StrReplace(obj, v, k)
    return """" obj """"
  }
  s:="", arr:=1  ; 是简单数组
  For k,v in obj
    if (k!=A_Index) and !(arr:=0)
      Break
  For k,v in obj
    s.=(arr ? " " : " """ k """ : ") %A_ThisFunc%(v) ",`r`n"
  return (arr ? "[`r`n":"{`r`n")
    . SubStr(s,1,-3) . (arr ? "`r`n]":"`r`n}")
}

