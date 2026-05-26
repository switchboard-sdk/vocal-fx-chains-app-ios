//
//  Harmonizer.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 25..
//

import SwitchboardSDK

class HarmonizerEffect: FXChain {
    override func graphJSON(prefix: String) -> String {
        """
        {
            "nodes": [
                {"id": "\(prefix)AvpcNode", "type": "Superpowered.AutomaticVocalPitchCorrection"},
                {"id": "\(prefix)BusSplitterNode", "type": "BusSplitter"},
                {"id": "\(prefix)LowPitchShiftNode", "type": "Superpowered.PitchShift"},
                {"id": "\(prefix)LowGainNode", "type": "Switchboard.Gain"},
                {"id": "\(prefix)HighPitchShiftNode", "type": "Superpowered.PitchShift"},
                {"id": "\(prefix)HighGainNode", "type": "Switchboard.Gain"},
                {"id": "\(prefix)MixerNode", "type": "Mixer"},
                {"id": "\(prefix)ReverbNode", "type": "Superpowered.Reverb"}
            ],
            "connections": [
                {"sourceNode": "inputNode", "destinationNode": "\(prefix)AvpcNode"},
                {"sourceNode": "\(prefix)AvpcNode", "destinationNode": "\(prefix)BusSplitterNode"},
                {"sourceNode": "\(prefix)BusSplitterNode", "destinationNode": "\(prefix)LowPitchShiftNode"},
                {"sourceNode": "\(prefix)BusSplitterNode", "destinationNode": "\(prefix)HighPitchShiftNode"},
                {"sourceNode": "\(prefix)BusSplitterNode", "destinationNode": "\(prefix)MixerNode"},
                {"sourceNode": "\(prefix)LowPitchShiftNode", "destinationNode": "\(prefix)LowGainNode"},
                {"sourceNode": "\(prefix)LowGainNode", "destinationNode": "\(prefix)MixerNode"},
                {"sourceNode": "\(prefix)HighPitchShiftNode", "destinationNode": "\(prefix)HighGainNode"},
                {"sourceNode": "\(prefix)HighGainNode", "destinationNode": "\(prefix)MixerNode"},
                {"sourceNode": "\(prefix)MixerNode", "destinationNode": "\(prefix)ReverbNode"},
                {"sourceNode": "\(prefix)ReverbNode", "destinationNode": "outputNode"}
            ]
        }
        """
    }

    override func setLowPreset(prefix: String) {
        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)AvpcNode")
        Switchboard.setValue(1, forKey: "speed", onObject: "\(prefix)AvpcNode")   // MEDIUM
        Switchboard.setValue(0, forKey: "range", onObject: "\(prefix)AvpcNode")   // WIDE
        Switchboard.setValue(1, forKey: "scale", onObject: "\(prefix)AvpcNode")   // CMAJOR

        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)LowPitchShiftNode")
        Switchboard.setValue(-400, forKey: "pitchShiftCents", onObject: "\(prefix)LowPitchShiftNode")
        Switchboard.setValue(Float(0.4), forKey: "gain", onObject: "\(prefix)LowGainNode")

        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)HighPitchShiftNode")
        Switchboard.setValue(400, forKey: "pitchShiftCents", onObject: "\(prefix)HighPitchShiftNode")
        Switchboard.setValue(Float(0.4), forKey: "gain", onObject: "\(prefix)HighGainNode")

        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.008), forKey: "mix", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.7), forKey: "width", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.5), forKey: "damp", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.5), forKey: "roomSize", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(10.0), forKey: "predelayMs", onObject: "\(prefix)ReverbNode")
    }

    override func setHighPreset(prefix: String) {
        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)AvpcNode")
        Switchboard.setValue(2, forKey: "speed", onObject: "\(prefix)AvpcNode")   // EXTREME
        Switchboard.setValue(0, forKey: "range", onObject: "\(prefix)AvpcNode")   // WIDE
        Switchboard.setValue(1, forKey: "scale", onObject: "\(prefix)AvpcNode")   // CMAJOR

        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)LowPitchShiftNode")
        Switchboard.setValue(-400, forKey: "pitchShiftCents", onObject: "\(prefix)LowPitchShiftNode")
        Switchboard.setValue(Float(1.0), forKey: "gain", onObject: "\(prefix)LowGainNode")

        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)HighPitchShiftNode")
        Switchboard.setValue(400, forKey: "pitchShiftCents", onObject: "\(prefix)HighPitchShiftNode")
        Switchboard.setValue(Float(1.0), forKey: "gain", onObject: "\(prefix)HighGainNode")

        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.015), forKey: "mix", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.7), forKey: "width", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.5), forKey: "damp", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.75), forKey: "roomSize", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(10.0), forKey: "predelayMs", onObject: "\(prefix)ReverbNode")
    }
}
