import SwiftUI

struct ToolItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let badge: String
    let actionType: ActionKind
}

enum ActionKind {
    case mdm
    case passcode
    case icloudHide
    case basebandCheck
    case sysInfo
    case prankRespring
}

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("simDelay") private var simDelay: Double = 1.6

    @State private var showSettings = false
    @State private var activeLog: [String] = [
        "[v1.0.1] Bypass IP lab initialized — Phần mềm phát triển bởi Hugiem."
    ]
    @State private var isRunning = false
    @State private var progress: Double = 0.0
    @State private var currentTaskTitle = ""
    @State private var selectedSegment = 0

    private let appVersion = "1.0.1"
    private let developerName = "Hugiem"

    private let bypassTools: [ToolItem] = [
        ToolItem(
            title: "Bypass MDM",
            subtitle: "Mô phỏng bỏ qua cấu hình quản lý thiết bị từ xa",
            icon: "building.2.crop.circle",
            badge: "MDM",
            actionType: .mdm
        ),
        ToolItem(
            title: "Bypass Mật khẩu màn hình",
            subtitle: "Giả lập quét trạng thái khóa passcode màn hình",
            icon: "lock.open.display",
            badge: "PASSCODE",
            actionType: .passcode
        ),
        ToolItem(
            title: "Ẩn iCloud",
            subtitle: "Giả lập ẩn thông tin tài khoản iCloud trên giao diện",
            icon: "icloud.slash",
            badge: "ICL HIDE",
            actionType: .icloudHide
        )
    ]

    private let funTools: [ToolItem] = [
        ToolItem(
            title: "Check Baseband & Serial",
            subtitle: "Đọc thông số giả lập phần cứng & trạng thái mạng",
            icon: "antenna.radiowaves.left.and.right",
            badge: "DIAG",
            actionType: .basebandCheck
        ),
        ToolItem(
            title: "SysInfo Lab",
            subtitle: "In thông tin phiên bản iOS & bộ nhớ ảo nghịch chơi",
            icon: "cpu",
            badge: "INFO",
            actionType: .sysInfo
        ),
        ToolItem(
            title: "Fake Respring Alert",
            subtitle: "Chạy hiệu ứng giả lập khởi động lại giao diện",
            icon: "arrow.clockwise.circle",
            badge: "PRANK",
            actionType: .prankRespring
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                (isDarkMode ? Color(red: 0.06, green: 0.07, blue: 0.10) : Color(red: 0.95, green: 0.96, blue: 0.98))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerBanner
                        developerNoticeBanner
                        modeSwitcher
                        statusCard
                        toolListSection
                        consoleSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Bypass IP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("v\(appVersion)")
                        .font(.caption.monospaced().bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheetView(
                    isDarkMode: $isDarkMode,
                    enableHaptics: $enableHaptics,
                    simDelay: $simDelay,
                    appVersion: appVersion,
                    developerName: developerName,
                    onClearLog: {
                        activeLog = ["[v\(appVersion)] Console cleared — Dev: \(developerName)."]
                    }
                )
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private var headerBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Image(systemName: "waveform.path.ecg.rectangle")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Bypass IP")
                        .font(.title3.bold())
                    Text("PLAYGROUND")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.cyan.opacity(0.2), in: Capsule())
                        .foregroundStyle(.cyan)
                }
                Text("Bản nghịch chơi v\(appVersion) • Sáng / Tối linh hoạt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private var developerNoticeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.cyan)
            Text("Thông báo: Phần mềm phát triển bởi \(developerName).")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var modeSwitcher: some View {
        Picker("Chế độ", selection: $selectedSegment) {
            Text("Bypass Core").tag(0)
            Text("Nghịch Thêm").tag(1)
        }
        .pickerStyle(.segmented)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(isRunning ? .orange : .green)
                    .frame(width: 9, height: 9)
                Text(isRunning ? "Đang chạy: \(currentTaskTitle)" : "Trạng thái: Sẵn sàng nghịch")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(isRunning ? .orange : .cyan)
        }
        .padding()
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var toolListSection: some View {
        let list = selectedSegment == 0 ? bypassTools : funTools
        return VStack(spacing: 10) {
            ForEach(list) { item in
                Button {
                    runSimulatedTool(item)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.title3)
                            .frame(width: 38, height: 38)
                            .background(.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.cyan)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Text(item.badge)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.secondary.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(isRunning ? .gray : .cyan)
                    }
                    .padding(12)
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 15))
                }
                .disabled(isRunning)
            }
        }
    }

    private var consoleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Log nghịch chơi", systemImage: "terminal")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Xóa log") {
                    activeLog = ["[v\(appVersion)] Log reset — Dev: \(developerName)."]
                }
                .font(.caption)
            }

            VStack(alignment: .leading, spacing: 5) {
                ForEach(activeLog.suffix(8), id: \.self) { line in
                    Text(line)
                        .font(.caption2.monospaced())
                        .foregroundStyle(isDarkMode ? .green.opacity(0.9) : .blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .background(isDarkMode ? Color.black.opacity(0.45) : Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var cardBackground: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.white
    }

    private func runSimulatedTool(_ item: ToolItem) {
        triggerHaptic(.medium)
        isRunning = true
        currentTaskTitle = item.title
        progress = 0.15
        appendLog("[\(item.badge)] Khởi chạy mô phỏng \(item.title)...")

        Task {
            let steps = 5
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: UInt64((simDelay / Double(steps)) * 1_000_000_000))
                await MainActor.run {
                    progress = Double(i) / Double(steps)
                }
            }
            await MainActor.run {
                let resultMessage = messageFor(item.actionType)
                appendLog("[OK] \(resultMessage)")
                triggerHaptic(.success)
                isRunning = false
            }
        }
    }

    private func messageFor(_ kind: ActionKind) -> String {
        switch kind {
        case .mdm:
            return "MDM profile check: mô phỏng hoàn tất (chế độ sandbox)."
        case .passcode:
            return "Passcode scan: mô phỏng xong — không thay đổi dữ liệu máy."
        case .icloudHide:
            return "Ẩn iCloud: cập nhật trạng thái hiển thị giả lập thành công."
        case .basebandCheck:
            return "Baseband: SIM-MOCK-01 | Serial: IP-LAB-101 | Status: OK."
        case .sysInfo:
            return "Device: iOS Sandbox | Build: \(appVersion) | RAM Mock: 6.0/8.0 GB."
        case .prankRespring:
            return "Fake Respring: hiệu ứng hoàn tất — màn hình không bị khởi động lại thật."
        }
    }

    private func appendLog(_ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let stamp = formatter.string(from: Date())
        activeLog.append("[\(stamp)] \(text)")
    }

    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enableHaptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

struct SettingsSheetView: View {
    @Binding var isDarkMode: Bool
    @Binding var enableHaptics: Bool
    @Binding var simDelay: Double
    let appVersion: String
    let developerName: String
    let onClearLog: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Giao diện") {
                    Toggle("Nền tối (Dark Mode)", isOn: $isDarkMode)
                    Text("Tắt để chuyển sang nền sáng (Light Mode).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Nghịch chơi") {
                    Toggle("Rung phản hồi (Haptics)", isOn: $enableHaptics)
                    VStack(alignment: .leading) {
                        Text("Tốc độ chạy giả lập: \(simDelay, specifier: "%.1f")s")
                            .font(.subheadline)
                        Slider(value: $simDelay, in: 0.5...4.0, step: 0.5)
                    }
                    Button("Xóa toàn bộ log", role: .destructive) {
                        onClearLog()
                        dismiss()
                    }
                }

                Section("Thông tin") {
                    LabeledContent("Tên ứng dụng", value: "Bypass IP")
                    LabeledContent("Phiên bản", value: appVersion)
                    LabeledContent("Nhà phát triển", value: "Phần mềm phát triển bởi \(developerName)")
                    LabeledContent("Chế độ", value: "Demo / UI Nghịch")
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
