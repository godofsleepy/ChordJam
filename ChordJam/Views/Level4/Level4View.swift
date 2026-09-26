//
//  Level4View.swift
//  ChordJam
//
//  Created by Christian Aldrich Darrien on 18/06/24.
//

import SwiftUI

struct Level4View: View {
    @Binding var unlockedLevel: Int

    var body: some View {
        ChordPracticeView(level: .dm, unlockedLevel: $unlockedLevel)
    }
}

#Preview {
    Level4View(unlockedLevel: .constant(4))
}
