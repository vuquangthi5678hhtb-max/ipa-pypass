import SwiftUI
import UIKit

struct SpinReward: Identifiable, Codable {
    let id: UUID
    let label: String
    let amount: Int
    let weight: Int

    init(id: UUID = UUID(), label: String, amount: Int, weight: Int) {
        self.id = id
        self.label = label
        self.amount = amount
        self.weight = max(1, weight)
    }
}

enum GameCategory: String, CaseIterable, Identifiable, Codable {
    case lienQuan = "Liên Quân"
    case freeFire = "Free Fire"
    case fcMobile = "FC Mobile"

    var id: String { rawValue }

    var cost: Int {
        switch self {
        case .lienQuan: return 10_000
        case .freeFire: return 15_000
        case .fcMobile: return 20_000
        }
    }

    var shortUnit: String {
        switch self {
        case .lienQuan: return "QH"
        case .freeFire: return "KC"
        case .fcMobile: return "FV"
        }
    }

    var rewards: [SpinReward] {
        switch self {
        case .lienQuan:
            return [
                SpinReward(label: "60 QH", amount: 60, weight: 34),
                SpinReward(label: "150 QH", amount: 150, weight: 28),
                SpinReward(label: "300 QH", amount: 300, weight: 19),
                SpinReward(label: "650 QH", amount: 650, weight: 11),
                SpinReward(label: "1.200 QH", amount: 1200, weight: 6),
                SpinReward(label: "2.500 QH", amount: 2500, weight: 2)
            ]
        case .freeFire:
            return [
                SpinReward(label: "70 KC", amount: 70, weight: 34),
                SpinReward(label: "140 KC", amount: 140, weight: 28),
                SpinReward(label: "290 KC", amount: 290, weight: 19),
                SpinReward(label: "580 KC", amount: 580, weight: 11),
                SpinReward(label: "1.150 KC", amount: 1150, weight: 6),
                SpinReward(label: "2.200 KC", amount: 2200, weight: 2)
            ]
        case .fcMobile:
            return [
                SpinReward(label: "100 FV", amount: 100, weight: 34),
                SpinReward(label: "200 FV", amount: 200, weight: 28),
                SpinReward(label: "450 FV", amount: 450, weight: 19),
                SpinReward(label: "950 FV", amount: 950, weight: 11),
                SpinReward(label: "1.800 FV", amount: 1800, weight: 6),
                SpinReward(label: "3.500 FV", amount: 3500, weight: 2)
            ]
        }
    }
}

enum LoginType: String, CaseIterable, Identifiable, Codable {
    case facebook = "Facebook"
    case google = "Google"
    case account = "Tài khoản"

    var id: String { rawValue }
}

struct MemberProfile: Codable, Identifiable {
    let id: UUID
    let username: String
    let password: String
    var balance: Int
    var quanHuy: Int
    var kimCuong: Int
    var fv: Int
}

struct MarketItem: Identifiable, Codable {
    let id: UUID
    let owner: String
    let game: GameCategory
    let title: String
    let price: Int
    let loginType: LoginType
    let imageData: Data?
}

struct WheelSegmentShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct LibraryImagePicker: UIViewControllerRepresentable {
    let onSelect: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onSelect: (UIImage?) -> Void

        init(onSelect: @escaping (UIImage?) -> Void) {
            self.onSelect = onSelect
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let img = info[.originalImage] as? UIImage
            onSelect(img)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onSelect(nil)
            picker.dismiss(animated: true)
        }
    }
}

struct ContentView: View {
    private let profilesKey = "lab_notebook_profiles_v1"
    private let activeKey = "lab_notebook_active_v1"
    private let itemsKey = "lab_notebook_items_v1"
    private let darkKey = "lab_notebook_dark_v1"
    private let hapticKey = "lab_notebook_haptic_v1"

    private let adminBankName = "MB Bank"
    private let adminAccountNumber = "0987654321"
    private let adminAccountHolder = "PHAM NGOC HUNG ANH"

    @State private var profiles: [MemberProfile] = []
    @State private var activeUser: String = ""
    @State private var items: [MarketItem] = []

    @State private var darkTheme: Bool = true
    @State private var enableHaptic: Bool = true

    @State private var isSignUp: Bool = false
    @State private var authName: String = ""
    @State private var authPass: String = ""
    @State private var authPassAgain: String = ""
    @State private var authAlert: String?

    @State private var currentTab: Int = 0
    @State private var filterGame: GameCategory? = nil

    @State private var spinGame: GameCategory = .lienQuan
    @State private var spinAngle: Double = 0
    @State private var isSpinning: Bool = false
    @State private var spinStatus: String = "Chọn vòng quay rồi bấm Quay"

    @State private var draftGame: GameCategory = .lienQuan
    @State private var draftTitle: String = ""
    @State private var draftPrice: String = ""
    @State private var draftLogin: LoginType = .facebook
    @State private var showPicker: Bool = false
    @State private var draftPreview: UIImage?
    @State private var draftImageData: Data?
    @State private var draftNotice: String?

    @State private var selectedTopUpAmount: Int = 50_000
    @State private var customTopUpInput: String = ""
    @State private var showTransferCard: Bool = false
    @State private var walletNotice: String?
    @State private var prefNotice: String?

    private let topUpPresets = [10_000, 20_000, 50_000, 100_000, 200_000, 500_000]

    private var activeIndex: Int? {
        profiles.firstIndex { $0.username.caseInsensitiveCompare(activeUser) == .orderedSame }
    }

    private var currentProfile: MemberProfile? {
        guard let idx = activeIndex else { return nil }
        return profiles[idx]
    }

    private var effectiveTopUpAmount: Int {
        let digits = Int(customTopUpInput.filter { $0.isNumber }) ?? 0
        return digits > 0 ? digits : selectedTopUpAmount
    }

    private var transferMemo: String {
        let cleanUser = activeUser.uppercased().replacingOccurrences(of: " ", with: "")
        return "NAP \(cleanUser) \(effectiveTopUpAmount)"
    }

    private var surfaceBg: Color {
        darkTheme ? Color(red: 0.07, green: 0.08, blue: 0.11) : Color(red: 0.97, green: 0.97, blue: 0.96)
    }

    private var cardSurface: Color {
        darkTheme ? Color(red: 0.14, green: 0.16, blue: 0.21) : Color.white
    }

    private var fieldSurface: Color {
        darkTheme ? Color(red: 0.09, green: 0.10, blue: 0.14) : Color(red: 0.93, green: 0.94, blue: 0.95)
    }

    private var inkPrimary: Color {
        darkTheme ? .white : Color(red: 0.12, green: 0.12, blue: 0.14)
    }

    private var inkSecondary: Color {
        darkTheme ? Color.white.opacity(0.72) : Color(red: 0.42, green: 0.42, blue: 0.46)
    }

    private var strokeTone: Color {
        darkTheme ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    private func pulseHaptic() {
        guard enableHaptic else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func copyToClipboard(_ text: String, label: String) {
        UIPasteboard.general.string = text
        pulseHaptic()
        walletNotice = "Đã sao chép \(label)."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                surfaceBg.ignoresSafeArea()

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(darkTheme ? Color(red: 0.22, green: 0.18, blue: 0.14) : Color(red: 0.22, green: 0.22, blue: 0.25))
                        .frame(width: 10)
                        .ignoresSafeArea()

                    if let profile = currentProfile {
                        workspaceView(profile: profile)
                    } else {
                        entryView
                    }
                }
            }
            .navigationTitle(currentProfile == nil ? "Sổ Lab" : "Sổ • \(currentProfile!.username)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if currentProfile != nil {
                        Button("Đăng xuất") {
                            pulseHaptic()
                            activeUser = ""
                            UserDefaults.standard.set("", forKey: activeKey)
                            authPass = ""
                            authAlert = nil
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                LibraryImagePicker { img in
                    if let img = img {
                        let packed = shrinkImage(img)
                        draftPreview = packed.0
                        draftImageData = packed.1
                        draftNotice = "Đã tải ảnh lên khung xem trước."
                    }
                }
            }
            .onAppear {
                restoreState()
            }
        }
        .preferredColorScheme(darkTheme ? .dark : .light)
    }

    private var entryView: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.orange)
                    Text("Sổ Ghi Chép & Vòng Quay")
                        .font(.title2.bold())
                        .foregroundColor(inkPrimary)
                    Text(isSignUp ? "Tạo tài khoản thử nghiệm" : "Đăng nhập tài khoản thử nghiệm")
                        .font(.subheadline)
                        .foregroundColor(inkSecondary)
                }

                Picker("Chế độ", selection: $isSignUp) {
                    Text("Đăng nhập").tag(false)
                    Text("Đăng ký").tag(true)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    TextField("Tên đăng nhập", text: $authName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(inkPrimary)
                        .padding(12)
                        .background(fieldSurface)
                        .cornerRadius(10)

                    SecureField("Mật khẩu", text: $authPass)
                        .foregroundColor(inkPrimary)
                        .padding(12)
                        .background(fieldSurface)
                        .cornerRadius(10)

                    if isSignUp {
                        SecureField("Nhập lại mật khẩu", text: $authPassAgain)
                            .foregroundColor(inkPrimary)
                            .padding(12)
                            .background(fieldSurface)
                            .cornerRadius(10)
                    }

                    if let alert = authAlert {
                        Text(alert)
                            .font(.footnote.bold())
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: processAuth) {
                        Text(isSignUp ? "Tạo tài khoản" : "Vào sổ")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }
                .padding(14)
                .background(cardSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeTone, lineWidth: 1))
            }
            .padding(16)
        }
    }

    private func processAuth() {
        pulseHaptic()
        let name = authName.trimmingCharacters(in: .whitespacesAndNewlines)
        let pass = authPass

        if name.count < 3 {
            authAlert = "Tên đăng nhập ít nhất 3 ký tự."
            return
        }
        if pass.count < 4 {
            authAlert = "Mật khẩu ít nhất 4 ký tự."
            return
        }

        if isSignUp {
            if pass != authPassAgain {
                authAlert = "Mật khẩu nhập lại chưa khớp."
                return
            }
            if profiles.contains(where: { $0.username.caseInsensitiveCompare(name) == .orderedSame }) {
                authAlert = "Tên đăng nhập đã tồn tại."
                return
            }
            let created = MemberProfile(id: UUID(), username: name, password: pass, balance: 0, quanHuy: 0, kimCuong: 0, fv: 0)
            profiles.append(created)
            persistProfiles()
            activeUser = created.username
            UserDefaults.standard.set(created.username, forKey: activeKey)
            authAlert = nil
        } else {
            guard let matched = profiles.first(where: {
                $0.username.caseInsensitiveCompare(name) == .orderedSame && $0.password == pass
            }) else {
                authAlert = "Sai tên đăng nhập hoặc mật khẩu."
                return
            }
            activeUser = matched.username
            UserDefaults.standard.set(matched.username, forKey: activeKey)
            authAlert = nil
        }
    }

    private func workspaceView(profile: MemberProfile) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Số dư")
                            .font(.caption)
                            .foregroundColor(inkSecondary)
                        Text(formatVND(profile.balance))
                            .font(.headline.bold())
                            .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        statPill(tag: "QH", count: profile.quanHuy, color: .blue)
                        statPill(tag: "KC", count: profile.kimCuong, color: .teal)
                        statPill(tag: "FV", count: profile.fv, color: .orange)
                    }
                }
                .padding(12)
                .background(cardSurface)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(strokeTone, lineWidth: 1))

                ScrollView(.horizontal, showsIndicators: false) {
                    Picker("Trang", selection: $currentTab) {
                        Text("Màn chính").tag(0)
                        Text("Vòng quay").tag(1)
                        Text("Đăng bán").tag(2)
                        Text("Nạp tiền").tag(3)
                        Text("Cài đặt").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .frame(minWidth: 380)
                }
                .padding(4)
                .background(cardSurface)
                .cornerRadius(12)

                switch currentTab {
                case 0:
                    catalogSection
                case 1:
                    wheelSection
                case 2:
                    draftSection
                case 3:
                    walletSection
                default:
                    preferencesSection(profile: profile)
                }
            }
            .padding(14)
        }
    }

    private func statPill(tag: String, count: Int, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.caption.bold())
                .foregroundColor(color)
            Text(tag)
                .font(.caption2)
                .foregroundColor(inkSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(fieldSurface)
        .cornerRadius(8)
    }

    private var catalogSection: some View {
        let visible: [MarketItem]
        if let fg = filterGame {
            visible = items.filter { $0.game == fg }
        } else {
            visible = items
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Danh sách acc (\(visible.count))")
                    .font(.headline)
                    .foregroundColor(inkPrimary)
                Spacer()
                Button("+ Đăng bán") {
                    pulseHaptic()
                    currentTab = 2
                }
                .font(.subheadline.bold())
                .foregroundColor(.orange)
            }

            if !items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button("Tất cả") {
                            filterGame = nil
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(filterGame == nil ? Color.orange : cardSurface)
                        .foregroundColor(filterGame == nil ? .white : inkPrimary)
                        .cornerRadius(12)

                        ForEach(GameCategory.allCases) { g in
                            Button(g.rawValue) {
                                filterGame = g
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(filterGame == g ? Color.orange : cardSurface)
                            .foregroundColor(filterGame == g ? .white : inkPrimary)
                            .cornerRadius(12)
                        }
                    }
                }
            }

            if visible.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("Chưa có mục nào")
                        .font(.subheadline.bold())
                        .foregroundColor(inkPrimary)
                    Text("Vào mục Đăng bán để chọn ảnh và tạo mục thử nghiệm.")
                        .font(.caption)
                        .foregroundColor(inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(cardSurface)
                .cornerRadius(16)
            } else {
                ForEach(visible) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        if let data = item.imageData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: 220)
                                .background(fieldSurface)
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(fieldSurface)
                                .frame(height: 120)
                                .overlay(Text(item.game.rawValue).foregroundColor(inkSecondary))
                        }

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(inkPrimary)
                                Text("\(item.game.rawValue) • Đăng nhập: \(item.loginType.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(inkSecondary)
                            }
                            Spacer()
                            Text(formatVND(item.price))
                                .font(.headline.bold())
                                .foregroundColor(.orange)
                        }

                        HStack {
                            Text("Bởi \(item.owner)")
                                .font(.caption)
                                .foregroundColor(inkSecondary)
                            Spacer()
                            if item.owner.caseInsensitiveCompare(activeUser) == .orderedSame {
                                Button("Xóa") {
                                    pulseHaptic()
                                    items.removeAll { $0.id == item.id }
                                    persistItems()
                                }
                                .font(.caption.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.14))
                                .cornerRadius(12)
                            }
                            Button("Mua thử") {
                                pulseHaptic()
                                guard let idx = activeIndex else { return }
                                if profiles[idx].balance >= item.price {
                                    profiles[idx].balance -= item.price
                                    persistProfiles()
                                    items.removeAll { $0.id == item.id }
                                    persistItems()
                                }
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                    }
                    .padding(12)
                    .background(cardSurface)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeTone, lineWidth: 1))
                }
            }
        }
    }

    private func segmentColor(_ i: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.22, green: 0.42, blue: 0.78),
            Color(red: 0.16, green: 0.62, blue: 0.56),
            Color(red: 0.78, green: 0.42, blue: 0.16),
            Color(red: 0.42, green: 0.28, blue: 0.74),
            Color(red: 0.20, green: 0.54, blue: 0.86),
            Color(red: 0.74, green: 0.22, blue: 0.36)
        ]
        return colors[i % colors.count]
    }

    private var wheelSection: some View {
        let list = spinGame.rewards
        let step = 360.0 / Double(list.count)

        return VStack(spacing: 14) {
            VStack(spacing: 8) {
                ForEach(GameCategory.allCases) { g in
                    let selected = spinGame == g
                    Button(action: {
                        pulseHaptic()
                        spinGame = g
                        spinStatus = "Vòng \(g.rawValue) • \(formatVND(g.cost))/lượt"
                    }) {
                        HStack {
                            Text(g.rawValue)
                                .font(.subheadline.bold())
                                .foregroundColor(inkPrimary)
                            Spacer()
                            Text("\(formatVND(g.cost))/lượt")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(selected ? Color.orange : fieldSurface)
                                .foregroundColor(selected ? .white : inkPrimary)
                                .cornerRadius(10)
                        }
                        .padding(10)
                        .background(selected ? Color.orange.opacity(0.14) : fieldSurface)
                        .cornerRadius(12)
                    }
                    .disabled(isSpinning)
                }
            }

            ZStack {
                ZStack {
                    ForEach(0..<list.count, id: \.self) { i in
                        let a0 = -90.0 + Double(i) * step - step / 2.0
                        let a1 = a0 + step
                        let mid = (-90.0 + Double(i) * step) * Double.pi / 180.0
                        let rad: CGFloat = 74

                        WheelSegmentShape(startAngle: .degrees(a0), endAngle: .degrees(a1))
                            .fill(segmentColor(i))
                            .overlay(WheelSegmentShape(startAngle: .degrees(a0), endAngle: .degrees(a1)).stroke(Color.white.opacity(0.85), lineWidth: 1.5))

                        Text(list[i].label)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .offset(x: cos(mid) * rad, y: sin(mid) * rad)
                    }
                }
                .frame(width: 230, height: 230)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .rotationEffect(.degrees(spinAngle))

                Circle()
                    .fill(cardSurface)
                    .frame(width: 68, height: 68)
                    .overlay(Circle().stroke(Color.orange, lineWidth: 2))

                Text(spinGame.shortUnit)
                    .font(.caption.bold())
                    .foregroundColor(inkPrimary)
            }
            .overlay(alignment: .top) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .offset(y: -12)
            }
            .padding(.top, 10)

            Text(spinStatus)
                .font(.subheadline.bold())
                .foregroundColor(inkPrimary)
                .multilineTextAlignment(.center)

            Button(action: triggerSpin) {
                Text(isSpinning ? "Đang quay..." : "Quay \(spinGame.rawValue) (-\(formatVND(spinGame.cost)))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isSpinning ? Color.orange.opacity(0.6) : Color.orange)
                    .cornerRadius(12)
            }
            .disabled(isSpinning)
        }
        .padding(14)
        .background(cardSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeTone, lineWidth: 1))
    }

    private func triggerSpin() {
        guard let idx = activeIndex, !isSpinning else { return }
        pulseHaptic()

        let cost = spinGame.cost
        if profiles[idx].balance < cost {
            spinStatus = "Không đủ số dư (\(formatVND(cost))). Qua mục Nạp tiền."
            return
        }

        profiles[idx].balance -= cost
        persistProfiles()

        let pool = spinGame.rewards
        let totalW = pool.reduce(0) { $0 + $1.weight }
        let roll = Int.random(in: 1...max(1, totalW))
        var sum = 0
        var chosenIdx = 0
        for (i, r) in pool.enumerated() {
            sum += r.weight
            if roll <= sum {
                chosenIdx = i
                break
            }
        }
        let chosen = pool[chosenIdx]

        let step = 360.0 / Double(pool.count)
        let targetDeg = Double(chosenIdx) * step
        let curMod = spinAngle.truncatingRemainder(dividingBy: 360.0)
        var diff = ((360.0 - targetDeg).truncatingRemainder(dividingBy: 360.0)) - curMod
        if diff < 0 { diff += 360.0 }
        let spinTotal = 1800.0 + diff + Double.random(in: -step * 0.2 ... step * 0.2)

        isSpinning = true
        spinStatus = "Đang quay \(spinGame.rawValue)..."

        withAnimation(.timingCurve(0.14, 0.88, 0.25, 1.0, duration: 2.2)) {
            spinAngle += spinTotal
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
            guard let uIdx = activeIndex else {
                isSpinning = false
                return
            }
            switch spinGame {
            case .lienQuan: profiles[uIdx].quanHuy += chosen.amount
            case .freeFire: profiles[uIdx].kimCuong += chosen.amount
            case .fcMobile: profiles[uIdx].fv += chosen.amount
            }
            persistProfiles()
            pulseHaptic()
            spinStatus = "Trúng \(chosen.label)!"
            isSpinning = false
        }
    }

    private var draftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tạo mục thử nghiệm")
                .font(.headline)
                .foregroundColor(inkPrimary)

            Picker("Danh mục", selection: $draftGame) {
                ForEach(GameCategory.allCases) { g in
                    Text(g.rawValue).tag(g)
                }
            }
            .pickerStyle(.segmented)

            TextField("Tiêu đề / ghi chú", text: $draftTitle)
                .foregroundColor(inkPrimary)
                .padding(12)
                .background(fieldSurface)
                .cornerRadius(10)

            TextField("Mức giá (vd: 100000)", text: $draftPrice)
                .keyboardType(.numberPad)
                .foregroundColor(inkPrimary)
                .padding(12)
                .background(fieldSurface)
                .cornerRadius(10)

            Picker("Kiểu đăng nhập", selection: $draftLogin) {
                ForEach(LoginType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)

            Button(action: {
                pulseHaptic()
                showPicker = true
            }) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(draftPreview == nil ? "Chọn ảnh từ thư viện" : "Đổi ảnh khác")
                }
                .font(.subheadline.bold())
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(fieldSurface)
                .cornerRadius(10)
            }

            if let img = draftPreview {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 190)
                    .background(fieldSurface)
                    .cornerRadius(12)
            }

            if let msg = draftNotice {
                Text(msg)
                    .font(.caption.bold())
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }

            Button(action: saveDraft) {
                Text("Lưu lên màn chính")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
        }
        .padding(14)
        .background(cardSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeTone, lineWidth: 1))
    }

    private func shrinkImage(_ img: UIImage) -> (UIImage, Data?) {
        let maxSide: CGFloat = 800
        let s = img.size
        let ratio = min(maxSide / max(s.width, 1), maxSide / max(s.height, 1), 1.0)
        let target = CGSize(width: max(1, s.width * ratio), height: max(1, s.height * ratio))
        let renderer = UIGraphicsImageRenderer(size: target)
        let small = renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: target))
        }
        let data = small.jpegData(compressionQuality: 0.65)
        let outImg = data.flatMap { UIImage(data: $0) } ?? small
        return (outImg, data)
    }

    private func saveDraft() {
        pulseHaptic()
        guard let p = currentProfile else { return }
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let price = Int(draftPrice.filter { $0.isNumber }) ?? 0
        if title.isEmpty {
            draftNotice = "Nhập tiêu đề trước."
            return
        }
        if price <= 0 {
            draftNotice = "Nhập mức giá hợp lệ."
            return
        }

        let item = MarketItem(
            id: UUID(),
            owner: p.username,
            game: draftGame,
            title: title,
            price: price,
            loginType: draftLogin,
            imageData: draftImageData
        )
        items.insert(item, at: 0)
        persistItems()
        filterGame = nil
        draftTitle = ""
        draftPrice = ""
        draftPreview = nil
        draftImageData = nil
        draftNotice = nil
        currentTab = 0
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nạp tiền chuyển khoản")
                .font(.headline)
                .foregroundColor(inkPrimary)

            Text("Chọn mệnh giá hoặc nhập số tiền muốn nạp, sau đó mở bảng thông tin chuyển khoản.")
                .font(.caption)
                .foregroundColor(inkSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(topUpPresets, id: \.self) { amt in
                    let active = effectiveTopUpAmount == amt && customTopUpInput.isEmpty
                    Button(action: {
                        pulseHaptic()
                        selectedTopUpAmount = amt
                        customTopUpInput = ""
                        showTransferCard = true
                        walletNotice = "Đã chọn mức nạp \(formatVND(amt))."
                    }) {
                        Text(formatVND(amt))
                            .font(.subheadline.bold())
                            .foregroundColor(active ? .white : inkPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(active ? Color.orange : fieldSurface)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(active ? Color.orange : strokeTone, lineWidth: 1))
                    }
                }
            }

            TextField("Hoặc nhập số tiền khác (vd: 150000)", text: $customTopUpInput)
                .keyboardType(.numberPad)
                .foregroundColor(inkPrimary)
                .padding(12)
                .background(fieldSurface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(strokeTone, lineWidth: 1))
                .onChange(of: customTopUpInput) { _ in
                    if effectiveTopUpAmount > 0 {
                        showTransferCard = true
                    }
                }

            Button(action: {
                pulseHaptic()
                if effectiveTopUpAmount <= 0 {
                    walletNotice = "Vui lòng chọn hoặc nhập số tiền hợp lệ."
                    return
                }
                showTransferCard = true
            }) {
                Text("Hiện thông tin chuyển khoản (\(formatVND(effectiveTopUpAmount)))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.orange)
                    .cornerRadius(12)
            }

            if showTransferCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Thông tin chuyển khoản")
                            .font(.subheadline.bold())
                            .foregroundColor(inkPrimary)
                        Spacer()
                        Button("Ẩn") {
                            showTransferCard = false
                        }
                        .font(.caption.bold())
                        .foregroundColor(inkSecondary)
                    }

                    transferInfoRow(title: "Ngân hàng", value: adminBankName, copyValue: adminBankName, tag: "tên ngân hàng")
                    transferInfoRow(title: "Số tài khoản", value: adminAccountNumber, copyValue: adminAccountNumber, tag: "số tài khoản")
                    transferInfoRow(title: "Chủ tài khoản", value: adminAccountHolder, copyValue: adminAccountHolder, tag: "chủ tài khoản")
                    transferInfoRow(title: "Số tiền", value: formatVND(effectiveTopUpAmount), copyValue: "\(effectiveTopUpAmount)", tag: "số tiền")
                    transferInfoRow(title: "Nội dung CK", value: transferMemo, copyValue: transferMemo, tag: "nội dung chuyển khoản")

                    Button(action: {
                        pulseHaptic()
                        guard let idx = activeIndex else { return }
                        let addAmt = effectiveTopUpAmount
                        guard addAmt > 0 else { return }
                        profiles[idx].balance += addAmt
                        persistProfiles()
                        walletNotice = "Đã xác nhận cộng +\(formatVND(addAmt)) vào số dư."
                    }) {
                        Text("Xác nhận đã chuyển (Cộng số dư test)")
                            .font(.subheadline.bold())
                            .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(red: 0.16, green: 0.78, blue: 0.44).opacity(0.14))
                            .cornerRadius(10)
                    }
                }
                .padding(12)
                .background(fieldSurface)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.5), lineWidth: 1))
            }

            if let msg = walletNotice {
                Text(msg)
                    .font(.caption.bold())
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }
        }
        .padding(14)
        .background(cardSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeTone, lineWidth: 1))
    }

    private func transferInfoRow(title: String, value: String, copyValue: String, tag: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(inkSecondary)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(inkPrimary)
            }
            Spacer()
            Button(action: {
                copyToClipboard(copyValue, label: tag)
            }) {
                Text("Sao chép")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(cardSurface)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeTone, lineWidth: 1))
            }
        }
        .padding(8)
        .background(cardSurface.opacity(0.7))
        .cornerRadius(10)
    }

    private func preferencesSection(profile: MemberProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cài đặt")
                .font(.headline)
                .foregroundColor(inkPrimary)

            Picker("Nền", selection: $darkTheme) {
                Text("Nền đen").tag(true)
                Text("Nền trắng").tag(false)
            }
            .pickerStyle(.segmented)
            .onChange(of: darkTheme) { val in
                pulseHaptic()
                UserDefaults.standard.set(val, forKey: darkKey)
                prefNotice = val ? "Đã bật nền đen." : "Đã bật nền trắng."
            }

            Toggle("Rung phản hồi", isOn: $enableHaptic)
                .tint(.orange)
                .foregroundColor(inkPrimary)
                .onChange(of: enableHaptic) { val in
                    UserDefaults.standard.set(val, forKey: hapticKey)
                }

            Text("Tài khoản: \(profile.username) • Số mục lưu: \(items.count)")
                .font(.caption)
                .foregroundColor(inkSecondary)

            Button(action: {
                pulseHaptic()
                items.removeAll()
                persistItems()
                prefNotice = "Đã xóa toàn bộ mục lưu."
            }) {
                Text("Xóa toàn bộ mục lưu")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red.opacity(0.14))
                    .cornerRadius(10)
            }

            if let msg = prefNotice {
                Text(msg)
                    .font(.caption.bold())
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }
        }
        .padding(14)
        .background(cardSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeTone, lineWidth: 1))
    }

    private func formatVND(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return "\(formatter.string(from: NSNumber(value: value)) ?? "\(value)")đ"
    }

    private func restoreState() {
        if let d = UserDefaults.standard.data(forKey: profilesKey),
           let dec = try? JSONDecoder().decode([MemberProfile].self, from: d) {
            profiles = dec
        }
        activeUser = UserDefaults.standard.string(forKey: activeKey) ?? ""
        if let d = UserDefaults.standard.data(forKey: itemsKey),
           let dec = try? JSONDecoder().decode([MarketItem].self, from: d) {
            items = dec
        }
        if UserDefaults.standard.object(forKey: darkKey) != nil {
            darkTheme = UserDefaults.standard.bool(forKey: darkKey)
        }
        if UserDefaults.standard.object(forKey: hapticKey) != nil {
            enableHaptic = UserDefaults.standard.bool(forKey: hapticKey)
        }
    }

    private func persistProfiles() {
        if let enc = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(enc, forKey: profilesKey)
        }
    }

    private func persistItems() {
        if let enc = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(enc, forKey: itemsKey)
        }
    }
}
