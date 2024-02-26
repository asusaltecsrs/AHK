colours := Object("red", 0xFF0000, "blue", 0x0000FF, "green", 0x00FF00)
; 上面的表达式可以直接代替下面的 "colours":
for k, v in colours
    s .= k "=" v "`n";点是拼接的意思
MsgBox % s
