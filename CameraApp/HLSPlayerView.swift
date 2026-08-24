import SwiftUI
import AVKit

struct HLSPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        let player = AVPlayer(url: url)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        view.layer.addSublayer(layer)
        
        context.coordinator.player = player
        context.coordinator.layer = layer
        
        player.play()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let player = context.coordinator.player,
           let currentItem = player.currentItem,
           let asset = currentItem.asset as? AVURLAsset,
           asset.url != url {
            
            let newItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: newItem)
            player.play()
        }
        
        DispatchQueue.main.async {
            context.coordinator.layer?.frame = uiView.bounds
        }
    }

    func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var player: AVPlayer?
        var layer: AVPlayerLayer?

        override init() {
            super.init()
        }

        deinit {
            player?.pause()
            player = nil
        }
    }
}
