import WidgetScreenCore
import SwiftUI

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome, howItWorks, location, setup
}

// MARK: - Onboarding Container

struct OnboardingView: View {
    @EnvironmentObject var settings: SettingsStore
    let onComplete: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var goingForward = true
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            onboardingBackground

            VStack(spacing: 0) {
                // ── Step content ──────────────────────────────────────────────
                ZStack {
                    switch step {
                    case .welcome:    WelcomeStep()
                    case .howItWorks: HowItWorksStep()
                    case .location:   LocationStep()
                    case .setup:      SetupStep()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(Motion.spring(.spring(response: 0.4, dampingFraction: 0.85), reduceMotion: reduceMotion), value: step)

                // ── Footer ────────────────────────────────────────────────────
                footerBar
            }
        }
        .frame(width: 540, height: 540)
    }

    // MARK: - Background

    private var onboardingBackground: some View {
        ZStack {
            LinearGradient(
                colors: [PreferencesPalette.canvasTop, PreferencesPalette.canvasBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -200, y: -160)
            Circle()
                .fill(Color.blue.opacity(0.10))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 220, y: 180)
        }
        .ignoresSafeArea()
    }

    // MARK: - Footer

    private var footerBar: some View {
        VStack(spacing: 14) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 0.5)

            // Step indicator dots
            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases, id: \.self) { s in
                    Capsule()
                        .fill(step == s ? Color.white.opacity(0.9) : Color.white.opacity(0.22))
                        .frame(width: step == s ? 18 : 6, height: 6)
                        .animation(Motion.spring(.spring(response: 0.3, dampingFraction: 0.8), reduceMotion: reduceMotion), value: step)
                }
            }

            HStack {
                if step != .welcome {
                    Button("Back") {
                        goingForward = false
                        withAnimation(Motion.spring(.spring(response: 0.4, dampingFraction: 0.85), reduceMotion: reduceMotion)) {
                            step = OnboardingStep(rawValue: step.rawValue - 1) ?? .welcome
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Button("Skip") {
                    markComplete()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.3))

                if step != OnboardingStep.allCases.last {
                    glassButton("Continue") {
                        goingForward = true
                        withAnimation(Motion.spring(.spring(response: 0.4, dampingFraction: 0.85), reduceMotion: reduceMotion)) {
                            step = OnboardingStep(rawValue: step.rawValue + 1) ?? .setup
                        }
                    }
                    .keyboardShortcut(.return)
                } else {
                    glassButton("Get Started") {
                        markComplete()
                    }
                    .keyboardShortcut(.return)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 14)
        .padding(.bottom, 22)
        .background(Color.black.opacity(0.25))
    }

    private func glassButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.white.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.5))
                )
        }
        .buttonStyle(.plain)
    }

    private func markComplete() {
        UserDefaults.standard.set(true, forKey: "ww.onboardingComplete")
        onComplete()
    }

    private func stepTransition(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion:  .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal:    .move(edge: forward ? .leading  : .trailing).combined(with: .opacity)
        )
    }
}

// MARK: - Step 1: Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 72))
                .symbolRenderingMode(.multicolor)
                .shadow(color: .blue.opacity(0.25), radius: 20, x: 0, y: 8)

            VStack(spacing: 10) {
                Text("Welcome to WeatherWidget")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)

                Text("Live weather conditions shown above your\nMac lock screen — always in the corner,\nnever in the way.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding(40)
    }
}

// MARK: - Step 2: How it works

private struct HowItWorksStep: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "lock.display")
                .font(.system(size: 60))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.cyan)

            VStack(spacing: 10) {
                Text("Sits above the lock screen")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text("WeatherWidget uses macOS's native SkyLight\ncompositor — no Screen Recording permission needed.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            VStack(alignment: .leading, spacing: 12) {
                featureRow(.green,  "checkmark.circle.fill", "No permissions required")
                featureRow(.blue,   "paintbrush.fill",       "Native macOS glass effect")
                featureRow(.orange, "arrow.clockwise",       "Auto-refreshes in the background")
                featureRow(.purple, "gearshape.fill",        "Tap ⚙ on the widget to change settings while locked")
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(40)
    }

    private func featureRow(_ color: Color, _ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.75))
        }
    }
}

// MARK: - Step 3: Location

private struct LocationStep: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 52))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.mint)

                    VStack(spacing: 8) {
                        Text("Set Your Location")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        Text("WeatherWidget uses your IP address for\nautomatic location, or you can pin a custom city.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                }
                .padding(.top, 24)

                VStack(spacing: 10) {
                    SettingsGroup(title: "LOCATION MODE") {
                        SettingRow(label: "Mode", icon: "location.fill", iconColor: .mint) {
                            SegmentPicker(
                                options: LocationMode.allCases,
                                selection: $settings.locationMode
                            )
                        }

                        if settings.locationMode == .manual {
                            RowDivider()
                            SettingRow(label: "City", icon: "magnifyingglass", iconColor: .teal) {
                                LocationSearchView()
                            }
                        }
                    }

                    if settings.locationMode == .auto {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("Location is detected automatically using your IP address.")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Step 4: Quick setup

private struct SetupStep: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Quick Setup")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("You can change these anytime from the menu bar.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 24)

                VStack(spacing: 10) {
                    SettingsGroup(title: "WIDGET") {
                        SettingRow(label: "Position", icon: "arrow.up.left.and.arrow.down.right", iconColor: .blue) {
                            PositionPickerRow(selection: $settings.position)
                        }
                        RowDivider()
                        SettingRow(label: "Size", icon: "rectangle.expand.vertical", iconColor: .green) {
                            SegmentPicker(options: Array(WidgetSize.allCases), selection: $settings.widgetSize)
                        }
                    }

                    SettingsGroup(title: "UNITS") {
                        SettingRow(label: "Temperature", icon: "thermometer.medium", iconColor: .orange) {
                            SegmentPicker(options: Array(TempUnit.allCases), selection: $settings.tempUnit)
                        }
                        RowDivider()
                        SettingRow(label: "Wind Speed", icon: "wind", iconColor: .cyan) {
                            SegmentPicker(options: Array(WindUnit.allCases), selection: $settings.windUnit)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .scrollIndicators(.hidden)
    }
}
