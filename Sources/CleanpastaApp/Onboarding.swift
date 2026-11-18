import AppKit
import ServiceManagement
import SwiftUI
import CleanpastaCore

/// The introduction, as in Mowa: a first screen from Eryk, then a few short screens to the first
/// clean paste, and a last screen that says what works. Shown at the first launch; again from
/// Settings > General. Everything can be changed later in Settings.
enum OnboardingStep: Int, CaseIterable {
    case hello, what, permission, shortcut, tryIt, done
}

final class OnboardingFlow: ObservableObject {
    @Published var step: OnboardingStep = .hello
    var close: () -> Void = {}

    func next() {
        guard let following = OnboardingStep(rawValue: step.rawValue + 1) else { return close() }
        step = following
    }

    func back() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = previous
    }
}

/// The introduction window: AppKit, so it shows at launch without a SwiftUI scene.
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    static let size = NSSize(width: 568, height: 760)
    private var window: NSWindow?

    func show() {
        DockIcon.show("onboarding")
        if window == nil {
            let flow = OnboardingFlow()
            flow.close = { [weak self] in self?.window?.close() }
            let hosting = NSHostingController(rootView: OnboardingView(flow: flow))
            hosting.sizingOptions = []
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable, .miniaturizable]
            WindowChrome.apply(to: window, title: "Welcome to Cleanpasta")
            window.setContentSize(Self.size)
            window.isRestorable = false
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        DockIcon.hide("onboarding")
    }
}

/// Start at login through `SMAppService`, shared by the introduction and Settings.
enum LoginItem {
    static var isOn: Bool { SMAppService.mainApp.status == .enabled }

    /// Returns why it could not be changed, or nil.
    static func set(_ enabled: Bool) -> String? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return "Could not change it: \(error.localizedDescription)"
        }
    }
}

struct OnboardingView: View {
    @ObservedObject var flow: OnboardingFlow

    var body: some View {
        VStack(spacing: 0) {
            if flow.step != .hello { progress }
            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .id(flow.step)
            footer
        }
        .background(Tokens.surface)
        .tint(Tokens.accent)
        .frame(minWidth: OnboardingWindowController.size.width, minHeight: OnboardingWindowController.size.height)
    }

    @ViewBuilder
    private var content: some View {
        switch flow.step {
        case .hello: HelloStep()
        case .what: WhatStep()
        case .permission: PermissionStep()
        case .shortcut: ShortcutStep()
        case .tryIt: TryStep()
        case .done: DoneStep()
        }
    }

    /// Capsules for the steps after the first screen: the current one long and green.
    private var progress: some View {
        let steps = OnboardingStep.allCases.dropFirst()
        return HStack(spacing: 6) {
            ForEach(Array(steps), id: \.rawValue) { step in
                Capsule()
                    .fill(step == flow.step ? Tokens.accent : Tokens.controlBorder)
                    .frame(width: step == flow.step ? 32 : 14, height: 4)
            }
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(flow.step.rawValue) of \(steps.count)")
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if flow.step == .hello {
                Button("Skip") { flow.close() }
                    .buttonStyle(.brandGhost)
            } else {
                Button("Back") { flow.back() }
                    .buttonStyle(.brandGhost)
            }
            Spacer()
            Button(primaryTitle) { flow.next() }
                .buttonStyle(.brandPrimaryLarge)
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Tokens.surface)
        .overlay(alignment: .top) { Rectangle().fill(Tokens.border).frame(height: 1) }
    }

    private var primaryTitle: String {
        switch flow.step {
        case .hello: return "Show me"
        case .done: return "Done"
        default: return "Continue"
        }
    }
}

// MARK: - Steps

private struct HelloStep: View {
    var body: some View {
        VStack(spacing: 0) {
            ErykPhotoView()
                .padding(.top, 8)
            Text("Hi, it's Eryk")
                .textStyle(.title1)
                .foregroundStyle(Tokens.text)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 24)
            Text("I made Cleanpasta so that what you copy pastes clean: no backgrounds, no colors, no stray fonts. Give me 30 seconds and I'll show you how to use it.")
                .textStyle(.bodyLarge)
                .foregroundStyle(Tokens.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 420)
                .padding(.top, 12)
            VStack(spacing: 2) {
                Text(verbatim: "Eryk Sadowski")
                    .textStyle(.bodyLarge, weight: .semibold)
                    .foregroundStyle(Tokens.text)
                Text("Maker of Cleanpasta")
                    .textStyle(.body)
                    .foregroundStyle(Tokens.mutedOnFill)
            }
            .accessibilityElement(children: .combine)
            .padding(.top, 20)
            Label("Your clipboard never leaves this Mac.", systemImage: "lock")
                .textStyle(.body)
                .foregroundStyle(Tokens.mutedOnFill)
                .padding(.top, 24)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WhatStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepHeading(symbol: "doc.on.clipboard", title: "What Cleanpasta does",
                        text: "Text copied from a website, a chat or an AI assistant brings its look along. Cleanpasta keeps the content and drops the look, so it fits wherever you paste it.")
            HStack(alignment: .top, spacing: 12) {
                list(title: "Stays", symbol: "checkmark", color: Tokens.ink,
                     items: ["Bold and italics", "Lists and links", "Line breaks"])
                list(title: "Goes", symbol: "xmark", color: Tokens.mutedOnFill,
                     items: ["Backgrounds", "Colors", "Fonts and sizes"])
            }
            VStack(alignment: .leading, spacing: 8) {
                Label("Markdown becomes formatted text.", systemImage: "text.badge.checkmark")
                Label("Long dashes and curly quotes become the keyboard's - and \" '.", systemImage: "character.cursor.ibeam")
            }
            .textStyle(.body)
            .foregroundStyle(Tokens.text)
        }
    }

    private func list(title: String, symbol: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .textStyle(.small, weight: .medium)
                .foregroundStyle(Tokens.mutedOnFill)
            ForEach(items, id: \.self) { item in
                Label {
                    Text(item).textStyle(.body).foregroundStyle(Tokens.text)
                } icon: {
                    Image(systemName: symbol).font(.system(size: 12, weight: .semibold)).foregroundStyle(color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .card()
    }
}

private struct PermissionStep: View {
    @State private var trusted = AXIsProcessTrusted()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepHeading(symbol: "hand.raised", title: "Let Cleanpasta paste for you",
                        text: "Cleanpasta presses Cmd+V for you, and macOS asks you to allow it once in Privacy & Security > Accessibility.")
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility")
                            .textStyle(.body, weight: .medium)
                            .foregroundStyle(Tokens.text)
                        Text(trusted ? "Allowed. Cleanpasta can paste." : "Turn on Cleanpasta in the list, then come back here.")
                            .textStyle(.small)
                            .foregroundStyle(Tokens.mutedOnFill)
                    }
                    Spacer()
                    if trusted {
                        StatusLine(ok: true, text: "Allowed")
                    } else {
                        Button("Open Accessibility") { Permissions.requestAccessibility() }
                            .buttonStyle(.brandPrimary)
                    }
                }
            }
            .padding(16)
            .card()
            if !trusted {
                Text("Updating from an older Cleanpasta? If it is already in the list, select it, remove it with the minus button and turn on the new one.")
                    .textStyle(.small)
                    .foregroundStyle(Tokens.mutedOnFill)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Without it, Cleanpasta still cleans the clipboard; you press Cmd+V yourself.")
                .textStyle(.small)
                .foregroundStyle(Tokens.mutedOnFill)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onReceive(timer) { _ in trusted = AXIsProcessTrusted() }
    }
}

private struct ShortcutStep: View {
    @ObservedObject private var preferences = Preferences.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepHeading(symbol: "keyboard", title: "One shortcut, in any app",
                        text: "Copy as usual, then press the shortcut instead of Cmd+V: Cleanpasta cleans the text and pastes it. To change it, click the field and press the keys.")
            VStack(spacing: 0) {
                SettingRow(title: "Paste Clean", detail: "Cleans the clipboard and pastes it.") {
                    ShortcutRow(shortcut: $preferences.pasteCleanShortcut)
                }
                Rectangle().fill(Tokens.border).frame(height: 1)
                SettingRow(title: "Repair Clipboard", detail: "Cleans the clipboard only; you paste with Cmd+V.") {
                    ShortcutRow(shortcut: $preferences.repairShortcut)
                }
            }
            .card()
            if preferences.shortcutConflict {
                StatusLine(ok: false, text: "Another app already uses this shortcut. Pick a different one.")
            }
            Text("Both commands are also in the Cleanpasta menu in the menu bar.")
                .textStyle(.small)
                .foregroundStyle(Tokens.mutedOnFill)
        }
    }
}

private struct TryStep: View {
    @ObservedObject private var preferences = Preferences.shared
    @State private var pasted = PasteResult.empty
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepHeading(symbol: "text.cursor", title: "Try it",
                        text: "Copy a sample with a yellow background and a large font, click in the field below and press \(preferences.pasteCleanShortcut?.display ?? "Paste Clean in the menu bar").")
            HStack(spacing: 12) {
                Button(copied ? "Copied" : "Copy the sample") {
                    Sample.copy()
                    copied = true
                }
                .buttonStyle(.brandSecondary)
                if copied {
                    Text("Now click in the field and paste clean.")
                        .textStyle(.small)
                        .foregroundStyle(Tokens.mutedOnFill)
                }
            }
            RichTextField(result: $pasted)
                .frame(height: 180)
                .overlay(alignment: .topLeading) {
                    if pasted == .empty {
                        Text("Paste here")
                            .textStyle(.body)
                            .foregroundStyle(Tokens.muted)
                            .padding(.horizontal, 17)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                .card()
            switch pasted {
            case .empty: EmptyView()
            case .clean: StatusLine(ok: true, text: "It works: the text stayed, the look is gone.")
            case .styled: StatusLine(ok: false, text: "That was a plain paste: the yellow stayed. Clear the field and use the shortcut.")
            }
        }
    }
}

private struct DoneStep: View {
    @ObservedObject private var preferences = Preferences.shared
    @State private var trusted = AXIsProcessTrusted()
    @State private var openAtLogin = LoginItem.isOn
    @State private var loginError: String?
    @State private var cli = CommandLineTool.status()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepHeading(symbol: "checkmark", title: "All set", text: "This is how Cleanpasta works for you now:")
            VStack(spacing: 0) {
                row(ok: trusted, text: trusted ? "Pastes for you (Accessibility allowed)" : "Cleans the clipboard; you paste with Cmd+V") {
                    if !trusted {
                        Button("Allow") { Permissions.requestAccessibility() }.buttonStyle(.brandSecondarySmall)
                    }
                }
                Rectangle().fill(Tokens.border).frame(height: 1)
                row(ok: preferences.pasteCleanShortcut != nil,
                    text: preferences.pasteCleanShortcut.map { "Paste Clean with \($0.display)" } ?? "Paste Clean from the menu bar") { EmptyView() }
                Rectangle().fill(Tokens.border).frame(height: 1)
                row(ok: cli.installed, text: cli.installed ? "cleanpasta command in Terminal" : "cleanpasta command for Terminal and AI assistants") {
                    if !cli.installed {
                        Button("Install") { cli = CommandLineTool.install() }.buttonStyle(.brandSecondarySmall)
                    }
                }
            }
            .card()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open Cleanpasta when the Mac starts")
                        .textStyle(.body, weight: .medium)
                        .foregroundStyle(Tokens.text)
                    Text(loginError ?? "Then the shortcut works right after the Mac starts.")
                        .textStyle(.small)
                        .foregroundStyle(loginError == nil ? Tokens.mutedOnFill : Tokens.warn)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("Open Cleanpasta when the Mac starts", isOn: $openAtLogin)
                    .toggleStyle(BrandSwitchStyle())
                    .onChange(of: openAtLogin) { _, enabled in
                        loginError = LoginItem.set(enabled)
                        openAtLogin = LoginItem.isOn
                    }
            }
            .padding(.horizontal, 16)
            Label("Cleanpasta lives in the menu bar at the top of the screen, next to the clock.", systemImage: "menubar.arrow.up.rectangle")
                .textStyle(.body)
                .foregroundStyle(Tokens.mutedOnFill)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear {
            trusted = AXIsProcessTrusted()
            cli = CommandLineTool.status()
        }
    }

    private func row<Fix: View>(ok: Bool, text: String, @ViewBuilder fix: () -> Fix) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ok ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ok ? Tokens.ink : Tokens.mutedOnFill)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(text)
                .textStyle(.body)
                .foregroundStyle(Tokens.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            fix()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Try it

/// A sample with the look Cleanpasta removes: a background, a color and a large font.
enum Sample {
    static let html = """
    <div style="background:#FEF3C7;color:#7C2D12;font-family:Georgia,serif;font-size:20px">\
    <p>Hi Anna,</p><p>the plan for <b>Thursday</b>:</p>\
    <ul><li>call at 10:00</li><li>notes in <a href="https://eryksadowski.com">the shared document</a></li></ul>\
    <p>See you &mdash; Eryk</p></div>
    """

    static let text = "Hi Anna,\n\nthe plan for Thursday:\n\n- call at 10:00\n- notes in the shared document\n\nSee you \u{2014} Eryk"

    static func copy() {
        Clipboard.write(html: html, text: text)
    }
}

/// What the field holds: nothing, text without the sample's look, or text that kept it.
enum PasteResult {
    case empty, clean, styled

    init(_ storage: NSAttributedString) {
        guard !storage.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self = .empty
            return
        }
        var styled = false
        storage.enumerateAttributes(in: NSRange(location: 0, length: storage.length)) { attributes, _, stop in
            let background = attributes[.backgroundColor] != nil
            let serif = (attributes[.font] as? NSFont)?.familyName == "Georgia"
            if background || serif {
                styled = true
                stop.pointee = true
            }
        }
        self = styled ? .styled : .clean
    }
}

/// A rich text field that shows what a paste looks like.
struct RichTextField: NSViewRepresentable {
    @Binding var result: PasteResult

    func makeCoordinator() -> Coordinator { Coordinator(result: $result) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        if let view = scroll.documentView as? NSTextView {
            view.isRichText = true
            view.importsGraphics = false
            view.allowsUndo = true
            view.drawsBackground = false
            // Pasted text has no color of its own: black would vanish on the dark card.
            view.usesAdaptiveColorMappingForDarkAppearance = true
            view.font = .systemFont(ofSize: 13)
            view.textContainerInset = NSSize(width: 12, height: 12)
            view.delegate = context.coordinator
            view.setAccessibilityLabel("Paste here")
        }
        return scroll
    }

    func updateNSView(_ view: NSScrollView, context: Context) {}

    final class Coordinator: NSObject, NSTextViewDelegate {
        var result: Binding<PasteResult>

        init(result: Binding<PasteResult>) { self.result = result }

        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView, let storage = view.textStorage else { return }
            result.wrappedValue = PasteResult(storage)
        }
    }
}
