//
//  LoadingView.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import SwiftUI

struct LoadingView: View {

    var body: some View {

        ZStack {

            LinearGradient.brandBackground
                .ignoresSafeArea()

            VStack(spacing:20) {

                Text("🕵️")
                    .font(.system(size:60))

                ProgressView()
                    .tint(.white)

                Text("Preparing the game...")
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}
