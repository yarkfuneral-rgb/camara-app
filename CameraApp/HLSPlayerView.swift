import SwiftUI
import AVKit

struct HLSPlayerView: View {
    let url: URL

    var body: some View {
        LiveAVPlayerView(url: url)
    }
}

struct LiveAVPlayerView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        player.automaticallyWaitsToMinimizeStalling = false
        
        controller.player = player
        controller.showsPlaybackControls = true // Muestra controles: Agrandar (pantalla completa) y Play
        controller.allowsPictureInPicturePlayback = true // Habilita Picture-in-Picture (PiP)
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.videoGravity = .resizeAspect
        
        player.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if let player = uiViewController.player,
           let currentItem = player.currentItem,
           let asset = currentItem.asset as? AVURLAsset,
           asset.url != url {
            let newPlayer = AVPlayer(url: url)
            newPlayer.automaticallyWaitsToMinimizeStalling = false
            uiViewController.player = newPlayer
            newPlayer.play()
        }
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
