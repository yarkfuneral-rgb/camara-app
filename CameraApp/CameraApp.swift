import SwiftUI
import AVFoundation
import UserNotifications

@main
struct CameraApp: App {
    init() {
        // Configura la sesión de audio para permitir Picture-in-Picture (PiP) y reproducción continua
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error al configurar AVAudioSession: \(error)")
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error al solicitar permisos de notificación: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
