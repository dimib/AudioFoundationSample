//
//  SimultaneousAudioPlayerView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 29.03.24.
//

import SwiftUI
import AVFAudio

struct SimulataneousAudioPlayerView: View {
    @StateObject private var audioPlayer = SimulataneousAudioPlayer()

    var body: some View {
        VStack {
            HStack(spacing: 48) {
                PlayerButtonView(number: 0, title: "Bass", isPlaying: audioPlayer.isPlaying[0]) { play, number in
                    audioPlayer.play(play: play, player: number)
                }

                PlayerButtonView(number: 1, title: "Drums", isPlaying: audioPlayer.isPlaying[1]) { play, number in
                    audioPlayer.play(play: play, player: number)
                }
            }
            HStack(spacing: 24) {
                Button(action: {
                    audioPlayer.stop(player: 0, reset: true)
                    audioPlayer.stop(player: 1, reset: true)
                    audioPlayer.stop(player: 2, reset: true)
                    audioPlayer.stop(player: 3, reset: true)
                }) {
                    Text("Stop all")
                        .foregroundColor(.red)
                }
                Button(action: {
                    audioPlayer.play(player: 0)
                    audioPlayer.play(player: 1)
                    audioPlayer.play(player: 2)
                    audioPlayer.play(player: 3)
                }) {
                    Text("Play all")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 42)

            HStack(spacing: 48) {
                PlayerButtonView(number: 2, title: "Hope Stack", isPlaying: audioPlayer.isPlaying[2]) { play, number in
                    audioPlayer.play(play: play, player: number)
                }

                PlayerButtonView(number: 3, title: "Silk Stack", isPlaying: audioPlayer.isPlaying[3]) { play, number in
                    audioPlayer.play(play: play, player: number)
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
        .task() {
            audioPlayer.configure()
            audioPlayer.createPlayers()
        }
    }
}

@MainActor
final class SimulataneousAudioPlayer: NSObject, ObservableObject {
    
    public enum PlayerError: Error {
        case playerCreation
    }
    
    @Published var useSpeaker = true {
        didSet {
            configure()
        }
    }
    @Published var isPlaying = [false, false, false, false]
    private var players: [AVAudioPlayer] = []
    
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

    func createPlayers() {
        do {
            self.players = try Resources.audioFiles.map { try createPlayer(resource: $0) }
        } catch {
            print("💀 Error setting up audio session")
        }
    }
    
    func createPlayer(resource: String) throws -> AVAudioPlayer {
        guard let url = Bundle.main.url(forResource: resource, withExtension: nil),
              let player = try? AVAudioPlayer(contentsOf: url) else { throw PlayerError.playerCreation }
        player.volume = 1.0
        player.delegate = self
        player.numberOfLoops = 10
        player.prepareToPlay()
        return player
    }
    
    func play(play: Bool, player: Int) {
        if play {
            self.play(player: player)
        } else {
            self.stop(player: player)
        }
    }
    
    func play(player: Int) {
        players[player].play()
        updatePlayerState()
    }
    
    func stop(player: Int, reset: Bool = true) {
        players[player].stop()
        if reset {
            players[player].currentTime = 0
        }
        updatePlayerState()
    }
    
    private func updatePlayerState() {
        withAnimation {
            isPlaying = players.map { $0.isPlaying }
        }
    }
}

extension SimulataneousAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updatePlayerState()
    }
}

#Preview {
    SimulataneousAudioPlayerView()
}
