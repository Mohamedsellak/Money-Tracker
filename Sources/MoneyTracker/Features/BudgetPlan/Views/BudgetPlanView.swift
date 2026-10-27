// BudgetPlanView.swift
// Purpose: Budget allocation screen: donut summary with status chip and legend,
// actual-vs-planned Essentials comparison, and the bucket list with add/edit sheets.

import SwiftUI

struct BudgetPlanView: View {
    @Environment(TrackerStore.self) private var trackerStore
    @Environment(BudgetStore.self) private var budgetStore
    @Environment(SettingsStore.self) private var settings

    @State private var showingAddBucket = false
    @State private var editingBucket: BudgetBucket? = nil

    private var monthlyIncome: Decimal {
        trackerStore.totalIncome
    }
    private var currencyCode: String { settings.currencyCode }
    private var canAddBucket: Bool { budgetStore.unallocatedPercentage > 0 }

    /// The bucket that expenses are compared against.
    private var essentialsBucket: BudgetBucket? {
        budgetStore.buckets.first { $0.linkedCategory != nil }
            ?? budgetStore.buckets.first { $0.trimmedName.lowercased() == "essentials" }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HeaderView(
                    title: "Budget",
                    eyebrow: "Monthly plan",
                    actionIcon: "plus",
                    actionAccessibilityLabel: "Add bucket"
                ) {
                    if canAddBucket {
                        showingAddBucket = true
                    } else {
                        Haptics.error()
                    }
                }
                .appearLift(0)

                summaryCard
                    .horizontalMargin()
                    .padding(.bottom, Spacing.md)
                    .appearLift(1)

                if let essentialsBucket {
                    PlanComparisonCard(
                        bucket: essentialsBucket,
                        planned: budgetStore.amount(for: essentialsBucket, income: monthlyIncome),
                        spent: trackerStore.totalExpenses,
                        currencyCode: currencyCode,
                        isHidden: settings.hideBalances
                    )
                    .horizontalMargin()
                    .padding(.bottom, Spacing.xl)
                    .appearLift(2)
                }

                HStack {
                    Text("Buckets")
                        .font(AppFont.headline)
                        .foregroundColor(Color.appTextPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("\(budgetStore.totalPercentage)% of 100%")
                        .font(AppFont.caption)
                        .foregroundColor(budgetStore.isOverAllocated ? Color.appNegative : Color.appTextSecondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .horizontalMargin()
                .padding(.bottom, Spacing.sm)

                VStack(spacing: 0) {
                    ForEach(Array(budgetStore.buckets.enumerated()), id: \.element.id) { index, bucket in
                        BucketRow(
                            bucket: bucket,
                            income: monthlyIncome,
                            currencyCode: currencyCode,
                            isHidden: settings.hideBalances,
                            onEdit: { editingBucket = bucket }
                        )
                        if index < budgetStore.buckets.count - 1 {
                            Rectangle()
                                .fill(Color.appHairline)
                                .frame(height: 1)
                                .padding(.leading, Spacing.md + Layout.rowIconSize + Spacing.md)
                        }
                    }
                }
                .surfaceCard()
                .horizontalMargin()
                .appearLift(3)

                if canAddBucket {
                    SecondaryButton(title: "Add bucket", iconName: "plus") {
                        showingAddBucket = true
                    }
                    .horizontalMargin()
                    .padding(.top, Spacing.md)
                }
            }
            .padding(.bottom, Spacing.floatingBarClearance)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .sheet(isPresented: $showingAddBucket) {
            BucketFormSheet(budgetStore: budgetStore, income: monthlyIncome, currencyCode: currencyCode)
        }
        .sheet(item: $editingBucket) { bucket in
            BucketFormSheet(budgetStore: budgetStore, income: monthlyIncome, currencyCode: currencyCode, bucket: bucket)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                AllocationRing(
                    buckets: budgetStore.buckets,
                    totalPercentage: budgetStore.totalPercentage
                )
                .frame(width: 210, height: 210)

                VStack(spacing: 4) {
                    Text("Monthly income")
                        .font(AppFont.caption)
                        .foregroundColor(Color.appTextSecondary)

                    Text(MoneyFormatter.amount(monthlyIncome, currencyCode: currencyCode))
                        .font(AppFont.numberLarge)
                        .foregroundColor(Color.appTextPrimary)
                        .contentTransition(.numericText(value: monthlyIncome.doubleValue))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .masked(settings.hideBalances)

                    BudgetStatusChip(totalPercentage: budgetStore.totalPercentage)
                        .padding(.top, 4)
                }
                .frame(width: 140)
            }

            if !canAddBucket && !budgetStore.isOverAllocated {
                Text("All of your income has a job. Lower a bucket to add another.")
                    .font(AppFont.caption)
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.lg), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(budgetStore.buckets) { bucket in
                    LegendCell(color: bucket.color, name: bucket.trimmedName, percentage: bucket.percentage, isMuted: false)
                }
                if budgetStore.unallocatedPercentage > 0 {
                    LegendCell(color: Color.appBorder, name: "Unallocated", percentage: budgetStore.unallocatedPercentage, isMuted: true)
                }
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .surfaceCard()
    }
}

// MARK: - Plan comparison

private struct PlanComparisonCard: View {
    let bucket: BudgetBucket
    let planned: Decimal
    let spent: Decimal
    let currencyCode: String
    let isHidden: Bool

    @State private var shown: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var ratio: Double {
        guard planned > 0 else { return spent > 0 ? 1.2 : 0 }
        return (spent / planned).doubleValue
    }
    private var isOver: Bool { spent > planned }
    private var difference: Decimal { abs(planned - spent) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                IconTile(iconName: bucket.iconName, tint: bucket.color, size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Spending vs \(bucket.trimmedName)")
                        .font(AppFont.bodyStrong)
                        .foregroundColor(Color.appTextPrimary)
                    Text("All tracked expenses this month")
                        .font(AppFont.micro)
                        .foregroundColor(Color.appTextSecondary)
                }
                Spacer()
                Text(isOver ? "Over" : "On track")
                    .font(AppFont.captionStrong)
                    .foregroundColor(isOver ? Color.appNegative : Color.appOnAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(isOver ? Color.appNegative.opacity(0.14) : Color.appAccent))
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(MoneyFormatter.amount(spent, currencyCode: currencyCode))
                    .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(Color.appTextPrimary)
                Text("of \(MoneyFormatter.amount(planned, currencyCode: currencyCode))")
                    .font(AppFont.caption)
                    .foregroundColor(Color.appTextSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .masked(isHidden)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.appSurfaceMuted)
                    Capsule()
                        .fill(isOver ? AnyShapeStyle(Color.appNegative) : AnyShapeStyle(LinearGradient.accentSheen))
                        .frame(width: proxy.size.width * min(1, shown))
                }
            }
            .frame(height: 10)

            Text(isOver
                 ? "\(MoneyFormatter.amount(difference, currencyCode: currencyCode)) above plan"
                 : "\(MoneyFormatter.amount(difference, currencyCode: currencyCode)) left in plan")
                .font(AppFont.caption)
                .foregroundColor(isOver ? Color.appNegative : Color.appTextSecondary)
                .masked(isHidden)
        }
        .padding(Spacing.lg)
        .surfaceCard()
        .onAppear { animate() }
        .onChange(of: ratio) { _, _ in animate() }
        .accessibilityElement(children: .combine)
    }

    private func animate() {
        withAnimation(Motion.respecting(reduceMotion, .easeOut(duration: 0.55))) {
            shown = CGFloat(ratio)
        }
    }
}

// MARK: - Budget Status Chip

private struct BudgetStatusChip: View {
    let totalPercentage: Int

    private var status: (text: String, icon: String, fill: Color, fg: Color) {
        if totalPercentage == 100 {
            return ("Balanced", "checkmark", Color.appAccent, Color.appOnAccent)
        } else if totalPercentage > 100 {
            return ("\(totalPercentage - 100)% over", "exclamationmark.triangle.fill", Color.appNegative.opacity(0.15), Color.appNegative)
        } else {
            return ("\(100 - totalPercentage)% free", "circle.dashed", Color.appSurfaceMuted, Color.appTextSecondary)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .bold))
            Text(status.text)
                .font(AppFont.captionStrong)
        }
        .foregroundColor(status.fg)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(status.fill))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Legend Cell

private struct LegendCell: View {
    let color: Color
    let name: String
    let percentage: Int
    let isMuted: Bool

    var body: some View {
        HStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 10)

            Text(name)
                .font(AppFont.caption)
                .foregroundColor(isMuted ? Color.appTextSecondary : Color.appTextPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text("\(percentage)%")
                .font(AppFont.captionStrong)
                .foregroundColor(Color.appTextSecondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}
