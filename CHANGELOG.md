# CHANGELOG

## v1.4.0

### Improvements
- **Optional Maximized-State Sync (Groups + Rivals):** Added new `Sync Maximized State (Groups/Rivals)` checkbox in the `Options` section.
- **Default Behavior Change:** Maximized synchronization now starts **disabled by default**; visibility/minimized synchronization remains active.
- **Immediate Runtime Apply:** Toggling maximized sync while synchronization is running now applies immediately without restarting `Sync All`.
- **Rivals Visible-Mode Preservation:** With maximized sync enabled, Rival windows restore using the last visible mode (normal or maximized).
- **Options Layout Update:** `Options` section now supports the extra checkbox while preserving responsive spacing.

## v1.3.0

### Improvements
- **State-Preserving Return (Tray/Shortcut):** Reopening the GUI while sync is active now preserves the running state instead of resetting it.
- **Keyboard Return Shortcuts:** `ESC` and `Ctrl+Shift+Tab` (when enabled) now reopen the control window during sync rather than stopping synchronization.
- **Visible Sync Control:** Starting sync keeps the GUI visible and switches `Sync All` to `Stop`.
- **Selective Lock During Sync:** Group/Rival assignment remains blocked while review controls stay usable.
- **Default UX Update:** `ESC` starts disabled by default; `Minimize to Tray on Close` starts enabled.
- **Layout Refinement:** GUI vertical layout updated to avoid overlap between `Active Windows`, `Shortcuts`, and `Options`.

## v1.1.0

### Fixes
- **Group Z-Order Priority Bug:** Fixed case where only the clicked Group window came to front while other visible Group windows stayed behind non-group windows.
- **External Focus Lock Bug:** Fixed issue where group focus logic could prevent non-group windows from staying focused/on top.
- **Restore Focus Target Bug:** Fixed issue where focus could land on another group window instead of the originally clicked window after restore.

### Improvements
- **Focus + Z-Order Sync (Groups):** Focus policy now runs when focus enters a Group from outside and preserves the clicked window as final focus target.
- **Safe Focus Policy:** Switching between windows inside the same Group no longer re-triggers full group focus sequencing.
- **Focus Conflict Guard:** Focus policy is deferred when state synchronization is happening in the same Group.
- **Reliable Focus Finalization:** Added activation/wait retry strategy to improve focus consistency across applications.

## v1.0.1 (Initial Release)

### Features
- **Window Synchronization:** Synchronize maximize, minimize, and restore actions across multiple windows
- **Group Management:** Create up to 5 independent groups for window synchronization
- **Rivals Logic:** Implement binary visibility switching with auto-correction between paired windows
- **Tray Integration:** Native tray menu with "Configure", "Toggle Sync", and "Exit" options
- **Background Mode:** Option to minimize to tray and keep the app running silently
- **Responsive Interface:** Layout that adapts to resizing with flexible columns
- **Direct Manipulation:** Click on any line in the list to open the instant assignment menu
- **Session Memory:** Remembers window assignments between activations
- **Robust Polling:** High-frequency monitoring (100ms) compatible with any application
- **Customizable Shortcuts:** Choose to use ESC and/or Ctrl+Shift+Tab to end synchronization
