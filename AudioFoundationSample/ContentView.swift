//
//  ContentView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 29.03.24.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationStack {
            NavigationLink(destination: { SingleAudioPlayerView() }) {
                VStack {
                    Text("Single Player")
                        .tint(.white)
                        .font(.title)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(.gray)
                .cornerRadius(20)
                .padding(.horizontal, 20)
            }
            NavigationLink(destination: { SimulataneousAudioPlayerView() }) {
                VStack {
                    Text("Simultaneous Player")
                        .tint(.white)
                        .font(.title)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(.gray)
                .cornerRadius(20)
                .padding(.horizontal, 20)
            }
            NavigationLink(destination: { AudioEnginePlayerView() }) {
                VStack {
                    Text("Audio Engine Player")
                        .tint(.white)
                        .font(.title)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(.gray)
                .cornerRadius(20)
                .padding(.horizontal, 20)
            }
            NavigationLink(destination: { AudioUnitCompositionPlayerView() }) {
                VStack {
                    Text("AU Composition Player")
                        .tint(.white)
                        .font(.title)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(.gray)
                .cornerRadius(20)
                .padding(.horizontal, 20)
            }
        }
    }
}

    
#Preview {
    ContentView()
}
