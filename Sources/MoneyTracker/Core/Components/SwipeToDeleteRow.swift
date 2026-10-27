// SwipeToDeleteRow.swift
// Purpose: Custom swipe-to-delete row component using DragGesture with reveal width 80,
// spring snap, horizontal-only drag filtering, single-row open management, and tap-to-close behavior.

import SwiftUI

struct SwipeToDeleteRow<Content: View>: View {
    let rowID: UUID
    @Binding var openRowID: UUID?
    let content: Content
    let onDelete: () -> Void
    var rowBackground: Color = .appSurface

    @State private var offset: CGFloat = 0
    @State private var initialOffset: CGFloat = 0
    private let revealWidth: CGFloat = 80

    init(
        rowID: UUID,
        openRowID: Binding<UUID?>,
        rowBackground: Color = .appSurface,
        @ViewBuilder content: () -> Content,
        onDelete: @escaping () -> Void
    ) {
        self.rowID = rowID
        self._openRowID = openRowID
        self.rowBackground = rowBackground
        self.content = content()
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Background red delete button (80pt wide)
            if offset < -1 {
                Button {
                    Haptics.warning()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        offset = 0
                    }
                    if openRowID == rowID {
                        openRowID = nil
                    }
                    onDelete()
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Delete")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxHeight: .infinity)
                    .frame(width: revealWidth)
                    .background(Color.appNegativeStrong)
                }
                .buttonStyle(.plain)
            }

            // Foreground content
            content
                .background(rowBackground)
                .offset(x: offset)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            if offset < 0 {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    offset = 0
                                    initialOffset = 0
                                    if openRowID == rowID {
                                        openRowID = nil
                                    }
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            if abs(value.translation.width) > abs(value.translation.height) {
                                let tentative = initialOffset + value.translation.width
                                if tentative < 0 {
                                    offset = max(-revealWidth, tentative)
                                } else {
                                    offset = min(0, tentative)
                                }
                            }
                        }
                        .onEnded { value in
                            // Vertical scrolls that started on this row: nothing to do.
                            if offset == 0 && abs(value.translation.width) <= abs(value.translation.height) {
                                return
                            }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                if value.translation.width < -30 || offset < -revealWidth / 2 {
                                    offset = -revealWidth
                                    openRowID = rowID
                                } else {
                                    offset = 0
                                    if openRowID == rowID {
                                        openRowID = nil
                                    }
                                }
                            }
                            initialOffset = offset
                        }
                )
        }
        .clipped()
        .onChange(of: openRowID) { _, newOpenID in
            if newOpenID != rowID && offset < 0 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    offset = 0
                    initialOffset = 0
                }
            }
        }
        .accessibilityAction(named: "Delete") {
            Haptics.warning()
            onDelete()
        }
    }
}