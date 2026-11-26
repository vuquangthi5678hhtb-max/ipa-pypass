import SwiftUI
import PhotosUI
import UIKit

struct RewardOption: Identifiable, Codable {
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

enum GamePlatform: String, CaseIterable, Identifiable, Codable {
    case lienQuan = "Liên Quân"
    case freeFire = "Free Fire"
    case fcMobile = "FC Mobile"

    var id: String { rawValue }

    var currencyName: String {
        switch self {
        case .lienQuan: return "Quân Huy"
        case .freeFire: return "Kim Cương"
        case .fcMobile: return "FV"
        }
    }

    var spinCost: Int {
        switch self {
        case .lienQuan: return 10_000
        case .freeFire: return 15_000
        case .fcMobile: return 20_000
        }
    }

    var rewards: [RewardOption] {
        switch self {
        case .lienQuan:
            return [
                RewardOption(label: "60 QH", amount: 60, weight: 32),
                RewardOption(label: "150 QH", amount: 150, weight: 28),
                RewardOption(label: "300 QH", amount: 300, weight: 20),
                RewardOption(label: "650 QH", amount: 650, weight: 12),
                RewardOption(label: "1.200 QH", amount: 1200, weight: 6),
                RewardOption(label: "2.500 QH", amount: 2500, weight: 2)
            ]
        case .freeFire:
            return [
                RewardOption(label: "70 KC", amount: 70, weight: 32),
                RewardOption(label: "140 KC", amount: 140, weight: 28),
                RewardOption(label: "290 KC", amount: 290, weight: 20),
                RewardOption(label: "580 KC", amount: 580, weight: 12),
                RewardOption(label: "1.150 KC", amount: 1150, weight: 6),
                RewardOption(label: "2.200 KC", amount: 2200, weight: 2)
            ]
        case .fcMobile:
            return [
                RewardOption(label: "100 FV", amount: 100, weight: 32),
                RewardOption(label: "200 FV", amount: 200, weight: 28),
                RewardOption(label: "450 FV", amount: 450, weight: 20),
                RewardOption(label: "950 FV", amount: 950, weight: 12),
                RewardOption(label: "1.800 FV", amount: 1800, weight: 6),
                RewardOption(label: "3.500 FV", amount: 3500, weight: 2)
            ]
        }
    }
}

enum LoginMethod: String, CaseIterable, Identifiable, Codable {
    case facebook = "Facebook"
    case google = "Google"
    case account = "Tài khoản"

    var id: String { rawValue }
}

enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case dark = "Nền đen"
    case light = "Nền trắng"

    var id: String { rawValue }
}

enum AccentChoice: String, CaseIterable, Identifiable, Codable {
    case orange = "Cam"
    case blue = "Xanh dương"
    case mint = "Xanh ngọc"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .orange: return .orange
        case .blue: return Color(red: 0.25, green: 0.58, blue: 1.0)
        case .mint: return Color(red: 0.14, green: 0.78, blue: 0.62)
        }
    }
}

struct NotebookSettings: Codable {
    var themeMode: ThemeMode = .dark
    var accentChoice: AccentChoice = .orange
    var showGreetingBanner: Bool = true
    var hapticEnabled: Bool = true
    var showRewardList: Bool = true
}

struct UserAccount: Codable, Identifiable {
    let id: UUID
    let username: String
    let password: String
    var balance: Int
    var quanHuy: Int
    var kimCuong: Int
    var fv: Int
}

struct AccountListing: Identifiable, Codable {
    let id: UUID
    let sellerName: String
    let platform: GamePlatform
    let title: String
    let price: Int
    let loginMethod: LoginMethod
    let imageData: Data?
    let createdAt: Date
}

struct WheelSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

struct ContentView: View {
    private let accountsKey = "notebook_shop_accounts_v2"
    private let currentUserKey = "notebook_shop_current_user_v2"
    private let listingsKey = "notebook_shop_listings_v2"
    private let settingsKey = "notebook_shop_settings_v1"

    @State private var accounts: [UserAccount] = []
    @State private var activeUsername: String = ""
    @State private var listings: [AccountListing] = []
    @State private var settings: NotebookSettings = NotebookSettings()

    @State private var isRegisterTab = false
    @State private var authUsername = ""
    @State private var authPassword = ""
    @State private var authConfirmPassword = ""
    @State private var authErrorMessage: String?

    @State private var selectedSection = 0
    @State private var showNotice = true

    @State private var selectedPlatform: GamePlatform = .lienQuan
    @State private var wheelAngle: Double = 0
    @State private var isSpinning = false
    @State private var lastSpinResult = "Chọn vòng quay và kiểm tra giá lượt trước khi quay"

    @State private var newPlatform: GamePlatform = .lienQuan
    @State private var newTitle = ""
    @State private var newPriceText = ""
    @State private var newLoginMethod: LoginMethod = .facebook
    @State private var selectedListingPhoto: PhotosPickerItem?
    @State private var newImageData: Data?
    @State private var postMessage: String?

    private let topUpAmounts = [10_000, 20_000, 50_000, 100_000, 200_000, 500_000]
    @State private var topUpNotice: String?

    @State private var settingsNotice: String?
    @State private var filterPlatform: GamePlatform? = nil

    private var isDark: Bool {
        settings.themeMode == .dark
    }

    private var accent: Color {
        settings.accentChoice.color
    }

    private var pageBgTop: Color {
        isDark ? Color(red: 0.06, green: 0.07, blue: 0.09) : Color(red: 0.99, green: 0.98, blue: 0.96)
    }

    private var pageBgBottom: Color {
        isDark ? Color(red: 0.10, green: 0.11, blue: 0.15) : Color(red: 0.95, green: 0.94, blue: 0.91)
    }

    private var cardBg: Color {
        isDark ? Color(red: 0.14, green: 0.16, blue: 0.21) : Color.white
    }

    private var inputBg: Color {
        isDark ? Color(red: 0.09, green: 0.10, blue: 0.14) : Color(red: 0.97, green: 0.97, blue: 0.96)
    }

    private var primaryText: Color {
        isDark ? .white : Color(red: 0.12, green: 0.12, blue: 0.14)
    }

    private var secondaryText: Color {
        isDark ? Color.white.opacity(0.72) : Color(red: 0.42, green: 0.42, blue: 0.46)
    }

    private var borderTone: Color {
        isDark ? Color.white.opacity(0.11) : Color.black.opacity(0.12)
    }

    private var spineColor: Color {
        isDark ? Color(red: 0.18, green: 0.16, blue: 0.15) : Color(red: 0.20, green: 0.20, blue: 0.22)
    }

    private var currentUserIndex: Int? {
        accounts.firstIndex { $0.username.caseInsensitiveCompare(activeUsername) == .orderedSame }
    }

    private var currentUser: UserAccount? {
        guard let idx = currentUserIndex else { return nil }
        return accounts[idx]
    }

    private var filteredListings: [AccountListing] {
        guard let fp = filterPlatform else { return listings }
        return listings.filter { $0.platform == fp }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                notebookBackground

                if let user = currentUser {
                    mainNotebookContent(user: user)
                } else {
                    authNotebookView
                }
            }
            .navigationTitle(currentUser == nil ? "Sổ Acc & Vòng Quay" : "Sổ Shop • \(currentUser!.username)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if currentUser != nil {
                        Button("Đăng xuất") {
                            triggerHaptic()
                            activeUsername = ""
                            UserDefaults.standard.set("", forKey: currentUserKey)
                            authUsername = ""
                            authPassword = ""
                            authConfirmPassword = ""
                            authErrorMessage = nil
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(accent)
                    }
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
    }

    private var notebookBackground: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                gradient: Gradient(colors: [pageBgTop, pageBgBottom]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(spineColor)
                .frame(width: 12)
                .ignoresSafeArea()

            Rectangle()
                .fill(accent.opacity(0.28))
                .frame(width: 1.5)
                .padding(.leading, 30)
                .ignoresSafeArea()
        }
    }

    private var authNotebookView: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 40))
                        .foregroundColor(accent)

                    Text("Sổ Quản Lý Acc & Vòng Quay")
                        .font(.title2.bold())
                        .foregroundColor(primaryText)

                    Text(isRegisterTab ? "Tạo tài khoản mới để lưu số dư & tin đăng" : "Đăng nhập bằng tài khoản đã tạo")
                        .font(.subheadline)
                        .foregroundColor(secondaryText)
                }
                .padding(.top, 12)

                Picker("Chế độ", selection: $isRegisterTab) {
                    Text("Đăng nhập").tag(false)
                    Text("Tạo tài khoản").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(cardBg)
                .cornerRadius(12)

                VStack(spacing: 14) {
                    TextField("Tên tài khoản", text: $authUsername)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(primaryText)
                        .padding(14)
                        .background(inputBg)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderTone, lineWidth: 1)
                        )

                    SecureField("Mật khẩu", text: $authPassword)
                        .foregroundColor(primaryText)
                        .padding(14)
                        .background(inputBg)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderTone, lineWidth: 1)
                        )

                    if isRegisterTab {
                        SecureField("Nhập lại mật khẩu", text: $authConfirmPassword)
                            .foregroundColor(primaryText)
                            .padding(14)
                            .background(inputBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderTone, lineWidth: 1)
                            )
                    }

                    if let err = authErrorMessage {
                        Text(err)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: handleAuthSubmit) {
                        Text(isRegisterTab ? "Tạo tài khoản & Vào sổ" : "Đăng nhập")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(accent)
                            .cornerRadius(14)
                    }
                }
                .padding(16)
                .background(cardBg)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderTone, lineWidth: 1)
                )
            }
            .padding(.leading, 24)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
    }

    private func handleAuthSubmit() {
        triggerHaptic()
        let cleanUser = authUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPass = authPassword

        if cleanUser.count < 3 {
            authErrorMessage = "Tên tài khoản cần ít nhất 3 ký tự."
            return
        }
        if cleanPass.count < 4 {
            authErrorMessage = "Mật khẩu cần ít nhất 4 ký tự."
            return
        }

        if isRegisterTab {
            if cleanPass != authConfirmPassword {
                authErrorMessage = "Mật khẩu nhập lại chưa khớp."
                return
            }
            let exists = accounts.contains { $0.username.caseInsensitiveCompare(cleanUser) == .orderedSame }
            if exists {
                authErrorMessage = "Tên tài khoản này đã tồn tại."
                return
            }
            let created = UserAccount(
                id: UUID(),
                username: cleanUser,
                password: cleanPass,
                balance: 0,
                quanHuy: 0,
                kimCuong: 0,
                fv: 0
            )
            accounts.append(created)
            saveAccounts()
            activeUsername = created.username
            UserDefaults.standard.set(created.username, forKey: currentUserKey)
            authErrorMessage = nil
        } else {
            guard let matched = accounts.first(where: {
                $0.username.caseInsensitiveCompare(cleanUser) == .orderedSame && $0.password == cleanPass
            }) else {
                authErrorMessage = "Sai tên tài khoản hoặc mật khẩu. Hãy tạo tài khoản trước nếu chưa có."
                return
            }
            activeUsername = matched.username
            UserDefaults.standard.set(matched.username, forKey: currentUserKey)
            authErrorMessage = nil
        }
    }

    private func mainNotebookContent(user: UserAccount) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if settings.showGreetingBanner && showNotice {
                    HStack(spacing: 10) {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(accent)

                        Text("Chào \(user.username) • Số dư hiện tại: \(formatVND(user.balance))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(primaryText)

                        Spacer()

                        Button(action: {
                            showNotice = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.footnote.bold())
                                .foregroundColor(secondaryText)
                                .frame(width: 28, height: 28)
                                .background(inputBg)
                                .clipShape(Circle())
                        }
                    }
                    .padding(12)
                    .background(cardBg)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderTone, lineWidth: 1)
                    )
                }

                walletSummaryCard(user: user)

                ScrollView(.horizontal, showsIndicators: false) {
                    Picker("Trang sổ", selection: $selectedSection) {
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
                .background(cardBg)
                .cornerRadius(12)

                switch selectedSection {
                case 0:
                    homeListingsView
                case 1:
                    wheelSpinView(user: user)
                case 2:
                    createListingView
                case 3:
                    topUpView
                default:
                    settingsView(user: user)
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
    }

    private func walletSummaryCard(user: UserAccount) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Số dư tài khoản")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(secondaryText)
                Spacer()
                Text(formatVND(user.balance))
                    .font(.headline.bold())
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }

            Divider()
                .background(borderTone)

            HStack(spacing: 8) {
                resourcePill(label: "Quân Huy", value: "\(user.quanHuy)", tint: Color(red: 0.32, green: 0.65, blue: 1.0))
                resourcePill(label: "Kim Cương", value: "\(user.kimCuong)", tint: Color(red: 0.20, green: 0.82, blue: 0.78))
                resourcePill(label: "FV", value: "\(user.fv)", tint: accent)
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderTone, lineWidth: 1)
        )
    }

    private func resourcePill(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(tint)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(inputBg)
        .cornerRadius(10)
    }

    private var homeListingsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Acc đang rao bán (\(filteredListings.count))")
                    .font(.headline)
                    .foregroundColor(primaryText)
                Spacer()
                Button("+ Đăng bán") {
                    triggerHaptic()
                    selectedSection = 2
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(accent)
            }

            if !listings.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "Tất cả", target: nil)
                        ForEach(GamePlatform.allCases) { p in
                            filterChip(title: p.rawValue, target: p)
                        }
                    }
                }
            }

            if filteredListings.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.largeTitle)
                        .foregroundColor(accent.opacity(0.85))
                    Text("Chưa có tin đăng acc nào")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(primaryText)
                    Text("Chuyển sang mục Đăng bán để chọn ảnh acc, nhập giá và cách đăng nhập.")
                        .font(.caption)
                        .foregroundColor(secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(cardBg)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderTone, lineWidth: 1)
                )
            } else {
                ForEach(filteredListings) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        if let data = item.imageData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 190)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(inputBg)
                                .frame(height: 140)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.title2)
                                            .foregroundColor(accent)
                                        Text(item.platform.rawValue)
                                            .font(.caption.bold())
                                            .foregroundColor(primaryText.opacity(0.85))
                                    }
                                )
                        }

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(primaryText)

                                HStack(spacing: 8) {
                                    Text(item.platform.rawValue)
                                        .font(.caption.bold())
                                        .foregroundColor(primaryText)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(inputBg)
                                        .cornerRadius(10)

                                    Text("Đăng nhập: \(item.loginMethod.rawValue)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color(red: 0.35, green: 0.68, blue: 1.0))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.16))
                                        .cornerRadius(10)
                                }
                            }

                            Spacer()

                            Text(formatVND(item.price))
                                .font(.headline.bold())
                                .foregroundColor(accent)
                        }

                        HStack {
                            Text("Người đăng: \(item.sellerName)")
                                .font(.caption)
                                .foregroundColor(secondaryText)

                            Spacer()

                            if item.sellerName.caseInsensitiveCompare(activeUsername) == .orderedSame {
                                Button("Xóa tin") {
                                    deleteListing(item)
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.16))
                                .foregroundColor(.red)
                                .cornerRadius(16)
                            }

                            Button("Mua thử") {
                                buyListing(item)
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(accent)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding(14)
                    .background(cardBg)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderTone, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func filterChip(title: String, target: GamePlatform?) -> some View {
        let active = filterPlatform == target
        return Button(action: {
            triggerHaptic()
            filterPlatform = target
        }) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(active ? accent : cardBg)
                .foregroundColor(active ? .white : primaryText)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(active ? accent : borderTone, lineWidth: 1)
                )
        }
    }

    private func deleteListing(_ item: AccountListing) {
        triggerHaptic()
        listings.removeAll { $0.id == item.id }
        saveListings()
    }

    private func buyListing(_ item: AccountListing) {
        triggerHaptic()
        guard let idx = currentUserIndex else { return }
        if accounts[idx].balance >= item.price {
            accounts[idx].balance -= item.price
            saveAccounts()
            listings.removeAll { $0.id == item.id }
            saveListings()
        } else {
            showNotice = true
        }
    }

    private func sliceColor(index: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.22, green: 0.42, blue: 0.78),
            Color(red: 0.16, green: 0.62, blue: 0.56),
            Color(red: 0.78, green: 0.42, blue: 0.16),
            Color(red: 0.42, green: 0.28, blue: 0.74),
            Color(red: 0.20, green: 0.54, blue: 0.86),
            Color(red: 0.74, green: 0.22, blue: 0.36)
        ]
        return palette[index % palette.count]
    }

    private func wheelSpinView(user: UserAccount) -> some View {
        let pool = selectedPlatform.rewards
        let sliceCount = pool.count
        let sliceDeg = 360.0 / Double(sliceCount)

        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Chọn vòng quay theo nền tảng")
                    .font(.headline)
                    .foregroundColor(primaryText)

                VStack(spacing: 8) {
                    ForEach(GamePlatform.allCases) { platform in
                        let isSelected = selectedPlatform == platform
                        Button(action: {
                            triggerHaptic()
                            selectedPlatform = platform
                            lastSpinResult = "Vòng \(platform.rawValue) • Giá \(formatVND(platform.spinCost))/lượt"
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(platform.rawValue)
                                        .font(.subheadline.bold())
                                        .foregroundColor(primaryText)
                                    Text("Thưởng: \(platform.currencyName)")
                                        .font(.caption)
                                        .foregroundColor(secondaryText)
                                }

                                Spacer()

                                Text("\(formatVND(platform.spinCost)) / lượt")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? accent : inputBg)
                                    .foregroundColor(isSelected ? .white : primaryText)
                                    .cornerRadius(14)
                            }
                            .padding(12)
                            .background(isSelected ? accent.opacity(0.14) : inputBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? accent : borderTone, lineWidth: isSelected ? 1.5 : 1)
                            )
                        }
                        .disabled(isSpinning)
                    }
                }

                HStack {
                    Text("Giá vòng đang chọn: \(formatVND(selectedPlatform.spinCost))")
                        .font(.footnote.bold())
                        .foregroundColor(accent)
                    Spacer()
                    Text("Số dư: \(formatVND(user.balance))")
                        .font(.footnote.bold())
                        .foregroundColor(user.balance >= selectedPlatform.spinCost ? Color(red: 0.16, green: 0.78, blue: 0.44) : .red)
                }
            }
            .padding(14)
            .background(cardBg)
            .cornerRadius(16)

            VStack(spacing: 10) {
                ZStack {
                    ZStack {
                        ForEach(0..<sliceCount, id: \.self) { idx in
                            let startDeg = -90.0 + Double(idx) * sliceDeg - sliceDeg / 2.0
                            let endDeg = startDeg + sliceDeg
                            let midRad = (-90.0 + Double(idx) * sliceDeg) * Double.pi / 180.0
                            let labelR: CGFloat = 76

                            WheelSliceShape(
                                startAngle: .degrees(startDeg),
                                endAngle: .degrees(endDeg)
                            )
                            .fill(sliceColor(index: idx))
                            .overlay(
                                WheelSliceShape(
                                    startAngle: .degrees(startDeg),
                                    endAngle: .degrees(endDeg)
                                )
                                .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                            )

                            Text(pool[idx].label)
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.55), radius: 1.5, x: 0, y: 1)
                                .offset(
                                    x: cos(midRad) * labelR,
                                    y: sin(midRad) * labelR
                                )
                        }
                    }
                    .frame(width: 240, height: 240)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(color: Color.black.opacity(0.35), radius: 10)
                    .rotationEffect(.degrees(wheelAngle))

                    Circle()
                        .fill(cardBg)
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(accent, lineWidth: 2.5))
                        .shadow(radius: 4)

                    VStack(spacing: 1) {
                        Text(selectedPlatform.rawValue)
                            .font(.caption2.bold())
                        Text(formatVND(selectedPlatform.spinCost))
                            .font(.caption2)
                            .foregroundColor(secondaryText)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(primaryText)
                }
                .overlay(alignment: .top) {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.title)
                        .foregroundColor(.red)
                        .shadow(color: Color.black.opacity(0.45), radius: 2, x: 0, y: 2)
                        .offset(y: -14)
                }
                .padding(.top, 14)
                .padding(.bottom, 6)

                Text(lastSpinResult)
                    .font(.subheadline.bold())
                    .foregroundColor(primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            if settings.showRewardList {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mốc thưởng & tỉ lệ \(selectedPlatform.rawValue)")
                        .font(.caption.bold())
                        .foregroundColor(secondaryText)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(pool) { opt in
                            HStack {
                                Text(opt.label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(primaryText)
                                Spacer()
                                Text("\(opt.weight)%")
                                    .font(.caption2.bold())
                                    .foregroundColor(accent)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(inputBg)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(12)
                .background(inputBg.opacity(0.65))
                .cornerRadius(14)
            }

            Button(action: spinWheel) {
                Text(isSpinning ? "Đang quay vòng..." : "Quay \(selectedPlatform.rawValue) (-\(formatVND(selectedPlatform.spinCost)))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isSpinning ? accent.opacity(0.65) : accent)
                    .cornerRadius(14)
            }
            .disabled(isSpinning)
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderTone, lineWidth: 1)
        )
    }

    private func pickWeightedIndex(from pool: [RewardOption]) -> Int {
        let totalWeight = pool.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        let roll = Int.random(in: 1...totalWeight)
        var running = 0
        for (idx, item) in pool.enumerated() {
            running += item.weight
            if roll <= running {
                return idx
            }
        }
        return pool.count - 1
    }

    private func spinWheel() {
        guard let idx = currentUserIndex, !isSpinning else { return }
        triggerHaptic()

        let cost = selectedPlatform.spinCost
        let currentBalance = accounts[idx].balance

        if currentBalance < cost {
            let missingAmount = cost - currentBalance
            lastSpinResult = "Số dư chưa đủ \(formatVND(cost)) (còn thiếu \(formatVND(missingAmount))). Hãy qua mục Nạp tiền."
            return
        }

        accounts[idx].balance -= cost
        saveAccounts()

        isSpinning = true
        lastSpinResult = "Đã trừ \(formatVND(cost)) • Đang quay \(selectedPlatform.rawValue)..."

        let rewardPool = selectedPlatform.rewards
        let pickedIndex = pickWeightedIndex(from: rewardPool)
        let picked = rewardPool[pickedIndex]

        let sliceAngle = 360.0 / Double(rewardPool.count)
        let targetSliceCenter = Double(pickedIndex) * sliceAngle
        let currentMod = wheelAngle.truncatingRemainder(dividingBy: 360.0)
        let desiredMod = (360.0 - targetSliceCenter).truncatingRemainder(dividingBy: 360.0)
        var deltaToTarget = desiredMod - currentMod
        if deltaToTarget < 0 {
            deltaToTarget += 360.0
        }
        let extraSpins = 360.0 * 5.0
        let jitter = Double.random(in: -sliceAngle * 0.22 ... sliceAngle * 0.22)
        let totalDelta = extraSpins + deltaToTarget + jitter

        withAnimation(.timingCurve(0.14, 0.88, 0.25, 1.0, duration: 2.4)) {
            wheelAngle += totalDelta
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.45) {
            guard let userIdx = currentUserIndex else {
                isSpinning = false
                return
            }

            switch selectedPlatform {
            case .lienQuan:
                accounts[userIdx].quanHuy += picked.amount
            case .freeFire:
                accounts[userIdx].kimCuong += picked.amount
            case .fcMobile:
                accounts[userIdx].fv += picked.amount
            }

            saveAccounts()
            triggerHaptic()
            lastSpinResult = "Nổ \(picked.label) (\(selectedPlatform.rawValue))!"
            isSpinning = false
        }
    }

    private var createListingView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Đăng tin bán acc lên màn hình chính")
                .font(.headline)
                .foregroundColor(primaryText)

            Picker("Nền tảng", selection: $newPlatform) {
                ForEach(GamePlatform.allCases) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
            .pickerStyle(.segmented)

            TextField("Tên / mô tả acc (vd: Acc rank cao, nhiều skin)", text: $newTitle)
                .foregroundColor(primaryText)
                .padding(12)
                .background(inputBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderTone, lineWidth: 1)
                )

            TextField("Giá tiền cần bán (vd: 150000)", text: $newPriceText)
                .keyboardType(.numberPad)
                .foregroundColor(primaryText)
                .padding(12)
                .background(inputBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderTone, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Cách thức đăng nhập")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(primaryText)

                Picker("Cách đăng nhập", selection: $newLoginMethod) {
                    ForEach(LoginMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)
            }

            PhotosPicker(selection: $selectedListingPhoto, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(newImageData == nil ? "Chọn ảnh acc từ thư viện" : "Đổi ảnh acc khác")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(inputBg)
                .foregroundColor(accent)
                .cornerRadius(12)
            }

            Button(action: loadPickedImage) {
                Text(selectedListingPhoto == nil ? "Tải ảnh đã chọn vào bài đăng" : "Xác nhận ảnh acc đã chọn")
                    .font(.footnote.bold())
                    .foregroundColor(accent)
            }

            if let data = newImageData, let previewImg = UIImage(data: data) {
                Image(uiImage: previewImg)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 165)
                    .clipped()
                    .cornerRadius(12)
            }

            if let msg = postMessage {
                Text(msg)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }

            Button(action: submitListing) {
                Text("Đăng lên màn hình chính")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(accent)
                    .cornerRadius(14)
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderTone, lineWidth: 1)
        )
    }

    private func loadPickedImage() {
        triggerHaptic()
        guard let item = selectedListingPhoto else {
            postMessage = "Hãy bấm 'Chọn ảnh acc từ thư viện' trước."
            return
        }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    DispatchQueue.main.async {
                        self.newImageData = data
                        self.postMessage = "Đã tải ảnh acc."
                    }
                } else {
                    DispatchQueue.main.async {
                        self.postMessage = "Không đọc được dữ liệu ảnh này, thử chọn ảnh khác."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.postMessage = "Lỗi tải ảnh: \(error.localizedDescription)"
                }
            }
        }
    }

    private func submitListing() {
        triggerHaptic()
        guard let user = currentUser else { return }
        let cleanTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let digitsOnly = newPriceText.filter { $0.isNumber }
        let price = Int(digitsOnly) ?? 0

        if cleanTitle.isEmpty {
            postMessage = "Nhập tên hoặc mô tả acc trước khi đăng."
            return
        }
        if price <= 0 {
            postMessage = "Nhập giá tiền bán hợp lệ lớn hơn 0."
            return
        }

        let item = AccountListing(
            id: UUID(),
            sellerName: user.username,
            platform: newPlatform,
            title: cleanTitle,
            price: price,
            loginMethod: newLoginMethod,
            imageData: newImageData,
            createdAt: Date()
        )

        listings.insert(item, at: 0)
        saveListings()

        newTitle = ""
        newPriceText = ""
        newImageData = nil
        selectedListingPhoto = nil
        postMessage = "Đã đăng acc lên màn hình chính."
        selectedSection = 0
    }

    private var topUpView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nạp tiền vào tài khoản")
                .font(.headline)
                .foregroundColor(primaryText)

            Text("Chọn mệnh giá để cộng trực tiếp vào số dư tài khoản đang đăng nhập.")
                .font(.footnote)
                .foregroundColor(secondaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(topUpAmounts, id: \.self) { amount in
                    Button(action: {
                        addBalance(amount)
                    }) {
                        Text("+ \(formatVND(amount))")
                            .font(.subheadline.bold())
                            .foregroundColor(primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(inputBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderTone, lineWidth: 1)
                            )
                    }
                }
            }

            if let notice = topUpNotice {
                Text(notice)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderTone, lineWidth: 1)
        )
    }

    private func addBalance(_ amount: Int) {
        triggerHaptic()
        guard let idx = currentUserIndex else { return }
        accounts[idx].balance += amount
        saveAccounts()
        topUpNotice = "Đã cộng \(formatVND(amount)) vào tài khoản \(accounts[idx].username)."
    }

    private func settingsView(user: UserAccount) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cài đặt ứng dụng")
                .font(.headline)
                .foregroundColor(primaryText)

            VStack(alignment: .leading, spacing: 8) {
                Text("Nền giao diện (Trắng / Đen)")
                    .font(.subheadline.bold())
                    .foregroundColor(primaryText)

                Picker("Nền giao diện", selection: $settings.themeMode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.themeMode) { _ in
                    triggerHaptic()
                    saveSettings()
                    settingsNotice = "Đã chuyển sang \(settings.themeMode.rawValue)."
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Màu điểm nhấn")
                    .font(.subheadline.bold())
                    .foregroundColor(primaryText)

                Picker("Màu điểm nhấn", selection: $settings.accentChoice) {
                    ForEach(AccentChoice.allCases) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.accentChoice) { _ in
                    triggerHaptic()
                    saveSettings()
                    settingsNotice = "Đã đổi màu nhấn sang \(settings.accentChoice.rawValue)."
                }
            }

            Divider()
                .background(borderTone)

            Toggle(isOn: $settings.showGreetingBanner) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hiện thanh chào ở đầu trang")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(primaryText)
                    Text("Hiển thị tên tài khoản và số dư nhanh")
                        .font(.caption)
                        .foregroundColor(secondaryText)
                }
            }
            .tint(accent)
            .onChange(of: settings.showGreetingBanner) { newVal in
                if newVal { showNotice = true }
                saveSettings()
            }

            Toggle(isOn: $settings.showRewardList) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hiện bảng mốc thưởng & tỉ lệ")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(primaryText)
                    Text("Xem các mức thưởng và tỉ lệ nổ trước khi quay")
                        .font(.caption)
                        .foregroundColor(secondaryText)
                }
            }
            .tint(accent)
            .onChange(of: settings.showRewardList) { _ in
                saveSettings()
            }

            Toggle(isOn: $settings.hapticEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rung phản hồi khi thao tác")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(primaryText)
                    Text("Rung nhẹ khi bấm nút, nạp tiền hoặc quay")
                        .font(.caption)
                        .foregroundColor(secondaryText)
                }
            }
            .tint(accent)
            .onChange(of: settings.hapticEnabled) { _ in
                saveSettings()
            }

            Divider()
                .background(borderTone)

            VStack(alignment: .leading, spacing: 6) {
                Text("Thông tin lưu trữ cục bộ")
                    .font(.subheadline.bold())
                    .foregroundColor(primaryText)
                Text("Tài khoản: \(user.username) • Tổng acc đăng: \(listings.count)")
                    .font(.caption)
                    .foregroundColor(secondaryText)
            }

            VStack(spacing: 10) {
                Button(action: resetSettingsOnly) {
                    Text("Khôi phục cài đặt mặc định")
                        .font(.subheadline.bold())
                        .foregroundColor(primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(inputBg)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderTone, lineWidth: 1)
                        )
                }

                Button(action: clearAllListings) {
                    Text("Xóa toàn bộ tin rao bán acc")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(12)
                }
            }

            if let sNotice = settingsNotice {
                Text(sNotice)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderTone, lineWidth: 1)
        )
    }

    private func resetSettingsOnly() {
        settings = NotebookSettings()
        showNotice = true
        saveSettings()
        triggerHaptic()
        settingsNotice = "Đã khôi phục cài đặt mặc định."
    }

    private func clearAllListings() {
        listings.removeAll()
        saveListings()
        triggerHaptic()
        settingsNotice = "Đã xóa toàn bộ tin rao bán acc."
    }

    private func triggerHaptic() {
        guard settings.hapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func formatVND(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let numStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(numStr)đ"
    }

    private func loadInitialData() {
        if let data = UserDefaults.standard.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([UserAccount].self, from: data) {
            accounts = decoded
        }
        activeUsername = UserDefaults.standard.string(forKey: currentUserKey) ?? ""
        if let data = UserDefaults.standard.data(forKey: listingsKey),
           let decoded = try? JSONDecoder().decode([AccountListing].self, from: data) {
            listings = decoded
        }
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(NotebookSettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: accountsKey)
        }
    }

    private func saveListings() {
        if let encoded = try? JSONEncoder().encode(listings) {
            UserDefaults.standard.set(encoded, forKey: listingsKey)
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
}
