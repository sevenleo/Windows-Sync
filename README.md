# Windows-Sync v1.0.1

## Description

A professional and robust **AutoHotkey v2** script to synchronize window states in Windows. Ideal for workflows that require keeping multiple application instances (such as browsers, terminals, or folders) in sync, or quickly switching between complementary windows.

The initial release of Windows-Sync provides a responsive interface, **native tray integration**, support for multiple independent groups, "rivals" logic, and a complete visual identity.

## Key Features

### Synchronization Core
- ✅ **Multi-Group Synchronization** - Create up to 5 independent groups. Windows in the same group synchronize Maximize, Minimize, and Restore actions.
- ✅ **Rivals Logic (Visibility Duel)** - Pairs of windows where one remains visible while the other automatically minimizes. Perfect for switching between documentation and code.
- ✅ **Intelligent Auto-Correction** - Rivals are forced into opposite states (one visible, one hidden) when starting synchronization.
- ✅ **Robust Synchronization (Polling)** - High-frequency monitoring (100ms) compatible with any application (Chrome, VSCode, Office, etc).
- ✅ **Session Memory** - The script remembers your assignments between activations, allowing quick adjustments without losing previous work.

### Interface and Usability (UX)
- ✅ **Tray Menu & Background Mode** - Control synchronization directly from the system tray. Use the new **"Minimize to Tray"** option to keep the app running silently in the background.
- ✅ **Responsive Layout** - Interface that adapts to resizing, with flexible columns.
- ✅ **Executable Identification** - View the process name (`chrome.exe`, `Code.exe`) to easily identify windows.
- ✅ **Direct Manipulation** - Click on any line in the list to open the instant assignment menu.
- ✅ **Customizable Stop Shortcuts** - Choose to use **ESC** and/or **Ctrl + Shift + Tab** to end synchronization and return to the menu.
- ✅ **Professional Identity** - Custom icons embedded in the executable.

## How to Use

### Requirements
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. For the compiled executable, no external files are needed.

### Workflow
1. **Assignment:** Click on the "Assignment" column of the desired windows and choose the corresponding Group or Rival.
2. **Options:** 
   - Check **"Minimize to Tray on Close"** to keep the app running in the background.
   - Configure stop shortcuts (**ESC**, **Ctrl+Shift+Tab**).
3. **Synchronize:** Click "Sync All" (or use "Toggle Sync" from the tray). The configuration window will be hidden and monitoring will begin.
4. **Stop:** Press the chosen shortcut or use the Tray Menu to stop monitoring.

## Architecture and Compilation

### File Structure
- `windows-sync.ahk`: Main source code.
- `compile.bat`: Automated script to generate the `.exe` executable.
- `icon.ico`: Official project icon (embedded during compilation).

### Generating the Executable
Double-click the `compile.bat` file. It will automatically detect your AutoHotkey v2 installation and generate the `Windows-Sync.exe` file with the embedded icon and professional metadata.

## Credits

- **Icon:** Sourced from [Icons8](https://icons8.com.br/icons/set/sync) (Usage License).

## License

MIT License - Free for personal and commercial use.
