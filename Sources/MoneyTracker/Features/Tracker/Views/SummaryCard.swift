// SummaryCard.swift
// Purpose: Graphite "metal card" hero with the balance (cents set smaller),
// a hide-balances toggle, a savings-rate meter, and Income / Expenses tiles.

import SwiftUI

struct SummaryCard: View {
    let balance: Decimal
    let income: Decimal
    let expenses: Decimal
    let savingsRate: Double?
    let currencyCode: String
    @Binding var isHidden: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isNegative: Bool { balance < 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isNegative ? Color.appInkNegative : Color.appAccent)
                        .frame(width: 7, height: 7)
                        .shadow(color: isNegative ? Color.appInkNegative : Color.appAccent, radius: 4)
                    Text(isNegative ? "Overspent this month" : "Balance this month")
                        .font(AppFont.caption)
                        .foregroundColor(Color.appOnInkMuted)
                }

                Spacer()

                Button {
                    Haptics.tap()
                    withAnimation(Motion.respecting(reduceMotion, Motion.snappy)) { isHidden.toggle() }
                } label: {
                    Image(systemName: isHidden ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.appOnInk)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(isHidden ? "Show balances" : "Hide balances")
            }

            BalanceText(value: balance, currencyCode: currencyCode, isNegative: isNegative)
                .masked(isHidden)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Balance")
                .accessibilityValue(isHidden ? "Hidden" : MoneyFormatter.amount(balance, currencyCode: currencyCode))

            if let savingsRate {
                SavingsMeter(rate: savingsRate, isNegative: isNegative)
            }

            HStack(spacing: Spacing.sm) {
                StatTile(icon: "arrow.down.left", label: "Income", amount: income, currencyCode: currencyCode, tint: Color.appAccent, isHidden: isHidden)
                StatTile(icon: "arrow.up.right", label: "Expenses", amount: expenses, currencyCode: currencyCode, tint: Color(hex: 0xFFB86B), isHidden: isHidden)
            }
        }
        .padding(22)
        .inkCard()
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Balance text (big whole part, small cents)

private struct BalanceText: View {
    let value: Decimal
    let currencyCode: String
    let isNegative: Bool

    private var parts: (head: String, tail: String) {
        let formatted = MoneyFormatter.amount(abs(value), currencyCode: currencyCode)
        let separator = Locale.current.decimalSeparator ?? "."
        guard let range = formatted.range(of: separator, options: .backwards) else {
            return (formatted, "")
        }
        return (String(formatted[..<range.lowerBound]), String(formatted[range.lowerBound...]))
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if isNegative {
                Text("−")
                    .font(AppFont.balance)
                    .foregroundColor(Color.appInkNegative)
            }
            Text(parts.head)
                .font(AppFont.balance)
                .foregroundColor(isNegative ? Color.appInkNegative : Color.appOnInk)
                .contentTransition(.numericText(value: value.doubleValue))
            Text(parts.tail)
                .font(.system(size: 26, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundColor(Color.appOnInkMuted)
                .contentTransition(.numericText(value: value.doubleValue))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .animation(Motion.numeric, value: value)
    }
}

// MARK: - Savings meter

private struct SavingsMeter: View {
    let rate: Double
    let isNegative: Bool

    @State private var shown: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(isNegative ? "Spending exceeds income" : "You keep \(Int((rate * 100).rounded()))% of your income")
                    .font(AppFont.caption)
                    .foregroundColor(Color.appOnInkMuted)
                Spacer()
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(isNegative ? AnyShapeStyle(Color.appInkNegative) : AnyShapeStyle(LinearGradient.accentSheen))
                        .frame(width: max(6, proxy.size.width * (isNegative ? 1 : shown)))
                        .shadow(color: Color.appAccent.opacity(isNegative ? 0 : 0.6), radius: 6)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
        .onAppear { animate(to: rate) }
        .onChange(of: rate) { _, newValue in animate(to: newValue) }
    }

    private func animate(to value: Double) {
        withAnimation(Motion.respecting(reduceMotion, .easeOut(duration: 0.55))) { shown = value }
    }
}

// MARK: - Stat tile

private struct StatTile: View {
    let icon: String
    let label: String
    let amount: Decimal
    let currencyCode: String
    let tint: Color
    let isHidden: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.appOnAccent)
                .frame(width: 28, height: 28)
                .background(Circle().fill(tint))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFont.micro)
                    .foregroundColor(Color.appOnInkMuted)
                Text(MoneyFormatter.amount(amount, currencyCode: currencyCode))
                    .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundColor(Color.appOnInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: amount.doubleValue))
                    .animation(Motion.numeric, value: amount)
                    .masked(isHidden)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(isHidden ? "Hidden" : MoneyFormatter.amount(amount, currencyCode: currencyCode))
    }
}
