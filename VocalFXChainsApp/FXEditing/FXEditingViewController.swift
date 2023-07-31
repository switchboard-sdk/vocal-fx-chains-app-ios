//
//  FXViewController.swift
//  VocalFXChainsApp
//
//  Created by Iván Nádor on 2023. 07. 24..
//

import UIKit

class FXEditingViewController: UIViewController {

    let audioSystem = FXEditingAudioSystem()

    @IBOutlet var playbackButton: UIButton!
    @IBOutlet var exportButton: UIButton!
    @IBOutlet var fxChainSwitch: UISwitch!
    @IBOutlet var fxChainSelector: UISegmentedControl!
    @IBOutlet var fxChainPreset: UISegmentedControl!
    @IBOutlet var vocalVolumeSlider: UISlider!
    @IBOutlet var beatVolumeSlider: UISlider!
    @IBOutlet var loaderView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        fxChainSwitch.isOn = audioSystem.applyFXChain
        fxChainSelector.selectedSegmentIndex = Config.selectedFXChainIndex

        vocalVolumeSlider.value = audioSystem.vocalGainNode.gain
        beatVolumeSlider.value = audioSystem.beatGainNode.gain

        audioSystem.start()
    }

    deinit {
        audioSystem.stop()
    }

    @IBAction func toggledFXChainSwitch() {
        audioSystem.applyFXChain = fxChainSwitch.isOn
    }

    @IBAction func selectedFXChain() {
        Config.selectedFXChainIndex = fxChainSelector.selectedSegmentIndex
        audioSystem.selectFXChain()
        selectedFXChainPreset()
    }

    @IBAction func selectedFXChainPreset() {
        switch Config.selectedFXChainIndex {
        case 0:
            Config.harmonizerPreset = fxChainPreset.selectedSegmentIndex
        default:
            Config.radioPreset = fxChainPreset.selectedSegmentIndex
        }
        audioSystem.selectFXChainPreset()
    }

    @IBAction func tappedPlaybackButton() {
        if audioSystem.isPlaying {
            audioSystem.stopPlayback()
            playbackButton.setTitle("Start Playback", for: .normal)
        } else {
            audioSystem.startPlayback()
            playbackButton.setTitle("Stop Playback", for: .normal)
        }
    }

    @IBAction func tappedExportButton() {
        loaderView.isHidden = false
        audioSystem.stopPlayback()
        playbackButton.setTitle("Start Playback", for: .normal)
        audioSystem.stop()

        DispatchQueue.global(qos: .default).async {
            self.audioSystem.renderMix()

            DispatchQueue.main.async {
                self.loaderView.isHidden = true

                let fileURL = NSURL(fileURLWithPath: Config.finalMixRecordingFile)
                var filesToShare = [Any]()
                filesToShare.append(fileURL)
                let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
                    self.audioSystem.start()
                }
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }

    @IBAction func vocalVolumeChanged() {
        audioSystem.vocalGainNode.gain = vocalVolumeSlider.value
    }

    @IBAction func beatVolumeChanged() {
        audioSystem.beatGainNode.gain = beatVolumeSlider.value
    }
}

