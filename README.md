# Windows-Sync v1.6.0

## Description

A professional and robust **AutoHotkey v2** script to synchronize window states in Windows. Ideal for workflows that require keeping multiple application instances (such as browsers, terminals, or folders) in sync, or quickly switching between complementary windows.

Windows-Sync provides a responsive interface, **native tray integration**, support for multiple independent groups, rivals logic, and a complete visual identity.

## What's New in v1.6.0

- ✅ **Blacklist with Persistent Config** - Added `config.json` with blacklist support for process names and window titles.
- ✅ **Manage Blacklist UI** - New `Manage Blacklist` button in `Options` to list/add/remove blacklist terms.
- ✅ **Quick Blacklist from Window Row** - Right-click any listed window to add its process name or title directly to the blacklist.
- ✅ **Case-Insensitive Contains Matching** - Filtering is applied using substring matching (`contains_ci`) for process and title terms.

## Key Features

### Synchronization Core
- ✅ **Multi-Group Synchronization** - Create up to 5 independent groups. Windows in the same group always synchronize Minimize/Restore visibility state.
- ✅ **Optional Maximized State Sync (Groups + Rivals)** - Maximize/normal propagation can be enabled with `Sync Maximized State (Groups/Rivals)`.
- ✅ **Focus + Z-Order Sync (Groups)** - When focus enters a Group from outside, Windows-Sync applies group focus policy and keeps the clicked window as final focus target.
- ✅ **Safe Focus Policy** - Switching focus between windows in the same Group does not re-run full group focus sequencing.
- ✅ **External Window Priority Preserved** - Non-group windows can stay on top when you focus them; the script does not force continuous group refocus.
- ✅ **Restore-to-Target Focus** - If a Group is minimized and you click one Group window to restore visibility, focus returns to that originally clicked window at the end.
- ✅ **Rivals Logic (Visibility Duel)** - Pairs of windows where one remains visible while the other automatically minimizes; with maximized sync enabled, visible mode is also preserved.
- ✅ **Intelligent Auto-Correction** - Rivals are forced into opposite states (one visible, one hidden) when starting synchronization.
- ✅ **Robust Synchronization (Polling)** - High-frequency monitoring (100ms) compatible with any application (Chrome, VSCode, Office, etc).
- ✅ **Session Memory** - The script remembers your assignments between activations, allowing quick adjustments without losing previous work.

### Interface and Usability (UX)
- ✅ **Single-Instance Protection** - Prevents duplicate launches of the same file and reuses the active instance UI.
- ✅ **Tray Menu & Background Mode** - Control synchronization directly from the system tray. Use the new **"Minimize to Tray"** option to keep the app running silently in the background.
- ✅ **Sync Behavior Toggle in Options** - Enable or disable maximized-state synchronization at any time.
- ✅ **Blacklist Manager in Options** - Open a dedicated manager window to maintain blacklist entries.
- ✅ **Row Context Blacklist Actions** - Add process/title terms directly from any `Active Windows` row.
- ✅ **Responsive Layout** - Interface that adapts to resizing, with flexible columns.
- ✅ **Executable Identification** - View the process name (`chrome.exe`, `Code.exe`) to easily identify windows.
- ✅ **Direct Manipulation** - Click on any line in the list to open the instant assignment menu.
- ✅ **Customizable Return Shortcuts** - Choose to use **ESC** and/or **Ctrl + Shift + Tab** to bring the control window back during synchronization.
- ✅ **Professional Identity** - Custom icons embedded in the executable.

## How to Use

### Requirements
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Run `windows-sync.ahk` directly for manual testing and development.
3. For the compiled executable, no external files are needed.

### Workflow
1. **Assignment:** Click any row of the desired window and choose the corresponding Group or Rival.
2. **Options:** 
   - Check **"Minimize to Tray on Close"** to keep the app running in the background.
   - Enable **"Sync Maximized State (Groups/Rivals)"** if you also want normal/maximized state propagation.
   - Click **"Manage Blacklist"** to list, add, and remove blacklist terms.
   - Configure return shortcuts (**ESC**, **Ctrl+Shift+Tab**).
3. **Synchronize:** Click "Sync All" (or use "Toggle Sync" from the tray). Monitoring begins and the button changes to **Stop**.
4. **Review While Active:** You can keep the GUI open (or reopen via tray/shortcut) without cancelling synchronization.
5. **Stop:** Click **Stop** in the GUI or use the Tray Menu.
6. **Relaunch Behavior:** If you run the same `.ahk` or `.exe` again, Windows-Sync brings the existing instance window to front instead of opening a new one.
7. **Quick Blacklist:** Right-click a window row to add that row’s process name or title to blacklist.

## Configuration (`config.json`)

Windows-Sync now stores runtime settings in `config.json` at the script root (`A_ScriptDir`).

Current schema:

```json
{
  "schemaVersion": 1,
  "blacklist": {
    "matchMode": "contains_ci",
    "processTerms": [],
    "titleTerms": []
  }
}
```

- `processTerms`: hides rows when the executable name contains a term.
- `titleTerms`: hides rows when the window title contains a term.
- Matching is case-insensitive and applied immediately to `Active Windows`.

### Focus Behavior (Groups)
1. Focus policy is applied when focus changes from a non-group window to a Group window.
2. During policy application, the Group can be reordered for visibility, but final focus is forced back to the clicked Group window.
3. If focus stays inside the same Group (for example A -> B), policy is ignored to avoid unnecessary focus churn.
4. If you focus a non-group window, Windows-Sync does not continuously steal focus back.

## Architecture and Compilation

### File Structure
- `windows-sync.ahk`: Main source code.
- `compile.bat`: Automated script to generate the `.exe` executable.
- `icon.ico`: Official project icon (embedded during compilation).

### Generating the Executable
Double-click the `compile.bat` file. It will generate `Windows-Sync.exe` with embedded icon and metadata.

## Credits

- **Icon:** Sourced from [Icons8](https://icons8.com.br/icons/set/sync) (Usage License).

## License

MIT License - Free for personal and commercial use.
