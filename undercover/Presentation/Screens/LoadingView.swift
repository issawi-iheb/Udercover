//
//  LoadingView.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import SwiftUI

struct LoadingView: View {

    @State private var textIn = false
    let title: String
    let subtitle: String?
    
    init(
        title: String,
        subtitle: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        ZStack {
            LinearGradient.brandBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                MrWhiteDrawing()
                    .frame(width: 190, height: 190)

                VStack(spacing: 8) {
                    //Text("PREPARING GAME")
                    Text(title)
                        .font(AppFont.label(size: 11))
                        .tracking(2.5)
                        .foregroundStyle(Color.brandPurple)

//                    Text("Getting everything ready...")
//                        .font(AppFont.body(size: 14, weight: .medium))
//                        .foregroundStyle(Color.white.opacity(0.45))
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                }
                .opacity(textIn ? 1 : 0)
                .offset(y: textIn ? 0 : 10)

                LoadingDots()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                textIn = true
            }
        }
    }
}

// MARK: - Loading dots (replaces ProgressView)

private struct LoadingDots: View {

    @State private var phase = 0

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(phase == index ? 0.85 : 0.22))
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == index ? 1.35 : 1)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(280))

                withAnimation(.easeInOut(duration: 0.28)) {
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}

struct MrWhiteDrawing: View {

    // MARK: Outline draw-on

    @State private var hatStroke: CGFloat = 0
    @State private var collarLeftStroke: CGFloat = 0
    @State private var collarRightStroke: CGFloat = 0

    // MARK: Fills

    @State private var hatFill: CGFloat = 0
    @State private var collarLeftFill: CGFloat = 0
    @State private var collarRightFill: CGFloat = 0

    // MARK: Eyes

    @State private var eyePop: CGFloat = 0
    @State private var eyeOpen: CGFloat = 1

    // MARK: Transform

    @State private var rootOpacity: CGFloat = 0
    @State private var rootScale: CGFloat = 0.92
    @State private var hatDrop: CGFloat = -26
    @State private var headBob: CGFloat = 0
    @State private var headTilt: Double = 0
    @State private var squashX: CGFloat = 1
    @State private var squashY: CGFloat = 1
    @State private var collarLeftSlide: CGFloat = 34
    @State private var collarRightSlide: CGFloat = 34
    @State private var glowScale: CGFloat = 0.88

    // MARK: Shine

    @State private var shineX: CGFloat = -200

    private let ink = Color.white.opacity(0.93)
    private let pivot = UnitPoint(x: 0.5, y: 0.46)

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.brandPurple.opacity(0.14))
                .frame(width: 200, height: 200)
                .blur(radius: 58)
                .scaleEffect(glowScale)
                .offset(y: headBob * 1.5)

            ZStack {
                collarGroup
                hatGroup
                eyeGroup
            }
            .frame(width: 190, height: 190)
            .scaleEffect(
                CGSize(width: squashX, height: squashY),
                anchor: pivot
            )
            .rotationEffect(.degrees(headTilt), anchor: pivot)
            .offset(y: headBob)
            .scaleEffect(rootScale)
            .opacity(rootOpacity)
        }
        .task {
            await runTimeline()
        }
    }

    // MARK: Hat

    private var hatGroup: some View {
        ZStack {
            SpyHat()
                .fill(ink)
                .opacity(hatFill)

            SpyHat()
                .trim(from: 0, to: hatStroke)
                .stroke(
                    ink,
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .opacity(1 - hatFill)
        }
        .offset(y: hatDrop)
    }

    // MARK: Eyes

    private var eyeGroup: some View {
        SpyEyes()
            .fill(ink)
            .scaleEffect(
                CGSize(width: eyePop, height: eyePop * eyeOpen),
                anchor: UnitPoint(x: 0.5, y: 0.44)
            )
            .offset(y: hatDrop * 0.35)
    }

    // MARK: Collar

    private var collarGroup: some View {
        ZStack {
            ZStack {
                SpyCollarLeft()
                    .fill(ink)
                    .opacity(collarLeftFill)

                SpyCollarLeft()
                    .trim(from: 0, to: collarLeftStroke)
                    .stroke(
                        ink,
                        style: StrokeStyle(
                            lineWidth: 2.2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
            .offset(y: collarLeftSlide)

            ZStack {
                SpyCollarRight()
                    .fill(ink)
                    .opacity(collarRightFill)

                SpyCollarRight()
                    .trim(from: 0, to: collarRightStroke)
                    .stroke(
                        ink,
                        style: StrokeStyle(
                            lineWidth: 2.2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
            .offset(y: collarRightSlide)
        }
    }
}

extension MrWhiteDrawing {

    private func runTimeline() async {
        await drawIn()
        await idleLoop()
    }

    // MARK: Draw-in (~2.1s)

    private func drawIn() async {
        withAnimation(.easeOut(duration: 0.4)) {
            rootOpacity = 1
            rootScale = 1
        }

        withAnimation(.easeOut(duration: 0.7)) {
            glowScale = 1
        }

        // 1. Hat outline traces, dropping into place.
        withAnimation(.easeInOut(duration: 0.62)) {
            hatStroke = 1
        }

        withAnimation(
            .interpolatingSpring(stiffness: 150, damping: 12)
        ) {
            hatDrop = 0
        }

        await sleep(0.52)

        // 2. Hat floods solid.
        withAnimation(.easeOut(duration: 0.28)) {
            hatFill = 1
        }

        await sleep(0.24)

        // 3. Collars sweep up, left leading.
        withAnimation(.easeInOut(duration: 0.44)) {
            collarLeftStroke = 1
        }

        withAnimation(
            .interpolatingSpring(stiffness: 170, damping: 14)
        ) {
            collarLeftSlide = 0
        }

        await sleep(0.14)

        withAnimation(.easeInOut(duration: 0.48)) {
            collarRightStroke = 1
        }

        withAnimation(
            .interpolatingSpring(stiffness: 170, damping: 14)
        ) {
            collarRightSlide = 0
        }

        await sleep(0.34)

        withAnimation(.easeOut(duration: 0.26)) {
            collarLeftFill = 1
        }

        withAnimation(.easeOut(duration: 0.26).delay(0.08)) {
            collarRightFill = 1
        }

        await sleep(0.26)

        // 4. Eyes snap open — the reveal.
        withAnimation(
            .interpolatingSpring(stiffness: 300, damping: 12)
        ) {
            eyePop = 1
        }

        await sleep(0.14)

        // 5. Settle.
        withAnimation(.easeOut(duration: 0.11)) {
            squashX = 1.05
            squashY = 0.95
        }

        await sleep(0.11)

        withAnimation(
            .interpolatingSpring(stiffness: 180, damping: 9)
        ) {
            squashX = 1
            squashY = 1
        }

        await sleep(0.28)
    }

    // MARK: Idle

    private func idleLoop() async {
        withAnimation(
            .easeInOut(duration: 2.1)
                .repeatForever(autoreverses: true)
        ) {
            headBob = -4
        }

        withAnimation(
            .easeInOut(duration: 2.7)
                .repeatForever(autoreverses: true)
        ) {
            glowScale = 1.08
        }

        var beat = 0

        while !Task.isCancelled {
            await sleep(1.5)

            switch beat % 3 {
            case 0:
                await blink()

            case 1:
                await headTurn()

            default:
                await doubleBlink()
            }

            beat += 1
        }
    }

    // MARK: Beats

    private func blink() async {
        withAnimation(.easeIn(duration: 0.07)) {
            eyeOpen = 0.08
        }

        await sleep(0.07)

        withAnimation(.easeOut(duration: 0.12)) {
            eyeOpen = 1
        }

        await sleep(0.12)
    }

    private func doubleBlink() async {
        await blink()
        await sleep(0.1)
        await blink()
    }

    private func brimShine() async {
        shineX = -200

        withAnimation(.easeInOut(duration: 0.72)) {
            shineX = 200
        }

        await sleep(0.72)
    }

    private func headTurn() async {
        withAnimation(.easeInOut(duration: 0.3)) {
            headTilt = -5
            squashX = 0.985
        }

        await sleep(0.42)

        withAnimation(
            .interpolatingSpring(stiffness: 140, damping: 11)
        ) {
            headTilt = 0
            squashX = 1
        }

        await sleep(0.4)
    }

    private func sleep(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }
}

// MARK: - Design-space mapping (reference art is 360 × 360)

private func spyPoint(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
    let scale = min(rect.width, rect.height) / 360
    let originX = rect.midX - 180 * scale
    let originY = rect.midY - 180 * scale

    return CGPoint(x: originX + x * scale, y: originY + y * scale)
}

// MARK: - Hat: crown with two peaks and a centre dimple, plus brim

struct SpyHat: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            spyPoint(x, y, in: rect)
        }

        // Crown, left base.
        path.move(to: p(102, 118))

        path.addCurve(
            to: p(114, 52),
            control1: p(100, 92),
            control2: p(104, 66)
        )

        // Left peak.
        path.addCurve(
            to: p(144, 22),
            control1: p(120, 32),
            control2: p(130, 22)
        )

        // Centre dimple.
        path.addCurve(
            to: p(180, 42),
            control1: p(158, 22),
            control2: p(168, 42)
        )

        path.addCurve(
            to: p(216, 22),
            control1: p(192, 42),
            control2: p(202, 22)
        )

        // Right peak.
        path.addCurve(
            to: p(246, 52),
            control1: p(230, 22),
            control2: p(240, 32)
        )

        path.addCurve(
            to: p(258, 118),
            control1: p(256, 66),
            control2: p(260, 92)
        )

        // Brim, right half.
        path.addLine(to: p(348, 118))

        path.addCurve(
            to: p(342, 144),
            control1: p(350, 128),
            control2: p(348, 139)
        )

        path.addCurve(
            to: p(18, 144),
            control1: p(240, 152),
            control2: p(120, 152)
        )

        path.addCurve(
            to: p(12, 118),
            control1: p(12, 139),
            control2: p(10, 128)
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Eye slits: flat top, shallow curve underneath

struct SpyEyes: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            spyPoint(x, y, in: rect)
        }

        // Left slit.
        path.move(to: p(94, 160))
        path.addLine(to: p(166, 160))
        path.addCurve(
            to: p(94, 160),
            control1: p(160, 182),
            control2: p(100, 182)
        )

        // Right slit.
        path.move(to: p(194, 160))
        path.addLine(to: p(266, 160))
        path.addCurve(
            to: p(194, 160),
            control1: p(260, 182),
            control2: p(200, 182)
        )

        return path
    }
}

// MARK: - Hat dimple (a subtle crease, drawn as a stroke)

struct SpyHatCrease: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            spyPoint(x, y, in: rect)
        }

        path.move(to: p(146, 22))
        path.addCurve(
            to: p(214, 22),
            control1: p(166, 44),
            control2: p(194, 44)
        )

        return path
    }
}


// MARK: - Left collar panel

struct SpyCollarLeft: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            spyPoint(x, y, in: rect)
        }

        path.move(to: p(30, 154))
        path.addLine(to: p(98, 154))
        path.addLine(to: p(64, 200))
        path.addLine(to: p(120, 214))
        path.addLine(to: p(154, 280))
        path.addLine(to: p(48, 236))
        path.closeSubpath()

        return path
    }
}

// MARK: - Right collar panel (longer, reaches bottom centre)

struct SpyCollarRight: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            spyPoint(x, y, in: rect)
        }

        path.move(to: p(330, 154))
        path.addLine(to: p(262, 154))
        path.addLine(to: p(296, 200))
        path.addLine(to: p(240, 214))
        path.addLine(to: p(178, 350))
        path.addLine(to: p(312, 240))
        path.closeSubpath()

        return path
    }
}

