#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ==============================================================================
; COMPILATION DIRECTIVES (For Ahk2Exe)
; ==============================================================================
;@Ahk2Exe-SetName Windows-Sync
;@Ahk2Exe-SetDescription Windows-Sync
;@Ahk2Exe-SetVersion 1.3.0
;@Ahk2Exe-AddResource icon.ico, 160  ; Sets the main icon in the executable
;@Ahk2Exe-SetMainIcon icon.ico

; ==============================================================================
; ICON AND IDENTITY CONFIGURATION
; ==============================================================================
global ProjectName := "Windows-Sync"
global IconPath := A_ScriptDir . "\icon.ico"

; Sets the tray icon (near the clock)
if A_IsCompiled {
    ; When compiled, the executable *is* the icon resource (index 1 usually)
    try TraySetIcon(A_ScriptFullPath, 1)
} else if FileExist(IconPath) {
    TraySetIcon(IconPath)
} else {
    TraySetIcon("shell32.dll", 16) 
}

A_IconTip := ProjectName . " - Stopped"

; ==============================================================================
; CONFIGURATION AND STATE
; ==============================================================================
global SyncActive := false
global SyncInProgress := false
global SyncGroups := Map() 
global SyncRivals := Map() 
global SyncRivalVisibleMode := Map()
global PersistentAssignments := Map() 
global LastActiveHwnd := 0
global LastFocusPolicyGroupId := 0

global UseEsc := false
global UseTab := true
global UseMaximizedSync := false

global BtnGap := 10
global BtnRefreshW := 120
global BtnStartW := 150
global BtnExitW := 90

; ==============================================================================
; TRAY MENU CONFIGURATION
; ==============================================================================
ExitAllAndCloseApp(*) {
    global SyncActive, SyncInProgress, SyncGroups, SyncRivals, SyncRivalVisibleMode, PersistentAssignments
    global LastActiveHwnd, LastFocusPolicyGroupId, BtnStart

    SyncActive := false
    SyncInProgress := false
    SetTimer(MonitorAll, 0)

    SyncGroups.Clear()
    SyncRivals.Clear()
    SyncRivalVisibleMode.Clear()
    PersistentAssignments.Clear()
    LastActiveHwnd := 0
    LastFocusPolicyGroupId := 0

    try BtnStart.Text := "Sync All"
    try SetSyncUiLocked(false)
    try A_TrayMenu.Rename("Stop Sync", "Toggle Sync")
    A_IconTip := ProjectName . " - Stopped"

    ExitApp()
}

SetupTrayMenu() {
    Tray := A_TrayMenu
    Tray.Delete() ; Clear default menu
    
    Tray.Add("Configure", ShowGui)
    Tray.Add("Toggle Sync", ToggleSync)
    Tray.Add("Reload", (*) => Reload())
    Tray.Add() ; Separator
    Tray.Add("Exit", ExitAllAndCloseApp)

    Tray.Default := "Configure"
    Tray.ClickCount := 1 ; Single click to open config
}
SetupTrayMenu()

; ==============================================================================
; RESPONSIVE INTERFACE (v2.8.2)
; ==============================================================================
global MainGui := Gui("+Resize +MinSize600x750", ProjectName)
MainGui.OnEvent("Close", Gui_Close)
MainGui.OnEvent("Size", Gui_Size) 

; Fix for the window icon in AHK v2
try {
    if A_IsCompiled {
        ; Load from executable resource
        h_icon := LoadPicture(A_ScriptFullPath, "Icon1 w32 h32", &img_type)
    } else if FileExist(IconPath) {
        ; Load from file
        h_icon := LoadPicture(IconPath, "Icon1 w32 h32", &img_type)
    }
    
    if IsSet(h_icon) {
        SendMessage(0x0080, 0, h_icon, MainGui.Hwnd) ; WM_SETICON, ICON_SMALL
        SendMessage(0x0080, 1, h_icon, MainGui.Hwnd) ; WM_SETICON, ICON_BIG
    }
}

MainGui.SetFont("s10", "Segoe UI")

; Header
MainGui.SetFont("s12 w700")
global Header1 := MainGui.Add("Text", "xm y15 w580 Center", ProjectName)
MainGui.SetFont("s9 w400")
global Header2 := MainGui.Add("Text", "xm y+5 w580 Center cGray", "Define Groups or Rivals by clicking the 'Assignment' column.")

; List GroupBox
global GroupList := MainGui.Add("GroupBox", "xm y+20 w580 h300", "Active Windows")
global LV := MainGui.Add("ListView", "xp+10 yp+25 w560 h280 Grid -Multi", ["ID", "Assignment", "Executable", "Title"])
LV.ModifyCol(1, 0)   
LV.ModifyCol(2, 130) 
LV.ModifyCol(3, 120) 
LV.ModifyCol(4, 300) 
LV.OnEvent("Click", LV_Click)

; Shortcuts Section
global GroupShortcuts := MainGui.Add("GroupBox", "xm y+30 w580 h70", "Shortcuts")
global ChkEsc := MainGui.Add("Checkbox", "xp+20 yp+30 w100 h20", "Enable ESC")
ChkEsc.Value := UseEsc
global ChkTab := MainGui.Add("Checkbox", "x+20 yp w160 h20", "Enable Ctrl+Shift+Tab")
ChkTab.Value := UseTab

; Options Section
global GroupOptions := MainGui.Add("GroupBox", "xm y+10 w580 h95", "Options")
global ChkTray := MainGui.Add("Checkbox", "xp+20 yp+30 w220 h20", "Minimize to Tray on Close")
ChkTray.Value := true ; Default to Close = Minimize to Tray
global ChkSyncMaximized := MainGui.Add("Checkbox", "xp yp+25 w300 h20", "Sync Maximized State (Groups/Rivals)")
ChkSyncMaximized.Value := UseMaximizedSync
ChkSyncMaximized.OnEvent("Click", OnSyncMaximizedToggle)

; Actions Footer
btnTotalW := BtnRefreshW + BtnStartW + BtnExitW + (BtnGap * 2)
btnStartX := 20 + Floor((580 - btnTotalW) / 2)
global BtnRefresh := MainGui.Add("Button", "x" btnStartX " y+40 w" BtnRefreshW " h35", "Refresh List")
BtnRefresh.OnEvent("Click", (*) => UpdateList())

global BtnStart := MainGui.Add("Button", "x" (btnStartX + BtnRefreshW + BtnGap) " yp w" BtnStartW " h35 Default", "Sync All")
BtnStart.OnEvent("Click", ToggleSync)

global BtnExit := MainGui.Add("Button", "x" (btnStartX + BtnRefreshW + BtnGap + BtnStartW + BtnGap) " yp w" BtnExitW " h35", "Exit")
BtnExit.OnEvent("Click", ExitAllAndCloseApp)

global StatusBar := MainGui.Add("StatusBar")

; Assignment Menu
global AssignMenu := Menu()
AssignMenu.Add("None", SetAssignmentFromMenu)
AssignMenu.Add()
AssignMenu.Add("GROUPS", (*) => "")
AssignMenu.Disable("GROUPS")
Loop 5
    AssignMenu.Add("Group " A_Index, SetAssignmentFromMenu)
AssignMenu.Add()
AssignMenu.Add("RIVALS", (*) => "")
AssignMenu.Disable("RIVALS")
Loop 3
    AssignMenu.Add("Rival " A_Index, SetAssignmentFromMenu)

UpdateList()
MainGui.Show("w620 h750")

ShowGui(*) {
    global SyncActive, BtnStart, UseEsc, UseTab, UseMaximizedSync, ChkEsc, ChkTab, ChkSyncMaximized
    ChkEsc.Value := UseEsc
    ChkTab.Value := UseTab
    ChkSyncMaximized.Value := UseMaximizedSync
    if (SyncActive) {
        BtnStart.Text := "Stop"
        SetSyncUiLocked(true)
        try A_TrayMenu.Rename("Toggle Sync", "Stop Sync")
        A_IconTip := ProjectName . " - Active"
    } else {
        BtnStart.Text := "Sync All"
        SetSyncUiLocked(false)
        try A_TrayMenu.Rename("Stop Sync", "Toggle Sync")
        A_IconTip := ProjectName . " - Stopped"
    }
    MainGui.Show()
    UpdateList()
}

Gui_Close(*) {
    if (ChkTray.Value) {
        MainGui.Hide()
    } else {
        ExitAllAndCloseApp()
    }
}

; ==============================================================================
; RESPONSIVENESS LOGIC
; ==============================================================================

Gui_Size(thisGui, WindowState, Width, Height) {
    if (WindowState == -1) 
        return

    m := 20
    w := Width - (m * 2)

    ; Vertical stack from bottom to top to keep spacing stable:
    ; Actions -> Options -> Shortcuts -> Active Windows
    yActions := Height - 90
    yOptions := yActions - 105
    yShortcuts := yOptions - 80
     
    Header1.Move(m, , w)
    Header2.Move(m, , w)

    GroupList.GetPos(, &groupTop)
    groupHeight := yShortcuts - 10 - groupTop
    if (groupHeight < 170)
        groupHeight := 170
    GroupList.Move(m, , w, groupHeight)

    lvHeight := groupHeight - 45
    if (lvHeight < 120)
        lvHeight := 120
    LV.Move(m + 10, , w - 20, lvHeight)
    LV.ModifyCol(4, w - 20 - 130 - 120 - 30) 

    GroupShortcuts.Move(m, yShortcuts, w, 70)
    ChkEsc.Move(m + 20, yShortcuts + 30)
    ChkTab.Move(m + 130, yShortcuts + 30)

    GroupOptions.Move(m, yOptions, w, 95)
    ChkTray.Move(m + 20, yOptions + 30)
    ChkSyncMaximized.Move(m + 20, yOptions + 55)

    totalButtonsW := BtnRefreshW + BtnStartW + BtnExitW + (BtnGap * 2)
    buttonsStartX := m + Floor((w - totalButtonsW) / 2)
    if (buttonsStartX < m)
        buttonsStartX := m

    BtnRefresh.Move(buttonsStartX, yActions, BtnRefreshW)
    BtnStart.Move(buttonsStartX + BtnRefreshW + BtnGap, yActions, BtnStartW)
    BtnExit.Move(buttonsStartX + BtnRefreshW + BtnGap + BtnStartW + BtnGap, yActions, BtnExitW)
    
    WinRedraw(thisGui)
}

; ==============================================================================
; INTERFACE LOGIC
; ==============================================================================

UpdateList() {
    LV.Delete()
    detectHidden := A_DetectHiddenWindows
    DetectHiddenWindows(false)
    
    for hwnd in WinGetList() {
        title := WinGetTitle(hwnd)
        if (title == "" || title == "Program Manager" || hwnd == MainGui.Hwnd)
            continue
        
        style := WinGetStyle(hwnd)
        if !(style & 0x10000000) 
            continue
            
        class := WinGetClass(hwnd)
        if (class == "Shell_TrayWnd" || class == "WorkerW" || class == "Progman")
            continue

        try {
            exeName := WinGetProcessName(hwnd)
        } catch {
            exeName := "unknown"
        }

        assign := PersistentAssignments.Has(hwnd) ? PersistentAssignments[hwnd] : "---"
        LV.Add("", hwnd, assign, exeName, title)
    }
    DetectHiddenWindows(detectHidden)
    StatusBar.SetText("List updated.")
}

LV_Click(LV, RowNumber) {
    global SyncActive
    if (SyncActive || RowNumber == 0)
        return
    AssignMenu.Show()
}

SetSyncUiLocked(isLocked) {
    ; Keep Active Windows list enabled so user can scroll and review assignments during sync.
    ; Group/Rival assignment is blocked by LV_Click when SyncActive is true.
    LV.Opt("-Disabled")
    BtnRefresh.Opt("-Disabled")
    ChkEsc.Enabled := true
    ChkTab.Enabled := true
    ChkTray.Enabled := true
    ChkSyncMaximized.Enabled := true
}

SetAssignmentFromMenu(ItemName, ItemPos, MyMenu) {
    row := LV.GetNext(0)
    if (!row)
        return
    hwnd := Integer(LV.GetText(row, 1))
    val := (ItemName == "None") ? "---" : ItemName
    
    if InStr(ItemName, "Rival") {
        count := 0
        Loop LV.GetCount() {
            if (LV.GetText(A_Index, 2) == ItemName && A_Index != row)
                count++
        }
        if (count >= 2) {
            MsgBox("Maximum of 2 windows per Rival pair.", "Warning", "Icon!")
            return
        }
    }
    
    LV.Modify(row, , , val) 
    PersistentAssignments[hwnd] := val
}

; ==============================================================================
; SYNCHRONIZATION LOGIC
; ==============================================================================

GetTrackedStateFromRaw(raw) {
    global UseMaximizedSync
    if (raw == -1)
        return -1
    return UseMaximizedSync ? raw : 0
}

GetGroupTrackedState(hwnd) {
    if !WinExist(hwnd)
        return -1
    raw := WinGetMinMax(hwnd)
    return GetTrackedStateFromRaw(raw)
}

ApplyGroupStateToWindow(hwnd, trackedState) {
    global UseMaximizedSync
    if !WinExist(hwnd)
        return

    currRaw := WinGetMinMax(hwnd)
    currTracked := GetTrackedStateFromRaw(currRaw)
    if (currTracked == trackedState)
        return

    if (trackedState == -1) {
        WinMinimize(hwnd)
        return
    }

    if (UseMaximizedSync) {
        if (trackedState == 1)
            WinMaximize(hwnd)
        else
            WinRestore(hwnd)
        return
    }

    ; With maximized sync disabled, only un-minimize hidden windows.
    if (currRaw == -1)
        WinRestore(hwnd)
}

GetVisibleModeFromRaw(raw) {
    return (raw == 1) ? 1 : 0
}

UpdateRivalVisibleMode(rid, windows) {
    global UseMaximizedSync, SyncRivalVisibleMode
    if (!UseMaximizedSync) {
        if (SyncRivalVisibleMode.Has(rid))
            SyncRivalVisibleMode.Delete(rid)
        return
    }

    visibleFound := false
    for hwnd, _ in windows {
        if !WinExist(hwnd)
            continue
        raw := WinGetMinMax(hwnd)
        if (raw == -1)
            continue
        SyncRivalVisibleMode[rid] := GetVisibleModeFromRaw(raw)
        visibleFound := true
        break
    }

    if (!visibleFound && !SyncRivalVisibleMode.Has(rid))
        SyncRivalVisibleMode[rid] := 0
}

RebaselineGroupSnapshots() {
    global SyncGroups
    for groupId, windows in SyncGroups {
        for hwnd, _ in windows {
            if !WinExist(hwnd) {
                windows.Delete(hwnd)
                continue
            }
            try windows[hwnd] := GetGroupTrackedState(hwnd)
        }
    }
}

RebaselineRivalSnapshots() {
    global SyncRivals
    for rid, windows in SyncRivals {
        for hwnd, _ in windows {
            if !WinExist(hwnd) {
                windows.Delete(hwnd)
                continue
            }
            try windows[hwnd] := (WinGetMinMax(hwnd) == -1) ? -1 : 1
        }
    }
}

GetGroupReferenceHwnd(windows) {
    activeHwnd := 0
    try activeHwnd := WinGetID("A")
    if (activeHwnd && windows.Has(activeHwnd) && WinExist(activeHwnd))
        return activeHwnd

    firstVisible := 0
    firstExisting := 0
    for hwnd, _ in windows {
        if !WinExist(hwnd)
            continue
        if (!firstExisting)
            firstExisting := hwnd
        raw := WinGetMinMax(hwnd)
        if (raw != -1) {
            firstVisible := hwnd
            break
        }
    }

    if (firstVisible)
        return firstVisible
    return firstExisting
}

ApplyGroupReferencePolicy(windows) {
    referenceHwnd := GetGroupReferenceHwnd(windows)
    if (!referenceHwnd || !WinExist(referenceHwnd))
        return

    referenceState := GetGroupTrackedState(referenceHwnd)
    for hwnd, _ in windows {
        if !WinExist(hwnd) {
            windows.Delete(hwnd)
            continue
        }
        windows[hwnd] := referenceState
        if (hwnd == referenceHwnd)
            continue
        try ApplyGroupStateToWindow(hwnd, referenceState)
    }
}

ApplyRuntimeMaximizedSyncPolicy() {
    global SyncActive, SyncInProgress, SyncGroups, SyncRivals, SyncRivalVisibleMode
    global UseMaximizedSync, LastActiveHwnd, LastFocusPolicyGroupId

    if (!SyncActive)
        return

    if (SyncInProgress) {
        SetTimer(ApplyRuntimeMaximizedSyncPolicy, -30)
        return
    }

    SyncInProgress := true
    try {
        if (UseMaximizedSync) {
            for groupId, windows in SyncGroups
                ApplyGroupReferencePolicy(windows)
        }

        RebaselineGroupSnapshots()
        RebaselineRivalSnapshots()

        SyncRivalVisibleMode.Clear()
        if (UseMaximizedSync) {
            for rid, windows in SyncRivals
                UpdateRivalVisibleMode(rid, windows)
        }

        LastActiveHwnd := 0
        LastFocusPolicyGroupId := 0
    } finally {
        SyncInProgress := false
    }
}

OnSyncMaximizedToggle(*) {
    global ChkSyncMaximized, UseMaximizedSync, SyncActive
    newValue := !!ChkSyncMaximized.Value
    if (UseMaximizedSync == newValue)
        return

    UseMaximizedSync := newValue
    if (!SyncActive)
        return

    ApplyRuntimeMaximizedSyncPolicy()
}

ToggleSync(*) {
    global SyncActive, SyncGroups, SyncRivals, SyncRivalVisibleMode, StatusBar, BtnStart, PersistentAssignments
    global UseEsc, UseTab, UseMaximizedSync, ChkSyncMaximized, LastActiveHwnd, LastFocusPolicyGroupId
    if (SyncActive) {
        StopSync()
        return
    }
    UseEsc := ChkEsc.Value
    UseTab := ChkTab.Value
    UseMaximizedSync := !!ChkSyncMaximized.Value
    SyncGroups.Clear()
    SyncRivals.Clear()
    SyncRivalVisibleMode.Clear()
    Loop LV.GetCount() {
        hwndText := LV.GetText(A_Index, 1)
        if (hwndText == "")
            continue
        hwnd := Integer(hwndText)
        assignText := LV.GetText(A_Index, 2)
        PersistentAssignments[hwnd] := assignText
        if (assignText == "---")
            continue
        if RegExMatch(assignText, "(\w+) (\d+)", &match) {
            aType := match[1]
            id := Integer(match[2])
            if (aType == "Group") {
                if !SyncGroups.Has(id)
                    SyncGroups[id] := Map()
                if WinExist(hwnd)
                    SyncGroups[id][hwnd] := GetGroupTrackedState(hwnd)
            } else if (aType == "Rival") {
                if !SyncRivals.Has(id)
                    SyncRivals[id] := Map()
                if WinExist(hwnd)
                    SyncRivals[id][hwnd] := (WinGetMinMax(hwnd) == -1) ? -1 : 1
            }
        }
    }
    if (SyncGroups.Count == 0 && SyncRivals.Count == 0) {
        MsgBox("Select windows to synchronize.", "Warning", "Icon!")
        return
    }
    for rid, windows in SyncRivals {
        if (windows.Count == 2) {
            hwnds := []
            for h in windows
                hwnds.Push(h)
            h1 := hwnds[1], h2 := hwnds[2]
            s1 := (WinGetMinMax(h1) == -1) ? -1 : 1
            s2 := (WinGetMinMax(h2) == -1) ? -1 : 1
            if (s1 == s2) {
                target := (Random(0, 1) == 0) ? h1 : h2
                if (s1 == 1)
                    WinMinimize(target)
                else
                    WinRestore(target)
                Sleep(150)
            }
            windows[h1] := (WinGetMinMax(h1) == -1) ? -1 : 1
            windows[h2] := (WinGetMinMax(h2) == -1) ? -1 : 1
            if (UseMaximizedSync)
                UpdateRivalVisibleMode(rid, windows)
        }
    }
    SyncActive := true
    LastActiveHwnd := 0
    LastFocusPolicyGroupId := 0
    SetSyncUiLocked(true)
    BtnStart.Text := "Stop"
    A_IconTip := ProjectName . " - Active"
    try A_TrayMenu.Rename("Toggle Sync", "Stop Sync")
    if (!UseEsc && !UseTab)
        MsgBox("Warning: No stop shortcuts active. Use Tray Icon to stop.", "Warning", "Iconi")
    SetTimer(MonitorAll, 100)
}

StopSync() {
    global SyncActive, SyncRivalVisibleMode, StatusBar, BtnStart, MainGui, LastActiveHwnd, LastFocusPolicyGroupId
    SyncActive := false
    LastActiveHwnd := 0
    LastFocusPolicyGroupId := 0
    SyncRivalVisibleMode.Clear()
    SetSyncUiLocked(false)
    SetTimer(MonitorAll, 0)
    BtnStart.Text := "Sync All"
    A_IconTip := ProjectName . " - Stopped"
    try A_TrayMenu.Rename("Stop Sync", "Toggle Sync")
    MainGui.Show()
    UpdateList()
}

GetGroupIdByHwnd(hwnd) {
    global SyncGroups
    if (!hwnd)
        return 0
    for groupId, windows in SyncGroups {
        if (windows.Has(hwnd))
            return groupId
    }
    return 0
}

ActivateWindowAndWait(hwnd, attempts := 3, waitSeconds := 0.10, sleepMs := 25) {
    if (!WinExist(hwnd))
        return false

    Loop attempts {
        try WinActivate(hwnd)
        try WinWaitActive("ahk_id " hwnd, , waitSeconds)

        curr := 0
        try curr := WinGetID("A")
        if (curr == hwnd)
            return true

        Sleep(sleepMs)
    }
    return false
}

SyncGroupFocusAndZOrder(groupId, activeHwnd) {
    global SyncGroups
    if (!groupId || !SyncGroups.Has(groupId) || !WinExist(activeHwnd))
        return

    windows := SyncGroups[groupId]
    if (windows.Count == 0)
        return

    groupHwnds := []
    for hwnd, _ in windows {
        if !WinExist(hwnd) {
            windows.Delete(hwnd)
            continue
        }
        try {
            curr := WinGetMinMax(hwnd)
            windows[hwnd] := GetTrackedStateFromRaw(curr)
            if (curr == -1)
                continue
            groupHwnds.Push(hwnd)
        }
    }

    if (groupHwnds.Length == 0)
        return

    IsFocusOutsideGroup := false
    for _, hwnd in groupHwnds {
        try {
            currActive := WinGetID("A")
            if (currActive && currActive != activeHwnd) {
                currGroupId := GetGroupIdByHwnd(currActive)
                if (currGroupId != groupId) {
                    IsFocusOutsideGroup := true
                    break
                }
            }
        }
        if (IsFocusOutsideGroup)
            break
    }
    if (IsFocusOutsideGroup)
        return

    ; Focuses all other windows in the group first and guarantees the clicked window as final focus target.
    focusSequence := []
    for _, hwnd in groupHwnds {
        if (hwnd == activeHwnd || !WinExist(hwnd))
            continue
        focusSequence.Push(hwnd)
    }

    for _, hwnd in focusSequence {
        try {
            currActive := WinGetID("A")
            if (currActive && currActive != activeHwnd) {
                currGroupId := GetGroupIdByHwnd(currActive)
                if (currGroupId != groupId)
                    return
            }

            ActivateWindowAndWait(hwnd, 2, 0.08, 20)
        }
    }

    currActive := 0
    try currActive := WinGetID("A")
    if (currActive && currActive != activeHwnd) {
        currGroupId := GetGroupIdByHwnd(currActive)
        if (currGroupId != groupId)
            return
    }

    if WinExist(activeHwnd)
        ActivateWindowAndWait(activeHwnd, 6, 0.12, 30)

    for hwnd, _ in windows {
        if !WinExist(hwnd) {
            windows.Delete(hwnd)
            continue
        }
        try windows[hwnd] := GetGroupTrackedState(hwnd)
    }
}

MonitorAll() {
    global SyncInProgress, SyncGroups, SyncRivals, SyncRivalVisibleMode, SyncActive, UseMaximizedSync
    global LastActiveHwnd, LastFocusPolicyGroupId
    if (SyncInProgress || !SyncActive)
        return
    SyncInProgress := true
    changedGroups := Map()
    focusRequests := Map()

    for groupId, windows in SyncGroups {
        leader := 0, newState := 0
        for hwnd, last in windows {
            if !WinExist(hwnd) {
                windows.Delete(hwnd)
                continue
            }
            curr := GetGroupTrackedState(hwnd)
            if (curr != last) {
                leader := hwnd, newState := curr
                break
            }
        }
        if (leader) {
            changedGroups[groupId] := true
            for hwnd, _ in windows {
                windows[hwnd] := newState
                if (hwnd == leader)
                    continue
                try ApplyGroupStateToWindow(hwnd, newState)
            }

            ; Preserve original leader focus target when group becomes visible again.
            if (newState != -1)
                focusRequests[groupId] := leader
        }
    }

    for rid, windows in SyncRivals {
        leader := 0, leaderNorm := 0
        hwnds := []
        for h in windows
            hwnds.Push(h)
        if (hwnds.Length != 2)
            continue
        if (UseMaximizedSync)
            UpdateRivalVisibleMode(rid, windows)
        for h in hwnds {
            if !WinExist(h)
                continue
            curr := WinGetMinMax(h), currNorm := (curr == -1) ? -1 : 1
            if (currNorm != windows[h]) {
                leader := h, leaderNorm := currNorm
                break
            }
        }
        if (leader) {
            follower := (leader == hwnds[1]) ? hwnds[2] : hwnds[1]
            if (WinExist(follower)) {
                if (leaderNorm == 1) {
                    if (WinGetMinMax(follower) != -1)
                        WinMinimize(follower)
                    followerNorm := -1
                } else {
                    if (WinGetMinMax(follower) == -1)
                        WinRestore(follower)
                    if (UseMaximizedSync) {
                        visibleMode := SyncRivalVisibleMode.Has(rid) ? SyncRivalVisibleMode[rid] : 0
                        if (visibleMode == 1) {
                            if (WinGetMinMax(follower) != 1)
                                WinMaximize(follower)
                        } else {
                            if (WinGetMinMax(follower) == 1)
                                WinRestore(follower)
                        }
                    }
                    followerNorm := 1
                }
                windows[leader] := leaderNorm
                windows[follower] := followerNorm
                if (UseMaximizedSync)
                    UpdateRivalVisibleMode(rid, windows)
                Sleep(50)
            }
        }
    }

    ; Apply focus requests generated by state transitions using the original leader as final target.
    for groupId, targetHwnd in focusRequests {
        if (!WinExist(targetHwnd))
            continue
        SyncGroupFocusAndZOrder(groupId, targetHwnd)
        LastFocusPolicyGroupId := groupId
        newActive := 0
        try newActive := WinGetID("A")
        LastActiveHwnd := newActive ? newActive : targetHwnd
    }

    activeHwnd := 0
    try activeHwnd := WinGetID("A")
    if (activeHwnd != LastActiveHwnd) {
        currGroupId := GetGroupIdByHwnd(activeHwnd)

        ; Focus is outside any group: reset focus policy tracking.
        if (!currGroupId) {
            LastFocusPolicyGroupId := 0
            LastActiveHwnd := activeHwnd

        ; Focus moved inside a group that already had focus policy applied: ignore.
        } else if (currGroupId == LastFocusPolicyGroupId) {
            LastActiveHwnd := activeHwnd

        ; If state sync happened in this group, defer focus policy to next stable cycle.
        } else if (changedGroups.Has(currGroupId)) {
            LastActiveHwnd := activeHwnd

        } else {
            SyncGroupFocusAndZOrder(currGroupId, activeHwnd)
            newActive := 0
            try newActive := WinGetID("A")
            LastActiveHwnd := newActive ? newActive : activeHwnd
            LastFocusPolicyGroupId := currGroupId
        }
    }

    SyncInProgress := false
}

#HotIf SyncActive
~Esc:: {
    if (UseEsc)
        ShowGui()
}
^+Tab:: {
    if (UseTab)
        ShowGui()
}
#HotIf
