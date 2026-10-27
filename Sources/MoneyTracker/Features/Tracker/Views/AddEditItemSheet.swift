// AddEditItemSheet.swift
// Purpose: Bottom sheet to add or edit a transaction: income/expense switch,
// giant centered amount, name, category suggestions, icon chips, and delete.

import SwiftUI

struct AddEditItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let store: TrackerStore
    let currencyCode: String
    let existingItem: TransactionItem?

    @State private var kind: TransactionKind
    @State private var name: String
    @State private var amountText: String
    @State private var iconName: String
    @State private var category: String
    @State private var showingDeleteConfirm = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, amount, category
    }

    init(
        store: TrackerStore,
        currencyCode: String,
        kind: TransactionKind,
        existingItem: TransactionItem? = nil
    ) {
        self.store = store
        self.currencyCode = currencyCode
        self.existingItem = existingItem

        _kind = State(initialValue: existingItem?.kind ?? kind)
        _name = State(initialValue: existingItem?.name ?? "")
        if let amount = existingItem?.amount {
            _amountText = State(initialValue: MoneyFormatter.editableString(amount))
        } else {
            _amountText = State(initialValue: "")
        }
        _iconName = State(initialValue: existingItem?.iconName ?? kind.defaultIcons[0])
        _category = State(initialValue: existingItem?.category ?? "")
    }

    private var parsedAmount: Decimal? {
        MoneyFormatter.parse(amountText)
    }

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (parsedAmount ?? 0) <= 0
    }

    private func save() {
        guard !isSaveDisabled else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)

        let item = TransactionItem(
            id: existingItem?.id ?? UUID(),
            name: trimmedName,
            amount: parsedAmount ?? 0,
            kind: kind,
            iconName: iconName,
            category: trimmedCategory.isEmpty ? nil : trimmedCategory,
            createdAt: existingItem?.createdAt ?? .now
        )

        withAnimation(Motion.smooth) {
            if existingItem != nil {
                store.update(item)
            } else {
                store.add(item)
            }
        }

        Haptics.success()
        dismiss()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    if existingItem == nil {
                        KindSwitch(selection: $kind)
                            .frame(maxWidth: .infinity)
                            .onChange(of: kind) { _, newKind in
                                if !newKind.defaultIcons.contains(iconName) {
                                    iconName = newKind.defaultIcons[0]
                                }
                            }
                    }

                    amountInput

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        FieldLabel(text: "Name")
                        FormTextField(
                            placeholder: kind == .income ? "e.g. Salary, Freelance" : "e.g. Rent, Groceries",
                            text: $name,
                            isFocused: focusedField == .name
                        )
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = nil }
                    }
                    .horizontalMargin()

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        FieldLabel(text: "Category")
                            .horizontalMargin()
                        TextChipRow(selection: $category, options: kind.suggestedCategories)
                        FormTextField(placeholder: "Or type your own", text: $category, isFocused: focusedField == .category)
                            .focused($focusedField, equals: .category)
                            .submitLabel(.done)
                            .horizontalMargin()
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        FieldLabel(text: "Icon")
                            .horizontalMargin()
                        IconChipRow(selection: $iconName, options: kind.defaultIcons)
                    }

                    if existingItem != nil {
                        Button {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete transaction", systemImage: "trash")
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
            .navigationTitle(existingItem == nil ? "New \(kind.singularTitle.lowercased())" : "Edit \(kind.singularTitle.lowercased())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.appTextSecondary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appTextPrimary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(existingItem == nil ? "Add \(kind.singularTitle.lowercased())" : "Save changes", iconName: "checkmark", isEnabled: !isSaveDisabled) {
                    save()
                }
                .horizontalMargin()
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.sm)
                .background(Color.appBackground.opacity(0.95).ignoresSafeArea())
            }
            .onAppear {
                if existingItem == nil { focusedField = .amount }
            }
            .confirmationDialog("Delete this transaction?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let item = existingItem {
                        withAnimation(Motion.smooth) { store.delete(item) }
                        Haptics.warning()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.hero)
        .presentationBackground(Color.appBackground)
    }

    private var amountInput: some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(kind == .income ? "+" : "−")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(kind == .income ? Color.appPositiveText : Color.appNegative)

                TextField("0", text: $amountText)
                    .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .foregroundColor(Color.appTextPrimary)
                    .fixedSize(horizontal: true, vertical: false)
                    .onChange(of: amountText) { _, newValue in
                        let cleaned = AmountInputSanitizer.clean(newValue)
                        if cleaned != newValue {
                            amountText = cleaned
                        }
                    }

                Text(MoneyFormatter.symbol(for: currencyCode))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(focusedField == .amount ? Color.appAccentDeep : Color.appHairline, lineWidth: focusedField == .amount ? 1.5 : 1)
            )
            .onTapGesture { focusedField = .amount }
            .animation(Motion.snappy, value: focusedField)

            Text(kind == .income ? "Money coming in each month" : "Money going out each month")
                .font(AppFont.caption)
                .foregroundColor(Color.appTextSecondary)
        }
        .horizontalMargin()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Amount")
    }
}

// MARK: - Kind switch

private struct KindSwitch: View {
    @Binding var selection: TransactionKind
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TransactionKind.allCases) { kind in
                Button {
                    withAnimation(Motion.snappy) { selection = kind }
                    Haptics.tap()
                } label: {
                    ZStack {
                        if selection == kind {
                            Capsule()
                                .fill(kind == .income ? AnyShapeStyle(LinearGradient.accentSheen) : AnyShapeStyle(Color.appInk))
                                .matchedGeometryEffect(id: "kind", in: namespace)
                        }
                        Text(kind.singularTitle)
                            .font(AppFont.captionStrong)
                            .foregroundColor(
                                selection == kind
                                    ? (kind == .income ? Color.appOnAccent : Color.appOnInk)
                                    : Color.appTextSecondary
                            )
                    }
                    .frame(width: 104, height: 36)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityAddTraits(selection == kind ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.appSurfaceMuted))
    }
}
