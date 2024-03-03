;/*
;===========================================
;  FindText - 屏幕抓字生成字库工具与找字函数
;  https://www.autohotkey.com/boards/viewtopic.php?f=6&t=17834
;
;  脚本作者 : FeiYue
;  最新版本 : 9.4
;  更新时间 : 2023-12-18
;
;  用法:  (需要最新版本 AHK v1.1.34+)
;  1. 将本脚本保存为“FindText.ahk”并复制到AHK执行程序的Lib子目录中（手动建立目录）
;  2. 抓图并生成调用FindText()的代码
;     2.1 方式一：直接点击“抓图”按钮
;     2.2 方式二：先设定截屏热键，使用热键截屏，再点击“截屏抓图”按钮
;  3. 测试一下调用的代码是否成功:直接点击“测试”按钮
;  4. 复制调用的代码到自己的脚本中
;     4.1 方式一：打勾“附加FindText()函数”的选框，然后点击“复制”按钮（不推荐）
;     4.2 方式二：取消“附加FindText()函数”的选框，然后点击“复制”按钮，
;         然后粘贴到自己的脚本中，然后在自己的脚本开头加上一行:
;         #Include <FindText>  ; Lib目录中必须有FindText.ahk
;  5. 多色查找模式可以一定程度上适应图像的放大缩小，常用于游戏中找图
;  6. 这个库还可以用于快速截屏、获取颜色、写入颜色、编辑后另存图片
;  7. 如果要调用FindTextClass类中的函数，请用无参数的FindText()获取类实例对象
;
;===========================================
;*/


if (!A_IsCompiled && A_LineFile=A_ScriptFullPath)
  FindText().Gui("Show")


;===== 复制下面的函数和类到你的代码中仅仅一次 =====


FindText(ByRef x:="FindTextClass", ByRef y:="", args*)
{
  static init, obj
  if (!VarSetCapacity(init) && init:="1")
    obj:=new FindTextClass()
  return (x=="FindTextClass" && !args.Length()) ? obj : obj.FindText(x, y, args*)
}

Class FindTextClass
{  ;// Class Begin

__New()
{
  this.bits:={ Scan0: 0, hBM: 0, oldzw: 0, oldzh: 0 }
  this.bind:={ id: 0, mode: 0, oldStyle: 0 }
  this.Lib:=[]
  this.Cursor:=0
}

__Delete()
{
  if (this.bits.hBM)
    DllCall("DeleteObject", "Ptr",this.bits.hBM)
}

New()
{
  return new FindTextClass()
}

help()
{
return "
(
;--------------------------------
;  FindText - 屏幕找字函数
;  版本 : 9.4  (2023-12-18)
;--------------------------------
;  返回变量:=FindText(
;      OutputX --> 保存返回的X坐标的变量名称
;    , OutputY --> 保存返回的Y坐标的变量名称
;    , X1 --> 查找范围的左上角X坐标
;    , Y1 --> 查找范围的左上角Y坐标
;    , X2 --> 查找范围的右下角X坐标
;    , Y2 --> 查找范围的右下角Y坐标
;    , err1 --> 文字的黑点容错百分率（0.1=10%）
;    , err0 --> 背景的白点容错百分率（0.1=10%）
;    , Text --> 由工具生成的查找图像的数据，可以一次查找多个，用“|”分隔
;    , ScreenShot --> 是否截屏，为0则使用上一次的截屏数据
;    , FindAll --> 是否搜索所有位置，为0则找到一个位置就返回
;    , JoinText --> 如果想组合查找，可以为1，或者是要查找单词的数组
;    , offsetX --> 组合图像的每个字和前一个字的最大横向间隔
;    , offsetY --> 组合图像的每个字和前一个字的最大高低间隔
;    , dir --> 查找的方向，有上、下、左、右、中心9种
;    , zoomW --> 图像宽度的缩放百分率（1.0=100%）
;    , zoomH --> 图像高度的缩放百分率（1.0=100%）
;  )
;
;  返回变量 --> 如果没找到结果会返回0。否则返回一个二级数组，
;      第一级是每个结果对象，第二级是结果对象的具体信息对象:
;      { 1:左上角X, 2:左上角Y, 3:图像宽度W, 4:图像高度H
;        , x:中心点X, y:中心点Y, id:图像识别文本 }
;  坐标都是相对于屏幕，颜色使用RGB格式
;
;  如果 OutputX 等于 'wait' 或 'wait1' 意味着等待图像出现，
;  如果 OutputX 等于 'wait0' 意味着等待图像消失
;  此时 OutputY 设置等待时间的秒数，如果小于0则无限等待
;  如果超时则返回0，意味着失败，如果等待图像出现成功，则返回位置数组
;  如果等待图像消失成功，则返回 1（注意这里的等待功能仅适用于静态图像）
;  例1: FindText(X:='wait', Y:=3, 0,0,0,0,0,0,Text)   ; 等待3秒等图像出现
;  例2: FindText(X:='wait0', Y:=-1, 0,0,0,0,0,0,Text) ; 无限等待等图像消失
;
;  <FindMultiColor> <FindColor> : 找色 是仅有一个点的 找多色
;  Text:='|<>##DRDGDB $ 0/0/RRGGBB1-DRDGDB1/RRGGBB2/-RRGGBB3, xn/yn/...'
;  '##'之后的颜色 (0xDRDGDB) 是所有颜色的默认偏色（各个分量允许的变化值）
;  初始点 (0,0) 匹配 0xRRGGBB1(+/-0xDRDGDB1) 或者 0xRRGGBB2(+/-0xDRDGDB)
;  或者 非 0xRRGGBB3(+/-0xDRDGDB)，满足其中一个就成功，是或的关系
;  每个点最多允许匹配10组颜色 (xn/yn/RRGGBB1/.../RRGGBB10)
;  以 '-' 开头的颜色，表示除了这种颜色的其他的任何颜色都匹配
;  如果在某个点(xn,yn)要同时排除多种颜色，几个条件是与的关系，
;  可以重复使用这个点的坐标，设置不同的条件 ',xn/yn/-RRGGBB1,xn/yn/-RRGGBB2'
;
;  <FindPic> : Text 参数需要手动输入
;  Text:='|<>##DRDGDB-RRGGBB1-RRGGBB2... $ d:\a.bmp'
;  0xRRGGBB1(+/-0xDRDGDB)... 都是透明色，不参与匹配
;
;--------------------------------
)"
}

FindText(ByRef OutputX:="", ByRef OutputY:=""
  , x1:=0, y1:=0, x2:=0, y2:=0, err1:=0, err0:=0, text:=""
  , ScreenShot:=1, FindAll:=1, JoinText:=0, offsetX:=20, offsetY:=10
  , dir:=1, zoomW:=1, zoomH:=1)
{
  local
  if (OutputX ~= "i)^\s*wait[10]?\s*$")
  {
    found:=!InStr(OutputX,"0"), time:=Round(OutputY,15)
    , timeout:=A_TickCount+Round(time*1000)
    Loop
    {
      ok:=this.FindText(,, x1, y1, x2, y2, err1, err0, text, ScreenShot
        , FindAll, JoinText, offsetX, offsetY, dir, zoomW, zoomH)
      if (found && ok)
      {
        OutputX:=ok[1].x, OutputY:=ok[1].y
        return ok
      }
      if (!found && !ok)
        return 1
      if (time>=0 && A_TickCount>=timeout)
        Break
      Sleep 50
    }
    return 0
  }
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  x1:=Floor(x1), y1:=Floor(y1), x2:=Floor(x2), y2:=Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
  , this.ok:=0, info:=[]
  Loop Parse, text, |
    if IsObject(j:=this.PicInfo(A_LoopField))
      info.Push(j)
  if (w<1 || h<1 || !(num:=info.Length()) || !bits.Scan0)
  {
    SetBatchLines, %bch%
    return 0
  }
  arr:=[], info2:=[], k:=0, s:=""
  , mode:=(IsObject(JoinText) ? 2 : JoinText ? 1 : 0)
  For i,j in info
  {
    k:=Max(k, (j[7]=5 && j[8]=0 ? j[9] : j[2]*j[3]))
    if (mode)
      v:=(mode=2 ? j[10] : i) . "", s.="|" v
      , (!info2.HasKey(v) && info2[v]:=[]), (v!="" && info2[v].Push(j))
  }
  sx:=x, sy:=y, sw:=w, sh:=h
  , JoinText:=(mode=1 ? [s] : JoinText)
  , VarSetCapacity(s1, k*4), VarSetCapacity(s0, k*4)
  , VarSetCapacity(ss, sw*(sh+2))
  , FindAll:=(dir=9 ? 1 : FindAll)
  , allpos_max:=(FindAll || JoinText ? 10240 : 1)
  , ini:={ sx:sx, sy:sy, sw:sw, sh:sh, zx:zx, zy:zy
  , mode:mode, bits:bits, ss:&ss, s1:&s1, s0:&s0
  , err1:err1, err0:err0, allpos_max:allpos_max
  , zoomW:zoomW, zoomH:zoomH }
  Loop 2
  {
    if (err1=0 && err0=0) && (num>1 || A_Index>1)
      ini.err1:=err1:=0.05, ini.err0:=err0:=0.05
    if (!JoinText)
    {
      VarSetCapacity(allpos, allpos_max*4), allpos_ptr:=&allpos
      For i,j in info
      Loop % this.PicFind(ini, j, dir, sx, sy, sw, sh, allpos_ptr)
      {
        pos:=NumGet(allpos, 4*(A_Index-1), "uint")
        , x:=(pos&0xFFFF)+zx, y:=(pos>>16)+zy
        , w:=Floor(j[2]*zoomW), h:=Floor(j[3]*zoomH), comment:=j[10]
        , arr.Push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:comment})
        if (!FindAll)
          Break 3
      }
    }
    else
    For k,v in JoinText
    {
      v:=StrSplit(Trim(RegExReplace(v, "\s*\|[|\s]*", "|"), "|")
      , (InStr(v,"|")?"|":""), " `t")
      , this.JoinText(arr, ini, info2, v, 1, offsetX, offsetY
      , FindAll, dir, 0, 0, 0, sx, sy, sw, sh)
      if (!FindAll && arr.Length())
        Break 2
    }
    if (err1!=0 || err0!=0 || arr.Length() || info[1][4] || info[1][7]=5)
      Break
  }
  if (dir=9 && arr.Length())
    arr:=this.Sort2(arr, (x1+x2)//2, (y1+y2)//2)
  SetBatchLines, %bch%
  if (arr.Length())
  {
    OutputX:=arr[1].x, OutputY:=arr[1].y, this.ok:=arr
    return arr
  }
  return 0
}

; 组合文本参数可以用数组 <==> [ "abc", "xyz", "a1|a2|a3" ]

JoinText(arr, ini, info2, text, index, offsetX, offsetY
  , FindAll, dir, minX, minY, maxY, sx, sy, sw, sh)
{
  local
  if !(Len:=text.Length())
    return 0
  VarSetCapacity(allpos, ini.allpos_max*4), allpos_ptr:=&allpos
  , zoomW:=ini.zoomW, zoomH:=ini.zoomH, mode:=ini.mode
  For i,j in info2[text[index]]
  if (mode!=2 || text[index]==j[10])
  Loop % this.PicFind(ini, j, dir, sx, sy, (index=1 ? sw
  : Min(sx+offsetX+Floor(j[2]*zoomW),ini.sx+ini.sw)-sx), sh, allpos_ptr)
  {
    pos:=NumGet(allpos, 4*(A_Index-1), "uint")
    , x:=pos&0xFFFF, y:=pos>>16
    , w:=Floor(j[2]*zoomW), h:=Floor(j[3]*zoomH)
    , (index=1 && (minX:=x, minY:=y, maxY:=y+h))
    , minY1:=Min(y, minY), maxY1:=Max(y+h, maxY), sx1:=x+w
    if (index<Len)
    {
      sy1:=Max(minY1-offsetY, ini.sy)
      , sh1:=Min(maxY1+offsetY, ini.sy+ini.sh)-sy1
      if this.JoinText(arr, ini, info2, text, index+1, offsetX, offsetY
      , FindAll, 5, minX, minY1, maxY1, sx1, sy1, 0, sh1)
      && (index>1 || !FindAll)
        return 1
    }
    else
    {
      comment:=""
      For k,v in text
        comment.=(mode=2 ? v : info2[v][1][10])
      x:=minX+ini.zx, y:=minY1+ini.zy, w:=sx1-minX, h:=maxY1-minY1
      , arr.Push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:comment})
      if (index>1 || !FindAll)
        return 1
    }
  }
  return 0
}

PicFind(ini, j, dir, sx, sy, sw, sh, allpos_ptr)
{
  local
  static MyFunc:=""
  if (!MyFunc)
  {
    x32:="VVdWU4PEgIO8JJQAAAAFi6wkzAAAAA+EoAoAAIu8JNAAAACF@w+O7RAAAMcEJAAA"
    . "AADHRCQQAAAAADH@x0QkHAAAAADHRCQUAAAAAIuEJMgAAACLTCQUMfYx2wHIhe2J"
    . "RCQMf0HplAAAAI22AAAAAA+vhCS0AAAAicGJ8Jn3@QHBi0QkDIA8GDF0TIuEJMQA"
    . "AACDwwEDtCTkAAAAiQy4g8cBOd10VIsEJJn3vCTQAAAAg7wklAAAAAR1tQ+vhCSo"
    . "AAAAicGJ8Jn3@Y0MgYtEJAyAPBgxdbSLRCQci5QkwAAAAIPDAQO0JOQAAACJDIKD"
    . "wAE53YlEJBx1rAFsJBSDRCQQAYuMJOgAAACLRCQQAQwkOYQk0AAAAA+FLv@@@4tM"
    . "JBy7rYvbaIl8JCQPr4wk1AAAAInIwfkf9+vB+gwpyouMJNgAAACJVCQYD6@PicjB"
    . "+R@368H6DCnKiVQkKIO8JJQAAAAED4RNCgAAi4QkqAAAAIu0JKwAAAAPr4QksAAA"
    . "AIuMJKgAAACNPLCLhCS0AAAA99iNBIGJRCQwi4QklAAAAIXAD4VWAwAAi4QkmAAA"
    . "AIusJLgAAADHRCQsAAAAAMdEJDQAAAAAwegQD7bAiUQkDIuEJJgAAAAPtsSJRCQQ"
    . "D7aEJJgAAACJRCQUi4QktAAAAMHgAoXtiUQkPA+OvQAAAIu0JLQAAACF9g+OlAAA"
    . "AIu0JKQAAACLbCQ0A6wkvAAAAAH+A3wkPIl8JDgDvCSkAAAAiTwkifaNvCcAAAAA"
    . "D7ZOAotcJAwPtkYBD7YWK0QkECtUJBSJzwHZKd+NmQAEAAAPr8APr9@B4AsPr98B"
    . "w7j+BQAAKcgPr8IPr9AB0zmcJJwAAAAPk0UAg8YEg8UBOzQkdaqLjCS0AAAAAUwk"
    . "NIt8JDiDRCQsAQN8JDCLRCQsOYQkuAAAAA+FQ@@@@4tEJBiJRCREi0QkKIlEJFyL"
    . "dCQci0wkRDHAOc6LTCRcD07wiXQkHIt0JCQ5zg9PxolEJCSLdCQki0QkHDnGD03G"
    . "iUQkFIuEJJQAAACD6ASD+AEPhnQHAADHRCRkAAAAAMdEJHAAAAAAi0QkcAOEJLQA"
    . "AAArhCTkAAAAiUQkdItEJGQDhCS4AAAAK4Qk6AAAAIlEJEyLhCSgAAAAg+gBg@gH"
    . "D4fpBgAAg@gDiUQkVA+O5AYAAIt0JGSLRCRwiXQkcIlEJGSLdCR0OXQkZA+P5AYA"
    . "AItEJHSLTCQci3QkVMdEJDwAAAAAiUQkeIuEJMAAAACNBIiJRCRgifCD4AGJRCRY"
    . "ifCD4AOJRCR8i0QkcIt0JEw58A+PAQEAAIN8JHwBi0wkZA9PTCR4iXQkQIlEJCyJ"
    . "TCRQi0QkWIXAi0QkQA9ERCQsg3wkVAOJRCQ0D49PAgAAg7wklAAAAAWLRCRQiUQk"
    . "OItEJDgPhFcCAACDvCSUAAAABA+EKwQAAA+vhCS0AAAAi0wkFIt0JDSFyY0sMA+E"
    . "4AMAAIt0JFyLXCREMcCLlCS8AAAAiWwkEItMJByLfCQkiRwkiXQkDAHqi2wkFOsL"
    . "g8ABOcUPhKUDAAA5yH0Xi5wkwAAAAIs0gwHWgD4AdQaDLCQBeBw5x37Wi5wkxAAA"
    . "AIs0gwHWgD4BdcWDbCQMAXm+g0QkLAGDbCRAAYtEJCw5RCRMD40Z@@@@g0QkZAGD"
    . "bCR4AYtEJGQ5RCR0D43X@v@@i0QkPIPsgFteX13CWACDvCSUAAAAAQ+EQgsAAIO8"
    . "JJQAAAACD4QtCQAAi4QkmAAAAA+2jCScAAAAx0QkFAAAAADHRCQsAAAAAMHoEA+2"
    . "wIkEJIuEJJgAAAAPtsSJRCQMD7aEJJgAAACJRCQQi4QknAAAAMHoEA+26IuEJJwA"
    . "AACJ7g+v9Q+2xIl0JCCJxg+v8InID6@BiXQkCIlEJASLhCS0AAAAweACiUQkNIuE"
    . "JLgAAACFwA+OEv3@@4uEJLQAAACFwA+OfgAAAIuUJKQAAACLXCQsA5wkvAAAAAH6"
    . "A3wkNIl8JDgDvCSkAAAAif0PtkICMf8PtkoBKwQkD7YyD6@AOUQkIHwiK0wkDA+v"
    . "yTlMJAh8FYnwD7bwK3QkEA+v9jl0JAQPncCJx4n4g8IEg8MBiEP@Oep1touMJLQA"
    . "AAABTCQsi3wkOINEJBQBA3wkMItEJBQ5hCS4AAAAD4VZ@@@@6Wb8@@+NtCYAAAAA"
    . "i0QkNIO8JJQAAAAFiUQkOItEJFCJRCQ0i0QkOA+Fqf3@@w+vhCSoAAAAi0wkNIts"
    . "JGiF7Y0EiIlEJDAPhQUDAACLRCRsi3wkFMdEJBgAAAAAiUQkKItEJESF@4lEJEgP"
    . "hBsBAACLfCQgjbQmAAAAAItMJBiLtCTAAAAAi0QkMAMEjou0JMQAAACNFImNHJGL"
    . "VCQoizSOi4wkpAAAAIkUJIm0JJwAAACLtCSkAAAAD7Z0BgKJdCQMi7QkpAAAAA+2"
    . "dAYBD7YEAYl0JBCJRCQgid7reYsEJIPGAosIi1gEiciJ38HoEMHvEA+2wCtEJAyJ"
    . "+g+2+g+21w+224n9iVwkBDHbD6@viVQkCA+vwDnofysPtsUrRCQQidUPr+oPr8A5"
    . "6H8Yi1QkBA+2wStEJCCJ0w+v2g+vwDnYD57DgwQkCIH5@@@@AA+XwDjYdRg5tCSc"
    . "AAAAD4d6@@@@g2wkSAEPiIICAACDRCQYAYNEJChUi0QkGDlEJBQPhfT+@@+JfCQg"
    . "i4Qk3AAAAINEJDwBi0wkPIXAD4TK@P@@i1QkOAOUJLAAAACLRCQ0A4QkrAAAAIu0"
    . "JNwAAADB4hAJ0DuMJOAAAACJRI78D4yX@P@@6cL8@@+LbCQQi1QkHIXSdKSLtCS8"
    . "AAAAi4QkwAAAAItcJGCNDC6LEIPABAHKOdjGAgB18ul8@@@@D6+EJKgAAACLdCQ0"
    . "i1wkFI0EsIu0JKQAAACJBCQDhCSYAAAAhduJ8Q+2bAYCD7Z0BgEPtgQBiXQkDIlE"
    . "JBAPhDj@@@+LRCRcMduJbCQYiUQkMItEJESJRCQoZpA7XCQcfWSLhCTAAAAAixQk"
    . "i3wkGAMUmA+2dBECD7ZEEQErRCQMD7YUEStUJBCJ9QH+Kf2NvgAEAAAPr8APr@3B"
    . "4AsPr@0Bx7j+BQAAKfAPr8IPr9AB1zu8JJwAAAB2C4NsJCgBD4iY+@@@OVwkJH5k"
    . "i4QkxAAAAIsUJIt8JBgDFJgPtnQRAg+2RBEBK0QkDA+2FBErVCQQifUB@in9jb4A"
    . "BAAAD6@AD6@9weALD6@9Ace4@gUAACnwD6@CD6@QAdc7vCScAAAAdwuDbCQwAQ+I"
    . "Lvv@@4PDATlcJBQPhR@@@@@pOv7@@4t0JBSF9g+ELv7@@4t0JESLnCSkAAAAMdKQ"
    . "i4QkwAAAAIt8JDADPJCLhCTEAAAAiyyQD7ZEOwKJ6cHpEA+2ySnID7ZMOwEPtjw7"
    . "D6@AO0QkIH8niegPtsQpwQ+vyTtMJAh@F4n4D7b4iegPtsApxw+v@zt8JAR+B2aQ"
    . "g+4BeBWDwgE5VCQUdZKJrCSYAAAA6ab9@@+JrCSYAAAA6Xz6@@+JfCQg6XP6@@@H"
    . "RCRUAAAAAIt0JHSLRCRMiXQkTIlEJHSLdCR0OXQkZA+OHPn@@8dEJDwAAAAAi0Qk"
    . "PIPsgFteX13CWACLhCSwAAAAx4QksAAAAAAAAACJRCRki4QkrAAAAMeEJKwAAAAA"
    . "AAAAiUQkcOlr+P@@i7QkmAAAADHAhfYPlcCJRCRoD4U6AQAAi5wknAAAAIXbD4R@"
    . "BgAAi7QknAAAAIu8JMAAAACLnCTEAAAAjQS3MfaJBCSLhCTIAAAAMdKDxwSDwwSL"
    . "BLCJhCSYAAAAwegE9@UPr4Qk6AAAAIlUJAyZ97wk0AAAAA+vhCSoAAAAicGLRCQM"
    . "D6+EJOQAAACZ9@2NBIGJR@yLhCSYAAAAg+APjQRGg8YViUP8OzwkdZeLhCScAAAA"
    . "i4wk1AAAALqti9toD6@IiUQkHInIwfkf9+qJ0MH4DCnIi7QkyAAAAIlEJETHRCRc"
    . "AAAAAMdEJCQAAAAAg8YEiXQkbOkX9@@@i4QkmAAAAMHoEA+vhCToAAAAmfe8JNAA"
    . "AAAPr4QkqAAAAInBD7eEJJgAAAAPr4Qk5AAAAJn3@Y0EgYmEJJgAAACLRCQYiUQk"
    . "RItEJCiJRCRc6cH2@@+LhCTQAAAAi7QkyAAAAA+2lCSYAAAAD6@FjQSGiUQkbIuE"
    . "JJgAAADB6BAPtsiLhCSYAAAAic4Pr@GLjCTQAAAAD7bEiXQkIInGD6@widAPr8KF"
    . "yYl0JAiJRCQED47OBAAAi3QkbI0ErQAAAACJrCTMAAAAi5wkmAAAAIu8JJwAAACL"
    . "bCQgiUQkNDHAx0QkLAAAAADHRCQwAAAAAMdEJBwAAAAAiTQki5QkzAAAAIXSD44a"
    . "AQAAi4wkyAAAAIs0JMdEJBQAAAAAiVwkKAHBA0QkNIlMJBCJRCQ4A4QkyAAAAIlE"
    . "JCSLRCQQhf8PtlABD7ZIAg+2AIkUJIlEJAx0RjHSZpCLHJaJ2MHoEA+2wCnID6@A"
    . "OcV8Iw+2xysEJA+vwDlEJAh8FA+2wytEJAwPr8A5RCQED435AAAAg8IBOfp1wolc"
    . "JCiLRCQcweEQweACiUQkGItEJCyZ97wk0AAAAA+vhCSoAAAAicOLRCQUmfe8JMwA"
    . "AACLVCQcjQSDi5wkwAAAAIkEk4sEJIPCAYucJMQAAACJVCQcweAICcELTCQMi0Qk"
    . "GIkMA4NEJBAEi5Qk5AAAAItEJBABVCQUO0QkJA+FIP@@@4tcJCiLRCQ4iTQkg0Qk"
    . "MAGLtCToAAAAi0wkMAF0JCw5jCTQAAAAD4W2@v@@i0wkHLqti9toiZwkmAAAAA+v"
    . "jCTUAAAAx0QkXAAAAADHRCQkAAAAAInIwfkf9+rB+gwpyolUJETplPT@@5CNdCYA"
    . "iVwkKOlr@@@@i4wktAAAAIuEJLwAAAAx7YuUJLgAAADHBCQAAAAAjQRIiUQkNInI"
    . "weAChdKJRCQMD45A9P@@i4QktAAAAIXAfleLjCSkAAAAi0QkNAH5A3wkDI0cKIl8"
    . "JBADvCSkAAAAD7ZRAg+2QQGDwQQPtnH8g8MBa8BLa9ImAcKJ8MHgBCnwAdDB+AeI"
    . "Q@85+XXTA6wktAAAAIt8JBCDBCQBA3wkMIsEJDmEJLgAAAB1iouEJLQAAACLvCSc"
    . "AAAAMfbHRCQMAAAAAIPoAYlEJCyLhCS4AAAAg+gBiUQkMIuEJLQAAACFwA+O7QAA"
    . "AItEJAyLjCS0AAAAi6wkvAAAAIXAi0QkNA+URCQUAfGJTCQ4icONFDABy4nxK4wk"
    . "tAAAAAHuiXQkEAHBMcCJDCTpkgAAAIB8JBQAD4WPAAAAOUQkLA+EhQAAAItMJAw5"
    . "TCQwdHsPtjoPtmr@vgEAAAADvCSYAAAAOe9yPA+2agE573I0iwwkD7YpOe9yKg+2"
    . "KznvciMPtmn@Oe9yGw+2aQE573ITD7Zr@znvcgsPtnMBOfcPksGJzotsJBCJ8YhM"
    . "BQCDwAGDwgGDwwGDBCQBOYQktAAAAHQShcAPhWb@@@+LdCQQxgQGAuvYi3QkOINE"
    . "JAwBi0QkDDmEJLgAAAAPhe7+@@+LRCQYibwknAAAAIlEJESLRCQoiUQkXOl@8v@@"
    . "i4QkmAAAAIucJLgAAAAx7ccEJAAAAACDwAHB4AeJhCSYAAAAi4QktAAAAMHgAoXb"
    . "iUQkDA+ONfL@@4uMJLQAAACFyX5mi4wkpAAAAIucJLwAAACJbCQUAfkDfCQMAeuL"
    . "rCSYAAAAiXwkEAO8JKQAAAAPtlECD7ZBAQ+2MWvAS2vSJgHCifDB4AQp8AHCOdUP"
    . "lwODwQSDwwE5+XXVi2wkFAOsJLQAAACLfCQQgwQkAQN8JDCLBCQ5hCS4AAAAD4V3"
    . "@@@@6afx@@@HRCQoAAAAAMdEJBgAAAAAx0QkJAAAAADHRCQcAAAAAOkg8P@@x0Qk"
    . "RAAAAADHRCQcAAAAAMdEJFwAAAAAx0QkJAAAAADpkfH@@zHAx0QkHAAAAADpIPr@"
    . "@5CQkJCQkJCQkJCQkJCQkA=="
    x64:="QVdBVkFVQVRVV1ZTSIHsuAAAAEiLtCQgAQAAi5wkcAEAAIP5BYmMJAABAACJ1UWJ"
    . "xUSJjCQYAQAARIu8JHgBAAAPhDIMAABFhf8PjlASAABEiXQkEIl8JBgxwIu8JAAB"
    . "AABEi6wkQAEAAEUx0kyLtCRgAQAAi6wkoAEAAEUx20SJZCQgx0QkCAAAAABBicTH"
    . "RCQoAAAAAImUJAgBAABEiYQkEAEAAEiJtCQgAQAASGN0JChFMclFMcBIA7QkaAEA"
    . "AIXbfzfrfWYPH4QAAAAAAEEPr8WJwUSJyJn3+wHBQoA8BjF0PUmDwAFJY8NBAelB"
    . "g8MBRDnDQYkMhn5ERInQmUH3@4P@BHXID6+EJCgBAACJwUSJyJn3+0KAPAYxjQyB"
    . "dcNIi5QkWAEAAEmDwAFJY8RBAelBg8QBRDnDiQyCf7wBXCQog0QkCAFEA5QkqAEA"
    . "AItEJAhBOccPhVD@@@9EieFBuK2L22hEi3QkEA+vjCSAAQAARIlkJFSLrCQIAQAA"
    . "RItkJCBEi6wkEAEAAEiLtCQgAQAAi3wkGESJXCQIicjB+R9B9+jB+gwpyouMJIgB"
    . "AACJVCQQQQ+vy4nIwfkfQffowfoMKcqJVCQYg7wkAAEAAAQPhIMLAACLhCQoAQAA"
    . "i5wkMAEAAA+vhCQ4AQAAjQSYi5wkKAEAAIlEJCiLhCRAAQAA99iNBIOLnCQAAQAA"
    . "iUQkLIXbD4X6AwAAiehEi5wkSAEAAMHoEA+22EiJ6A+2xEWF24nBQA+2xYnCD44X"
    . "BQAAi4QkQAEAAImsJAgBAABEi3wkKIusJEABAABEiXQkQESJZCRIQYnWweACx0Qk"
    . "IAAAAADHRCQwAAAAAIlEJDiJfCRQQYnMhe0PjooAAABIY3wkMEljx0Ux20gDvCRQ"
    . "AQAATI1UBgIPH4QAAAAAAEEPtlL+RQ+2CkEPtkL@RCnyRInJQYnQQo0UCynZRCng"
    . "RI2KAAQAAA+vwEQPr8nB4AtED6@Juf4FAAAp0YnKQQ+v0EGNBAFBD6@QAdBBOcVC"
    . "D5MEH0mDwwFJg8IERDndf59EA3wkOAFsJDCDRCQgAUQDfCQsi0QkIDmEJEgBAAAP"
    . "hVP@@@+LRCQQRIt0JECLfCRQRItkJEiLrCQIAQAAiUQkWItEJBiJhCSAAAAAi1wk"
    . "VItMJFgxwDnLi4wkgAAAAA9O2IlcJFSLXCQIOcsPT8OJRCQIi1wkCItEJFQ5ww9N"
    . "w0GJw4uEJAABAACD6ASD+AEPhpsIAADHhCSMAAAAAAAAAMeEJKAAAAAAAAAAi4Qk"
    . "oAAAAAOEJEABAAArhCSgAQAAiYQkpAAAAIuEJIwAAAADhCRIAQAAK4QkqAEAAIlE"
    . "JGCLhCQYAQAAg+gBg@gHD4f+BwAAg@gDiUQkaA+O+QcAAIucJIwAAACLhCSgAAAA"
    . "iZwkoAAAAImEJIwAAACLnCSkAAAAOZwkjAAAAA+P8wcAAIuEJKQAAABIi5wkWAEA"
    . "AImsJAgBAABEieVFidxEibQkhAAAAMdEJEAAAAAARYnuiYQkqAAAAItEJFSJvCSI"
    . "AAAAg+gBSI1EgwRIiUQkeEGNQ@9JifNIi7QkUAEAAEiNRIMEi1wkaEiJRCRIidiD"
    . "4AGJRCRsidiD4AOJhCSsAAAAi4QkoAAAAIt8JGA5+A+PBQEAAIO8JKwAAAABi5wk"
    . "jAAAAA9PnCSoAAAAiXwkUIlEJCCJXCRkDx+EAAAAAACLTCRsi0QkUIXJD0REJCCD"
    . "fCRoA4lEJCwPj1QCAACDvCQAAQAABYtEJGSJRCQwD4RcAgAAg7wkAAEAAAQPhFQE"
    . "AACLTCQwD6+MJEABAAADTCQsRYXkD4QJBAAARIuUJIAAAABEi0wkWDHARItEJFSL"
    . "fCQITIusJFgBAABMi7wkYAEAAOsNSIPAAUE5xA+O0gMAAEE5wInCfhOJy0EDXIUA"
    . "gDweAHUGQYPpAXgWOdd+1YnKQQMUh4A8FgF1yUGD6gF5w4NEJCABg2wkUAGLRCQg"
    . "OUQkYA+NJv@@@4OEJIwAAAABg6wkqAAAAAGLhCSMAAAAOYQkpAAAAA+NxP7@@4tE"
    . "JEBIgcS4AAAAW15fXUFcQV1BXkFfw4O8JAABAAABD4S3CwAAg7wkAAEAAAIPhIcJ"
    . "AABIiehEi4QkSAEAAEEPts0PtsSJ60GJzEGJw0APtsXB6xCJRCQgRInoD7bbwegQ"
    . "x0QkMAAAAADHRCQ4AAAAAA+20EyJ6A+2xEGJ1onHD6@4i4QkQAEAAEQPr@JEjTyF"
    . "AAAAAEQPr+FFhcAPjrkAAACJrCQIAQAAi6wkQAEAAESJrCQQAQAARYndhe1+b0hj"
    . "RCQoTGNcJDhFMcBMA5wkUAEAAEiNVAYCDx+EAAAAAAAPtgJFMdIPtkr@RA+2Sv4p"
    . "2A+vwEE5xnwaRCnpD6@JOc98EEQrTCQgRQ+vyUU5zEEPncJHiBQDSYPAAUiDwgRE"
    . "OcV@vEQBfCQoAWwkOItUJCyDRCQwAQFUJCiLRCQwOYQkSAEAAA+Fb@@@@4usJAgB"
    . "AABEi6wkEAEAAItEJBCJRCRYi0QkGImEJIAAAADp6@v@@4tEJCyDvCQAAQAABYlE"
    . "JDCLRCRkiUQkLA+FpP3@@4tEJDCLfCQsD6+EJCgBAACLlCSQAAAAhdKNBLiJRCQ4"
    . "D4VVAwAARYXkD4RRAQAASIu8JGABAABIi4QkWAEAAESLrCSEAAAASIm0JJgAAADH"
    . "RCQoAAAAAESJpCSUAAAASIl8JBBIi3wkcEiJxkiJfCQYi3wkWIl8JFyLvCSIAAAA"
    . "i0QkOAMGSItcJBBEi0QkKEiLVCQYjUgBRIszRI1IAkiYSGPJTWPJRQ+2JANBD7Yc"
    . "C0cPthQLQYnZ63QPH0QAAItKBIsaQYPAAkGJzYnYD7b9wegQQcHtEA+26UUPtu0P"
    . "tsAxyUQp0EWJ7w+vwEUPr@1EOfh@KA+2x0GJ@0QpyA+vwEQPr@9EOfh@Ew+2w4np"
    . "RCngD6@ND6@AOcgPnsFIg8IIgfv@@@8AD5fAOMh1EEU5xneMg2wkXAEPiBADAABI"
    . "g8YESINEJBAEg0QkKBVIg0QkGFRIO3QkSA+FIf@@@0SLpCSUAAAASIu0JJgAAABE"
    . "iawkhAAAAIm8JIgAAABmkINEJEABSIO8JJABAAAAi3wkQA+Emvz@@4tEJDADhCQ4"
    . "AQAASGPXi0wkLAOMJDABAABIi5wkkAEAAMHgEAnIO7wkmAEAAIlEk@wPjGP8@@@p"
    . "mvz@@4tEJFSFwHSkSIuEJFgBAABMi0QkeA8fgAAAAACJygMQSIPABEw5wMYEFgB1"
    . "7+l6@@@@i0QkMIt8JCwPr4QkKAEAAI0EuInBA4QkCAEAAEWF5I1QAkhj0kEPthwT"
    . "jVABSJhBD7YEA0hj0kEPtjwTQYn9D4Q1@@@@i7wkgAAAAIlsJBhFMcmJzUGJx0iJ"
    . "dCQ4iXwkEIt8JFiJfCQoi3wkVEQ5z0WJyn5uSIuEJFgBAABCixSIAeqNQgJImEEP"
    . "tgwDjUIBSGPSQQ+2FBNImEEPtgQDic4B2USNgQAEAAAp3kQp+kQPr8ZEKegPr8BE"
    . "D6@GweALQQHAuP4FAAApyA+vwg+v0EEB0EU58HYLg2wkKAEPiEcBAABEOVQkCH5w"
    . "SIuEJGABAABCixSIAeqNQgJImEEPtgwDjUIBSGPSQQ+2FBNImEEPtgQDQYnKAdlE"
    . "jYEABAAAQSnaRCn6RQ+vwkQp6A+vwEUPr8LB4AtBAcC4@gUAACnID6@CD6@QQQHQ"
    . "RTnwdwuDbCQQAQ+I0AAAAEmDwQFFOcwPjwb@@@+LbCQYSIt0JDjpBf7@@0WF5A+E"
    . "@P3@@0SJdCQoRItMJFgxyUSLrCSEAAAAi7wkiAAAAESLVCQ4TIu0JFgBAABMi7wk"
    . "YAEAAEGLFI5BixyPRAHSQYnYjUICQcHoEEUPtsBImEEPtgQDRCnARI1CAUhj0g+v"
    . "wEEPthQTTWPARw+2BANEOeh@HQ+2x0EpwEUPr8BBOfh@Dg+2wynCD6@SOep+CGaQ"
    . "QYPpAXgoSIPBAUE5zH+ViZwkCAEAAESLdCQo6VD9@@+LbCQYSIt0JDjp9Pn@@4mc"
    . "JAgBAABEi3QkKOnj+f@@RImsJIQAAACJvCSIAAAARIukJJQAAABIi7QkmAAAAOm@"
    . "+f@@x0QkaAAAAACLnCSkAAAAi0QkYIlcJGCJhCSkAAAAi5wkpAAAADmcJIwAAAAP"
    . "jg34@@@HRCRAAAAAAOm8+f@@i4QkOAEAAMeEJDgBAAAAAAAAiYQkjAAAAIuEJDAB"
    . "AADHhCQwAQAAAAAAAImEJKAAAADpRPf@@zHAhdIPlcCJhCSQAAAAD4UTAQAARTHJ"
    . "RTHbRYXATIuUJGgBAAAPhEkGAABBiyox0kmDwlSJ6MHoBPfzD6+EJKgBAACJ0ZlB"
    . "9@8Pr4QkKAEAAEGJwIuEJKABAAAPr8FIi4wkWAEAAJn3+0GNBIBCiQSJiehIi4wk"
    . "YAEAAIPgD0GNBENBg8MVQokEiUmDwQFFOc13mIuMJIABAAC6rYvbaESJbCRUQQ+v"
    . "zYnIwfkf9+qJ0MH4DCnISIucJGgBAACJRCRYx4QkgAAAAAAAAADHRCQIAAAAAEiD"
    . "wwRIiVwkcOkB9v@@iejB6BAPr4QkqAEAAJlB9@8Pr4QkKAEAAInBD7fFD6+EJKAB"
    . "AACZ9@uNLIGLRCQQiUQkWItEJBiJhCSAAAAA6b31@@+J2EEPr8fB4AJImEgDhCRo"
    . "AQAASIlEJHCJ0A+20sHoEEGJ1A+2yEiJ6A+2xEGJzonHRA+v8Q+v+EQPr+JFhf8P"
    . "juAEAACNQ@9Ii0wkcEGNUP@HRCQoAAAAAMdEJBAAAAAASI0EhQYAAADHRCQYAAAA"
    . "AESJhCQQAQAATI1UkQQx0onpSIlEJCCNBJ0AAAAAQYnVSIm0JCABAACJnCRwAQAA"
    . "iUQkLESJvCR4AQAAi7QkcAEAAIX2D47tAAAASGNEJBhIi7QkaAEAAEiNXAYCSANE"
    . "JCBIAfAx9kiJRCQIDx9AAIusJBABAABED7YDRA+2S@9ED7Zb@oXtdEBIi1QkcGaQ"
    . "iwqJyMHoEA+2wEQpwA+vwEE5xnwbD7bFRCnID6@AOcd8Dg+2wUQp2A+vwEE5xH1a"
    . "SIPCBEw50nXHi0QkKE1j@UHB4BBBweEIQYPFAUUJyJlFCdj3vCR4AQAAD6+EJCgB"
    . "AACJxYnwmfe8JHABAABIi5QkWAEAAI1EhQBCiQS6SIuEJGABAABGiQS4SIPDBAO0"
    . "JKABAABIOVwkCA+FQP@@@4t0JCwBdCQYg0QkEAGLnCSoAQAAi0QkEAFcJCg5hCR4"
    . "AQAAD4Xj@v@@RIlsJFSJzYtMJFQPr4wkgAEAALqti9toRIusJBABAABIi7QkIAEA"
    . "AMeEJIAAAAAAAAAAx0QkCAAAAACJyMH5H@fqwfoMKcqJVCRY6aTz@@+LhCRAAQAA"
    . "RIuMJEgBAABFMdsx2wHASJhIA4QkUAEAAEWFyUiJRCQwi4QkQAEAAESNPIUAAAAA"
    . "D45k9@@@iXwkIIu8JEABAACF@35PSGNEJChMY9NMA1QkMEUxwEiNTAYCD7YRD7ZB"
    . "@0iDwQRED7ZJ+mvAS2vSJgHCRInIweAERCnIAdDB+AdDiAQCSYPAAUQ5x3@NRAF8"
    . "JCgB+0GDwwGLTCQsAUwkKEQ5nCRIAQAAdZdIY4QkQAEAALoBAAAASIm0JCABAACL"
    . "tCRAAQAAi3wkIEUx28dEJCwAAAAASI1YAUgpwouEJEABAABIiVQkQEiJXCQ4g+gB"
    . "iUQkKIuEJEgBAACD6AGJRCQghfYPjt8AAABMY0wkLEiLTCQ4RYXbSItEJDBMi5Qk"
    . "UAEAAA+Uw06NBAlIi0wkQEqNVAgBTQHKSQHATAHJSAHBMcDpjgAAAITbD4WOAAAA"
    . "OUQkKA+EhAAAAEQ5XCQgdH1ED7Zq@0QPtnr+QbkBAAAAQQHtRTn9ckVED7Y6RTn9"
    . "cjxED7Z5@0U5@XIyRQ+2eP9FOf1yKEQPtnn+RTn9ch5ED7Y5RTn9chVFD7Z4@kU5"
    . "@XILRQ+2CEU5zUEPksFFiAwCSIPAAUiDwgFJg8ABSIPBATnGfg+FwA+Fav@@@0HG"
    . "BAIC690BdCQsQYPDAUQ5nCRIAQAAD4UH@@@@i0QkEEiLtCQgAQAAiUQkWItEJBiJ"
    . "hCSAAAAA6YLx@@+NRQFEi5QkSAEAAEUx2zHbweAHicWLhCRAAQAARYXSRI08hQAA"
    . "AAAPjlL1@@9EiXQkIESLtCRAAQAARYX2flNIY0QkKExj00wDlCRQAQAARTHASI1M"
    . "BgIPthEPtkH@RA+2Sf5rwEtr0iYBwkSJyMHgBEQpyAHQOcVDD5cEAkmDwAFIg8EE"
    . "RTnGf81EAXwkKEQB80GDwwGLTCQsAUwkKEQ5nCRIAQAAdZKLRCQQRIt0JCCJRCRY"
    . "i0QkGImEJIAAAADpvfD@@8dEJBgAAAAAx0QkEAAAAADHRCQIAAAAAMdEJFQAAAAA"
    . "6Qbv@@@HRCRYAAAAAMeEJIAAAAAAAAAAx0QkVAAAAADHRCQIAAAAAOmX8P@@McDH"
    . "RCRUAAAAAOkz+v@@kJCQkA=="
    this.MCode(MyFunc, StrReplace((A_PtrSize=8?x64:x32),"@","/"))
  }
  text:=j[1], w:=j[2], h:=j[3]
  , err1:=(j[4] ? j[5] : ini.err1)
  , err0:=(j[4] ? j[6] : ini.err0)
  , mode:=j[7], color:=j[8], n:=j[9]
  return (!ini.bits.Scan0) ? 0 : DllCall(&MyFunc
    , "int",mode, "uint",color, "uint",n, "int",dir
    , "Ptr",ini.bits.Scan0, "int",ini.bits.Stride
    , "int",sx, "int",sy, "int",sw, "int",sh
    , "Ptr",ini.ss, "Ptr",ini.s1, "Ptr",ini.s0
    , (mode=5 ? "Ptr":"AStr"),text, "int",w, "int",h
    , "int",Floor(err1*10000), "int",Floor(err0*10000)
    , "Ptr",allpos_ptr, "int",ini.allpos_max
    , "int",Floor(w*ini.zoomW), "int",Floor(h*ini.zoomH))
}

code()
{
return "
(

//***** 机器码的 C语言 源代码 *****

int __attribute__((__stdcall__)) PicFind(
  int mode, unsigned int c, unsigned int n, int dir
  , unsigned char * Bmp, int Stride
  , int sx, int sy, int sw, int sh
  , unsigned char * ss, unsigned int * s1, unsigned int * s0
  , unsigned char * text, int w, int h, int err1, int err0
  , unsigned int * allpos, int allpos_max
  , int new_w, int new_h )
{
  int ok, o, i, j, k, v, e1, e0, len1, len0, max;
  int x, y, x1, y1, x2, y2, x3, y3;
  int r, g, b, rr, gg, bb, dR, dG, dB;
  unsigned int c1, c2;
  unsigned char * gs;
  unsigned int * cors;
  ok=0; o=0; len1=0; len0=0;
  //----------------------
  // 找多色、找单色、搜图模式
  if (mode==5)
  {
    if (k=(c!=0))  // FindPic
    {
      cors=(unsigned int *)(text+w*h*4);
      r=(c>>16)&0xFF; g=(c>>8)&0xFF; b=c&0xFF;
      dR=r*r; dG=g*g; dB=b*b;
      for (y=0; y<h; y++)
      {
        for (x=0; x<w; x++, o+=4)
        {
          rr=text[2+o]; gg=text[1+o]; bb=text[o];
          for (i=0; i<n; i++)
          {
            c=cors[i]; r=((c>>16)&0xFF)-rr;
            g=((c>>8)&0xFF)-gg; b=(c&0xFF)-bb;
            if (r*r<=dR && g*g<=dG && b*b<=dB) goto NoMatch1;
          }
          s1[len1]=(y*new_h/h)*Stride+(x*new_w/w)*4;
          s0[len1++]=(rr<<16)|(gg<<8)|bb;
          NoMatch1:;
        }
      }
    }
    else  // FindMultiColor or FindColor
    {
      cors=(unsigned int *)text;
      for (; len1<n; len1++, o+=21)
      {
        c=cors[o]; y=(c>>4)/w; x=(c>>4)%w;
        s1[len1]=(y*new_h/h)*Stride+(x*new_w/w)*4;
        s0[len1]=o+(c&0xF)*2;
      }
      cors++;
    }
    goto StartLookUp;
  }
  //----------------------
  // 生成查表需要的表格
  for (y=0; y<h; y++)
  {
    for (x=0; x<w; x++)
    {
      if (mode==4)
        i=(y*new_h/h)*Stride+(x*new_w/w)*4;
      else
        i=(y*new_h/h)*sw+(x*new_w/w);
      if (text[o++]=='1')
        s1[len1++]=i;
      else
        s0[len0++]=i;
    }
  }
  //----------------------
  // 颜色位置模式
  // 仅用于多色验证码的识别
  if (mode==4)
  {
    y=c>>16; x=c&0xFFFF;
    c=(y*new_h/h)*Stride+(x*new_w/w)*4;
    goto StartLookUp;
  }
  //----------------------
  // 生成二值化图像
  o=sy*Stride+sx*4; j=Stride-sw*4; i=0;
  if (mode==0)  // 颜色相似二值化
  {
    rr=(c>>16)&0xFF; gg=(c>>8)&0xFF; bb=c&0xFF;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
      {
        r=Bmp[2+o]-rr; g=Bmp[1+o]-gg; b=Bmp[o]-bb; v=r+rr+rr;
        ss[i]=((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=n) ? 1:0;
      }
  }
  else if (mode==1)  // 灰度阈值二值化
  {
    c=(c+1)<<7;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
        ss[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15<c) ? 1:0;
  }
  else if (mode==2)  // 灰度差值二值化
  {
    gs=ss+sw*2;
    for (y=0; y<sh; y++, o+=j)
    {
      for (x=0; x<sw; x++, o+=4, i++)
        gs[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15)>>7;
    }
    for (i=0, y=0; y<sh; y++)
      for (x=0; x<sw; x++, i++)
      {
        if (x==0 || y==0 || x==sw-1 || y==sh-1)
          ss[i]=2;
        else
        {
          n=gs[i]+c;
          ss[i]=(gs[i-1]>n || gs[i+1]>n
          || gs[i-sw]>n   || gs[i+sw]>n
          || gs[i-sw-1]>n || gs[i-sw+1]>n
          || gs[i+sw-1]>n || gs[i+sw+1]>n) ? 1:0;
        }
      }
  }
  else  // (mode==3) 颜色分量二值化
  {
    rr=(c>>16)&0xFF; gg=(c>>8)&0xFF; bb=c&0xFF;
    r=(n>>16)&0xFF; g=(n>>8)&0xFF; b=n&0xFF;
    dR=r*r; dG=g*g; dB=b*b;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
      {
        r=Bmp[2+o]-rr; g=Bmp[1+o]-gg; b=Bmp[o]-bb;
        ss[i]=(r*r<=dR && g*g<=dG && b*b<=dB) ? 1:0;
      }
  }
  //----------------------
  StartLookUp:
  err1=len1*err1/10000;
  err0=len0*err0/10000;
  if (err1>=len1) len1=0;
  if (err0>=len0) len0=0;
  max=(len1>len0) ? len1 : len0;
  if (mode==5 || mode==4)
  {
    x1=sx; y1=sy; sx=0; sy=0;
  }
  else
  {
    x1=0; y1=0;
  }
  x2=x1+sw-new_w; y2=y1+sh-new_h;
  // 1 ==> ( Left to Right ) Top to Bottom
  // 2 ==> ( Right to Left ) Top to Bottom
  // 3 ==> ( Left to Right ) Bottom to Top
  // 4 ==> ( Right to Left ) Bottom to Top
  // 5 ==> ( Top to Bottom ) Left to Right
  // 6 ==> ( Bottom to Top ) Left to Right
  // 7 ==> ( Top to Bottom ) Right to Left
  // 8 ==> ( Bottom to Top ) Right to Left
  if (dir<1 || dir>8) dir=1;
  if (--dir>3) { r=y1; y1=x1; x1=r; r=y2; y2=x2; x2=r; }
  for (y3=y1; y3<=y2; y3++)
  {
    for (x3=x1; x3<=x2; x3++)
    {
      y=((dir&3)>1) ? y1+y2-y3 : y3;
      x=(dir&1) ? x1+x2-x3 : x3;
      if (dir>3) { r=y; y=x; x=r; }
      //----------------------
      e1=err1; e0=err0;
      if (mode==5)
      {
        o=y*Stride+x*4;
        if (k)
        {
          for (i=0; i<max; i++)
          {
            j=o+s1[i]; c=s0[i]; r=Bmp[2+j]-((c>>16)&0xFF);
            g=Bmp[1+j]-((c>>8)&0xFF); b=Bmp[j]-(c&0xFF);
            if ((r*r>dR || g*g>dG || b*b>dB) && (--e1)<0) goto NoMatch;
          }
        }
        else
        {
          for (i=0; i<max; i++)
          {
            j=o+s1[i]; rr=Bmp[2+j]; gg=Bmp[1+j]; bb=Bmp[j];
            for (j=i*21, n=s0[i]; j<n;)
            {
              c1=cors[j++]; c2=cors[j++];
              r=((c1>>16)&0xFF)-rr; g=((c1>>8)&0xFF)-gg; b=(c1&0xFF)-bb;
              dR=(c2>>16)&0xFF; dG=(c2>>8)&0xFF; dB=c2&0xFF;
              if ((r*r<=dR*dR && g*g<=dG*dG && b*b<=dB*dB)^(c1>0xFFFFFF))
                goto MatchOK;
            }
            if ((--e1)<0) goto NoMatch;
            MatchOK:;
          }
        }
      }
      else if (mode==4)
      {
        o=y*Stride+x*4;
        j=o+c; rr=Bmp[2+j]; gg=Bmp[1+j]; bb=Bmp[j];
        for (i=0; i<max; i++)
        {
          if (i<len1)
          {
            j=o+s1[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
            if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b>n && (--e1)<0) goto NoMatch;
          }
          if (i<len0)
          {
            j=o+s0[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
            if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=n && (--e0)<0) goto NoMatch;
          }
        }
      }
      else
      {
        o=y*sw+x;
        for (i=0; i<max; i++)
        {
          if (i<len1 && ss[o+s1[i]]==0 && (--e1)<0) goto NoMatch;
          if (i<len0 && ss[o+s0[i]]==1 && (--e0)<0) goto NoMatch;
        }
        // 清空已经找到的图像
        for (i=0; i<len1; i++)
          ss[o+s1[i]]=0;
      }
      ok++;
      if (allpos!=0)
      {
        allpos[ok-1]=(sy+y)<<16|(sx+x);
        if (ok>=allpos_max) goto Return1;
      }
      NoMatch:;
    }
  }
  //----------------------
  Return1:
  return ok;
}

)"
}

PicInfo(text)
{
  local
  if !InStr(text, "$")
    return
  static init, info, bmp
  if (!VarSetCapacity(init) && init:="1")
    info:=[], bmp:=[]
  key:=(r:=StrLen(text))<10000 ? text
    : DllCall("ntdll\RtlComputeCrc32", "uint",0
    , "Ptr",&text, "uint",r*(1+!!A_IsUnicode), "uint")
  if info.HasKey(key)
    return info[key]
  v:=text, comment:="", seterr:=err1:=err0:=0
  ; You Can Add Comment Text within The <>
  if RegExMatch(v, "O)<([^>\n]*)>", r)
    v:=StrReplace(v,r[0]), comment:=Trim(r[1])
  ; You can Add two fault-tolerant in the [], separated by commas
  if RegExMatch(v, "O)\[([^\]\n]*)]", r)
  {
    v:=StrReplace(v,r[0]), r:=StrSplit(r[1] ",", ",")
    , seterr:=1, err1:=r[1], err0:=r[2]
  }
  color:=SubStr(v,1,InStr(v,"$")-1), v:=Trim(SubStr(v,InStr(v,"$")+1))
  mode:=InStr(color,"##") ? 5
    : InStr(color,"#") ? 4 : InStr(color,"-") ? 3
    : InStr(color,"**") ? 2 : InStr(color,"*") ? 1 : 0
  color:=RegExReplace(color, "[*#\s]")
  (mode=0 || mode=3 || mode=5) && color:=StrReplace(color,"0x")
  if (mode=5)
  {
    if !(v~="/[\s\-\w]+/[\s\-\w,/]+$")  ; FindPic
    {
      ; 你可以使用 Text:="|<>##DRDGDB-RRGGBB1-RRGGBB2... $ d:\a.bmp"
      ; 那么 0xRRGGBB1(+/-0xDRDGDB)... 都是透明色
      if !(hBM:=LoadPicture(v))
        return
      this.GetBitmapWH(hBM, w, h)
      if (w<1 || h<1)
        return
      hBM2:=this.CreateDIBSection(w, h, 32, Scan0)
      this.CopyHBM(hBM2, 0, 0, hBM, 0, 0, w, h)
      DllCall("DeleteObject", "Ptr",hBM)
      if (!Scan0)
        return
      ; 所有用于搜索的图片都缓存了
      StrReplace(color, "-",, n)
      bmp.Push(buf:=this.Buffer(w*h*4+n*4)), v:=buf.Ptr
      DllCall("RtlMoveMemory", "Ptr",v, "Ptr",Scan0, "Ptr",w*h*4)
      DllCall("DeleteObject", "Ptr",hBM2)
      p:=v+w*h*4-4
      , tab:=Object("Black", "000000", "White", "FFFFFF"
      , "Red", "FF0000", "Green", "008000", "Blue", "0000FF"
      , "Yellow", "FFFF00", "Silver", "C0C0C0", "Gray", "808080"
      , "Teal", "008080", "Navy", "000080", "Aqua", "00FFFF"
      , "Olive", "808000", "Lime", "00FF00", "Fuchsia", "FF00FF"
      , "Purple", "800080", "Maroon", "800000")
      For k1,v1 in StrSplit(color, "-")
      if (k1>1)
        NumPut(Floor("0x" (tab.HasKey(v1)?tab[v1]:v1)), 0|p+=4, "uint")
      color:=Floor("0x" StrSplit(color "-", "-")[1])|0x1000000
    }
    else  ; FindMultiColor or FindColor
    {
      ; Text:='|<>##DRDGDB $ 0/0/RRGGBB1-DRDGDB1/RRGGBB2/-RRGGBB3, xn/yn/...'
      ; '##'之后的颜色 (0xDRDGDB) 是所有颜色的默认偏色（各个分量允许的变化值）
      ; 初始点 (0,0) 匹配 0xRRGGBB1(+/-0xDRDGDB1) 或者 0xRRGGBB2(+/-0xDRDGDB)
      ; 或者 非 0xRRGGBB3(+/-0xDRDGDB)
      ; 每个点可以允许匹配10组颜色 (xn/yn/RRGGBB1/.../RRGGBB10)
      ; 以 '-' 开头的颜色，表示排除这种颜色
      ; 如果要同时排除多种颜色可以这样： ',xn/yn/-RRGGBB1,xn/yn/-RRGGBB2'
      arr:=StrSplit(Trim(RegExReplace(v, "i)\s|0x"), ","), ",")
      if !(n:=arr.Length())
        return
      bmp.Push(buf:=this.Buffer(n*(1+10+10)*4)), v:=buf.Ptr
      , color:=StrSplit(color "-", "-")[1]
      For k1,v1 in arr
      {
        r:=StrSplit(v1 "/", "/")
        , x:=Floor(r[1]), y:=Floor(r[2])
        , (A_Index=1) ? (x1:=x2:=x, y1:=y2:=y)
        : (x1:=Min(x1,x), x2:=Max(x2,x)
        , y1:=Min(y1,y), y2:=Max(y2,y))
      }
      w:=x2-x1+1, h:=y2-y1+1
      For k1,v1 in arr
      {
        r:=StrSplit(v1 "/", "/")
        , x:=Floor(r[1])-x1, y:=Floor(r[2])-y1
        , n1:=Min(Max(r.Length()-3, 0), 10)
        , NumPut((y*w+x)<<4|n1, 0|p:=v+(A_Index-1)*84, "uint")
        Loop % n1
          k1:=(InStr(v1:=r[2+A_Index], "-")=1 ? 0x1000000:0)
          , c:=StrSplit(Trim(v1,"-") "-" color, "-")
          , NumPut(Floor("0x" c[1])&0xFFFFFF|k1, 0|p+=4, "uint")
          , NumPut(Floor("0x" c[2]), 0|p+=4, "uint")
      }
      color:=0
    }
  }
  else
  {
    r:=StrSplit(v ".", "."), w:=Floor(r[1])
    , v:=this.base64tobit(r[2]), h:=StrLen(v)//w
    if (w<1 || h<1 || StrLen(v)!=w*h)
      return
    if (mode=3)
    {
      r:=StrSplit(color, "-")
      , color:=Floor("0x" r[1]), n:=Floor("0x" r[2])
    }
    else
    {
      r:=StrSplit(color "@1", "@")
      , color:=Floor((mode=0?"0x":"") r[1]), n:=r[2]
      , n:=(n<=0||n>1?1:n), n:=Floor(4606*255*255*(1-n)*(1-n))
      , (mode=4) && color:=((color-1)//w)<<16|Mod(color-1,w)
    }
  }
  return info[key]:=[v, w, h, seterr, err1, err0, mode, color, n, comment]
}

Buffer(size, FillByte:="")
{
  local
  buf:={}, buf.SetCapacity("a", size), p:=buf.GetAddress("a")
  , (FillByte!="" && DllCall("RtlFillMemory","Ptr",p,"Ptr",size,"uchar",FillByte))
  , buf.Ptr:=p, buf.Size:=size
  return buf
}

GetBitsFromScreen(ByRef x:=0, ByRef y:=0, ByRef w:=0, ByRef h:=0
  , ScreenShot:=1, ByRef zx:=0, ByRef zy:=0, ByRef zw:=0, ByRef zh:=0)
{
  local
  static CAPTUREBLT:=""
  (!IsObject(this.bits) && this.bits:={Scan0:0, hBM:0, oldzw:0, oldzh:0})
  , bits:=this.bits
  if (!ScreenShot && bits.Scan0)
  {
    zx:=bits.zx, zy:=bits.zy, zw:=bits.zw, zh:=bits.zh
    , w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
    , h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
    return bits
  }
  bch:=A_BatchLines, cri:=A_IsCritical
  Critical
  if (id:=this.BindWindow(0,0,1))
  {
    WinGet, id, ID, ahk_id %id%
    WinGetPos, zx, zy, zw, zh, ahk_id %id%
  }
  if (!id)
  {
    SysGet, zx, 76
    SysGet, zy, 77
    SysGet, zw, 78
    SysGet, zh, 79
  }
  this.UpdateBits(bits, zx, zy, zw, zh)
  , w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
  , h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
  if (!ScreenShot || w<1 || h<1 || !bits.hBM)
  {
    Critical, %cri%
    SetBatchLines, %bch%
    return bits
  }
  if IsFunc(k:="GetBitsFromScreen2")
    && %k%(bits, x-zx, y-zy, w, h)
  {
    ; Each small range of data obtained from DXGI must be
    ; copied to the screenshot cache using this.CopyBits()
    zx:=bits.zx, zy:=bits.zy, zw:=bits.zw, zh:=bits.zh
    Critical, %cri%
    SetBatchLines, %bch%
    return bits
  }
  if (CAPTUREBLT="")  ; thanks Descolada
  {
    DllCall("Dwmapi\DwmIsCompositionEnabled", "Int*",i:=0)
    CAPTUREBLT:=i ? 0 : 0x40000000
  }
  mDC:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM:=DllCall("SelectObject", "Ptr",mDC, "Ptr",bits.hBM, "Ptr")
  if (id)
  {
    if (mode:=this.BindWindow(0,0,0,1))<2
    {
      hDC:=DllCall("GetDCEx", "Ptr",id, "Ptr",0, "int",3, "Ptr")
      DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
        , "Ptr",hDC, "int",x-zx, "int",y-zy, "uint",0xCC0020|CAPTUREBLT)
      DllCall("ReleaseDC", "Ptr",id, "Ptr",hDC)
    }
    else
    {
      hBM2:=this.CreateDIBSection(zw, zh)
      mDC2:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
      oBM2:=DllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
      DllCall("PrintWindow", "Ptr",id, "Ptr",mDC2, "uint",(mode>3)*3)
      DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
        , "Ptr",mDC2, "int",x-zx, "int",y-zy, "uint",0xCC0020)
      DllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
      DllCall("DeleteDC", "Ptr",mDC2)
      DllCall("DeleteObject", "Ptr",hBM2)
    }
  }
  else
  {
    hDC:=DllCall("GetWindowDC","Ptr",id:=DllCall("GetDesktopWindow","Ptr"),"Ptr")
    DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
      , "Ptr",hDC, "int",x, "int",y, "uint",0xCC0020|CAPTUREBLT)
    DllCall("ReleaseDC", "Ptr",id, "Ptr",hDC)
  }
  if this.CaptureCursor(0,0,0,0,0,1)
    this.CaptureCursor(mDC, zx, zy, zw, zh)
  DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
  DllCall("DeleteDC", "Ptr",mDC)
  Critical, %cri%
  SetBatchLines, %bch%
  return bits
}

UpdateBits(bits, zx, zy, zw, zh)
{
  local
  if (zw>bits.oldzw || zh>bits.oldzh || !bits.hBM)
  {
    Try DllCall("DeleteObject", "Ptr",bits.hBM)
    bits.hBM:=this.CreateDIBSection(zw, zh, bpp:=32, ppvBits)
    , bits.Scan0:=(!bits.hBM ? 0:ppvBits)
    , bits.Stride:=((zw*bpp+31)//32)*4
    , bits.oldzw:=zw, bits.oldzh:=zh
  }
  bits.zx:=zx, bits.zy:=zy, bits.zw:=zw, bits.zh:=zh
}

CreateDIBSection(w, h, bpp:=32, ByRef ppvBits:=0)
{
  local
  VarSetCapacity(bi, 40, 0), NumPut(40, bi, 0, "int")
  , NumPut(w, bi, 4, "int"), NumPut(-h, bi, 8, "int")
  , NumPut(1, bi, 12, "short"), NumPut(bpp, bi, 14, "short")
  return DllCall("CreateDIBSection", "Ptr",0, "Ptr",&bi
    , "int",0, "Ptr*",ppvBits:=0, "Ptr",0, "int",0, "Ptr")
}

GetBitmapWH(hBM, ByRef w, ByRef h)
{
  local
  VarSetCapacity(bm, size:=(A_PtrSize=8 ? 32:24))
  , DllCall("GetObject", "Ptr",hBM, "int",size, "Ptr",&bm)
  , w:=NumGet(bm,4,"int"), h:=Abs(NumGet(bm,8,"int"))
}

CopyHBM(hBM1, x1, y1, hBM2, x2, y2, w, h, Clear:=0, trans:=0, alpha:=255)
{
  local
  if (w<1 || h<1 || !hBM1 || !hBM2)
    return
  mDC1:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM1:=DllCall("SelectObject", "Ptr",mDC1, "Ptr",hBM1, "Ptr")
  mDC2:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM2:=DllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
  if (trans)
    DllCall("GdiAlphaBlend", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
    , "Ptr",mDC2, "int",x2, "int",y2, "int",w, "int",h, "uint",alpha<<16)
  else
    DllCall("BitBlt", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
    , "Ptr",mDC2, "int",x2, "int",y2, "uint",0xCC0020)
  if (Clear)
    DllCall("BitBlt", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
    , "Ptr",mDC1, "int",x1, "int",y1, "uint",MERGECOPY:=0xC000CA)
  DllCall("SelectObject", "Ptr",mDC1, "Ptr",oBM1)
  DllCall("DeleteDC", "Ptr",mDC1)
  DllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
  DllCall("DeleteDC", "Ptr",mDC2)
}

CopyBits(Scan01,Stride1,x1,y1,Scan02,Stride2,x2,y2,w,h,Reverse:=0)
{
  local
  if (w<1 || h<1 || !Scan01 || !Scan02)
    return
  static init, MFCopyImage
  if (!VarSetCapacity(init) && init:="1")
  {
    MFCopyImage:=DllCall("GetProcAddress", "Ptr"
    , DllCall("LoadLibrary", "Str","Mfplat.dll", "Ptr")
    , "AStr","MFCopyImage", "Ptr")
  }
  if (MFCopyImage && !Reverse)  ; thanks QQ:任性
  {
    return DllCall(MFCopyImage
      , "Ptr",Scan01+y1*Stride1+x1*4, "int",Stride1
      , "Ptr",Scan02+y2*Stride2+x2*4, "int",Stride2
      , "uint",w*4, "uint",h)
  }
  ListLines % (lls:=A_ListLines)?0:0
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  p1:=Scan01+(y1-1)*Stride1+x1*4
  , p2:=Scan02+(y2-1)*Stride2+x2*4, w*=4
  if (Reverse)
    p2+=(h+1)*Stride2, Stride2:=-Stride2
  Loop % h
    DllCall("RtlMoveMemory","Ptr",p1+=Stride1,"Ptr",p2+=Stride2,"Ptr",w)
  SetBatchLines, %bch%
  ListLines %lls%
}

DrawHBM(hBM, lines)
{
  local
  mDC:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM:=DllCall("SelectObject", "Ptr",mDC, "Ptr",hBM, "Ptr")
  oldc:="", brush:=0, VarSetCapacity(rect, 16)
  For k,v in lines  ; [ [x, y, w, h, color] ]
  if IsObject(v)
  {
    if (oldc!=v[5])
    {
      oldc:=v[5], BGR:=(oldc&0xFF)<<16|oldc&0xFF00|(oldc>>16)&0xFF
      DllCall("DeleteObject", "Ptr",brush)
      brush:=DllCall("CreateSolidBrush", "UInt",BGR, "Ptr")
    }
    DllCall("SetRect", "Ptr",&rect, "int",v[1], "int",v[2]
      , "int",v[1]+v[3], "int",v[2]+v[4])
    DllCall("FillRect", "Ptr",mDC, "Ptr",&rect, "Ptr",brush)
  }
  DllCall("DeleteObject", "Ptr",brush)
  DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
  DllCall("DeleteObject", "Ptr",mDC)
}

; 绑定窗口从而可以后台查找这个窗口的图像
; 相当于始终在前台。解绑窗口使用 FindText().BindWindow(0)

BindWindow(bind_id:=0, bind_mode:=0, get_id:=0, get_mode:=0)
{
  local
  (!IsObject(this.bind) && this.bind:={id:0, mode:0, oldStyle:0})
  , bind:=this.bind
  if (get_id)
    return bind.id
  if (get_mode)
    return bind.mode
  if (bind_id)
  {
    bind.id:=bind_id, bind.mode:=bind_mode, bind.oldStyle:=0
    if (bind_mode & 1)
    {
      WinGet, i, ExStyle, ahk_id %bind_id%
      bind.oldStyle:=i
      WinSet, Transparent, 255, ahk_id %bind_id%
      Loop 30
      {
        Sleep 100
        WinGet, i, Transparent, ahk_id %bind_id%
      }
      Until (i=255)
    }
  }
  else
  {
    bind_id:=bind.id
    if (bind.mode & 1)
      WinSet, ExStyle, % bind.oldStyle, ahk_id %bind_id%
    bind.id:=0, bind.mode:=0, bind.oldStyle:=0
  }
}

; 使用 FindText().CaptureCursor(1) 设置抓图时捕获鼠标
; 使用 FindText().CaptureCursor(0) 取消抓图时捕获鼠标

CaptureCursor(hDC:=0, zx:=0, zy:=0, zw:=0, zh:=0, get_cursor:=0)
{
  local
  if (get_cursor)
    return this.Cursor
  if (hDC=1 || hDC=0) && (zw=0)
  {
    this.Cursor:=hDC
    return
  }
  VarSetCapacity(mi, 40, 0), NumPut(16+A_PtrSize, mi, "int")
  DllCall("GetCursorInfo", "Ptr",&mi)
  bShow:=NumGet(mi, 4, "int")
  hCursor:=NumGet(mi, 8, "Ptr")
  x:=NumGet(mi, 8+A_PtrSize, "int")
  y:=NumGet(mi, 12+A_PtrSize, "int")
  if (!bShow) || (x<zx || y<zy || x>=zx+zw || y>=zy+zh)
    return
  VarSetCapacity(ni, 40, 0)
  DllCall("GetIconInfo", "Ptr",hCursor, "Ptr",&ni)
  xCenter:=NumGet(ni, 4, "int")
  yCenter:=NumGet(ni, 8, "int")
  hBMMask:=NumGet(ni, (A_PtrSize=8?16:12), "Ptr")
  hBMColor:=NumGet(ni, (A_PtrSize=8?24:16), "Ptr")
  DllCall("DrawIconEx", "Ptr",hDC
    , "int",x-xCenter-zx, "int",y-yCenter-zy, "Ptr",hCursor
    , "int",0, "int",0, "int",0, "int",0, "int",3)
  DllCall("DeleteObject", "Ptr",hBMMask)
  DllCall("DeleteObject", "Ptr",hBMColor)
}

MCode(ByRef code, hex)
{
  local
  flag:=((hex~="[^\s\da-fA-F]")?1:4), hex:=RegExReplace(hex, "[\s=]")
  VarSetCapacity(code, len:=(flag=1 ? StrLen(hex)//4*3+3 : StrLen(hex)//2))
  DllCall("crypt32\CryptStringToBinary", "Str",hex, "uint",0
    , "uint",flag, "Ptr",&code, "uint*",len, "Ptr",0, "Ptr",0)
  DllCall("VirtualProtect", "Ptr",&code, "Ptr",len, "uint",0x40, "Ptr*",0)
}

bin2hex(addr, size, base64:=1)
{
  local
  flag:=(base64 ? 1|0x40000000 : 4|0x0000000C)
  Loop 2
    p:=(A_Index=1 ? 0 : VarSetCapacity(hex,len*2)*0 + &hex)
    , DllCall("Crypt32\CryptBinaryToString", "Ptr",addr, "uint",size
    , "uint",flag, "Ptr",p, "uint*",len:=0)
  return RegExReplace(StrGet(p, len), "\s+")
}

base64tobit(s)
{
  local
  ListLines % (lls:=A_ListLines)?0:0
  Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  SetFormat, IntegerFast, d
  Loop Parse, Chars
    if InStr(s, A_LoopField, 1)
      s:=RegExReplace(s, "[" A_LoopField "]", ((i:=A_Index-1)>>5&1)
      . (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1))
  s:=RegExReplace(RegExReplace(s,"[^01]+"),"10*$")
  ListLines %lls%
  return s
}

bit2base64(s)
{
  local
  ListLines % (lls:=A_ListLines)?0:0
  s:=RegExReplace(s,"[^01]+")
  s.=SubStr("100000",1,6-Mod(StrLen(s),6))
  s:=RegExReplace(s,".{6}","|$0")
  Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  SetFormat, IntegerFast, d
  Loop Parse, Chars
    s:=StrReplace(s, "|" . ((i:=A_Index-1)>>5&1)
    . (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1), A_LoopField)
  ListLines %lls%
  return s
}

ASCII(s)
{
  local
  if RegExMatch(s, "O)\$(\d+)\.([\w+/]+)", r)
  {
    s:=RegExReplace(this.base64tobit(r[2]),".{" r[1] "}","$0`n")
    s:=StrReplace(StrReplace(s,"0","_"),"1","0")
  }
  else s:=""
  return s
}

; 可以在脚本的开头用 FindText().PicLib(Text,1) 导入字库,
; 然后使用 FindText().PicLib("说明文字1|说明文字2|...") 获取字库中的数据

PicLib(comments, add_to_Lib:=0, index:=1)
{
  local
  (!IsObject(this.Lib) && this.Lib:=[]), Lib:=this.Lib
  , (!Lib.HasKey(index) && Lib[index]:=[]), Lib:=Lib[index]
  if (add_to_Lib)
  {
    re:="O)<([^>\n]*)>[^$\n]+\$[^""\r\n]+"
    Loop Parse, comments, |
      if RegExMatch(A_LoopField, re, r)
      {
        s1:=Trim(r[1]), s2:=""
        Loop Parse, s1
          s2.="_" . Format("{:d}",Ord(A_LoopField))
        Lib[s2]:=r[0]
      }
    Lib[""]:=""
  }
  else
  {
    Text:=""
    Loop Parse, comments, |
    {
      s1:=Trim(A_LoopField), s2:=""
      Loop Parse, s1
        s2.="_" . Format("{:d}",Ord(A_LoopField))
      if Lib.HasKey(s2)
        Text.="|" . Lib[s2]
    }
    return Text
  }
}

; 分割字符串为单个文字并获取数据

PicN(Number, index:=1)
{
  return this.PicLib(RegExReplace(Number,".","|$0"), 0, index)
}

; 使用 FindText().PicX(Text) 可以将文字分割成多个单字的组合，从而适应间隔变化
; 但是不能用于“颜色位置二值化”模式, 因为位置是与整体图像相关的

PicX(Text)
{
  local
  if !RegExMatch(Text, "O)(<[^$\n]+)\$(\d+)\.([\w+/]+)", r)
    return Text
  v:=this.base64tobit(r[3]), Text:=""
  c:=StrLen(StrReplace(v,"0"))<=StrLen(v)//2 ? "1":"0"
  txt:=RegExReplace(v,".{" r[2] "}","$0`n")
  While InStr(txt,c)
  {
    While !(txt~="m`n)^" c)
      txt:=RegExReplace(txt,"m`n)^.")
    i:=0
    While (txt~="m`n)^.{" i "}" c)
      i:=Format("{:d}",i+1)
    v:=RegExReplace(txt,"m`n)^(.{" i "}).*","$1")
    txt:=RegExReplace(txt,"m`n)^.{" i "}")
    if (v!="")
      Text.="|" r[1] "$" i "." this.bit2base64(v)
  }
  return Text
}

; 截屏，作为后续操作要用的“上一次的截屏”

ScreenShot(x1:=0, y1:=0, x2:=0, y2:=0)
{
  this.FindText(,, x1, y1, x2, y2)
}

; 从“上一次的截屏”中快速获取指定坐标的RGB颜色
; 如果坐标超出了屏幕范围，将返回白色

GetColor(x, y, fmt:=1)
{
  local
  bits:=this.GetBitsFromScreen(,,,,0,zx,zy,zw,zh)
  , c:=(x<zx || x>=zx+zw || y<zy || y>=zy+zh || !bits.Scan0)
  ? 0xFFFFFF : NumGet(bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4,"uint")
  return (fmt ? Format("0x{:06X}",c&0xFFFFFF) : c)
}

; 在“上一次的截屏”中设置点的RGB颜色

SetColor(x, y, color:=0x000000)
{
  local
  bits:=this.GetBitsFromScreen(,,,,0,zx,zy,zw,zh)
  if !(x<zx || x>=zx+zw || y<zy || y>=zy+zh || !bits.Scan0)
    NumPut(color, bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4, "uint")
}

; 根据 FindText() 的结果识别一行文字或验证码
; offsetX 为两个文字的最大间隔，超过会插入*号
; offsetY 为两个文字的最大高度差
; overlapW 用于设置覆盖的宽度
; 最后返回数组:{text:识别结果, x:结果左上角X, y:结果左上角Y, w:宽, h:高}

Ocr(ok, offsetX:=20, offsetY:=20, overlapW:=0)
{
  local
  ocr_Text:=ocr_X:=ocr_Y:=min_X:=dx:=""
  For k,v in ok
    x:=v.1
    , min_X:=(A_Index=1 || x<min_X ? x : min_X)
    , max_X:=(A_Index=1 || x>max_X ? x : max_X)
  While (min_X!="" && min_X<=max_X)
  {
    LeftX:=""
    For k,v in ok
    {
      x:=v.1, y:=v.2
      if (x<min_X) || (ocr_Y!="" && Abs(y-ocr_Y)>offsetY)
        Continue
      ; Get the leftmost X coordinates
      if (LeftX="" || x<LeftX)
        LeftX:=x, LeftY:=y, LeftW:=v.3, LeftH:=v.4, LeftOCR:=v.id
    }
    if (LeftX="")
      Break
    if (ocr_X="")
      ocr_X:=LeftX, min_Y:=LeftY, max_Y:=LeftY+LeftH
    ; If the interval exceeds the set value, add "*" to the result
    ocr_Text.=(ocr_Text!="" && LeftX>dx ? "*":"") . LeftOCR
    ; Update for next search
    min_X:=LeftX+LeftW-(overlapW>LeftW//2 ? LeftW//2:overlapW)
    , dx:=LeftX+LeftW+offsetX, ocr_Y:=LeftY
    , (LeftY<min_Y && min_Y:=LeftY)
    , (LeftY+LeftH>max_Y && max_Y:=LeftY+LeftH)
  }
  if (ocr_X="")
    ocr_X:=0, min_Y:=0, min_X:=0, max_Y:=0
  return {text:ocr_Text, x:ocr_X, y:min_Y
    , w: min_X-ocr_X, h: max_Y-min_Y}
}

; 按照从左到右、从上到下的顺序排序FindText()的结果
; 忽略轻微的Y坐标差距，返回排序后的数组对象

Sort(ok, dy:=10)
{
  local
  if !IsObject(ok)
    return ok
  s:="", n:=150000, ypos:=[]
  For k,v in ok
  {
    x:=v.x, y:=v.y, add:=1
    For k1,v1 in ypos
    if Abs(y-v1)<=dy
    {
      y:=v1, add:=0
      Break
    }
    if (add)
      ypos.Push(y)
    s.=(y*n+x) "." k "|"
  }
  s:=Trim(s,"|")
  Sort, s, N D|
  ok2:=[]
  Loop Parse, s, |
    ok2.Push( ok[StrSplit(A_LoopField,".")[2]] )
  return ok2
}

; 以指定点为中心，按从近到远排序FindText()的结果，返回排序后的数组

Sort2(ok, px, py)
{
  local
  if !IsObject(ok)
    return ok
  s:=""
  For k,v in ok
    s.=((v.x-px)**2+(v.y-py)**2) "." k "|"
  s:=Trim(s,"|")
  Sort, s, N D|
  ok2:=[]
  Loop Parse, s, |
    ok2.Push( ok[StrSplit(A_LoopField,".")[2]] )
  return ok2
}

; 按指定的查找方向，排序FindText()的结果，返回排序后的数组

Sort3(ok, dir:=1)
{
  local
  if !IsObject(ok)
    return ok
  s:="", n:=150000
  For k,v in ok
    x:=v.1, y:=v.2
    , s.=(dir=1 ? y*n+x
    : dir=2 ? y*n-x
    : dir=3 ? -y*n+x
    : dir=4 ? -y*n-x
    : dir=5 ? x*n+y
    : dir=6 ? x*n-y
    : dir=7 ? -x*n+y
    : dir=8 ? -x*n-y : y*n+x) "." k "|"
  s:=Trim(s,"|")
  Sort, s, N D|
  ok2:=[]
  Loop Parse, s, |
    ok2.Push( ok[StrSplit(A_LoopField,".")[2]] )
  return ok2
}

; 提示某个坐标的位置，或远程控制中当前鼠标的位置

MouseTip(x:="", y:="", w:=10, h:=10, d:=3)
{
  local
  if (x="")
  {
    VarSetCapacity(pt,16,0), DllCall("GetCursorPos","Ptr",&pt)
    x:=NumGet(pt,0,"uint"), y:=NumGet(pt,4,"uint")
  }
  Loop 4
  {
    this.RangeTip(x-w, y-h, 2*w+1, 2*h+1, (A_Index & 1 ? "Red":"Blue"), d)
    Sleep 500
  }
  this.RangeTip()
}

; 显示范围的边框，类似于 ToolTip

RangeTip(x:="", y:="", w:="", h:="", color:="Red", d:=3)
{
  local
  static id:=""
  ListLines % (lls:=A_ListLines)?0:0
  if (x="")
  {
    id:=0
    Loop 4
      Gui, Range_%A_Index%: Destroy
    ListLines % lls
    return
  }
  if (!id)
  {
    Loop 4
      Gui, Range_%A_Index%: +Hwndid +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
  }
  x:=Floor(x), y:=Floor(y), w:=Floor(w), h:=Floor(h), d:=Floor(d)
  Loop 4
  {
    i:=A_Index
    , x1:=(i=2 ? x+w : x-d)
    , y1:=(i=3 ? y+h : y-d)
    , w1:=(i=1 || i=3 ? w+2*d : d)
    , h1:=(i=2 || i=4 ? h+2*d : d)
    Gui, Range_%i%: Color, %color%
    Gui, Range_%i%: Show, NA x%x1% y%y1% w%w1% h%h1%
  }
  ListLines % lls
}

; 用鼠标左右键选取屏幕范围

GetRange(ww:=25, hh:=8, key:="RButton")
{
  local
  static Gui_Off:="", hk
  if (!Gui_Off)
    Gui_Off:=this.GetRange.Bind(this, "Off")
  if (ww="Off")
    return hk:=Trim(A_ThisHotkey, "*")
  ;---------------------
  Gui, FindText_HotkeyIf: Destroy
  Gui, FindText_HotkeyIf: -Caption +ToolWindow +E0x80000
  Gui, FindText_HotkeyIf: Show, NA x0 y0 w0 h0, FindText_HotkeyIf
  ;---------------------
  Hotkey, IfWinExist, FindText_HotkeyIf
  keys:=key "|Up|Down|Left|Right"
  For k,v in StrSplit(keys, "|")
  {
    KeyWait, %v%
    Hotkey, *%v%, %Gui_Off%, On UseErrorLevel
  }
  KeyWait, Ctrl
  Hotkey, IfWinExist
  ;---------------------
  Critical % (cri:=A_IsCritical)?"Off":"Off"
  CoordMode, Mouse
  tip:=this.Lang("s5")
  hk:="", oldx:=oldy:="", keydown:=0
  Loop
  {
    Sleep 50
    MouseGetPos, x, y
    if (hk=key) || GetKeyState(key,"P") || GetKeyState("Ctrl","P")
    {
      keydown++
      if (keydown=1)
        MouseGetPos, x1, y1, Bind_ID
      KeyWait, % key
      KeyWait, Ctrl
      hk:=""
      if (keydown>1)
        Break
    }
    else if (hk="Up") || GetKeyState("Up","P")
      (hh>1 && hh--), hk:=""
    else if (hk="Down") || GetKeyState("Down","P")
      hh++, hk:=""
    else if (hk="Left") || GetKeyState("Left","P")
      (ww>1 && ww--), hk:=""
    else if (hk="Right") || GetKeyState("Right","P")
      ww++, hk:=""
    this.RangeTip((keydown?x1:x)-ww, (keydown?y1:y)-hh
      , 2*ww+1, 2*hh+1, (A_MSec<500?"Red":"Blue"))
    if (oldx=x && oldy=y)
      Continue
    oldx:=x, oldy:=y
    ToolTip % "x: " (keydown?x1:x) " y: " (keydown?y1:y) "`n" tip
  }
  ToolTip
  this.RangeTip()
  Hotkey, IfWinExist, FindText_HotkeyIf
  For k,v in StrSplit(keys, "|")
    Hotkey, *%v%, %Gui_Off%, Off UseErrorLevel
  Hotkey, IfWinExist
  Gui, FindText_HotkeyIf: Destroy
  Critical %cri%
  return [x1-ww, y1-hh, x1+ww, y1+hh, Bind_ID]
}

; 截屏到剪贴板或者文件，或者仅获取范围

SnapShot(ScreenShot:=1, key:="LButton")
{
  local
  static Gui_Off:="", hk
  if (!Gui_Off)
    Gui_Off:=this.SnapShot.Bind(this, "Off")
  if (ScreenShot="Off")
    return hk:=Trim(A_ThisHotkey, "*")
  n:=150000, x:=y:=-n, w:=h:=2*n
  hBM:=this.BitmapFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
  ;---------------
  Gui, SnapShot_HotkeyIf: Destroy
  Gui, SnapShot_HotkeyIf: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
  Gui, SnapShot_HotkeyIf: Margin, 0, 0
  Gui, SnapShot_HotkeyIf: Add, Pic, w%zw% h%zh%, % "HBITMAP:*" hBM
  Gui, SnapShot_HotkeyIf: Show, NA x%zx% y%zy% w%zw% h%zh%, SnapShot_HotkeyIf
  ;---------------
  Gui, SnapShot_Box: Destroy
  Gui, SnapShot_Box: +Hwndbox_id +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
  Gui, SnapShot_Box: Margin, 0, 0
  Gui, SnapShot_Box: Font, s12
  For k,v in StrSplit(this.Lang("s15"), "|")
    Gui, SnapShot_Box: Add, Button, % (k=1 ? "":"x+0") " Hwndid", %v%
  GuiControlGet, p, SnapShot_Box: Pos, %id%
  box_w:=pX+pW+10, box_h:=pH+10
  Gui, SnapShot_Box: Show, Hide, SnapShot_Box
  ;---------------
  Hotkey, IfWinExist, SnapShot_HotkeyIf
  keys:=key "|RButton|Esc|Up|Down|Left|Right"
  For k,v in StrSplit(keys, "|")
  {
    KeyWait, %v%
    Hotkey, *%v%, %Gui_Off%, On UseErrorLevel
  }
  Hotkey, IfWinExist
  ;---------------
  Critical % (cri:=A_IsCritical)?"Off":"Off"
  CoordMode, Mouse
  Loop
  {  ;// For ReTry
  tip:=this.Lang("s16")
  hk:="", oldx:=oldy:="", ok:=0, d:=10, oldt:=0, oldf:=""
  x:=y:=w:=h:=0
  Loop
  {
    Sleep 50
    if (hk="RButton") || (hk="Esc") || GetKeyState("RButton","P") || GetKeyState("Esc","P")
      Break 2
    MouseGetPos, x1, y1
    if (oldx=x1 && oldy=y1)
      Continue
    oldx:=x1, oldy:=y1
    ToolTip % "x: " x1 " y: " y1 " w: 0 h: 0`n" tip
  }
  Until (hk=key) || GetKeyState(key,"P")
  Loop
  {
    Sleep 50
    MouseGetPos, x2, y2
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x1-x2)+1, h:=Abs(y1-y2)+1
    this.RangeTip(x, y, w, h, (A_MSec<500 ? "Red":"Blue"))
    if (oldx=x2 && oldy=y2)
      Continue
    oldx:=x2, oldy:=y2
    ToolTip % "x: " x " y: " y " w: " w " h: " h "`n" tip
  }
  Until !GetKeyState(key,"P")
  hk:=""
  Loop
  {
    Sleep 50
    MouseGetPos, x3, y3
    x1:=x, y1:=y, x2:=x+w-1, y2:=y+h-1
    , d1:=Abs(x3-x1)<=d, d2:=Abs(x3-x2)<=d
    , d3:=Abs(y3-y1)<=d, d4:=Abs(y3-y2)<=d
    , d5:=x3>x1+d && x3<x2-d, d6:=y3>y1+d && y3<y2-d
    , f:=(d1 && d3 ? 1 : d2 && d3 ? 2 : d1 && d4 ? 3
    : d2 && d4 ? 4 : d5 && d3 ? 5 : d5 && d4 ? 6
    : d6 && d1 ? 7 : d6 && d2 ? 8 : d5 && d6 ? 9 : 0)
    if (oldf!=f)
      oldf:=f, this.SetCursor(f=1 || f=4 ? "SIZENWSE"
      : f=2 || f=3 ? "SIZENESW" : f=5 || f=6 ? "SIZENS"
      : f=7 || f=8 ? "SIZEWE" : f=9 ? "SIZEALL" : "ARROW")
    ;--------------
    if (hk="Up") || GetKeyState("Up","P")
      hk:="", y--
    else if (hk="Down") || GetKeyState("Down","P")
      hk:="", y++
    else if (hk="Left") || GetKeyState("Left","P")
      hk:="", x--
    else if (hk="Right") || GetKeyState("Right","P")
      hk:="", x++
    else if (hk="RButton") || (hk="Esc") || GetKeyState("RButton","P") || GetKeyState("Esc","P")
      Break
    else if (hk=key) || GetKeyState(key,"P")
    {
      MouseGetPos,,, id, mc
      if (id=box_id) && (mc="Button1")
      {
        KeyWait, % key
        this.RangeTip(), this.SetCursor()
        Gui, SnapShot_Box: Hide
        Continue 2
      }
      if (id=box_id) && (ok:=mc="Button2" ? 2 : mc="Button4" ? 1:100)
        Break
      Gui, SnapShot_Box: Hide
      ToolTip
      Loop
      {
        Sleep 50
        MouseGetPos, x4, y4
        x1:=x, y1:=y, x2:=x+w-1, y2:=y+h-1, dx:=x4-x3, dy:=y4-y3
        , (f=1 ? (x1+=dx, y1+=dy) : f=2 ? (x2+=dx, y1+=dy)
        : f=3 ? (x1+=dx, y2+=dy) : f=4 ? (x2+=dx, y2+=dy)
        : f=5 ? y1+=dy : f=6 ? y2+=dy : f=7 ? x1+=dx : f=8 ? x2+=dx
        : f=9 ? (x1+=dx, y1+=dy, x2+=dx, y2+=dy) : 0)
        , (f ? this.RangeTip(Min(x1,x2), Min(y1,y2), Abs(x1-x2)+1, Abs(y1-y2)+1
        , (A_MSec<500 ? "Red":"Blue")) : 0)
      }
      Until !GetKeyState(key,"P")
      hk:="", x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x1-x2)+1, h:=Abs(y1-y2)+1
      if (f=9) && Abs(dx)<2 && Abs(dy)<2 && (ok:=(-oldt)+(oldt:=A_TickCount)<400)
        Break
    }
    this.RangeTip(x, y, w, h, (A_MSec<500 ? "Red":"Blue"))
    x1:=x+w-box_w, (x1<10 && x1:=10), (x1>zx+zw-box_w && x1:=zx+zw-box_w)
    , y1:=y+h+10, (y1>zy+zh-box_h && y1:=y-box_h), (y1<10 && y1:=10)
    Gui, SnapShot_Box: Show, NA x%x1% y%y1%
    ;-------------
    if (oldx=x3 && oldy=y3)
      Continue
    oldx:=x3, oldy:=y3
    ToolTip % "x: " x " y: " y " w: " w " h: " h "`n" tip
  }
  Break
  }  ;// For ReTry
  Hotkey, IfWinExist, SnapShot_HotkeyIf
  For k,v in StrSplit(keys, "|")
  {
    KeyWait, %v%
    Hotkey, *%v%, %Gui_Off%, Off UseErrorLevel
  }
  Hotkey, IfWinExist
  ToolTip
  this.RangeTip()
  this.SetCursor()
  Gui, SnapShot_Box: Destroy
  Gui, SnapShot_HotkeyIf: Destroy
  Critical %cri%
  ;---------------
  w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
  h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
  if (ok=1)
    this.SaveBitmapToFile(0, hBM, x-zx, y-zy, w, h)
  else if (ok=2)
  {
    FileSelectFile, f, S18, %A_Desktop%\1.bmp, SaveAs, Image (*.bmp)
    this.SaveBitmapToFile(f, hBM, x-zx, y-zy, w, h)
  }
  DllCall("DeleteObject", "Ptr",hBM)
  return [x, y, x+w-1, y+h-1]
}

SetCursor(cursor:="", args*)
{
  local
  static init, tab
  if (!VarSetCapacity(init) && init:="1")
  {
    tab:=[], OnExit(this.SetCursor.Bind(this,"")), this.SetCursor()
    s:="ARROW,32512, SIZENWSE,32642, SIZENESW,32643"
      . ", SIZEWE,32644, SIZENS,32645, SIZEALL,32646"
      . ", IBEAM,32513, WAIT,32514, CROSS,32515, UPARROW,32516"
      . ", NO,32648, HAND,32649, APPSTARTING,32650, HELP,32651"
    For i,v in StrSplit(s, ",", " ")
      (i&1) ? (k:=v) : (tab[k]:=DllCall("CopyImage", "Ptr"
      , DllCall("LoadCursor", "Ptr",0, "Ptr",v, "Ptr")
      , "int",2, "int",0, "int",0, "int",0, "Ptr"))
  }
  if (cursor!="") && tab.HasKey(cursor)
    DllCall("SetSystemCursor", "Ptr", DllCall("CopyImage", "Ptr",tab[cursor]
    , "int",2, "int",0, "int",0, "int",0, "Ptr"), "int",32512)
  else
    DllCall("SystemParametersInfo", "int",0x57, "int",0, "Ptr",0, "int",0)
}

BitmapFromScreen(ByRef x:=0, ByRef y:=0, ByRef w:=0, ByRef h:=0
  , ScreenShot:=1, ByRef zx:=0, ByRef zy:=0, ByRef zw:=0, ByRef zh:=0)
{
  local
  bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
  if (w<1 || h<1 || !bits.hBM)
    return
  hBM:=this.CreateDIBSection(w, h)
  this.CopyHBM(hBM, 0, 0, bits.hBM, x-zx, y-zy, w, h, 1)
  return hBM
}

; 快速保存截图为BMP文件，可用于调试
; 如果 file = 0 或 "" ，会保存到剪贴板

SavePic(file:=0, x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
{
  local
  x1:=Floor(x1), y1:=Floor(y1), x2:=Floor(x2), y2:=Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  hBM:=this.BitmapFromScreen(x, y, w, h, ScreenShot)
  this.SaveBitmapToFile(file, hBM)
  DllCall("DeleteObject", "Ptr",hBM)
}

; 保存图像到文件，如果 file = 0 或者 ""，保存到剪贴板
; 参数可以是位图句柄或者文件路径，例如： "c:\a.bmp"

SaveBitmapToFile(file, hBM_or_file, x:=0, y:=0, w:=0, h:=0)
{
  local
  if hBM_or_file is Number
    hBM_or_file:="HBITMAP:*" hBM_or_file
  if !hBM:=DllCall("CopyImage", "Ptr",LoadPicture(hBM_or_file)
  , "int",0, "int",0, "int",0, "uint",0x2008)
    return
  if (file) || (w!=0 && h!=0)
  {
    (w=0 || h=0) && this.GetBitmapWH(hBM, w, h)
    hBM2:=this.CreateDIBSection(w, -h, bpp:=(file ? 24 : 32))
    this.CopyHBM(hBM2, 0, 0, hBM, x, y, w, h)
    DllCall("DeleteObject", "Ptr",hBM), hBM:=hBM2
  }
  VarSetCapacity(dib, dib_size:=(A_PtrSize=8 ? 104:84))
  , DllCall("GetObject", "Ptr",hBM, "int",dib_size, "Ptr",&dib)
  , pbi:=&dib+(bitmap_size:=A_PtrSize=8 ? 32:24)
  , size:=NumGet(pbi+20, "uint"), pBits:=NumGet(pbi-A_PtrSize, "Ptr")
  if (!file)
  {
    hdib:=DllCall("GlobalAlloc", "uint",2, "Ptr",40+size, "Ptr")
    pdib:=DllCall("GlobalLock", "Ptr",hdib, "Ptr")
    DllCall("RtlMoveMemory", "Ptr",pdib, "Ptr",pbi, "Ptr",40)
    DllCall("RtlMoveMemory", "Ptr",pdib+40, "Ptr",pBits, "Ptr",size)
    DllCall("GlobalUnlock", "Ptr",hdib)
    DllCall("OpenClipboard", "Ptr",0)
    DllCall("EmptyClipboard")
    if !DllCall("SetClipboardData", "uint",8, "Ptr",hdib)
      DllCall("GlobalFree", "Ptr",hdib)
    DllCall("CloseClipboard")
  }
  else
  {
    if InStr(file,"\") && !FileExist(dir:=RegExReplace(file,"[^\\]*$"))
      Try FileCreateDir, % dir
    VarSetCapacity(bf, 14, 0), NumPut(0x4D42, bf, "short")
    NumPut(54+size, bf, 2, "uint"), NumPut(54, bf, 10, "uint")
    f:=FileOpen(file, "w"), f.RawWrite(bf, 14)
    , f.RawWrite(pbi+0, 40), f.RawWrite(pBits+0, size), f.Close()
  }
  DllCall("DeleteObject", "Ptr",hBM)
}

; 显示保存的图像

ShowPic(file:="", show:=1, ByRef x:="", ByRef y:="", ByRef w:="", ByRef h:="")
{
  local
  if (file="")
  {
    this.ShowScreenShot()
    return
  }
  if !(hBM:=LoadPicture(file))
    return
  this.GetBitmapWH(hBM, w, h)
  this.GetBitsFromScreen(,,,,0,x,y)
  bits:=this.GetBitsFromScreen(x,y,w,h,0)
  this.CopyHBM(bits.hBM, 0, 0, hBM, 0, 0, w, h)
  DllCall("DeleteObject", "Ptr",hBM)
  if (show)
    this.ShowScreenShot(x, y, x+w-1, y+h-1, 0)
}

; 显示内存中的屏幕截图用于调试

ShowScreenShot(x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
{
  local
  static hPic, oldx, oldy, oldw, oldh
  x1:=Floor(x1), y1:=Floor(y1), x2:=Floor(x2), y2:=Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
  {
    Gui, FindText_Screen: Destroy
    return
  }
  x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  if !hBM:=this.BitmapFromScreen(x,y,w,h,ScreenShot)
    return
  ;---------------
  Gui, FindText_Screen: +LastFoundExist
  IfWinNotExist
  {
    ; WS_EX_NOACTIVATE:=0x08000000
    Gui, FindText_Screen: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
    Gui, FindText_Screen: Margin, 0, 0
    Gui, FindText_Screen: Add, Pic, HwndhPic w%w% h%h%
    Gui, FindText_Screen: Show, NA x%x% y%y% w%w% h%h%, Show Pic
    oldx:=x, oldy:=y, oldw:=w, oldh:=h
  }
  else if (oldx!=x || oldy!=y || oldw!=w || oldh!=h)
  {
    if (oldw!=w || oldh!=h)
      GuiControl, FindText_Screen: Move, %hPic%, w%w% h%h%
    Gui, FindText_Screen: Show, NA x%x% y%y% w%w% h%h%
    oldx:=x, oldy:=y, oldw:=w, oldh:=h
  }
  this.BitmapToWindow(hPic, 0, 0, hBM, 0, 0, w, h)
  DllCall("DeleteObject", "Ptr",hBM)
}

BitmapToWindow(hwnd, x1, y1, hBM, x2, y2, w, h)
{
  local
  mDC:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM:=DllCall("SelectObject", "Ptr",mDC, "Ptr",hBM, "Ptr")
  hDC:=DllCall("GetDC", "Ptr",hwnd, "Ptr")
  DllCall("BitBlt", "Ptr",hDC, "int",x1, "int",y1, "int",w, "int",h
    , "Ptr",mDC, "int",x2, "int",y2, "uint",0xCC0020)
  DllCall("ReleaseDC", "Ptr",hwnd, "Ptr",hDC)
  DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
  DllCall("DeleteDC", "Ptr",mDC)
}

; 快速获取屏幕图像的搜索文本数据

GetTextFromScreen(x1, y1, x2, y2, Threshold:=""
  , ScreenShot:=1, ByRef rx:="", ByRef ry:="", cut:=1)
{
  local
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy)
  Scan0:=bits.Scan0, Stride:=bits.Stride
  if (w<1 || h<1 || !Scan0)
  {
    SetBatchLines, %bch%
    return
  }
  ListLines % (lls:=A_ListLines)?0:0
  gray:=[]
  Loop % h + 0*(j:=y-zy-1)*(k:=0)
  Loop % w + 0*(i:=x-zx-1)*(j++)
    c:=NumGet(Scan0+j*Stride+(++i)*4,"uint")
    , gray[++k]:=(((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
  if InStr(Threshold,"**")
  {
    Threshold:=StrReplace(Threshold,"*")
    if (Threshold="")
      Threshold:=50
    s:="", sw:=w, w-=2, h-=2, x++, y++
    Loop % h + 0*(y1:=0)
    Loop % w + 0*(y1++)
      i:=y1*sw+A_Index+1, j:=gray[i]+Threshold
      , s.=( gray[i-1]>j || gray[i+1]>j
      || gray[i-sw]>j || gray[i+sw]>j
      || gray[i-sw-1]>j || gray[i-sw+1]>j
      || gray[i+sw-1]>j || gray[i+sw+1]>j ) ? "1":"0"
    Threshold:="**" Threshold
  }
  else
  {
    Threshold:=StrReplace(Threshold,"*")
    if (Threshold="")
    {
      pp:=[]
      Loop 256
        pp[A_Index-1]:=0
      Loop % w*h
        pp[gray[A_Index]]++
      IP0:=IS0:=0
      Loop 256
        k:=A_Index-1, IP0+=k*pp[k], IS0+=pp[k]
      Threshold:=Floor(IP0/IS0)
      Loop 20
      {
        LastThreshold:=Threshold
        IP1:=IS1:=0
        Loop % LastThreshold+1
          k:=A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
        IP2:=IP0-IP1, IS2:=IS0-IS1
        if (IS1!=0 && IS2!=0)
          Threshold:=Floor((IP1/IS1+IP2/IS2)/2)
        if (Threshold=LastThreshold)
          Break
      }
    }
    s:=""
    Loop % w*h
      s.=gray[A_Index]<=Threshold ? "1":"0"
    Threshold:="*" Threshold
  }
  ListLines % lls
  ;--------------------
  w:=Format("{:d}",w), CutUp:=CutDown:=0
  if (cut=1)
  {
    re1:="(^0{" w "}|^1{" w "})"
    re2:="(0{" w "}$|1{" w "}$)"
    While (s~=re1)
      s:=RegExReplace(s,re1), CutUp++
    While (s~=re2)
      s:=RegExReplace(s,re2), CutDown++
  }
  rx:=x+w//2, ry:=y+CutUp+(h-CutUp-CutDown)//2
  s:="|<>" Threshold "$" w "." this.bit2base64(s)
  ;--------------------
  SetBatchLines, %bch%
  return s
}

; 等待几秒钟直到屏幕图像改变，需要先调用FindText().ScreenShot()

WaitChange(time:=-1, x1:=0, y1:=0, x2:=0, y2:=0)
{
  local
  hash:=this.GetPicHash(x1, y1, x2, y2, 0)
  timeout:=A_TickCount+Round(time*1000)
  Loop
  {
    if (hash!=this.GetPicHash(x1, y1, x2, y2, 1))
      return 1
    if (time>=0 && A_TickCount>=timeout)
      Break
    Sleep 10
  }
  return 0
}

; 等待屏幕图像稳定下来

WaitNotChange(time:=1, timeout:=30, x1:=0, y1:=0, x2:=0, y2:=0)
{
  local
  oldhash:="", timeout:=A_TickCount+Round(timeout*1000)
  Loop
  {
    hash:=this.GetPicHash(x1, y1, x2, y2, 1), t:=A_TickCount
    if (hash!=oldhash)
      oldhash:=hash, timeout2:=t+Round(time*1000)
    if (t>=timeout2)
      return 1
    if (t>=timeout)
      return 0
    Sleep 10
  }
}

GetPicHash(x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
{
  local
  static init:=DllCall("LoadLibrary", "Str","ntdll", "Ptr")
  x1:=Floor(x1), y1:=Floor(y1), x2:=Floor(x2), y2:=Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
  if (w<1 || h<1 || !bits.Scan0)
    return 0
  hash:=0, Stride:=bits.Stride, p:=bits.Scan0+(y-1)*Stride+x*4, w*=4
  ListLines % (lls:=A_ListLines)?0:0
  Loop % h
    hash:=(hash*31+DllCall("ntdll\RtlComputeCrc32", "uint",0
      , "Ptr",p+=Stride, "uint",w, "uint"))&0xFFFFFFFF
  ListLines % lls
  return hash
}

WindowToScreen(ByRef x, ByRef y, x1, y1, id:="")
{
  local
  if (!id)
    WinGet, id, ID, A
  VarSetCapacity(rect, 16, 0)
  , DllCall("GetWindowRect", "Ptr",id, "Ptr",&rect)
  , x:=x1+NumGet(rect,"int"), y:=y1+NumGet(rect,4,"int")
}

ScreenToWindow(ByRef x, ByRef y, x1, y1, id:="")
{
  local
  this.WindowToScreen(dx, dy, 0, 0, id), x:=x1-dx, y:=y1-dy
}

ClientToScreen(ByRef x, ByRef y, x1, y1, id:="")
{
  local
  if (!id)
    WinGet, id, ID, A
  VarSetCapacity(pt, 8, 0), NumPut(0, pt, "int64")
  , DllCall("ClientToScreen", "Ptr",id, "Ptr",&pt)
  , x:=x1+NumGet(pt,"int"), y:=y1+NumGet(pt,4,"int")
}

ScreenToClient(ByRef x, ByRef y, x1, y1, id:="")
{
  local
  this.ClientToScreen(dx, dy, 0, 0, id), x:=x1-dx, y:=y1-dy
}

; 不像 FindText 总是使用屏幕坐标，它使用与内置命令
; ImageSearch 一样的 CoordMode 设置的坐标模式
; 图片文件参数可以使用 "*n *TransRRGGBB-RRGGBB-White... d:\a.bmp"

ImageSearch(ByRef rx:="", ByRef ry:="", x1:=0, y1:=0, x2:=0, y2:=0
  , ImageFile:="", ScreenShot:=1, FindAll:=0)
{
  local
  dx:=dy:=0
  if (A_CoordModePixel="Window")
    this.WindowToScreen(dx, dy, 0, 0)
  else if (A_CoordModePixel="Client")
    this.ClientToScreen(dx, dy, 0, 0)
  text:=""
  Loop Parse, ImageFile, |
  if (v:=Trim(A_LoopField))!=""
  {
    text.=InStr(v,"$") ? "|" v : "|##"
    . (RegExMatch(v, "O)(^|\s)\*(\d+)\s", r)
    ? Format("{:06X}", r[2]<<16|r[2]<<8|r[2]) : "000000")
    . (RegExMatch(v, "Oi)(^|\s)\*Trans([\-\w]+)\s", r)
    ? "-" . Trim(r[2],"-") : "") . "$"
    . Trim(RegExReplace(v, "(?<=^|\s)\*\S+"))
  }
  x1:=Floor(x1), y1:=Floor(y1), x2:=Floor(x2), y2:=Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x1:=y1:=-n, x2:=y2:=n
  if (ok:=this.FindText(,, x1+dx, y1+dy, x2+dx, y2+dy
    , 0, 0, text, ScreenShot, FindAll))
  {
    For k,v in ok  ; you can use ok:=FindText().ok
      v.1-=dx, v.2-=dy, v.x-=dx, v.y-=dy
    rx:=ok[1].1, ry:=ok[1].2, ErrorLevel:=0
    return ok
  }
  else
  {
    rx:=ry:="", ErrorLevel:=1
    return 0
  }
}

; 不像 FindText 总是使用屏幕坐标，它使用与内置命令
; PixelSearch 一样的 CoordMode 设置的坐标模式
; 颜色参数可以是 "RRGGBB-DRDGDB|RRGGBB-DRDGDB", Variation 取值 0-255

PixelSearch(ByRef rx:="", ByRef ry:="", x1:=0, y1:=0, x2:=0, y2:=0
  , ColorID:="", Variation:=0, ScreenShot:=1, FindAll:=0)
{
  local
  n:=Floor(Variation), text:=Format("##{:06X}$0/0", n<<16|n<<8|n)
  Loop Parse, ColorID, |
  if (v:=Trim(A_LoopField))!=""
    text.="/" v
  return this.ImageSearch(rx, ry, x1, y1, x2, y2, text, ScreenShot, FindAll)
}

; 屏幕坐标指示的范围内的某些颜色的像素计数
; 颜色参数可以是 "RRGGBB-DRDGDB|RRGGBB-DRDGDB", Variation 取值 0-255

PixelCount(x1:=0, y1:=0, x2:=0, y2:=0, ColorID:="", Variation:=0, ScreenShot:=1)
{
  local
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  x1:=Floor(x1), y1:=Floor(y1), x2:=Floor(x2), y2:=Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
  sum:=0, VarSetCapacity(s1,4), VarSetCapacity(s0,4)
  , ini:={ bits:bits, ss:0, s1:&s1, s0:&s0
  , err1:0, err0:0, allpos_max:0, zoomW:1, zoomH:1 }
  , n:=Floor(Variation), text:=Format("##{:06X}$0/0", n<<16|n<<8|n)
  Loop Parse, ColorID, |
  if (v:=Trim(A_LoopField))!=""
    text.="/" v
  if (w>0 && h>0 && bits.Scan0) && IsObject(j:=this.PicInfo(text))
    sum:=this.PicFind(ini, j, 1, x, y, w, h, 0)
  SetBatchLines, %bch%
  return sum
}

Click(x:="", y:="", other1:="", other2:="", GoBack:=0)
{
  local
  CoordMode, Mouse, % (bak:=A_CoordModeMouse)?"Screen":"Screen"
  if GoBack
    MouseGetPos, oldx, oldy
  MouseMove, x, y, 0
  Click % x "," y "," other1 "," other2
  if GoBack
    MouseMove, oldx, oldy, 0
  CoordMode, Mouse, %bak%
}

; 使用 ControlClick 代替 Click, 使用屏幕坐标，如果用于后台请提供 hwnd

ControlClick(x, y, WhichButton:="", ClickCount:=1, Opt:="", hwnd:="")
{
  local
  if !hwnd
    hwnd:=DllCall("WindowFromPoint", "int64",y<<32|x&0xFFFFFFFF, "Ptr")
  VarSetCapacity(pt,8,0), ScreenX:=x, ScreenY:=y
  Loop
  {
    NumPut(0,pt,"int64"), DllCall("ClientToScreen", "Ptr",hwnd, "Ptr",&pt)
    , x:=ScreenX-NumGet(pt,"int"), y:=ScreenY-NumGet(pt,4,"int")
    , id:=DllCall("ChildWindowFromPoint", "Ptr",hwnd, "int64",y<<32|x, "Ptr")
    if (!id || id=hwnd)
      Break
    else hwnd:=id
  }
  DetectHiddenWindows, % (bak:=A_DetectHiddenWindows)?1:1
  PostMessage, 0x200, 0, y<<16|x,, ahk_id %hwnd%  ; WM_MOUSEMOVE
  SetControlDelay -1
  ControlClick, x%x% y%y%, ahk_id %hwnd%,, %WhichButton%, %ClickCount%, NA Pos %Opt%
  DetectHiddenWindows, % bak
}

; 动态运行AHK代码作为新线程

Class Thread
{
  __New(args*)
  {
    this.pid:=this.Exec(args*)
  }
  __Delete()
  {
    Process, Close, % this.pid
  }
  Exec(s, Ahk:="", args:="")    ; required AHK v1.1.34+
  {
    local
    Ahk:=Ahk ? Ahk : A_IsCompiled ? A_ScriptFullPath : A_AhkPath
    add:=A_IsCompiled ? " /script " : ""
    s:="`nDllCall(""SetWindowText"",""Ptr"",A_ScriptHwnd,""Str"",""<AHK>"")`n"
      . "`nSetBatchLines,-1`n" . s, s:=RegExReplace(s, "\R", "`r`n")
    Try
    {
      shell:=ComObjCreate("WScript.Shell")
      oExec:=shell.Exec("""" Ahk """" add " /force /CP0 * " args)
      oExec.StdIn.Write(s)
      oExec.StdIn.Close(), pid:=oExec.ProcessID
    }
    Catch
    {
      f:=A_Temp "\~ahk.tmp"
      s:="`r`nTry FileDelete " f "`r`n" s
      Try FileDelete %f%
      FileAppend %s%, %f%
      r:=this.Clear.Bind(this)
      SetTimer %r%, -3000
      Run "%Ahk%" %add% /force /CP0 "%f%" %args%,, UseErrorLevel, pid
    }
    return pid
  }
  Clear()
  {
    Try FileDelete % A_Temp "\~ahk.tmp"
    SetTimer,, Off
  }
}

; FindText().QPC() 用法类似于 A_TickCount

QPC()
{
  static f:="", c
  (!f) && DllCall("QueryPerformanceFrequency","Int*",f)+(f/=1000)
  return (!DllCall("QueryPerformanceCounter","Int64*",c))*0+(c/f)
}

; FindText().ToolTip() 用法类似于 ToolTip

ToolTip(s:="", x:="", y:="", num:=1, arg:="")
{
  local
  static init, ini, timer
  if (!VarSetCapacity(init) && init:="1")
    ini:=[], timer:=[]
  f:="ToolTip_" . Floor(num)
  if (s="")
  {
    ini[f]:=""
    Gui, %f%: Destroy
    return
  }
  ;-----------------
  r1:=A_CoordModeToolTip
  r2:=A_CoordModeMouse
  CoordMode Mouse, Screen
  MouseGetPos x1, y1
  CoordMode Mouse, %r1%
  MouseGetPos x2, y2
  CoordMode Mouse, %r2%
  (x!="" && x:="x" (Floor(x)+x1-x2))
  , (y!="" && y:="y" (Floor(y)+y1-y2))
  , (x="" && y="" && x:="x" (x1+16) " y" (y1+16))
  ;-----------------
  bgcolor:=arg.bgcolor!="" ? arg.bgcolor : "FAFBFC"
  color:=arg.color!="" ? arg.color : "Black"
  font:=arg.font ? arg.font : "Consolas"
  size:=arg.size ? arg.size : "10"
  bold:=arg.bold ? arg.bold : ""
  trans:=arg.trans!="" ? arg.trans & 255 : 255
  timeout:=arg.timeout!="" ? arg.timeout : ""
  ;-----------------
  r:=bgcolor "|" color "|" font "|" size "|" bold "|" trans "|" s
  if (!ini.HasKey(f) || ini[f]!=r)
  {
    ini[f]:=r
    Gui, %f%: Destroy  ; WS_EX_LAYERED:=0x80000, WS_EX_TRANSPARENT:=0x20
    Gui, %f%: +AlwaysOnTop -Caption +ToolWindow -DPIScale +Hwndid +E0x80020
    Gui, %f%: Margin, 2, 2
    Gui, %f%: Color, %bgcolor%
    Gui, %f%: Font, c%color% s%size% %bold%, %font%
    Gui, %f%: Add, Text,, %s%
    Gui, %f%: Show, Hide, %f%
    ;------------------
    DetectHiddenWindows, % (bak:=A_DetectHiddenWindows)?1:1
    WinSet, Transparent, %trans%, ahk_id %id%
    DetectHiddenWindows, % bak
  }
  Gui, %f%: +AlwaysOnTop
  Gui, %f%: Show, % "NA " x " " y
  if (timeout)
  {
    (!timer.HasKey(f) && timer[f]:=this.ToolTip.Bind(this,"","","",num))
    , r:=timer[f]
    SetTimer, %r%, % -Round(Abs(timeout*1000))-1
  }
}

; FindText().ObjView() 查看对象的值用于调试

ObjView(obj, keyname:="")
{
  local
  if IsObject(obj)  ; thanks lexikos's type(v)
  {
    s:=""
    For k,v in obj
      s.=this.ObjView(v, keyname "[" (StrLen(k)>1000
      || [k].GetCapacity(1) ? """" k """":k) "]")
  }
  else
    s:=keyname ": " (StrLen(obj)>1000
    || [obj].GetCapacity(1) ? """" obj """":obj) "`n"
  if (keyname!="")
    return s
  ;------------------
  Gui, Gui_DeBug: Destroy
  Gui, Gui_DeBug: +LastFound +AlwaysOnTop
  Gui, Gui_DeBug: Add, Button, y270 w350 gCancel Default, OK
  Gui, Gui_DeBug: Add, Edit, xp y10 w350 h250 -Wrap -WantReturn
  GuiControl, Gui_DeBug:, Edit1, %s%
  Gui, Gui_DeBug: Show,, Debug view object values
  DetectHiddenWindows, 0
  WinWaitClose, % "ahk_id " WinExist()
  Gui, Gui_DeBug: Destroy
}

EditScroll(hEdit, regex:="", line:=0, pos:=0)
{
  local
  ControlGetText, s,, ahk_id %hEdit%
  pos:=(regex!="") ? InStr(SubStr(s,1,s~=regex),"`n",0,0)
    : (line>1) ? InStr(s,"`n",0,1,line-1) : pos
  SendMessage, 0xB1, pos, pos,, ahk_id %hEdit%
  SendMessage, 0xB7,,,, ahk_id %hEdit%
}

; 从编译后的程序中获取脚本

GetScript()  ; thanks TAC109
{
  local
  if (!A_IsCompiled)
    return
  For i,ahk in ["#1", ">AUTOHOTKEY SCRIPT<"]
  if (rc:=DllCall("FindResource", "Ptr",0, "Str",ahk, "Ptr",10, "Ptr"))
  && (sz:=DllCall("SizeofResource", "Ptr",0, "Ptr",rc, "Uint"))
  && (pt:=DllCall("LoadResource", "Ptr",0, "Ptr",rc, "Ptr"))
  && (pt:=DllCall("LockResource", "Ptr",pt, "Ptr"))
  && (DllCall("VirtualProtect", "Ptr",pt, "Ptr",sz, "UInt",0x4, "UInt*",0))
  && (InStr(StrGet(pt, 20, "utf-8"), "<COMPILER"))
    return this.FormatScript(StrGet(pt, sz, "utf-8"))
}

FormatScript(s, space:="", tab:="    ")
{
  local
  ListLines % (lls:=A_ListLines)?0:0
  VarSetCapacity(ss, StrLen(s)*2), n:=0, w:=StrLen(tab)
  , space2:=StrReplace(Format("{:020d}",0), "0", tab)
  Loop Parse, s, `n, `r
  {
    v:=Trim(A_LoopField), n2:=n
    if RegExMatch(v, "O)^\s*[{}][\s{}]*|\{\s*$|\{\s+;", r)
      n+=w*(StrLen(RegExReplace(r[0], "[^{]"))
      -StrLen(RegExReplace(r[0], "[^}]"))), n2:=Min(n,n2)
    ss.=Space . SubStr(space2,1,n2) . v . "`r`n"
  }
  ListLines %lls%
  return SubStr(ss,1,-2)
}

; 获取最后添加的Gui控件的Hwnd，前提是 Gui +LastFound

LastCtrl()
{
  local
  WinGet, s, ControlListHwnd
  return SubStr(s, InStr(s,"`n",0,0)+1)
}

; 隐藏窗口，前提是 Gui +LastFound

Hide(id:="")
{
  if (id ? WinExist("ahk_id " id) : WinExist())
  {
    WinMinimize
    WinHide
    ToolTip
    DetectHiddenWindows, 0
    WinWaitClose, % "ahk_id " WinExist()
  }
}


;==== Optional GUI interface ====


Gui(cmd, arg1:="", args*)
{
  local
  static
  local bch, cri, lls
  ListLines, % InStr("MouseMove|ToolTipOff",cmd)?0:A_ListLines
  static init
  if (!VarSetCapacity(init) && init:="1")
  {
    SavePicDir:=A_Temp "\Ahk_ScreenShot\"
    Gui_ := this.Gui.Bind(this)
    Gui_G := this.Gui.Bind(this, "G")
    Gui_Run := this.Gui.Bind(this, "Run")
    Gui_Off := this.Gui.Bind(this, "Off")
    Gui_Show := this.Gui.Bind(this, "Show")
    Gui_KeyDown := this.Gui.Bind(this, "KeyDown")
    Gui_LButtonDown := this.Gui.Bind(this, "LButtonDown")
    Gui_RButtonDown := this.Gui.Bind(this, "RButtonDown")
    Gui_MouseMove := this.Gui.Bind(this, "MouseMove")
    Gui_ScreenShot := this.Gui.Bind(this, "ScreenShot")
    Gui_ShowPic := this.Gui.Bind(this, "ShowPic")
    Gui_Slider := this.Gui.Bind(this, "Slider")
    Gui_ToolTip := this.Gui.Bind(this, "ToolTip")
    Gui_ToolTipOff := this.Gui.Bind(this, "ToolTipOff")
    Gui_SaveScr := this.Gui.Bind(this, "SaveScr")
    bch:=A_BatchLines, cri:=A_IsCritical
    Critical
    #NoEnv
    Lang:=this.Lang(,1), Tip_Text:=this.Lang(,2)
    %Gui_%("MakeCaptureWindow")
    %Gui_%("MakeMainWindow")
    OnMessage(0x100, Gui_KeyDown)
    OnMessage(0x201, Gui_LButtonDown)
    OnMessage(0x204, Gui_RButtonDown)
    OnMessage(0x200, Gui_MouseMove)
    Menu, Tray, Add
    Menu, Tray, Add, % Lang["s1"], %Gui_Show%
    if (!A_IsCompiled && A_LineFile=A_ScriptFullPath)
    {
      Menu, Tray, Default, % Lang["s1"]
      Menu, Tray, Click, 1
      Menu, Tray, Icon, Shell32.dll, 23
    }
    Critical, %cri%
    SetBatchLines, %bch%
    Gui, New, +LastFound
    Gui, Destroy
    ;-------------------
    Pics:=PrevControl:=x:=y:=oldx:=oldy:="", oldt:=0
  }
  Switch cmd
  {
  Case "Off":
    return hk:=Trim(A_ThisHotkey, "*")
  Case "G":
    id:=this.LastCtrl()
    GuiControl, +g, %id%, %Gui_Run%
    return
  Case "Run":
    Critical
    %Gui_%(A_GuiControl)
    return
  Case "Show":
    Gui, FindText_Main: Default
    Gui, Show, % arg1 ? "Center" : ""
    GuiControl, Focus, %hscr%
    return
  Case "Cancel", "Cancel2":
    WinHide
    return
  Case "MakeCaptureWindow":
    WindowColor:="0xDDEEFF"
    Gui, FindText_Capture: New
    Gui, +LastFound +AlwaysOnTop -DPIScale
    Gui, Margin, 15, 15
    Gui, Color, %WindowColor%
    Gui, Font, s12, Verdana
    Gui, Add, Tab3, vMyTab1 -Wrap, % Lang["s18"]
    Gui, Tab, 1
    C_:=[], nW:=71, nH:=25, w:=h:=12, pW:=nW*(w+1)-1, pH:=(nH+1)*(h+1)-1
    Gui, -Theme
    ListLines % (lls:=A_ListLines)?0:0
    Loop % nW*(nH+1)
    {
      i:=A_Index, j:=i=1 ? "Section" : Mod(i,nW)=1 ? "xs y+1":"x+1"
      Gui, Add, Progress, %j% w%w% h%h% Hwndid -E0x20000 Smooth
      C_[i]:=id
    }
    ListLines % lls
    Gui, +Theme
    Gui, Add, Slider, xs w%pW% vMySlider1 +Center Page20 Line10 NoTicks AltSubmit
    %Gui_G%()
    Gui, Add, Slider, ys h%pH% vMySlider2 +Center Page20 Line10 NoTicks AltSubmit +Vertical
    %Gui_G%()
    Gui, Tab, 2
    pW-=120+15
    Gui, Add, Text, w%pW% h%pH% Hwndparent_id +Border Section
    Gui, Add, Slider, xs w%pW% vMySlider3 +Center Page20 Line10 NoTicks AltSubmit
    %Gui_G%()
    Gui, Add, Slider, ys h%pH% vMySlider4 +Center Page20 Line10 NoTicks AltSubmit +Vertical
    %Gui_G%()
    Gui, Add, ListBox, % "ys w120 h200 vSelectBox AltSubmit 0x100"
    %Gui_G%()
    Gui, Add, Button, y+0 wp vClearAll, % Lang["ClearAll"]
    %Gui_G%()
    Gui, Add, Button, y+0 wp vOpenDir, % Lang["OpenDir"]
    %Gui_G%()
    Gui, Add, Button, y+0 wp vLoadPic, % Lang["LoadPic"]
    %Gui_G%()
    Gui, Add, Button, y+0 wp vSavePic, % Lang["SavePic"]
    %Gui_G%()
    Gui, Tab
    MySlider1:=MySlider2:=MySlider3:=MySlider4:=dx:=dy:=0
    ;--------------
    Gui, Add, Button, xm Hidden Section, % Lang["Auto"]
    GuiControlGet, p, Pos, % this.LastCtrl()
    w:=Round(pW*0.75), i:=Round(w*3+15+pW*0.5-w*1.5)
    Gui, Add, Button, xm+%i% yp w%w% hp -Wrap vRepU, % Lang["RepU"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp hp -Wrap vCutU, % Lang["CutU"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp hp -Wrap vCutU3, % Lang["CutU3"]
    %Gui_G%()
    Gui, Add, Button, xm wp hp -Wrap vRepL, % Lang["RepL"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp hp -Wrap vCutL, % Lang["CutL"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp hp -Wrap vCutL3, % Lang["CutL3"]
    %Gui_G%()
    Gui, Add, Button, x+15 w%pW% hp -Wrap vAuto, % Lang["Auto"]
    %Gui_G%()
    Gui, Add, Button, x+15 w%w% hp -Wrap vRepR, % Lang["RepR"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp hp -Wrap vCutR, % Lang["CutR"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp hp -Wrap vCutR3, % Lang["CutR3"]
    %Gui_G%()
    Gui, Add, Button, xm+%i% wp hp -Wrap vRepD, % Lang["RepD"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp hp -Wrap vCutD, % Lang["CutD"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp hp -Wrap vCutD3, % Lang["CutD3"]
    %Gui_G%()
    ;--------------
    Gui, Add, Text, x+60 ys+3 Section, % Lang["SelGray"]
    Gui, Add, Edit, x+3 yp-3 w60 vSelGray ReadOnly
    Gui, Add, Text, x+15 ys, % Lang["SelColor"]
    Gui, Add, Edit, x+3 yp-3 w150 vSelColor ReadOnly
    Gui, Add, Text, x+15 ys, % Lang["SelR"]
    Gui, Add, Edit, x+3 yp-3 w60 vSelR ReadOnly
    Gui, Add, Text, x+5 ys, % Lang["SelG"]
    Gui, Add, Edit, x+3 yp-3 w60 vSelG ReadOnly
    Gui, Add, Text, x+5 ys, % Lang["SelB"]
    Gui, Add, Edit, x+3 yp-3 w60 vSelB ReadOnly
    ;--------------
    x:=w*6+pW+15*4
    Gui, Add, Tab3, x%x% y+15 -Wrap, % Lang["s2"]
    Gui, Tab, 1
    Gui, Add, Text, x+15 y+15, % Lang["Threshold"]
    Gui, Add, Edit, x+15 w100 vThreshold
    Gui, Add, Button, x+15 yp-3 vGray2Two, % Lang["Gray2Two"]
    %Gui_G%()
    Gui, Tab, 2
    Gui, Add, Text, x+15 y+15, % Lang["GrayDiff"]
    Gui, Add, Edit, x+15 w100 vGrayDiff, 50
    Gui, Add, Button, x+15 yp-3 vGrayDiff2Two, % Lang["GrayDiff2Two"]
    %Gui_G%()
    Gui, Tab, 3
    Gui, Add, Text, x+15 y+15, % Lang["Similar1"] " 0"
    Gui, Add, Slider, x+0 w120 vSimilar1 +Center Page1 NoTicks ToolTip, 100
    %Gui_G%()
    Gui, Add, Text, x+0, 100
    Gui, Add, Button, x+15 yp-3 vColor2Two, % Lang["Color2Two"]
    %Gui_G%()
    Gui, Tab, 4
    Gui, Add, Text, x+15 y+15, % Lang["Similar2"] " 0"
    Gui, Add, Slider, x+0 w120 vSimilar2 +Center Page1 NoTicks ToolTip, 100
    %Gui_G%()
    Gui, Add, Text, x+0, 100
    Gui, Add, Button, x+15 yp-3 vColorPos2Two, % Lang["ColorPos2Two"]
    %Gui_G%()
    Gui, Tab, 5
    Gui, Add, Text, x+10 y+15, % Lang["DiffR"]
    Gui, Add, Edit, x+5 w80 vDiffR Limit3
    Gui, Add, UpDown, vdR Range0-255 Wrap
    Gui, Add, Text, x+5, % Lang["DiffG"]
    Gui, Add, Edit, x+5 w80 vDiffG Limit3
    Gui, Add, UpDown, vdG Range0-255 Wrap
    Gui, Add, Text, x+5, % Lang["DiffB"]
    Gui, Add, Edit, x+5 w80 vDiffB Limit3
    Gui, Add, UpDown, vdB Range0-255 Wrap
    Gui, Add, Button, x+15 yp-3 vColorDiff2Two, % Lang["ColorDiff2Two"]
    %Gui_G%()
    Gui, Tab, 6
    Gui, Add, Text, x+10 y+15, % Lang["DiffRGB"]
    Gui, Add, Edit, x+5 w80 vDiffRGB Limit3
    Gui, Add, UpDown, vdRGB Range0-255 Wrap
    Gui, Add, Checkbox, x+15 yp+5 vMultiColor, % Lang["MultiColor"]
    %Gui_G%()
    Gui, Add, Button, x+15 yp-5 vUndo, % Lang["Undo"]
    %Gui_G%()
    Gui, Tab
    ;--------------
    Gui, Add, Button, xm vReset, % Lang["Reset"]
    %Gui_G%()
    Gui, Add, Checkbox, x+15 yp+5 vModify, % Lang["Modify"]
    %Gui_G%()
    Gui, Add, Text, x+30, % Lang["Comment"]
    Gui, Add, Edit, x+5 yp-2 w150 vComment
    Gui, Add, Button, x+10 yp-3 vSplitAdd, % Lang["SplitAdd"]
    %Gui_G%()
    Gui, Add, Button, x+10 vAllAdd, % Lang["AllAdd"]
    %Gui_G%()
    Gui, Add, Button, x+30 wp vOK, % Lang["OK"]
    %Gui_G%()
    Gui, Add, Button, x+10 wp vCancel, % Lang["Cancel"]
    %Gui_G%()
    Gui, Add, Button, xm vBind0, % Lang["Bind0"]
    %Gui_G%()
    Gui, Add, Button, x+10 vBind1, % Lang["Bind1"]
    %Gui_G%()
    Gui, Add, Button, x+10 vBind2, % Lang["Bind2"]
    %Gui_G%()
    Gui, Add, Button, x+10 vBind3, % Lang["Bind3"]
    %Gui_G%()
    Gui, Add, Button, x+10 vBind4, % Lang["Bind4"]
    %Gui_G%()
    Gui, Add, Button, x+60 vSavePic2, % Lang["SavePic2"]
    %Gui_G%()
    Gui, Show, Hide, % Lang["s3"]
    ;--------------------
    Gui, FindText_SubPic: New
    Gui, +Parent%parent_id% +AlwaysOnTop -Caption +ToolWindow -DPIScale
    Gui, Margin, 0, 0
    Gui, Color, White
    Gui, Add, Pic, x0 y0 w500 h500 +Hwndsub_hpic
    Gui, Show, NA x0 y0, SubPic
    return
  Case "MakeMainWindow":
    Gui, FindText_Main: New
    Gui, +LastFound +AlwaysOnTop -DPIScale
    Gui, Margin, 15, 10
    Gui, Color, %WindowColor%
    Gui, Font, s12, Verdana
    Gui, Add, Text, xm, % Lang["NowHotkey"]
    Gui, Add, Edit, x+5 w160 vNowHotkey ReadOnly
    Gui, Add, Hotkey, x+5 w160 vSetHotkey1
    s:="F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|LWin|MButton"
      . "|ScrollLock|CapsLock|Ins|Esc|BS|Del|Tab|Home|End|PgUp|PgDn"
      . "|NumpadDot|NumpadSub|NumpadAdd|NumpadDiv|NumpadMult"
    Gui, Add, DDL, x+5 w160 vSetHotkey2, % s
    Gui, Add, Button, x+15 vApply, % Lang["Apply"]
    %Gui_G%()
    Gui, Add, GroupBox, xm y+0 w280 h55 vMyGroup cBlack
    Gui, Add, Text, xp+15 yp+20 Section, % Lang["Myww"] ": "
    Gui, Add, Text, x+0 w80, % nW//2
    Gui, Add, UpDown, vMyww Range1-100, % nW//2
    Gui, Add, Text, x+15 ys, % Lang["Myhh"] ": "
    Gui, Add, Text, x+0 w80, % nH//2
    Gui, Add, UpDown, vMyhh Range1-100, % nH//2
    GuiControlGet, p, Pos, % this.LastCtrl()
    GuiControl, Move, MyGroup, % "w" (pX+pW) " h" (pH+30)
    Gui, Add, Checkbox, x+100 ys vAddFunc, % Lang["AddFunc"] " FindText()"
    GuiControlGet, p, Pos, % this.LastCtrl()
    pW:=pX+pW-15, pW:=(pW<720?720:pW), w:=pW//5
    Gui, Add, Button, xm y+18 w%w% vCutL2, % Lang["CutL2"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutR2, % Lang["CutR2"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutU2, % Lang["CutU2"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCutD2, % Lang["CutD2"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vUpdate, % Lang["Update"]
    %Gui_G%()
    Gui, Font, s6 bold, Verdana
    Gui, Add, Edit, xm y+10 w%pW% h260 vMyPic -Wrap HScroll
    Gui, Font, s12 norm, Verdana
    w:=pW//3
    Gui, Add, Button, xm w%w% vCapture, % Lang["Capture"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vTest, % Lang["Test"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vCopy, % Lang["Copy"]
    %Gui_G%()
    Gui, Add, Button, xm y+0 wp vCaptureS, % Lang["CaptureS"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vGetRange, % Lang["GetRange"]
    %Gui_G%()
    Gui, Add, Button, x+0 wp vGetOffset, % Lang["GetOffset"]
    %Gui_G%()
    Gui, Add, Edit, xm y+10 w130 hp vClipText
    Gui, Add, Button, x+0 vPaste, % Lang["Paste"]
    %Gui_G%()
    Gui, Add, Button, x+0 vTestClip, % Lang["TestClip"]
    %Gui_G%()
    Gui, Add, Button, x+0 vGetClipOffset, % Lang["GetClipOffset"]
    %Gui_G%()
    r:=pW
    GuiControlGet, p, Pos, % this.LastCtrl()
    w:=((r+15)-(pX+pW))//2, pW:=r
    Gui, Add, Edit, x+0 w%w% hp vOffset
    Gui, Add, Button, x+0 wp vCopyOffset, % Lang["CopyOffset"]
    %Gui_G%()
    Gui, Font, cBlue
    Gui, Add, Edit, xm w%pW% h250 vscr Hwndhscr -Wrap HScroll
    Gui, Show, Hide, % Lang["s4"]
    %Gui_%("LoadScr")
    OnExit(Gui_SaveScr)
    return
  Case "LoadScr":
    f:=A_Temp "\~scr1.tmp"
    FileRead, s, %f%
    GuiControl, FindText_Main:, scr, %s%
    return
  Case "SaveScr":
    f:=A_Temp "\~scr1.tmp"
    GuiControlGet, s, FindText_Main:, scr
    FileDelete, %f%
    FileAppend, %s%, %f%
    return
  Case "Capture", "CaptureS":
    Gui, FindText_Main: +Hwndid
    if WinExist()!=id
      return this.GetRange()
    this.Hide()
    if !InStr(cmd, "CaptureS")
    {
      Gui, FindText_Main: Default
      GuiControlGet, w,, Myww
      GuiControlGet, h,, Myhh
      p:=this.GetRange(w, h)
      sx:=p[1], sy:=p[2], sw:=p[3]-p[1]+1, sh:=p[4]-p[2]+1
      , Bind_ID:=p[5], bind_mode:=""
      Gui, FindText_Capture: Default
      GuiControl, Choose, MyTab1, 1
    }
    else
    {
      sx:=0, sy:=0, sw:=1, sh:=1, Bind_ID:=WinExist("A"), bind_mode:=""
      Gui, FindText_Capture: Default
      GuiControl, Choose, MyTab1, 2
    }
    this.ScreenShot()
    n:=150000, x:=y:=-n, w:=h:=2*n
    hBM:=this.BitmapFromScreen(x,y,w,h,0)
    %Gui_%("CaptureUpdate")
    %Gui_%("PicUpdate")
    Names:=[], s:=""
    Loop Files, % SavePicDir "*.bmp"
      Names.Push(v:=A_LoopFileFullPath), s.="|" RegExReplace(v,"i)^.*\\|\.bmp$")
    GuiControl,, SelectBox, % "|" Trim(s,"|")
    ;----------------------
    Loop Parse, % "SelGray|SelColor|SelR|SelG|SelB|Threshold|Comment", |
      GuiControl,, % A_LoopField
    GuiControl,, Modify, % Modify:=0
    GuiControl,, MultiColor, % MultiColor:=0
    GuiControl,, GrayDiff, 50
    GuiControl, Focus, Gray2Two
    GuiControl, +Default, Gray2Two
    Gui, +LastFound
    Gui, Show, Center
    Event:=Result:=""
    DetectHiddenWindows, 0
    Critical, Off
    WinWaitClose, % "ahk_id " WinExist()
    Critical
    ToolTip
    Gui, FindText_Main: Default
    ;--------------------------------
    if (bind_mode!="")
    {
      WinGetTitle, tt, ahk_id %Bind_ID%
      WinGetClass, tc, ahk_id %Bind_ID%
      tt:=Trim(SubStr(tt,1,30) (tc ? " ahk_class " tc:""))
      tt:=StrReplace(RegExReplace(tt,"[;``]","``$0"),"""","""""")
      Result:="`nSetTitleMatchMode 2`nid:=WinExist(""" tt """)"
        . "`nFindText().BindWindow(id" (bind_mode=0 ? "":"," bind_mode)
        . ")  `; " Lang["s6"] " FindText().BindWindow(0)`n`n" Result
    }
    if (Event="OK")
    {
      if (!A_IsCompiled)
        FileRead, s, %A_LineFile%
      else
        s:=this.GetScript()
      re:="Oi)\n\s*FindText[^\n]+args\*[\s\S]*?Script_End[(){\s]+}"
      if RegExMatch(s, re, r)
        s:="`n;==========`n" r[0] "`n"
      GuiControl,, scr, % Result "`n" s
      GuiControl,, MyPic, % Trim(this.ASCII(Result),"`n")
    }
    else if (Event="SplitAdd") || (Event="AllAdd")
    {
      GuiControlGet, s,, scr
      r:=SubStr(s, 1, InStr(s,"=FindText("))
      i:=j:=0, re:="<[^>\n]*>[^$\n]+\$[^""\r\n]+"
      While j:=RegExMatch(r, re,, j+1)
        i:=InStr(r, "`n", 0, j)
      GuiControl,, scr, % SubStr(s,1,i) . Result . SubStr(s,i+1)
      GuiControl,, MyPic, % Trim(this.ASCII(Result),"`n")
    }
    if (Event) && RegExMatch(Result, "O)\$\d+\.[\w+/]{1,100}", r)
      this.EditScroll(hscr, "\Q" r[0] "\E")
    Event:=Result:=s:=""
    ;----------------------
    %Gui_Show%()
    return
  Case "CaptureUpdate":
    nX:=sx, nY:=sy, nW:=sw, nH:=sh
    bits:=this.GetBitsFromScreen(nX,nY,nW,nH,0,zx,zy)
    cors:=[], cut:=[], ascii:=[]
    bg:=color:="", dx:=dy:=CutLeft:=CutRight:=CutUp:=CutDown:=0
    ListLines % (lls:=A_ListLines)?0:0
    if (nW>0 && nH>0 && bits.Scan0)
    {
      j:=bits.Stride-nW*4, p:=bits.Scan0+(nY-zy)*bits.Stride+(nX-zx)*4-4-j
      Loop % nH + 0*(k:=0)
      Loop % nW + 0*(p+=j)
        cors[++k]:=NumGet(0|p+=4,"uint")
    }
    Loop % 25 + 0*(ty:=dy-1)*(k:=0)
    Loop % 71 + 0*(tx:=dx-1)*(ty++)
    {
      c:=(++tx)<nW && ty<nH ? cors[ty*nW+tx+1] : WindowColor
      SendMessage,0x2001,0,(c&0xFF)<<16|c&0xFF00|(c>>16)&0xFF,,% "ahk_id " C_[++k]
    }
    Loop % 71 + 0*(k:=71*25)
      SendMessage,0x2001,0,0xAAFFFF,,% "ahk_id " C_[++k]
    ListLines % lls
    Gui, FindText_Capture: Default
    GuiControl, % "Enable" (nW>71), MySlider1
    GuiControl, % "Enable" (nH>25), MySlider2
    GuiControl,, MySlider1, % MySlider1:=0
    GuiControl,, MySlider2, % MySlider2:=0
    return
  Case "PicUpdate":
    GuiControl, FindText_SubPic:, %sub_hpic%, % "*w0 *h0 HBITMAP:" hBM
    Gui, FindText_Capture: Default
    GuiControl,, MySlider3, % MySlider3:=0
    GuiControl,, MySlider4, % MySlider4:=0
    %Gui_%("MySlider3")
    return
  Case "Reset":
    %Gui_%("CaptureUpdate")
    return
  Case "LoadPic":
    Gui, FindText_Capture: +OwnDialogs
    f:=arg1
    if (f="")
    {
      if !FileExist(SavePicDir)
        FileCreateDir, % SavePicDir
      f:=SavePicDir "*.bmp"
      Loop Files, % f
        f:=A_LoopFileFullPath
      FileSelectFile, f,, %f%, Select Picture
    }
    if !FileExist(f)
    {
      MsgBox, 4096, Tip, % Lang["s17"] " !", 1
      return
    }
    this.ShowPic(f, 0, sx, sy, sw, sh)
    hBM:=this.BitmapFromScreen(sx, sy, sw, sh, 0)
    sw:=Min(sw,200), sh:=Min(sh,200)
    %Gui_%("CaptureUpdate")
    %Gui_%("PicUpdate")
    return
  Case "SavePic":
    Gui, FindText_Capture: Default
    GuiControlGet, SelectBox
    f:=Names[SelectBox]
    Gui, Hide
    this.ShowPic(f)
    pos:=this.SnapShot(0)
    %Gui_%("ScreenShot", pos[1] "|" pos[2] "|" pos[3] "|" pos[4] "|0")
    this.ShowPic()
    return
  Case "SelectBox":
    Gui, FindText_Capture: Default
    GuiControlGet, SelectBox
    f:=Names[SelectBox]
    if (f!="")
      %Gui_%("LoadPic", f)
    return
  Case "ClearAll":
    Gui, FindText_Capture: Hide
    FileDelete, % SavePicDir "*.bmp"
    return
  Case "OpenDir":
    Gui, FindText_Capture: Minimize
    if !FileExist(SavePicDir)
      FileCreateDir, % SavePicDir
    Run, % SavePicDir
    return
  Case "GetRange":
    Gui, FindText_Main: +LastFound
    this.Hide()
    p:=this.SnapShot(), v:=p[1] ", " p[2] ", " p[3] ", " p[4]
    Gui, FindText_Main: Default
    GuiControlGet, s,, scr
    re:="i)(=FindText\([^\n]*?)([^(,\n]*,){4}([^,\n]*,[^,\n]*,[^,\n]*Text)"
    if SubStr(s,1,s~="i)\n\s*FindText[^\n]+args\*")~=re
    {
      s:=RegExReplace(s, re, "$1 " v ",$3",, 1)
      GuiControl,, scr, %s%
    }
    GuiControl,, Offset, %v%
    %Gui_Show%()
    return
  Case "Test", "TestClip":
    Gui, FindText_Main: Default
    Gui, +LastFound
    this.Hide()
    ;----------------------
    if (cmd="Test")
      GuiControlGet, s,, scr
    else
      GuiControlGet, s,, ClipText
    if (cmd="Test") && InStr(s, "MCode(")
    {
      s:="`n#NoEnv`nMenu, Tray, Click, 1`n" s "`nExitApp`n"
      Thread1:=new this.Thread(s)
      DetectHiddenWindows, 1
      WinWait, % "ahk_class AutoHotkey ahk_pid " Thread1.pid,, 3
      if (!ErrorLevel)
        WinWaitClose,,, 30
      ; Thread1:=""  ; kill the Thread
    }
    else
    {
      t:=A_TickCount, v:=X:=Y:=""
      if RegExMatch(s, "O)<[^>\n]*>[^$\n]+\$[^""\r\n]+", r)
        v:=this.FindText(X, Y, 0,0,0,0, 0,0, r[0])
      r:=StrSplit(Lang["s8"] "||||", "|")
      MsgBox, 4096, Tip, % r[1] ":`t" (IsObject(v)?v.Length():v) "`n`n"
        . r[2] ":`t" (A_TickCount-t) " " r[3] "`n`n"
        . r[4] ":`t" X ", " Y "`n`n"
        . r[5] ":`t<" (IsObject(v)?v[1].id:"") ">", 3
      Try For i,j in v
        if (i<=2)
          this.MouseTip(j.x, j.y)
      v:="", Clipboard:=X "," Y
    }
    ;----------------------
    %Gui_Show%()
    return
  Case "GetOffset", "GetClipOffset":
    Gui, FindText_Main: Hide
    p:=this.GetRange()
    Gui, FindText_Main: Default
    if (cmd="GetOffset")
      GuiControlGet, s,, scr
    else
      GuiControlGet, s,, ClipText
    if RegExMatch(s, "O)<[^>\n]*>[^$\n]+\$[^""\r\n]+", r)
    && this.FindText(X, Y, 0,0,0,0, 0,0, r[0])
    {
      r:=StrReplace("X+" ((p[1]+p[3])//2-X)
        . ", Y+" ((p[2]+p[4])//2-Y), "+-", "-")
      if (cmd="GetOffset")
      {
        re:="i)(\(\)\.\w*Click\w*\()[^,\n]*,[^,)\n]*"
        if SubStr(s,1,s~="i)\n\s*FindText[^\n]+args\*")~=re
          s:=RegExReplace(s, re, "$1" r,, 1)
        GuiControl,, scr, %s%
      }
      GuiControl,, Offset, %r%
    }
    s:="", %Gui_Show%()
    return
  Case "Paste":
    s:=Clipboard
    if RegExMatch(s, "O)\|?<[^>\n]*>[^$\n]+\$[^""\r\n]+", r)
    {
      Gui, FindText_Main: Default
      GuiControl,, ClipText, % r[0]
      GuiControl,, MyPic, % Trim(this.ASCII(r[0]),"`n")
    }
    return
  Case "CopyOffset":
    GuiControlGet, s, FindText_Main:, Offset
    Clipboard:=s
    return
  Case "Copy":
    Gui, FindText_Main: Default
    ControlGet, s, Selected,,, ahk_id %hscr%
    if (s="")
    {
      GuiControlGet, s,, scr
      GuiControlGet, r,, AddFunc
      if (r != 1)
        s:=RegExReplace(s, "i)\n\s*FindText[^\n]+args\*[\s\S]*")
        , s:=RegExReplace(s, "i)\n; ok:=FindText[\s\S]*")
        , s:=SubStr(s, (s~="i)\n[ \t]*Text"))
    }
    Clipboard:=RegExReplace(s,"\R","`r`n")
    GuiControl, Focus, scr
    return
  Case "Apply":
    Gui, FindText_Main: Default
    GuiControlGet, NowHotkey
    GuiControlGet, SetHotkey1
    GuiControlGet, SetHotkey2
    if (NowHotkey!="")
      Hotkey, *%NowHotkey%,, Off UseErrorLevel
    k:=SetHotkey1!="" ? SetHotkey1 : SetHotkey2
    if (k!="")
      Hotkey, *%k%, %Gui_ScreenShot%, On UseErrorLevel
    GuiControl,, NowHotkey, %k%
    GuiControl,, SetHotkey1
    GuiControl, Choose, SetHotkey2, 0
    return
  Case "ScreenShot":
    Critical
    if !FileExist(SavePicDir)
      FileCreateDir, % SavePicDir
    Loop
      f:=SavePicDir . Format("{:03d}.bmp",A_Index)
    Until !FileExist(f)
    this.SavePic(f, StrSplit(arg1,"|")*)
    CoordMode, ToolTip
    this.ToolTip(Lang["s9"],, 0,, { bgcolor:"Yellow", color:"Red"
      , size:48, bold:"bold", trans:200, timeout:0.2 })
    return
  Case "Bind0", "Bind1", "Bind2", "Bind3", "Bind4":
    this.BindWindow(Bind_ID, bind_mode:=SubStr(cmd,5))
    n:=150000, x:=y:=-n, w:=h:=2*n
    hBM:=this.BitmapFromScreen(x,y,w,h,1)
    %Gui_%("PicUpdate")
    GuiControl, FindText_Capture: Choose, MyTab1, 2
    this.BindWindow(0)
    return
  Case "MySlider1", "MySlider2":
    SetTimer, %Gui_Slider%, -10
    return
  Case "Slider":
    Critical
    dx:=nW>71 ? Round((nW-71)*MySlider1/100) : 0
    dy:=nH>25 ? Round((nH-25)*MySlider2/100) : 0
    if (oldx=dx && oldy=dy)
      return
    ListLines % (lls:=A_ListLines)?0:0
    Loop % 25 + 0*(ty:=dy-1)*(k:=0)
    Loop % 71 + 0*(tx:=dx-1)*(ty++)
    {
      c:=((++tx)>=nW || ty>=nH || cut[i:=ty*nW+tx+1]
      ? WindowColor : bg="" ? cors[i] : ascii[i])
      SendMessage,0x2001,0,(c&0xFF)<<16|c&0xFF00|(c>>16)&0xFF,,% "ahk_id " C_[++k]
    }
    Loop % 71*(oldx!=dx) + 0*(i:=nW*nH+dx)*(k:=71*25)
      SendMessage,0x2001,0,(cut[++i]?0x0000FF:0xAAFFFF),,% "ahk_id " C_[++k]
    ListLines % lls
    oldx:=dx, oldy:=dy
    return
  Case "MySlider3", "MySlider4":
    GuiControlGet, p, FindText_Capture: Pos, % parent_id
    w:=pW, h:=pH
    GuiControlGet, p, FindText_SubPic: Pos, % sub_hpic
    x:=pW>w ? -Round((pW-w)*MySlider3/100) : 0
    y:=pH>h ? -Round((pH-h)*MySlider4/100) : 0
    Gui, FindText_SubPic: Show, NA x%x% y%y% w%pW% h%pH%
    return
  Case "RepColor":
    cut[k]:=0, c:=(bg="" ? cors[k] : ascii[k])
    if (tx:=Mod(k-1,nW)-dx)>=0 && tx<71 && (ty:=(k-1)//nW-dy)>=0 && ty<25
      SendMessage,0x2001,0,(c&0xFF)<<16|c&0xFF00|(c>>16)&0xFF,,% "ahk_id " C_[ty*71+tx+1]
    return
  Case "CutColor":
    cut[k]:=1, c:=WindowColor
    if (tx:=Mod(k-1,nW)-dx)>=0 && tx<71 && (ty:=(k-1)//nW-dy)>=0 && ty<25
      SendMessage,0x2001,0,(c&0xFF)<<16|c&0xFF00|(c>>16)&0xFF,,% "ahk_id " C_[ty*71+tx+1]
    return
  Case "RepL":
    if (CutLeft<=0) || (bg!="" && InStr(color,"**") && CutLeft=1)
      return
    k:=CutLeft-nW, CutLeft--
    Loop %nH%
      k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && %Gui_%("RepColor"))
    return
  Case "CutL":
    if (CutLeft+CutRight>=nW)
      return
    CutLeft++, k:=CutLeft-nW
    Loop %nH%
      k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && %Gui_%("CutColor"))
    return
  Case "CutL3":
    Loop 3
      %Gui_%("CutL")
    return
  Case "RepR":
    if (CutRight<=0) || (bg!="" && InStr(color,"**") && CutRight=1)
      return
    k:=1-CutRight, CutRight--
    Loop %nH%
      k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && %Gui_%("RepColor"))
    return
  Case "CutR":
    if (CutLeft+CutRight>=nW)
      return
    CutRight++, k:=1-CutRight
    Loop %nH%
      k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && %Gui_%("CutColor"))
    return
  Case "CutR3":
    Loop 3
      %Gui_%("CutR")
    return
  Case "RepU":
    if (CutUp<=0) || (bg!="" && InStr(color,"**") && CutUp=1)
      return
    k:=(CutUp-1)*nW, CutUp--
    Loop %nW%
      k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && %Gui_%("RepColor"))
    return
  Case "CutU":
    if (CutUp+CutDown>=nH)
      return
    CutUp++, k:=(CutUp-1)*nW
    Loop %nW%
      k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && %Gui_%("CutColor"))
    return
  Case "CutU3":
    Loop 3
      %Gui_%("CutU")
    return
  Case "RepD":
    if (CutDown<=0) || (bg!="" && InStr(color,"**") && CutDown=1)
      return
    k:=(nH-CutDown)*nW, CutDown--
    Loop %nW%
      k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && %Gui_%("RepColor"))
    return
  Case "CutD":
    if (CutUp+CutDown>=nH)
      return
    CutDown++, k:=(nH-CutDown)*nW
    Loop %nW%
      k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && %Gui_%("CutColor"))
    return
  Case "CutD3":
    Loop 3
      %Gui_%("CutD")
    return
  Case "Gray2Two":
    ListLines % (lls:=A_ListLines)?0:0
    gray:=[], k:=0
    Loop % nW*nH
      gray[++k]:=((((c:=cors[k])>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
    Gui, FindText_Capture: Default
    GuiControl, Focus, Threshold
    GuiControlGet, Threshold
    if (Threshold="")
    {
      pp:=[]
      Loop 256
        pp[A_Index-1]:=0
      Loop % nW*nH
        if (!cut[A_Index])
          pp[gray[A_Index]]++
      IP0:=IS0:=0
      Loop 256
        k:=A_Index-1, IP0+=k*pp[k], IS0+=pp[k]
      Threshold:=Floor(IP0/IS0)
      Loop 20
      {
        LastThreshold:=Threshold
        IP1:=IS1:=0
        Loop % LastThreshold+1
          k:=A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
        IP2:=IP0-IP1, IS2:=IS0-IS1
        if (IS1!=0 && IS2!=0)
          Threshold:=Floor((IP1/IS1+IP2/IS2)/2)
        if (Threshold=LastThreshold)
          Break
      }
      GuiControl,, Threshold, %Threshold%
    }
    Threshold:=Round(Threshold)
    color:="*" Threshold, k:=i:=0
    Loop % nW*nH
      ascii[++k]:=v:=(gray[k]<=Threshold
      ? 0x000000:0xFFFFFF), (!cut[k] && i:=(v?i-1:i+1))
    bg:=(i>0 ? "1":"0")
    ;--------------
    Loop % 25 + 0*(ty:=dy-1)*(k:=0)
    Loop % 71 + 0*(tx:=dx-1)*(ty++)
    if (k++)*0 + (++tx)<nW && ty<nH && !cut[i:=ty*nW+tx+1]
      SendMessage,0x2001,0,ascii[i],,% "ahk_id " C_[k]
    ListLines % lls
    return
  Case "GrayDiff2Two":
    Gui, FindText_Capture: Default
    GuiControlGet, GrayDiff
    if (GrayDiff="")
    {
      Gui, +OwnDialogs
      MsgBox, 4096, Tip, % Lang["s11"] " !", 1
      return
    }
    ListLines % (lls:=A_ListLines)?0:0
    gray:=[], k:=0
    Loop % nW*nH
      gray[++k]:=((((c:=cors[k])>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
    if (CutLeft=0)
      %Gui_%("CutL")
    if (CutRight=0)
      %Gui_%("CutR")
    if (CutUp=0)
      %Gui_%("CutU")
    if (CutDown=0)
      %Gui_%("CutD")
    GrayDiff:=Round(GrayDiff)
    color:="**" GrayDiff, k:=i:=0
    Loop % nW*nH
      j:=gray[++k]+GrayDiff
      , ascii[k]:=v:=(gray[k-1]>j || gray[k+1]>j
      || gray[k-nW]>j || gray[k+nW]>j
      || gray[k-nW-1]>j || gray[k-nW+1]>j
      || gray[k+nW-1]>j || gray[k+nW+1]>j
      ? 0x000000:0xFFFFFF), (!cut[k] && i:=(v?i-1:i+1))
    bg:=(i>0 ? "1":"0")
    ;--------------
    Loop % 25 + 0*(ty:=dy-1)*(k:=0)
    Loop % 71 + 0*(tx:=dx-1)*(ty++)
    if (k++)*0 + (++tx)<nW && ty<nH && !cut[i:=ty*nW+tx+1]
      SendMessage,0x2001,0,ascii[i],,% "ahk_id " C_[k]
    ListLines % lls
    return
  Case "Color2Two", "ColorPos2Two":
    Gui, FindText_Capture: Default
    GuiControlGet, c,, SelColor
    if (c="")
    {
      Gui, +OwnDialogs
      MsgBox, 4096, Tip, % Lang["s12"] " !", 1
      return
    }
    UsePos:=(cmd="ColorPos2Two")
    GuiControlGet, n,, % UsePos ? "Similar2" : "Similar1"
    n:=Round(n/100,2), color:=StrReplace(c,"0x") "@" n
    , n:=Floor(4606*255*255*(1-n)*(1-n)), k:=i:=0
    , rr:=(c>>16)&0xFF, gg:=(c>>8)&0xFF, bb:=c&0xFF
    ListLines % (lls:=A_ListLines)?0:0
    Loop % nW*nH
      c:=cors[++k], r:=((c>>16)&0xFF)-rr
      , g:=((c>>8)&0xFF)-gg, b:=(c&0xFF)-bb, j:=r+rr+rr
      , ascii[k]:=v:=((1024+j)*r*r+2048*g*g+(1534-j)*b*b<=n
      ? 0x000000:0xFFFFFF), (!cut[k] && i:=(v?i-1:i+1))
    bg:=(i>0 ? "1":"0")
    ;--------------
    Loop % 25 + 0*(ty:=dy-1)*(k:=0)
    Loop % 71 + 0*(tx:=dx-1)*(ty++)
    if (k++)*0 + (++tx)<nW && ty<nH && !cut[i:=ty*nW+tx+1]
      SendMessage,0x2001,0,ascii[i],,% "ahk_id " C_[k]
    ListLines % lls
    return
  Case "ColorDiff2Two":
    Gui, FindText_Capture: Default
    GuiControlGet, c,, SelColor
    if (c="")
    {
      Gui, +OwnDialogs
      MsgBox, 4096, Tip, % Lang["s12"] " !", 1
      return
    }
    GuiControlGet, dR
    GuiControlGet, dG
    GuiControlGet, dB
    rr:=(c>>16)&0xFF, gg:=(c>>8)&0xFF, bb:=c&0xFF
    , n:=Format("{:06X}",(dR<<16)|(dG<<8)|dB)
    , color:=StrReplace(c "-" n,"0x"), k:=i:=0
    ListLines % (lls:=A_ListLines)?0:0
    Loop % nW*nH
      c:=cors[++k], r:=(c>>16)&0xFF, g:=(c>>8)&0xFF, b:=c&0xFF
      , ascii[k]:=v:=(Abs(r-rr)<=dR && Abs(g-gg)<=dG && Abs(b-bb)<=dB
      ? 0x000000:0xFFFFFF), (!cut[k] && i:=(v?i-1:i+1))
    bg:=(i>0 ? "1":"0")
    ;--------------
    Loop % 25 + 0*(ty:=dy-1)*(k:=0)
    Loop % 71 + 0*(tx:=dx-1)*(ty++)
    if (k++)*0 + (++tx)<nW && ty<nH && !cut[i:=ty*nW+tx+1]
      SendMessage,0x2001,0,ascii[i],,% "ahk_id " C_[k]
    ListLines % lls
    return
  Case "Modify":
    Gui, FindText_Capture: Default
    GuiControlGet, Modify
    return
  Case "MultiColor":
    Gui, FindText_Capture: Default
    GuiControlGet, MultiColor
    Result:=""
    ToolTip
    return
  Case "Undo":
    Result:=RegExReplace(Result, ",[^/]+/[^/]+/[^/]+$")
    ToolTip % Trim(Result,"/,")
    return
  Case "Similar1":
    Gui, FindText_Capture: Default
    GuiControl,, Similar2, %Similar1%
    return
  Case "Similar2":
    Gui, FindText_Capture: Default
    GuiControl,, Similar1, %Similar2%
    return
  Case "GetTxt":
    txt:=""
    if (bg="")
      return
    k:=0
    ListLines % (lls:=A_ListLines)?0:0
    Loop %nH%
    {
      v:=""
      Loop %nW%
        v.=cut[++k] ? "" : ascii[k] ? "0":"1"
      txt.=v="" ? "" : v "`n"
    }
    ListLines % lls
    return
  Case "Auto":
    %Gui_%("GetTxt")
    if (txt="")
    {
      Gui, FindText_Capture: +OwnDialogs
      MsgBox, 4096, Tip, % Lang["s13"] " !", 1
      return
    }
    While InStr(txt,bg)
    {
      if (txt~="^" bg "+\n")
        txt:=RegExReplace(txt, "^" bg "+\n"), %Gui_%("CutU")
      else if !(txt~="m`n)[^\n" bg "]$")
        txt:=RegExReplace(txt, "m`n)" bg "$"), %Gui_%("CutR")
      else if (txt~="\n" bg "+\n$")
        txt:=RegExReplace(txt, "\n\K" bg "+\n$"), %Gui_%("CutD")
      else if !(txt~="m`n)^[^\n" bg "]")
        txt:=RegExReplace(txt, "m`n)^" bg), %Gui_%("CutL")
      else Break
    }
    txt:=""
    return
  Case "OK", "SplitAdd", "AllAdd":
    Gui, FindText_Capture: Default
    Gui, +OwnDialogs
    %Gui_%("GetTxt")
    if (txt="") && (!MultiColor)
    {
      MsgBox, 4096, Tip, % Lang["s13"] " !", 1
      return
    }
    if InStr(color,"@") && (UsePos) && (!MultiColor)
    {
      r:=StrSplit(color,"@")
      k:=i:=j:=0
      ListLines % (lls:=A_ListLines)?0:0
      Loop % nW*nH
      {
        if (cut[++k])
          Continue
        i++
        if (k=cors.SelPos)
        {
          j:=i
          Break
        }
      }
      ListLines % lls
      if (j=0)
      {
        MsgBox, 4096, Tip, % Lang["s12"] " !", 1
        return
      }
      color:="#" j "@" r[2]
    }
    GuiControlGet, Comment
    if (cmd="SplitAdd") && (!MultiColor)
    {
      if InStr(color,"#")
      {
        MsgBox, 4096, Tip, % Lang["s14"], 3
        return
      }
      bg:=StrLen(StrReplace(txt,"0"))
        > StrLen(StrReplace(txt,"1")) ? "1":"0"
      s:="", i:=0, k:=nW*nH+1+CutLeft
      Loop % w:=nW-CutLeft-CutRight
      {
        i++
        if (!cut[k++] && A_Index<w)
          Continue
        i:=Format("{:d}",i)
        v:=RegExReplace(txt,"m`n)^(.{" i "}).*","$1")
        txt:=RegExReplace(txt,"m`n)^.{" i "}"), i:=0
        While InStr(v,bg)
        {
          if (v~="^" bg "+\n")
            v:=RegExReplace(v,"^" bg "+\n")
          else if !(v~="m`n)[^\n" bg "]$")
            v:=RegExReplace(v,"m`n)" bg "$")
          else if (v~="\n" bg "+\n$")
            v:=RegExReplace(v,"\n\K" bg "+\n$")
          else if !(v~="m`n)^[^\n" bg "]")
            v:=RegExReplace(v,"m`n)^" bg)
          else Break
        }
        if (v!="")
        {
          v:=Format("{:d}",InStr(v,"`n")-1) "." this.bit2base64(v)
          s.="`nText.=""|<" SubStr(Comment,1,1) ">" color "$" v """`n"
          Comment:=SubStr(Comment, 2)
        }
      }
      Event:=cmd, Result:=s
      Gui, Hide
      return
    }
    if (!MultiColor)
      txt:=Format("{:d}",InStr(txt,"`n")-1) "." this.bit2base64(txt)
    else
    {
      GuiControlGet, n,, dRGB
      color:=Format("##{:06X}", n<<16|n<<8|n)
      r:=StrSplit(Trim(StrReplace(Result, ",", "/"), "/"), "/")
      , x:=r[1], y:=r[2], s:="", i:=1
      SetFormat, IntegerFast, d
      Loop % r.Length()//3
        s.="," (r[i++]-x) "/" (r[i++]-y) "/" r[i++]
      txt:=SubStr(s,2)
    }
    s:="`nText.=""|<" Comment ">" color "$" txt """`n"
    if (cmd="AllAdd")
    {
      Event:=cmd, Result:=s
      Gui, Hide
      return
    }
    x:=nX+CutLeft+(nW-CutLeft-CutRight)//2
    y:=nY+CutUp+(nH-CutUp-CutDown)//2
    s:=StrReplace(s, "Text.=", "Text:="), r:=StrSplit(Lang["s8"] "|||||||", "|")
    s:="`; #Include <FindText>`n"
    . "`nt1:=A_TickCount, Text:=X:=Y:=""""`n" s
    . "`nif (ok:=FindText(X, Y, " x "-150000, "
    . y "-150000, " x "+150000, " y "+150000, 0, 0, Text))"
    . "`n{"
    . "`n  `; FindText()." . "Click(" . "X, Y, ""L"")"
    . "`n}`n"
    . "`n`; ok:=FindText(X:=""wait"", Y:=3, 0,0,0,0,0,0,Text)    `; " r[7]
    . "`n`; ok:=FindText(X:=""wait0"", Y:=-1, 0,0,0,0,0,0,Text)  `; " r[8]
    . "`n`nMsgBox, 4096, Tip, `% """ r[1] ":``t"" (IsObject(ok)?ok.Length():ok)"
    . "`n  . ""``n``n" r[2] ":``t"" (A_TickCount-t1) "" " r[3] """"
    . "`n  . ""``n``n" r[4] ":``t"" X "", "" Y"
    . "`n  . ""``n``n" r[5] ":``t<"" (IsObject(ok)?ok[1].id:"""") "">""`n"
    . "`nTry For i,v in ok  `; ok " r[6] " ok:=FindText().ok"
    . "`n  if (i<=2)"
    . "`n    FindText().MouseTip(ok[i].x, ok[i].y)`n"
    Event:=cmd, Result:=s
    Gui, Hide
    return
  Case "SavePic2":
    x:=nX+CutLeft, w:=nW-CutLeft-CutRight
    y:=nY+CutUp, h:=nH-CutUp-CutDown
    %Gui_%("ScreenShot", x "|" y "|" (x+w-1) "|" (y+h-1) "|0")
    return
  Case "ShowPic":
    Gui, FindText_Main: Default
    ControlGet, i, CurrentLine,,, ahk_id %hscr%
    ControlGet, s, Line, %i%,, ahk_id %hscr%
    GuiControl,, MyPic, % Trim(this.ASCII(s),"`n")
    return
  Case "KeyDown":
    Critical
    if (A_Gui!="FindText_Main")
      return
    if (A_GuiControl="scr")
      SetTimer, %Gui_ShowPic%, -150
    else if (A_GuiControl="ClipText")
    {
      GuiControlGet, s, FindText_Main:, ClipText
      GuiControl, FindText_Main:, MyPic, % Trim(this.ASCII(s),"`n")
    }
    return
  Case "LButtonDown":
    Critical
    if (A_Gui="FindText_SubPic")
    {
      ; Two windows trigger two messages
      if (A_TickCount-oldt)<100 || !GetKeyState("LButton","P")
        return
      CoordMode, Mouse
      MouseGetPos, k1, k2
      ListLines % (lls:=A_ListLines)?0:0
      Loop
      {
        Sleep 50
        MouseGetPos, k3, k4
        this.RangeTip(Min(k1,k3), Min(k2,k4)
        , Abs(k1-k3), Abs(k2-k4), (A_MSec<500 ? "Red":"Blue"))
      }
      Until !GetKeyState("LButton","P")
      ListLines % lls
      this.RangeTip()
      this.GetBitsFromScreen(,,,,0,zx,zy)
      this.ClientToScreen(sx, sy, 0, 0, sub_hpic)
      if Abs(k1-k3)+Abs(k2-k4)>4
        sx:=zx+Min(k1,k3)-sx, sy:=zy+Min(k2,k4)-sy
        , sw:=Abs(k1-k3), sh:=Abs(k2-k4)
      else
        sx:=zx+k1-sx-71//2, sy:=zy+k2-sy-25//2, sw:=71, sh:=25
      %Gui_%("CaptureUpdate")
      GuiControl, FindText_Capture: Choose, MyTab1, 1
      oldt:=A_TickCount
      return
    }
    if (A_Gui!="FindText_Capture")
      return %Gui_%("KeyDown")
    MouseGetPos,,,, k2, 2
    k1:=0
    ListLines % (lls:=A_ListLines)?0:0
    For k_,v_ in C_
      if (v_=k2) && (k1:=k_)
        Break
    ListLines % lls
    if (k1<1)
      return
    else if (k1>71*25)
    {
      k3:=nW*nH+dx+(k1-71*25)
      SendMessage,0x2001,0,((cut[k3]:=!cut[k3])?0x0000FF:0xAAFFFF),,% "ahk_id " k2
      return
    }
    k2:=Mod(k1-1,71)+dx, k3:=(k1-1)//71+dy
    if (k2<0 || k2>=nW || k3<0 || k3>=nH)
      return
    k1:=k, k4:=c, k:=k3*nW+k2+1
    if (MultiColor && !cut[k])
    {
      c:="," (nX+k2) "/" (nY+k3) "/"
      . Format("{:06X}",cors[k]&0xFFFFFF)
      , Result.=InStr(Result,c) ? "":c
      ToolTip % Trim(Result,"/,")
    }
    if (Modify && bg!="" && !cut[k])
    {
      ascii[k]:=c:=(ascii[k] ? 0x000000:0xFFFFFF)
      if (tx:=Mod(k-1,nW)-dx)>=0 && tx<71 && (ty:=(k-1)//nW-dy)>=0 && ty<25
        SendMessage,0x2001,0,c,,% "ahk_id " C_[ty*71+tx+1]
    }
    else
    {
      c:=cors[k], cors.SelPos:=k
      Gui, FindText_Capture: Default
      GuiControl,, SelGray, % (((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
      GuiControl,, SelColor, % Format("0x{:06X}",c&0xFFFFFF)
      GuiControl,, SelR, % (c>>16)&0xFF
      GuiControl,, SelG, % (c>>8)&0xFF
      GuiControl,, SelB, % c&0xFF
    }
    k:=k1, c:=k4
    return
  Case "RButtonDown":
    Critical
    if (A_Gui!="FindText_SubPic")
      return
    ; Two windows trigger two messages
    if (A_TickCount-oldt)<100 || !GetKeyState("RButton","P")
      return
    r:=[x, y, w, h, pX, pY, pW, pH]
    CoordMode, Mouse
    MouseGetPos, k1, k2
    WinGetPos, x, y, w, h, ahk_id %parent_id%
    WinGetPos, pX, pY, pW, pH, ahk_id %sub_hpic%
    pX-=x, pY-=y, pW-=w, pH-=h
    ListLines % (lls:=A_ListLines)?0:0
    Loop
    {
      Sleep 10
      MouseGetPos, k3, k4
      x:=Min(Max(pX+k3-k1,-pW),0), y:=Min(Max(pY+k4-k2,-pH),0)
      Gui, FindText_SubPic: Show, NA x%x% y%y%
      GuiControl, FindText_Capture:, MySlider3, % Round(-x/pW*100)
      GuiControl, FindText_Capture:, MySlider4, % Round(-y/pH*100)
    }
    Until !GetKeyState("RButton","P")
    ListLines % lls
    x:=r[1], y:=r[2], w:=r[3], h:=r[4], pX:=r[5], pY:=r[6], pW:=r[7], pH:=r[8]
    oldt:=A_TickCount
    return
  Case "MouseMove":
    if (PrevControl!=A_GuiControl)
    {
      ToolTip
      PrevControl:=A_GuiControl
      if (Gui_ToolTip)
      {
        SetTimer, %Gui_ToolTip%, % PrevControl ? -500 : "Off"
        SetTimer, %Gui_ToolTipOff%, % PrevControl ? -5500 : "Off"
      }
    }
    return
  Case "ToolTip":
    MouseGetPos,,, _TT
    IfWinExist, ahk_id %_TT% ahk_class AutoHotkeyGUI
      ToolTip % Tip_Text[PrevControl]
    return
  Case "ToolTipOff":
    ToolTip
    return
  Case "CutL2", "CutR2", "CutU2", "CutD2":
    Gui, FindText_Main: Default
    GuiControlGet, s,, MyPic
    s:=Trim(s,"`n") . "`n", v:=SubStr(cmd,4,1)
    if (v="U")
      s:=RegExReplace(s,"^[^\n]+\n")
    else if (v="D")
      s:=RegExReplace(s,"[^\n]+\n$")
    else if (v="L")
      s:=RegExReplace(s,"m`n)^[^\n]")
    else if (v="R")
      s:=RegExReplace(s,"m`n)[^\n]$")
    GuiControl,, MyPic, % Trim(s,"`n")
    return
  Case "Update":
    Gui, FindText_Main: Default
    GuiControl, Focus, scr
    ControlGet, i, CurrentLine,,, ahk_id %hscr%
    ControlGet, s, Line, %i%,, ahk_id %hscr%
    if !RegExMatch(s, "O)(<[^>\n]*>[^$\n]+\$)\d+\.[\w+/]+", r)
      return
    GuiControlGet, v,, MyPic
    v:=Trim(v,"`n") . "`n", w:=Format("{:d}",InStr(v,"`n")-1)
    v:=StrReplace(StrReplace(v,"0","1"),"_","0")
    s:=StrReplace(s, r[0], r[1] . w "." this.bit2base64(v))
    v:="{End}{Shift Down}{Home}{Shift Up}{Del}"
    ControlSend,, %v%, ahk_id %hscr%
    Control, EditPaste, %s%,, ahk_id %hscr%
    ControlSend,, {Home}, ahk_id %hscr%
    return
  }
}

Lang(text:="", getLang:=0)
{
  local
  static init, Lang1, Lang2
  if (!VarSetCapacity(init) && init:="1")
  {
    s:="
    (
Myww       = 宽度 = 调整抓图范围的宽度
Myhh       = 高度 = 调整抓图范围的高度
AddFunc    = 附加 = 复制时带 FindText() 函数
NowHotkey  = 截屏热键 = 当前的截屏热键
SetHotkey1 = = 第一优先级的截屏热键
SetHotkey2 = = 第二优先级的截屏热键
Apply      = 应用 = 应用新的截屏热键
CutU2      = 上删 = 裁剪下面编辑框中文字的上边缘
CutL2      = 左删 = 裁剪下面编辑框中文字的左边缘
CutR2      = 右删 = 裁剪下面编辑框中文字的右边缘
CutD2      = 下删 = 裁剪下面编辑框中文字的下边缘
Update     = 更新 = 更新下面编辑框中文字到代码行中
GetRange   = 获取屏幕范围 = 获取屏幕范围并替换代码中的范围参数
GetOffset  = 获取相对坐标 = 获取相对图像位置的偏移坐标并替换代码中的坐标
GetClipOffset  = 获取相对坐标2 = 获取相对左边编辑框的图像的偏移坐标
Capture    = 抓图 = 开始屏幕抓图
CaptureS   = 截屏抓图 = 先恢复某个截屏到屏幕上再开始抓图
Test       = 测试 = 测试生成的代码是否可以查找成功
TestClip   = 测试2 = 测试左边文本框中的文字，结果复制到剪贴板
Paste      = 粘贴 = 粘贴剪贴板的文字数据
CopyOffset = 复制2 = 复制左边的偏移坐标到剪贴板
Copy       = 复制 = 复制代码到剪贴板
Reset      = 重读 = 重新读取原来的彩色图像
SplitAdd   = 分割添加 = 使用黄色的标签来分割图像为单个的图像数据，添加到旧代码中
AllAdd     = 整体添加 = 将文字数据整体添加到旧代码中
Gray2Two      = 灰度阈值二值化 = 灰度小于阈值的为黑色其余白色
GrayDiff2Two  = 灰度差值二值化 = 某点与周围灰度之差大于差值的为黑色其余白色
Color2Two     = 颜色相似二值化 = 指定颜色及相似色为黑色其余白色
ColorPos2Two  = 颜色位置二值化 = 指定颜色及相似色为黑色其余白色，但是记录该色的位置
ColorDiff2Two = 颜色分量二值化 = 指定颜色及颜色分量小于允许值的为黑色其余白色
SelGray    = 灰度 = 选定颜色的灰度值 (0-255)
SelColor   = 颜色 = 选定颜色的RGB颜色值
SelR       = 红 = 选定颜色的红色分量
SelG       = 绿 = 选定颜色的绿色分量
SelB       = 蓝 = 选定颜色的蓝色分量
RepU       = -上 = 撤销裁剪上边缘1个像素
CutU       = 上 = 裁剪上边缘1个像素
CutU3      = 上3 = 裁剪上边缘3个像素
RepL       = -左 = 撤销裁剪左边缘1个像素
CutL       = 左 = 裁剪左边缘1个像素
CutL3      = 左3 = 裁剪左边缘3个像素
Auto       = 自动 = 二值化之后自动裁剪空白边缘
RepR       = -右 = 撤销裁剪右边缘1个像素
CutR       = 右 = 裁剪右边缘1个像素
CutR3      = 右3 = 裁剪右边缘3个像素
RepD       = -下 = 撤销裁剪下边缘1个像素
CutD       = 下 = 裁剪下边缘1个像素
CutD3      = 下3 = 裁剪下边缘3个像素
Modify     = 修改 = 二值化后可以用鼠标在预览区点击手动修改黑白点
MultiColor = 多色查找 = 鼠标选择多种颜色，之后点击“确定”按钮
Undo       = 撤销 = 撤销上一次选择的颜色
Comment    = 识别文字 = 识别文本 (包含在<>中)，分割添加时也会分解成单个文字
Threshold  = 灰度阈值 = 灰度阈值 (0-255)
GrayDiff   = 灰度差值 = 灰度差值 (0-255)
Similar1   = 相似度 = 与选定颜色的相似度
Similar2   = 相似度 = 与选定颜色的相似度
DiffR      = 红 = 红色分量允许的偏差 (0-255)
DiffG      = 绿 = 绿色分量允许的偏差 (0-255)
DiffB      = 蓝 = 蓝色分量允许的偏差 (0-255)
DiffRGB    = 红/绿/蓝 = 多色查找时各分量允许的偏差 (0-255)
Bind0      = 绑定窗口1 = 绑定窗口使用GetDCEx()获取后台窗口图像
Bind1      = 绑定窗口1+ = 绑定窗口使用GetDCEx()并修改窗口透明度
Bind2      = 绑定窗口2 = 绑定窗口使用PrintWindow()获取后台窗口图像
Bind3      = 绑定窗口2+ = 绑定窗口使用PrintWindow()并修改窗口透明度
Bind4      = 绑定窗口3 = 绑定窗口使用PrintWindow(,,3)获取后台窗口图像
OK         = 确定 = 生成全新的代码替换旧代码
OK2        = 确定 = 恢复截屏到屏幕然后再抓图
Cancel     = 取消 = 关闭窗口不做任何事
Cancel2    = 取消 = 关闭窗口不做任何事
ClearAll   = 清空 = 清空所有保存的截图
OpenDir    = 打开目录 = 打开保存屏幕截图的目录
SavePic    = 保存图片 = 选择一个范围保存为图片
SavePic2   = 保存图片 = 将修剪后的原始图像保存为图片
LoadPic    = 载入图片 = 载入一张图片作为抓取的图像
ClipText   = = 显示粘贴的文字数据
Offset     = = 显示“获取相对坐标2”或者“获取屏幕范围”的结果
SelectBox  = = 选择截图显示到屏幕左上角
s1  = FindText
s2  = 灰度阈值|灰度差值|颜色相似|颜色位置|颜色分量|多色查找
s3  = 图像二值化及分割
s4  = 抓图生成字库及找字代码
s5  = 方向键微调选框\n先点击右键一次\n把鼠标移开\n再点击右键一次
s6  = 解绑窗口使用
s7  = 请用左键拖动范围\n坐标复制到剪贴板
s8  = 找到|时间|毫秒|位置|结果|值可以这样获取|等待3秒等图像出现|无限等待等图像消失
s9  = 截屏成功
s10 = 鼠标位置|穿透显示绑定窗口\n点击右键完成抓图
s11 = 请先设定灰度差值
s12 = 请先选择核心颜色
s13 = 请先将图像二值化
s14 = 不能用于颜色位置二值化模式, 因为分割后会导致位置错误
s15 = 重选|到文件|仅范围|到剪贴板
s16 = 左键拖动选择范围，方向键微调\n右键或ESC仅范围，双击到剪贴板
s17 = 请先保存图片
s18 = 捕获|截图
    )"
    Lang1:=[], Lang2:=[]
    Loop Parse, s, `n, `r
      if InStr(v:=A_LoopField, "=")
        r:=StrSplit(StrReplace(v "==","\n","`n"), "=", "`t ")
        , Lang1[r[1]]:=r[2], Lang2[r[1]]:=r[3]
  }
  return getLang=1 ? Lang1 : getLang=2 ? Lang2 : Lang1[text]
}

}  ;// Class End

Script_End() {
}

;================= The End =================

;