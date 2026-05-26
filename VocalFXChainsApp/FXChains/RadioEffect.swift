//
//  Radio.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 25..
//

import SwitchboardSDK

class RadioEffect: FXChain {
    override func graphJSON(prefix: String) -> String {
        """
        {
            "nodes": [
                {"id": "\(prefix)FilterNode", "type": "Superpowered.Filter"},
                {"id": "\(prefix)DistortionNode", "type": "Superpowered.GuitarDistortion"},
                {"id": "\(prefix)ReverbNode", "type": "Superpowered.Reverb"}
            ],
            "connections": [
                {"sourceNode": "inputNode", "destinationNode": "\(prefix)FilterNode"},
                {"sourceNode": "\(prefix)FilterNode", "destinationNode": "\(prefix)DistortionNode"},
                {"sourceNode": "\(prefix)DistortionNode", "destinationNode": "\(prefix)ReverbNode"},
                {"sourceNode": "\(prefix)ReverbNode", "destinationNode": "outputNode"}
            ]
        }
        """
    }

    override func setLowPreset(prefix: String) {
        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)FilterNode")
        Switchboard.setValue(2, forKey: "type", onObject: "\(prefix)FilterNode")       // Bandlimited_Bandpass
        Switchboard.setValue(Float(3648.0), forKey: "frequency", onObject: "\(prefix)FilterNode")
        Switchboard.setValue(Float(0.7), forKey: "octave", onObject: "\(prefix)FilterNode")

        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.008), forKey: "mix", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.7), forKey: "width", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.5), forKey: "damp", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.5), forKey: "roomSize", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(10.0), forKey: "predelayMs", onObject: "\(prefix)ReverbNode")
    }

    override func setHighPreset(prefix: String) {
        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)FilterNode")
        Switchboard.setValue(2, forKey: "type", onObject: "\(prefix)FilterNode")       // Bandlimited_Bandpass
        Switchboard.setValue(Float(3648.0), forKey: "frequency", onObject: "\(prefix)FilterNode")
        Switchboard.setValue(Float(0.3), forKey: "octave", onObject: "\(prefix)FilterNode")

        Switchboard.setValue(true, forKey: "enabled", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.015), forKey: "mix", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.7), forKey: "width", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.5), forKey: "damp", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(0.75), forKey: "roomSize", onObject: "\(prefix)ReverbNode")
        Switchboard.setValue(Float(10.0), forKey: "predelayMs", onObject: "\(prefix)ReverbNode")
    }
}
