import SwiftUI
import AVKit
import CoreMedia

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
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        
        if let item = player.currentItem {
            context.coordinator.observe(item: item, player: player)
        }
        
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
            if let newItem = newPlayer.currentItem {
                context.coordinator.observe(item: newItem, player: newPlayer)
            }
            newPlayer.play()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var statusObserver: NSKeyValueObservation?

        func observe(item: AVPlayerItem, player: AVPlayer) {
            statusObserver = item.observe(\.status, options: [.new]) { item, _ in
                if item.status == .readyToPlay {
                    player.seek(to: item.duration)
                    player.play()
                }
            }
        }

        deinit {
            statusObserver?.invalidate()
        }
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.statusObserver?.invalidate()
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
