// Decimal+Currency.swift
// Purpose: Money formatting and parsing helpers built on Decimal + Foundation.
// Always exactly 2 decimals, grouping separator, currency symbol after the number.

import Foundation

extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    var wholeUnits: Decimal {
        rounded(scale: 0)
    }

    func rounded(scale: Int) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, .plain)
        return result
    }

    var isPositive: Bool { self > 0 }
}

/// Formatters are expensive to create, so each one is built once and reused.
/// Everything that displays money runs on the main actor, which also keeps the
/// non-Sendable NumberFormatter instances on a single thread.
@MainActor
enum MoneyFormatter {
    private static var currencyFormatters: [String: NumberFormatter] = [:]

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let editableFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let parseFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        return formatter
    }()

    /// "1 721,70 €" / "100,00 €" with exact 2 decimals and currency symbol after with non-breaking space.
    static func amount(_ value: Decimal, currencyCode: String) -> String {
        currencyFormatter(currencyCode).string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    static func signedAmount(_ value: Decimal, currencyCode: String, isCredit: Bool) -> String {
        let text = amount(value, currencyCode: currencyCode)
        return isCredit ? "+" + text : text
    }

    static func number(_ value: Decimal) -> String {
        numberFormatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    static func symbol(for currencyCode: String) -> String {
        currencyFormatter(currencyCode).currencySymbol ?? currencyCode
    }

    static func editableString(_ value: Decimal) -> String {
        editableFormatter.string(from: NSDecimalNumber(decimal: value)) ?? ""
    }

    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let number = parseFormatter.number(from: trimmed) {
            return number.decimalValue
        }

        let separator = Locale.current.decimalSeparator ?? "."
        let normalized = trimmed
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: separator)
            .replacingOccurrences(of: ".", with: separator)
        return Decimal(string: normalized, locale: Locale.current)
    }

    private static func currencyFormatter(_ currencyCode: String) -> NumberFormatter {
        if let cached = currencyFormatters[currencyCode] { return cached }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        currencyFormatters[currencyCode] = formatter
        return formatter
    }
}

enum AmountInputSanitizer {
    static func clean(_ input: String) -> String {
        let separator = Locale.current.decimalSeparator ?? "."
        var integerPart = ""
        var fractionPart = ""
        var hasSeparator = false

        for character in input {
            if character.isNumber {
                if hasSeparator {
                    if fractionPart.count < 2 { fractionPart.append(character) }
                } else {
                    if integerPart.count < 9 { integerPart.append(character) }
                }
            } else if character == "." || character == "," {
                guard !hasSeparator else { continue }
                hasSeparator = true
            }
        }

        guard hasSeparator else { return integerPart }
        return integerPart + separator + fractionPart
    }
}