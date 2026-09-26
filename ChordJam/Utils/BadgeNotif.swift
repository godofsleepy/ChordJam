//
//  BadgeNotif.swift
//  ChordJam
//
//  Created by Christian Aldrich Darrien on 26/06/24.
//

import SwiftUI

struct BadgeNotif: View {
    @State private var showBadge: Bool = false

    private let level = UserDefaults.standard.integer(forKey: "LevelSekarang")

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 30)
                .frame(width: 275, height: 45)
                .foregroundStyle(Color(hex: "FFC107"))

            HStack {
                Image(badgeImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 31, height: 31)

                VStack(alignment: .leading) {
                    Text("Badge earned")
                        .fontWeight(.light)
                    Text(badgeText)
                        .fontWeight(.bold)
                }
                .font(.callout)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color.white)
            }
            .padding()
        }
        .offset(y: showBadge ? 0 : -UIScreen.main.bounds.height)
        .animation(.easeInOut(duration: 1), value: showBadge)
        .onAppear {
            withAnimation { showBadge = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showBadge = false }
            }
        }
    }

    private var badgeText: String {
        switch level {
        case 1: return "Learning C Major"
        case 2: return "Learning Am Major"
        case 3: return "Learning G Major"
        case 4: return "Learning Dm Major"
        case 5: return "Learning One Song"
        default: return "NULL"
        }
    }

    private var badgeImage: String {
        switch level {
        case 1: return "BadgeC"
        case 2: return "BadgeAm"
        case 3: return "BadgeG"
        case 4: return "BadgeDm"
        case 5: return "oneSong"
        default: return "NULL"
        }
    }
}

#Preview {
    BadgeNotif()
}
