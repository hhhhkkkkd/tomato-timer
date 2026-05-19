import SwiftUI
import Combine

struct ContentView: View {
    @State private var totalMinutes: Double = 25
    @State private var remainingSeconds: Int = 25 * 60
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var inputMinutes: String = "25"
    
    // 动画控制
    @State private var timeScale: CGFloat = 1.0
    @State private var receiptProgress: CGFloat = 0.0 // 控制收据吐出的进度 (0.0 到 1.0)
    @State private var showReceipt = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var progress: Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(remainingSeconds) / (totalMinutes * 60)
    }
    
    // 复古终端绿色
    private let pixelGreen = Color(red: 0.0, green: 1.0, blue: 0.33)
    private let pixelDarkGreen = Color(red: 0.0, green: 0.25, blue: 0.08)
    
    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter.string(from: Date())
    }
    
    // 触发模拟打印机的“滋滋”吐纸动画
    private func triggerReceiptAnimation() {
        showReceipt = true
        receiptProgress = 0.0
        
        // 分段式定时器：模拟热敏打印机一卡一卡吐纸的复古感
        var currentStep = 0
        let totalSteps = 5
        
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            currentStep += 1
            withAnimation(.backToFrontPixel) {
                receiptProgress = CGFloat(currentStep) / CGFloat(totalSteps)
            }
            if currentStep >= totalSteps {
                timer.invalidate()
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 25) {
                Text("REVISION TIMER v1.1")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(pixelGreen)
                    .padding(.top)
                
                // 时间输入区
                HStack {
                    Text("SET MINUTES:")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(pixelGreen)
                    
                    // 彻底像素化的输入框
                    TextField("", text: $inputMinutes)
                        .textFieldStyle(.plain) // 核心：移除 macOS/iOS 的默认立体阴影和边框
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.black) // 文字全黑
                        .multilineTextAlignment(.center) // 文字居中
                        .padding(6)
                        .frame(width: 70)
                        .background(pixelGreen) // 整个背景统一为最纯正的高级绿
                        .border(pixelGreen, width: 1) // 确保边缘颜色完全一致
                        .modifier(KeyboardTypeModifier())
                        .disabled(isRunning || isPaused)
                        .onChange(of: inputMinutes) { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue { inputMinutes = filtered }
                            if let mins = Double(filtered), mins > 0 {
                                totalMinutes = mins
                                remainingSeconds = Int(totalMinutes * 60)
                            }
                        }
                }
                .padding(.horizontal)
                
                // 环形倒计时
                ZStack {
                    Circle()
                        .stroke(pixelDarkGreen, style: StrokeStyle(lineWidth: 16, lineCap: .butt, dash: [4, 4]))
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                        .stroke(pixelGreen, style: StrokeStyle(lineWidth: 16, lineCap: .butt, dash: [4, 4]))
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.linear(duration: 1), value: progress)
                    
                    Text(timeString(from: remainingSeconds))
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(pixelGreen)
                        .shadow(color: pixelGreen.opacity(0.6), radius: 10)
                        .scaleEffect(timeScale)
                        .animation(.spring(response: 0.2, dampingFraction: 0.4), value: timeScale)
                }
                .frame(width: 220, height: 220)
                .padding(.vertical, 10)
                
                // 控制按钮
                HStack(spacing: 15) {
                    Button(action: {
                        if isPaused {
                            isPaused = false
                        } else {
                            remainingSeconds = Int(totalMinutes * 60)
                            isRunning = true
                            isPaused = false
                        }
                        showReceipt = false
                        receiptProgress = 0.0
                    }) {
                        Text(isPaused ? "RESUME" : "START")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .frame(width: 85, height: 35)
                            .background(isRunning && !isPaused ? Color.clear : pixelGreen)
                            .foregroundColor(isRunning && !isPaused ? pixelDarkGreen : .black)
                            .border(pixelGreen, width: 2)
                    }
                    .disabled(isRunning && !isPaused)
                    
                    Button(action: { isPaused = true }) {
                        Text("PAUSE")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .frame(width: 85, height: 35)
                            .background(isPaused ? pixelGreen : Color.clear)
                            .foregroundColor(isPaused ? .black : pixelGreen)
                            .border(pixelGreen, width: 2)
                    }
                    .disabled(!isRunning || isPaused)
                    
                    Button(action: {
                        isRunning = false
                        isPaused = false
                        remainingSeconds = Int(totalMinutes * 60)
                        showReceipt = false
                        receiptProgress = 0.0
                    }) {
                        Text("STOP")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .frame(width: 85, height: 35)
                            .foregroundColor(.red)
                            .border(Color.red, width: 2)
                    }
                    .disabled(!isRunning && !isPaused)
                }
                
                // 打印机及收据区域
                VStack(spacing: 0) {
                    // 打印机槽口 - 已根据你的要求修改
                    Rectangle()
                        .fill(Color(white: 0.15))
                        .frame(width: 240, height: 10)
                        .overlay(Rectangle().stroke(pixelDarkGreen, lineWidth: 1))
                        .zIndex(2)
                    
                    // 收据组件
                    ZStack(alignment: .top) {
                        if showReceipt {
                            ReceiptView(durationMinutes: Int(totalMinutes), dateStr: currentDateString)
                                .offset(y: -210 + (210 * receiptProgress))
                        } else {
                            Color.clear.frame(height: 210)
                        }
                    }
                    .frame(width: 220, height: 210, alignment: .top)
                    .clipped()
                }
                
                Spacer()
            }
        }
        .onReceive(timer) { _ in
            guard isRunning, !isPaused else { return }
            
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                timeScale = 1.05
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    timeScale = 1.0
                }
            }
            
            if remainingSeconds == 0 {
                isRunning = false
                isPaused = false
                triggerReceiptAnimation()
            }
        }
    }
}

// 独立组件：带智能时间解析的像素收据
struct ReceiptView: View {
    let durationMinutes: Int
    let dateStr: String
    
    private var formattedDuration: String {
        let hours = durationMinutes / 60
        let mins = durationMinutes % 60
        
        if hours > 0 {
            return String(format: "%02dH %02dM", hours, mins)
        } else {
            return String(format: "%02d MINS", mins)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                Text("*********************")
                Text("* SESSION COMPLETE *")
                Text("*********************")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer().frame(height: 5)
            
            Text("DATE:    \(dateStr)")
            Text("TICKET:  #\(String(Int.random(in: 1000...9999)))")
            Text("ELAPSED: \(formattedDuration)")
            Text("STATUS:  100% PASSED")
            
            Spacer().frame(height: 5)
            Text("---------------------")
            Text("* GOOD JOB!      *")
                .frame(maxWidth: .infinity, alignment: .center)
            Text("---------------------")
            
            Text("v v v v v v v v v v v")
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.system(size: 13, weight: .bold, design: .monospaced))
        .foregroundColor(.black)
        .padding(15)
        .frame(width: 220, height: 210, alignment: .topLeading)
        .background(Color(white: 0.9))
        .border(Color.white, width: 2)
        .shadow(color: Color.green.opacity(0.15), radius: 8, y: 4)
    }
}

// 跨平台键盘适配
struct KeyboardTypeModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.keyboardType(.numberPad)
        #else
        content
        #endif
    }
}

extension Animation {
    static var backToFrontPixel: Animation {
        Animation.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
