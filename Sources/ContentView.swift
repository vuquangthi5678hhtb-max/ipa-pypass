import SwiftUI

struct ToolItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let badge: String
    let resultText: String
}

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("simDelay") private var simDelay: Double = 1.5

    @State private var showSettings = false
    @State private var selectedTab = 0
    @State private var isRunning = false
    @State private var progress: Double = 0.0
    @State private var statusText = "Sẵn sàng nghịch"
    @State private var logs: [String] = [
        "[v1.0.1] Phần mềm phát triển bởi Hugiem."
    ]

    private let appVersion = "1.0.1"
    private let devNotice = "Phần mềm phát triển bởi Hugiem"

    private let coreTools: [ToolItem] = [
        ToolItem(title: "Bypass MDM", subtitle: "Mô phỏng bỏ qua quản lý MDM", icon: "building.2.crop.circle", badge: "MDM", resultText: "MDM profile check xong (sandbox)."),
        ToolItem(title: "Bypass Passcode", subtitle: "Giả lập quét khóa màn hình", icon: "lock.open.display", badge: "PASS", resultText: "Passcode scan xong — không đổi dữ liệu."),
        ToolItem(title: "Ẩn iCloud", subtitle: "Giả lập ẩn thông tin iCloud", icon: "icloud.slash", badge: "ICLOUD", resultText: "Ẩn iCloud mô phỏng thành công.")
    ]

    private let extraTools: [ToolItem] = [
        ToolItem(title: "Check Baseband", subtitle: "Đọc thông số giả lập mạng & serial", icon: "antenna.radiowaves.left.and.right", badge: "DIAG", resultText: "Baseband: MOCK-01 | Serial: LAB-101."),
        ToolItem(title: "SysInfo Lab", subtitle: "Xem thông tin giả lập hệ thống", icon: "cpu", badge: "INFO", resultText: "iOS Lab v1.0.1 | RAM Mock 6/8GB."),
        ToolItem(title: "Fake Respring", subtitle: "Hiệu ứng giả lập respring giao diện", icon: "arrow.clockwise.circle", badge: "PRANK", resultText: "Fake Respring hoàn tất.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                (isDarkMode ? Color(red: 0.06, green: 0.07, blue: 0.10) : Color(red: 0.95, green: 0.96, blue: 0.98))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.cyan)
                            Text("Thông báo: \(devNotice).")
                                .font(.caption.weight(.semibold))
                            Spacer()
                        }
                        .padding(12)
                        .background(.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

                        Picker("Chế độ", selection: $selectedTab) {
                            Text("Bypass Core").tag(0)
                            Text("Nghịch Thêm").tag(1)
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(statusText)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.caption.monospaced())
                            }
                            ProgressView(value: progress)
                                .tint(.cyan)
                        }
                        .padding(12)
                        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))

                        ForEach(selectedTab == 0 ? coreTools : extraTools) { item in
                            Button {
                                runTool(item)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: item.icon)
                                        .font(.title3)
                                        .foregroundStyle(.cyan)
                                        .frame(width: 36, height: 36)
                                        .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.primary)
                                        Text(item.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text(item.badge)
                                        .font(.caption2.bold().monospaced())
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(.secondary.opacity(0.16), in: Capsule())
                                }
                                .padding(12)
                                .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(isRunning)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Log nghịch chơi")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            ForEach(logs.suffix(6), id: \.self) { line in
                                Text(line)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(isDarkMode ? .green : .blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(isDarkMode ? Color.black.opacity(0.45) : Color.white, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding()
                }
            }
            .navigationTitle("Bypass IP v\(appVersion)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    Form {
                        Section("Giao diện") {
                            Toggle("Nền tối (Dark Mode)", isOn: $isDarkMode)
                        }
                        Section("Cài đặt giả lập") {
                            Toggle("Rung phản hồi", isOn: $enableHaptics)
                            Slider(value: $simDelay, in: 0.5...3.0, step: 0.5)
                        }
                        Section("Thông tin") {
                            LabeledContent("Ứng dụng", value: "Bypass IP")
                            LabeledContent("Phiên bản", value: appVersion)
                            LabeledContent("Thông báo", value: devNotice)
                        }
                    }
                    .navigationTitle("Cài đặt")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Xong") { showSettings = false }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private var cardBg: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.white
    }

    private func runTool(_ item: ToolItem) {
        if enableHaptics {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        isRunning = true
        progress = 0.2
        statusText = "Đang chạy \(item.title)..."
        logs.append("[\(item.badge)] Bắt đầu \(item.title)")

        Task { @MainActor in
            for step in 1...5 {
                try? await Task.sleep(nanoseconds: UInt64((simDelay / 5.0) * 1_000_000_000))
                progress = Double(step) / 5.0
            }
            logs.append("[OK] \(item.resultText)")
            statusText = "Sẵn sàng nghịch"
            isRunning = false
            if enableHaptics {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}
