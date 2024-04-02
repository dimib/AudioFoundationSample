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
    @StateObject var audioPlayer: AudioEnginePlayer

    var body: some View {
        VStack {
            HStack(spacing: 48) {
                VStack {
                    PlayerButtonView(number: 0, title: "Bass", isPlaying: audioPlayer.isPlaying[0], action: audioPlayer.play)
                    if audioPlayer.withEffects {
                        VStack(spacing: 0) {
                            FilterView(number: 0, action: audioPlayer.lowPass)
                            DistortionView(number: 0, action: audioPlayer.distortion)
                        }
                    }
                }
                VStack {
                    PlayerButtonView(number: 1, title: "Drums", isPlaying: audioPlayer.isPlaying[1], action: audioPlayer.play)
                    if audioPlayer.withEffects {
                        VStack(spacing: 0) {
                            FilterView(number: 1, action: audioPlayer.lowPass)
                            DistortionView(number: 1, action: audioPlayer.distortion)
                        }
                    }
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
            .padding(.vertical, 12)
            

            HStack(spacing: 48) {
                VStack {
                    PlayerButtonView(number: 2, title: "Hope Stack", isPlaying: audioPlayer.isPlaying[2], action: audioPlayer.play)
                    if audioPlayer.withEffects {
                        VStack(spacing: 0) {
                            FilterView(number: 2, action: audioPlayer.lowPass)
                            DistortionView(number: 2, action: audioPlayer.distortion)
                        }
                    }

                }
                VStack {
                    PlayerButtonView(number: 3, title: "Silk Stack", isPlaying: audioPlayer.isPlaying[3], action: audioPlayer.play)
                    if audioPlayer.withEffects {
                        VStack(spacing: 0) {
                            FilterView(number: 3, action: audioPlayer.lowPass)
                            DistortionView(number: 3, action: audioPlayer.distortion)
                        }
                    }

                }
            }

            Spacer()
//            HStack {
//                Text("Volume")
//                Slider(value: $audioPlayer.volume, in: 0...1)
//            }
//            .padding(.horizontal, 24)
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
    
    @Published var useSpeaker = false {
        didSet {
            for player in 0...3 {
                stop(player: player)
            }
            configure()
            createEngines()
        }
    }
    @Published var volume: Float = 1 {
        didSet {
            engines[0].mainMixerNode.volume = volume
        }
    }
    @Published var isPlaying = [false, false, false, false]
    private var engines: [AVAudioEngine] = []
    private var distortion = [false, false, false, false]
    
    let withEffects: Bool
    
    init(withEffects: Bool = false) {
        self.withEffects = withEffects
        super.init()
    }
    
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

    func createEngines() {
        do {
            self.engines = try Resources.audioFiles.map {
                if withEffects {
                    try createEngineWithEffects(resource: $0)
                } else {
                    try createEngine(resource: $0)
                }
            }
        } catch {
            print("💀 Error setting up audio session")
        }
    }
    
    private func createEngine(resource: String) throws -> AVAudioEngine {

        guard let url = Bundle.main.url(forResource: resource, withExtension: nil),
              let audioFile = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                            frameCapacity: AVAudioFrameCount(audioFile.length))
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

    private func createEngineWithEffects(resource: String) throws -> AVAudioEngine {

        guard let url = Bundle.main.url(forResource: resource, withExtension: nil),
              let audioFile = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                            frameCapacity: AVAudioFrameCount(audioFile.length))
        else {
            throw PlayerError.playerCreation
        }
            
        try audioFile.read(into: buffer)

        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        let lowPassUnit = attachLowPassFilter(engine: engine)
        let distortionUnit = attachDistortion(engine: engine)
        engine.connect(playerNode, to: lowPassUnit, format: audioFile.processingFormat)
        engine.connect(lowPassUnit, to: distortionUnit, format: audioFile.processingFormat)
        engine.connect(distortionUnit, to: engine.mainMixerNode, format: audioFile.processingFormat)
        engine.prepare()
        playerNode.scheduleBuffer(buffer, at: nil, options: [.loops])
        try engine.start()
        
        distortion(param1: 0, param2: -80, engine: engine)
        return engine
    }
        
    // MARK: - Play and Stop

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
    
    // MARK: - Main Mixer
    
    // MARK: - Low Pass Filter Effects
    
    private func attachLowPassFilter(engine: AVAudioEngine) -> AVAudioUnitEffect {
        let lowPassDescription = AudioComponentDescription(componentType: kAudioUnitType_Effect,
                                                           componentSubType: kAudioUnitSubType_LowPassFilter,
                                                           componentManufacturer: kAudioUnitManufacturer_Apple,
                                                           componentFlags: 0, componentFlagsMask: 0)
        let lowPassUnit = AVAudioUnitEffect(audioComponentDescription: lowPassDescription)
        engine.attach(lowPassUnit)
        return lowPassUnit
    }
    
    func lowPass(cutoff: Float, resonance: Float, player: Int) {
        guard let lowPassUnit = lowPassUnit(from: engines[player]) else { return }
        AudioUnitSetParameter(lowPassUnit.audioUnit, kLowPassParam_CutoffFrequency, kAudioUnitScope_Global, 0, cutoff, 0)
        AudioUnitSetParameter(lowPassUnit.audioUnit, kLowPassParam_Resonance, kAudioUnitScope_Global, 0, resonance, 0)
    }

    private func lowPassUnit(from engine: AVAudioEngine) -> AVAudioUnitEffect? {
        engine.attachedNodes.first(where: {
            if let effect = $0 as? AVAudioUnitEffect {
                effect.audioComponentDescription.componentSubType == kAudioUnitSubType_LowPassFilter
            } else {
                false
            }
        }) as? AVAudioUnitEffect
    }
    
    // MARK: - Distortion Effect

    private func attachDistortion(engine: AVAudioEngine) -> AVAudioUnitEffect {
        let distortionDescription = AudioComponentDescription(componentType: kAudioUnitType_Effect,
                                                              componentSubType: kAudioUnitSubType_Distortion,
                                                              componentManufacturer: kAudioUnitManufacturer_Apple,
                                                              componentFlags: 0, componentFlagsMask: 0)
        let distortionUnit = AVAudioUnitEffect(audioComponentDescription: distortionDescription)
        engine.attach(distortionUnit)
        return distortionUnit
    }
    
    func distortion(param1: Float, param2: Float, player: Int) {
        distortion(param1: param1, param2: param2, engine: engines[player])
    }

    private func distortion(param1: Float, param2: Float, engine: AVAudioEngine) {
        guard let distortionUnit = distortionUnit(from: engine) else { return }
        AudioUnitSetParameter(distortionUnit.audioUnit, kDistortionParam_Decimation, kAudioUnitScope_Global, 0, param1, 0)
        AudioUnitSetParameter(distortionUnit.audioUnit, kDistortionParam_SoftClipGain, kAudioUnitScope_Global, 0, param2, 0)
    }
    func distortion(bypass: Bool, player: Int) {
        guard let distortionUnit = distortionUnit(from: engines[player]) else { return }
        distortionUnit.bypass = true
    }

    private func distortionUnit(from engine: AVAudioEngine) -> AVAudioUnitEffect? {
        engine.attachedNodes.first(where: {
            if let effect = $0 as? AVAudioUnitEffect {
                effect.audioComponentDescription.componentSubType == kAudioUnitSubType_Distortion
            } else {
                false
            }
        }) as? AVAudioUnitEffect
    }
}

extension AudioEnginePlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updatePlayerState()
    }
}

#Preview {
    AudioEnginePlayerView(audioPlayer: AudioEnginePlayer(withEffects: true))
}
