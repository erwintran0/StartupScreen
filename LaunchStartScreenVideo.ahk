#NoEnv
#SingleInstance force
SetBatchLines, -1
SetTitleMatchMode, 2

DllCall("SetProcessDPIAware")

; --- User settings ---
videoDir := "E:\Videos\StartScreens"
vlcPath := "C:\Program Files\VideoLAN\VLC\vlc.exe"
maxRandomStart := 1 ; seconds

; Optional: autoplay once when script starts
Gosub, PlayRandomVideo
Return

; --- Hotkey ---
F15::
    Gosub, PlayRandomVideo
Return

; --- Main Playback Routine ---
PlayRandomVideo:

; --- Close any existing VLC instance first ---
Process, Close, vlc.exe

; --- Pick a random video ---
videoList := []
Loop, Files, %videoDir%\*.mp4
{
    videoList.Push(A_LoopFileFullPath)
}

if (videoList.Length() = 0)
{
    MsgBox, 48, Error, No MP4 files found in %videoDir%.
    Return
}

Random, randIndex, 1, % videoList.Length()
videoPath := videoList[randIndex]

; --- Pick random start time ---
Random, randStart, 0, %maxRandomStart%

; --- Find the smallest monitor by area ---
SysGet, monitorCount, MonitorCount

debugText := ""

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

    debugText .= "Mon " . mon . " smallest Area " . area
          . " | Width: " . monWidth
          . " Height: " . monHeight
          . " | Left: " . monLeft
          . " Top: " . monTop . "`n"
}

if (smallestMon = "") {
    MsgBox, Monitors could not be read.
    Return
}

; --- Debug Prints ---
; MsgBox, Mon %smallestMon% smalles Area %smallestArea%: | Width: %monSmallestWidth% Height: %monSmallestHeight% | Left: %monSmallestLeft% Top: %monSmallestTop%
debugText .= "`n`n`n"
debugText .= "Smallest monitor: " . smallestMon
          . " | Area: " . smallestArea
          . " | Width: " . monSmallestWidth
          . " Height: " . monSmallestHeight
          . " | Left: " . monSmallestLeft
          . " Top: " . monSmallestTop
; MsgBox, % "Debug:`n" . debugText

; --- Launch VLC ---
cmdLine := Format("""{1}"" ""{2}"" --start-time={3} --fullscreen", vlcPath, videoPath, randStart)
Run, % cmdLine

; --- Wait for VLC window ---
WinWait, ahk_exe vlc.exe
WinActivate, ahk_exe vlc.exe
WinGet, vlcWinId, ID, ahk_exe vlc.exe

; --- Move VLC to smallest monitor ---
Sleep, 300
WinMove, ahk_id %vlcWinId%, , monSmallestLeft, monSmallestTop, monSmallestWidth, monSmallestHeight
; WinMove, ahk_id %vlcWinId%, , monSmallestLeft, monSmallestTop, 1200, 750

; --- Mute and fullscreen ---
WinActivate, ahk_id %vlcWinId%

Sleep, 100
Send, m

Return


