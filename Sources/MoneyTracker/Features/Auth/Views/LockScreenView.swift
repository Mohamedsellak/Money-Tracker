// LockScreenView.swift
// Purpose: "Welcome back" sign-in screen shown on launch and after auto-lock.
// Offers Face ID / Touch ID first, then a 6-digit passcode with shake on error
// and a temporary lockout after repeated failures.

import SwiftUI

struct LockScreenView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var entry = PasscodeEntry()
    @State private var shakeTrigger: CGFloat = 0
    @State private var isError = false
    @State private var message: String?
    @State private var didAutoPromptBiometrics = false

    private var isLockedOut: Bool { auth.lockoutUntil != nil }

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.85)

            VStack(spacing: 0) {
                Spacer(minLength: Spacing.xl)

                VStack(spacing: Spacing.md) {
                    AvatarView(name: auth.displayName, size: 76)
                        .shadow(color: Color.appAccent.opacity(0.5), radius: 24)
                        .appearLift(0)

                    VStack(spacing: 6) {
                        Text("\(auth.greeting),")
                            .font(AppFont.body)
                            .foregroundColor(Color.appOnInkMuted)
                        Text(auth.firstName)
                            .font(AppFont.marketing)
                            .foregroundColor(Color.appOnInk)
                    }
                    .multilineTextAlignment(.center)
                    .appearLift(1)
                }

                Spacer(minLength: Spacing.xl)

                VStack(spacing: Spacing.md) {
                    PasscodeDots(filled: entry.digits.count, isError: isError)
                        .shake(shakeTrigger)

                    Group {
                        if let until = auth.lockoutUntil {
                            // Only this label ticks, and only during a lockout.
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                let seconds = max(0, Int(until.timeIntervalSince(context.date).rounded(.up)))
                                Text("Too many attempts. Try again in \(seconds)s")
                                    .monospacedDigit()
                            }
                        } else {
                            Text(message ?? "Enter your passcode")
                        }
                    }
                    .font(AppFont.caption)
                    .foregroundColor(isError || isLockedOut ? Color.appInkNegative : Color.appOnInkMuted)
                    .frame(height: 18)
                    .accessibilityAddTraits(.updatesFrequently)
                }
                .appearLift(2)

                Spacer(minLength: Spacing.xl)

                PasscodeKeypad(
                    biometricIcon: auth.biometricsEnabled ? auth.biometricKind.iconName : nil,
                    isDisabled: isLockedOut,
                    onKey: handle
                )
                .appearLift(3)

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .environment(\.colorScheme, .dark)
        .task {
            guard !didAutoPromptBiometrics else { return }
            didAutoPromptBiometrics = true
            try? await Task.sleep(for: .milliseconds(150))
            await tryBiometrics()
        }
    }

    private func handle(_ key: PadKey) {
        if key == .biometric {
            Task { await tryBiometrics() }
            return
        }
        if isError {
            isError = false
            message = nil
        }
        guard let code = entry.apply(key) else { return }

        if auth.unlock(with: code) {
            Haptics.success()
        } else {
            Haptics.error()
            isError = true
            let remaining = auth.remainingAttempts
            message = auth.lockoutUntil != nil ? nil : "Wrong passcode · \(remaining) attempt\(remaining == 1 ? "" : "s") left"
            withAnimation(reduceMotion ? nil : .linear(duration: 0.45)) {
                shakeTrigger += 1
            }
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                entry.reset()
            }
        }
    }

    private func tryBiometrics() async {
        guard auth.biometricsEnabled else { return }
        if await auth.unlockWithBiometrics() {
            Haptics.success()
        }
    }
}
