//
//  RecordingAudioSystem.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 24..
//

import AVFoundation
import SwitchboardSDK

protocol RecordingAudioSystemDelegate {
    func recordingAudioSystem(_: RecordingAudioSystem, isLiveMonitoringActive: Bool)
}

class RecordingAudioSystem: AudioSystem {
    // Node ID prefixes to avoid conflicts with FXEditingAudioSystem
    private static let harmPrefix = "recHarm"
    private static let radioPrefix = "recRadio"

    let harmonizer = HarmonizerEffect()
    let radio = RadioEffect()

    var applyFXChain: Bool = Config.applyFXChain {
        didSet {
            Switchboard.setValue(applyFXChain ? 0 : 1, forKey: "selectedBus", onObject: "recFxApplySelectNode")
            Config.applyFXChain = applyFXChain
        }
    }

    var delegate: RecordingAudioSystemDelegate?

    override init() {
        super.init()

        let beatURL = Bundle.main.url(forResource: "trap130bpm", withExtension: "mp3")!.absoluteString
        let graphJSON = """
        {
            "type": "Realtime",
            "config": {
                "microphoneEnabled": true,
                "voiceProcessingEnabled": false,
                "graph": {
                    "nodes": [
                        {"id": "recInputSplitterNode", "type": "BusSplitter"},
                        {
                            "id": "recRecorderNode",
                            "type": "Recorder",
                            "config": {
                                "numberOfRecordedChannels": 2
                            }
                        },
                        {
                            "id": "recHarmonizerNode",
                            "type": "SubgraphProcessor",
                            "config": {"graph": \(harmonizer.graphJSON(prefix: Self.harmPrefix))}
                        },
                        {
                            "id": "recRadioNode",
                            "type": "SubgraphProcessor",
                            "config": {"graph": \(radio.graphJSON(prefix: Self.radioPrefix))}
                        },
                        {"id": "recFxSelectNode", "type": "Switchboard.BusSelect"},
                        {"id": "recFxApplySelectNode", "type": "Switchboard.BusSelect"},
                        {"id": "recMuteNode", "type": "Switchboard.Mute"},
                        {"id": "recBeatPlayerNode", "type": "AudioPlayer"},
                        {"id": "recMixerNode", "type": "Mixer"}
                    ],
                    "connections": [
                        {"sourceNode": "inputNode", "destinationNode": "recInputSplitterNode"},
                        {"sourceNode": "recInputSplitterNode", "destinationNode": "recHarmonizerNode"},
                        {"sourceNode": "recInputSplitterNode", "destinationNode": "recRadioNode"},
                        {"sourceNode": "recHarmonizerNode", "destinationNode": "recFxSelectNode"},
                        {"sourceNode": "recRadioNode", "destinationNode": "recFxSelectNode"},
                        {"sourceNode": "recFxSelectNode", "destinationNode": "recFxApplySelectNode"},
                        {"sourceNode": "recInputSplitterNode", "destinationNode": "recFxApplySelectNode"},
                        {"sourceNode": "recInputSplitterNode", "destinationNode": "recRecorderNode"},
                        {"sourceNode": "recFxApplySelectNode", "destinationNode": "recMuteNode"},
                        {"sourceNode": "recBeatPlayerNode", "destinationNode": "recMixerNode"},
                        {"sourceNode": "recMuteNode", "destinationNode": "recMixerNode"},
                        {"sourceNode": "recMixerNode", "destinationNode": "outputNode"}
                    ]
                }
            }
        }
        """

        let result = Switchboard.createEngine(withJSON: graphJSON)
        guard result.success else {
            fatalError("Failed to create Recording engine: \(result.error!)")
        }
        engineID = result.value! as String

        // Apply initial FX chain presets for both chains
        if Config.harmonizerPreset == 0 {
            harmonizer.setLowPreset(prefix: Self.harmPrefix)
        } else {
            harmonizer.setHighPreset(prefix: Self.harmPrefix)
        }
        if Config.radioPreset == 0 {
            radio.setLowPreset(prefix: Self.radioPrefix)
        } else {
            radio.setHighPreset(prefix: Self.radioPrefix)
        }

        // Set initial FX chain selection (harmonizer = bus 0, radio = bus 1)
        Switchboard.setValue(Config.selectedFXChainIndex, forKey: "selectedBus", onObject: "recFxSelectNode")

        // Set initial FX apply/bypass selection (fx = bus 0, bypass = bus 1)
        Switchboard.setValue(applyFXChain ? 0 : 1, forKey: "selectedBus", onObject: "recFxApplySelectNode")

        // Load beat
        Switchboard.callAction(withObject: "recBeatPlayerNode", actionName: "load", params: ["audioFilePath": beatURL])
        Switchboard.setValue(true, forKey: "isLoopingEnabled", onObject: "recBeatPlayerNode")

        // Mute monitoring when output is speaker/receiver (to prevent feedback)
        Switchboard.setValue(isSpeaker(), forKey: "isMuted", onObject: "recMuteNode")

        // Observe audio route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func selectFXChain() {
        // Harmonizer = bus 0, Radio = bus 1
        Switchboard.setValue(Config.selectedFXChainIndex, forKey: "selectedBus", onObject: "recFxSelectNode")
    }

    func startRecording() {
        Switchboard.callAction(withObject: "recRecorderNode", actionName: "start", params: nil)
    }

    func stopRecording() {
        Switchboard.setValue(Config.cleanVocalRecordingFilePath, forKey: "outputFilePath", onObject: "recRecorderNode")
        Switchboard.callAction(withObject: "recRecorderNode", actionName: "stop", params: nil)
    }

    var isRecording: Bool {
        return Switchboard.getValueForKey("isRecording", object: "recRecorderNode").value as? Bool ?? false
    }

    func startBeat() {
        Switchboard.callAction(withObject: "recBeatPlayerNode", actionName: "play", params: nil)
    }

    func stopBeat() {
        Switchboard.callAction(withObject: "recBeatPlayerNode", actionName: "stop", params: nil)
    }

    var isBeatPlaying: Bool {
        return Switchboard.getValueForKey("isPlaying", object: "recBeatPlayerNode").value as? Bool ?? false
    }

    func isSpeaker() -> Bool {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        return outputs.contains { $0.portType == .builtInSpeaker || $0.portType == .builtInReceiver }
    }

    @objc private func audioRouteChanged(_ notification: Notification) {
        let muted = isSpeaker()
        Switchboard.setValue(muted, forKey: "isMuted", onObject: "recMuteNode")
        delegate?.recordingAudioSystem(self, isLiveMonitoringActive: !muted)
    }
}
