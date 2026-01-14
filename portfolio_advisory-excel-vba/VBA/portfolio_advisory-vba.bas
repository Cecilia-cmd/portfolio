Attribute VB_Name = "Module1"
Option Explicit

Public Sub RefreshAndValidate()
    On Error GoTo ErrHandler

    Dim wsSum As Worksheet, wsHold As Worksheet
    Dim clientId As String
    Dim errCount As Long

    Set wsSum = ThisWorkbook.Worksheets("Portfolio_Summary")
    Set wsHold = ThisWorkbook.Worksheets("Holdings")

    clientId = Trim$(CStr(wsSum.Range("C2").Value))
    If clientId = "" Then
        MsgBox "Please select a client in Portfolio_Summary!C2.", vbExclamation
        Exit Sub
    End If

    Application.ScreenUpdating = False
    Application.EnableEvents = False

    Application.Calculate

    ' Timestamp
    wsSum.Range("K2").Value = Now
    wsSum.Range("K2").NumberFormat = "yyyy-mm-dd hh:mm"

    ' Count formula errors
    errCount = Application.WorksheetFunction.CountIf(wsHold.UsedRange, "#N/A") _
             + Application.WorksheetFunction.CountIf(wsHold.UsedRange, "#NAME?") _
             + Application.WorksheetFunction.CountIf(wsHold.UsedRange, "#VALUE!") _
             + Application.WorksheetFunction.CountIf(wsHold.UsedRange, "#REF!")

    Application.ScreenUpdating = True
    Application.EnableEvents = True

    If errCount = 0 Then
        MsgBox "Refresh OK for " & clientId & ". No formula errors detected.", vbInformation
    Else
        MsgBox "Refresh done for " & clientId & ", but " & errCount & _
               " formula error(s) detected in Holdings." & vbCrLf & _
               "Tip: check fx_to_chf / market_value_chf columns.", vbExclamation
    End If

    Exit Sub

ErrHandler:
    Application.ScreenUpdating = True
    Application.EnableEvents = True
    MsgBox "Error in RefreshAndValidate: " & Err.Description, vbExclamation
End Sub


Public Sub GenerateMarketCommentary()
    On Error GoTo Fail
    
    Dim wsS As Worksheet, wsM As Worksheet
    Set wsS = ThisWorkbook.Worksheets("Portfolio_Summary")
    Set wsM = ThisWorkbook.Worksheets("Market_Commentary")
    
    ' Header (client context)
    Dim clientId As String, segment As String, risk As String, mandate As String
    clientId = Trim(CStr(wsS.Range("C2").Value))
    segment = Trim(CStr(wsS.Range("D2").Value))
    risk = Trim(CStr(wsS.Range("E2").Value))
    mandate = Trim(CStr(wsS.Range("F2").Value))
    
    If clientId = "" Then clientId = "N/A"
    If segment = "" Then segment = "N/A"
    If risk = "" Then risk = "N/A"
    If mandate = "" Then mandate = "N/A"
    
    wsM.Range("A1").Value = "Client: " & clientId & " (" & segment & ", " & risk & ", " & mandate & ")."
    wsM.Range("A2").Value = "Market Commentary (Switzerland) | January 2026 | " & Format(Date, "yyyy-mm-dd")
    
    '  Body (macro only, Switzerland-focused)
    Dim body As String
    body = "Overview:" & vbCrLf & _
           "Swiss markets continue to reflect a low-growth, low-inflation environment, with the CHF supported by its safe-haven profile. " & _
           "In this context, defensives and income-oriented assets remain relatively attractive, while volatility can rise around macro and geopolitical headlines." & vbCrLf & vbCrLf & _
           "Central bank (SNB):" & vbCrLf & _
           "• Policy stance remains accommodative, with a focus on price stability (0–2%) and attention to CHF strength." & vbCrLf & _
           "• Base case: rates stay low in 2026 as long as inflation remains contained." & vbCrLf & vbCrLf & _
           "Inflation:" & vbCrLf & _
           "• Inflation remains very low by international standards; CHF strength continues to limit imported price pressures." & vbCrLf & _
           "• Key watch items: energy prices, supply-chain disruptions, and services inflation." & vbCrLf & vbCrLf & _
           "Earnings & equities:" & vbCrLf & _
           "• Earnings expectations are cautiously positive, supported by defensive sectors (healthcare, staples) and select exporters." & vbCrLf & _
           "• Dividend yield and quality bias remain attractive in a low-rate environment." & vbCrLf & vbCrLf & _
           "Geopolitics:" & vbCrLf & _
           "• Ongoing geopolitical uncertainty supports Switzerland’s safe-haven role, but global trade and sanctions complexity remain key risks for cross-border finance." & vbCrLf & vbCrLf & _
           "Implications:" & vbCrLf & _
           "Maintain diversification, avoid reactive trading around headline risk, and rebalance systematically when allocations drift."
    
    wsM.Range("A4").Value = body
    
    ' Formatting
    With wsM.Columns("A")
        .ColumnWidth = 115
        .WrapText = True
    End With
    
    wsM.Rows("1").Font.Bold = True
    wsM.Rows("2").Font.Italic = True

    wsM.Rows("4").RowHeight = 380
    
    Exit Sub

Fail:
    MsgBox "GenerateMarketCommentary failed: " & Err.Description, vbExclamation
End Sub

