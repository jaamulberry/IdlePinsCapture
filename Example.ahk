#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force

CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
PixelGetColor, autoColor, 835, 485
greenColor := autoColor
;redColor = 0
If (autoColor = greenColor){ ;Green. Switch to red
    MouseClick, Left, 845, 485
}

If (autoColor = 2) { ;Red. Wait
    Return
}
Else {
    MsgBox, % "Error: " autoColor " | " greenColor
    FormatTime, curTime, , yyyy-MM-dd hh:mm:ss tt
    FileAppend, %curTime% wrong color found: %autoColor%`r, log.txt
}