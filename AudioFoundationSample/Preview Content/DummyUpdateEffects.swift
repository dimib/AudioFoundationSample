//
//  DummyUpdateEffects.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 30.03.24.
//

import Foundation

final class DummyUpdateEffects: UpdateEffectsProtocol {
    func changeDelay(feedback: Float, delayTime: Float, cutoff: Float, mix: Float, number: Int) {
        print("Delay \(number) \(feedback) \(delayTime) \(cutoff) \(mix)")
    }
    
    func changeLowpass(cutoff: Float, resonance: Float, number: Int) {
        print("Filter \(number) \(cutoff) \(resonance)")
    }
    
    func getDelay(of number: Int) -> (feedback: Float, delayTime: Float, cutoff: Float, mix: Float) {
        return (0, 0, 0, 0)
    }
    
    func getLowpass(of number: Int) -> (cutoff: Float, resonance: Float) {
        return (0, 0)
    }
}
