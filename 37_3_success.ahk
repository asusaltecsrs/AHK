#SingleInstance Force

f1::
  url := "http://192.168.3.2:3000/user"

  httpClient := ComObjCreate("WinHttp.WinHttpRequest.5.1")
  httpClient.Open("POST", url, false)
  ;httpClient.SetRequestHeader("User-Agent", User-Agent)
  ;httpClient.SetRequestHeader("Content-Type", Content-Type)
  ;httpClient.SetRequestHeader("Cookie", Cookie)

  action = 
(
{
    "username": "addNote",
    "version": 6,
    "params": {
        "note": {
            "deckName": "Default",
            "modelName": "Basic",
            "fields": {
                "Front": "中文: 貓",
                "Back": "英文: cat"
            },
            "tags": [
                "yomichan"
            ],
            "audio": {
                "url": "https://s.yimg.com/bg/dict/dreye/live/f/cat.mp3",
                "filename": "mycat.mp3",
                "skipHash": "7e2c2f954ef6051373ba916f000168dc",
                "fields": [
                    "Back"
                ]
            }
        }
    }
}
)  
  ;; "application/x-www-form-urlencoded"
  httpClient.SetRequestHeader("Content-Type", "application/json")
  ;; "{""action"": ""deckNames"", ""version"": 6}"
  httpClient.Send(action)
  ;;msgbox start to invoke
  httpClient.WaitForResponse()
  response := httpClient.ResponseText
  
  MsgBox result=%response%
  city := json(response, "username")
  version := json(response, "version")
  deckName := json(response, "params.note.deckName")
MsgBox, %city%
MsgBox, %version%
MsgBox, %deckName%
;   ankiJson := jsonAHK(response)
;   anki_ID := ankiJson.result
;   error := ankiJson.error
;   MsgBox ID=%anki_ID%, error=%error%.
  ;;Result := uXXXX2Chinese(response)
  ;;MsgBox result=%Result%

  return

jsonAHK(s){
    static o := GetObjJScript()
    o.language:="jscript"
    return o.eval("(" s ")")
}

GetObjJScript()
{
   if !FileExist(ComObjFile := A_ScriptDir "\JS.wsc")
      FileAppend,
         (LTrim
            <component>
            <public><method name='eval'/></public>
            <script language='JScript'></script>
            </component>
         ), % ComObjFile
   Return ComObjGet("script:" . ComObjFile)
}

;; copied from https://www.autohotkey.com/boards/viewtopic.php?f=28&t=3897
uXXXX2Chinese(uXXXX) ; in: "\u7231\u5c14\u5170\u4e4b\u72d0"  out: "爱尔兰之狐"
{    ; by RobertL
    Loop, Parse, uXXXX, u, \
  {
        retStr .= Chr("0x" . A_LoopField) ;为字符串添加16进制前缀。字符=Chr(编码)。
  }
    return retStr
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
