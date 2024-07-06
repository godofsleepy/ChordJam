//
//  GameCenterManager.swift
//  ChordJam
//
//  Created by Anthony on 18/06/24.
//

import Foundation
import GameKit

class GameCenterManager: NSObject, ObservableObject {
    
    static let shared = GameCenterManager()
    
    @Published var isAuthenticated = false
    @Published var playerAlias: String?
    
    let leaderboardID = "chordjam_leaderboard" // Your leaderboard ID
    
    private override init() {
        super.init()
        authenticatePlayer()
    }
    
    func authenticatePlayer() {
        let localPlayer = GKLocalPlayer.local
                localPlayer.authenticateHandler = { viewController, error in
                    if let viewController = viewController {
                        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                            rootViewController.present(viewController, animated: true, completion: nil)
                        }
                    } else if localPlayer.isAuthenticated {
                        print("Player authenticated")
                        self.isAuthenticated = true
                    } else {
                        if let error = error {
                            print("Authentication error: \(error.localizedDescription)")
                        }
                        self.isAuthenticated = false
                    }
                }
    }
    
    func showLeaderboard() {
        let viewController = GKGameCenterViewController(state: .leaderboards)
        viewController.gameCenterDelegate = self
        viewController.leaderboardIdentifier = leaderboardID // Set the leaderboard ID
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(viewController, animated: true)
        }
    }
    
    func reportScore(score: Int64) {
        let scoreReporter = GKScore(leaderboardIdentifier: leaderboardID)
        scoreReporter.value = score
        GKScore.report([scoreReporter]) { error in
            if let error = error {
                print("Error reporting score: \(error.localizedDescription)")
            }
        }
    }
}

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
