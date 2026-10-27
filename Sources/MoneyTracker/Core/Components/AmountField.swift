// AmountField.swift
// Purpose: A decimal text field with a currency symbol and a numeric keyboard.

import SwiftUI

struct AmountField: View {
    @Binding var amount: Decimal?
    let currencySymbol: String
    let placeholder: String

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(currencySymbol)
                    .font(AppFont.numberLarge)
                    .foregroundColor(Color.appTextSecondary)

                TextField(placeholder, text: $text)
                    .font(AppFont.numberLarge)
                    .foregroundColor(amount != nil ? Color.appTextPrimary : Color.appTextSecondary)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onChange(of: text) { _, newValue in
                        let cleaned = AmountInputSanitizer.clean(newValue)
                        if cleaned != newValue {
                            text = cleaned
                        }
                        amount = MoneyFormatter.parse(cleaned)
                    }
                    .onAppear {
                        if let amount = amount, amount != 0 {
                            text = MoneyFormatter.editableString(amount)
                        }
                    }
                    .onTapGesture {
                        if isFocused && text.isEmpty {
                            text = "0"
                            amount = 0
                        }
                    }
            }

            Rectangle()
                .fill(Color.appHairline)
                .frame(height: 1)
        }
        .padding(.vertical, Spacing.sm)
        .onDisappear {
            if amount == 0 && text.isEmpty {
                amount = nil
            }
        }
    }
}