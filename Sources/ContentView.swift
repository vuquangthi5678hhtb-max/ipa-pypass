import SwiftUI
import UIKit

struct RewardItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let amount: Int
    let weight: Int

    init(id: UUID = UUID(), title: String, amount: Int, weight: Int) {
        self.id = id
        self.title = title
        self.amount = amount
        self.weight = max(1, weight)
    }
}

enum GameKind: String, CaseIterable, Identifiable, Codable {
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

    var unit: String {
        switch self {
        case .lienQuan: return "QH"
        case .freeFire: return "KC"
        case .fcMobile: return "FV"
        }
    }

    var rewards: [RewardItem] {
        switch self {
        case .lienQuan:
            return [
                RewardItem(title: "60 QH", amount: 60, weight: 34),
                RewardItem(title: "150 QH", amount: 150, weight: 28),
                RewardItem(title: "300 QH", amount: 300, weight: 19),
                RewardItem(title: "650 QH", amount: 650, weight: 11),
                RewardItem(title: "1.200 QH", amount: 1200, weight: 6),
                RewardItem(title: "2.500 QH", amount: 2500, weight: 2)
            ]
        case .freeFire:
            return [
                RewardItem(title: "70 KC", amount: 70, weight: 34),
                RewardItem(title: "140 KC", amount: 140, weight: 28),
                RewardItem(title: "290 KC", amount: 290, weight: 19),
                RewardItem(title: "580 KC", amount: 580, weight: 11),
                RewardItem(title: "1.150 KC", amount: 1150, weight: 6),
                RewardItem(title: "2.200 KC", amount: 2200, weight: 2)
            ]
        case .fcMobile:
            return [
                RewardItem(title: "100 FV", amount: 100, weight: 34),
                RewardItem(title: "200 FV", amount: 200, weight: 28),
                RewardItem(title: "450 FV", amount: 450, weight: 19),
                RewardItem(title: "950 FV", amount: 950, weight: 11),
                RewardItem(title: "1.800 FV", amount: 1800, weight: 6),
                RewardItem(title: "3.500 FV", amount: 3500, weight: 2)
            ]
        }
    }
}

enum AuthModeKind: String, CaseIterable, Identifiable, Codable {
    case facebook = "Facebook"
    case google = "Google"
    case account = "Tài khoản"

    var id: String { rawValue }
}

struct ShopAccount: Codable, Identifiable {
    let id: UUID
    let username: String
    let password: String
    var balance: Int
    var quanHuy: Int
    var kimCuong: Int
    var fv: Int
}

struct ShopListing: Identifiable, Codable {
    let id: UUID
    let seller: String
    let game: GameKind
    let title: String
    let price: Int
    let authType: AuthModeKind
    let imageData: Data?
}

struct SliceShape: Shape {
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

struct ImagePickerSheet: UIViewControllerRepresentable {
    let onPicked: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onPicked: (UIImage?) -> Void

        init(onPicked: @escaping (UIImage?) -> Void) {
            self.onPicked = onPicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let img = info[.originalImage] as? UIImage
            onPicked(img)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onPicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

struct ContentView: View {
    private let accountsKey = "shop_accounts_store_v3"
    private let currentUserKey = "shop_current_user_v3"
    private let listingsKey = "shop_listings_store_v3"
    private let darkThemeKey = "shop_dark_theme_v3"
    private let showRatesKey = "shop_show_rates_v3"
    private let hapticKey = "shop_haptic_v3"

    @State private var accounts: [ShopAccount] = []
    @State private var currentUsername: String = ""
    @State private var listings: [ShopListing] = []

    @State private var isDarkMode: Bool = true
    @State private var showRates: Bool = true
    @State private var hapticOn: Bool = true

    @State private var registerMode: Bool = false
    @State private var inputUser: String = ""
    @State private var inputPass: String = ""
    @State private var inputPass2: String = ""
    @State private var authError: String?

    @State private var tabIndex: Int = 0
    @State private var filterGame: GameKind? = nil

    @State private var spinGame: GameKind = .lienQuan
    @State private var wheelDeg: Double = 0
    @State private var spinning: Bool = false
    @State private var spinText: String = "Chọn vòng quay rồi bấm Quay"

    @State private var postGame: GameKind = .lienQuan
    @State private var postTitle: String = ""
    @State private var postPrice: String = ""
    @State private var postAuth: AuthModeKind = .facebook
    @State private var pickerOpen: Bool = false
    @State private var previewImg: UIImage?
    @State private var pickedData: Data?
    @State private var postStatus: String?

    @State private var topUpMsg: String?
    @State private var settingMsg: String?

    private let topUpList = [10_000, 20_000, 50_000, 100_000, 200_000, 500_000]

    private var userIndex: Int? {
        accounts.firstIndex { $0.username.caseInsensitiveCompare(currentUsername) == .orderedSame }
    }

    private var activeUser: ShopAccount? {
        guard let idx = userIndex else { return nil }
        return accounts[idx]
    }

    private var bgColor: Color {
        isDarkMode ? Color(red: 0.07, green: 0.08, blue: 0.11) : Color(red: 0.97, green: 0.97, blue: 0.96)
    }

    private var cardColor: Color {
        isDarkMode ? Color(red: 0.14, green: 0.16, blue: 0.21) : Color.white
    }

    private var fieldColor: Color {
        isDarkMode ? Color(red: 0.09, green: 0.10, blue: 0.14) : Color(red: 0.93, green: 0.94, blue: 0.95)
    }

    private var textMain: Color {
        isDarkMode ? .white : Color(red: 0.12, green: 0.12, blue: 0.14)
    }

    private var textSub: Color {
        isDarkMode ? Color.white.opacity(0.72) : Color(red: 0.42, green: 0.42, blue: 0.46)
    }

    private var lineColor: Color {
        isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    private func tapHaptic() {
        guard hapticOn else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(isDarkMode ? Color(red: 0.22, green: 0.18, blue: 0.14) : Color(red: 0.22, green: 0.22, blue: 0.25))
                        .frame(width: 10)
                        .ignoresSafeArea()

                    if let u = activeUser {
                        mainView(user: u)
                    } else {
                        loginView
                    }
                }
            }
            .navigationTitle(activeUser == nil ? "Sổ Acc & Vòng Quay" : "Sổ • \(activeUser!.username)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if activeUser != nil {
                        Button("Thoát") {
                            tapHaptic()
                            currentUsername = ""
                            UserDefaults.standard.set("", forKey: currentUserKey)
                            inputPass = ""
                            authError = nil
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $pickerOpen) {
                ImagePickerSheet { img in
                    if let img = img {
                        let packed = packImage(img)
                        previewImg = packed.0
                        pickedData = packed.1
                        postStatus = "Đã nhận ảnh acc."
                    }
                }
            }
            .onAppear {
                loadStore()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private var loginView: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.orange)
                    Text("Sổ Acc & Vòng Quay")
                        .font(.title2.bold())
                        .foregroundColor(textMain)
                    Text(registerMode ? "Tạo tài khoản mới" : "Đăng nhập tài khoản")
                        .font(.subheadline)
                        .foregroundColor(textSub)
                }

                Picker("Chế độ", selection: $registerMode) {
                    Text("Đăng nhập").tag(false)
                    Text("Đăng ký").tag(true)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    TextField("Tên tài khoản", text: $inputUser)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(textMain)
                        .padding(12)
                        .background(fieldColor)
                        .cornerRadius(10)

                    SecureField("Mật khẩu", text: $inputPass)
                        .foregroundColor(textMain)
                        .padding(12)
                        .background(fieldColor)
                        .cornerRadius(10)

                    if registerMode {
                        SecureField("Nhập lại mật khẩu", text: $inputPass2)
                            .foregroundColor(textMain)
                            .padding(12)
                            .background(fieldColor)
                            .cornerRadius(10)
                    }

                    if let err = authError {
                        Text(err)
                            .font(.footnote.bold())
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: submitAuth) {
                        Text(registerMode ? "Tạo tài khoản" : "Vào sổ")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }
                .padding(14)
                .background(cardColor)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(lineColor, lineWidth: 1))
            }
            .padding(16)
        }
    }

    private func submitAuth() {
        tapHaptic()
        let u = inputUser.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = inputPass

        if u.count < 3 {
            authError = "Tên tài khoản ít nhất 3 ký tự."
            return
        }
        if p.count < 4 {
            authError = "Mật khẩu ít nhất 4 ký tự."
            return
        }

        if registerMode {
            if p != inputPass2 {
                authError = "Mật khẩu nhập lại không khớp."
                return
            }
            if accounts.contains(where: { $0.username.caseInsensitiveCompare(u) == .orderedSame }) {
                authError = "Tài khoản này đã tồn tại."
                return
            }
            let acc = ShopAccount(id: UUID(), username: u, password: p, balance: 0, quanHuy: 0, kimCuong: 0, fv: 0)
            accounts.append(acc)
            saveAccounts()
            currentUsername = acc.username
            UserDefaults.standard.set(acc.username, forKey: currentUserKey)
            authError = nil
        } else {
            guard let found = accounts.first(where: {
                $0.username.caseInsensitiveCompare(u) == .orderedSame && $0.password == p
            }) else {
                authError = "Sai tên tài khoản hoặc mật khẩu."
                return
            }
            currentUsername = found.username
            UserDefaults.standard.set(found.username, forKey: currentUserKey)
            authError = nil
        }
    }

    private func mainView(user: ShopAccount) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Số dư")
                            .font(.caption)
                            .foregroundColor(textSub)
                        Text(formatMoney(user.balance))
                            .font(.headline.bold())
                            .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        badgeBox(label: "QH", val: user.quanHuy, tint: .blue)
                        badgeBox(label: "KC", val: user.kimCuong, tint: .teal)
                        badgeBox(label: "FV", val: user.fv, tint: .orange)
                    }
                }
                .padding(12)
                .background(cardColor)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(lineColor, lineWidth: 1))

                ScrollView(.horizontal, showsIndicators: false) {
                    Picker("Mục", selection: $tabIndex) {
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
                .background(cardColor)
                .cornerRadius(12)

                switch tabIndex {
                case 0:
                    marketTab
                case 1:
                    wheelTab(user: user)
                case 2:
                    postTab
                case 3:
                    topUpTab
                default:
                    settingsTab(user: user)
                }
            }
            .padding(14)
        }
    }

    private func badgeBox(label: String, val: Int, tint: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(val)")
                .font(.caption.bold())
                .foregroundColor(tint)
            Text(label)
                .font(.caption2)
                .foregroundColor(textSub)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(fieldColor)
        .cornerRadius(8)
    }

    private var marketTab: some View {
        let shown: [ShopListing]
        if let fg = filterGame {
            shown = listings.filter { $0.game == fg }
        } else {
            shown = listings
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tin rao acc (\(shown.count))")
                    .font(.headline)
                    .foregroundColor(textMain)
                Spacer()
                Button("+ Đăng bán") {
                    tapHaptic()
                    tabIndex = 2
                }
                .font(.subheadline.bold())
                .foregroundColor(.orange)
            }

            if !listings.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button("Tất cả") {
                            filterGame = nil
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(filterGame == nil ? Color.orange : cardColor)
                        .foregroundColor(filterGame == nil ? .white : textMain)
                        .cornerRadius(12)

                        ForEach(GameKind.allCases) { g in
                            Button(g.rawValue) {
                                filterGame = g
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(filterGame == g ? Color.orange : cardColor)
                            .foregroundColor(filterGame == g ? .white : textMain)
                            .cornerRadius(12)
                        }
                    }
                }
            }

            if shown.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("Chưa có acc nào")
                        .font(.subheadline.bold())
                        .foregroundColor(textMain)
                    Text("Vào mục Đăng bán để chọn ảnh và đăng tin.")
                        .font(.caption)
                        .foregroundColor(textSub)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(cardColor)
                .cornerRadius(16)
            } else {
                ForEach(shown) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        if
