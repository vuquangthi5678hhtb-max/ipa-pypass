import SwiftUI
import PhotosUI
import UIKit

enum LoginMethod: String, CaseIterable, Identifiable, Codable {
    case facebook = "Facebook"
    case google = "Google"
    case account = "Tài khoản"

    var id: String { rawValue }
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

    @State private var newPlatform: GamePlatform = .lienQuan
    @State private var newTitle = ""
    @State private var newPriceText = ""
    @State private var newLoginMethod: LoginMethod = .facebook
    @State private var selectedListingPhoto: PhotosPickerItem?
    @State private var newImageData: Data?
    @State private var postMessage: String?

    private let topUpAmounts = [10_000, 20_000, 50_000, 100_000, 200_000, 500_000]
    @State private var topUpNotice: String?
    @State private var filterPlatform: GamePlatform? = nil

    private var isDark: Bool { settings.themeMode == .dark }
    private var accent: Color { settings.accentChoice.color }
    private var pageBgTop: Color { isDark ? Color(red: 0.06, green: 0.07, blue: 0.09) : Color(red: 0.99, green: 0.98, blue: 0.96) }
    private var pageBgBottom: Color { isDark ? Color(red: 0.10, green: 0.11, blue: 0.15) : Color(red: 0.95, green: 0.94, blue: 0.91) }
    private var cardBg: Color { isDark ? Color(red: 0.14, green: 0.16, blue: 0.21) : Color.white }
    private var inputBg: Color { isDark ? Color(red: 0.09, green: 0.10, blue: 0.14) : Color(red: 0.97, green: 0.97, blue: 0.96) }
    private var primaryText: Color { isDark ? .white : Color(red: 0.12, green: 0.12, blue: 0.14) }
    private var secondaryText: Color { isDark ? Color.white.opacity(0.72) : Color(red: 0.42, green: 0.42, blue: 0.46) }
    private var borderTone: Color { isDark ? Color.white.opacity(0.11) : Color.black.opacity(0.12) }
    private var spineColor: Color { isDark ? Color(red: 0.18, green: 0.16, blue: 0.15) : Color(red: 0.20, green: 0.20, blue: 0.22) }

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

    private func haptic() {
        guard settings.hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                            haptic()
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
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderTone, lineWidth: 1))

                    SecureField("Mật khẩu", text: $authPassword)
                        .foregroundColor(primaryText)
                        .padding(14)
                        .background(inputBg)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderTone, lineWidth: 1))

                    if isRegisterTab {
                        SecureField("Nhập lại mật khẩu", text: $authConfirmPassword)
                            .foregroundColor(primaryText)
                            .padding(14)
                            .background(inputBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderTone, lineWidth: 1))
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
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderTone, lineWidth: 1))
            }
            .padding(.leading, 24)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
    }

    private func handleAuthSubmit() {
        haptic()
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
            if accounts.contains(where: { $0.username.caseInsensitiveCompare(cleanUser) == .orderedSame }) {
                authErrorMessage = "Tên tài khoản này đã tồn tại."
                return
            }
            let created = UserAccount(id: UUID(), username: cleanUser, password: cleanPass, balance: 0, quanHuy: 0, kimCuong: 0, fv: 0)
            accounts.append(created)
            saveAccounts()
            activeUsername = created.username
            UserDefaults.standard.set(created.username, forKey: currentUserKey)
            authErrorMessage = nil
        } else {
            guard let matched = accounts.first(where: {
                $0.username.caseInsensitiveCompare(cleanUser) == .orderedSame && $0.password == cleanPass
            }) else {
                authErrorMessage = "Sai tên tài khoản hoặc mật khẩu."
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
                        Button(action: { showNotice = false }) {
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
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderTone, lineWidth: 1))
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
                    WheelSpinView(
                        balance: user.balance,
                        accent: accent,
                        cardBg: cardBg,
                        inputBg: inputBg,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        borderTone: borderTone,
                        isDark: isDark,
                        showRewardList: settings.showRewardList,
                        hapticEnabled: settings.hapticEnabled,
                        formatVND: formatVND,
                        onSpinComplete: applySpinReward
                    )
                case 2:
                    createListingView
                case 3:
                    topUpView
                default:
                    SettingsTabView(
                        settings: $settings,
                        username: user.username,
                        listingCount: listings.count,
                        accent: accent,
                        cardBg: cardBg,
                        inputBg: inputBg,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        borderTone: borderTone,
                        onSaveSettings: saveSettings,
                        onResetSettings: {
                            settings = NotebookSettings()
                            showNotice = true
                            saveSettings()
                        },
                        onClearListings: {
                            listings.removeAll()
                            saveListings()
                        }
                    )
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
    }

    private func applySpinReward(platform: GamePlatform, reward: RewardOption) {
        guard let idx = currentUserIndex else { return }
        accounts[idx].balance = max(0, accounts[idx].balance - platform.spinCost)
        switch platform {
        case .lienQuan:
            accounts[idx].quanHuy += reward.amount
        case .freeFire:
            accounts[idx].kimCuong += reward.amount
        case .fcMobile:
            accounts[idx].fv += reward.amount
        }
        saveAccounts()
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

            Divider().background(borderTone)

            HStack(spacing: 8) {
                resourcePill(label: "Quân Huy", value: "\(user.quanHuy)", tint: Color(red: 0.32, green: 0.65, blue: 1.0))
                resourcePill(label: "Kim Cương", value: "\(user.kimCuong)", tint: Color(red: 0.20, green: 0.82, blue: 0.78))
                resourcePill(label: "FV", value: "\(user.fv)", tint: accent)
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderTone, lineWidth: 1))
    }

    private func resourcePill(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.subheadline.bold()).foregroundColor(tint)
            Text(label).font(.caption2.weight(.medium)).foregroundColor(secondaryText)
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
                    haptic()
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
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderTone, lineWidth: 1))
            } else {
                ForEach(filteredListings) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        if let data = item.imageData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 195)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(inputBg)
                                .frame(height: 140)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "gamecontroller.fill").font(.title2).foregroundColor(accent)
                                        Text(item.platform.rawValue).font(.caption.bold()).foregroundColor(primaryText.opacity(0.85))
                                    }
                                )
                        }

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title).font(.headline).foregroundColor(primaryText)
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
                            Text(formatVND(item.price)).font(.headline.bold()).foregroundColor(accent)
                        }

                        HStack {
                            Text("Người đăng: \(item.sellerName)").font(.caption).foregroundColor(secondaryText)
                            Spacer()
                            if item.sellerName.caseInsensitiveCompare(activeUsername) == .orderedSame {
                                Button("Xóa tin") {
                                    haptic()
                                    listings.removeAll { $0.id == item.id }
                                    saveListings()
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.16))
                                .foregroundColor(.red)
                                .cornerRadius(16)
                            }
                            Button("Mua thử") {
                                haptic()
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
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderTone, lineWidth: 1))
                }
            }
        }
    }

    private func filterChip(title: String, target: GamePlatform?) -> some View {
        let active = filterPlatform == target
        return Button(action: {
            haptic()
            filterPlatform = target
        }) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(active ? accent : cardBg)
                .foregroundColor(active ? .white : primaryText)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(active ? accent : borderTone, lineWidth: 1))
        }
    }

    private var createListingView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Đăng tin bán acc lên màn hình chính").font(.headline).foregroundColor(primaryText)

            Picker("Nền tảng", selection: $newPlatform) {
                ForEach(GamePlatform.allCases) { p in Text(p.rawValue).tag(p) }
            }
            .pickerStyle(.segmented)

            TextField("Tên / mô tả acc (vd: Acc rank cao, nhiều skin)", text: $newTitle)
                .foregroundColor(primaryText)
                .padding(12)
                .background(inputBg)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderTone, lineWidth: 1))

            TextField("Giá tiền cần bán (vd: 150000)", text: $newPriceText)
                .keyboardType(.numberPad)
                .foregroundColor(primaryText)
                .padding(12)
                .background(inputBg)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderTone, lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                Text("Cách thức đăng nhập").font(.subheadline.weight(.semibold)).foregroundColor(primaryText)
                Picker("Cách đăng nhập", selection: $newLoginMethod) {
                    ForEach(LoginMethod.allCases) { m in Text(m.rawValue).tag(m) }
                }
                .pickerStyle(.segmented)
            }

            PhotosPicker(selection: $selectedListingPhoto, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(newImageData == nil ? "Chọn ảnh acc từ thư viện" : "Đổi ảnh acc khác").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(inputBg)
                .foregroundColor(accent)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderTone, lineWidth: 1))
            }
            .onChange(of: selectedListingPhoto) { newItem in
                if newItem != nil {
                    loadPickedImage()
                }
            }

            if selectedListingPhoto != nil && newImageData == nil {
                Button(action: loadPickedImage) {
                    Text("Nạp lại ảnh đã chọn")
                        .font(.footnote.bold())
                        .foregroundColor(accent)
                }
            }

            if let data = newImageData, let previewImg = UIImage(data: data) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Xem trước ảnh acc đã chọn")
                        .font(.caption.bold())
                        .foregroundColor(secondaryText)

                    Image(uiImage: previewImg)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(12)

                    Button(role: .destructive, action: {
                        haptic()
                        newImageData = nil
                        selectedListingPhoto = nil
                        postMessage = "Đã bỏ ảnh đã chọn."
                    }) {
                        Text("Xóa ảnh này")
                            .font(.caption.bold())
                    }
                }
            }

            if let msg = postMessage {
                Text(msg).font(.footnote.weight(.semibold)).foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
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
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderTone, lineWidth: 1))
    }

    private func compressImageData(_ rawData: Data) -> Data? {
        guard let img = UIImage(data: rawData) else { return rawData }
        let maxSide: CGFloat = 1200
        let size = img.size
        let ratio = min(maxSide / max(size.width, 1), maxSide / max(size.height, 1), 1.0)
        let targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.75) ?? rawData
    }

    private func loadPickedImage() {
        haptic()
        guard let item = selectedListingPhoto else {
            postMessage = "Hãy bấm 'Chọn ảnh acc từ thư viện' trước."
            return
        }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    let prepared = compressImageData(data)
                    DispatchQueue.main.async {
                        self.newImageData = prepared
                        self.postMessage = "Đã hiện ảnh acc, kiểm tra khung xem trước rồi bấm Đăng."
                    }
                } else {
                    DispatchQueue.main.async {
                        self.postMessage = "Không đọc được ảnh này, thử chọn ảnh khác."
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
        haptic()
        guard let user = currentUser else { return }
        let cleanTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let price = Int(newPriceText.filter { $0.isNumber }) ?? 0
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
        filterPlatform = nil
        newTitle = ""
        newPriceText = ""
        newImageData = nil
        selectedListingPhoto = nil
        postMessage = "Đã đăng acc lên màn hình chính."
        selectedSection = 0
    }

    private var topUpView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nạp tiền vào tài khoản").font(.headline).foregroundColor(primaryText)
            Text("Chọn mệnh giá để cộng trực tiếp vào số dư tài khoản đang đăng nhập.")
                .font(.footnote)
                .foregroundColor(secondaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(topUpAmounts, id: \.self) { amount in
                    Button(action: {
                        haptic()
                        guard let idx = currentUserIndex else { return }
                        accounts[idx].balance += amount
                        saveAccounts()
                        topUpNotice = "Đã cộng \(formatVND(amount)) vào tài khoản \(accounts[idx].username)."
                    }) {
                        Text("+ \(formatVND(amount))")
                            .font(.subheadline.bold())
                            .foregroundColor(primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(inputBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderTone, lineWidth: 1))
                    }
                }
            }

            if let notice = topUpNotice {
                Text(notice).font(.footnote.weight(.semibold)).foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderTone, lineWidth: 1))
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
