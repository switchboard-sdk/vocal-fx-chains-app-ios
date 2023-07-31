//
//  Radio.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 25..
//

import SwitchboardSDK
import SwitchboardSuperpowered

class RadioEffect: FXChain {
    let bandpassFilterNode = SBFilterNode()
    let distortionNode = SBGuitarDistortionNode()
    let reverbNode = SBReverbNode()

    func setLowPreset() {
        bandpassFilterNode.isEnabled = true
        bandpassFilterNode.type = Bandlimited_Bandpass
        bandpassFilterNode.frequency = 3648.0
        bandpassFilterNode.octave = 0.7

        reverbNode.isEnabled = true
        reverbNode.mix = 0.008
        reverbNode.width = 0.7
        reverbNode.damp = 0.5
        reverbNode.roomSize = 0.5
        reverbNode.predelayMs = 10.0
    }

    func setHighPreset() {
        bandpassFilterNode.isEnabled = true
        bandpassFilterNode.type = Bandlimited_Bandpass
        bandpassFilterNode.frequency = 3648.0
        bandpassFilterNode.octave = 0.3

        reverbNode.isEnabled = true
        reverbNode.mix = 0.015
        reverbNode.width = 0.7
        reverbNode.damp = 0.5
        reverbNode.roomSize = 0.75
        reverbNode.predelayMs = 10.0
    }

    override init() {
        super.init()

        switch Config.radioPreset {
        case 0:
            setLowPreset()
        default:
            setHighPreset()
        }

        audioGraph.addNode(bandpassFilterNode)
        audioGraph.addNode(distortionNode)
        audioGraph.addNode(reverbNode)

        audioGraph.connect(audioGraph.inputNode, to: bandpassFilterNode)
        audioGraph.connect(bandpassFilterNode, to: distortionNode)
        audioGraph.connect(distortionNode, to: reverbNode)
        audioGraph.connect(reverbNode, to: audioGraph.outputNode)

        audioGraph.start()
    }
}
