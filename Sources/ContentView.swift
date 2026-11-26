import SwiftUI
import PhotosUI
import UIKit

struct RewardOption: Identifiable, Codable {
    let id: UUID
    let label: String
    let amount: Int

    init(id: UUID = UUID(), label: String, amount: Int) {
        self.id = id
        self.label = label
        self.amount = amount
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
                RewardOption(label: "150 Quân Huy", amount: 150),
                RewardOption(label: "300 Quân Huy", amount: 300),
                RewardOption(label: "650 Quân Huy", amount: 650),
                RewardOption(label: "1.200 Quân Huy", amount: 1200),
                RewardOption(label: "60 Quân Huy", amount: 60),
                RewardOption(label: "2.500 Quân Huy", amount: 2500)
            ]
        case .freeFire:
            return [
                RewardOption(label: "140 Kim Cương", amount: 140),
                RewardOption(label: "290 Kim Cương", amount: 290),
                RewardOption(label: "580 Kim Cương", amount: 580),
                RewardOption(label: "1.150 Kim Cương", amount: 1150),
                RewardOption(label: "70 Kim Cương", amount: 70),
                RewardOption(label: "2.200 Kim Cương", amount: 2200)
            ]
        case .fcMobile:
            return [
                RewardOption(label: "200 FV", amount: 200),
                RewardOption(label: "450 FV", amount: 450),
                RewardOption(label: "950 FV", amount: 950),
                RewardOption(label: "1.800 FV", amount: 1800),
                RewardOption(label: "100 FV", amount: 100),
                RewardOption(label: "3.500 FV", amount: 3500)
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
                    RoundedRectangle(cornerRadius
