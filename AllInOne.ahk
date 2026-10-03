#NoEnv
#SingleInstance Force
SetBatchLines, -1
SetTitleMatchMode, 2

DllCall("SetProcessDPIAware")

; ============================================================
; USER SETTINGS
; ============================================================

vlcPath := "C:\Program Files\VideoLAN\VLC\vlc.exe"
spotifyPath := "C:\Users\erwin\AppData\Roaming\Spotify\Spotify.exe"

startScreensDir := "E:\Videos\StartScreens"
idleVideosDir := "E:\Videos\IdleVideos"

startScreensMaxRandomStart := 1
idleVideosMaxRandomStart := 3000

; ============================================================
; STARTUP
; Start a random StartScreens video immediately.
; Equivalent to pressing F15.
; ============================================================

SetTimer, DelayedStartupVideo, -30000
Return


DelayedStartupVideo:
    SetTimer, DelayedStartupVideo, Off
    Gosub, PlayStartScreenVideo
Return


; ============================================================
; HOTKEYS
; ============================================================

; F13 = Play random idle video
F13::
    Gosub, PlayIdleVideo
Return


; F14 = Setup / fullscreen Spotify
F14::
    Gosub, RunSpotifySetup
Return


; F15 = Play random StartScreens video
F15::
    Gosub, PlayStartScreenVideo
Return


; F16 = Put Windows to sleep
F16::
    DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
Return


; ============================================================
; START SCREEN VIDEO
; ============================================================

PlayStartScreenVideo:
    PlayRandomVideo(startScreensDir, startScreensMaxRandomStart, true)
Return


; ============================================================
; IDLE VIDEO
; ============================================================

PlayIdleVideo:
    PlayRandomVideo(idleVideosDir, idleVideosMaxRandomStart, false)
Return


; ============================================================
; GENERIC VLC VIDEO PLAYER
;
; Parameters:
;   videoDir       = directory containing MP4 files
;   maxRandomStart = maximum random starting position in seconds
;   moveToMonitor  = true -> move VLC to smallest monitor
;                    false -> leave VLC where it opens
; ============================================================

PlayRandomVideo(videoDir, maxRandomStart, moveToMonitor)
{
    global vlcPath

    ; --------------------------------------------------------
    ; Verify VLC exists
    ; --------------------------------------------------------

    if !FileExist(vlcPath)
    {
        MsgBox, 48, VLC Error, VLC was not found:`n`n%vlcPath%
        Return
    }

    ; --------------------------------------------------------
    ; Stop any existing VLC instance
    ; --------------------------------------------------------

    Process, Close, vlc.exe
    Process, WaitClose, vlc.exe, 3

    ; --------------------------------------------------------
    ; Find MP4 files
    ; --------------------------------------------------------

    videoList := []

    Loop, Files, %videoDir%\*.mp4
    {
        videoList.Push(A_LoopFileFullPath)
    }

    if (videoList.Length() = 0)
    {
        MsgBox, 48, Video Error, No MP4 files found in:`n`n%videoDir%
        Return
    }

    ; --------------------------------------------------------
    ; Pick random video
    ; --------------------------------------------------------

    Random, randIndex, 1, % videoList.Length()
    videoPath := videoList[randIndex]

    ; --------------------------------------------------------
    ; Pick random start position
    ; --------------------------------------------------------

    Random, randStart, 0, %maxRandomStart%

    ; --------------------------------------------------------
    ; Determine target monitor if requested
    ; --------------------------------------------------------

    if (moveToMonitor)
    {
        if !GetSmallestMonitor(monLeft, monTop, monWidth, monHeight)
            Return
    }

    ; --------------------------------------------------------
    ; Launch VLC
    ; --------------------------------------------------------

    cmdLine := Format("""{1}"" ""{2}"" --start-time={3} --fullscreen"
        , vlcPath
        , videoPath
        , randStart)

    Run, %cmdLine%

    ; --------------------------------------------------------
    ; Wait for VLC window
    ; --------------------------------------------------------

    WinWait, ahk_exe vlc.exe, , 10

    if ErrorLevel
    {
        MsgBox, 48, VLC Error, VLC did not open within 10 seconds.
        Return
    }

    WinGet, vlcWinId, ID, ahk_exe vlc.exe

    if (!vlcWinId)
    {
        MsgBox, 48, VLC Error, Could not obtain the VLC window handle.
        Return
    }

    WinActivate, ahk_id %vlcWinId%

    ; --------------------------------------------------------
    ; Move VLC to smallest monitor if requested
    ; --------------------------------------------------------

    if (moveToMonitor)
    {
        Sleep, 300

        WinMove
            , ahk_id %vlcWinId%
            ,
            , %monLeft%
            , %monTop%
            , %monWidth%
            , %monHeight%
    }

    ; --------------------------------------------------------
    ; Mute VLC
    ; --------------------------------------------------------

    WinActivate, ahk_id %vlcWinId%

    Sleep, 100
    Send, m
}


; ============================================================
; FIND SMALLEST MONITOR
;
; Returns:
;   true  = monitor found
;   false = error
;
; Output variables:
;   left
;   top
;   width
;   height
; ============================================================

GetSmallestMonitor(ByRef left, ByRef top, ByRef width, ByRef height)
{
    SysGet, monitorCount, MonitorCount

    if (monitorCount < 3)
    {
        MsgBox, 48, Monitor Error
            , You need at least 3 monitors for this script.`n`nDetected: %monitorCount%
        Return false
    }

    smallestArea := 0
    smallestMon := 0

    Loop, %monitorCount%
    {
        mon := A_Index

        ; Use the full monitor area rather than the work area.
        ; This is appropriate for fullscreen VLC.
        SysGet, monRect, Monitor, %mon%

        monLeft := monRectLeft
        monTop := monRectTop
        monRight := monRectRight
        monBottom := monRectBottom

        monWidth := monRight - monLeft
        monHeight := monBottom - monTop

        if (monWidth <= 0 || monHeight <= 0)
            Continue

        area := monWidth * monHeight

        if (smallestMon = 0 || area < smallestArea)
        {
            smallestMon := mon

            smallestArea := area

            left := monLeft
            top := monTop
            width := monWidth
            height := monHeight
        }
    }

    if (smallestMon = 0)
    {
        MsgBox, 48, Monitor Error, Could not determine the smallest monitor.
        Return false
    }

    Return true
}


; ============================================================
; SPOTIFY
; ============================================================

RunSpotifySetup:
    ; --------------------------------------------------------
    ; Try to find an existing Spotify window
    ; --------------------------------------------------------

    WinGet, hWnd, ID, ahk_exe Spotify.exe

    if (!hWnd)
    {
        ; Spotify isn't running -> launch it
        if !FileExist(spotifyPath)
        {
            MsgBox, 48, Spotify Error, Spotify was not found:`n`n%spotifyPath%
            Return
        }

        Run, %spotifyPath%

        WinWait, ahk_exe Spotify.exe, , 10

        if ErrorLevel
        {
            MsgBox, 48, Spotify Error, Could not find the Spotify window within 10 seconds.
            Return
        }

        Sleep, 1000

        WinGet, hWnd, ID, ahk_exe Spotify.exe

        if (!hWnd)
        {
            MsgBox, 48, Spotify Error, Could not obtain the Spotify window handle.
            Return
        }
    }

    ; --------------------------------------------------------
    ; Get primary monitor dimensions
    ; --------------------------------------------------------

    SysGet, primaryMonitor, MonitorPrimary
    SysGet, primaryRect, Monitor, %primaryMonitor%

    primaryLeft := primaryRectLeft
    primaryTop := primaryRectTop
    primaryRight := primaryRectRight
    primaryBottom := primaryRectBottom

    primaryWidth := primaryRight - primaryLeft
    primaryHeight := primaryBottom - primaryTop

    ; --------------------------------------------------------
    ; Move Spotify to primary monitor
    ; --------------------------------------------------------

    WinActivate, ahk_id %hWnd%

    Sleep, 300

    Send, {Esc}
    Sleep, 300

    WinShow, ahk_id %hWnd%

    WinMove, ahk_id %hWnd%, , %primaryLeft%, %primaryTop%, %primaryWidth%, %primaryHeight%

    WinMaximize, ahk_id %hWnd%

    Sleep, 500

    ; --------------------------------------------------------
    ; Move mouse to bottom-right of primary monitor
    ; --------------------------------------------------------

    mouseX := primaryRight - 60
    mouseY := primaryBottom - 60

    MouseMove, %mouseX%, %mouseY%, 0

    Sleep, 500

    ; --------------------------------------------------------
    ; Click fullscreen button
    ; --------------------------------------------------------

    Click

    Sleep, 500

    ; --------------------------------------------------------
    ; Find smallest monitor
    ; --------------------------------------------------------

    if !GetSmallestMonitor(smallestLeft, smallestTop, smallestWidth, smallestHeight)
    {
        Return
    }

    ; --------------------------------------------------------
    ; Move Spotify to smallest monitor
    ; --------------------------------------------------------

    WinMove, ahk_id %hWnd%, , %smallestLeft%, %smallestTop%, 300, 300

    Sleep, 300

    WinShow, ahk_id %hWnd%
Return