// FloatingTabBar.swift
// Purpose: Frosted floating capsule nav bar with 3 equal slots, a lime pill that
// slides between tabs (matchedGeometryEffect) and a bouncy symbol on selection.

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case tracker = "Tracker"
    case budget = "Budget"
    case settings = "Settings"

    var id: String { rawValue }

    var filledIconName: String {
        switch self {
        case .tracker: "chart.bar.fill"
        case .budget: "chart.pie.fill"
        case .settings: "gearshape.fill"
        }
    }

    var outlineIconName: String {
        switch self {
        case .tracker: "chart.bar"
        case .budget: "chart.pie"
        case .settings: "gearshape"
        }
    }

    var label: String {
        switch self {
        case .tracker: "Home"
        case .budget: "Budget"
        case .settings: "Settings"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var animation

    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradient fade above the bar so content dissolves underneath it
            LinearGradient(
                colors: [Color.appBackground.opacity(0), Color.appBackground.opacity(0.9), Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 110)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)

            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selection == tab,
                        selection: $selection,
                        namespace: animation,
                        reduceMotion: reduceMotion
                    )
                }
            }
            .padding(7)
            .frame(height: Layout.floatingBarHeight)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(Color.appSurface.opacity(colorScheme == .dark ? 0.55 : 0.7)))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.12), radius: 20, x: 0, y: 10)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(colorScheme == .dark ? 0.14 : 0.8), Color.appHairline],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .frame(height: Layout.floatingBarHeight + 46)
    }
}

// MARK: - Tab Button (Equal Width Slots)

private struct TabButton: View {
    let tab: AppTab
    let isSelected: Bool
    @Binding var selection: AppTab
    let namespace: Namespace.ID
    let reduceMotion: Bool

    var body: some View {
        Button {
            guard selection != tab else { return }
            withAnimation(Motion.respecting(reduceMotion, Motion.smooth)) {
                selection = tab
            }
            Haptics.tap()
        } label: {
            ZStack {
                if isSelected {
                    Capsule()
                        .fill(LinearGradient.accentSheen)
                        .shadow(color: Color.appAccent.opacity(0.45), radius: 10, x: 0, y: 4)
                        .matchedGeometryEffect(id: "activeTab", in: namespace)
                }

                HStack(spacing: 6) {
                    Image(systemName: isSelected ? tab.filledIconName : tab.outlineIconName)
                        .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? Color.appOnAccent : Color.appTextSecondary)
                        .symbolEffect(.bounce, value: isSelected && !reduceMotion)

                    if isSelected {
                        Text(tab.label)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.appOnAccent)
                            .lineLimit(1)
                            .fixedSize()
                            .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
                    }
                }
                .padding(.horizontal, isSelected ? 14 : 0)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
}
