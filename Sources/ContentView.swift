import SwiftUI
import PhotosUI

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
    @AppStorage("bgOverlayOpacity") private var bgOverlayOpacity: Double = 0.42
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("savedUserLabel") private var savedUserLabel = "Hugiem Lab"

    @State private var isRegisterMode = false
    @State private var authAccountInput = ""
    @State private var authPasswordInput = ""
    @State private var authNote = ""

    @State private var showBanner = true
    @State private var showSettings = false
    @State private var selectedTab = 0
    @State private var isRunning = false
    @State private var progress: Double = 0.0
    @State private var statusText = "Sẵn sàng nghịch v1.1.0"
    @State private var logs: [String] = [
        "[v1.1.0] Phần mềm phát triển bởi Hugiem."
    ]

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var customBgImage: UIImage? = ContentView.loadSavedImage()

    private let appVersion = "1.1.0"
    private let devNotice = "Phần mềm phát triển bởi Hugiem"

    private let coreTools: [ToolItem] = [
        ToolItem(title: "Bypass MDM", subtitle: "Mô phỏng bỏ qua quản lý MDM", icon: "building.2.crop.circle", badge: "MDM", resultText: "MDM profile check xong (sandbox)."),
        ToolItem(title: "Bypass Passcode", subtitle: "Giả lập quét khóa màn hình", icon: "lock.open.display", badge: "PASS", resultText: "Passcode scan xong — không đổi dữ liệu."),
        ToolItem(title: "Ẩn iCloud", subtitle: "Giả lập ẩn thông tin iCloud", icon: "icloud.slash", badge: "ICLOUD", resultText: "Ẩn iCloud mô phỏng thành công.")
    ]

    private let extraTools: [ToolItem] = [
        ToolItem(title: "Check Baseband", subtitle: "Đọc thông số giả lập mạng & serial", icon: "antenna.radiowaves.left.and.right", badge: "DIAG", resultText: "Baseband: MOCK-01 | Serial: LAB-110."),
        ToolItem(title: "SysInfo Lab", subtitle: "Xem thông tin giả lập hệ thống", icon: "cpu", badge: "INFO", resultText: "iOS Lab v1.1.0 | RAM Mock 6/8GB."),
        ToolItem(title: "Fake Respring", subtitle: "Hiệu ứng giả lập respring giao diện", icon: "arrow.clockwise.circle", badge: "PRANK", resultText: "Fake Respring hoàn tất.")
    ]

    var body: some View {
        ZStack {
            backdropLayer
                .ignoresSafeArea()

            if isLoggedIn {
                mainAppView
            } else {
                authGateView
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showSettings) {
            settingsSheetView
        }
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        customBgImage = uiImage
                        Self.saveImage(uiImage)
                    }
                }
            }
        }
    }

    private var authGateView: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.cyan)
                        .shadow(color: .cyan.opacity(0.65), radius: 14)

                    Text("Bypass IP v\(appVersion)")
                        .font(.title2.bold())

                    Text("Chế độ nghịch — nhập gì cũng vào được")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                Picker("Chế độ tài khoản", selection: $isRegisterMode) {
                    Text("Đăng nhập").tag(false)
                    Text("Đăng ký").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 14) {
                    TextField(isRegisterMode ? "Tên tài khoản mới (tùy ý)" : "Tài khoản (gõ gì cũng được)", text: $authAccountInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                    SecureField(isRegisterMode ? "Mật khẩu mới (tùy ý)" : "Mật khẩu (gõ gì cũng được)", text: $authPasswordInput)
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                    if isRegisterMode {
                        TextField("Ghi chú hoặc biệt danh (tùy chọn)", text: $authNote)
                            .padding(14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        let cleanName = authAccountInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        savedUserLabel = cleanName.isEmpty ? (isRegisterMode ? "Member Lab" : "Hugiem Lab") : cleanName
                        logs.append(isRegisterMode ? "[AUTH] Đã đăng ký nhanh: \(savedUserLabel)" : "[AUTH] Đã đăng nhập nhanh: \(savedUserLabel)")
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isLoggedIn = true
                        }
                    } label: {
                        Text(isRegisterMode ? "Đăng ký & Vào App" : "Đăng nhập & Vào App")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .shadow(color: .cyan.opacity(0.45), radius: 12)
                    }
                    .buttonStyle(.plain)

                    Button("Vào thẳng không cần điền") {
                        savedUserLabel = "Guest Lab"
                        logs.append("[AUTH] Vào thẳng chế độ nghịch.")
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isLoggedIn = true
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.cyan)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(isDarkMode ? 0.14 : 0.35), lineWidth: 1)
                )

                Text(devNotice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
        }
    }

    private var mainAppView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if showBanner {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .font(.title3)
                                .foregroundStyle(.cyan)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Thông báo v\(appVersion) • \(savedUserLabel)")
                                    .font(.subheadline.bold())
                                Text("\(devNotice) — bấm X để tắt thông báo.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showBanner = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.cyan.opacity(0.35), lineWidth: 1)
                        )
                    }

                    Picker("Chế độ", selection: $selectedTab) {
                        Text("Bypass Core").tag(0)
                        Text("Nghịch Thêm").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(statusText)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.caption.monospaced())
                        }
                        ProgressView(value: progress)
                            .tint(.cyan)
                            .scaleEffect(y: 1.3)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))

                    VStack(spacing: 12) {
                        ForEach(selectedTab == 0 ? coreTools : extraTools) { item in
                            Button {
                                runTool(item)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: item.icon)
                                        .font(.title2)
                                        .foregroundStyle(.cyan)
                                        .frame(width: 48, height: 48)
                                        .background(.cyan.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(item.subtitle)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Text(item.badge)
                                        .font(.caption.bold().monospaced())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.cyan.opacity(0.18), in: Capsule())
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, minHeight: 78)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(isDarkMode ? 0.14 : 0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isRunning)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Log nghịch chơi")
                                .font(.subheadline.bold())
                            Spacer()
                            Button("Hiện lại thông báo") {
                                withAnimation(.easeIn(duration: 0.2)) {
                                    showBanner = true
                                }
                            }
                            .font(.caption.weight(.semibold))
                        }

                        ForEach(logs.suffix(6), id: \.self) { line in
                            Text(line)
                                .font(.caption.monospaced())
                                .foregroundStyle(isDarkMode ? .green : .blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(16)
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
        }
    }

    private var settingsSheetView: some View {
        NavigationStack {
            Form {
                Section("Ảnh nền ứng dụng") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(customBgImage == nil ? "Tự chọn ảnh từ thư viện" : "Đổi ảnh nền khác", systemImage: "photo.on.rectangle.angled")
                    }

                    if customBgImage != nil {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Độ tối phủ lên ảnh: \(Int(bgOverlayOpacity * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $bgOverlayOpacity, in: 0.0...0.85, step: 0.05)
                        }

                        Button("Xóa ảnh nền (về nền hào quang)", role: .destructive) {
                            customBgImage = nil
                            Self.deleteSavedImage()
                        }
                    }
                }

                Section("Giao diện & Thông báo") {
                    Toggle("Nền tối (Dark Mode)", isOn: $isDarkMode)
                    Toggle("Hiện thông báo đầu trang", isOn: $showBanner)
                }

                Section("Cài đặt giả lập") {
                    Toggle("Rung phản hồi", isOn: $enableHaptics)
                    Slider(value: $simDelay, in: 0.5...3.0, step: 0.5)
                }

                Section("Tài khoản & Thông tin") {
                    LabeledContent("Tài khoản", value: savedUserLabel)
                    LabeledContent("Ứng dụng", value: "Bypass IP")
                    LabeledContent("Phiên bản", value: appVersion)
                    Button("Quay lại màn Đăng nhập / Đăng ký", role: .destructive) {
                        showSettings = false
                        isLoggedIn = false
                    }
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

    @ViewBuilder
    private var backdropLayer: some View {
        if let customBgImage {
            GeometryReader { geo in
                ZStack {
                    Image(uiImage: customBgImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                    Color.black.opacity(bgOverlayOpacity)
                }
            }
        } else {
            ZStack {
                LinearGradient(
                    colors: isDarkMode
                        ? [Color(red: 0.04, green: 0.07, blue: 0.16), Color(red: 0.08, green: 0.14, blue: 0.28), Color(red: 0.03, green: 0.04, blue: 0.09)]
                        : [Color(red: 0.86, green: 0.94, blue: 1.0), Color(red: 0.94, green: 0.97, blue: 1.0), Color(red: 0.84, green: 0.91, blue: 0.99)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.cyan.opacity(isDarkMode ? 0.45 : 0.38), .blue.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 36)
                    .offset(x: -110, y: -210)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.indigo.opacity(isDarkMode ? 0.42 : 0.28), .cyan.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 185
                        )
                    )
                    .frame(width: 370, height: 370)
                    .blur(radius: 34)
                    .offset(x: 125, y: 190)

                Ellipse()
                    .fill(.cyan.opacity(isDarkMode ? 0.14 : 0.18))
                    .frame(width: 320, height: 140)
                    .blur(radius: 28)
                    .rotationEffect(.degrees(-18))
                    .offset(x: 10, y: -20)
            }
        }
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
            statusText = "Sẵn sàng nghịch v1.1.0"
            isRunning = false
            if enableHaptics {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private static var bgFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("custom_bg.jpg")
    }

    private static func saveImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: bgFileURL, options: .atomic)
        }
    }

    private static func loadSavedImage() -> UIImage? {
        guard let data = try? Data(contentsOf: bgFileURL) else { return nil }
        return UIImage(data: data)
    }

    private static func deleteSavedImage() {
        try? FileManager.default.removeItem(at: bgFileURL)
    }
}
