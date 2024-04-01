//
//  AudioSessionView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 01.04.24.
//

import Foundation
import AVFAudio
import SwiftUI

struct AudioEnginePlayerView: View {
    @StateObject private var audioPlayer = AudioEnginePlayer()

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
            audioPlayer.createEngines()
        }
    }
}

@MainActor
final class AudioEnginePlayer: NSObject, ObservableObject {
    
    public enum PlayerError: Error {
        case playerCreation
    }
    
    @Published var useSpeaker = true {
        didSet {
            configure()
        }
    }
    @Published var isPlaying = [false, false, false, false]
    private var engines: [AVAudioEngine] = []
    
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
    
    deinit {
//        for player in engines {
//            if let playerNode = player.attachedNodes.first(where: { $0 is AVAudioPlayerNode}) as? AVAudioPlayerNode {
//                player.disconnectNodeInput(playerNode)
//                player.detach(playerNode)
//            }
//        }
    }

    func createEngines() {
        do {
            self.engines = try Resources.audioFiles.map { try createEngine(resource: $0) }
        } catch {
            print("💀 Error setting up audio session")
        }
    }
    
    func createEngine(resource: String) throws -> AVAudioEngine {
        guard let url = Bundle.main.url(forResource: resource, withExtension: nil),
              let audioFile = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
        else {
            throw PlayerError.playerCreation
        }
        
        try audioFile.read(into: buffer)

        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.outputNode, format: audioFile.processingFormat)
        engine.prepare()
        playerNode.scheduleBuffer(buffer, at: nil, options: [.loops])
        try engine.start()
        return engine
    }
    
    func play(play: Bool, player: Int) {
        if play {
            self.play(player: player)
        } else {
            self.stop(player: player)
        }
    }
    
    func play(player: Int) {
        guard let playerNode = playerNode(from: engines[player]) else { return }
        playerNode.play(at: AVAudioTime(hostTime: 0))
        updatePlayerState(player: player, playing: true)
    }
    
    func stop(player: Int, reset: Bool = true) {
        guard let playerNode = playerNode(from: engines[player]) else { return }
        playerNode.pause()
        playerNode.nodeTime(forPlayerTime: AVAudioTime(hostTime: 0))
        updatePlayerState(player: player, playing: false)
    }

    private func updatePlayerState(player: Int, playing: Bool) {
        var isPlaying = isPlaying
        isPlaying[player] = playing
        self.isPlaying = isPlaying
    }

    private func updatePlayerState() {
        isPlaying = engines.map { playerNode(from: $0)?.isPlaying == true }
    }
    
    private func playerNode(from engine: AVAudioEngine) -> AVAudioPlayerNode? {
        engine.attachedNodes.first(where: { $0 is AVAudioPlayerNode}) as? AVAudioPlayerNode
    }
}

extension AudioEnginePlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updatePlayerState()
    }
}

#Preview {
    AudioEnginePlayerView()
}
