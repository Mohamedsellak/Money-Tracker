// EmptyStateView.swift
// Purpose: Friendly empty states shown when a list is empty, with a large
// SF Symbol and a call to action.

import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?

    init(
        iconName: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: iconName)
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(Color.appTextSecondary)
                .padding(.top, Spacing.section)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(AppFont.title)
                    .foregroundColor(Color.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppFont.body)
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            if let buttonTitle, let buttonAction {
                PrimaryButton(buttonTitle, iconName: "plus") {
                    buttonAction()
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.sm)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        EmptyStateView(
            iconName: "banknote",
            title: "No transactions yet",
            message: "Add your first income or expense to start tracking.",
            buttonTitle: "Add Transaction"
        ) {
            print("Add tapped")
        }

        EmptyStateView(
            iconName: "chart.pie",
            title: "No budget plan",
            message: "Create a plan to allocate your monthly income."
        )
    }
    .screenBackground()
}