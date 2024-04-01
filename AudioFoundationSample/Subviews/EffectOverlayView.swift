//
//  EffectOverlayView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 30.03.24.
//

import SwiftUI

protocol UpdateEffectsProtocol {
    func changeDelay(feedback: Float, delayTime: Float, cutoff: Float, mix: Float, number: Int)
    func changeLowpass(cutoff: Float, resonance: Float, number: Int)
    
    func getDelay(of number: Int) -> (feedback: Float, delayTime: Float, cutoff: Float, mix: Float)
    func getLowpass(of number: Int) -> (cutoff: Float, resonance: Float)
}

struct EffectOverlayView: View {
    var updateEffects: UpdateEffectsProtocol
    @Binding var number: Int

    var body: some View {
        VStack(spacing: 24) {
            VStack {
                Text("Delay")
                    .font(.title)
                DelayView(number: number) { feedback, delayTime, cutoff, mix, number in
                    print("Delay \(number) \(feedback) \(delayTime) \(cutoff) \(mix)")
                    updateEffects.changeDelay(feedback: feedback, delayTime: delayTime,
                                              cutoff: cutoff, mix: mix, number: number)
                }
            }
            VStack {
                Text("Low pass filter")
                    .font(.title)
                FilterView(number: number) { cutoff, resonance, number in
                    print("Filter \(number) \(cutoff) \(resonance)")
                    updateEffects.changeLowpass(cutoff: cutoff, resonance: resonance, number: number)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}



#Preview {
    EffectOverlayView(updateEffects: DummyUpdateEffects(), number: .constant(0))
}
