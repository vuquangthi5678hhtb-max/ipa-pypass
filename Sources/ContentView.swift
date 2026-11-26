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
                            activeUsername = ""
                            UserDefaults.standard.set("", forKey: currentUserKey)
                            authUsername = ""
                            authPassword = ""
                            authConfirmPassword = ""
                            authErrorMessage = nil
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.brown)
                    }
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
    }

    private var notebookBackground: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.99, green: 0.97, blue: 0.92),
                    Color(red: 0.96, green: 0.93, blue: 0.86)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(Color(red: 0.76, green: 0.60, blue: 0.42))
                .frame(width: 14)
                .ignoresSafeArea()

            Rectangle()
                .fill(Color.red.opacity(0.22))
                .frame(width: 1.5)
                .padding(.leading, 32)
                .ignoresSafeArea()
        }
    }

    private var authNotebookView: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.16))

                    Text("Sổ Quản Lý Acc & Vòng Quay")
                        .font(.title2.bold())
                        .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))

                    Text(isRegisterTab ? "Tạo tài khoản mới để lưu số dư & tin đăng" : "Đăng nhập bằng tài khoản đã tạo")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.45, green: 0.36, blue: 0.26))
                }
                .padding(.top, 12)

                Picker("Chế độ", selection: $isRegisterTab) {
                    Text("Đăng nhập").tag(false)
                    Text("Tạo tài khoản").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(Color.white.opacity(0.85))
                .cornerRadius(12)

                VStack(spacing: 14) {
                    TextField("Tên tài khoản", text: $authUsername)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.brown.opacity(0.25), lineWidth: 1)
                        )

                    SecureField("Mật khẩu", text: $authPassword)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.brown.opacity(0.25), lineWidth: 1)
                        )

                    if isRegisterTab {
                        SecureField("Nhập lại mật khẩu", text: $authConfirmPassword)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brown.opacity(0.25), lineWidth: 1)
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
                            .background(Color(red: 0.58, green: 0.36, blue: 0.16))
                            .cornerRadius(14)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.88))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.brown.opacity(0.25), lineWidth: 1.2)
                )
            }
            .padding(.leading, 26)
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
                            .foregroundColor(Color(red: 0.65, green: 0.35, blue: 0.12))

                        Text("Chào \(user.username) • Số dư hiện tại: \(formatVND(user.balance))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))

                        Spacer()

                        Button(action: {
                            showNotice = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.footnote.bold())
                                .foregroundColor(.brown)
                                .frame(width: 28, height: 28)
                                .background(Color.brown.opacity(0.12))
                                .clipShape(Circle())
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.92))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.brown.opacity(0.25), lineWidth: 1)
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
                .background(Color.white.opacity(0.88))
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
            .padding(.leading, 26)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
    }

    private func walletSummaryCard(user: UserAccount) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Số dư tài khoản")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatVND(user.balance))
                    .font(.headline)
                    .foregroundColor(Color(red: 0.12, green: 0.48, blue: 0.24))
            }

            Divider()

            HStack(spacing: 8) {
                resourcePill(label: "Quân Huy", value: "\(user.quanHuy)", tint: .blue)
                resourcePill(label: "Kim Cương", value: "\(user.kimCuong)", tint: .teal)
                resourcePill(label: "FV", value: "\(user.fv)", tint: .orange)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.92))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brown.opacity(0.25), lineWidth: 1)
        )
    }

    private func resourcePill(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(tint)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.10))
        .cornerRadius(10)
    }

    private var homeListingsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Acc đang rao bán (\(listings.count))")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))
                Spacer()
                Button("+ Đăng bán") {
                    selectedSection = 2
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(red: 0.58, green: 0.36, blue: 0.16))
            }

            if listings.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.largeTitle)
                        .foregroundColor(.brown.opacity(0.6))
                    Text("Chưa có tin đăng acc nào")
                        .font(.subheadline.weight(.semibold))
                    Text("Chuyển sang mục Đăng bán để chọn ảnh acc, nhập giá và cách đăng nhập.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white.opacity(0.88))
                .cornerRadius(16)
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
                                .fill(Color.brown.opacity(0.10))
                                .frame(height: 140)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.title2)
                                            .foregroundColor(.brown)
                                        Text(item.platform.rawValue)
                                            .font(.caption.bold())
                                            .foregroundColor(.brown)
                                    }
                                )
                        }

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.20, green: 0.15, blue: 0.10))

                                HStack(spacing: 8) {
                                    Text(item.platform.rawValue)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.brown.opacity(0.14))
                                        .cornerRadius(10)

                                    Text("Đăng nhập: \(item.loginMethod.rawValue)")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundColor(.blue)
                                        .cornerRadius(10)
                                }
                            }

                            Spacer()

                            Text(formatVND(item.price))
                                .font(.headline)
                                .foregroundColor(Color(red: 0.72, green: 0.24, blue: 0.10))
                        }

                        HStack {
                            Text("Người đăng: \(item.sellerName)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button("Mua thử") {
                                buyListing(item)
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.58, green: 0.36, blue: 0.16))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.94))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.brown.opacity(0.25), lineWidth: 1)
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
                    .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))

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
                                        .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))
                                    Text("Thưởng: \(platform.currencyName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("\(formatVND(platform.spinCost)) / lượt")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color(red: 0.58, green: 0.36, blue: 0.16) : Color.brown.opacity(0.12))
                                    .foregroundColor(isSelected ? .white : Color(red: 0.45, green: 0.26, blue: 0.10))
                                    .cornerRadius(14)
                            }
                            .padding(12)
                            .background(isSelected ? Color.brown.opacity(0.08) : Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isSelected ? Color(red: 0.58, green: 0.36, blue: 0.16) : Color.brown.opacity(0.22),
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
                        .foregroundColor(Color(red: 0.58, green: 0.36, blue: 0.16))
                    Spacer()
                    Text("Số dư: \(formatVND(user.balance))")
                        .font(.footnote.bold())
                        .foregroundColor(user.balance >= selectedPlatform.spinCost ? Color(red: 0.12, green: 0.48, blue: 0.24) : .red)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.92))
            .cornerRadius(16)

            ZStack {
                Circle()
                    .fill(Color(red: 0.25, green: 0.48, blue: 0.85))
                    .frame(width: 220, height: 220)
                    .overlay(Circle().stroke(Color.white, lineWidth: 5))
                    .shadow(color: Color.brown.opacity(0.25), radius: 10)
                    .rotationEffect(.degrees(wheelAngle))

                Circle()
                    .fill(Color.white)
                    .frame(width: 76, height: 76)
                    .shadow(radius: 4)

                VStack(spacing: 2) {
                    Text(selectedPlatform.currencyName)
                        .font(.caption.bold())
                    Text(formatVND(selectedPlatform.spinCost))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))
            }
            .padding(.vertical, 8)

            Text(lastSpinResult)
                .font(.subheadline.bold())
                .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))
                .multilineTextAlignment(.center)

            Button(action: spinWheel) {
                Text(isSpinning ? "Đang quay..." : "Quay \(selectedPlatform.rawValue) (-\(formatVND(selectedPlatform.spinCost)))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.58, green: 0.36, blue: 0.16))
                    .cornerRadius(14)
            }
            .disabled(isSpinning)
        }
        .padding(14)
        .background(Color.white.opacity(0.88))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brown.opacity(0.25), lineWidth: 1)
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
                .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))

            Picker("Nền tảng", selection: $newPlatform) {
                ForEach(GamePlatform.allCases) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
            .pickerStyle(.segmented)

            TextField("Tên / mô tả acc (vd: Acc rank cao, nhiều skin)", text: $newTitle)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brown.opacity(0.25), lineWidth: 1)
                )

            TextField("Giá tiền cần bán (vd: 150000)", text: $newPriceText)
                .keyboardType(.numberPad)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brown.opacity(0.25), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Cách thức đăng nhập")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))

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
                .background(Color.brown.opacity(0.12))
                .foregroundColor(Color(red: 0.45, green: 0.26, blue: 0.10))
                .cornerRadius(12)
            }

            Button(action: loadPickedImage) {
                Text(selectedListingPhoto == nil ? "Tải ảnh đã chọn vào bài đăng" : "Xác nhận ảnh acc đã chọn")
                    .font(.footnote.bold())
                    .foregroundColor(Color(red: 0.58, green: 0.36, blue: 0.16))
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
                    .foregroundColor(Color(red: 0.12, green: 0.48, blue: 0.24))
            }

            Button(action: submitListing) {
                Text("Đăng lên màn hình chính")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.58, green: 0.36, blue: 0.16))
                    .cornerRadius(14)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.92))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brown.opacity(0.25), lineWidth: 1)
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
                .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))

            Text("Chọn mệnh giá để cộng trực tiếp vào số dư tài khoản đang đăng nhập.")
                .font(.footnote)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(topUpAmounts, id: \.self) { amount in
                    Button(action: {
                        addBalance(amount)
                    }) {
                        Text("+ \(formatVND(amount))")
                            .font(.subheadline.bold())
                            .foregroundColor(Color(red: 0.22, green: 0.16, blue: 0.10))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brown.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }

            if let notice = topUpNotice {
                Text(notice)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(red: 0.12, green: 0.48, blue: 0.24))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.92))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brown.opacity(0.25), lineWidth: 1)
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
