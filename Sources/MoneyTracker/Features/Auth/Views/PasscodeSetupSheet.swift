// PasscodeSetupSheet.swift
// Purpose: Settings flow to create, change or turn off the passcode. Verifies
// the current code first when one exists.

import SwiftUI

struct PasscodeSetupSheet: View {
    enum Mode {
        case create, change, remove
    }

    let mode: Mode

    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Stage { case current, new, confirm }

    @State private var stage: Stage
    @State private var entry = PasscodeEntry()
    @State private var firstPasscode = ""
    @State private var isError = false
    @State private var errorText = ""
    @State private var shakeTrigger: CGFloat = 0

    init(mode: Mode) {
        self.mode = mode
        _stage = State(initialValue: mode == .create ? .new : .current)
    }

    private var title: String {
        switch stage {
        case .current: "Enter current passcode"
        case .new: mode == .create ? "Create a passcode" : "Enter a new passcode"
        case .confirm: "Confirm new passcode"
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            AuroraBackground(intensity: 0.7)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .font(AppFont.bodyMedium)
                        .foregroundColor(Color.appOnInkMuted)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)

                Spacer(minLength: Spacing.md)

                VStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                    Text(title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appOnInk)
                        .id(stage)
                        .transition(.opacity)
                    Text(isError ? errorText : "\(PasscodeVault.length) digits")
                        .font(AppFont.caption)
                        .foregroundColor(isError ? Color.appInkNegative : Color.appOnInkMuted)
                }

                Spacer(minLength: Spacing.lg)

                PasscodeDots(filled: entry.digits.count, isError: isError)
                    .shake(shakeTrigger)

                Spacer(minLength: Spacing.lg)

                PasscodeKeypad(onKey: handle)
                    .padding(.bottom, Spacing.xxl)
            }
        }
        .environment(\.colorScheme, .dark)
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.hero)
    }

    private func handle(_ key: PadKey) {
        if isError { isError = false }
        guard let code = entry.apply(key) else { return }

        Task {
            try? await Task.sleep(for: .milliseconds(160))
            switch stage {
            case .current:
                if auth.verify(code) {
                    if mode == .remove {
                        auth.removePasscode()
                        Haptics.success()
                        dismiss()
                    } else {
                        advance(to: .new)
                    }
                } else {
                    fail("Wrong passcode")
                }
            case .new:
                firstPasscode = code
                advance(to: .confirm)
            case .confirm:
                if code == firstPasscode {
                    auth.setPasscode(code)
                    Haptics.success()
                    dismiss()
                } else {
                    fail("Passcodes didn't match")
                    firstPasscode = ""
                    advance(to: .new, keepError: true)
                }
            }
        }
    }

    private func advance(to next: Stage, keepError: Bool = false) {
        entry.reset()
        withAnimation(Motion.respecting(reduceMotion, Motion.smooth)) { stage = next }
        if keepError { isError = true }
    }

    private func fail(_ message: String) {
        Haptics.error()
        errorText = message
        isError = true
        withAnimation(reduceMotion ? nil : .linear(duration: 0.45)) { shakeTrigger += 1 }
        entry.reset()
    }
}
