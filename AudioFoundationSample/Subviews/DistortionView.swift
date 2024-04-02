//
//  DistortionView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 02.04.24.
//

import SwiftUI

struct DistortionView: View {
    let number: Int
    let action: (Float, Float, Int) -> Void
    
    @State var percent: Float = 0
    @State var gain: Float = -80
    @State var enabled: Bool = false

    var body: some View {
        
        VStack(spacing: 0) {
            HStack {
                Text("P: ")
                    .font(.title2)
                Slider(value: $percent, in: 0...100)
            }
            HStack {
                Text("G: ")
                    .font(.title2)
                Slider(value: $gain, in: -80...20)
            }
        }
        .background(Color.orange)
        .onChange(of: percent) { oldValue, newValue in
            action(newValue, gain, number)
        }
        .onChange(of: gain) { oldValue, newValue in
            action(percent, newValue, number)
        }
    }
}

#Preview {
    DistortionView(number: 0) {_,_,_ in }
}
