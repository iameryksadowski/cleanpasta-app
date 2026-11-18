import AppKit
import SwiftUI

/// "About Cleanpasta": the tool, the author and the version, in one window.
final class AboutWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let updater: Updater

    init(updater: Updater) {
        self.updater = updater
    }

    func show() {
        DockIcon.show("about")
        if window == nil {
            let hosting = NSHostingController(rootView: AboutView(updater: updater))
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable]
            WindowChrome.apply(to: window, title: "About Cleanpasta")
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        DockIcon.hide("about")
    }
}

enum Links {
    static let website = URL(string: "https://eryksadowski.com")!
    static let repository = URL(string: "https://github.com/iameryksadowski/cleanpasta-app")!
    static let releases = URL(string: "https://github.com/iameryksadowski/cleanpasta-app/releases")!
    static let license = URL(string: "https://github.com/iameryksadowski/cleanpasta-app/blob/main/LICENSE")!
    static let email = URL(string: "mailto:iam@eryksadowski.com?subject=Cleanpasta")!
}

/// The same as Mowa's "About Mowa": the icon, the name, the version, the author.
struct AboutView: View {
    let updater: Updater

    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev" }
    private var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-" }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "Cleanpasta")
                    .textStyle(.title3)
                    .foregroundStyle(Tokens.text)
                Text("Version \(version) (\(build))")
                    .textStyle(.small)
                    .foregroundStyle(Tokens.muted)
                    .textSelection(.enabled)
                Button("Check for Updates") { updater.checkForUpdates() }
                    .buttonStyle(.brandSecondarySmall)
                    .padding(.vertical, 4)
                Text("Paste formatted text without backgrounds, colors and fonts. Bold, lists, links and line breaks stay; Markdown becomes formatted text; dashes and quotes become keyboard characters.")
                    .textStyle(.small)
                    .foregroundStyle(Tokens.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 14) {
                    Link("Source code", destination: Links.repository)
                    Link("Changelog", destination: Links.releases)
                    Link("License", destination: Links.license)
                    Link("eryksadowski.com", destination: Links.website)
                }
                .textStyle(.small, weight: .medium)
                .foregroundStyle(Tokens.ink)
                .padding(.top, 4)
                Text(verbatim: "\u{00A9} 2026 Eryk Sadowski")
                    .textStyle(.small)
                    .foregroundStyle(Tokens.muted)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .frame(width: 480)
        .background(Tokens.surface)
        .tint(Tokens.accent)
    }
}
