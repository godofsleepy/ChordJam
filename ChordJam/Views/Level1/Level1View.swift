//
//  Level1View.swift
//  ChordJam
//
//  Created by Christian Aldrich Darrien on 18/06/24.
//

import SwiftUI

struct Level1View: View {
    @Binding var unlockedLevel: Int

    var body: some View {
        ChordPracticeView(level: .c, unlockedLevel: $unlockedLevel)
    }
}

#Preview {
    Level1View(unlockedLevel: .constant(1))
}
