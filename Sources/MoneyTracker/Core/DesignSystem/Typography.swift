// Typography.swift
// Purpose: Single source of truth for type (system .rounded, monospacedDigit for money).

import SwiftUI

enum AppFont {
    /// 48pt heavy - hero amount
    static var display: Font {
        .system(size: 48, weight: .heavy, design: .rounded)
            .monospacedDigit()
    }

    static var hero: Font {
        .system(size: 48, weight: .heavy, design: .rounded)
            .monospacedDigit()
    }

    /// 56pt heavy - balance on the hero card
    static var balance: Font {
        .system(size: 52, weight: .bold, design: .rounded)
            .monospacedDigit()
    }

    /// 34pt bold - onboarding headlines
    static var marketing: Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }

    /// 11pt semibold - uppercase eyebrow labels
    static var eyebrow: Font {
        .system(size: 11, weight: .semibold, design: .rounded)
    }

    /// 30pt bold - screen titles (large, left-aligned)
    static var title: Font {
        .system(size: 30, weight: .bold, design: .rounded)
    }

    static var largeTitle: Font {
        .system(size: 30, weight: .bold, design: .rounded)
    }

    /// 17pt semibold - headlines
    static var headline: Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }

    /// 16pt regular - body text
    static var body: Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }

    /// 16pt medium - body emphasis
    static var bodyMedium: Font {
        .system(size: 16, weight: .medium, design: .rounded)
    }

    static var bodyStrong: Font {
        .system(size: 16, weight: .semibold, design: .rounded)
    }

    /// 13pt medium - captions
    static var caption: Font {
        .system(size: 13, weight: .medium, design: .rounded)
    }

    static var captionStrong: Font {
        .system(size: 13, weight: .semibold, design: .rounded)
    }

    /// 13pt regular - secondary captions
    static var captionRegular: Font {
        .system(size: 13, weight: .regular, design: .rounded)
    }

    /// 12pt medium - micro labels
    static var micro: Font {
        .system(size: 12, weight: .medium, design: .rounded)
    }

    /// 17pt semibold - inline amounts
    static var number: Font {
        .system(size: 17, weight: .semibold, design: .rounded)
            .monospacedDigit()
    }

    /// 24pt bold - large amount
    static var numberLarge: Font {
        .system(size: 24, weight: .bold, design: .rounded)
            .monospacedDigit()
    }

    /// Tab label (14pt semibold)
    static var tabLabel: Font {
        .system(size: 14, weight: .semibold, design: .rounded)
    }

    /// 17pt semibold - button labels
    static var button: Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }
}