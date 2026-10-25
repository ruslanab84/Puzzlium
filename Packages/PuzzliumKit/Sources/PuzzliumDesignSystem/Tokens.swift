import SwiftUI
import UIKit

public enum PZColor {
    public static let ground = Color(light: 0xF3F2EF, dark: 0x111614)
    public static let surface = Color(light: 0xFFFFFF, dark: 0x1B221F)
    public static let ink = Color(light: 0x18201D, dark: 0xEEF1EF)
    public static let muted = Color(light: 0x5B6661, dark: 0xA3ADA8)
    public static let divider = Color(light: 0xE2E0DA, dark: 0x2C3531)
    /// Brand green for fills. Text on `ground` uses `accentText` (passes contrast in dark mode).
    public static let felt = Color(hex: 0x1F4A3D)
    public static let feltDeep = Color(hex: 0x173A30)
    public static let accentText = Color(light: 0x1F4A3D, dark: 0x7CC8AB)
    public static let amber = Color(hex: 0xE3A13A)
    public static let ember = Color(hex: 0xC9561E)
    public static let onFelt = Color.white
    public static let onFeltMuted = Color(hex: 0xCFE0D9)
}

public enum PZFont {
    public static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    public static let title = Font.system(.title2, design: .rounded, weight: .bold)
    public static let title3 = Font.system(.title3, design: .rounded, weight: .bold)
    public static let headline = Font.system(.headline, design: .rounded, weight: .bold)
    public static let body = Font.body
    public static let callout = Font.callout
    public static let footnote = Font.footnote
    public static let caption = Font.caption
    public static let eyebrow = Font.caption.weight(.bold)

    public static func number(_ style: Font.TextStyle) -> Font {
        .system(style, design: .rounded, weight: .bold).monospacedDigit()
    }
}

public enum PZSpacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

public enum PZRadius {
    public static let s: CGFloat = 12
    public static let m: CGFloat = 16
    public static let l: CGFloat = 20
    public static let xl: CGFloat = 28
}

extension Color {
    public init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    public init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
