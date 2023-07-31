//
//  RecordingAudioSystem.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 24..
//

import SwitchboardSDK
import SwitchboardAudioEffects

protocol RecordingAudioSystemDelegate {
    func recordingAudioSystem(_: RecordingAudioSystem, isLiveMonitoringActive: Bool)
}

class RecordingAudioSystem: AudioSystem {
    let inputSplitterNode = SBBusSplitterNode()
    let inputRecorderNode = SBRecorderNode()
    let fxChainNode = SBSubgraphProcessorNode()
    let busSelectNode = SBBusSelectNode()
    let muteNode = SBMuteNode()
    let beatPlayerNode = SBAudioPlayerNode()
    let mixerNode = SBMixerNode()

    let harmonizer = HarmonizerEffect()
    let radio = RadioEffect()

    var applyFXChain: Bool = Config.applyFXChain {
        didSet {
            busSelectNode.selectedBus = applyFXChain ? 0 : 1;
            Config.applyFXChain = applyFXChain
        }
    }

    var delegate: RecordingAudioSystemDelegate?

    override init() {
        super.init()
        audioEngine.delegate = self

        busSelectNode.selectedBus = applyFXChain ? 0 : 1;
        selectFXChain()

        audioGraph.addNode(inputSplitterNode)
        audioGraph.addNode(inputRecorderNode)
        audioGraph.addNode(fxChainNode)
        audioGraph.addNode(busSelectNode)
        audioGraph.addNode(muteNode)
        audioGraph.addNode(beatPlayerNode)
        audioGraph.addNode(mixerNode)

        audioGraph.connect(audioGraph.inputNode, to: inputSplitterNode)
        audioGraph.connect(inputSplitterNode, to: fxChainNode)
        audioGraph.connect(fxChainNode, to: busSelectNode)
        audioGraph.connect(inputSplitterNode, to: busSelectNode)
        audioGraph.connect(inputSplitterNode, to: inputRecorderNode)
        audioGraph.connect(busSelectNode, to: muteNode)
        audioGraph.connect(beatPlayerNode, to: mixerNode)
        audioGraph.connect(muteNode, to: mixerNode)
        audioGraph.connect(mixerNode, to: audioGraph.outputNode)

        beatPlayerNode.load(Bundle.main.url(forResource: "trap130bpm", withExtension: "mp3")!.absoluteString)
        beatPlayerNode.isLoopingEnabled = true

        muteNode.isMuted = isSpeaker()
        audioEngine.voiceProcessingEnabled = false

        audioEngine.microphoneEnabled = true
    }

    func selectFXChain() {
        switch Config.selectedFXChainIndex {
        case 0:
            fxChainNode.audioGraph = harmonizer.audioGraph
        default:
            fxChainNode.audioGraph = radio.audioGraph
        }
    }

    func startRecording() {
        inputRecorderNode.start()
    }

    func stopRecording() {
        inputRecorderNode.stop(Config.cleanVocalRecordingFilePath, withFormat: Config.recordingFormat)
    }

    var isRecording: Bool {
        return inputRecorderNode.isRecording
    }

    func startBeat() {
        beatPlayerNode.play()
    }

    func stopBeat() {
        beatPlayerNode.stop()
    }

    var isBeatPlaying: Bool {
        return beatPlayerNode.isPlaying
    }

    func isSpeaker() -> Bool {
        return audioEngine.currentOutputRoute == .builtInSpeaker || audioEngine.currentOutputRoute == .builtInReceiver
    }
}

extension RecordingAudioSystem: SBAudioEngineDelegate {
    func audioEngine(_: SBAudioEngine, inputRouteChanged currentInputRoute: AVAudioSession.Port) {}

    func audioEngine(_: SBAudioEngine, outputRouteChanged currentOutputRoute: AVAudioSession.Port) {
        muteNode.isMuted = isSpeaker()
        delegate?.recordingAudioSystem(self, isLiveMonitoringActive: !isSpeaker())
    }
}
