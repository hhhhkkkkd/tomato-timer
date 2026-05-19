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
    @State private var receiptProgress: CGFloat = 0.0
    @State private var showReceipt = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 核心修改点：调整进度计算
    private var progress: Double {
        guard totalMinutes > 0 else { return 1.0 }
        // 如果倒计时结束归零了，强制返回 1.0 (100%)，让亮绿色虚线圈保持满格
        if remainingSeconds == 0 {
            return 1.0
        }
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
    
    private func triggerReceiptAnimation() {
        showReceipt = true
        receiptProgress = 0.0
        
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
            // 全黑底色背景
            Color.black.ignoresSafeArea()
            
            // 核心：强制限制内容整体宽度为 380，模拟手机或者复古紧凑机身
            VStack(spacing: 25) {
                
                // 💡 已经为你删除了这里的 REVISION TIMER v1.1 标题
                
                // 时间输入区
                HStack(spacing: 12) {
                    Text("SET MINUTES:")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(pixelGreen)
                    
                    // 彻底解决 Mac 杂色：用原生 Text 覆盖在上面，做绝对纯净的亮绿输入框
                    ZStack {
                        Rectangle()
                            .fill(pixelGreen)
                        
                        TextField("", text: $inputMinutes)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 2)
                    }
                    .frame(width: 60, height: 26)
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
                .padding(.top, 45) // 稍微加一点顶部留白，让布局更美观
                
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
                        .font(.system(size: 46, weight: .black, design: .monospaced))
                        .foregroundColor(pixelGreen)
                        .shadow(color: pixelGreen.opacity(0.6), radius: 10)
                        .scaleEffect(timeScale)
                        .animation(.spring(response: 0.2, dampingFraction: 0.4), value: timeScale)
                }
                .frame(width: 210, height: 210)
                .padding(.vertical, 10)
                
                // 控制按钮（剥离所有 Mac 默认阴影）
                HStack(spacing: 12) {
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
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .frame(width: 80, height: 32)
                            .background(isRunning && !isPaused ? Color.clear : pixelGreen)
                            .foregroundColor(isRunning && !isPaused ? pixelDarkGreen : .black)
                            .border(pixelGreen, width: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning && !isPaused)
                    
                    Button(action: { isPaused = true }) {
                        Text("PAUSE")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .frame(width: 80, height: 32)
                            .background(isPaused ? pixelGreen : Color.clear)
                            .foregroundColor(isPaused ? .black : pixelGreen)
                            .border(pixelGreen, width: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isRunning || isPaused)
                    
                    Button(action: {
                        isRunning = false
                        isPaused = false
                        remainingSeconds = Int(totalMinutes * 60)
                        showReceipt = false
                        receiptProgress = 0.0
                    }) {
                        Text("STOP")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .frame(width: 80, height: 32)
                            .foregroundColor(.red)
                            .border(Color.red, width: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isRunning && !isPaused)
                }
                
                // 打印机及收据区域
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(white: 0.15))
                        .frame(width: 240, height: 10)
                        .overlay(Rectangle().stroke(pixelDarkGreen, lineWidth: 1))
                        .zIndex(2)
                    
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
            .frame(width: 380) // 锁死面板宽度，不论窗口多大，内容永远精致紧凑居中
        }
        // 设置整个 Mac 软件打开时的初始和最小窗口大小
        .frame(minWidth: 400, minHeight: 650)
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
