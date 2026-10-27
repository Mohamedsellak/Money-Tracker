// PasscodePad.swift
// Purpose: Glass numeric keypad and progress dots shared by the lock screen and
// passcode setup. Designed for the dark aurora backdrop.

import SwiftUI

struct PasscodeDots: View {
    let filled: Int
    var length: Int = PasscodeVault.length
    var isError: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 18) {
            ForEach(0..<length, id: \.self) { index in
                let isFilled = index < filled
                Circle()
                    .fill(isError ? Color.appInkNegative : (isFilled ? Color.appAccent : Color.white.opacity(0.14)))
                    .overlay(Circle().strokeBorder(Color.white.opacity(isFilled ? 0 : 0.28), lineWidth: 1))
                    .frame(width: 14, height: 14)
                    .scaleEffect(isFilled && !reduceMotion ? 1.15 : 1)
                    .shadow(color: isFilled ? Color.appAccent.opacity(0.7) : .clear, radius: 8)
                    .animation(Motion.respecting(reduceMotion, Motion.snappy), value: isFilled)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Passcode")
        .accessibilityValue("\(filled) of \(length) digits entered")
    }
}

enum PadKey: Hashable {
    case digit(Int)
    case delete
    case biometric
}

struct PasscodeKeypad: View {
    var biometricIcon: String? = nil
    var isDisabled: Bool = false
    let onKey: (PadKey) -> Void

    private let rows: [[PadKey?]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.biometric, .digit(0), .delete],
    ]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(0..<rows.count, id: \.self) { row in
                HStack(spacing: 26) {
                    ForEach(0..<3, id: \.self) { column in
                        keyView(rows[row][column])
                    }
                }
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
    }

    @ViewBuilder
    private func keyView(_ key: PadKey?) -> some View {
        switch key {
        case .digit(let number):
            PadButton(label: { Text("\(number)").font(.system(size: 30, weight: .medium, design: .rounded)) }, isGlass: true) {
                onKey(.digit(number))
            }
            .accessibilityLabel("\(number)")
        case .delete:
            PadButton(label: { Image(systemName: "delete.left").font(.system(size: 22, weight: .medium)) }, isGlass: false) {
                onKey(.delete)
            }
            .accessibilityLabel("Delete")
        case .biometric:
            if let biometricIcon {
                PadButton(label: { Image(systemName: biometricIcon).font(.system(size: 26, weight: .medium)) }, isGlass: false) {
                    onKey(.biometric)
                }
                .accessibilityLabel("Use biometrics")
            } else {
                Color.clear.frame(width: PadButton<EmptyView>.size, height: PadButton<EmptyView>.size)
            }
        case nil:
            Color.clear.frame(width: PadButton<EmptyView>.size, height: PadButton<EmptyView>.size)
        }
    }
}

private struct PadButton<Label: View>: View {
    static var size: CGFloat { 76 }

    @ViewBuilder let label: () -> Label
    let isGlass: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            label()
                .foregroundColor(Color.appOnInk)
                .frame(width: Self.size, height: Self.size)
                .background(
                    Circle()
                        .fill(Color.white.opacity(isGlass ? 0.08 : 0))
                        .overlay(Circle().strokeBorder(Color.white.opacity(isGlass ? 0.12 : 0), lineWidth: 1))
                )
                .contentShape(Circle())
        }
        .buttonStyle(PadPressStyle())
    }
}

private struct PadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(Color.appAccent.opacity(configuration.isPressed ? 0.85 : 0))
            )
            .foregroundStyle(configuration.isPressed ? Color.appOnAccent : Color.appOnInk)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Collects digits and reports a full code. Shared state machine for keypads.
struct PasscodeEntry {
    private(set) var digits = ""

    mutating func apply(_ key: PadKey) -> String? {
        switch key {
        case .digit(let number):
            guard digits.count < PasscodeVault.length else { return nil }
            digits.append(String(number))
            return digits.count == PasscodeVault.length ? digits : nil
        case .delete:
            if !digits.isEmpty { digits.removeLast() }
            return nil
        case .biometric:
            return nil
        }
    }

    mutating func reset() {
        digits = ""
    }
}
