//
//  DelayView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 30.03.24.
//

import SwiftUI

struct DelayView: View {
    
    let number: Int
    let action: (Float, Float, Float, Float, Int) -> Void
    
    @State var feedback: Float = 50
    @State var delayTime: Float = 0
    @State var cutoff: Float = 1500
    @State var mix: Float = 0

    var body: some View {
        VStack {
            HStack {
                HStack {
                    Text("F: ")
                        .font(.title2)
                    Slider(value: $feedback, in: -100...100)
                }
                HStack {
                    Text("T: ")
                        .font(.title2)
                    Slider(value: $delayTime, in: 0...2)
                }
            }
            HStack {
                HStack {
                    Text("C: ")
                        .font(.title2)
                    Slider(value: $cutoff, in: 10...22050)
                }
                HStack {
                    Text("M: ")
                        .font(.title2)
                    Slider(value: $mix, in: 0...100)
                }
            }

        }
        .onChange(of: feedback) { oldValue, newValue in
            action(newValue, delayTime, cutoff, mix, number)
        }
        .onChange(of: delayTime) { oldValue, newValue in
            action(feedback, newValue, cutoff, mix, number)
        }
        .onChange(of: cutoff) { oldValue, newValue in
            action(feedback, delayTime, newValue, mix, number)
        }
        .onChange(of: mix) { oldValue, newValue in
            action(feedback, delayTime, cutoff, newValue, number)
        }
    }
}

#Preview {
    DelayView(number: 0) {_,_,_,_,_ in }
}
