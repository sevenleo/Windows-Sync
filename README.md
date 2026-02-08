# Windows-Sync v2.8.2

## Description

A professional and robust **AutoHotkey v2** script to synchronize window states in Windows. Ideal for workflows that require keeping multiple application instances (such as browsers, terminals, or folders) in sync, or quickly switching between complementary windows.

Now with a responsive interface, support for multiple independent groups, "rivals" logic, and a complete visual identity.

## Key Features

### Synchronization Core
- ✅ **Multi-Group Synchronization** - Create up to 5 independent groups. Windows in the same group synchronize Maximize, Minimize, and Restore actions.
- ✅ **Rivals Logic (Visibility Duel)** - Pairs of windows where one remains visible while the other automatically minimizes. Perfect for switching between documentation and code.
- ✅ **Intelligent Auto-Correction** - Rivals are forced into opposite states (one visible, one hidden) when starting synchronization.
- ✅ **Robust Synchronization (Polling)** - High-frequency monitoring (100ms) compatible with any application (Chrome, VSCode, Office, etc).
- ✅ **Session Memory** - The script remembers your assignments between activations, allowing quick adjustments without losing previous work.

### Interface and Usability (UX)
- ✅ **Responsive Layout** - Interface that adapts to resizing, with flexible columns.
- ✅ **Executable Identification** - View the process name (`chrome.exe`, `Code.exe`) to easily identify windows.
- ✅ **Direct Manipulation** - Click on any line in the list to open the instant assignment menu.
- ✅ **Customizable Stop Shortcuts** - Choose to use **ESC** and/or **Ctrl + Shift + Tab** to end synchronization and return to the menu.
- ✅ **Professional Identity** - Custom icons in the tray and window, unified title as "Windows-Sync".

## How to Use

### Requirements
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. (Optional) Keep `icon.ico` in the same folder for the complete visual identity.

### Workflow
1. **Assignment:** Click on the "Assignment" column of the desired windows and choose the corresponding Group or Rival.
2. **Shortcuts:** Check the boxes for the shortcuts you want to use to stop synchronization.
3. **Synchronize:** Click "Sync All". The configuration window will be hidden and monitoring will begin.
4. **Stop:** Press the chosen shortcut (**ESC** or **Ctrl+Shift+Tab**) to stop monitoring and return to the configuration menu.

## Architecture and Compilation

### File Structure
- `windows-sync.ahk`: Main source code.
- `compile.bat`: Automated script to generate the `.exe` executable.
- `icon.ico`: Official project icon.

### Generating the Executable
Double-click the `compile.bat` file. It will automatically detect your AutoHotkey v2 installation and generate the `Windows-Sync.exe` file with the embedded icon and professional metadata.

## License

MIT License - Free for personal and commercial use.