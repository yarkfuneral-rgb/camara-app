import SwiftUI
import AVKit

struct HLSPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black

            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true) // Deshabilita controles nativos para mantener UI limpia
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .onChange(of: url) { newURL in
            setupPlayer()
        }
    }

    private func setupPlayer() {
        player?.pause()
        let newPlayer = AVPlayer(url: url)
        newPlayer.automaticallyWaitsToMinimizeStalling = false
        newPlayer.play()
        self.player = newPlayer
    }
}
