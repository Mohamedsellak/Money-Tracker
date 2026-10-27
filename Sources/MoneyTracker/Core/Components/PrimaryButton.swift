// PrimaryButton.swift
// Purpose: The main accent-coloured capsule button ("Continue", "Save", ...)
// plus a quieter secondary variant.

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let iconName: String?
    let action: () -> Void
    let isLoading: Bool
    let isEnabled: Bool

    init(
        _ title: String,
        iconName: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard !isLoading, isEnabled else { return }
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appOnAccent))
                } else if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .bold))
                }

                Text(title)
                    .font(AppFont.button)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.saveButtonHeight)
            .foregroundColor(Color.appOnAccent)
            .background(
                Capsule()
                    .fill(LinearGradient.accentSheen)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.appAccent.opacity(isEnabled ? 0.35 : 0), radius: 14, x: 0, y: 6)
            )
            .opacity(isEnabled ? 1 : 0.35)
        }
        .buttonStyle(.pressable)
        .disabled(isLoading || !isEnabled)
        .accessibilityLabel(isLoading ? "Loading…" : title)
    }
}

struct SecondaryButton: View {
    let title: String
    var iconName: String? = nil
    var tint: Color = .appTextPrimary
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: Spacing.xs) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.button)
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(Capsule().fill(Color.appSurface))
            .overlay(Capsule().strokeBorder(Color.appHairline, lineWidth: 1))
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        PrimaryButton("Add Transaction", iconName: "plus") {}
        PrimaryButton("Saving…", isLoading: true) {}
        SecondaryButton(title: "Not now") {}
    }
    .padding()
}
