// BucketRow.swift
// Purpose: Bucket row inside the plan card: tinted icon tile, name, share of
// income, monthly amount and an animated progress track. Tap to edit.

import SwiftUI

struct BucketRow: View {
    let bucket: BudgetBucket
    let income: Decimal
    let currencyCode: String
    var isHidden: Bool = false
    let onEdit: () -> Void

    @State private var shown: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var amount: Decimal {
        (income * Decimal(bucket.percentage) / 100).rounded(scale: 2)
    }

    var body: some View {
        Button(action: {
            Haptics.tap()
            onEdit()
        }) {
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.md) {
                    IconTile(iconName: bucket.iconName, tint: bucket.color)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(bucket.trimmedName)
                            .font(AppFont.bodyStrong)
                            .foregroundColor(Color.appTextPrimary)
                            .lineLimit(1)
                        Text("\(bucket.percentage)% of income")
                            .font(AppFont.caption)
                            .foregroundColor(Color.appTextSecondary)
                            .monospacedDigit()
                    }

                    Spacer(minLength: Spacing.xs)

                    Text(MoneyFormatter.amount(amount, currencyCode: currencyCode))
                        .font(AppFont.number)
                        .foregroundColor(Color.appTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .contentTransition(.numericText(value: amount.doubleValue))
                        .masked(isHidden)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.appTextMuted)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appSurfaceMuted)
                        Capsule()
                            .fill(bucket.color)
                            .frame(width: max(0, geometry.size.width * shown))
                    }
                }
                .frame(height: 6)
                .padding(.leading, Layout.rowIconSize + Spacing.md)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear { animate() }
        .onChange(of: bucket.percentage) { _, _ in animate() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bucket.trimmedName)
        .accessibilityValue("\(bucket.percentage) percent, \(isHidden ? "amount hidden" : MoneyFormatter.amount(amount, currencyCode: currencyCode))")
        .accessibilityHint("Double tap to edit")
        .accessibilityAddTraits(.isButton)
    }

    private func animate() {
        withAnimation(Motion.respecting(reduceMotion, .easeOut(duration: 0.5))) {
            shown = CGFloat(bucket.percentage) / 100
        }
    }
}
