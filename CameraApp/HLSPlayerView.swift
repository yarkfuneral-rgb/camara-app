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
        
        item.preferredForwardBufferDuration = 1.0
        
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        
        controller.player = player
        controller.showsPlaybackControls = true // Muestra controles nativos de iOS (Agrandar a pantalla completa y PiP)
        controller.allowsPictureInPicturePlayback = true // Habilita PiP en iOS
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.videoGravity = .resizeAspect
        
        context.coordinator.observe(item: item, player: player)
        
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
            newItem.preferredForwardBufferDuration = 1.0
            
            let newPlayer = AVPlayer(playerItem: newItem)
            newPlayer.automaticallyWaitsToMinimizeStalling = false
            uiViewController.player = newPlayer
            context.coordinator.observe(item: newItem, player: newPlayer)
            newPlayer.play()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var statusObserver: NSKeyValueObservation?
        var timeObserver: Any?

        func observe(item: AVPlayerItem, player: AVPlayer) {
            statusObserver?.invalidate()
            if let timeObs = timeObserver {
                player.removeTimeObserver(timeObs)
            }
            
            statusObserver = item.observe(\.status, options: [.new]) { item, _ in
                if item.status == .readyToPlay {
                    player.play()
                }
            }
            
            // Re-sincroniza periódicamente para mantener el stream en vivo sin congelamientos
            timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 5, preferredTimescale: 1), queue: .main) { _ in
                if let liveEnd = item.seekableTimeRanges.last?.timeRangeValue.end {
                    let currentTime = player.currentTime()
                    let diff = CMTimeGetSeconds(liveEnd) - CMTimeGetSeconds(currentTime)
                    if diff > 3.0 { // Si el retraso supera los 3 segundos, salta al borde en vivo
                        player.seek(to: liveEnd, toleranceBefore: .zero, toleranceAfter: .zero)
                    }
                }
            }
        }

        deinit {
            statusObserver?.invalidate()
            statusObserver = nil
        }
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.statusObserver?.invalidate()
        if let timeObs = coordinator.timeObserver {
            uiViewController.player?.removeTimeObserver(timeObs)
        }
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
