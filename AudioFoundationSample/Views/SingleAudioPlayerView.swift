//
//  SingleAudioPlayerView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 29.03.24.
//

import SwiftUI
import AVFAudio

struct SingleAudioPlayerView: View {
    @StateObject private var audioPlayer = SingleAudioPlayer()

    var body: some View {
        VStack {
            VStack {
                PlayerButtonView(number: 0, title: "Bass", isPlaying: audioPlayer.isPlaying) { play, _ in
                    if play {
                        audioPlayer.play()
                    } else {
                        audioPlayer.stop()
                    }
                }
            }
            Spacer()
            HStack {
                Spacer()
                Toggle("Use Speaker", isOn: $audioPlayer.useSpeaker)
                    .toggleStyle(.switch)
                    .tint(.gray)
                Spacer()
            }
            .padding()
        }
        .padding()
        .onAppear() {
            audioPlayer.configure()
            audioPlayer.createPlayer()
        }
    }
}

@MainActor
final class SingleAudioPlayer: NSObject, ObservableObject {
    @Published var useSpeaker = true {
        didSet {
            configure()
        }
    }
    @Published var isPlaying = false
    private var player: AVAudioPlayer?
    
    func configure() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)
            try session.setCategory(useSpeaker ? .playAndRecord : .playback)
            try session.overrideOutputAudioPort(useSpeaker ? .speaker : .none)
        } catch {
            print("💀 Error setting up audio session")
        }
    }

    func createPlayer() {
        guard let url = Bundle.main.url(forResource: "NW_DDNP_115_kit_just_bass_G#min.wav", withExtension: nil),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return }
        player.volume = 1.0
        player.delegate = self
        player.enableRate = true
        player.prepareToPlay()
        self.player = player
    }
    
    func play() {
        player?.play()
        withAnimation { isPlaying = true }
    }
    
    func stop() {
        player?.stop()
        withAnimation { isPlaying = false }
    }
}

extension SingleAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        withAnimation { isPlaying = player.isPlaying }
    }
}

#Preview {
    SingleAudioPlayerView()
}
