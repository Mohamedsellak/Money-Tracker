You are a senior iOS engineer and UI/UX designer. Build a beautiful, minimal personal finance app called "MoneyTracker" in SwiftUI.

BUILD ENVIRONMENT (important)
- The project is built with xtool on Linux (SwiftPM, NO Xcode). I run `xtool dev` to build and install on my iPhone.
- Do NOT use SwiftData, Core Data, .xcassets-only workflows, storyboards, or any Apple-proprietary macro that needs Xcode.
- Allowed: SwiftUI, Foundation, Observation (@Observable), @AppStorage, SF Symbols.
- No third-party packages unless I approve them. If you want to use Swift Charts or a custom font, make it optional with a safe fallback, and tell me it is untested on xtool.
- Keep every change buildable with `xtool dev`. After each step, tell me exactly what to run.

DESIGN
- Style: clean, modern, minimal, generous spacing, large rounded cards (corner radius 20-28), soft shadows in light mode, subtle borders in dark mode, smooth spring animations, haptic feedback on add/delete.
- Typography: system font, rounded design (.rounded) for numbers and titles. Big bold totals.
- Icons: SF Symbols only (e.g. house, cart, fork.knife, dumbbell, bus, wifi, banknote, chart.pie, gearshape).
- Color palette (define as semantic tokens, never hardcode in views):
  - #f4f5f6 White Smoke  -> light background
  - #e2e3e2 Aria         -> light cards / dividers
  - #bcee29 Yellowy Green -> ACCENT (buttons, active tab, highlights, positive balance)
  - #c7c7c6 Paternoster  -> borders, inactive elements
  - #959493 Grey Shingle -> secondary text
  - #464543 Ravenwood    -> primary text in light mode, card surface in dark mode
  - Dark mode: background is a darker shade derived from #464543 (about #2b2a29), cards use #464543, text uses #f4f5f6, accent stays #bcee29.
  - Text on the accent color must be dark (#464543) for contrast.
- Theme: ThemeManager with three options in Settings: System / Light / Dark, persisted with @AppStorage and applied through .preferredColorScheme.

NAVIGATION
- A custom FLOATING tab bar: a rounded capsule that hovers above the bottom safe area, with a blur/material background, a soft shadow, icon + short label for the selected tab, and an accent-colored pill behind the active icon with a matched-geometry animation.
- 3 tabs: Tracker (chart.bar / banknote), Budget Plan (chart.pie), Settings (gearshape).
- Content must scroll behind the bar with enough bottom padding so nothing is hidden.

FEATURE 1: MONEY TRACKER
- Top summary card: Total Income, Total Expenses, and a large Balance (Income minus Expenses). Balance is accent-colored when positive and red-ish when negative. Animate number changes.
- Two sections: INCOME and EXPENSES.
  - Income has multiple sources (Salary, Freelance, Side job, etc.).
  - Expenses have categories (Rent, Food, Groceries, Gym, Transport, Subscriptions, etc.).
  - Each section shows its items as rows (icon, name, amount) and a section total at the bottom.
- The user can ADD an item (name, amount, icon picker, optional custom category), EDIT it by tapping, and DELETE it by swipe. Use a bottom sheet for add/edit with a numeric keypad.
- All totals recalculate automatically and instantly (computed properties, no manual refresh).
- Ship with a few removable sample items on first launch, plus a friendly empty state with an illustration-like SF Symbol and a call-to-action.
- Currency: default EUR (the user lives in France), selectable in Settings. Format with NumberFormatter / FormatStyle.currency.

FEATURE 2: BUDGET PLAN (percentage allocation, like the 50/30/20 rule)
- Base amount = total monthly income from the Money Tracker (read-only, linked automatically).
- Default allocation buckets (the user can edit names, percentages, colors, add and remove buckets):
  - 60% Essentials (rent, subscriptions, transport, necessities)
  - 10% Personal / Fun
  - 10% Investing
  - 10% Savings / Emergency fund
  - 10% Debt payoff or extra investing
- For each bucket show: name, icon, percentage, and the computed amount (percentage x income), with a progress bar.
- Percentages are editable with a slider or stepper. Show a live "Allocated: X% / 100%" indicator. Warn visibly if the total is not 100% and show the remaining or over-allocated amount. Do not allow saving a plan that goes over 100% without a clear warning.
- A donut or segmented bar summary of the split (build it with plain SwiftUI shapes so it needs no extra framework).
- Optional comparison: actual spending vs. planned for the Essentials bucket, using the expense data from the Tracker.

FEATURE 3: SETTINGS
- Theme switch (System / Light / Dark), currency picker, "Reset all data" with a confirmation dialog, app version.

ARCHITECTURE (feature-based, easy to extend)
Sources/MoneyTracker/
  App/            MoneyTrackerApp.swift, RootView.swift (tab container + floating bar)
  Core/
    DesignSystem/ Colors.swift, Typography.swift, Spacing.swift, Theme.swift, Haptics.swift
    Components/   FloatingTabBar, CardView, PrimaryButton, AmountField, EmptyStateView, SectionHeader, IconPicker
    Storage/      Storable protocol + JSONFileStore (Codable, saves to the Documents directory, atomic writes)
    Extensions/   Decimal+Currency, View+Modifiers
  Features/
    Tracker/      Models (TransactionItem, TransactionKind), TrackerStore (@Observable), Views (TrackerView, ItemRow, AddEditItemSheet, SummaryCard)
    BudgetPlan/   Models (BudgetBucket, BudgetPlan), BudgetStore (@Observable), Views (BudgetPlanView, BucketRow, AllocationRing)
    Settings/     SettingsStore (@AppStorage), SettingsView
- Each feature is self-contained: Models, Store/ViewModel, Views. Adding a new feature = adding a folder and one tab entry in an AppTab enum.
- Use MVVM with @Observable stores injected through the SwiftUI environment.
- Use Decimal (not Double) for money values.
- Persistence: JSON files, one per feature, loaded at launch and saved on every change (debounced). Include a version field in the stored models so migration is possible later.
- Keep files small, with a comment at the top of each explaining its purpose. Add #Preview blocks only if they do not break the xtool build.

ACCESSIBILITY AND POLISH
- Dynamic Type support, VoiceOver labels on icon-only buttons, 44pt minimum touch targets, sufficient contrast in both themes, Reduce Motion respected.

DELIVERABLES
1. First, show the final folder tree and a short plan.
2. Then write all the code, file by file, with the full file path above each file.
3. Make sure it compiles with the Swift 6.4 toolchain via xtool (watch for concurrency and Sendable errors; use @MainActor where needed).
4. End with a short "How to add a new feature" guide, and a list of anything that might not work under xtool.