// SettingsView.swift
// Purpose: Settings screen: profile card, security (passcode, biometrics,
// auto-lock), appearance, preferences, data management and about.

import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var store
    @Environment(TrackerStore.self) private var trackerStore
    @Environment(BudgetStore.self) private var budgetStore
    @Environment(AuthStore.self) private var auth

    @State private var showingResetConfirmation = false
    @State private var showingEraseConfirmation = false
    @State private var showingCurrencySheet = false
    @State private var showingNameSheet = false
    @State private var passcodeMode: PasscodeSetupSheet.Mode?

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(title: "Settings", eyebrow: "Account & app")
                    .appearLift(0)

                profileCard
                    .horizontalMargin()
                    .padding(.bottom, Spacing.xl)
                    .appearLift(1)

                SectionLabel(title: "Security")
                SettingsGroup {
                    SettingsToggleRow(
                        icon: "lock.fill",
                        tint: Color(hex: 0x9BA9FF),
                        title: "Passcode",
                        subtitle: auth.hasPasscode ? "Required to open the app" : "Off",
                        isOn: Binding(
                            get: { auth.hasPasscode },
                            set: { passcodeMode = $0 ? .create : .remove }
                        )
                    )

                    if auth.hasPasscode {
                        RowDivider()
                        Button { passcodeMode = .change } label: {
                            SettingsRow(icon: "key.fill", tint: Color(hex: 0xFFB86B), title: "Change passcode", value: nil)
                        }
                        .buttonStyle(.plain)

                        if auth.biometricKind != .none {
                            RowDivider()
                            SettingsToggleRow(
                                icon: auth.biometricKind.iconName,
                                tint: Color.appAccent,
                                title: auth.biometricKind.title,
                                subtitle: "Unlock with a glance",
                                isOn: Binding(
                                    get: { auth.biometricsEnabled },
                                    set: { newValue in toggleBiometrics(newValue) }
                                )
                            )
                        }

                        RowDivider()
                        Menu {
                            Picker("Auto-lock", selection: Binding(
                                get: { auth.profile?.autoLock ?? .oneMinute },
                                set: { auth.setAutoLock($0); Haptics.tap() }
                            )) {
                                ForEach(AutoLock.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                        } label: {
                            SettingsRow(
                                icon: "timer",
                                tint: Color(hex: 0x7CD3C0),
                                title: "Auto-lock",
                                value: auth.profile?.autoLock.title ?? "",
                                chevron: "chevron.up.chevron.down"
                            )
                        }

                        RowDivider()
                        Button {
                            Haptics.tap()
                            auth.lock()
                        } label: {
                            SettingsRow(icon: "lock.rectangle.stack.fill", tint: Color(hex: 0xE0A9FF), title: "Lock now", value: nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .appearLift(2)

                SectionLabel(title: "Appearance")
                HStack(spacing: Spacing.sm) {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeTile(
                            theme: theme,
                            isSelected: store.theme == theme,
                            action: {
                                withAnimation(Motion.smooth) { store.theme = theme }
                                Haptics.tap()
                            }
                        )
                    }
                }
                .horizontalMargin()
                .padding(.bottom, Spacing.xl)
                .appearLift(3)

                SectionLabel(title: "Preferences")
                SettingsGroup {
                    Button {
                        showingCurrencySheet = true
                        Haptics.tap()
                    } label: {
                        SettingsRow(
                            icon: SettingsStore.availableCurrencies.first { $0.code == store.currencyCode }?.icon ?? "dollarsign",
                            tint: Color.appAccent,
                            title: "Currency",
                            value: "\(store.currencyCode) · \(store.currencyName)"
                        )
                    }
                    .buttonStyle(.plain)

                    RowDivider()
                    SettingsToggleRow(
                        icon: "eye.slash.fill",
                        tint: Color(hex: 0x8FC7FF),
                        title: "Hide balances",
                        subtitle: "Blur amounts in public",
                        isOn: Binding(get: { store.hideBalances }, set: { store.hideBalances = $0 })
                    )
                }

                SectionLabel(title: "Data")
                SettingsGroup {
                    Button {
                        showingResetConfirmation = true
                    } label: {
                        SettingsRow(icon: "arrow.counterclockwise", tint: Color(hex: 0xFFB86B), title: "Reset to sample data", value: nil)
                    }
                    .buttonStyle(.plain)

                    RowDivider()
                    Button {
                        showingEraseConfirmation = true
                    } label: {
                        SettingsRow(icon: "trash.fill", tint: Color.appNegative, title: "Erase everything & sign out", value: nil, isDestructive: true)
                    }
                    .buttonStyle(.plain)
                }

                SectionLabel(title: "About")
                SettingsGroup {
                    SettingsRow(icon: "info.circle.fill", tint: Color(hex: 0x959493), title: "Version", value: "\(appVersion) (\(buildNumber))", chevron: nil)
                    RowDivider()
                    SettingsRow(icon: "iphone.gen3", tint: Color(hex: 0x7CD3C0), title: "Data storage", value: "On this device", chevron: nil)
                }

                Text("Made with care in France")
                    .font(AppFont.caption)
                    .foregroundColor(Color.appTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.sm)
            }
            .padding(.bottom, Spacing.floatingBarClearance)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .confirmationDialog(
            "Reset to sample data?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Data", role: .destructive) {
                store.resetAllData()
                trackerStore.reloadSamples()
                budgetStore.resetToDefaults()
                Haptics.warning()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your transactions and budget are replaced with the sample set and settings return to defaults. Your profile and passcode stay.")
        }
        .confirmationDialog(
            "Erase everything?",
            isPresented: $showingEraseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Erase & Sign Out", role: .destructive) {
                store.resetAllData()
                trackerStore.reloadSamples()
                budgetStore.resetToDefaults()
                auth.signOutAndErase()
                Haptics.warning()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes your profile, passcode, transactions and budget from this iPhone. This can't be undone.")
        }
        .sheet(isPresented: $showingCurrencySheet) {
            CurrencySelectionSheet()
                .environment(store)
        }
        .sheet(isPresented: $showingNameSheet) {
            EditNameSheet(name: auth.displayName) { auth.updateName($0) }
        }
        .fullScreenCover(item: Binding(
            get: { passcodeMode.map(PasscodeModeBox.init) },
            set: { passcodeMode = $0?.mode }
        )) { box in
            PasscodeSetupSheet(mode: box.mode)
                .environment(auth)
        }
    }

    private var profileCard: some View {
        Button {
            Haptics.tap()
            showingNameSheet = true
        } label: {
            HStack(spacing: Spacing.md) {
                AvatarView(name: auth.displayName, size: 58)
                VStack(alignment: .leading, spacing: 3) {
                    Text(auth.displayName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appOnInk)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Image(systemName: auth.hasPasscode ? "checkmark.shield.fill" : "shield.slash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(auth.hasPasscode ? Color.appAccent : Color.appInkNegative)
                        Text(auth.hasPasscode ? "Protected" : "Not protected")
                            .font(AppFont.caption)
                            .foregroundColor(Color.appOnInkMuted)
                        if let created = auth.profile?.createdAt {
                            Text("· since \(created.formatted(.dateTime.month(.abbreviated).year()))")
                                .font(AppFont.caption)
                                .foregroundColor(Color.appOnInkMuted)
                        }
                    }
                    .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.appOnInk)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .padding(Spacing.lg)
            .inkCard()
            .environment(\.colorScheme, .dark)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Profile, \(auth.displayName)")
        .accessibilityHint("Double tap to edit your name")
    }

    private func toggleBiometrics(_ enabled: Bool) {
        guard enabled else {
            auth.setBiometricsEnabled(false)
            Haptics.tap()
            return
        }
        Task {
            if await BiometricAuth.authenticate(reason: "Enable \(auth.biometricKind.title) for MoneyTracker") {
                auth.setBiometricsEnabled(true)
                Haptics.success()
            }
        }
    }
}

/// Identifiable wrapper so the passcode mode can drive `fullScreenCover(item:)`.
private struct PasscodeModeBox: Identifiable {
    let mode: PasscodeSetupSheet.Mode
    var id: String { "\(mode)" }
}

// MARK: - Building blocks

private struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(AppFont.eyebrow)
            .tracking(1.2)
            .foregroundColor(Color.appTextSecondary)
            .horizontalMargin()
            .padding(.leading, 4)
            .padding(.bottom, Spacing.xs)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .surfaceCard(cornerRadius: Radius.lg)
            .horizontalMargin()
            .padding(.bottom, Spacing.xl)
    }
}

private struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.appHairline)
            .frame(height: 1)
            .padding(.leading, 60)
    }
}

private struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String
    let value: String?
    var chevron: String? = "chevron.right"
    var isDestructive = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconTile(iconName: icon, tint: tint, size: 32)

            Text(title)
                .font(AppFont.bodyMedium)
                .foregroundColor(isDestructive ? Color.appNegative : Color.appTextPrimary)

            Spacer(minLength: Spacing.xs)

            if let value {
                Text(value)
                    .font(AppFont.body)
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
            }

            if let chevron {
                Image(systemName: chevron)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.appTextMuted)
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: Spacing.md) {
                IconTile(iconName: icon, tint: tint, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(AppFont.bodyMedium)
                        .foregroundColor(Color.appTextPrimary)
                    Text(subtitle)
                        .font(AppFont.micro)
                        .foregroundColor(Color.appTextSecondary)
                }
            }
        }
        .tint(Color.appAccentDeep)
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 60)
    }
}

// MARK: - Theme Tile

private struct ThemeTile: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ThemePreview(theme: theme)
                    .frame(height: 54)

                HStack(spacing: 5) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : theme.iconName)
                        .font(.system(size: 12, weight: .bold))
                    Text(theme.title)
                        .font(AppFont.captionStrong)
                }
                .foregroundColor(isSelected ? Color.appTextPrimary : Color.appTextSecondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(isSelected ? Color.appAccentDeep : Color.appHairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(theme.title) theme")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Miniature phone UI rendered in the theme's colors.
private struct ThemePreview: View {
    let theme: AppTheme

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                mini(light: true)
                    .frame(width: theme == .system ? proxy.size.width / 2 : proxy.size.width)
                    .opacity(theme == .dark ? 0 : 1)
                if theme != .light {
                    mini(light: false)
                        .frame(width: theme == .system ? proxy.size.width / 2 : proxy.size.width)
                }
            }
            .frame(width: proxy.size.width, alignment: theme == .dark ? .trailing : .leading)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .accessibilityHidden(true)
    }

    private func mini(light: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            Color(hex: light ? 0xF4F5F6 : 0x1A1918)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.appInk)
                    .overlay(alignment: .topTrailing) {
                        Circle().fill(Color.appAccent.opacity(0.8)).frame(width: 10).blur(radius: 3).offset(x: -4, y: 4)
                    }
                    .frame(height: 18)
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: light ? 0xFFFFFF : 0x32312F)).frame(height: 6)
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: light ? 0xFFFFFF : 0x32312F)).frame(width: 30, height: 6)
            }
            .padding(6)
        }
    }
}

// MARK: - Edit Name Sheet

private struct EditNameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var name: String
    let onSave: (String) -> Void
    @FocusState private var isFocused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Capsule()
                .fill(Color.appTextMuted.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, Spacing.sm)

            AvatarView(name: trimmed.isEmpty ? "?" : trimmed, size: 72)
                .animation(Motion.snappy, value: trimmed)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Your name")
                    .font(AppFont.caption)
                    .foregroundColor(Color.appTextSecondary)
                TextField("Name", text: $name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .textContentType(.name)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onSubmit(save)
                    .padding(.horizontal, Spacing.md)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Color.appSurfaceMuted)
                    )
            }

            PrimaryButton("Save", isEnabled: !trimmed.isEmpty, action: save)

            Spacer(minLength: 0)
        }
        .horizontalMargin()
        .presentationDetents([.medium])
        .presentationCornerRadius(Radius.hero)
        .presentationBackground(Color.appBackground)
        .onAppear { isFocused = true }
    }

    private func save() {
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Currency Selection Sheet

private struct CurrencySelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(SettingsStore.availableCurrencies.enumerated()), id: \.element.code) { index, currency in
                        Button {
                            store.currencyCode = currency.code
                            Haptics.tap()
                            dismiss()
                        } label: {
                            HStack(spacing: Spacing.md) {
                                IconTile(iconName: currency.icon, tint: Color.appAccent, size: 36)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(currency.code)
                                        .font(AppFont.bodyStrong)
                                        .foregroundColor(Color.appTextPrimary)
                                    Text(currency.name)
                                        .font(AppFont.caption)
                                        .foregroundColor(Color.appTextSecondary)
                                }
                                Spacer()
                                if store.currencyCode == currency.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color.appOnAccent, Color.appAccent)
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                            .frame(height: 60)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(store.currencyCode == currency.code ? [.isSelected] : [])

                        if index < SettingsStore.availableCurrencies.count - 1 {
                            Rectangle()
                                .fill(Color.appHairline)
                                .frame(height: 1)
                                .padding(.leading, 68)
                        }
                    }
                }
                .surfaceCard(cornerRadius: Radius.lg)
                .horizontalMargin()
                .padding(.vertical, Spacing.md)
            }
            .background(Color.appBackground)
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appTextPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(Radius.hero)
    }
}
