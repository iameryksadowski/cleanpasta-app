import AppKit
import ServiceManagement
import Combine
import SwiftUI
import CleanpastaCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let preferences = Preferences.shared
    private var subscriptions = Set<AnyCancellable>()
    private var appearanceObservation: NSKeyValueObservation?
    let updater = Updater()
    lazy var settings = SettingsWindowController(updater: updater) { [weak self] in self?.showOnboarding() }
    lazy var onboarding = OnboardingWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        BrandFont.register()
        CommandLineTool.moveToLocalBinIfNeeded()
        NSApp.mainMenu = MainMenu.build(target: self)
        AppIcon.apply()
        appearanceObservation = NSApp.observe(\.effectiveAppearance) { _, _ in
            DispatchQueue.main.async { AppIcon.apply() }
        }
        setUpStatusItem()
        registerHotKeys()
        preferences.$pasteCleanShortcut.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.registerHotKeys() }
        }.store(in: &subscriptions)
        preferences.$repairShortcut.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.registerHotKeys() }
        }.store(in: &subscriptions)
        updater.start()
        let trusted = Clipboard.canPaste
        if preferences.isFirstLaunch {
            preferences.isFirstLaunch = false
            onboarding.show()
        } else if !trusted && UserDefaults.standard.bool(forKey: "accessibilityWasAllowed") {
            // macOS drops the permission when an update changes the app's signature:
            // show the one-click way back instead of failing silently.
            settings.show()
        }
        if trusted {
            UserDefaults.standard.set(true, forKey: "accessibilityWasAllowed")
        }
        // remember the permission once it is given while the app runs
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            if Clipboard.canPaste {
                UserDefaults.standard.set(true, forKey: "accessibilityWasAllowed")
                timer.invalidate()
            }
        }
    }

    /// Opening the app again (Finder, Spotlight, a launcher) shows the settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settings.show()
        return false
    }

    // MARK: - Hotkeys

    private func registerHotKeys() {
        let pasteOK = HotKeys.shared.register(.pasteClean, shortcut: preferences.pasteCleanShortcut) { [weak self] in
            self?.pasteClean(delay: 0)
        }
        let repairOK = HotKeys.shared.register(.repairClipboard, shortcut: preferences.repairShortcut) { [weak self] in
            self?.repairClipboard()
        }
        preferences.shortcutConflict = !(pasteOK && repairOK)
    }

    // MARK: - Actions

    /// Clean the clipboard and paste it into the frontmost app.
    @objc func pasteCleanFromMenu() {
        // let the menu close and the previous app become frontmost again
        pasteClean(delay: 0.25)
    }

    func pasteClean(delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            let content = Clipboard.read()
            if content.hasText, let result = Converter.shared.clean(.content(html: content.html, text: content.text), options: preferences.cleanOptions) {
                Clipboard.write(html: result.html, text: result.text)
            }
            // Nothing to clean (an image, a file): paste it as it is.
            Clipboard.pasteIntoFrontmostApp { pasted in
                if !pasted {
                    HUD.show(
                        title: "Clean text copied - press Cmd+V",
                        detail: "Allow Cleanpasta in Accessibility to paste automatically.",
                        symbol: "exclamationmark.triangle"
                    )
                }
            }
        }
    }

    /// Clean the clipboard in place: the text stays, backgrounds, colors and fonts go.
    @objc func repairClipboard() {
        let content = Clipboard.read()
        guard content.hasText, let result = Converter.shared.clean(.content(html: content.html, text: content.text), options: preferences.cleanOptions) else {
            HUD.show(title: "Nothing to repair", detail: "The clipboard has no text.", symbol: "doc.on.clipboard")
            return
        }
        Clipboard.write(html: result.html, text: result.text)
        if preferences.showFeedback {
            HUD.show(title: "Clipboard repaired", detail: "Paste with Cmd+V anywhere.", symbol: "checkmark.circle")
        }
    }

    @objc func openSettings() { settings.show() }

    func showOnboarding() { onboarding.show() }

    @objc func checkForUpdates() { updater.checkForUpdates() }

    lazy var about = AboutWindowController(updater: updater)

    /// The tool, the author and the version, in one window.
    @objc func showAbout() { about.show() }

    static var versionTitle: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        return "Cleanpasta \(version)"
    }

    @objc func allowAccessibility() { Permissions.requestAccessibility() }

    // MARK: - Status item

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = NSImage(named: "MenuBarIcon") ?? NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Cleanpasta") {
            image.isTemplate = true
            item.button?.image = image
        }
        item.button?.toolTip = "Cleanpasta"
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        // One icon in the menu bar; the menu below it holds the commands, under a header as in Mowa.
        let header = NSMenuItem()
        header.view = MenuHeader.view(status: menuStatus)
        menu.addItem(header)
        menu.addItem(.separator())
        let paste = NSMenuItem(title: "Paste Clean", action: #selector(pasteCleanFromMenu), keyEquivalent: "")
        apply(preferences.pasteCleanShortcut, to: paste)
        paste.toolTip = "Clean the clipboard and paste it into the active app."
        menu.addItem(paste)
        let repair = NSMenuItem(title: "Repair Clipboard", action: #selector(repairClipboard), keyEquivalent: "")
        apply(preferences.repairShortcut, to: repair)
        repair.toolTip = "Keep the text, drop backgrounds, colors and fonts; then paste with Cmd+V."
        menu.addItem(repair)
        if !Clipboard.canPaste {
            menu.addItem(.separator())
            let allow = NSMenuItem(title: "Allow Accessibility to Paste Automatically...", action: #selector(allowAccessibility), keyEquivalent: "")
            allow.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: nil)
            menu.addItem(allow)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "About Cleanpasta", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Cleanpasta", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        // the installed version, so an update is visible at a glance
        let version = NSMenuItem(title: AppDelegate.versionTitle, action: nil, keyEquivalent: "")
        version.isEnabled = false
        menu.addItem(version)
        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) && item.action != nil {
            item.target = self
        }
    }

    /// The line under the name in the menu: what the shortcut does now.
    private var menuStatus: String {
        guard Clipboard.canPaste else { return "Allow Accessibility to paste for you" }
        guard let shortcut = preferences.pasteCleanShortcut else { return "Ready" }
        return "Ready - \(shortcut.display) pastes clean"
    }

    private func apply(_ shortcut: Shortcut?, to item: NSMenuItem) {
        guard let shortcut, !shortcut.menuKey.isEmpty else { return }
        item.keyEquivalent = shortcut.menuKey
        item.keyEquivalentModifierMask = shortcut.flags
    }
}

enum Permissions {
    static let accessibilityURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!

    /// Shows the system prompt (adds Cleanpasta to the list) and opens the settings pane.
    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            NSWorkspace.shared.open(accessibilityURL)
        }
    }
}

/// The menu bar menu while a window is open (the app is in the Dock then).
enum MainMenu {
    static func build(target: AppDelegate) -> NSMenu {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Cleanpasta", action: #selector(AppDelegate.showAbout), keyEquivalent: "").target = target
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Settings...", action: #selector(AppDelegate.openSettings), keyEquivalent: ",").target = target
        appMenu.addItem(withTitle: "Check for Updates...", action: #selector(AppDelegate.checkForUpdates), keyEquivalent: "").target = target
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Cleanpasta", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit Cleanpasta", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        main.addItem(editItem)

        let windowItem = NSMenuItem()
        let window = NSMenu(title: "Window")
        window.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        window.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowItem.submenu = window
        main.addItem(windowItem)
        return main
    }
}

/// Light icon by default (the bundle's AppIcon.icns); the dark variant while macOS is in dark mode.
enum AppIcon {
    static func apply() {
        let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if dark, let url = Bundle.main.url(forResource: "AppIcon-dark", withExtension: "png"), let image = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = image
        } else {
            NSApp.applicationIconImage = nil // back to the bundle icon
        }
    }
}

/// The Dock icon is shown only while a window needs it: the settings or an update.
enum DockIcon {
    private static var reasons = Set<String>()

    static func show(_ reason: String) {
        reasons.insert(reason)
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    static func hide(_ reason: String) {
        reasons.remove(reason)
        if reasons.isEmpty {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

/// The top of the menu bar menu, as in Mowa: the icon, the name and a status line.
enum MenuHeader {
    static func view(status: String) -> NSView {
        let hosting = NSHostingView(rootView: Content(status: status))
        hosting.frame = NSRect(origin: .zero, size: hosting.fittingSize)
        return hosting
    }

    private struct Content: View {
        let status: String

        var body: some View {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: "Cleanpasta")
                        .font(BrandFont.font(13, weight: .semibold))
                    Text(status)
                        .font(BrandFont.font(11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .frame(minWidth: 260, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}
