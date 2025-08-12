import Foundation
import SwiftUI

// This file contains shared protocols used across the app
// It serves as a bridge between different modules

protocol AudioManagerProtocol {
    func playAlarmSound(spotifyURI: String?)
    func stopAlarmSound()
    func setVolume(_ level: Float)
    func fadeIn(duration: TimeInterval)
}