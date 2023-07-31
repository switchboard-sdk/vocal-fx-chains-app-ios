//
//  Config.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 24..
//

import Foundation
import SwitchboardSDK

struct Config {
    static let clientID = "Synervoz"
    static let clientSecret = "VocalFXChainsApp"
    static let superpoweredLicenseKey = "ExampleLicenseKey-WillExpire-OnNextUpdate"


    static var cleanVocalRecordingFilePath: String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].absoluteString + "vocal_recording_clean.wav"
    }
    
    static let recordingFormat: SBCodec = .wav


    static var finalMixRecordingFile: String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].absoluteString + "final_mix.wav"
    }

    static var applyFXChain = false
    static var selectedFXChainIndex = 0
    static var harmonizerPreset = 0
    static var radioPreset = 0
}
