#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force
#Persistent
#Include, JSON.ahk

ReadPinTotal:
FileRead, settings, settings.json
MsgBox, Info is %settings%
allPos := JSON.Load(settings.json)
transformJson := JSON.Load(settings)
MsgBox, Info is %transformJson%
MsgBox, Info is %allPos% 
ExitApp, 0