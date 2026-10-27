// PrivacyShieldView.swift
// Purpose: Covers the UI while the app is inactive so balances never show up in
// the App Switcher snapshot.

import SwiftUI

struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThickMaterial)
            Color.appInk.opacity(0.75)
            VStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient.accentSheen)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Color.appOnAccent)
                }
                .frame(width: 76, height: 76)
                .shadow(color: Color.appAccent.opacity(0.5), radius: 24)

                Text("MoneyTracker")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appOnInk)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
