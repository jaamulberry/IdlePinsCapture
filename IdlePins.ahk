#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force
#Persistent

;TODO Empty positions to setup coordiantes
emptyPinsPos := { posX1: 0, posY1: 0, posX2: 0, posY2: 0 }
emptyAutoPos := { posX1: 0, posY1: 0 }

pinPos := emptyPinsPos
AutoPos := emptyAutoPos

ReadPinCoords:
;Read Pin coordiantes from ini File
IniRead, X1, settings.ini, pinPos, X1
IniRead, Y1, settings.ini, pinPos, Y1
IniRead, X2, settings.ini, pinPos, X2
IniRead, Y2, settings.ini, pinPos, Y2


;TODO #5 Create empty check if settings is off
;If (EmptyPinTotal = PinTotal)
    ;Gosub, GrabCoordinates
    ;GoSub, ReadPinTotal

;Every 40 Seconds check status of game
SetTimer, CheckEverything, 40000


CheckEverything:
GrabTotalPins(X1, Y1, X2, Y2)
Return



GrabTotalPins(X1, Y1, X2, Y2)
{
    ;Setup CMD command text
    s1 = cmd.exe /c Capture2Text\Capture2Text_CLI.exe -s "
    s2 := X1 " " Y1 " " X2 " " Y2
    s3 = " -o OCR.txt

    ;Combine into one long string
    target := s1 s2 s3
    ;Minimize command prompt so it doesn't intefere with OCR
    run, %target%,,Minimize
    ;OCR is slower than script. Sleep for 2 seconds to make sure file is updated 
    Sleep, 2000
    ;Read OCR results
    currentPins = Error
    FileRead, currentPins, OCR.txt

    ;Pull the strings from OCR except for the word Pins
    pinsArray := "Error"
    pinsArray := StrSplit(currentPins , A_Space, "Pins")

    For k, v in pinsArray
        pinsText .= v

    StringReplace, pinsText, pinsText, `r `n %A_Space%,,A
    lastPins = Error
    firstPins = Error
    lastPins := SubStr(pinsText, 4, 2)
    firstPins := SubStr(pinsText, 1, 2)

    ;What are the max pins I should expect & percent of min pins
    IniRead, maxPins, settings.ini, gameStats, MaxPins
    IniRead, pinPercent, settings.ini, gameStats, MinPinsPercent
    If (lastPins != maxPins){
        ;Pins didn't match. Log and wait
        FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
        FileAppend, %curTime%: Error in OCR. Expected %maxPins%. Found: %lastPins% `n, log.txt
        Return
    }
    Else
        ;Pins matched. Log
        FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
        FileAppend, %curTime%: OCR Validated: %lastPins%`n, log.txt
        ;If Pins are getter than 42(MinPins) disable autocollect 
        ;Change min pins to percent
        pinPercent = 0.%pinPercent%
        minPins := Maxpins -(Round(maxPins*pinPercent))

        If (firstPins >= minPins){
            changeColor("r", minPins, firstPins)
            return
        }
        ;If Pins are less than 42(MinPins) enable autocollect
        If (firstPins < minPins){
            changeColor("g", minPins, firstPins)
            return
        }
        ;Couldn't read Pin as a number. Log and error
        Else {
            FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
            FileAppend, %curTime%: Couldn't get pins number `n, log.txt
            return
        }
}
changeColor(endResult, minPins, curPins)
{
    ;Assuming 1080p screen
    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen
    ;Grab x and y of autocollect button
    IniRead, xAuto, settings.ini, autoPos, X1
    IniRead, yAuto, settings.ini, autoPos, Y1
    ;Grab color
    autoColor = 0
    PixelGetColor, autoColor, %xAuto%, %yAuto%
    greenColor = 0x2F694B
    redColor = 0x3232AC

    ;What is the end Result I want.
    ;if R I want red to be the color
    If (endResult = "r"){
        evilColor := greenColor
        goodColor := redColor
    }
    ;if g I want green to be the color
    If (endResult = "g"){
        evilColor := redColor
        goodColor := greenColor
    }

    If (autoColor = evilColor){ ;Switch
        MouseClick, Left, %xAuto%, %yAuto%
        FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
        FileAppend, %curTime%: Wrong color %evilColor% Detected. Tried to Change Color. Pin threshold %curPins%:%minPins%`n, log.txt
        return
    }

    If (autoColor = goodColor) { ;Keep same
        FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
        FileAppend, %curTime%: Color was fine. Is %goodColor%. Pins threshold %curPins%:%minPins%`n, log.txt
        return
    }
    Else { ;Didn't find the right color
        FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
        FileAppend, %curTime%: wrong color found: %autoColor% Pins threshold %curPins%:%minPins%`n, log.txt
        return
    }
}
;GrabCoordinates:
;MsgBox, 1, Empty Coordinates, Press OK to grab coordinates. Cancel will Quit App
;IfMsgBox OK
;    GoSub, GetMousePosition(1)
;Else
;    ExitApp

;GetMousePosition(i):
;ToolTip, Click High Left box for Pins XX / XX
;GetClicks(1)
;ToolTip, Click Lower Right Box for Pinx XX / XX
;MsgBox, 6, Mouse Coords, First Coordinate %CoordX1% %CoordY1% \nSecond Coordinate %CoordX2% %CoordY2%
;IfMsgBox, Retry
;    GoSub, GetMousePosition(i)
;IfMsgBox, Continue
;    If (i = 1)
;    {
;        IniWrite, CoordX1, settings.ini, PinCountPosition, X1
;        IniWrite, CoordY1, settings.ini, PinCountPosition, Y1
;        IniWrite, CoordX2, settings.ini, PinCountPosition, X2
;        IniWrite, CoordY2, settings.ini, PinCountPosition, Y2
;    }
;Else
;    ExitApp

;GetClicks(active){
;    if (active = 1)
;        LButton:: 
;            MouseGetPos, CoordX, CoordY
;            return CoordX, CoordY
;}
