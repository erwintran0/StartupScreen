#NoEnv
#SingleInstance, Force
SetTitleMatchMode, 2

DllCall("SetProcessDPIAware")

; --- Hotkey ---
F14::
    Gosub, RunSpotifySetup
Return

; --- Spotify Logic ---
RunSpotifySetup:

; Try to get Spotify window handle if already open
WinGet, hWnd, ID, ahk_exe Spotify.exe
WinWait, ahk_exe Spotify.exe, , 10

if (hWnd) {    
    ; Spotify is already open
    WinActivate, ahk_id %hWnd%    
    Send, {Esc}    
    Sleep, 500

    ; Move it to the first monitor (0,0)
    WinMove, ahk_id %hWnd%, , 0, 0, 2600, 1390    

    Send, {Esc}
    Sleep, 500

    WinActivate, ahk_id %hWnd%
    WinShow, ahk_id %hWnd%
    Sleep, 300

    MouseMove, 2540, 1330, 0
} else {
    ; Run Spotify
    Run, C:\Users\erwin\AppData\Roaming\Spotify\Spotify.exe
    ; Wait up to 10 seconds for the window
    WinWait, Spotify, , 10

    if ErrorLevel {
        MsgBox, Could not find Spotify window.
        Return
    }

    Sleep, 1000
    WinGet, hWnd, ID, Spotify

    ; Move to main monitor first
    WinMove, ahk_id %hWnd%, , 0, 0
    WinMaximize, ahk_id %hWnd%
    MouseMove, 2540, 1330, 0
}

; Click the fullscreen button
Sleep, 500
Click

; --- Find the smallest monitor by area ---
SysGet, monitorCount, MonitorCount
smallestArea := 0
smallestMon := ""

if (monitorCount < 3)
{
    MsgBox, 48, Error, You don’t have a third monitor detected.
    Return
}

Loop, %monitorCount%
{
    mon := A_Index
    SysGet, monRect, Monitor, %mon%
    monLeft := monRectLeft
    monTop := monRectTop
    monRight := monRectRight
    monBottom := monRectBottom

    if (monLeft = "" || monRight = "") {
        MsgBox, Monitor #%mon% returned blank. Skipping.
        continue
    }

    monWidth := monRight - monLeft
    monHeight := monBottom - monTop
    area := monWidth * monHeight

    if (smallestMon = "" || area < smallestArea) {
        smallestMon := mon
        smallestArea := area
        monSmallestLeft := monLeft
        monSmallestTop := monTop
        monSmallestWidth := monWidth
        monSmallestHeight := monHeight
    }
}

if (smallestMon = "") {
    MsgBox, Monitors could not be read.
    Return
}

WinMove, ahk_id %hWnd%, , monSmallestLeft, monSmallestTop, 300, 300

Sleep, 300

; Optional: hide the mouse afterward
; MouseMove, 1280, 720, 0

Return
