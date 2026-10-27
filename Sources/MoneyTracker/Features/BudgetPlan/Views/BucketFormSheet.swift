// BucketFormSheet.swift
// Purpose: One sheet to add or edit a budget bucket: name, colour, icon and a
// percentage slider capped at what is still free, with the live monthly amount.

import SwiftUI

struct BucketFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let budgetStore: BudgetStore
    let income: Decimal
    let currencyCode: String
    let existing: BudgetBucket?

    @State private var name: String
    @State private var iconName: String
    @State private var colorHex: UInt32
    @State private var percentage: Double
    @State private var showingDeleteConfirm = false
    @FocusState private var isNameFocused: Bool

    private static let icons = [
        "house", "cart", "fork.knife", "dumbbell", "bus", "wifi",
        "banknote", "chart.line.uptrend.xyaxis", "creditcard",
        "sparkles", "gift", "laptopcomputer", "bag", "heart", "airplane", "circle.grid.2x2",
    ]

    init(budgetStore: BudgetStore, income: Decimal, currencyCode: String, bucket: BudgetBucket? = nil) {
        self.budgetStore = budgetStore
        self.income = income
        self.currencyCode = currencyCode
        self.existing = bucket

        let usedColors = Set(budgetStore.buckets.map(\.colorHex))
        let freeColor = BucketPalette.options.first { !usedColors.contains($0) } ?? BucketPalette.colorHex(at: budgetStore.buckets.count)
        let free = max(0, budgetStore.unallocatedPercentage)

        _name = State(initialValue: bucket?.name ?? "")
        _iconName = State(initialValue: bucket?.iconName ?? "circle.grid.2x2")
        _colorHex = State(initialValue: bucket?.colorHex ?? freeColor)
        _percentage = State(initialValue: Double(bucket?.percentage ?? min(10, free)))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNameTaken: Bool {
        !trimmedName.isEmpty && !budgetStore.isNameUnique(trimmedName, excludingID: existing?.id)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && !isNameTaken
    }

    /// The most this bucket can take without pushing the plan over 100%.
    private var maxAllowed: Int {
        if let existing {
            return budgetStore.maximumPercentage(for: existing.id)
        }
        return max(0, budgetStore.unallocatedPercentage)
    }

    private var monthlyAmount: Decimal {
        (income * Decimal(Int(percentage)) / 100).rounded(scale: 2)
    }

    private var color: Color { Color(hex: colorHex) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    preview

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        FieldLabel(text: "Name")
                        FormTextField(placeholder: "e.g. Travel, Emergency fund", text: $name, isFocused: isNameFocused)
                            .focused($isNameFocused)
                            .submitLabel(.done)
                        if isNameTaken {
                            Label("A bucket with this name already exists", systemImage: "exclamationmark.circle.fill")
                                .font(AppFont.caption)
                                .foregroundColor(Color.appNegative)
                        }
                    }
                    .horizontalMargin()

                    allocation
                        .horizontalMargin()

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        FieldLabel(text: "Colour")
                            .horizontalMargin()
                        ColorSwatchRow(selection: $colorHex)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        FieldLabel(text: "Icon")
                            .horizontalMargin()
                        IconChipRow(selection: $iconName, options: Self.icons, tint: color)
                    }

                    if existing != nil && budgetStore.buckets.count > 1 {
                        Button {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete bucket", systemImage: "trash")
                                .font(AppFont.button)
                                .foregroundColor(Color.appNegative)
                                .frame(height: Layout.buttonHeight)
                                .frame(maxWidth: .infinity)
                                .background(Capsule().fill(Color.appNegative.opacity(0.1)))
                        }
                        .buttonStyle(.pressable)
                        .horizontalMargin()
                    }
                }
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground)
            .navigationTitle(existing == nil ? "New bucket" : "Edit bucket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.appTextSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(existing == nil ? "Add bucket" : "Save changes", iconName: "checkmark", isEnabled: isValid) {
                    save()
                }
                .horizontalMargin()
                .padding(.vertical, Spacing.sm)
                .background(Color.appBackground.opacity(0.95).ignoresSafeArea())
            }
            .onAppear {
                if existing == nil { isNameFocused = true }
            }
            .confirmationDialog("Delete this bucket?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let existing {
                        withAnimation(Motion.smooth) { budgetStore.delete(existing) }
                        Haptics.warning()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Its \(Int(percentage))% goes back to unallocated.")
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.hero)
        .presentationBackground(Color.appBackground)
    }

    // MARK: - Sections

    private var preview: some View {
        HStack(spacing: Spacing.md) {
            IconTile(iconName: iconName, tint: color, size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(trimmedName.isEmpty ? "New bucket" : trimmedName)
                    .font(AppFont.headline)
                    .foregroundColor(trimmedName.isEmpty ? Color.appTextSecondary : Color.appTextPrimary)
                    .lineLimit(1)
                Text("\(MoneyFormatter.amount(monthlyAmount, currencyCode: currencyCode)) / month")
                    .font(AppFont.caption)
                    .foregroundColor(Color.appTextSecondary)
                    .contentTransition(.numericText(value: monthlyAmount.doubleValue))
            }
            Spacer()
        }
        .padding(Spacing.md)
        .surfaceCard(cornerRadius: Radius.lg)
        .horizontalMargin()
        .animation(Motion.snappy, value: colorHex)
        .animation(Motion.snappy, value: iconName)
    }

    private var allocation: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FieldLabel(text: "Allocation")

            HStack {
                StepButton(icon: "minus", isAccent: false) {
                    percentage = max(0, percentage - 5)
                }
                .disabled(percentage <= 0)

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(Color.appTextPrimary)
                    .contentTransition(.numericText(value: percentage))
                    .animation(Motion.snappy, value: percentage)

                Spacer()

                StepButton(icon: "plus", isAccent: true) {
                    percentage = min(Double(maxAllowed), percentage + 5)
                }
                .disabled(Int(percentage) >= maxAllowed)
            }

            if maxAllowed > 0 {
                Slider(value: $percentage, in: 0...Double(maxAllowed), step: 1)
                    .tint(color)
                    .accessibilityLabel("Allocation percentage")
                    .accessibilityValue("\(Int(percentage)) percent")
            }

            HStack(spacing: 6) {
                Image(systemName: maxAllowed == 0 ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    .foregroundColor(maxAllowed == 0 ? Color.appNegative : Color.appTextMuted)
                Text(maxAllowed == 0
                     ? "Your plan is full. Lower another bucket first."
                     : "Up to \(maxAllowed)% available without going over 100%")
                    .foregroundColor(maxAllowed == 0 ? Color.appNegative : Color.appTextSecondary)
            }
            .font(AppFont.caption)
        }
        .padding(Spacing.lg)
        .surfaceCard()
    }

    private func save() {
        guard isValid else { return }
        let value = min(Int(percentage), maxAllowed)
        if var updated = existing {
            updated.name = trimmedName
            updated.iconName = iconName
            updated.colorHex = colorHex
            updated.percentage = value
            withAnimation(Motion.smooth) { budgetStore.update(updated) }
        } else {
            let bucket = BudgetBucket(name: trimmedName, iconName: iconName, percentage: value, colorHex: colorHex)
            withAnimation(Motion.smooth) { budgetStore.add(bucket) }
        }
        Haptics.success()
        dismiss()
    }
}

// MARK: - Pieces

private struct StepButton: View {
    let icon: String
    let isAccent: Bool
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isAccent ? Color.appOnAccent : Color.appTextPrimary)
                .frame(width: 48, height: 48)
                .background(Circle().fill(isAccent ? AnyShapeStyle(LinearGradient.accentSheen) : AnyShapeStyle(Color.appSurfaceMuted)))
                .opacity(isEnabled ? 1 : 0.35)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(icon == "plus" ? "Increase by 5 percent" : "Decrease by 5 percent")
    }
}

private struct ColorSwatchRow: View {
    @Binding var selection: UInt32

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(BucketPalette.options, id: \.self) { hex in
                    let isSelected = selection == hex
                    Button {
                        withAnimation(Motion.snappy) { selection = hex }
                        Haptics.tap()
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.4), radius: 2)
                                    .opacity(isSelected ? 1 : 0)
                            )
                            .padding(4)
                            .overlay(Circle().strokeBorder(isSelected ? Color.appTextPrimary : Color.clear, lineWidth: 2))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Colour \(BucketPalette.options.firstIndex(of: hex).map { $0 + 1 } ?? 0)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .horizontalMargin()
        }
    }
}
