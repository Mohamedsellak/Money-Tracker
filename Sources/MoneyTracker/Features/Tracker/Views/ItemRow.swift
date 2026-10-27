// ItemRow.swift
// Purpose: Transaction row: tinted icon tile, title, category subtitle and a
// signed amount. Tapping opens the edit sheet.

import SwiftUI

struct ItemRow: View {
    let item: TransactionItem
    let currencyCode: String
    var share: Double? = nil
    var isHidden: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            onTap()
        }) {
            HStack(spacing: Spacing.md) {
                IconTile(iconName: item.iconName)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.trimmedName)
                        .font(AppFont.bodyStrong)
                        .foregroundColor(Color.appTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if let category = item.displayCategory, category != item.trimmedName {
                            Text(category)
                        } else {
                            Text(item.kind.singularTitle)
                        }
                        if let share {
                            Text("·")
                            Text("\(Int((share * 100).rounded()))%")
                                .monospacedDigit()
                        }
                    }
                    .font(AppFont.caption)
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
                }

                Spacer(minLength: Spacing.xs)

                AmountText(
                    amount: item.amount,
                    kind: item.kind,
                    currencyCode: currencyCode,
                    font: AppFont.number
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .masked(isHidden)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: Layout.rowHeight + 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.trimmedName)
        .accessibilityValue(isHidden ? "Amount hidden" : MoneyFormatter.amount(item.amount, currencyCode: currencyCode))
        .accessibilityHint("Double tap to edit")
        .accessibilityAddTraits(.isButton)
    }
}
