//
//  CardFlip3D.swift
//  undercoverApp
//
//  A reusable 3D card that flips between a front and back face.
//  Used in RevealView (word reveal) and ResultsView (pair reveal).
//

import SwiftUI

struct CardFlip3D<Front: View, Back: View>: View {
    let isFlipped:   Bool
    let front:       () -> Front
    let back:        () -> Back
    let onFlipMid:   (() -> Void)?   // called at 90° midpoint (use to trigger haptic)

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Back face (shown when flipped)
            back()
                .rotation3DEffect(.degrees(rotation - 180), axis: (x: 0, y: 1, z: 0))
                .opacity(rotation > 90 ? 1 : 0)

            // Front face
            front()
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                .opacity(rotation <= 90 ? 1 : 0)
        }
        .onChange(of: isFlipped) { _, flipped in
            withAnimation(.cardFlip) {
                rotation = flipped ? 180 : 0
            }
            // Trigger haptic at 90° midpoint
            if let onFlipMid {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    onFlipMid()
                }
            }
        }
    }
}

// MARK: - Hold to Confirm

/// A button that requires the user to hold for `duration` seconds.
/// Shows a radial progress ring while held.
 struct HoldToConfirmButton: View {
    let label: String
    let icon: String
    let duration: TimeInterval
    let color: Color
    let action: () -> Void

    @State private var progress: CGFloat = 0
    @State private var completed = false

    var body: some View {
        VStack(spacing: 8) {

            ZStack {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.appSurface2)

                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(
                        Color.white.opacity(0.08),
                        lineWidth: 1
                    )

                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))

                    Text(label)
                        .font(AppFont.button(size: 15))
                        .tracking(1.2)
                }
                .foregroundStyle(.white)
            }
            .frame(height: 56)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))

                    Capsule()
                        .fill(color)
                        .frame(
                            width: geo.size.width * progress
                        )
                }
            }
            .frame(height: 3)
        }
        .contentShape(Rectangle())
        .onLongPressGesture(
            minimumDuration: duration,
            maximumDistance: 50,
            pressing: { pressing in

                guard !completed else { return }

                if pressing {
                    withAnimation(.linear(duration: duration)) {
                        progress = 1
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.15)) {
                        progress = 0
                    }
                }
            },
            perform: {
                guard !completed else { return }

                completed = true
                progress = 1

                action()
            }
        )
    }
}
