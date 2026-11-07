import AppKit

// Cleanpasta lives in the menu bar. It shows a Dock icon only while its
// settings window (or an update window) is open.
let app = NSApplication.shared
LegacyDefaults.migrateIfNeeded() // before Preferences loads
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
