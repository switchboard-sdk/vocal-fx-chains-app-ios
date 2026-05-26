//
//  FXEditingAudioSystem.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 24..
//

import AVFoundation
import SwitchboardSDK

class FXEditingAudioSystem: AudioSystem {
    // Node ID prefixes to avoid conflicts with RecordingAudioSystem
    private static let harmPrefix = "editHarm"
    private static let radioPrefix = "editRadio"

    let harmonizer = HarmonizerEffect()
    let radio = RadioEffect()

    private let beatFileURL = Bundle.main.url(forResource: "trap130bpm", withExtension: "mp3")!.absoluteString

    var applyFXChain: Bool = Config.applyFXChain {
        didSet {
            Switchboard.setValue(applyFXChain ? 0 : 1, forKey: "selectedBus", onObject: "editFxApplySelectNode")
            Config.applyFXChain = applyFXChain
        }
    }

    var vocalGain: Float {
        get { (Switchboard.getValueForKey("gain", object: "editVocalGainNode").value as? NSNumber)?.floatValue ?? 1.0 }
        set { Switchboard.setValue(newValue, forKey: "gain", onObject: "editVocalGainNode") }
    }

    var beatGain: Float {
        get { (Switchboard.getValueForKey("gain", object: "editBeatGainNode").value as? NSNumber)?.floatValue ?? 1.0 }
        set { Switchboard.setValue(newValue, forKey: "gain", onObject: "editBeatGainNode") }
    }

    override init() {
        super.init()

        let graphJSON = """
        {
            "type": "Realtime",
            "config": {
                "microphoneEnabled": false,
                "voiceProcessingEnabled": false,
                "graph": {
                    "nodes": [
                        {"id": "editBeatPlayerNode", "type": "AudioPlayer"},
                        {"id": "editBeatGainNode", "type": "Switchboard.Gain"},
                        {"id": "editVocalPlayerNode", "type": "AudioPlayer"},
                        {"id": "editVocalGainNode", "type": "Switchboard.Gain"},
                        {"id": "editVocalSplitterNode", "type": "BusSplitter"},
                        {
                            "id": "editHarmonizerNode",
                            "type": "SubgraphProcessor",
                            "config": {"graph": \(harmonizer.graphJSON(prefix: Self.harmPrefix))}
                        },
                        {
                            "id": "editRadioNode",
                            "type": "SubgraphProcessor",
                            "config": {"graph": \(radio.graphJSON(prefix: Self.radioPrefix))}
                        },
                        {"id": "editFxSelectNode", "type": "Switchboard.BusSelect"},
                        {"id": "editFxApplySelectNode", "type": "Switchboard.BusSelect"},
                        {"id": "editMixerNode", "type": "Mixer"}
                    ],
                    "connections": [
                        {"sourceNode": "editBeatPlayerNode", "destinationNode": "editBeatGainNode"},
                        {"sourceNode": "editBeatGainNode", "destinationNode": "editMixerNode"},
                        {"sourceNode": "editVocalPlayerNode", "destinationNode": "editVocalGainNode"},
                        {"sourceNode": "editVocalGainNode", "destinationNode": "editVocalSplitterNode"},
                        {"sourceNode": "editVocalSplitterNode", "destinationNode": "editHarmonizerNode"},
                        {"sourceNode": "editVocalSplitterNode", "destinationNode": "editRadioNode"},
                        {"sourceNode": "editHarmonizerNode", "destinationNode": "editFxSelectNode"},
                        {"sourceNode": "editRadioNode", "destinationNode": "editFxSelectNode"},
                        {"sourceNode": "editFxSelectNode", "destinationNode": "editFxApplySelectNode"},
                        {"sourceNode": "editVocalSplitterNode", "destinationNode": "editFxApplySelectNode"},
                        {"sourceNode": "editFxApplySelectNode", "destinationNode": "editMixerNode"},
                        {"sourceNode": "editMixerNode", "destinationNode": "outputNode"}
                    ]
                }
            }
        }
        """

        let result = Switchboard.createEngine(withJSON: graphJSON)
        guard result.success else {
            fatalError("Failed to create FXEditing engine: \(result.error!)")
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
        Switchboard.setValue(Config.selectedFXChainIndex, forKey: "selectedBus", onObject: "editFxSelectNode")

        // Set initial FX apply/bypass selection (fx = bus 0, bypass = bus 1)
        Switchboard.setValue(applyFXChain ? 0 : 1, forKey: "selectedBus", onObject: "editFxApplySelectNode")

        // Load beat
        Switchboard.callAction(withObject: "editBeatPlayerNode", actionName: "load", params: ["audioFilePath": beatFileURL])
        Switchboard.setValue(true, forKey: "isLoopingEnabled", onObject: "editBeatPlayerNode")

        // Load vocal recording
        Switchboard.callAction(withObject: "editVocalPlayerNode", actionName: "load", params: ["audioFilePath": Config.cleanVocalRecordingFilePath, "codec": "wav"])
        Switchboard.setValue(true, forKey: "isLoopingEnabled", onObject: "editVocalPlayerNode")

        // Sync beat end position to vocal duration
        let vocalDuration = (Switchboard.getValueForKey("duration", object: "editVocalPlayerNode").value as? NSNumber)?.doubleValue ?? 0.0
        Switchboard.setValue(vocalDuration, forKey: "endPosition", onObject: "editBeatPlayerNode")
    }

    func selectFXChain() {
        // Harmonizer = bus 0, Radio = bus 1
        Switchboard.setValue(Config.selectedFXChainIndex, forKey: "selectedBus", onObject: "editFxSelectNode")
    }

    func selectFXChainPreset() {
        switch Config.selectedFXChainIndex {
        case 0:
            if Config.harmonizerPreset == 0 {
                harmonizer.setLowPreset(prefix: Self.harmPrefix)
            } else {
                harmonizer.setHighPreset(prefix: Self.harmPrefix)
            }
        default:
            if Config.radioPreset == 0 {
                radio.setLowPreset(prefix: Self.radioPrefix)
            } else {
                radio.setHighPreset(prefix: Self.radioPrefix)
            }
        }
    }

    func startPlayback() {
        Switchboard.callAction(withObject: "editBeatPlayerNode", actionName: "play", params: nil)
        Switchboard.callAction(withObject: "editVocalPlayerNode", actionName: "play", params: nil)
    }

    func stopPlayback() {
        Switchboard.callAction(withObject: "editBeatPlayerNode", actionName: "stop", params: nil)
        Switchboard.callAction(withObject: "editVocalPlayerNode", actionName: "stop", params: nil)
    }

    var isPlaying: Bool {
        return Switchboard.getValueForKey("isPlaying", object: "editBeatPlayerNode").value as? Bool ?? false
    }

    func renderMix() {
        let sampleRate = UInt(AVAudioSession.sharedInstance().sampleRate)
        let vocalDuration = (Switchboard.getValueForKey("duration", object: "editVocalPlayerNode").value as? NSNumber)?.doubleValue ?? 0.0

        let currentBeatGain = beatGain
        let currentVocalGain = vocalGain

        // Build the FX subgraph for the offline engine based on selected chain
        let fxEffect: FXChain
        let offlineFxPrefix: String
        if Config.selectedFXChainIndex == 0 {
            fxEffect = harmonizer
            offlineFxPrefix = "offlineHarm"
        } else {
            fxEffect = radio
            offlineFxPrefix = "offlineRadio"
        }

        let fxSubgraphNode: String
        let fxConnections: String
        if applyFXChain {
            fxSubgraphNode = """
            {
                "id": "offlineFxNode",
                "type": "SubgraphProcessor",
                "config": {"graph": \(fxEffect.graphJSON(prefix: offlineFxPrefix))}
            },
            """
            fxConnections = """
            {"sourceNode": "offlineVocalSplitterNode", "destinationNode": "offlineFxNode"},
            {"sourceNode": "offlineFxNode", "destinationNode": "offlineMixerNode"},
            """
        } else {
            fxSubgraphNode = ""
            fxConnections = """
            {"sourceNode": "offlineVocalSplitterNode", "destinationNode": "offlineMixerNode"},
            """
        }

        let offlineJSON = """
        {
            "type": "Offline",
            "config": {
                "sampleRate": \(sampleRate),
                "maxNumberOfSecondsToRender": \(vocalDuration),
                "outputFiles": [
                    {"filePath": "\(Config.finalMixRecordingFile)", "codec": "wav"}
                ],
                "graph": {
                    "nodes": [
                        {"id": "offlineBeatPlayerNode", "type": "AudioPlayer", "config": {"audioFilePath": "\(beatFileURL)"}},
                        {"id": "offlineVocalPlayerNode", "type": "AudioPlayer", "config": {"audioFilePath": "\(Config.cleanVocalRecordingFilePath)"}},
                        {"id": "offlineBeatGainNode", "type": "Switchboard.Gain"},
                        {"id": "offlineVocalGainNode", "type": "Switchboard.Gain"},
                        {"id": "offlineVocalSplitterNode", "type": "BusSplitter"},
                        \(fxSubgraphNode)
                        {"id": "offlineMixerNode", "type": "Mixer"}
                    ],
                    "connections": [
                        {"sourceNode": "offlineBeatPlayerNode", "destinationNode": "offlineBeatGainNode"},
                        {"sourceNode": "offlineBeatGainNode", "destinationNode": "offlineMixerNode"},
                        {"sourceNode": "offlineVocalPlayerNode", "destinationNode": "offlineVocalGainNode"},
                        {"sourceNode": "offlineVocalGainNode", "destinationNode": "offlineVocalSplitterNode"},
                        \(fxConnections)
                        {"sourceNode": "offlineMixerNode", "destinationNode": "outputNode"}
                    ]
                }
            }
        }
        """

        let createResult = Switchboard.createEngine(withJSON: offlineJSON)
        guard createResult.success else {
            fatalError("Failed to create offline engine: \(createResult.error!)")
        }
        let offlineEngineID = createResult.value! as String

        Switchboard.setValue(currentBeatGain, forKey: "gain", onObject: "offlineBeatGainNode")
        Switchboard.setValue(currentVocalGain, forKey: "gain", onObject: "offlineVocalGainNode")

        if applyFXChain {
            if Config.selectedFXChainIndex == 0 {
                if Config.harmonizerPreset == 0 { harmonizer.setLowPreset(prefix: offlineFxPrefix) }
                else { harmonizer.setHighPreset(prefix: offlineFxPrefix) }
            } else {
                if Config.radioPreset == 0 { radio.setLowPreset(prefix: offlineFxPrefix) }
                else { radio.setHighPreset(prefix: offlineFxPrefix) }
            }
        }

        Switchboard.callAction(withObject: offlineEngineID, actionName: "process", params: nil)
        Switchboard.destroyEngine(withObjectID: offlineEngineID)
    }
}
