#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ==============================================================================
; COMPILATION DIRECTIVES (For Ahk2Exe)
; ==============================================================================
;@Ahk2Exe-SetName Windows-Sync
;@Ahk2Exe-SetDescription Windows-Sync
;@Ahk2Exe-SetVersion 1.0.1
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
global PersistentAssignments := Map() 
global LastActiveHwnd := 0
global LastFocusPolicyGroupId := 0

global UseEsc := true
global UseTab := true

; ==============================================================================
; TRAY MENU CONFIGURATION
; ==============================================================================
SetupTrayMenu() {
    Tray := A_TrayMenu
    Tray.Delete() ; Clear default menu
    
    Tray.Add("Configure", ShowGui)
    Tray.Add("Toggle Sync", ToggleSync)
    Tray.Add("Reload", (*) => Reload())
    Tray.Add() ; Separator
    Tray.Add("Exit", (*) => ExitApp())

    Tray.Default := "Configure"
    Tray.ClickCount := 1 ; Single click to open config
}
SetupTrayMenu()

; ==============================================================================
; RESPONSIVE INTERFACE (v2.8.2)
; ==============================================================================
global MainGui := Gui("+AlwaysOnTop +Resize +MinSize600x650", ProjectName)
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
global GroupShortcuts := MainGui.Add("GroupBox", "xm y+30 w580 h70", "Options")
global ChkEsc := MainGui.Add("Checkbox", "xp+20 yp+30 w100 h20", "Enable ESC")
ChkEsc.Value := UseEsc
global ChkTab := MainGui.Add("Checkbox", "x+20 yp w160 h20", "Enable Ctrl+Shift+Tab")
ChkTab.Value := UseTab
global ChkTray := MainGui.Add("Checkbox", "x+20 yp w180 h20", "Minimize to Tray on Close")
ChkTray.Value := false ; Default to Close = Exit

; Actions Footer
global BtnRefresh := MainGui.Add("Button", "xm+180 y+40 w120 h35", "Refresh List")
BtnRefresh.OnEvent("Click", (*) => UpdateList())

global BtnStart := MainGui.Add("Button", "x+10 yp w150 h35 Default", "Sync All")
BtnStart.OnEvent("Click", ToggleSync)

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
MainGui.Show("w620 h650")

ShowGui(*) {
    MainGui.Show()
    UpdateList()
}

Gui_Close(*) {
    if (ChkTray.Value) {
        MainGui.Hide()
    } else {
        ExitApp()
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
    
    Header1.Move(m, , w)
    Header2.Move(m, , w)
    GroupList.Move(m, , w, Height - 280)
    LV.Move(m + 10, , w - 20, Height - 325)
    LV.ModifyCol(4, w - 20 - 130 - 120 - 30) 

    yPos := Height - 180
    GroupShortcuts.Move(m, yPos, w, 70)
    ChkEsc.Move(m + 20, yPos + 30)
    ChkTab.Move(m + 130, yPos + 30)
    ChkTray.Move(m + 300, yPos + 30)
    
    yActions := Height - 90
    BtnRefresh.Move(m + 180, yActions)
    BtnStart.Move(m + 310, yActions)
    
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
    if (RowNumber == 0)
        return
    AssignMenu.Show()
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

ToggleSync(*) {
    global SyncActive, SyncGroups, SyncRivals, StatusBar, BtnStart, PersistentAssignments, UseEsc, UseTab, LastActiveHwnd, LastFocusPolicyGroupId
    if (SyncActive) {
        StopSync()
        return
    }
    UseEsc := ChkEsc.Value
    UseTab := ChkTab.Value
    SyncGroups.Clear()
    SyncRivals.Clear()
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
                    SyncGroups[id][hwnd] := WinGetMinMax(hwnd)
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
        }
    }
    SyncActive := true
    LastActiveHwnd := 0
    LastFocusPolicyGroupId := 0
    BtnStart.Text := "Stop"
    A_IconTip := ProjectName . " - Active"
    try A_TrayMenu.Rename("Toggle Sync", "Stop Sync")
    MainGui.Hide()
    if (!UseEsc && !UseTab)
        MsgBox("Warning: No stop shortcuts active. Use Tray Icon to stop.", "Warning", "Iconi")
    SetTimer(MonitorAll, 100)
}

StopSync() {
    global SyncActive, StatusBar, BtnStart, MainGui, LastActiveHwnd, LastFocusPolicyGroupId
    SyncActive := false
    LastActiveHwnd := 0
    LastFocusPolicyGroupId := 0
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
            windows[hwnd] := curr
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
        try windows[hwnd] := WinGetMinMax(hwnd)
    }
}

MonitorAll() {
    global SyncInProgress, SyncGroups, SyncRivals, SyncActive, LastActiveHwnd, LastFocusPolicyGroupId
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
            curr := WinGetMinMax(hwnd)
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
                try {
                    if (WinGetMinMax(hwnd) == newState)
                        continue
                    switch newState {
                        case -1: WinMinimize(hwnd)
                        case 1:  WinMaximize(hwnd)
                        case 0:  WinRestore(hwnd)
                    }
                }
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
                    followerNorm := 1
                }
                windows[leader] := leaderNorm
                windows[follower] := followerNorm
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
        StopSync()
}
^+Tab:: {
    if (UseTab)
        StopSync()
}
#HotIf
