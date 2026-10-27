// SectionHeader.swift
// Purpose: A standardised header for the INCOME and EXPENSES sections, with an
// icon, title and a "Add" button.

import SwiftUI

struct SectionHeader: View {
    let iconName: String
    let title: String
    let addAction: (() -> Void)?

    init(iconName: String, title: String, addAction: (() -> Void)? = nil) {
        self.iconName = iconName
        self.title = title
        self.addAction = addAction
    }

    var body: some View {
        HStack {
            HStack(spacing: Spacing.sm) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appTextSecondary)

                Text(title)
                    .font(AppFont.headline)
                    .foregroundColor(Color.appTextPrimary)
            }

            Spacer()

            if let addAction {
                Button(action: {
                    Haptics.tap()
                    addAction()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.appAccent)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Add \(title)")
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(height: Layout.minTouchTarget)
    }
}

#Preview {
    VStack(spacing: 0) {
        SectionHeader(
            iconName: "arrow.down.left",
            title: "Income",
            addAction: { print("Add income") }
        )

        Divider()
            .padding(.horizontal)

        SectionHeader(
            iconName: "arrow.up.right",
            title: "Expenses"
        )
    }
    .padding()
    .cardStyle()
}