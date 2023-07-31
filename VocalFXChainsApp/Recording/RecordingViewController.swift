//
//  ViewController.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 21..
//

import UIKit

class RecordingViewController: UIViewController {

    let audioSystem = RecordingAudioSystem()

    @IBOutlet var recordingButton: UIButton!
    @IBOutlet var beatButton: UIButton!
    @IBOutlet var fxChainSwitch: UISwitch!
    @IBOutlet var fxChainSelector: UISegmentedControl!
    @IBOutlet var liveMonitoringActiveLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        audioSystem.delegate = self

        fxChainSwitch.isOn = audioSystem.applyFXChain
        fxChainSelector.selectedSegmentIndex = Config.selectedFXChainIndex

        setLiveMonitoringActiveText(isLiveMonitoringActive: !audioSystem.isSpeaker())

        audioSystem.start()
    }

    deinit {
        audioSystem.stop()
    }

    @IBAction func tappedRecordingButton() {
        if audioSystem.isRecording {
            audioSystem.stopRecording()
            audioSystem.stopBeat()
            beatButton.isEnabled = true
            recordingButton.setTitle("Start Recording", for: .normal)
            navigateToFXEditing()
        } else {
            audioSystem.startRecording()
            audioSystem.startBeat()
            beatButton.isEnabled = false
            recordingButton.setTitle("Stop Recording", for: .normal)
        }
    }

    @IBAction func tappedBeatButton() {
        if audioSystem.isBeatPlaying {
            audioSystem.stopBeat()
            beatButton.setTitle("Listen to Beat", for: .normal)
        } else {
            audioSystem.startBeat()
            beatButton.setTitle("Stop Beat", for: .normal)
        }
    }

    @IBAction func toggledFXChainSwitch() {
        audioSystem.applyFXChain = fxChainSwitch.isOn
    }

    @IBAction func selectedFXChain() {
        Config.selectedFXChainIndex = fxChainSelector.selectedSegmentIndex
        audioSystem.selectFXChain()
    }

    private func navigateToFXEditing() {
        audioSystem.stop()
        let vc = self.storyboard?.instantiateViewController(identifier: "FXEditingViewController") as! FXEditingViewController
        self.present(vc, animated: true)
    }

    private func setLiveMonitoringActiveText(isLiveMonitoringActive: Bool) {
        if (isLiveMonitoringActive) {
            liveMonitoringActiveLabel.text = "Live Monitoring Active"
        } else {
            liveMonitoringActiveLabel.text = "Live Monitoring Inactive"
        }
    }
}

extension RecordingViewController: RecordingAudioSystemDelegate {
    func recordingAudioSystem(_: RecordingAudioSystem, isLiveMonitoringActive: Bool) {
        setLiveMonitoringActiveText(isLiveMonitoringActive: isLiveMonitoringActive)
    }
}
