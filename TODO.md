# TODO

Pending features and future improvements for Windows-Sync.

## ✅ Completed (v2.8.2)
- [x] **Sync Engine:** Robust polling compatible with third-party apps.
- [x] **Group Logic:** Independent Min/Max/Restore synchronization.
- [x] **Rivals Logic:** Binary visibility switching with auto-correction.
- [x] **Responsive Interface:** Layout that adapts to resizing.
- [x] **Visual Identity:** Custom icons and Windows-Sync branding.
- [x] **Direct UX:** Assignment via row click and session memory.
- [x] **Stop Shortcuts:** Support for configurable Esc and Ctrl+Shift+Tab.
- [x] **Automation:** `compile.bat` script for easy executable generation.

## 🚀 Next Priorities (v2.9)
- [ ] **Disk Persistence:** Save group/process settings to an `.ini` file (to avoid reconfiguring when closing the program).
- [ ] **Tray Menu:** Add "Configure", "Pause", and "Exit" options directly to the clock icon.
- [ ] **Focus Synchronization:** Option to bring all group windows to the front when one is activated.

## ⚙️ Technical Improvements
- [ ] **Polling Adjustment:** Slider in the GUI to control frequency (100ms to 1000ms) for battery/CPU savings.
- [ ] **Debug Logging:** Optional log window to see why a specific window is not syncing.
- [ ] **Automatic Blacklist:** Prevent selection of system windows (Taskbar, Start Menu) to avoid Windows errors.

## 📄 Documentation and Testing
- [ ] Create demonstration GIFs of Groups vs Rivals features.
- [ ] Test stability with 100+ windows and multiple virtual desktops.
- [ ] Validate compatibility with UWP windows (Calculator, Photos).

## 📦 Distribution
- [ ] Create official repository and organize folders (`/bin`, `/src`, `/docs`).
- [ ] Generate basic installer that checks for AutoHotkey v2 presence.