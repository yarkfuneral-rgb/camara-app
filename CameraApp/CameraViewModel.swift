import Foundation
import SwiftUI

struct SDFile: Identifiable, Codable {
    let id: String
    let name: String
    let size: String
    let date: String
    let url: String
}

class CameraViewModel: ObservableObject {
    @Published var serverBaseURL: String {
        didSet {
            UserDefaults.standard.set(serverBaseURL, forKey: "server_base_url")
        }
    }

    @Published var isPlaying = false
    @Published var isConnecting = false
    @Published var errorMessage: String? = nil

    @Published var sdFiles: [SDFile] = []
    @Published var isLoadingSD = false
    @Published var sdLoadError: String? = nil

    init() {
        // Default: IP de la PC en la red local
        self.serverBaseURL = UserDefaults.standard.string(forKey: "server_base_url") ?? "http://192.168.1.22:3000"
    }

    // URL del stream HLS (MediaMTX corre en puerto 8888)
    var hlsURL: URL? {
        let base = serverBaseURL.replacingOccurrences(of: ":3000", with: ":8888")
        return URL(string: "\(base)/camara/index.m3u8")
    }

    var validatedURL: URL? { hlsURL }

    func connect() {
        isConnecting = true
        errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isPlaying = true
            self.isConnecting = false
        }
    }

    func disconnect() {
        isPlaying = false
        isConnecting = false
    }

    // Control dual de luces:
    // 1. Envía directo a http://192.168.1.9:8001 (Funciona en Wi-Fi AUNQUE LA PC ESTÉ APAGADA)
    // 2. Envía al servidor para cuando estás fuera de casa por internet
    func changeLightMode(to mode: String) {
        let whiteVal = (mode == "off") ? "off" : (mode == "on" ? "on" : "auto")
        let irVal = (mode == "off") ? "off" : (mode == "on" ? "on" : "auto")
        
        // Petición directa a la cámara en la red local (sin pasar por la PC)
        if let directLightURL = URL(string: "http://192.168.1.9:8001/whitelight?mode=\(whiteVal)") {
            var req = URLRequest(url: directLightURL)
            req.timeoutInterval = 3.0
            URLSession.shared.dataTask(with: req).resume()
        }
        if let directIRURL = URL(string: "http://192.168.1.9:8001/ircut?mode=\(irVal)") {
            var req = URLRequest(url: directIRURL)
            req.timeoutInterval = 3.0
            URLSession.shared.dataTask(with: req).resume()
        }
        
        // Petición de respaldo a través del servidor
        if let serverURL = URL(string: "\(serverBaseURL)/api/light?action=\(mode)&cam=1") {
            URLSession.shared.dataTask(with: serverURL).resume()
        }
    }

    func ptzMove(action: String) {
        guard let url = URL(string: "\(serverBaseURL)/api/ptz?action=\(action)&cam=1") else { return }
        URLSession.shared.dataTask(with: url).resume()
    }

    func ptzStop() {
        ptzMove(action: "stop")
    }

    // Carga grabaciones locales guardadas por MediaMTX en la PC
    @MainActor
    func loadSDFiles() async {
        isLoadingSD = true
        sdLoadError = nil

        guard let url = URL(string: "\(serverBaseURL)/api/recordings") else {
            sdLoadError = "URL del servidor inválida"
            isLoadingSD = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            self.sdFiles = try JSONDecoder().decode([SDFile].self, from: data)
        } catch {
            self.sdLoadError = "Error al cargar grabaciones: \(error.localizedDescription)"
        }

        isLoadingSD = false
    }
}
