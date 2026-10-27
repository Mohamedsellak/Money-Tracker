// IconPicker.swift
// Purpose: Horizontal row of tinted SF Symbol chips for picking an icon, plus a
// generic text chip row used for category suggestions.

import SwiftUI

struct IconChipRow: View {
    @Binding var selection: String
    let options: [String]
    var tint: Color? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(options, id: \.self) { icon in
                    IconChip(
                        iconName: icon,
                        tint: tint ?? CategoryTint.color(for: icon),
                        isSelected: selection == icon
                    ) {
                        withAnimation(Motion.snappy) { selection = icon }
                        Haptics.tap()
                    }
                }
            }
            .horizontalMargin()
            .padding(.vertical, 4)
        }
    }
}

private struct IconChip: View {
    let iconName: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isSelected ? Color.appOnAccent : Color.appTextPrimary)
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? tint : tint.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isSelected ? Color.appTextPrimary.opacity(0.85) : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isSelected ? 1.04 : 1)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(iconName.replacingOccurrences(of: ".", with: " "))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct TextChipRow: View {
    @Binding var selection: String
    let options: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selection.caseInsensitiveCompare(option) == .orderedSame
                    Button {
                        withAnimation(Motion.snappy) { selection = isSelected ? "" : option }
                        Haptics.tap()
                    } label: {
                        Text(option)
                            .font(AppFont.captionStrong)
                            .foregroundColor(isSelected ? Color.appOnAccent : Color.appTextPrimary)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(Capsule().fill(isSelected ? Color.appAccent : Color.appSurface))
                            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Color.appHairline, lineWidth: 1))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .horizontalMargin()
        }
    }
}

/// Small caption label above a form field.
struct FieldLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(AppFont.eyebrow)
            .tracking(1.1)
            .foregroundColor(Color.appTextSecondary)
    }
}

/// Rounded text field used across sheets.
struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool = false

    var body: some View {
        TextField(placeholder, text: $text)
            .font(AppFont.bodyMedium)
            .foregroundColor(Color.appTextPrimary)
            .padding(.horizontal, Spacing.md)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(isFocused ? Color.appAccentDeep : Color.appHairline, lineWidth: isFocused ? 1.5 : 1)
            )
            .animation(Motion.snappy, value: isFocused)
    }
}
