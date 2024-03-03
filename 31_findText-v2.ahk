#Include ./lib/FindText-9.4-V2.ahk

!q::
{
    Text:="|<帮助>*159$25.4008Tz7Y14WG7ulDwFAwbzyGHMkD9zz4Ym8WGF4Fz8XlX4101CU"

    if (ok:=FindText(&X, &Y, 456-150000, 18-150000, 456+150000, 18+150000, 0, 0, Text))
    {
        FindText().Click(X, Y, "L")
    }
}
