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
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        
        context.coordinator.observe(item: item, player: player)
        
        player.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var statusObserver: NSKeyValueObservation?

        func observe(item: AVPlayerItem, player: AVPlayer) {
            statusObserver = item.observe(\.status, options: [.new]) { item, _ in
                if item.status == .readyToPlay {
                    player.seek(to: CMTime.positiveInfinity)
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
