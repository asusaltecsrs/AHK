#Include ./lib/FindText-9.4.ahk


Text:="|<帮助>*158$42.4008000zyD80004G982EqzK9zYEm4HD9YEnzz99gElMkD9gTlzy99gEl8W99AEl8WDtAEl8wMl4En0U0b4020000206U"

if (ok:=FindText(X, Y, 465-150000, 18-150000, 465+150000, 18+150000, 0, 0, Text))
{
  FindText().Click(X, Y, "L")
}

