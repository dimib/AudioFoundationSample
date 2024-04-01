//
//  Resources.swift
//  AudioFoundationSample
//
//  Created by Dimitri Brukakis on 01.04.24.
//

import Foundation

struct Resources {
    static let audioFiles = [
        "NW_DDNP_115_kit_just_bass_G#min.wav",
        "OS_VLV_115_Drum_Loop_3__Full_.wav",
        "OS_UTP2_115_Cmin_Hope_Stack.wav",
        "OS_VLV_115_Amin_Silk_Stack__Original_.wav"
    ]
    
    static func bundleUrl(for resource: String) -> URL? {
        Bundle.main.url(forResource: resource, withExtension: nil)
    }
    
}
