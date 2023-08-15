//
//  Harmonizer.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 25..
//

import SwitchboardSDK
import SwitchboardSuperpowered

class HarmonizerEffect: FXChain {
    let avpcNode = SBAutomaticVocalPitchCorrectionNode()
    let busSplitterNode = SBBusSplitterNode()
    let lowPitchShiftNode = SBPitchShiftNode()
    let lowPitchShiftGainNode = SBGainNode()
    let highPitchShiftNode = SBPitchShiftNode()
    let highPitchShiftGainNode = SBGainNode()
    let mixerNode = SBMixerNode()
    let reverbNode = SBReverbNode()

    func setLowPreset() {
        avpcNode.isEnabled = true
        avpcNode.speed = MEDIUM
        avpcNode.range = WIDE
        avpcNode.scale = CMAJOR

        lowPitchShiftNode.isEnabled = true
        lowPitchShiftNode.pitchShiftCents = -400
        lowPitchShiftGainNode.gain = 0.4

        highPitchShiftNode.isEnabled = true
        highPitchShiftNode.pitchShiftCents = 400
        highPitchShiftGainNode.gain = 0.4

        reverbNode.isEnabled = true
        reverbNode.mix = 0.008
        reverbNode.width = 0.7
        reverbNode.damp = 0.5
        reverbNode.roomSize = 0.5
        reverbNode.predelayMs = 10.0
    }

    func setHighPreset() {
        avpcNode.isEnabled = true
        avpcNode.speed = EXTREME
        avpcNode.range = WIDE
        avpcNode.scale = CMAJOR

        lowPitchShiftNode.isEnabled = true
        lowPitchShiftNode.pitchShiftCents = -400
        lowPitchShiftGainNode.gain = 1.0

        highPitchShiftNode.isEnabled = true
        highPitchShiftNode.pitchShiftCents = 400
        highPitchShiftGainNode.gain = 1.0

        reverbNode.isEnabled = true
        reverbNode.mix = 0.015
        reverbNode.width = 0.7
        reverbNode.damp = 0.5
        reverbNode.roomSize = 0.75
        reverbNode.predelayMs = 10.0
    }

    override init() {
        super.init()

        switch Config.harmonizerPreset {
        case 0:
            setLowPreset()
        default:
            setHighPreset()
        }

        audioGraph.addNode(avpcNode)
        audioGraph.addNode(busSplitterNode)
        audioGraph.addNode(lowPitchShiftNode)
        audioGraph.addNode(lowPitchShiftGainNode)
        audioGraph.addNode(highPitchShiftNode)
        audioGraph.addNode(highPitchShiftGainNode)
        audioGraph.addNode(mixerNode)
        audioGraph.addNode(reverbNode)

        audioGraph.connect(audioGraph.inputNode, to: avpcNode)
        audioGraph.connect(avpcNode, to: busSplitterNode)
        audioGraph.connect(busSplitterNode, to: lowPitchShiftNode)
        audioGraph.connect(busSplitterNode, to: highPitchShiftNode)
        audioGraph.connect(busSplitterNode, to: mixerNode)
        audioGraph.connect(lowPitchShiftNode, to: lowPitchShiftGainNode)
        audioGraph.connect(lowPitchShiftGainNode, to: mixerNode)
        audioGraph.connect(highPitchShiftNode, to: highPitchShiftGainNode)
        audioGraph.connect(highPitchShiftGainNode, to: mixerNode)
        audioGraph.connect(mixerNode, to: reverbNode)
        audioGraph.connect(reverbNode, to: audioGraph.outputNode)

        audioGraph.start()
    }
}
