import SwiftUI

struct PTZControlView: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Control PTZ")
                .font(.headline)
            
            Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                GridRow {
                    Color.clear.frame(width: 65, height: 65)
                    PTZButton(icon: "arrowtriangle.up.fill", action: "up", viewModel: viewModel)
                    Color.clear.frame(width: 65, height: 65)
                }
                
                GridRow {
                    PTZButton(icon: "arrowtriangle.backward.fill", action: "left", viewModel: viewModel)
                    
                    Button(action: {
                        viewModel.ptzStop()
                    }) {
                        Text("STOP")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 65, height: 65)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    
                    PTZButton(icon: "arrowtriangle.forward.fill", action: "right", viewModel: viewModel)
                }
                
                GridRow {
                    Color.clear.frame(width: 65, height: 65)
                    PTZButton(icon: "arrowtriangle.down.fill", action: "down", viewModel: viewModel)
                    Color.clear.frame(width: 65, height: 65)
                }
            }
        }
    }
}

struct PTZButton: View {
    let icon: String
    let action: String
    @ObservedObject var viewModel: CameraViewModel
    @State private var isPressing = false
    
    var body: some View {
        Image(systemName: icon)
            .font(.title2)
            .frame(width: 65, height: 65)
            .background(isPressing ? Color.blue.opacity(0.4) : Color.blue.opacity(0.15))
            .foregroundColor(.blue)
            .clipShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressing {
                            isPressing = true
                            viewModel.ptzMove(action: action)
                        }
                    }
                    .onEnded { _ in
                        isPressing = false
                        viewModel.ptzStop()
                    }
            )
    }
}
