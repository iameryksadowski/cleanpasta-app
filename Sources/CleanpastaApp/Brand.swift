import AppKit
import CoreText
import SwiftUI

/// Design tokens of Eryk Sadowski's apps, the same values as Mowa's `Brand.swift`. Each color
/// resolves for the current appearance, "Increase contrast" included.
enum Tokens {
    struct Pair {
        let light: UInt32
        let dark: UInt32
        var lightHigh: UInt32?
        var darkHigh: UInt32?

        init(_ light: UInt32, _ dark: UInt32, high lightHigh: UInt32? = nil, _ darkHigh: UInt32? = nil) {
            self.light = light
            self.dark = dark
            self.lightHigh = lightHigh
            self.darkHigh = darkHigh
        }

        var ns: NSColor {
            NSColor(name: nil) { appearance in
                let match = appearance.bestMatch(from: [.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua])
                switch match {
                case .darkAqua: return NSColor(hex: dark)
                case .accessibilityHighContrastAqua: return NSColor(hex: lightHigh ?? light)
                case .accessibilityHighContrastDarkAqua: return NSColor(hex: darkHigh ?? dark)
                default: return NSColor(hex: light)
                }
            }
        }

        var color: Color { Color(nsColor: ns) }

        /// The color at a share of itself: hover and pressed fills.
        func mix(_ light: Double, _ dark: Double) -> Color {
            let pair = self
            return Color(nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                return NSColor(hex: isDark ? pair.dark : pair.light).withAlphaComponent(isDark ? dark : light)
            })
        }
    }

    static let bgPair = Pair(0xFAFAFA, 0x0A0A0A)
    static let surfacePair = Pair(0xFFFFFF, 0x18181B)
    static let surface2Pair = Pair(0xF4F4F5, 0x27272A)
    static let borderPair = Pair(0xE4E4E7, 0x303036, high: 0x71717A, 0xA1A1AA)
    static let textPair = Pair(0x171717, 0xFAFAFA, high: 0x000000, 0xFFFFFF)
    static let mutedPair = Pair(0x71717A, 0xA1A1AA, high: 0x3F3F46, 0xD4D4D8)
    static let mutedOnFillPair = Pair(0x66666F, 0xA1A1AA, high: 0x3F3F46, 0xD4D4D8)
    static let accentPair = Pair(0x059669, 0x34D399, high: 0x047857, 0x6EE7B7)
    static let inkPair = Pair(0x047857, 0x6EE7B7, high: 0x065F46, 0xA7F3D0)
    static let softPair = Pair(0xECFDF5, 0x022C1E)
    static let onSoftPair = Pair(0x065F46, 0xA7F3D0)
    static let warnPair = Pair(0xB45309, 0xFBBF24, high: 0x92400E, 0xFCD34D)
    static let btnPair = Pair(0x171717, 0xFAFAFA, high: 0x000000, 0xFFFFFF)
    static let btnHoverPair = Pair(0x2E2E2E, 0xE4E4E7)
    static let onBtnPair = Pair(0xFFFFFF, 0x0A0A0A, high: 0xFFFFFF, 0x000000)
    static let controlBorderPair = Pair(0xD4D4D8, 0x3F3F46, high: 0x71717A, 0xA1A1AA)
    static let windowBarPair = Pair(0xF4F4F5, 0x1F1F23)

    static let bg = bgPair.color
    static let surface = surfacePair.color
    static let surface2 = surface2Pair.color
    static let border = borderPair.color
    static let text = textPair.color
    static let muted = mutedPair.color
    static let mutedOnFill = mutedOnFillPair.color
    static let accent = accentPair.color
    static let ink = inkPair.color
    static let soft = softPair.color
    static let onSoft = onSoftPair.color
    static let warn = warnPair.color
    static let btn = btnPair.color
    static let btnHover = btnHoverPair.color
    static let onBtn = onBtnPair.color
    static let controlBorder = controlBorderPair.color
    static let hover = textPair.mix(0.06, 0.08)
    static let pressed = textPair.mix(0.10, 0.12)
    static let warnTint = warnPair.mix(0.12, 0.16)

    /// Brand green of the mark: the icon and small dots, never text.
    static let brand = Color(hex: 0x10B981)
}

/// Spacing and radii of the brand book.
enum Metrics {
    static let radiusSm: CGFloat = 6
    static let radiusMd: CGFloat = 8
    static let radiusLg: CGFloat = 12
    static let radiusXl: CGFloat = 16
    static let controlSmall: CGFloat = 24
    static let control: CGFloat = 28
    static let controlLarge: CGFloat = 36
}

/// Type scale of the brand book, set in Geist.
enum TypeStyle {
    case caption, small, body, bodyLarge, title3, title2, title1

    var size: CGFloat {
        switch self {
        case .caption: return 11
        case .small: return 12
        case .body: return 13
        case .bodyLarge: return 15
        case .title3: return 17
        case .title2: return 20
        case .title1: return 24
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .caption: return 14
        case .small: return 16
        case .body: return 18
        case .bodyLarge, .title3: return 22
        case .title2: return 26
        case .title1: return 30
        }
    }

    /// In em.
    var tracking: CGFloat {
        switch self {
        case .caption: return 0.01
        case .small, .body, .bodyLarge: return 0
        case .title3: return -0.01
        case .title2: return -0.015
        case .title1: return -0.02
        }
    }

    var isHeading: Bool { self == .title3 || self == .title2 || self == .title1 }
}

/// Geist from the app's resources (SIL Open Font License, `Resources/Fonts/OFL.txt`), the system
/// font when it is missing.
enum BrandFont {
    static func register() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        for url in urls {
            // Already available (installed on the Mac): fine.
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .semibold, .bold, .heavy, .black: name = "Geist-SemiBold"
        case .medium: name = "Geist-Medium"
        default: name = "Geist-Regular"
        }
        guard NSFont(name: name, size: size) != nil else { return .system(size: size, weight: weight) }
        return .custom(name, fixedSize: size)
    }
}

extension View {
    /// Text in a style of the brand scale: Geist, its size, tracking and line height.
    func textStyle(_ style: TypeStyle, weight: Font.Weight? = nil) -> some View {
        let resolved = weight ?? (style.isHeading ? .semibold : (style == .caption ? .medium : .regular))
        return font(BrandFont.font(style.size, weight: resolved))
            .tracking(style.size * style.tracking)
            // Geist's natural line is about 1.3 em; only a taller line can be asked for.
            .lineSpacing(max(0, style.lineHeight - style.size * 1.3))
    }

    /// A card of the brand: surface, hairline border, 12 pt corners.
    func card() -> some View {
        background(Tokens.surface, in: RoundedRectangle(cornerRadius: Metrics.radiusLg, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: Metrics.radiusLg, style: .continuous).strokeBorder(Tokens.border, lineWidth: 1) }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

// MARK: - Buttons

/// Buttons of the brand (Mowa's `MowaButtonStyle`): they draw their own fill, so the main action
/// keeps its contrast whether or not the window is active.
struct BrandButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, ghost }
    enum Size { case small, regular, large }

    var kind: Kind = .secondary
    var size: Size = .regular

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, kind: kind, size: size)
    }

    private struct Face: View {
        let configuration: Configuration
        let kind: Kind
        let size: Size
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.colorSchemeContrast) private var contrast
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var isHovered = false

        private var isPressed: Bool { isEnabled && configuration.isPressed }
        private var isHot: Bool { isEnabled && isHovered }

        var body: some View {
            configuration.label
                .lineLimit(1)
                .font(BrandFont.font(fontSize, weight: .medium))
                .foregroundStyle(textColor)
                .padding(.horizontal, horizontalPadding)
                .frame(minHeight: height)
                .background(fill, in: RoundedRectangle(cornerRadius: Metrics.radiusMd))
                .background(base, in: RoundedRectangle(cornerRadius: Metrics.radiusMd))
                .overlay {
                    RoundedRectangle(cornerRadius: Metrics.radiusMd)
                        .strokeBorder(borderColor, lineWidth: contrast == .increased ? 1.5 : 1)
                }
                .scaleEffect(isPressed && !reduceMotion ? 0.98 : 1)
                .contentShape(RoundedRectangle(cornerRadius: Metrics.radiusMd))
                .onHover { isHovered = $0 && isEnabled }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isHovered)
        }

        private var fontSize: CGFloat { size == .small ? 12 : (size == .large ? 14 : 13) }
        private var horizontalPadding: CGFloat { size == .small ? 8 : (size == .large ? 16 : 12) }
        private var height: CGFloat { size == .small ? Metrics.controlSmall : (size == .large ? Metrics.controlLarge : Metrics.control) }

        private var textColor: Color {
            guard isEnabled else { return kind == .primary ? Tokens.mutedOnFill : Tokens.muted }
            return kind == .primary ? Tokens.onBtn : Tokens.text
        }

        private var fill: Color {
            switch kind {
            case .primary:
                guard isEnabled else { return Tokens.surface2 }
                return isHot || isPressed ? Tokens.btnHover : Tokens.btn
            case .secondary, .ghost:
                return isPressed ? Tokens.pressed : (isHot ? Tokens.hover : .clear)
            }
        }

        private var base: Color {
            guard kind == .secondary else { return .clear }
            return isEnabled ? Tokens.surface : Tokens.surface2
        }

        private var borderColor: Color {
            switch kind {
            case .primary: return isEnabled ? .clear : Tokens.border
            case .secondary: return isEnabled ? Tokens.controlBorder : Tokens.border
            case .ghost: return contrast == .increased ? Tokens.controlBorder : .clear
            }
        }
    }
}

extension ButtonStyle where Self == BrandButtonStyle {
    static var brandPrimary: BrandButtonStyle { BrandButtonStyle(kind: .primary) }
    static var brandSecondary: BrandButtonStyle { BrandButtonStyle(kind: .secondary) }
    static var brandGhost: BrandButtonStyle { BrandButtonStyle(kind: .ghost) }
    static var brandSecondarySmall: BrandButtonStyle { BrandButtonStyle(kind: .secondary, size: .small) }
    static var brandPrimaryLarge: BrandButtonStyle { BrandButtonStyle(kind: .primary, size: .large) }
}

// MARK: - Switch

/// The brand switch (Mowa's `MowaSwitchStyle`): accent when on, a framed gray track when off.
struct BrandSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Track(isOn: configuration.isOn) { configuration.isOn.toggle() }
            .accessibilityRepresentation {
                Toggle(isOn: configuration.$isOn) { configuration.label }
            }
    }

    private struct Track: View {
        let isOn: Bool
        let toggle: () -> Void
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? Tokens.accent : Tokens.controlBorder)
                Capsule().strokeBorder(Tokens.muted, lineWidth: 1).opacity(isOn ? 0 : 1)
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                    .padding(2)
            }
            .frame(width: 32, height: 20)
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Capsule())
            .onTapGesture { if isEnabled { toggle() } }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isOn)
        }
    }
}

// MARK: - Shared parts

/// A setting in a card: the name, one line about it, the control on the right.
struct SettingRow<Control: View>: View {
    let title: String
    var detail: String?
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textStyle(.body, weight: .medium)
                    .foregroundStyle(Tokens.text)
                if let detail {
                    Text(detail)
                        .textStyle(.small)
                        .foregroundStyle(Tokens.mutedOnFill)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            control()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// A group of settings: a small heading above a card with hairlines between its rows.
struct SettingSection<Content: View>: View {
    let title: String
    var footer: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .textStyle(.small, weight: .medium)
                .foregroundStyle(Tokens.mutedOnFill)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
            _VariadicView.Tree(Dividers()) { content() }
                .card()
            if let footer {
                Text(footer)
                    .textStyle(.small)
                    .foregroundStyle(Tokens.mutedOnFill)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
    }

    /// Rows with a hairline between them.
    private struct Dividers: _VariadicView_MultiViewRoot {
        func body(children: _VariadicView.Children) -> some View {
            VStack(spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    if index > 0 { Rectangle().fill(Tokens.border).frame(height: 1) }
                    child
                }
            }
        }
    }
}

/// A heading of the introduction: a soft tile with a symbol, the title and one paragraph.
struct StepHeading: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(Tokens.ink)
                .frame(width: 48, height: 48)
                .background(Tokens.soft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .textStyle(.title1)
                    .foregroundStyle(Tokens.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(text)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(Tokens.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A line that says how something went: green with a check, amber with a triangle.
struct StatusLine: View {
    let ok: Bool
    let text: String

    var body: some View {
        Label {
            Text(text).textStyle(.body, weight: .medium)
        } icon: {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
        }
        .foregroundStyle(ok ? Tokens.ink : Tokens.warn)
    }
}

/// Eryk's photo, read from the app's resources: the whole 5:4 frame in a rounded rectangle.
struct ErykPhotoView: View {
    var cornerRadius: CGFloat = Metrics.radiusXl
    private static let image: NSImage? = Bundle.main.url(forResource: "eryk", withExtension: "jpg", subdirectory: "Onboarding")
        .flatMap { NSImage(contentsOf: $0) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        Rectangle()
            .fill(Tokens.soft)
            .aspectRatio(5.0 / 4.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .overlay {
                if let image = Self.image {
                    Image(nsImage: image).resizable().interpolation(.high).scaledToFill()
                } else {
                    Text(verbatim: "ES").textStyle(.title1).foregroundStyle(Tokens.onSoft)
                }
            }
            .clipShape(shape)
            .overlay { shape.strokeBorder(Tokens.border, lineWidth: 1) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Eryk Sadowski with his dog Teddy")
            .accessibilityAddTraits(.isImage)
    }
}

/// The window look of the brand: the title bar in the window-bar color, no drawn title.
enum WindowChrome {
    static func apply(to window: NSWindow, title: String) {
        window.title = title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = Tokens.windowBarPair.ns
    }
}
