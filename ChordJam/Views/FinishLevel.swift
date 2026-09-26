import SwiftUI

struct FinishLevel: View {
    @Binding var unlockedLevel: Int
    @State private var navigateToMainMenu = false
    @EnvironmentObject var gameCenterManager: GameCenterManager

    var body: some View {
        NavigationStack {
            ZStack {
                Image("BackgroundLevel")
                    .resizable()

                VStack(spacing: 30.0) {
                    VStack(spacing: 20.0) {
                        Text("Congratulations!")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(Color.white)

                        Image("Exp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 326, height: 35)
                    }

                    HStack(spacing: 100.0) {
                        Button(action: {}, label: {
                            Image("RetryButton")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 51, height: 95)
                        })

                        Button(action: {
                            navigateToMainMenu = true
                        }, label: {
                            Image("ContinueButton")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 86, height: 94)
                        })
                    }
                    .padding()
                    NavigationLink(destination: MainMenuView(unlockedLevel: $unlockedLevel).environmentObject(gameCenterManager), isActive: $navigateToMainMenu) {
                        EmptyView()
                    }
                    .navigationBarBackButtonHidden(true)
                }
            }
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .overlay(
            BadgeNotif()
                .offset(y: -150)
        )
    }
}

#Preview {
    FinishLevel(unlockedLevel: .constant(1))
        .environmentObject(GameCenterManager.shared)
}
