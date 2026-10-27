// AllocationRing.swift
// Purpose: Pure SwiftUI donut of the plan. Segments sweep in on appear, are
// separated by small gaps, and an unallocated grey segment shows when < 100%.

import SwiftUI

struct AllocationRing: View {
    let buckets: [BudgetBucket]
    let totalPercentage: Int
    var lineWidth: CGFloat = 24

    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Segment: Identifiable {
        let id: String
        let start: Double
        let length: Double
        let color: Color
    }

    private var segments: [Segment] {
        let active = buckets.filter { $0.percentage > 0 }
        // Over-allocated plans are drawn proportionally so the ring stays closed.
        let scale = Double(max(100, totalPercentage))
        var cursor = 0.0
        var result: [Segment] = []
        for bucket in active {
            let length = Double(bucket.percentage) / scale
            result.append(Segment(id: bucket.id.uuidString, start: cursor, length: length, color: bucket.color))
            cursor += length
        }
        if totalPercentage < 100 {
            result.append(Segment(id: "unallocated", start: cursor, length: 1 - cursor, color: Color.appBorder))
        }
        return result
    }

    var body: some View {
        let gap = segments.count > 1 ? 0.008 : 0
        ZStack {
            Circle()
                .stroke(Color.appSurfaceMuted, lineWidth: lineWidth)

            ForEach(segments) { segment in
                let from = segment.start * progress + gap
                let to = (segment.start + segment.length) * progress - gap
                Circle()
                    .trim(from: from, to: max(from, to))
                    .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(lineWidth / 2)
        .aspectRatio(1, contentMode: .fit)
        .animation(Motion.respecting(reduceMotion, Motion.smooth), value: totalPercentage)
        .animation(Motion.respecting(reduceMotion, Motion.smooth), value: buckets)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.6)) {
                progress = 1
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Allocation chart")
        .accessibilityValue(buckets.map { "\($0.trimmedName) \($0.percentage) percent" }.joined(separator: ", "))
    }
}
