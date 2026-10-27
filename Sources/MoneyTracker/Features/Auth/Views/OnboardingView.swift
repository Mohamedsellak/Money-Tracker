// OnboardingView.swift
// Purpose: First-run flow: three illustrated intro slides, then account setup
// (name -> passcode -> confirm -> biometrics -> done). The profile is only
// written at the very end, so quitting midway restarts cleanly.

import SwiftUI

struct OnboardingView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Step: Int, Comparable {
        case intro, name, passcode, confirm, biometrics, done
        static func < (lhs: Step, rhs: Step) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    @State private var step: Step = .intro
    @State private var page = 0
    @State private var name = ""
    @State private var firstPasscode = ""
    @State private var entry = PasscodeEntry()
    @State private var shakeTrigger: CGFloat = 0
    @State private var isError = false
    @State private var wantsBiometrics = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack {
            AuroraBackground(intensity: step == .done ? 1.2 : 0.9)

            Group {
                switch step {
                case .intro: intro
                case .name: nameStep
                case .passcode, .confirm: passcodeStep
                case .biometrics: biometricStep
                case .done: doneStep
                }
            }
            .transition(
                reduceMotion
                    ? .opacity
                    : .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    )
            )
        }
        .environment(\.colorScheme, .dark)
    }

    private func go(_ next: Step) {
        withAnimation(Motion.respecting(reduceMotion, Motion.smooth)) {
            step = next
        }
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(spacing: 0) {
            HStack {
                BrandMark()
                Spacer()
                if page < OnboardingSlide.all.count - 1 {
                    Button("Skip") {
                        Haptics.tap()
                        go(.name)
                    }
                    .font(AppFont.bodyMedium)
                    .foregroundColor(Color.appOnInkMuted)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xs)

            TabView(selection: $page) {
                ForEach(Array(OnboardingSlide.all.enumerated()), id: \.offset) { index, slide in
                    SlideView(slide: slide, isActive: page == index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageIndicator(count: OnboardingSlide.all.count, current: page)
                .padding(.bottom, Spacing.xl)

            PrimaryButton(page == OnboardingSlide.all.count - 1 ? "Get started" : "Continue", iconName: "arrow.right") {
                Haptics.tap()
                if page < OnboardingSlide.all.count - 1 {
                    withAnimation(Motion.smooth) { page += 1 }
                } else {
                    go(.name)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.lg)
        }
    }

    // MARK: - Name

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            StepHeader(index: 1, total: 3) { go(.intro) }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What should we\ncall you?")
                    .font(AppFont.marketing)
                    .foregroundColor(Color.appOnInk)
                Text("Your name stays on this device. No account, no tracking.")
                    .font(AppFont.body)
                    .foregroundColor(Color.appOnInkMuted)
            }
            .appearLift(0)

            HStack(spacing: Spacing.md) {
                AvatarView(name: trimmedName.isEmpty ? "?" : trimmedName, size: 52)
                    .animation(Motion.snappy, value: trimmedName)

                TextField("", text: $name, prompt: Text("First name").foregroundColor(Color.white.opacity(0.35)))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appOnInk)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.continue)
                    .focused($isNameFocused)
                    .onSubmit(submitName)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(isNameFocused ? Color.appAccent.opacity(0.7) : Color.white.opacity(0.12), lineWidth: 1)
            )
            .appearLift(1)

            Spacer()

            PrimaryButton("Continue", iconName: "arrow.right", isEnabled: !trimmedName.isEmpty) {
                submitName()
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.lg)
        .onAppear { isNameFocused = true }
    }

    private func submitName() {
        guard !trimmedName.isEmpty else { return }
        Haptics.tap()
        isNameFocused = false
        entry.reset()
        go(.passcode)
    }

    // MARK: - Passcode

    private var passcodeStep: some View {
        VStack(spacing: 0) {
            StepHeader(index: 2, total: 3) {
                entry.reset()
                firstPasscode = ""
                go(step == .confirm ? .passcode : .name)
            }
            .padding(.horizontal, Spacing.xl)

            Spacer(minLength: Spacing.md)

            VStack(spacing: Spacing.sm) {
                Image(systemName: step == .confirm ? "checkmark.shield.fill" : "lock.shield.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .symbolEffect(.bounce, value: step)
                    .padding(.bottom, Spacing.xs)
                Text(step == .confirm ? "Confirm your passcode" : "Create a passcode")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appOnInk)
                Text(isError ? "Passcodes didn't match. Try again." : "6 digits to keep your finances private.")
                    .font(AppFont.body)
                    .foregroundColor(isError ? Color.appInkNegative : Color.appOnInkMuted)
            }
            .multilineTextAlignment(.center)
            .id(step)

            Spacer(minLength: Spacing.lg)

            PasscodeDots(filled: entry.digits.count, isError: isError)
                .shake(shakeTrigger)

            Spacer(minLength: Spacing.lg)

            PasscodeKeypad(onKey: handlePasscodeKey)

            Button("Skip for now") {
                Haptics.tap()
                firstPasscode = ""
                go(.done)
            }
            .font(AppFont.bodyMedium)
            .foregroundColor(Color.appOnInkMuted)
            .frame(minHeight: 44)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
        }
    }

    private func handlePasscodeKey(_ key: PadKey) {
        if isError { isError = false }
        guard let code = entry.apply(key) else { return }

        Task {
            try? await Task.sleep(for: .milliseconds(180))
            if step == .passcode {
                firstPasscode = code
                entry.reset()
                go(.confirm)
            } else if code == firstPasscode {
                auth.setPasscode(code)
                Haptics.success()
                entry.reset()
                go(auth.biometricKind == .none ? .done : .biometrics)
            } else {
                Haptics.error()
                isError = true
                withAnimation(reduceMotion ? nil : .linear(duration: 0.45)) { shakeTrigger += 1 }
                try? await Task.sleep(for: .milliseconds(450))
                entry.reset()
                firstPasscode = ""
                go(.passcode)
                isError = true
            }
        }
    }

    // MARK: - Biometrics

    private var biometricStep: some View {
        let kind = auth.biometricKind
        return VStack(spacing: Spacing.xl) {
            StepHeader(index: 3, total: 3, onBack: nil)

            Spacer()

            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .strokeBorder(Color.appAccent.opacity(0.25 - Double(ring) * 0.07), lineWidth: 1)
                        .frame(width: 130 + CGFloat(ring) * 50, height: 130 + CGFloat(ring) * 50)
                }
                Circle()
                    .fill(Color.appAccent.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: kind.iconName)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(Color.appAccent)
                    .symbolEffect(.pulse, isActive: !reduceMotion)
            }
            .appearLift(0)

            VStack(spacing: Spacing.sm) {
                Text("Unlock with \(kind.title)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appOnInk)
                Text("Sign in with a glance. Your passcode always works as a backup.")
                    .font(AppFont.body)
                    .foregroundColor(Color.appOnInkMuted)
            }
            .multilineTextAlignment(.center)
            .appearLift(1)

            Spacer()

            VStack(spacing: Spacing.sm) {
                PrimaryButton("Enable \(kind.title)", iconName: kind.iconName) {
                    Task {
                        if await BiometricAuth.authenticate(reason: "Enable \(kind.title) for MoneyTracker") {
                            wantsBiometrics = true
                            Haptics.success()
                        }
                        go(.done)
                    }
                }
                Button("Not now") {
                    Haptics.tap()
                    go(.done)
                }
                .font(AppFont.bodyMedium)
                .foregroundColor(Color.appOnInkMuted)
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Done

    private var doneStep: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            SuccessBadge()

            VStack(spacing: Spacing.sm) {
                Text("You're all set,\n\(trimmedName)")
                    .font(AppFont.marketing)
                    .foregroundColor(Color.appOnInk)
                Text("We added a few sample entries so you can look around. Delete them any time.")
                    .font(AppFont.body)
                    .foregroundColor(Color.appOnInkMuted)
            }
            .multilineTextAlignment(.center)
            .appearLift(1)

            Spacer()

            PrimaryButton("Open MoneyTracker", iconName: "arrow.right") {
                auth.createProfile(name: trimmedName)
                if wantsBiometrics { auth.setBiometricsEnabled(true) }
                Haptics.success()
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Pieces

private struct StepHeader: View {
    let index: Int
    let total: Int
    let onBack: (() -> Void)?

    var body: some View {
        HStack {
            if let onBack {
                Button {
                    Haptics.tap()
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.appOnInk)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .accessibilityLabel("Back")
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(1...total, id: \.self) { step in
                    Capsule()
                        .fill(step <= index ? Color.appAccent : Color.white.opacity(0.18))
                        .frame(width: step == index ? 22 : 8, height: 6)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(index) of \(total)")

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, Spacing.xs)
    }
}

private struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.appAccent : Color.white.opacity(0.22))
                    .frame(width: index == current ? 26 : 8, height: 8)
            }
        }
        .animation(Motion.snappy, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}

/// Small wordmark: lime squircle with the app glyph plus the name.
struct BrandMark: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient.accentSheen)
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.appOnAccent)
            }
            .frame(width: 34, height: 34)

            Text("MoneyTracker")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color.appOnInk)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SuccessBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(Color.appAccent.opacity(0.3 - Double(ring) * 0.09), lineWidth: 1.5)
                    .frame(width: 120 + CGFloat(ring) * 44)
                    .scaleEffect(isShown || reduceMotion ? 1 : 0.6)
                    .opacity(isShown ? 1 : 0)
                    .animation(Motion.gentle.delay(0.1 + Double(ring) * 0.08), value: isShown)
            }
            Circle()
                .fill(LinearGradient.accentSheen)
                .frame(width: 110, height: 110)
                .shadow(color: Color.appAccent.opacity(0.6), radius: 30)
                .scaleEffect(isShown || reduceMotion ? 1 : 0.4)
            Image(systemName: "checkmark")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Color.appOnAccent)
                .scaleEffect(isShown || reduceMotion ? 1 : 0.2)
        }
        .animation(Motion.respecting(reduceMotion, .spring(response: 0.55, dampingFraction: 0.6)), value: isShown)
        .onAppear {
            isShown = true
            Haptics.success()
        }
        .accessibilityHidden(true)
    }
}
