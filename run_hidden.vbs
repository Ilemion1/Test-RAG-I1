' Запускает программу (первый аргумент) с параметром (второй аргумент, опционально)
' полностью без окна (0 = hidden), не дожидаясь завершения (False = async).
' Путь и аргумент передаются отдельно, чтобы не возиться с экранированием кавычек.
Dim objShell, exePath, extraArg, fullCmd

Set objShell = CreateObject("WScript.Shell")

exePath = WScript.Arguments(0)

If WScript.Arguments.Count > 1 Then
    extraArg = " " & WScript.Arguments(1)
Else
    extraArg = ""
End If

fullCmd = Chr(34) & exePath & Chr(34) & extraArg

objShell.Run fullCmd, 0, False
