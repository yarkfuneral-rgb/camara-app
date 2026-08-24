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
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        
        // Cero buffer previo para reproducción en tiempo real estricto
        item.preferredForwardBufferDuration = 0.5
        
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        
        controller.player = player
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.videoGravity = .resizeAspect
        
        context.coordinator.observe(item: item, player: player, controller: controller)
        
        player.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if let player = uiViewController.player,
           let currentItem = player.currentItem,
           let asset = currentItem.asset as? AVURLAsset,
           asset.url != url {
            let newAsset = AVURLAsset(url: url)
            let newItem = AVPlayerItem(asset: newAsset)
            newItem.preferredForwardBufferDuration = 0.5
            
            let newPlayer = AVPlayer(playerItem: newItem)
            newPlayer.automaticallyWaitsToMinimizeStalling = false
            uiViewController.player = newPlayer
            context.coordinator.observe(item: newItem, player: newPlayer, controller: uiViewController)
            newPlayer.play()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, AVPictureInPictureControllerDelegate {
        var statusObserver: NSKeyValueObservation?
        var pipController: AVPictureInPictureController?

        func observe(item: AVPlayerItem, player: AVPlayer, controller: AVPlayerViewController) {
            statusObserver?.invalidate()
            statusObserver = item.observe(\.status, options: [.new]) { item, _ in
                if item.status == .readyToPlay {
                    // Salto automático al borde exacto de la transmisión en vivo (0 delay)
                    if let liveEnd = item.seekableTimeRanges.last?.timeRangeValue.end {
                        player.seek(to: liveEnd, toleranceBefore: .zero, toleranceAfter: .zero)
                    }
                    player.play()
                }
            }
        }

        deinit {
            statusObserver?.invalidate()
            pipController = nil
        }
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.statusObserver?.invalidate()
        coordinator.pipController = nil
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
