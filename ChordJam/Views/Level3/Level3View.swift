//
//  Level3View.swift
//  ChordJam
//
//  Created by Christian Aldrich Darrien on 18/06/24.
//

import SwiftUI

struct Level3View: View {
    @Binding var unlockedLevel: Int

    var body: some View {
        ChordPracticeView(level: .g, unlockedLevel: $unlockedLevel)
    }
}

#Preview {
    Level3View(unlockedLevel: .constant(3))
}
