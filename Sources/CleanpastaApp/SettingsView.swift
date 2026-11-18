import AppKit
import ServiceManagement
import SwiftUI
import CleanpastaCore

/// The settings window. While it is open the app has a Dock icon; closing it puts the
/// app back into the menu bar only.
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let updater: Updater
    private let onboarding: () -> Void

    init(updater: Updater, onboarding: @escaping () -> Void) {
        self.updater = updater
        self.onboarding = onboarding
    }

    func show() {
        DockIcon.show("settings")
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView(updater: updater, onboarding: onboarding))
            hosting.sizingOptions = []
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            WindowChrome.apply(to: window, title: "Cleanpasta Settings")
            window.setContentSize(NSSize(width: 580, height: 700))
            window.contentMinSize = NSSize(width: 520, height: 420)
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            window.setFrameAutosaveName("SettingsWindow")
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        DockIcon.hide("settings")
    }
}

struct SettingsView: View {
    @ObservedObject private var preferences = Preferences.shared
    let updater: Updater
    let onboarding: () -> Void
    @State private var trusted = AXIsProcessTrusted()
    @State private var openAtLogin = LoginItem.isOn
    @State private var loginError: String?
    @State private var autoUpdates = false
    @State private var cliStatus = CommandLineTool.status()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var version: String {
        let info = Bundle.main.infoDictionary
        return info?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if !trusted { permissionCard }
                shortcuts
                formatting
                general
                updates
                footer
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Tokens.bg)
        .tint(Tokens.accent)
        .frame(minWidth: 520, minHeight: 420)
        .onAppear {
            autoUpdates = updater.automaticallyChecks
            cliStatus = CommandLineTool.status()
            openAtLogin = LoginItem.isOn
        }
        .onReceive(timer) { _ in
            trusted = AXIsProcessTrusted()
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Cleanpasta")
                    .textStyle(.title1)
                    .foregroundStyle(Tokens.text)
                    .accessibilityAddTraits(.isHeader)
                Text("Paste formatted text without backgrounds, colors and fonts. Bold, lists, links and line breaks stay.")
                    .textStyle(.body)
                    .foregroundStyle(Tokens.mutedOnFill)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var permissionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hand.raised")
                .font(.system(size: 17))
                .foregroundStyle(Tokens.ink)
                .frame(width: 36, height: 36)
                .background(Tokens.soft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text("One step left: allow Accessibility")
                    .textStyle(.bodyLarge, weight: .semibold)
                    .foregroundStyle(Tokens.text)
                Text("Cleanpasta presses Cmd+V for you, and macOS asks for your permission. Click the button, turn on Cleanpasta in the list and come back here. An older Cleanpasta in the list: remove it with the minus button first.")
                    .textStyle(.body)
                    .foregroundStyle(Tokens.mutedOnFill)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Allow Accessibility") { Permissions.requestAccessibility() }
                    .buttonStyle(.brandPrimary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var shortcuts: some View {
        SettingSection(title: "Shortcuts",
                       footer: "Click a field and press the keys. The x removes a shortcut; both commands always work from the menu bar icon.") {
            SettingRow(title: "Paste Clean", detail: "Cleans the clipboard and pastes it into the app you are in.") {
                ShortcutRow(shortcut: $preferences.pasteCleanShortcut)
            }
            SettingRow(title: "Repair Clipboard", detail: "Keeps the text and removes backgrounds, colors and fonts. Then paste with Cmd+V yourself.") {
                ShortcutRow(shortcut: $preferences.repairShortcut)
            }
            if preferences.shortcutConflict {
                StatusLine(ok: false, text: "Another app already uses one of these shortcuts. Pick a different one.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
    }

    private var formatting: some View {
        SettingSection(title: "Formatting") {
            SettingRow(title: "Replace em and en dashes", detail: "Long dashes become a plain hyphen \"-\".") {
                Toggle("Replace em and en dashes", isOn: $preferences.replaceDashes).toggleStyle(BrandSwitchStyle())
            }
            SettingRow(title: "Replace typographic quotes", detail: "Curly and angle quotes, and the curly apostrophe, become \" and '.") {
                Toggle("Replace typographic quotes", isOn: $preferences.replaceQuotes).toggleStyle(BrandSwitchStyle())
            }
            SettingRow(title: "Font size", detail: "Size of the pasted text. Without a size, Mail and Notes paste at 16 px.") {
                Picker("Font size", selection: $preferences.fontSize) {
                    ForEach(Preferences.fontSizes, id: \.value) { size in
                        Text(size.title).tag(size.value)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            }
        }
    }

    private var general: some View {
        SettingSection(title: "General") {
            SettingRow(title: "Open at login", detail: loginError ?? "The shortcut works right after the Mac starts.") {
                Toggle("Open at login", isOn: $openAtLogin)
                    .toggleStyle(BrandSwitchStyle())
                    .onChange(of: openAtLogin) { _, enabled in
                        loginError = LoginItem.set(enabled)
                        openAtLogin = LoginItem.isOn
                    }
            }
            SettingRow(title: "Show a confirmation", detail: "A short note on screen after Repair Clipboard.") {
                Toggle("Show a confirmation", isOn: $preferences.showFeedback).toggleStyle(BrandSwitchStyle())
            }
            SettingRow(title: "Command line tool",
                       detail: cliStatus.note ?? (cliStatus.installed ? cliStatus.path : "cleanpasta for Terminal, scripts and AI assistants. See cleanpasta --help.")) {
                if cliStatus.installed {
                    StatusLine(ok: true, text: "Installed")
                } else {
                    Button("Install") { cliStatus = CommandLineTool.install() }
                        .buttonStyle(.brandSecondary)
                }
            }
            SettingRow(title: "Accessibility", detail: "Lets Cleanpasta press Cmd+V for you.") {
                if trusted {
                    StatusLine(ok: true, text: "Allowed")
                } else {
                    Button("Open Settings") { Permissions.requestAccessibility() }
                        .buttonStyle(.brandSecondary)
                }
            }
            SettingRow(title: "Introduction", detail: "The short tour from the first launch.") {
                Button("Show") { onboarding() }
                    .buttonStyle(.brandSecondary)
            }
        }
    }

    private var updates: some View {
        SettingSection(title: "Updates") {
            SettingRow(title: "Check for updates automatically", detail: "Once a day. Updates install after you agree.") {
                Toggle("Check for updates automatically", isOn: $autoUpdates)
                    .toggleStyle(BrandSwitchStyle())
                    .onChange(of: autoUpdates) { _, value in updater.automaticallyChecks = value }
                    .disabled(!updater.isAvailable)
            }
            SettingRow(title: "Version \(version)") {
                Button("Check Now") { updater.checkForUpdates() }
                    .buttonStyle(.brandSecondary)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Circle().fill(Tokens.brand).frame(width: 6, height: 6).accessibilityHidden(true)
            Text(verbatim: "Eryk Sadowski")
            Spacer()
            Link("eryksadowski.com", destination: Links.website)
                .foregroundStyle(Tokens.ink)
        }
        .textStyle(.small)
        .foregroundStyle(Tokens.mutedOnFill)
        .padding(.horizontal, 4)
    }
}

/// Links Contents/Helpers/cleanpasta into ~/.local/bin, without an admin password (like Mowa).
enum CommandLineTool {
    struct Status {
        var installed: Bool
        var path: String
        var note: String?
    }

    static let addToPathCommand = "echo 'export PATH=\"$HOME/.local/bin:$PATH\"' >> ~/.zprofile"

    static var helper: URL { Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/cleanpasta") }

    private static var home: URL { FileManager.default.homeDirectoryForCurrentUser }

    static var targetFolder: URL { home.appendingPathComponent(".local/bin") }

    /// Where 1.1.x and earlier linked the command.
    static var previousFolders: [URL] { ["/opt/homebrew/bin", "/usr/local/bin"].map { URL(fileURLWithPath: $0) } }

    static var targetIsOnPath: Bool {
        CLIInstallation.isOnShellPath(targetFolder, home: home, environmentPath: ProcessInfo.processInfo.environment["PATH"] ?? "")
    }

    static func status() -> Status {
        let link = targetFolder.appendingPathComponent("cleanpasta")
        let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: link.path)
        let installed = destination == helper.path
        let note = installed && !targetIsOnPath ? "Installed. Add ~/.local/bin to your PATH: \(addToPathCommand)" : nil
        return Status(installed: installed, path: link.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"), note: note)
    }

    static func install() -> Status {
        let fm = FileManager.default
        guard fm.fileExists(atPath: helper.path) else {
            return Status(installed: false, path: "", note: "The command line tool is missing from this build.")
        }
        do {
            try CLIInstallation.install(helper: helper, folder: targetFolder)
        } catch {
            return Status(installed: false, path: "", note: "Could not install: \(error.localizedDescription)")
        }
        return status()
    }

    /// At every launch until it is done: a link from 1.1.x moves to ~/.local/bin (CLIInstallation.moveToLocalBin).
    static func moveToLocalBinIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "cliInLocalBin") else { return }
        do {
            let left = try CLIInstallation.moveToLocalBin(previousFolders: previousFolders, helper: helper, localBin: targetFolder, removeOld: targetIsOnPath)
            if left.isEmpty { defaults.set(true, forKey: "cliInLocalBin") }
        } catch {
            NSLog("Cleanpasta: command line link stays where it is for now: %@", error.localizedDescription)
        }
    }
}
