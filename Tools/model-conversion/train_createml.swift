// Train a Create ML sound classifier for ChordJam from a folder-per-label dataset.
//
// Usage (macOS 14+):
//   swift train_createml.swift dataset/Train dataset/Test ChordDetectionV2.mlmodel [afp|vggish]
//
// Folder names become class labels, so they must match ChordType raw values
// (C, Am, G, Dm, ...) plus "Ambient Noise".

import CreateML
import Foundation

let args = CommandLine.arguments
guard args.count == 4 || args.count == 5 else {
    print("usage: swift train_createml.swift <train_dir> <test_dir> <out.mlmodel> [afp|vggish]")
    exit(1)
}
let trainURL = URL(fileURLWithPath: args[1])
let testURL = URL(fileURLWithPath: args[2])
let outURL = URL(fileURLWithPath: args[3])
let useVGGish = args.count == 5 && args[4] == "vggish"

// Audio Feature Print replaces the old VGGish extractor (smaller and faster on device).
// The automatic validation split holds out part of the training data to measure overfitting.
let params = MLSoundClassifier.ModelParameters(
    validation: .split(strategy: .automatic),
    maxIterations: 100,
    overlapFactor: 0.5,
    algorithm: .transferLearning(
        featureExtractor: useVGGish ? .vggish() : .audioFeaturePrint(),
        classifier: .logisticRegressor
    )
)

let start = Date()
let classifier = try MLSoundClassifier(trainingData: .labeledDirectories(at: trainURL), parameters: params)
print(String(format: "trained in %.0f s", Date().timeIntervalSince(start)))

func accuracy(_ m: MLClassifierMetrics) -> String {
    String(format: "%.1f%%", (1 - m.classificationError) * 100)
}
print("training accuracy:   \(accuracy(classifier.trainingMetrics))")
print("validation accuracy: \(accuracy(classifier.validationMetrics))")

let test = classifier.evaluation(on: .labeledDirectories(at: testURL))
print("test accuracy:       \(accuracy(test))")
print(test.confusionDataFrame)

let metadata = MLModelMetadata(
    author: "ChordJam",
    shortDescription: "Guitar chord classifier (\(useVGGish ? "VGGish" : "Audio Feature Print")). Trained on severyn-k/isolated-guitar-chords (CC-BY-4.0).",
    license: "Model: project license. Training data: CC-BY-4.0, severyn-k/isolated-guitar-chords.",
    version: "2.0"
)
try classifier.write(to: outURL, metadata: metadata)
print("saved \(outURL.path)")
