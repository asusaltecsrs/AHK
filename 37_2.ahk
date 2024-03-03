#SingleInstance, Force

URL := "http://192.168.3.2:3000/user"
HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")




HttpObj.Open("POST", URL, 0)
HttpObj.SetRequestHeader("Content-Type", "application/json")


; json_str := ({"username": "Any Name"})
json_str := ({username:123})


; Body := json_str
HttpObj.Send(json_str)

; MsgBox, %Body%
Result := HttpObj.ResponseText
Status := HttpObj.Status
msgbox % "status: " status "`n`nresult: " result
