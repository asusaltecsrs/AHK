result := UrlDownloadToVar("http://t.weather.sojson.com/api/weather/city/101270101","utf-8") ; 101270101为天气预报城市id  api接口https://www.sojson.com/api/weather.html
;msgbox %result% ;检查是否获取
city := json(result, "cityInfo.city")
tmp := json(result, "data.wendu")
quality := json(result, "data.quality")
htype := json(Result, "data.forecast[0].type") ;读取数组中的值
high0 := json(Result, "data.forecast[0].high")
low0 := json(Result, "data.forecast[0].low")
msgbox, %city%: %tmp%℃ %htype% `n 明日 %quality%  %high0% %low0%
Return
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
UrlDownloadToVar(URL,encode = "CP0", UserAgent = "", Proxy = "", ProxyBypass = "") 
{
    ; Requires Windows Vista, Windows XP, Windows 2000 Professional, Windows NT Workstation 4.0,
    ; Windows Me, Windows 98, or Windows 95.
    ; Requires Internet Explorer 3.0 or later.
    pFix:=a_isunicode ? "W" : "A"
    hModule := DllCall("LoadLibrary", "Str", "wininet.dll") 
    AccessType := Proxy != "" ? 3 : 1
    ;INTERNET_OPEN_TYPE_PRECONFIG                    0   // use registry configuration 
    ;INTERNET_OPEN_TYPE_DIRECT                       1   // direct to net 
    ;INTERNET_OPEN_TYPE_PROXY                        3   // via named proxy 
    ;INTERNET_OPEN_TYPE_PRECONFIG_WITH_NO_AUTOPROXY  4   // prevent using java/script/INS 
    io := DllCall("wininet\InternetOpen" . pFix
    , "Str", UserAgent ;lpszAgent 
    , "UInt", AccessType 
    , "Str", Proxy 
    , "Str", ProxyBypass 
    , "UInt", 0) ;dwFlags 
    iou := DllCall("wininet\InternetOpenUrl" . pFix
    , "UInt", io 
    , "Str", url 
    , "Str", "" ;lpszHeaders 
    , "UInt", 0 ;dwHeadersLength 
    , "UInt", 0x80000000 ;dwFlags: INTERNET_FLAG_RELOAD = 0x80000000 // retrieve the original item 
    , "UInt", 0) ;dwContext 
    If (ErrorLevel != 0 or iou = 0) { 
        DllCall("FreeLibrary", "UInt", hModule) 
        return 0 
    } 
    VarSetCapacity(buffer, 1024, 0)
    VarSetCapacity(BytesRead, 4, 0)
    Loop 
    { 
        ;http://msdn.microsoft.com/library/en-us/wininet/wininet/internetreadfile.asp
        irf := DllCall("wininet\InternetReadFile", "UInt", iou, "UInt", &buffer, "UInt", 1024, "UInt", &BytesRead) 
        VarSetCapacity(buffer, -1) ;to update the variable's internally-stored length
        BytesRead_ = 0 ; reset
        Loop, 4  ; Build the integer by adding up its bytes. (From ExtractInteger-function)
            BytesRead_ += *(&BytesRead + A_Index-1) << 8*(A_Index-1) ;Bytes read in this very DllCall
        ; To ensure all data is retrieved, an application must continue to call the
        ; InternetReadFile function until the function returns TRUE and the lpdwNumberOfBytesRead parameter equals zero.
        If (irf = 1 and BytesRead_ = 0)
            break
        Else ; append the buffer's contents
        {
            a_isunicode ? buffer:=StrGet(&buffer, encode) 
            Result .= SubStr(buffer, 1, BytesRead_ * (a_isunicode ? 2 : 1))
        }
        /* optional: retrieve only a part of the file
        BytesReadTotal += BytesRead_
        If (BytesReadTotal >= 30000) ; only read the first x bytes
        break                      ; (will be a multiple of the buffer size, if the file is not smaller; trim if neccessary)
        */
    }
    DllCall("wininet\InternetCloseHandle",  "UInt", iou) 
    DllCall("wininet\InternetCloseHandle",  "UInt", io) 
    DllCall("FreeLibrary", "UInt", hModule)
	return Result
}
