import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = CameraViewModel()
    
    var body: some View {
        TabView {
            LiveStreamView(viewModel: viewModel)
                .tabItem {
                    Label("En Vivo", systemImage: "video.fill")
                }
            
            SDCardBrowserView(viewModel: viewModel)
                .tabItem {
                    Label("Grabaciones", systemImage: "externaldrive.fill")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
        }
        .environmentObject(viewModel)
    }
}

struct LiveStreamView: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    Color.black
                    
                    if viewModel.isPlaying, let url = viewModel.validatedURL {
                        HLSPlayerView(url: url)
                    } else if viewModel.isConnecting {
                        ProgressView("Conectando...")
                            .foregroundColor(.white)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "video.slash.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            if let error = viewModel.errorMessage {
                                Text(error).foregroundColor(.red)
                            }
                            Button("Iniciar Transmisión") {
                                viewModel.connect()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    if viewModel.isPlaying {
                        VStack {
                            Spacer()
                            Button(action: {
                                viewModel.disconnect()
                            }) {
                                Text("Detener")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.bottom, 10)
                        }
                    }
                }
                .aspectRatio(16/9, contentMode: .fit)
                
                if viewModel.isPlaying {
                    PTZControlView(viewModel: viewModel)
                        .padding(.top)
                }
                
                Spacer()
                
                LightControlView(viewModel: viewModel)
                    .padding(.bottom)
            }
            .navigationTitle("Cámara 1")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LightControlView: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Luces / Infrarrojos")
                .font(.headline)
            
            HStack(spacing: 15) {
                Button(action: {
                    viewModel.changeLightMode(to: "off")
                }) {
                    Text("Apagar")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    viewModel.changeLightMode(to: "auto")
                }) {
                    Text("Automático")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    viewModel.changeLightMode(to: "on")
                }) {
                    Text("Encender")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
    }
}
