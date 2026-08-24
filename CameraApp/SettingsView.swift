import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: CameraViewModel
    @State private var isTesting = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Servidor")) {
                    TextField("URL del servidor", text: $viewModel.serverBaseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    Text("Ejemplo: http://192.168.1.22:3000")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: testConnection) {
                        HStack {
                            Text("Probar conexión")
                            if isTesting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isTesting || viewModel.serverBaseURL.isEmpty)
                }
                
                Section(header: Text("URLs Configuradas")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stream:")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text(streamPreview)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Divider()
                        
                        Text("PTZ:")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("\(viewModel.serverBaseURL)/api/ptz")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Divider()
                        
                        Text("Grabaciones:")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("\(viewModel.serverBaseURL)/api/recordings")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Configuración")
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var streamPreview: String {
        let base = viewModel.serverBaseURL.replacingOccurrences(of: ":3000", with: ":8888")
        return "\(base)/camara/index.m3u8"
    }
    
    private func testConnection() {
        guard let url = URL(string: "\(viewModel.serverBaseURL)/api/status") else {
            alertTitle = "Error"
            alertMessage = "La URL ingresada no es válida"
            showAlert = true
            return
        }
        
        isTesting = true
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isTesting = false
                
                if let error = error {
                    self.alertTitle = "Fallo de conexión"
                    self.alertMessage = "Error: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        self.alertTitle = "Éxito"
                        self.alertMessage = "Conexión establecida correctamente con el servidor"
                    } else {
                        self.alertTitle = "Error"
                        self.alertMessage = "El servidor respondió con código \(httpResponse.statusCode)"
                    }
                }
                self.showAlert = true
            }
        }.resume()
    }
}
