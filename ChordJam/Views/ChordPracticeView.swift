//
//  ChordPracticeView.swift
//  ChordJam
//
//  Shared screen for the chord practice levels (C, Am, G, Dm).
//

import SwiftUI

struct ChordLevel {
    let number: Int
    let title: String
    let fretImage: String
    /// Chord the player must strum to score on this level
    let chord: ChordType

    static let c = ChordLevel(number: 1, title: "C Major Chord", fretImage: "FretC", chord: .C)
    static let am = ChordLevel(number: 2, title: "A Minor Chord", fretImage: "FretAm", chord: .Am)
    static let g = ChordLevel(number: 3, title: "G Major Chord", fretImage: "FretG", chord: .G)
    static let dm = ChordLevel(number: 4, title: "D Minor Chord", fretImage: "FretDm", chord: .Dm)
}

struct ChordPracticeView: View {
    let level: ChordLevel
    @Binding var unlockedLevel: Int
    @StateObject private var manager = chordModel()
    @State private var showNextLevelView = false

    var body: some View {
        ZStack {
            Image("BackgroundLevel")
                .resizable()

            HStack {
                Spacer()
                VStack(alignment: .leading) {
                    Spacer()
                    VStack {
                        ProgressBar(progress: manager.points, total: Int(chordModel.pointsToClear))

                        Text(level.title)
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(Color.yellow)
                    }

                    HStack {
                        Image("Strings")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Image(level.fretImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 700)
                    }
                    .frame(height: 190)
                    Spacer()
                }
            }

            Image("Fingering")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 123)
                .offset(x: 350, y: 100)
        }
        .ignoresSafeArea()
        .onAppear {
            manager.currentLevel = level.number
            manager.targetChord = level.chord.rawValue
            manager.startAudioEngine()
        }
        .onChange(of: manager.points >= chordModel.pointsToClear) { _, cleared in
            guard cleared else { return }
            UserDefaults.standard.set(level.number, forKey: "LevelSekarang")
            manager.stopAudioEngine()
            unlockedLevel = max(unlockedLevel, level.number + 1)
            showNextLevelView = true
        }
        .fullScreenCover(isPresented: $showNextLevelView) {
            FinishLevel(unlockedLevel: $unlockedLevel)
        }
    }
}

#Preview {
    ChordPracticeView(level: .c, unlockedLevel: .constant(1))
}
