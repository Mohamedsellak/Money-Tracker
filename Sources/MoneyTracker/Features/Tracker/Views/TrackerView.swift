// TrackerView.swift
// Purpose: Home screen: personal greeting, graphite balance card, insight tiles,
// Income / Expenses switcher, grouped swipe-to-delete rows and an undo toast.

import SwiftUI

struct TrackerView: View {
    @Environment(TrackerStore.self) private var store
    @Environment(SettingsStore.self) private var settings
    @Environment(AuthStore.self) private var auth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedKind: TransactionKind = .expense
    @State private var selectedItem: TransactionItem? = nil
    @State private var showingAddSheet = false
    @State private var openRowID: UUID? = nil

    // Undo toast state
    @State private var deleted: (item: TransactionItem, index: Int)? = nil
    @State private var toastTask: Task<Void, Never>? = nil

    @Namespace private var segmentNamespace

    private var currencyCode: String { settings.currencyCode }

    private var hideBalances: Binding<Bool> {
        Binding(get: { settings.hideBalances }, set: { settings.hideBalances = $0 })
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    greetingHeader
                        .appearLift(0)

                    SummaryCard(
                        balance: store.balance,
                        income: store.totalIncome,
                        expenses: store.totalExpenses,
                        savingsRate: store.savingsRate,
                        currencyCode: currencyCode,
                        isHidden: hideBalances
                    )
                    .horizontalMargin()
                    .padding(.bottom, Spacing.md)
                    .appearLift(1)

                    InsightsRow(
                        balance: store.balance,
                        topExpense: store.topExpense,
                        totalExpenses: store.totalExpenses,
                        currencyCode: currencyCode,
                        isHidden: settings.hideBalances
                    )
                    .horizontalMargin()
                    .padding(.bottom, Spacing.xl)
                    .appearLift(2)

                    HStack {
                        Text("Transactions")
                            .font(AppFont.headline)
                            .foregroundColor(Color.appTextPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Text("\(store.items(for: selectedKind).count) items")
                            .font(AppFont.caption)
                            .foregroundColor(Color.appTextSecondary)
                            .contentTransition(.numericText())
                    }
                    .horizontalMargin()
                    .padding(.bottom, Spacing.sm)

                    CustomSegmentedControl(selection: $selectedKind, namespace: segmentNamespace)
                        .horizontalMargin()
                        .padding(.bottom, Spacing.md)

                    itemsSection
                        .appearLift(3)
                }
                .padding(.bottom, Spacing.floatingBarClearance)
            }
            .scrollIndicators(.hidden)

            if let deleted {
                UndoToastView(itemName: deleted.item.trimmedName) {
                    undoDelete()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 104)
                .zIndex(100)
            }
        }
        .screenBackground()
        .sheet(isPresented: $showingAddSheet) {
            AddEditItemSheet(
                store: store,
                currencyCode: currencyCode,
                kind: selectedKind
            )
        }
        .sheet(item: $selectedItem) { item in
            AddEditItemSheet(
                store: store,
                currencyCode: currencyCode,
                kind: item.kind,
                existingItem: item
            )
        }
    }

    // MARK: - Header

    private var greetingHeader: some View {
        HStack(spacing: Spacing.sm) {
            AvatarView(name: auth.displayName, size: 44)

            VStack(alignment: .leading, spacing: 1) {
                Text(auth.greeting)
                    .font(AppFont.caption)
                    .foregroundColor(Color.appTextSecondary)
                Text(auth.firstName.isEmpty ? "Welcome" : auth.firstName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer()

            CircleIconButton(iconName: "plus", accessibilityLabel: "Add transaction", isAccent: true) {
                showingAddSheet = true
            }
        }
        .horizontalMargin()
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Items

    @ViewBuilder
    private var itemsSection: some View {
        let items = store.items(for: selectedKind)
        let total = store.total(for: selectedKind)

        if items.isEmpty {
            TrackerEmptyStateView(kind: selectedKind) {
                showingAddSheet = true
            }
            .horizontalMargin()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    SwipeToDeleteRow(
                        rowID: item.id,
                        openRowID: $openRowID,
                        content: {
                            ItemRow(
                                item: item,
                                currencyCode: currencyCode,
                                share: total > 0 ? (item.amount / total).doubleValue : nil,
                                isHidden: settings.hideBalances,
                                onTap: { selectedItem = item }
                            )
                        },
                        onDelete: { delete(item) }
                    )

                    if index < items.count - 1 {
                        Rectangle()
                            .fill(Color.appHairline)
                            .frame(height: 1)
                            .padding(.leading, Spacing.md + Layout.rowIconSize + Spacing.md)
                    }
                }

                TotalRow(
                    title: "Total \(selectedKind.title.lowercased())",
                    amount: total,
                    kind: selectedKind,
                    currencyCode: currencyCode,
                    isHidden: settings.hideBalances
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .surfaceCard()
            .horizontalMargin()
            .id(selectedKind)
            .transition(.opacity)

            Button {
                Haptics.tap()
                showingAddSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.appOnAccent, Color.appAccent)
                    Text("Add \(selectedKind.singularTitle.lowercased())")
                        .font(AppFont.button)
                        .foregroundColor(Color.appTextPrimary)
                }
                .frame(height: Layout.buttonHeight)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .strokeBorder(Color.appBorder, style: StrokeStyle(lineWidth: 1.2, dash: [6, 5]))
                )
            }
            .buttonStyle(.pressable)
            .horizontalMargin()
            .padding(.top, Spacing.md)
        }
    }

    private func delete(_ item: TransactionItem) {
        let index = store.index(of: item) ?? 0
        withAnimation(Motion.respecting(reduceMotion, Motion.smooth)) {
            store.delete(item)
            deleted = (item, index)
        }
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(Motion.smooth) { deleted = nil }
        }
    }

    private func undoDelete() {
        guard let deleted else { return }
        toastTask?.cancel()
        withAnimation(Motion.respecting(reduceMotion, Motion.smooth)) {
            store.restore(deleted.item, at: deleted.index)
            self.deleted = nil
        }
        Haptics.success()
    }
}

// MARK: - Insights

private struct InsightsRow: View {
    let balance: Decimal
    let topExpense: TransactionItem?
    let totalExpenses: Decimal
    let currencyCode: String
    let isHidden: Bool

    /// Days left in the current month, including today.
    private var daysLeft: Int {
        let calendar = Calendar.current
        let now = Date.now
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return 1 }
        return max(1, range.count - calendar.component(.day, from: now) + 1)
    }

    private var perDay: Decimal {
        max(0, balance / Decimal(daysLeft)).rounded(scale: 2)
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            InsightTile(
                icon: "calendar",
                tint: Color(hex: 0x9BA9FF),
                title: "Safe to spend",
                value: MoneyFormatter.amount(perDay, currencyCode: currencyCode),
                caption: "per day · \(daysLeft) days left",
                isHidden: isHidden
            )

            if let topExpense {
                let share = totalExpenses > 0 ? Int(((topExpense.amount / totalExpenses).doubleValue * 100).rounded()) : 0
                InsightTile(
                    icon: topExpense.iconName,
                    tint: CategoryTint.color(for: topExpense.iconName),
                    title: "Top spend",
                    value: topExpense.trimmedName,
                    caption: "\(share)% of expenses",
                    isHidden: false
                )
            } else {
                InsightTile(
                    icon: "leaf",
                    tint: Color(hex: 0x7CD3C0),
                    title: "Top spend",
                    value: "Nothing yet",
                    caption: "No expenses logged",
                    isHidden: false
                )
            }
        }
    }
}

private struct InsightTile: View {
    let icon: String
    let tint: Color
    let title: String
    let value: String
    let caption: String
    let isHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 8) {
                IconTile(iconName: icon, tint: tint, size: 30)
                Text(title)
                    .font(AppFont.captionStrong)
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 19, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .masked(isHidden)
                Text(caption)
                    .font(AppFont.micro)
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard(cornerRadius: Radius.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isHidden ? "Hidden, \(caption)" : "\(value), \(caption)")
    }
}

// MARK: - Custom Segmented Control

private struct CustomSegmentedControl: View {
    @Binding var selection: TransactionKind
    let namespace: Namespace.ID
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TransactionKind.allCases) { kind in
                Button {
                    guard selection != kind else { return }
                    withAnimation(Motion.respecting(reduceMotion, Motion.smooth)) {
                        selection = kind
                    }
                    Haptics.tap()
                } label: {
                    ZStack {
                        if selection == kind {
                            Capsule()
                                .fill(Color.appSurface)
                                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                                .matchedGeometryEffect(id: "segment", in: namespace)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: kind.sectionIconName)
                                .font(.system(size: 12, weight: .bold))
                            Text(kind.title)
                                .font(AppFont.bodyStrong)
                        }
                        .foregroundColor(selection == kind ? Color.appTextPrimary : Color.appTextSecondary)
                    }
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == kind ? [.isSelected] : [])
            }
        }
        .padding(4)
        .frame(height: Layout.segmentedHeight)
        .background(Capsule().fill(Color.appSurfaceMuted))
    }
}

// MARK: - Total Row

private struct TotalRow: View {
    let title: String
    let amount: Decimal
    let kind: TransactionKind
    let currencyCode: String
    let isHidden: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.captionStrong)
                .foregroundColor(Color.appTextSecondary)
            Spacer()
            AmountText(
                amount: amount,
                kind: kind,
                currencyCode: currencyCode,
                font: AppFont.headline
            )
            .contentTransition(.numericText(value: amount.doubleValue))
            .animation(Motion.numeric, value: amount)
            .masked(isHidden)
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 54)
        .background(Color.appSurfaceMuted.opacity(0.6))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Empty State

private struct TrackerEmptyStateView: View {
    let kind: TransactionKind
    let action: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.18))
                    .frame(width: 96, height: 96)
                Circle()
                    .strokeBorder(Color.appAccent.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 124, height: 124)
                Image(systemName: kind == .income ? "banknote" : "cart")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(Color.appTextPrimary)
            }
            .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text("No \(kind.title.lowercased()) yet")
                    .font(AppFont.headline)
                    .foregroundColor(Color.appTextPrimary)

                Text(kind == .income
                     ? "Add your salary or side income to see your balance come alive."
                     : "Log rent, groceries or subscriptions to see where your money goes.")
                    .font(AppFont.body)
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton("Add \(kind.singularTitle.lowercased())", iconName: "plus") {
                Haptics.tap()
                action()
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .surfaceCard()
    }
}

// MARK: - Undo Toast View

private struct UndoToastView: View {
    let itemName: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "trash.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.appOnInkMuted)

            Text("Deleted \u{201C}\(itemName)\u{201D}")
                .font(AppFont.captionStrong)
                .foregroundColor(Color.appOnInk)
                .lineLimit(1)

            Spacer()

            Button(action: onUndo) {
                Text("Undo")
                    .font(AppFont.captionStrong)
                    .foregroundColor(Color.appOnAccent)
                    .padding(.horizontal, 14)
                    .frame(height: 32)
                    .background(Capsule().fill(Color.appAccent))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
        .padding(.leading, Spacing.lg)
        .padding(.trailing, Spacing.sm)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.appInk)
                .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 6)
        )
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
        .horizontalMargin()
        .accessibilityElement(children: .contain)
    }
}
