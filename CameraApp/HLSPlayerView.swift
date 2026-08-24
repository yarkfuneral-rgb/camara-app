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
        
        item.preferredForwardBufferDuration = 0.5
        
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        
        controller.player = player
        controller.showsPlaybackControls = false // OCULTA POR COMPLETO EL BOTÓN DE PLAY / CONTROLES
        controller.allowsPictureInPicturePlayback = true // Habilita PiP automático
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.videoGravity = .resizeAspect
        
        context.coordinator.observe(item: item, player: player)
        
        // Reproducción directa instantánea sin tocar nada
        player.playImmediately(atRate: 1.0)
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
            context.coordinator.observe(item: newItem, player: newPlayer)
            newPlayer.playImmediately(atRate: 1.0)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var statusObserver: NSKeyValueObservation?

        func observe(item: AVPlayerItem, player: AVPlayer) {
            statusObserver?.invalidate()
            statusObserver = item.observe(\.status, options: [.new]) { item, _ in
                if item.status == .readyToPlay {
                    if let liveEnd = item.seekableTimeRanges.last?.timeRangeValue.end {
                        player.seek(to: liveEnd, toleranceBefore: .zero, toleranceAfter: .zero)
                    }
                    player.playImmediately(atRate: 1.0)
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
