import SwiftUI
import Combine

struct ContentView: View {
    @State private var totalMinutes: Double = 25
    @State private var remainingSeconds: Int = 25 * 60
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var inputMinutes: String = "25"
    
    @State private var timeScale: CGFloat = 1.0
    @State private var finishedFlash = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var progress: Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(remainingSeconds) / (totalMinutes * 60)
    }
    
    private var progressColor: Color {
        if progress > 0.5 {
            return .green
        } else if progress > 0.2 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // 时间设置
            HStack {
                Text("专注时长(分钟):")
                    .font(.headline)
                TextField("分钟", text: $inputMinutes)
                    .frame(width: 60)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isRunning || isPaused)
                    .onChange(of: inputMinutes) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue {
                            inputMinutes = filtered
                        }
                        if let mins = Double(filtered), mins > 0 {
                            totalMinutes = mins
                            remainingSeconds = Int(totalMinutes * 60)
                        }
                    }
            }
            .padding(.horizontal)
            
            // 倒计时画面 + 动画
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.15)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round)
                    )
                    .foregroundColor(progressColor)
                    .rotationEffect(Angle(degrees: 270))
                    .animation(.linear(duration: 1), value: progress)
                    .opacity(finishedFlash ? 0.4 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true), value: finishedFlash)
                
                Text(timeString(from: remainingSeconds))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(progressColor)
                    .scaleEffect(timeScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0), value: timeScale)
            }
            .frame(width: 250, height: 250)
            .padding()
            
            // 控制按钮
            HStack(spacing: 40) {
                Button(action: {
                    if isPaused {
                        isPaused = false
                    } else {
                        remainingSeconds = Int(totalMinutes * 60)
                        isRunning = true
                        isPaused = false
                    }
                    finishedFlash = false
                }) {
                    Text("开始")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 80, height: 40)
                        .background((isRunning && !isPaused) ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(isRunning && !isPaused)
                
                Button(action: {
                    isPaused = true
                }) {
                    Text("暂停")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 80, height: 40)
                        .background(isPaused ? Color.orange : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(!isRunning || isPaused)
                
                Button(action: {
                    isRunning = false
                    isPaused = false
                    remainingSeconds = Int(totalMinutes * 60)
                    finishedFlash = false
                }) {
                    Text("停止")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 80, height: 40)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(!isRunning && !isPaused)
            }
        }
        .padding()
        .onReceive(timer) { _ in
            guard isRunning, !isPaused else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                timeScale = 1.3
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    timeScale = 1.0
                }
            }
            if remainingSeconds == 0 {
                isRunning = false
                isPaused = false
                finishedFlash = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
