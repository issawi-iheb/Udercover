//
//  ParticleSystem.swift
//  undercoverApp
//
//  Physics-based confetti for civilians win,
//  smoke/dark particles for undercover win,
//  white sparkle burst for Mr. White win.
//

import SwiftUI
import Combine

// MARK: ─── Particle model ─────────────────────────────────────────────────────

private struct Particle: Identifiable {
    let id    = UUID()
    var x:     CGFloat
    var y:     CGFloat
    var vx:    CGFloat   // velocity x
    var vy:    CGFloat   // velocity y
    var rot:   Double    // current rotation degrees
    var rotV:  Double    // rotation velocity deg/frame
    var scale: CGFloat
    var color: Color
    var shape: ParticleShape
    var alpha: Double    = 1.0
    var life:  Double    = 1.0  // 1 → 0

    enum ParticleShape { case rect, circle, star }
}

// MARK: ─── Confetti (civilians win) ──────────────────────────────────────────

struct ConfettiView: View {
    let active: Bool

    @State private var particles: [Particle] = []
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    private let colors: [Color] = [.brandPurple, .brandPink, .accentGreen, .accentAmber, .brandPurpleLight, .accentWhite]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    ParticleShape(p: p)
                        .position(x: p.x, y: p.y)
                        .opacity(p.alpha)
                }
            }
            .onReceive(timer) { _ in
                guard active else { return }
                updateParticles(geo: geo)
            }
            .onChange(of: active) { _, newVal in
                if newVal { spawnBurst(geo: geo, count: 80) }
                else      { particles = [] }
            }
        }
        .allowsHitTesting(false)
    }

    private func spawnBurst(geo: GeometryProxy, count: Int) {
        let w = geo.size.width
        for _ in 0..<count {
            var p = Particle(
                x:     CGFloat.random(in: 0...w),
                y:     CGFloat.random(in: -60...(-10)),
                vx:    CGFloat.random(in: -2...2),
                vy:    CGFloat.random(in: 2...7),
                rot:   Double.random(in: 0...360),
                rotV:  Double.random(in: -8...8),
                scale: CGFloat.random(in: 0.5...1.2),
                color: colors.randomElement()!,
                shape: [Particle.ParticleShape.rect, .rect, .circle].randomElement()!
            )
            p.life = Double.random(in: 0.6...1.0)
            particles.append(p)
        }
    }

    private func updateParticles(geo: GeometryProxy) {
        let gravity: CGFloat = 0.12
        particles = particles.compactMap { var p = $0
            p.x    += p.vx
            p.y    += p.vy
            p.vy   += gravity
            p.vx   *= 0.99
            p.rot  += p.rotV
            p.life -= 0.008
            p.alpha = max(0, p.life)
            return p.life > 0 && p.y < geo.size.height + 40 ? p : nil
        }
        // Continuously spawn while active
        if active && particles.count < 120 {
            spawnBurst(geo: geo, count: 8)
        }
    }
}

// MARK: ─── Dark particles (undercover win) ───────────────────────────────────

struct SmokeParticleView: View {
    let active: Bool

    @State private var particles: [Particle] = []
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color.opacity(p.alpha * 0.5))
                        .frame(width: 20 * p.scale, height: 20 * p.scale)
                        .position(x: p.x, y: p.y)
                        .blur(radius: 8 * p.scale)
                }
            }
            .onReceive(timer) { _ in
                guard active else { return }
                updateParticles(geo: geo)
            }
            .onChange(of: active) { _, newVal in
                if newVal { spawnInitial(geo: geo) }
                else      { particles = [] }
            }
        }
        .allowsHitTesting(false)
    }

    private func spawnInitial(geo: GeometryProxy) {
        let cx = geo.size.width / 2, cy = geo.size.height / 2
        for _ in 0..<30 {
            particles.append(Particle(
                x: cx + CGFloat.random(in: -80...80),
                y: cy + CGFloat.random(in: -80...80),
                vx: CGFloat.random(in: -1.5...1.5),
                vy: CGFloat.random(in: -2.5...(-0.5)),
                rot: 0, rotV: 0,
                scale: CGFloat.random(in: 0.8...2.5),
                color: [Color.brandPink, Color(hex: "#600010"), Color(hex: "#1A0020")].randomElement()!,
                shape: .circle
            ))
        }
    }

    private func updateParticles(geo: GeometryProxy) {
        particles = particles.compactMap { var p = $0
            p.x    += p.vx
            p.y    += p.vy
            p.scale *= 1.015
            p.life  -= 0.012
            p.alpha  = max(0, p.life)
            return p.life > 0 ? p : nil
        }
        if active && particles.count < 40 {
            spawnInitial(geo: geo)
        }
    }
}

// MARK: ─── White sparkle (Mr. White win) ─────────────────────────────────────

struct SparkleView: View {
    let active: Bool

    @State private var particles: [Particle] = []
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color.opacity(p.alpha))
                        .frame(width: 6 * p.scale, height: 6 * p.scale)
                        .position(x: p.x, y: p.y)
                        .blur(radius: p.scale)
                }
            }
            .onReceive(timer) { _ in guard active else { return }; updateParticles(geo: geo) }
            .onChange(of: active) { _, newVal in
                if newVal { spawnBurst(geo: geo) }
                else      { particles = [] }
            }
        }
        .allowsHitTesting(false)
    }

    private func spawnBurst(geo: GeometryProxy) {
        let cx = geo.size.width / 2, cy = geo.size.height * 0.4
        for _ in 0..<60 {
            let angle = Double.random(in: 0...360) * .pi / 180
            let speed = CGFloat.random(in: 1...6)
            particles.append(Particle(
                x: cx, y: cy,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                rot: 0, rotV: 0,
                scale: CGFloat.random(in: 0.6...2.0),
                color: [Color.white, Color.accentWhite, Color.brandPurpleLight].randomElement()!,
                shape: .circle,
                life: Double.random(in: 0.5...1.0)
            ))
        }
    }

    private func updateParticles(geo: GeometryProxy) {
        particles = particles.compactMap { var p = $0
            p.x   += p.vx; p.vx *= 0.96
            p.y   += p.vy; p.vy *= 0.96
            p.life -= 0.015
            p.alpha = max(0, p.life)
            return p.life > 0 ? p : nil
        }
    }
}

// MARK: ─── Shape renderer ─────────────────────────────────────────────────────

private struct ParticleShape: View {
    let p: Particle

    var body: some View {
        Group {
            switch p.shape {
            case .rect:
                Rectangle()
                    .fill(p.color)
                    .frame(width: 8 * p.scale, height: 5 * p.scale)
                    .rotationEffect(.degrees(p.rot))
            case .circle:
                Circle().fill(p.color).frame(width: 7 * p.scale, height: 7 * p.scale)
            case .star:
                Image(systemName: "star.fill")
                    .foregroundStyle(p.color)
                    .font(.system(size: 8 * p.scale))
                    .rotationEffect(.degrees(p.rot))
            }
        }
    }
}
