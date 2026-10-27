// Spacing.swift
// Purpose: Shared spacing and corner-radius scale based on 8pt grid tokens.

import CoreGraphics

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40

    static let section: CGFloat = 28
    static let horizontalMargin: CGFloat = 20
    static let cardPadding: CGFloat = 20
    static let floatingBarClearance: CGFloat = 120
}

enum Radius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let card: CGFloat = 24
    static let hero: CGFloat = 30
    static let tile: CGFloat = 20
    static let capsule: CGFloat = 999
}

enum Layout {
    static let minTouchTarget: CGFloat = 44
    static let rowHeight: CGFloat = 64
    static let rowIconSize: CGFloat = 40
    static let floatingBarHeight: CGFloat = 64
    static let buttonHeight: CGFloat = 52
    static let saveButtonHeight: CGFloat = 56
    static let segmentedHeight: CGFloat = 48
    static let progressBarHeight: CGFloat = 8
}