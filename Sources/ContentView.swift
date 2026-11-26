import SwiftUI
import PhotosUI

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

    @State private var accounts: [UserAccount] = []
    @State private var activeUsername: String = ""
    @State private var listings: [AccountListing] = []

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

    private var currentUserIndex: Int? {
        accounts.firstIndex { $0.username.caseInsensitiveCompare(activeUsername) == .orderedSame }
    }

    private var currentUser: UserAccount? {
        guard let idx = currentUserIndex else { return nil }
        return accounts[idx]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                darkNotebookBackground

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
                            activeUsername = ""
                            UserDefaults.standard.set("", forKey: currentUserKey)
                            authUsername = ""
                            authPassword = ""
                            authConfirmPassword = ""
                            authErrorMessage = nil
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.orange)
                    }
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var darkNotebookBackground: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.11),
                    Color(red: 0.11, green: 0.12, blue: 0.16)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(Color(red: 0.22, green: 0.17, blue: 0.13))
                .frame(width: 12)
                .ignoresSafeArea()

            Rectangle()
                .fill(Color.orange.opacity(0.28))
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
                        .foregroundColor(.orange)

                    Text("Sổ Quản Lý Acc & Vòng Quay")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text(isRegisterTab ? "Tạo tài khoản mới để lưu số dư & tin đăng" : "Đăng nhập bằng tài khoản đã tạo")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.72))
                }
                .padding(.top, 12)

                Picker("Chế độ", selection: $isRegisterTab) {
                    Text("Đăng nhập").tag(false)
                    Text("Tạo tài khoản").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(Color(red: 0.15, green: 0.17, blue: 0.22))
                .cornerRadius(12)

                VStack(spacing: 14) {
                    TextField("Tên tài khoản", text: $authUsername)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )

                    SecureField("Mật khẩu", text: $authPassword)
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )

                    if isRegisterTab {
                        SecureField("Nhập lại mật khẩu", text: $authConfirmPassword)
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Color(red: 0.10, green: 0.11, blue: 0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                    }

                    if let err = authErrorMessage {
                        Text(err)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: handleAuthSubmit) {
                        Text(isRegisterTab ? "Tạo tài khoản & Vào sổ" : "Đăng nhập")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange)
                            .cornerRadius(14)
                    }
                }
                .padding(16)
                .background(Color(red: 0.15, green: 0.17, blue: 0.22))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            }
            .padding(.leading, 24)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
    }

    private func handleAuthSubmit() {
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
                if showNotice {
                    HStack(spacing: 10) {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.orange)

                        Text("Chào \(user.username) • Số dư hiện tại: \(formatVND(user.balance))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            showNotice = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.footnote.bold())
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.10))
                                .clipShape(Circle())
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.15, green: 0.17, blue: 0.22))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                }

                walletSummaryCard(user: user)

                Picker("Trang sổ", selection: $selectedSection) {
                    Text("Màn chính").tag(0)
                    Text("Vòng quay").tag(1)
                    Text("Đăng bán").tag(2)
                    Text("Nạp tiền").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(Color(red: 0.15, green: 0.17, blue: 0.22))
                .cornerRadius(12)

                if selectedSection == 0 {
                    homeListingsView
                } else if selectedSection == 1 {
                    wheelSpinView(user: user)
                } else if selectedSection == 2 {
                    createListingView
                } else {
                    topUpView
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
                    .foregroundColor(Color.white.opacity(0.7))
                Spacer()
                Text(formatVND(user.balance))
                    .font(.headline.bold())
                    .foregroundColor(Color(red: 0.30, green: 0.90, blue: 0.55))
            }

            Divider()
                .background(Color.white.opacity(0.12))

            HStack(spacing: 8) {
                resourcePill(label: "Quân Huy", value: "\(user.quanHuy)", tint: Color(red: 0.35, green: 0.68, blue: 1.0))
                resourcePill(label: "Kim Cương", value: "\(user.kimCuong)", tint: Color(red: 0.30, green: 0.88, blue: 0.85))
                resourcePill(label: "FV", value: "\(user.fv)", tint: Color.orange)
            }
        }
        .padding(14)
        .background(Color(red: 0.15, green: 0.17, blue: 0.22))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func resourcePill(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(tint)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(Color.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(red: 0.10, green: 0.11, blue: 0.15))
        .cornerRadius(10)
    }

    private var homeListingsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Acc đang rao bán (\(listings.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("+ Đăng bán") {
                    selectedSection = 2
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange)
            }

            if listings.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange.opacity(0.85))
                    Text("Chưa có tin đăng acc nào")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    Text("Chuyển sang mục Đăng bán để chọn ảnh acc, nhập giá và cách đăng nhập.")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(red: 0.15, green: 0.17, blue: 0.22))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            } else {
                ForEach(listings) { item in
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
                                .fill(Color(red: 0.10, green: 0.11, blue: 0.15))
                                .frame(height: 140)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                        Text(item.platform.rawValue)
                                            .font(.caption.bold())
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                )
                        }

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                HStack(spacing: 8) {
                                    Text(item.platform.rawValue)
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.14))
                                        .cornerRadius(10)

                                    Text("Đăng nhập: \(item.loginMethod.rawValue)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.18))
                                        .cornerRadius(10)
                                }
                            }

                            Spacer()

                            Text(formatVND(item.price))
                                .font(.headline.bold())
                                .foregroundColor(.orange)
                        }

                        HStack {
                            Text("Người đăng: \(item.sellerName)")
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.7))

                            Spacer()

                            Button("Mua thử") {
                                buyListing(item)
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding(14)
                    .background(Color(red: 0.15, green: 0.17, blue: 0.22))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func buyListing(_ item: AccountListing) {
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

    private func wheelSpinView(user: UserAccount) -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Chọn vòng quay theo nền tảng")
                    .font(.headline)
                    .foregroundColor(.white)

                VStack(spacing: 8) {
                    ForEach(GamePlatform.allCases) { platform in
                        let isSelected = selectedPlatform == platform
                        Button(action: {
                            selectedPlatform = platform
                            lastSpinResult = "Vòng \(platform.rawValue) • Giá \(formatVND(platform.spinCost))/lượt"
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(platform.rawValue)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("Thưởng: \(platform.currencyName)")
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(0.72))
                                }

                                Spacer()

                                Text("\(formatVND(platform.spinCost)) / lượt")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color.orange : Color.white.opacity(0.10))
                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.88))
                                    .cornerRadius(14)
                            }
                            .padding(12)
                            .background(isSelected ? Color.orange.opacity(0.14) : Color(red: 0.10, green: 0.11, blue: 0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isSelected ? Color.orange : Color.white.opacity(0.12),
                                        lineWidth: isSelected ? 1.5 : 1
                                    )
                            )
                        }
                        .disabled(isSpinning)
                    }
                }

                HStack {
                    Text("Giá vòng đang chọn: \(formatVND(selectedPlatform.spinCost))")
                        .font(.footnote.bold())
                        .foregroundColor(.orange)
                    Spacer()
                    Text("Số dư: \(formatVND(user.balance))")
                        .font(.footnote.bold())
                        .foregroundColor(user.balance >= selectedPlatform.spinCost ? Color(red: 0.30, green: 0.90, blue: 0.55) : Color(red: 1.0, green: 0.42, blue: 0.42))
                }
            }
            .padding(14)
            .background(Color(red: 0.15, green: 0.17, blue: 0.22))
            .cornerRadius(16)

            ZStack {
                Circle()
                    .fill(Color(red: 0.22, green: 0.42, blue: 0.78))
                    .frame(width: 220, height: 220)
                    .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 4))
                    .shadow(color: Color.black.opacity(0.45), radius: 10)
                    .rotationEffect(.degrees(wheelAngle))

                Circle()
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.19))
                    .frame(width: 78, height: 78)
                    .overlay(Circle().stroke(Color.orange, lineWidth: 2))

                VStack(spacing: 2) {
                    Text(selectedPlatform.currencyName)
                        .font(.caption.bold())
                    Text(formatVND(selectedPlatform.spinCost))
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.75))
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            }
            .padding(.vertical, 8)

            Text(lastSpinResult)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button(action: spinWheel) {
                Text(isSpinning ? "Đang quay..." : "Quay \(selectedPlatform.rawValue) (-\(formatVND(selectedPlatform.spinCost)))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .cornerRadius(14)
            }
            .disabled(isSpinning)
        }
        .padding(14)
        .background(Color(red: 0.15, green: 0.17, blue: 0.22))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func spinWheel() {
        guard let idx = currentUserIndex, !isSpinning else { return }
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
        let pickedIndex = Int.random(in: 0..<rewardPool.count)
        let picked = rewardPool[pickedIndex]
        let sliceAngle = 360.0 / Double(rewardPool.count)
        let extraDegrees = Double(pickedIndex) * sliceAngle + 1080.0

        withAnimation(.easeOut(duration: 1.5)) {
            wheelAngle += extraDegrees
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
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
            lastSpinResult = "Trúng \(picked.label)!"
            isSpinning = false
        }
    }

    private var createListingView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Đăng tin bán acc lên màn hình chính")
                .font(.headline)
                .foregroundColor(.white)

            Picker("Nền tảng", selection: $newPlatform) {
                ForEach(GamePlatform.allCases) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
            .pickerStyle(.segmented)

            TextField("Tên / mô tả acc (vd: Acc rank cao, nhiều skin)", text: $newTitle)
                .foregroundColor(.white)
                .padding(12)
                .background(Color(red: 0.10, green: 0.11, blue: 0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )

            TextField("Giá tiền cần bán (vd: 150000)", text: $newPriceText)
                .keyboardType(.numberPad)
                .foregroundColor(.white)
                .padding(12)
                .background(Color(red: 0.10, green: 0.11, blue: 0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Cách thức đăng nhập")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)

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
                .background(Color.white.opacity(0.10))
                .foregroundColor(.orange)
                .cornerRadius(12)
            }

            Button(action: loadPickedImage) {
                Text(selectedListingPhoto == nil ? "Tải ảnh đã chọn vào bài đăng" : "Xác nhận ảnh acc đã chọn")
                    .font(.footnote.bold())
                    .foregroundColor(.orange)
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
                    .foregroundColor(Color(red: 0.30, green: 0.90, blue: 0.55))
            }

            Button(action: submitListing) {
                Text("Đăng lên màn hình chính")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .cornerRadius(14)
            }
        }
        .padding(14)
        .background(Color(red: 0.15, green: 0.17, blue: 0.22))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func loadPickedImage() {
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
                .foregroundColor(.white)

            Text("Chọn mệnh giá để cộng trực tiếp vào số dư tài khoản đang đăng nhập.")
                .font(.footnote)
                .foregroundColor(Color.white.opacity(0.72))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(topUpAmounts, id: \.self) { amount in
                    Button(action: {
                        addBalance(amount)
                    }) {
                        Text("+ \(formatVND(amount))")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 0.10, green: 0.11, blue: 0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                    }
                }
            }

            if let notice = topUpNotice {
                Text(notice)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(red: 0.30, green: 0.90, blue: 0.55))
            }
        }
        .padding(14)
        .background(Color(red: 0.15, green: 0.17, blue: 0.22))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func addBalance(_ amount: Int) {
        guard let idx = currentUserIndex else { return }
        accounts[idx].balance += amount
        saveAccounts()
        topUpNotice = "Đã cộng \(formatVND(amount)) vào tài khoản \(accounts[idx].username)."
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
}
