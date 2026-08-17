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
    let label:    String
    let icon:     String
    let duration: Double       // seconds to hold
    let color:    Color
    let action:   () -> Void

    @State private var progress:  Double  = 0
    @State private var isHolding: Bool    = false
    @State private var timer:     Timer?

    var body: some View {
        ZStack {
            // Background fill
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .strokeBorder(color.opacity(0.35), lineWidth: 1)
                )

            // Progress ring
            RoundedRectangle(cornerRadius: Radius.md)
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)

            // Label
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                Text(label)
                    .font(AppFont.button())
                    .tracking(1)
            }
            .foregroundStyle(isHolding ? color : .white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .scaleEffect(isHolding ? 0.97 : 1.0)
        .animation(.appSnap, value: isHolding)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHolding() }
                .onEnded   { _ in cancelHolding() }
        )
    }

    private func startHolding() {
        guard !isHolding else { return }
        isHolding = true
        progress  = 0
        Haptic.holdPulse()

        let interval = 0.05
        let steps    = duration / interval

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            progress += 1.0 / steps
            if progress >= 0.33 { Haptic.holdPulse() ; /* sparse */ }
            if progress >= 1.0 {
                t.invalidate()
                Haptic.cardFlip()
                action()
                reset()
            }
        }
    }

    private func cancelHolding() {
        timer?.invalidate()
        timer = nil
        withAnimation(.appSnap) {
            isHolding = false
            progress  = 0
        }
    }

    private func reset() {
        isHolding = false
        progress  = 0
    }
}
