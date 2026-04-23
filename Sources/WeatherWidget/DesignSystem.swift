import SwiftUI

enum PreferencesPalette {
    static let canvasTop = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let canvasBottom = Color(red: 0.03, green: 0.03, blue: 0.04)
    static let cardFill = WidgetPalette.preferencesPanel
    static let cardStroke = WidgetPalette.borderSecondary
    static let tileFill = WidgetPalette.preferencesTile
    static let tileStroke = WidgetPalette.borderSecondary
}

enum WidgetPalette {
    static let primaryText = Color.white.opacity(0.96)
    static let secondaryText = Color.white.opacity(0.72)
    static let tertiaryText = Color.white.opacity(0.48)
    static let quaternaryText = Color.white.opacity(0.32)

    static let surfacePrimary = Color.white.opacity(0.09)
    static let surfaceSecondary = Color.white.opacity(0.055)
    static let surfaceTertiary = Color.white.opacity(0.035)

    static let borderPrimary = Color.white.opacity(0.14)
    static let borderSecondary = Color.white.opacity(0.08)
    static let divider = Color.white.opacity(0.08)
    static let selectedFill = Color.white.opacity(0.20)
    static let pressedFill = Color.white.opacity(0.14)

    static let preferencesCanvas = Color.black.opacity(0.96)
    static let preferencesSurface = Color.white.opacity(0.045)
    static let preferencesPanel = Color.white.opacity(0.06)
    static let preferencesTile = Color.white.opacity(0.03)
}

enum WidgetTypography {
    static let widgetTitle = Font.system(size: 15, weight: .bold)
    static let widgetMeta = Font.system(size: 11, weight: .medium)
    static let widgetHero = Font.system(size: 62, weight: .thin)
    static let widgetDegree = Font.system(size: 24, weight: .light)
    static let widgetCondition = Font.system(size: 18, weight: .semibold)
    static let widgetSubheadline = Font.system(size: 13, weight: .semibold)
    static let widgetCaption = Font.system(size: 10, weight: .semibold)

    static let settingsTitle = Font.system(size: 16, weight: .bold)
    static let settingsSection = Font.system(size: 10, weight: .bold)
    static let settingsLabel = Font.system(size: 12, weight: .semibold)
    static let settingsValue = Font.system(size: 12, weight: .medium)
    static let settingsControl = Font.system(size: 12, weight: .semibold)

    static let prefsHero = Font.system(size: 32, weight: .bold)
    static let prefsSection = Font.system(size: 22, weight: .bold)
    static let prefsCardTitle = Font.system(size: 18, weight: .bold)
    static let prefsRowTitle = Font.system(size: 13, weight: .semibold)
    static let prefsBody = Font.system(size: 13, weight: .regular)
    static let prefsCaption = Font.system(size: 11, weight: .semibold)
}

struct MonochromePanelBackground: View {
    var cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(WidgetPalette.surfaceSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(WidgetPalette.borderSecondary, lineWidth: 1)
            )
    }
}

struct MonochromeInsetBackground: View {
    var cornerRadius: CGFloat = 18

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(WidgetPalette.surfaceTertiary)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(WidgetPalette.borderSecondary, lineWidth: 1)
            )
    }
}
