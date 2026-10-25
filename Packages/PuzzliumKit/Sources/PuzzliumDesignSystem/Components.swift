import SwiftUI

// MARK: - Buttons

public struct PZPrimaryButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    public init(background: Color = PZColor.felt, foreground: Color = PZColor.onFelt) {
        self.background = background
        self.foreground = foreground
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PZFont.headline)
            .foregroundStyle(foreground)
            .padding(.horizontal, PZSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(background, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

public struct PZOutlineButtonStyle: ButtonStyle {
    let tint: Color

    public init(tint: Color = PZColor.onFelt) {
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PZFont.headline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 56)
            .overlay(Capsule().strokeBorder(tint.opacity(0.5), lineWidth: 1.5))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// 44 pt circular icon button.
public struct PZCircleButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    public init(background: Color = PZColor.surface, foreground: Color = PZColor.ink) {
        self.background = background
        self.foreground = foreground
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: 44, height: 44)
            .background(background, in: Circle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PZPrimaryButtonStyle {
    public static var pzPrimary: PZPrimaryButtonStyle { PZPrimaryButtonStyle() }
    public static func pzPrimary(background: Color, foreground: Color) -> PZPrimaryButtonStyle {
        PZPrimaryButtonStyle(background: background, foreground: foreground)
    }
}

extension ButtonStyle where Self == PZCircleButtonStyle {
    public static var pzCircle: PZCircleButtonStyle { PZCircleButtonStyle() }
    public static func pzCircle(background: Color, foreground: Color) -> PZCircleButtonStyle {
        PZCircleButtonStyle(background: background, foreground: foreground)
    }
}

// MARK: - Chip

public struct PZChip: View {
    public enum Tone: Sendable {
        case light
        case onFelt
    }

    private let title: String
    private let isSelected: Bool
    private let tone: Tone
    private let action: () -> Void

    public init(_ title: String, isSelected: Bool, tone: Tone = .light, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.tone = tone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? PZFont.callout.weight(.bold) : PZFont.callout)
                .lineLimit(1)
                .padding(.horizontal, PZSpacing.l)
                .frame(minHeight: 40)
                .foregroundStyle(foreground)
                .background(background, in: Capsule())
                .overlay {
                    if !isSelected, tone == .light {
                        Capsule().strokeBorder(PZColor.divider)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var background: Color {
        switch (tone, isSelected) {
        case (.light, true): PZColor.felt
        case (.light, false): PZColor.surface
        case (.onFelt, true): PZColor.amber
        case (.onFelt, false): .white.opacity(0.1)
        }
    }

    private var foreground: Color {
        switch (tone, isSelected) {
        case (.light, true): PZColor.onFelt
        case (.light, false): PZColor.ink
        case (.onFelt, true): Color(hex: 0x18201D)
        case (.onFelt, false): PZColor.onFelt
        }
    }
}

// MARK: - Progress

public struct PZProgressBar: View {
    private let value: Double
    private let tint: Color
    private let track: Color
    private let height: CGFloat

    public init(value: Double, tint: Color = PZColor.felt, track: Color = PZColor.divider, height: CGFloat = 4) {
        self.value = min(max(value, 0), 1)
        self.tint = tint
        self.track = track
        self.height = height
    }

    public var body: some View {
        Capsule()
            .fill(track)
            .frame(height: height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule().fill(tint).frame(width: proxy.size.width * value)
                }
            }
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }
}

// MARK: - Card

extension View {
    public func pzCard(padding: CGFloat = PZSpacing.l, radius: CGFloat = PZRadius.l) -> some View {
        self
            .padding(padding)
            .background(PZColor.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
