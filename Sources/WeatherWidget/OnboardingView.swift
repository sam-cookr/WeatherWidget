import SwiftUI

// MARK: - Onboarding Container

struct OnboardingView: View {
    @EnvironmentObject var settings: SettingsStore
    let onComplete: () -> Void

    @State private var step = 0
    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {

            // ── Step content ──────────────────────────────────────────────
            ZStack {
                switch step {
                case 0:  WelcomeStep()
                            .transition(stepTransition(forward: true))
                case 1:  HowItWorksStep()
                            .transition(stepTransition(forward: step > 0))
                default: SetupStep()
                            .transition(stepTransition(forward: true))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: step)

            // ── Footer ────────────────────────────────────────────────────
            VStack(spacing: 14) {
                // Step indicator dots
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(step == i ? Color.accentColor : Color.secondary.opacity(0.25))
                            .frame(width: step == i ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: step)
                    }
                }

                HStack {
                    // Back button
                    if step > 0 {
                        Button("Back") { step -= 1 }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    // Forward button
                    if step < totalSteps - 1 {
                        Button("Continue") { step += 1 }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .keyboardShortcut(.return)
                    } else {
                        Button("Get Started") {
                            UserDefaults.standard.set(true, forKey: "ww.onboardingComplete")
                            onComplete()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.return)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(.bar)
        }
        .frame(width: 540, height: 460)
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

                Text("Live weather conditions shown above your\nMac lock screen — always in the corner,\nnever in the way.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
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
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 10) {
                Text("Sits above the lock screen")
                    .font(.system(size: 22, weight: .bold))

                Text("WeatherWidget uses macOS's native SkyLight\ncompositor — no Screen Recording permission needed.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
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
                .foregroundStyle(.primary.opacity(0.75))
        }
    }
}

// MARK: - Step 3: Quick setup

private struct SetupStep: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Quick Setup")
                    .font(.system(size: 22, weight: .bold))
                Text("You can change these anytime from the menu bar.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 36)
            .padding(.bottom, 24)

            Form {
                Section("Widget Position") {
                    PositionPickerRow(selection: $settings.position)
                }

                Section("Temperature") {
                    Picker("Unit", selection: $settings.tempUnit) {
                        ForEach(TempUnit.allCases, id: \.self) { u in
                            Text(u.label).tag(u)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("Wind Speed") {
                    Picker("Unit", selection: $settings.windUnit) {
                        ForEach(WindUnit.allCases, id: \.self) { u in
                            Text(u.label).tag(u)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
    }
}
