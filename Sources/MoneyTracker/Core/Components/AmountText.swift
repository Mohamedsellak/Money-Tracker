// AmountText.swift
// Purpose: Reusable component for displaying amounts with correct sign (using U+2212 for minus),
// currency symbol, monospaced digits, and conditional color based on transaction kind.

import SwiftUI

struct AmountText: View {
    let amount: Decimal
    let kind: TransactionKind
    let currencyCode: String
    var font: Font = AppFont.number

    private var isIncome: Bool { kind == .income }

    var body: some View {
        Text(formattedText)
            .font(font)
            .foregroundColor(textColor)
            .monospacedDigit()
    }

    private var formattedText: String {
        let formattedValue = MoneyFormatter.amount(amount, currencyCode: currencyCode)
        if isIncome {
            return "+\(formattedValue)"
        } else {
            return "−\(formattedValue)" // True minus sign U+2212
        }
    }

    private var textColor: Color {
        if isIncome {
            return Color.appPositiveText
        } else {
            return Color.appNegative
        }
    }
}