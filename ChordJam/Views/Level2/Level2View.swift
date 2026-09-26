//
//  Level2View.swift
//  ChordJam
//
//  Created by Christian Aldrich Darrien on 18/06/24.
//

import SwiftUI

struct Level2View: View {
    @Binding var unlockedLevel: Int

    var body: some View {
        ChordPracticeView(level: .am, unlockedLevel: $unlockedLevel)
    }
}

#Preview {
    Level2View(unlockedLevel: .constant(2))
}
