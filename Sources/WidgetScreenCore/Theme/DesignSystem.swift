import SwiftUI

public enum PreferencesPalette {
    public static let canvasTop    = Color(red: 0.08, green: 0.08, blue: 0.10)
    public static let canvasBottom = Color(red: 0.03, green: 0.03, blue: 0.04)
    public static let cardFill     = WidgetPalette.preferencesPanel
    public static let cardStroke   = WidgetPalette.borderSecondary
    public static let tileFill     = WidgetPalette.preferencesTile
    public static let tileStroke   = WidgetPalette.borderSecondary
}

public enum WidgetPalette {
    public static let primaryText    = Color.white.opacity(0.96)
    public static let secondaryText  = Color.white.opacity(0.72)
    public static let tertiaryText   = Color.white.opacity(0.48)
    public static let quaternaryText = Color.white.opacity(0.32)

    public static let surfacePrimary   = Color.white.opacity(0.09)
    public static let surfaceSecondary = Color.white.opacity(0.055)
    public static let surfaceTertiary  = Color.white.opacity(0.035)

    public static let borderPrimary   = Color.white.opacity(0.14)
    public static let borderSecondary = Color.white.opacity(0.08)
    public static let divider         = Color.white.opacity(0.08)
    public static let selectedFill    = Color.white.opacity(0.20)
    public static let pressedFill     = Color.white.opacity(0.14)

    public static let preferencesCanvas  = Color.black.opacity(0.96)
    public static let preferencesSurface = Color.white.opacity(0.045)
    public static let preferencesPanel   = Color.white.opacity(0.06)
    public static let preferencesTile    = Color.white.opacity(0.03)
}

public enum WidgetTypography {
    public static let widgetTitle      = Font.system(size: 15, weight: .bold)
    public static let widgetMeta       = Font.system(size: 11, weight: .medium)
    public static let widgetHero       = Font.system(size: 62, weight: .thin)
    public static let widgetDegree     = Font.system(size: 24, weight: .light)
    public static let widgetCondition  = Font.system(size: 18, weight: .semibold)
    public static let widgetSubheadline = Font.system(size: 13, weight: .semibold)
    public static let widgetCaption    = Font.system(size: 10, weight: .semibold)

    public static let settingsTitle   = Font.system(size: 16, weight: .bold)
    public static let settingsSection = Font.system(size: 10, weight: .bold)
    public static let settingsLabel   = Font.system(size: 12, weight: .semibold)
    public static let settingsValue   = Font.system(size: 12, weight: .medium)
    public static let settingsControl = Font.system(size: 12, weight: .semibold)

    public static let prefsHero      = Font.system(size: 32, weight: .bold)
    public static let prefsSection   = Font.system(size: 22, weight: .bold)
    public static let prefsCardTitle = Font.system(size: 18, weight: .bold)
    public static let prefsRowTitle  = Font.system(size: 13, weight: .semibold)
    public static let prefsBody      = Font.system(size: 13, weight: .regular)
    public static let prefsCaption   = Font.system(size: 11, weight: .semibold)

    public static let prefsSectionTitle = Font.system(size: 15, weight: .heavy)
    public static let prefsRowLabel     = Font.system(size: 13, weight: .semibold)
}

/// Canonical animation values. Use `Motion.spring(reduceMotion:)` at call sites.
public enum Motion {
    public static let defaultSpring = Animation.spring(response: 0.35, dampingFraction: 0.85)
    public static let quickSpring   = Animation.spring(response: 0.24, dampingFraction: 0.82)
    public static let fastSpring    = Animation.spring(response: 0.20)

    public static func spring(_ animation: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.18) : animation
    }
}

public struct MonochromePanelBackground: View {
    public var cornerRadius: CGFloat
    public init(cornerRadius: CGFloat) { self.cornerRadius = cornerRadius }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(WidgetPalette.surfaceSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(WidgetPalette.borderSecondary, lineWidth: 1)
            )
    }
}

public struct MonochromeInsetBackground: View {
    public var cornerRadius: CGFloat
    public init(cornerRadius: CGFloat = 18) { self.cornerRadius = cornerRadius }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(WidgetPalette.surfaceTertiary)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(WidgetPalette.borderSecondary, lineWidth: 1)
            )
    }
}
