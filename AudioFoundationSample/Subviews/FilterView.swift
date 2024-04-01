//
//  FilterView.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 30.03.24.
//

import SwiftUI

struct FilterView: View {
    let number: Int
    let action: (Float, Float, Int) -> Void
    
    @State var cutoff: Float = 6900
    @State var resonance: Float = 0

    var body: some View {
        
        VStack {
            HStack {
                Text("C: ")
                    .font(.title2)
                Slider(value: $cutoff, in: 200...12000)
            }
            HStack {
                Text("R: ")
                    .font(.title2)
                Slider(value: $resonance, in: -20...40)
            }
        }
        .onChange(of: cutoff) { oldValue, newValue in
            action(newValue, resonance, number)
        }
        .onChange(of: resonance) { oldValue, newValue in
            action(cutoff, newValue, number)
        }
    }
}

#Preview {
    FilterView(number: 0) {_,_,_ in }
}
