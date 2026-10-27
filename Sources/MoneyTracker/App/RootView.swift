// RootView.swift
// Purpose: App shell. Routes between onboarding, the lock screen and the tabbed
// app, injects the stores, and handles lifecycle (auto-lock, privacy shield,
// flushing pending saves when the app backgrounds).

import SwiftUI

struct RootView: View {
    @State private var trackerStore = TrackerStore()
    @State private var budgetStore = BudgetStore()
    @State private var settingsStore = SettingsStore()
    @State private var authStore = AuthStore()

    @State private var selectedTab: AppTab = .tracker
    @State private var visitedTabs: Set<AppTab> = [.tracker]
    @State private var isShielded = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if authStore.isOnboarded {
                mainApp
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }

            if authStore.isOnboarded && authStore.isLocked {
                LockScreenView()
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 1.08)))
                    )
                    .zIndex(10)
            }

            // The lock screen shows nothing sensitive, and Face ID briefly makes
            // the scene inactive, so skip the shield while locked.
            if isShielded && authStore.isOnboarded && !authStore.isLocked {
                PrivacyShieldView()
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .animation(Motion.respecting(reduceMotion, Motion.smooth), value: authStore.isOnboarded)
        .animation(Motion.respecting(reduceMotion, Motion.smooth), value: authStore.isLocked)
        .animation(.easeInOut(duration: 0.18), value: isShielded)
        .background(Color.appBackground.ignoresSafeArea())
        .preferredColorScheme(preferredScheme)
        .environment(trackerStore)
        .environment(budgetStore)
        .environment(settingsStore)
        .environment(authStore)
        .onChange(of: scenePhase) { _, phase in
            handle(phase)
        }
    }

    /// Onboarding and the lock screen are always dark; the app follows Settings.
    private var preferredScheme: ColorScheme? {
        if !authStore.isOnboarded || authStore.isLocked { return .dark }
        return settingsStore.theme.colorScheme
    }

    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            // All tabs stay alive: switching only flips visibility, so it is
            // instant and each tab keeps its scroll position. A tab is built
            // the first time it is opened, not at launch.
            ZStack {
                ForEach(AppTab.allCases) { tab in
                    if visitedTabs.contains(tab) {
                        tabContent(tab)
                            .opacity(selectedTab == tab ? 1 : 0)
                            .allowsHitTesting(selectedTab == tab)
                            .accessibilityHidden(selectedTab != tab)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: selectedTab) { _, tab in
                visitedTabs.insert(tab)
            }

            FloatingTabBar(selection: $selectedTab)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private func tabContent(_ tab: AppTab) -> some View {
        switch tab {
        case .tracker: TrackerView()
        case .budget: BudgetPlanView()
        case .settings: SettingsView()
        }
    }

    private func handle(_ phase: ScenePhase) {
        switch phase {
        case .active:
            authStore.willEnterForeground()
            isShielded = false
        case .inactive:
            isShielded = true
        case .background:
            isShielded = true
            authStore.didEnterBackground()
            trackerStore.flush()
            budgetStore.flush()
            settingsStore.flush()
        @unknown default:
            break
        }
    }
}

#Preview {
    RootView()
}
