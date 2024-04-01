//
//  PlayerButtonView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 29.03.24.
//

import SwiftUI

struct PlayerButtonView: View {
    
    let number: Int
    let title: String
    let isPlaying: Bool
    let action: (Bool, Int) -> Void
    
    var body: some View {
        VStack {
            Button(action: {
                if isPlaying {
                    action(false, number)
                } else {
                    action(true, number)
                }
            }) {
                VStack {
                    image
                        .resizable()
                        .foregroundStyle(color)
                        .frame(width: 100, height: 100)
                    Text(title)
                        .font(.footnote)
                        .foregroundStyle(color)
                }
            }
        }
    }
    
    var color: Color {
        isPlaying ? .green : .gray
    }
    var image: Image {
        isPlaying ? Image(systemName: "stop.circle") : Image(systemName: "play.circle")
    }
}

#Preview {
    PlayerButtonView(number: 0, title: "Bass", isPlaying: false, action: { _, _ in })
}
