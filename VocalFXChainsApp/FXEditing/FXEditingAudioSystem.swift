//
//  FXEditingAudioSystem.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 24..
//

import SwitchboardSDK

class FXEditingAudioSystem: AudioSystem {
    let beatPlayerNode = SBAudioPlayerNode()
    let beatGainNode = SBGainNode()
    let vocalPlayerNode = SBAudioPlayerNode()
    let vocalGainNode = SBGainNode()
    let vocalPlayerSplitterNode = SBBusSplitterNode()
    let fxChainNode = SBSubgraphProcessorNode()
    let busSelectNode = SBBusSelectNode()
    let mixerNode = SBMixerNode()

    let offlineGraphRenderer = SBOfflineGraphRenderer()

    let harmonizer = HarmonizerEffect()
    let radio = RadioEffect()

    var applyFXChain: Bool = Config.applyFXChain {
        didSet {
            busSelectNode.selectedBus = applyFXChain ? 0 : 1;
            Config.applyFXChain = applyFXChain
        }
    }

    override init() {
        super.init()

        busSelectNode.selectedBus = applyFXChain ? 0 : 1;
        selectFXChain()
        selectFXChainPreset()
        
        audioGraph.addNode(beatPlayerNode)
        audioGraph.addNode(beatGainNode)
        audioGraph.addNode(vocalPlayerNode)
        audioGraph.addNode(vocalGainNode)
        audioGraph.addNode(vocalPlayerSplitterNode)
        audioGraph.addNode(fxChainNode)
        audioGraph.addNode(busSelectNode)
        audioGraph.addNode(mixerNode)

        audioGraph.connect(beatPlayerNode, to: beatGainNode)
        audioGraph.connect(beatGainNode, to: mixerNode)
        audioGraph.connect(vocalPlayerNode, to: vocalGainNode)
        audioGraph.connect(vocalGainNode, to: vocalPlayerSplitterNode)
        audioGraph.connect(vocalPlayerSplitterNode, to: fxChainNode)
        audioGraph.connect(fxChainNode, to: busSelectNode)
        audioGraph.connect(vocalPlayerSplitterNode, to: busSelectNode)
        audioGraph.connect(busSelectNode, to: mixerNode)
        audioGraph.connect(mixerNode, to: audioGraph.outputNode)

        beatPlayerNode.load(Bundle.main.url(forResource: "trap130bpm", withExtension: "mp3")!.absoluteString)
        beatPlayerNode.isLoopingEnabled = true

        beatPlayerNode.duration()

        vocalPlayerNode.load(Config.cleanVocalRecordingFilePath, withFormat: Config.recordingFormat)
        vocalPlayerNode.isLoopingEnabled = true

        beatPlayerNode.endPosition = vocalPlayerNode.duration()

        audioEngine.voiceProcessingEnabled = false
        audioEngine.microphoneEnabled = false
    }

    func selectFXChain() {
        switch Config.selectedFXChainIndex {
        case 0:
            fxChainNode.audioGraph = harmonizer.audioGraph
        default:
            fxChainNode.audioGraph = radio.audioGraph
        }
    }

    func selectFXChainPreset() {
        switch Config.selectedFXChainIndex {
        case 0:
            switch Config.harmonizerPreset {
            case 0:
                harmonizer.setLowPreset()
            default:
                harmonizer.setHighPreset()
            }
        default:
            switch Config.radioPreset {
            case 0:
                radio.setLowPreset()
            default:
                radio.setHighPreset()
            }
        }
    }

    func startPlayback() {
        beatPlayerNode.play()
        vocalPlayerNode.play()
    }

    func stopPlayback() {
        beatPlayerNode.stop()
        vocalPlayerNode.stop()
    }

    var isPlaying: Bool {
        return beatPlayerNode.isPlaying
    }

    func renderMix() {
        let sampleRate = max(vocalPlayerNode.sourceSampleRate, beatPlayerNode.sourceSampleRate)
        vocalPlayerNode.position = 0.0
        beatPlayerNode.position = 0.0
        offlineGraphRenderer.sampleRate = sampleRate
        offlineGraphRenderer.maxNumberOfSecondsToRender = vocalPlayerNode.duration()

        startPlayback()
        offlineGraphRenderer.processGraph(audioGraph, withOutputFile: Config.finalMixRecordingFile, withOutputFileCodec: .wav)
        stopPlayback()
    }
}
