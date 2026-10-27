// OnboardingSlides.swift
// Purpose: Content and illustrations for the three intro slides. Illustrations
// are composed from SwiftUI shapes and SF Symbols (no image assets) and float
// gently unless Reduce Motion is on.

import SwiftUI

struct OnboardingSlide {
    enum Art { case balance, plan, privacy }

    let art: Art
    let eyebrow: String
    let title: String
    let message: String

    static let all: [OnboardingSlide] = [
        OnboardingSlide(
            art: .balance,
            eyebrow: "Track",
            title: "Every euro,\naccounted for.",
            message: "See income, spending and what's left at a glance. Totals update the moment you type."
        ),
        OnboardingSlide(
            art: .plan,
            eyebrow: "Plan",
            title: "A plan for\nevery paycheck.",
            message: "Split your income into buckets like 60 / 10 / 10 / 10 / 10 and watch each one fill up."
        ),
        OnboardingSlide(
            art: .privacy,
            eyebrow: "Protect",
            title: "Private by\ndesign.",
            message: "Your data never leaves this iPhone. Lock it with a passcode and Face ID."
        ),
    ]
}

struct SlideView: View {
    let slide: OnboardingSlide
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer(minLength: 0)

            Group {
                switch slide.art {
                case .balance: BalanceArt(isActive: isActive)
                case .plan: PlanArt(isActive: isActive)
                case .privacy: PrivacyArt(isActive: isActive)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .accessibilityHidden(true)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(slide.eyebrow.uppercased())
                    .font(AppFont.eyebrow)
                    .tracking(2)
                    .foregroundColor(Color.appAccent)
                Text(slide.title)
                    .font(AppFont.marketing)
                    .foregroundColor(Color.appOnInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(slide.message)
                    .font(AppFont.body)
                    .foregroundColor(Color.appOnInkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - Float helper

/// Bobs content up and down with one repeating animation that Core Animation
/// interpolates, instead of re-evaluating the view every frame.
private struct Floating: ViewModifier {
    let amplitude: CGFloat
    let period: Double
    let phase: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isUp = false

    func body(content: Content) -> some View {
        content
            .offset(y: isUp ? -amplitude : amplitude)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeInOut(duration: period / 2)
                        .repeatForever(autoreverses: true)
                        .delay(phase * 0.3)
                ) {
                    isUp = true
                }
            }
    }
}

private extension View {
    func floating(_ amplitude: CGFloat = 6, period: Double = 4, phase: Double = 0) -> some View {
        modifier(Floating(amplitude: amplitude, period: period, phase: phase))
    }
}

/// Small glass pill used inside illustrations.
private struct GlassChip: View {
    let icon: String
    let title: String
    let amount: String
    let positive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.appOnAccent)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(CategoryTint.color(for: icon)))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appOnInk)
                Text(amount)
                    .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(positive ? Color.appAccent : Color.appInkNegative)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: 0x2E2D2C).opacity(0.92))
                .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 8)
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
    }
}

// MARK: - Slide 1: balance card

private struct BalanceArt: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Total balance")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.appOnInkMuted)
                    Spacer()
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.appOnInkMuted)
                }
                Text("€1 721,01")
                    .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(Color.appOnInk)
                MiniBars()
                    .frame(height: 46)
            }
            .padding(22)
            .frame(width: 260)
            .inkCard()
            .rotationEffect(.degrees(-4))
            .floating(5, period: 5)

            GlassChip(icon: "banknote", title: "Salary", amount: "+€2 400,00", positive: true)
                .offset(x: -70, y: -130)
                .floating(7, period: 4.2, phase: 1)

            GlassChip(icon: "house", title: "Rent", amount: "−€950,00", positive: false)
                .offset(x: 80, y: 128)
                .floating(6, period: 3.6, phase: 2)
        }
        .scaleEffect(isActive ? 1 : 0.92)
        .opacity(isActive ? 1 : 0.4)
        .animation(Motion.gentle, value: isActive)
    }
}

private struct MiniBars: View {
    private let values: [CGFloat] = [0.35, 0.55, 0.4, 0.7, 0.5, 0.85, 0.65, 1.0]

    var body: some View {
        HStack(alignment: .bottom, spacing: 7) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(index == values.count - 1 ? AnyShapeStyle(LinearGradient.accentSheen) : AnyShapeStyle(Color.white.opacity(0.16)))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46 * value)
            }
        }
    }
}

// MARK: - Slide 2: plan donut

private struct PlanArt: View {
    let isActive: Bool
    @State private var progress: CGFloat = 0

    private let segments: [(Double, UInt32, String)] = [
        (0.6, 0xBCEE29, "house"),
        (0.1, 0x7CD3C0, "sparkles"),
        (0.1, 0x9BA9FF, "chart.line.uptrend.xyaxis"),
        (0.1, 0xFFB86B, "banknote"),
        (0.1, 0xE0A9FF, "creditcard"),
    ]

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 30)
                .frame(width: 210, height: 210)

            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                let start = segments.prefix(index).reduce(0) { $0 + $1.0 }
                Circle()
                    .trim(from: start + 0.006, to: start + segment.0 * progress - 0.006)
                    .stroke(Color(hex: segment.1), style: StrokeStyle(lineWidth: 30, lineCap: .butt))
                    .frame(width: 210, height: 210)
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("60%")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appOnInk)
                Text("Essentials")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.appOnInkMuted)
            }

            GlassChip(icon: "chart.line.uptrend.xyaxis", title: "Investing", amount: "€303,00", positive: true)
                .offset(x: 85, y: -125)
                .floating(6, period: 4, phase: 0.5)

            GlassChip(icon: "banknote", title: "Savings", amount: "€303,00", positive: true)
                .offset(x: -85, y: 128)
                .floating(6, period: 4.6, phase: 1.5)
        }
        .scaleEffect(isActive ? 1 : 0.92)
        .opacity(isActive ? 1 : 0.4)
        .animation(Motion.gentle, value: isActive)
        .onChange(of: isActive, initial: true) { _, active in
            if active {
                progress = 0
                withAnimation(.easeOut(duration: 0.7).delay(0.05)) { progress = 1 }
            }
        }
    }
}

// MARK: - Slide 3: privacy shield

private struct PrivacyArt: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                PulseRing(delay: Double(ring) * 1.0)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(LinearGradient.inkSurface)
                    .frame(width: 128, height: 128)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.appAccent.opacity(0.45), radius: 40)
                Image(systemName: "faceid")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(LinearGradient.accentSheen)
            }
            .floating(5, period: 4.5)

            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("Stored on device")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color.appOnAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(LinearGradient.accentSheen))
            .shadow(color: Color.appAccent.opacity(0.4), radius: 14, y: 6)
            .offset(y: 118)
            .floating(4, period: 3.8, phase: 1)
        }
        .scaleEffect(isActive ? 1 : 0.92)
        .opacity(isActive ? 1 : 0.4)
        .animation(Motion.gentle, value: isActive)
    }
}

/// One expanding, fading ring. Runs as a repeating Core Animation.
private struct PulseRing: View {
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false

    var body: some View {
        Circle()
            .stroke(Color.appAccent.opacity(0.5), lineWidth: 1.5)
            .frame(width: 120, height: 120)
            .scaleEffect(isExpanded ? 2.6 : 1)
            .opacity(reduceMotion ? 0.25 : (isExpanded ? 0 : 1))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false).delay(delay)) {
                    isExpanded = true
                }
            }
    }
}
