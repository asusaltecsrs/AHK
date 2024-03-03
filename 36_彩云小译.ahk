from_lang := "en"
to_lang :=  "zh"
~^LButton:: ;按下ctrl+左键划词，然后翻译并将结果直接替换英文英语
    Clipboard:=
    KeyWait, Lbutton, up
    MouseGetPos, X, Y
    send,^c
    ClipWait, , 0
    if(pos:=InStr(Clipboard,"&"))
    {
        altkey:="(" . SubStr(Clipboard,pos,2) . ")"
        TranslateWords:=SubStr(Clipboard,1,pos-1) . SubStr(Clipboard,pos+1,StrLen(Clipboard))
        Clipboard:=Translate(from_lang,to_lang,TranslateWords) . altkey
    }
    Else
    {
        TranslateWords:=Clipboard
        Clipboard:=Translate(from_lang,to_lang,TranslateWords)
    }
    text= %Clipboard%
    ; MsgBox, %text%
    ;单行宽度
    If (StrLen(text)>=70){
        i := 1
        Loop, % StrLen(text)/70+1{
            text1 .= SubStr(text, i, 70)
            text1 .= "`n"
            i += 70
        }
    }
    Else text1 := text
    ; ret := btt(text1,,,,,{JustCalculateSize:1})   ;这两行的作用是持续显示
    ; btt(text1,(1920-ret.w)/2,1015-ret.h,,"Style2")   ;如果需要这两行起作用一定要放在beautifulltolltip文件夹下面
    MouseGetPos,x,y   ;获得鼠标位置
    tooltip,%text1%,%x%,%y%,1   
    Clipboard:=text1   ;复制到剪切板
    SetTimer, RemoveToolTip, -5000  ;工具条5秒后自动取消
Return
RemoveToolTip:
ToolTip
return
Translate(from_lang,to_lang,query)
{
    tro:={}
    appid := "你的ID"
    appkey := "你的秘钥"
    endpoint := "http://api.fanyi.baidu.com"
    path := "/api/trans/vip/translate"
    url := endpoint . path
    random salt,32768,65536
    sign := MD5(appid . query . salt . appkey)
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST", url . "?q=" . query . "&from=en&to=zh&appid=" . appid . "&salt=" . salt . "&sign=" . sign, true)
    whr.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    whr.Send()
    whr.WaitForResponse()
    tro:=json2obj(whr.ResponseText)
    ptr:=ObjectToPointer(whr)
    ObjRelease(ptr)
    Return,tro.trans_result.1.dst
}
json2obj(s)  ; Json字符串转AHK对象
{
  static rep:=[ ["\\","\u005c"], ["\""",""""]
    , ["\r","`r"], ["\n","`n"], ["\t","`t"]
    , ["\/","/"], ["\b","`b"], ["\f","`f"] ]
  if !(p:=RegExMatch(s, "[\{\[]", r))
    return
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  obj:=[], stack:=[], arr:=obj, flag:=r
  , key:=(flag="{" ? "":1), keyok:=0
  While p:=RegExMatch(s, "\S", r, p+StrLen(r))
  {
    if (r="{" or r="[")       ; 如果是 左括号
    {
      arr[key]:=[], stack.Push(arr, flag)
      , arr:=arr[key], flag:=r
      , key:=(flag="{" ? "":1), keyok:=0
    }
    else if (r="}" or r="]")  ; 如果是 右括号
    {
      if !stack.MaxIndex()
        Break
      flag:=stack.Pop(), arr:=stack.Pop()
      , key:=(flag="{" ? "":arr.MaxIndex()), keyok:=0
    }
    else if (r=",")           ; 如果是 逗号
    {
      key:=(flag="{" ? "":Round(key)+1), keyok:=0
    }
    else if (r="""")          ; 如果是 双引号
    {
      if !(RegExMatch(s, """((?:\\[\s\S]|[^""\\])*)""", r, p)=p)
        Break
      if InStr(r1, "\")
      {
        For k,v in rep
          r1:=StrReplace(r1, v.1, v.2)
        While RegExMatch(r1, "\\u[0-9A-Fa-f]{4}", k)
          r1:=StrReplace(r1, k, Chr("0x" SubStr(k,3)))
      }
      if (flag="{" and keyok=0)  ; 如果是 键名
      {
        p+=StrLen(r)
        if !(RegExMatch(s, "\s*:", r, p)=p)
          Break
        key:=r1, keyok:=1
      }
      else arr[key]:=r1
    }
    else if RegExMatch(s, "[\w\+\-\.]+", r, p)=p
    {
      arr[key]:=r  ; 如果是 数字、true、false、null
    }
    else Break
  }
  SetBatchLines, %bch%
  return obj
}
obj2json(obj, space:="")  ; AHK对象转Json字符串
{
  ; 默认不替换 "/-->\/" 与 "Unicode字符-->\uXXXX"
  static rep:=[ ["\\","\"], ["\""",""""]  ; , ["\/","/"]
    , ["\r","`r"], ["\n","`n"], ["\t","`t"]
    , ["\b","`b"], ["\f","`f"] ]
  if !IsObject(obj)
  {
    if obj is Number
      return obj
    if (obj=="true" or obj=="false" or obj=="null")
      return obj
    For k,v in rep
      obj:=StrReplace(obj, v.2, v.1)
    ; While RegExMatch(obj, "[^\x20-\x7e]", k)
    ;   obj:=StrReplace(obj, k, Format("\u{:04x}",Ord(k)))
    return """" obj """"
  }
  is_arr:=1  ; 是简单数组
  For k,v in obj
    if (k!=A_Index) and !(is_arr:=0)
      Break
  s:="", space2:=space . "    "
  For k,v in obj
    s.= "`r`n" space2 . (is_arr ? ""
      : """" Trim(%A_ThisFunc%(Trim(k)),"""") """: ")
      . %A_ThisFunc%(v,space2) . ","
  return (is_arr?"[":"{") . Trim(s,",")
       . "`r`n" space . (is_arr?"]":"}")
}
ObjectToPointer(obj) {
    if !IsObject(obj)
        return ""
    ptr := &obj
    ObjAddRef(ptr)
    return ptr
}
;自定义的MD5函数，来自https://www.autoahk.com/archives/18400
 
MD5(string, encoding = "UTF-8")
{
    return CalcStringHash(string, 0x8003, encoding)
}
 
; CalcAddrHash ======================================================================
CalcAddrHash(addr, length, algid, byref hash = 0, byref hashlength = 0)
{
    static h := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, "a", "b", "c", "d", "e", "f"]
    static b := h.minIndex()
    hProv := hHash := o := ""
    if (DllCall("advapi32\CryptAcquireContext", "Ptr*", hProv, "Ptr", 0, "Ptr", 0, "UInt", 24, "UInt", 0xf0000000))
    {
        if (DllCall("advapi32\CryptCreateHash", "Ptr", hProv, "UInt", algid, "UInt", 0, "UInt", 0, "Ptr*", hHash))
        {
            if (DllCall("advapi32\CryptHashData", "Ptr", hHash, "Ptr", addr, "UInt", length, "UInt", 0))
            {
                if (DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", 0, "UInt*", hashlength, "UInt", 0))
                {
                    VarSetCapacity(hash, hashlength, 0)
                    if (DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", &hash, "UInt*", hashlength, "UInt", 0))
                    {
                        loop % hashlength
                        {
                            v := NumGet(hash, A_Index - 1, "UChar")
                            o .= h[(v >> 4) + b] h[(v & 0xf) + b]
                        }
                    }
                }
            }
            DllCall("advapi32\CryptDestroyHash", "Ptr", hHash)
        }
        DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
    }
    return o
}
 
; CalcStringHash ====================================================================
CalcStringHash(string, algid, encoding = "UTF-8", byref hash = 0, byref hashlength = 0)
{
    chrlength := (encoding = "CP1200" || encoding = "UTF-16") ? 2 : 1
    length := (StrPut(string, encoding) - 1) * chrlength
    VarSetCapacity(data, length, 0)
    StrPut(string, &data, floor(length / chrlength), encoding)
    return CalcAddrHash(&data, length, algid, hash, hashlength)
}
