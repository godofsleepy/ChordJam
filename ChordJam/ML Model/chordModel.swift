//
//  chordModel.swift
//  ChordJam
//
//  Created by Christian Aldrich Darrien on 23/06/24.
//

import Foundation
import CoreML
import AVKit
import SoundAnalysis

class chordModel: NSObject, ObservableObject, SNResultsObserving {
    /// Every practice level (1–4) currently listens for Am, as in the original game.
    static let practiceChord = "Am"
    static let pointsPerHit = 30.0
    static let pointsToClear = 90.0
    static let minConfidence = 60.0

    @Published var predictionResult: String = ""
    @Published var classifiedConfidence: Double = 0.0
    @Published var pointsAm: Double = 0.0
    @Published var currentLevel: Int = 0

    let audioEngine = AVAudioEngine()
    private let chordClassifierModel = try! ChordDetection(configuration: .init())
    private var analyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.apple.AnalysisQueue")

    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            try audioSession.setActive(true)

            // Prefer a headset or Bluetooth mic when one is connected
            if let input = audioSession.availableInputs?.first(where: { $0.portType == .headsetMic || $0.portType == .bluetoothA2DP }) {
                try audioSession.setPreferredInput(input)
            }
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    func startAudioEngine() {
        setupAudioSession()

        let inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        let analyzer = SNAudioStreamAnalyzer(format: inputFormat)
        do {
            let request = try SNClassifySoundRequest(mlModel: chordClassifierModel.model)
            try analyzer.add(request, withObserver: self)
        } catch {
            print("Unable to prepare request: \(error.localizedDescription)")
            return
        }
        self.analyzer = analyzer

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { [weak self] buffer, time in
            self?.analysisQueue.async {
                self?.analyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }

        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }

    func stopAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    func request(_ request: any SNRequest, didProduce result: any SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first else { return }

        let confidence = classification.confidence * 100.0
        guard confidence > chordModel.minConfidence else { return }

        let identifier = classification.identifier
        DispatchQueue.main.async {
            self.predictionResult = identifier
            self.classifiedConfidence = confidence

            if (1...4).contains(self.currentLevel) && identifier == chordModel.practiceChord {
                self.pointsAm += chordModel.pointsPerHit
            }
        }
    }
}
