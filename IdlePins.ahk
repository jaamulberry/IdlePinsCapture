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
IniRead, value, settings.ini, pinPos, X1
pinPos["posX1"] := value
IniRead, value, settings.ini, pinPos, Y1
pinPos["posY1"] := value
IniRead, value, settings.ini, pinPos, X2
pinPos["posX2"] := value
IniRead, value, settings.ini, pinPos, Y2
pinPos["posY2"] := value


;If (EmptyPinTotal = PinTotal)
    ;Gosub, GrabCoordinates
    ;GoSub, ReadPinTotal

;Ever 20 Seconds check status of game
SetTimer, CheckEverything, 20000


CheckEverything:
GoSub, GrabTotalPins
Return



GrabTotalPins:
;Don't reuse old value. Could not have been updated.
pinsText4 = "Error"

;Setup CMD command text
s1 = cmd.exe /c Capture2Text\Capture2Text_CLI.exe -s "
s2 := pinPos["PosX1"] " " pinPos["PosY1"] " " pinPos["PosX2"] " " pinPos["PosY2"]
s3 = " -o OCR.txt

;Combine into one long string
target := s1 s2 s3
;Minimize command prompt so it doesn't intefere with OCR
run, %target%,,Minimize
;OCR is slower than script. Sleep for 2 seconds to make sure file is updated 
Sleep, 2000
;Read OCR results
FileRead, currentPins, OCR.txt

;Pull the strings from OCR except for the word Pins
StringSplit, pinsText, currentPins , %A_Space% , "Pins"
Trim(pinsText4)
StringReplace, pinsText4, pinsText4, `r`n,,A

;What are the max pins I should expect
IniRead, maxPins, settings.ini, gameStats, MaxPins

If (pinsText4 != maxPins){
    ;Pins didn't match. Log and wait
    FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
    FileAppend, %curTime%: Error in OCR. Expected %maxPins%. Found: %pinsText4% `n, log.txt
    Return
}
Else
    ;Pins matched. Log
    FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
    FileAppend, %curTime%: OCR Validated. %pinsText2%`n, log.txt
    Trim(pinsText2)
    StringReplace, pinsText2, pinsText2, `r`n,,A
    ;If Pins are getter than 42(MinPins) disable autocollect 
    If (pinsText2 >= 42){
        changeColor("r")
        return
    }
    ;If Pins are less than 42(MinPins) enable autocollect
    If (pinsText2 < 42){
        changeColor("g")
        return
    }
    ;Couldn't read Pin as a number. Log and error
    Else {
        FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
        FileAppend, %curTime%: Couldn't get pins number `n, log.txt
        return
    }

changeColor(endResult)
{
    ;Assuming 1080p screen
    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen
    ;Grab x and y of autocollect button
    IniRead, xAuto, settings.ini, autoPos, X1
    IniRead, yAuto, settings.ini, autoPos, Y1
    ;Grab color
    PixelGetColor, autoColor, %xAuto%, %yAuto%
    greenColor := 0x2F694B
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
        FileAppend, %curTime%: Tried to Change Color`n, log.txt
        return
    }

    If (autoColor = goodColor) { ;Keep same
        FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
        FileAppend, %curTime%: Color was fine`n, log.txt
        return
    }
    Else { ;Didn't find the right color
        FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
        FileAppend, %curTime%: wrong color found: %autoColor%`n, log.txt
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
