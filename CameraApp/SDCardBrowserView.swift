import SwiftUI
import AVKit

struct SDCardBrowserView: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoadingSD {
                    ProgressView("Cargando grabaciones...")
                } else if viewModel.sdFiles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Sin grabaciones disponibles")
                            .font(.headline)
                        
                        if let error = viewModel.sdLoadError {
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button("Recargar") {
                            Task {
                                await viewModel.loadSDFiles()
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 10)
                    }
                } else {
                    List(viewModel.sdFiles) { file in
                        SDFileRow(file: file, baseURL: viewModel.serverBaseURL)
                    }
                    .refreshable {
                        await viewModel.loadSDFiles()
                    }
                }
            }
            .navigationTitle("Grabaciones")
            .task {
                await viewModel.loadSDFiles()
            }
        }
    }
}

struct SDFileRow: View {
    let file: SDFile
    let baseURL: String
    @State private var showPlayer = false
    
    private var fullRecordingURL: URL? {
        if file.url.hasPrefix("http") {
            return URL(string: file.url)
        } else {
            return URL(string: "\(baseURL)\(file.url)")
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "film.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("\(file.date) • \(file.size)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                showPlayer = true
            }) {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 30))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showPlayer) {
            if let targetURL = fullRecordingURL {
                VideoPlayerView(url: targetURL)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Error: URL de grabación inválida")
            }
        }
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        player.play()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    }
}
