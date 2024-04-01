//
//  SimultaneousAudioPlayerView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 29.03.24.
//

import SwiftUI
import AVFAudio
import DBAudioTools

struct AudioUnitCompositionPlayerView: View {
    @StateObject private var audioPlayer = AudioUnitCompositionPlayer()
    
    @State var showEffectOverlay = false
    @State var effectOverlay: Int = 0

    var body: some View {
        VStack {
            HStack(spacing: 48) {
                VStack {
                    PlayerButtonView(number: 0, title: "Bass", isPlaying: audioPlayer.isPlaying[0]) { play, number in
                        audioPlayer.play(play: play, player: number)
                    }
                    Button(action: { showEffectOverlay(number: 0) }) { Text("Effects") }
                }

                VStack {
                    PlayerButtonView(number: 1, title: "Drums", isPlaying: audioPlayer.isPlaying[1]) { play, number in
                        audioPlayer.play(play: play, player: number)
                    }
                    Button(action: { showEffectOverlay(number: 1) }) { Text("Effects") }
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
                VStack {
                    PlayerButtonView(number: 2, title: "Hope Stack", isPlaying: audioPlayer.isPlaying[2]) { play, number in
                        audioPlayer.play(play: play, player: number)
                    }
                    Button(action: { showEffectOverlay(number: 2) }) { Text("Effects") }
                }
                    
                VStack {
                    PlayerButtonView(number: 3, title: "Silk Stack", isPlaying: audioPlayer.isPlaying[3]) { play, number in
                        audioPlayer.play(play: play, player: number)
                    }
                    Button(action: { showEffectOverlay(number: 3) }) { Text("Effects") }
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
        .sheet(isPresented: $showEffectOverlay, onDismiss: { }) {
            EffectOverlayView(updateEffects: audioPlayer, number: $effectOverlay)
        }
    }
    
    private func showEffectOverlay(number: Int) {
        effectOverlay = number
        showEffectOverlay = true
    }
}

@MainActor
final class AudioUnitCompositionPlayer: NSObject, ObservableObject {
    
    public enum PlayerError: Error {
        case playerCreation
    }
    
    @Published var useSpeaker = true {
        didSet {
            configure()
        }
    }
    @Published var isPlaying = [false, false, false, false]
    private var players: [Composition] = []
    
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
    
    func createPlayer(resource: String) throws -> Composition {
        guard let path = Bundle.main.path(forResource: resource, ofType: nil) else { throw PlayerError.playerCreation }
        let audioFile = try AudioFile(path: path)
        let outputUnit = GeneralOutputUnit()
        let delayUnit = DelayEffectUnit()
        delayUnit.nextUnit = outputUnit
        delayUnit.change(parameter: .delayTime(0))
        delayUnit.change(parameter: .feedback(0))
        delayUnit.change(parameter: .wetDryMix(50))
        let lowPassFilter = LowPassFilterEffectUnit()
        lowPassFilter.nextUnit = delayUnit
        let inputUnit = FileInputUnit(inputFile: audioFile)
        inputUnit.nextUnit = lowPassFilter
        inputUnit.loops = 10
        
        let composition = Composition(units: [inputUnit, delayUnit, lowPassFilter, outputUnit])
        try composition.create()
        return composition
    }
    
    func play(play: Bool, player: Int) {
        if play {
            self.play(player: player)
        } else {
            self.stop(player: player)
        }
    }
    
    func play(player: Int) {
        try? players[player].start()
        updatePlayerState()
    }
    
    func stop(player: Int, reset: Bool = true) {
        try? players[player].stop()
        updatePlayerState()
    }
    
    private func updatePlayerState() {
        withAnimation {
            isPlaying = players.map { $0.isPlaying }
        }
    }
    
    func filter(player: Int, cutoff: Float, resonance: Float) {
        guard let filterUnit = players[player].units[1] as? LowPassFilterEffectUnit else { return }
     
        filterUnit.change(parameter: .cutoffFrequency(Float(cutoff)))
    }
}

// MARK: - Update Effects Protocol

extension AudioUnitCompositionPlayer: UpdateEffectsProtocol {
    func getLowpass(of number: Int) -> (cutoff: Float, resonance: Float) {
        guard let filterUnit = players[number].units.first(where: { $0 is LowPassFilterEffectUnit }) as? LowPassFilterEffectUnit else {
            return (0, 0)
        }

        var parameters: (cutoff: Float, resonance: Float) = (0, 0)
        for param in filterUnit.parameters {
            switch param {
            case let .cutoffFrequency(value): parameters.cutoff = value
            case let .resonance(value): parameters.resonance = value
            }
        }
        return parameters
    }
    
    func getDelay(of number: Int) -> (feedback: Float, delayTime: Float, cutoff: Float, mix: Float) {
        guard let filterUnit = players[number].units.first(where: { $0 is DelayEffectUnit }) as? DelayEffectUnit else {
            return (0, 0, 0, 0)
        }
        var parameters: (feedback: Float, delayTime: Float, cutoff: Float, mix: Float) = (0, 0, 0, 0)
        for param in filterUnit.parameters {
            switch param {
            case let .feedback(value): parameters.feedback = value
            case let .delayTime(value): parameters.delayTime = value
            case let .wetDryMix(value): parameters.mix = value
            case let .lowPassCutoff(value): parameters.cutoff = value
            }
        }
        return parameters
    }
    
    func changeDelay(feedback: Float, delayTime: Float, cutoff: Float, mix: Float, number: Int) {
        guard let filterUnit = players[number].units.first(where: { $0 is DelayEffectUnit }) as? DelayEffectUnit else { return }
        filterUnit.change(parameter: .feedback(feedback))
        filterUnit.change(parameter: .delayTime(delayTime))
        filterUnit.change(parameter: .lowPassCutoff(cutoff))
        filterUnit.change(parameter: .wetDryMix(mix))
    }
    
    func changeLowpass(cutoff: Float, resonance: Float, number: Int) {
        guard let filterUnit = players[number].units.first(where: { $0 is LowPassFilterEffectUnit }) as? LowPassFilterEffectUnit else { return }
        filterUnit.change(parameter: .cutoffFrequency(cutoff))
        filterUnit.change(parameter: .resonance(resonance))
    }
}

#Preview {
    AudioUnitCompositionPlayerView()
}
