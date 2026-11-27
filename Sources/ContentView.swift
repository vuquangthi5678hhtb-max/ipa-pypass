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
                        if let d = item.imageData, let ui = UIImage(data: d) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: 220)
                                .background(fieldColor)
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(fieldColor)
                                .frame(height: 120)
                                .overlay(Text(item.game.rawValue).foregroundColor(textSub))
                        }

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(textMain)
                                Text("\(item.game.rawValue) • Đăng nhập: \(item.authType.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(textSub)
                            }
                            Spacer()
                            Text(formatMoney(item.price))
                                .font(.headline.bold())
                                .foregroundColor(.orange)
                        }

                        HStack {
                            Text("Bởi \(item.seller)")
                                .font(.caption)
                                .foregroundColor(textSub)
                            Spacer()
                            if item.seller.caseInsensitiveCompare(currentUsername) == .orderedSame {
                                Button("Xóa") {
                                    tapHaptic()
                                    listings.removeAll { $0.id == item.id }
                                    saveListings()
                                }
                                .font(.caption.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.14))
                                .cornerRadius(12)
                            }
                            Button("Mua") {
                                tapHaptic()
                                guard let idx = userIndex else { return }
                                if accounts[idx].balance >= item.price {
                                    accounts[idx].balance -= item.price
                                    saveAccounts()
                                    listings.removeAll { $0.id == item.id }
                                    saveListings()
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
                    .background(cardColor)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(lineColor, lineWidth: 1))
                }
            }
        }
    }

    private func sliceTint(_ i: Int) -> Color {
        let arr: [Color] = [
            Color(red: 0.22, green: 0.42, blue: 0.78),
            Color(red: 0.16, green: 0.62, blue: 0.56),
            Color(red: 0.78, green: 0.42, blue: 0.16),
            Color(red: 0.42, green: 0.28, blue: 0.74),
            Color(red: 0.20, green: 0.54, blue: 0.86),
            Color(red: 0.74, green: 0.22, blue: 0.36)
        ]
        return arr[i % arr.count]
    }

    private func wheelTab(user: ShopAccount) -> some View {
        let items = spinGame.rewards
        let step = 360.0 / Double(items.count)

        return VStack(spacing: 14) {
            VStack(spacing: 8) {
                ForEach(GameKind.allCases) { g in
                    let sel = spinGame == g
                    Button(action: {
                        tapHaptic()
                        spinGame = g
                        spinText = "Vòng \(g.rawValue) • \(formatMoney(g.cost))/lượt"
                    }) {
                        HStack {
                            Text(g.rawValue)
                                .font(.subheadline.bold())
                                .foregroundColor(textMain)
                            Spacer()
                            Text("\(formatMoney(g.cost))/lượt")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(sel ? Color.orange : fieldColor)
                                .foregroundColor(sel ? .white : textMain)
                                .cornerRadius(10)
                        }
                        .padding(10)
                        .background(sel ? Color.orange.opacity(0.14) : fieldColor)
                        .cornerRadius(12)
                    }
                    .disabled(spinning)
                }
            }

            ZStack {
                ZStack {
                    ForEach(0..<items.count, id: \.self) { i in
                        let a0 = -90.0 + Double(i) * step - step / 2.0
                        let a1 = a0 + step
                        let mid = (-90.0 + Double(i) * step) * Double.pi / 180.0
                        let rad: CGFloat = 74

                        SliceShape(startAngle: .degrees(a0), endAngle: .degrees(a1))
                            .fill(sliceTint(i))
                            .overlay(SliceShape(startAngle: .degrees(a0), endAngle: .degrees(a1)).stroke(Color.white.opacity(0.85), lineWidth: 1.5))

                        Text(items[i].title)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .offset(x: cos(mid) * rad, y: sin(mid) * rad)
                    }
                }
                .frame(width: 230, height: 230)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .rotationEffect(.degrees(wheelDeg))

                Circle()
                    .fill(cardColor)
                    .frame(width: 68, height: 68)
                    .overlay(Circle().stroke(Color.orange, lineWidth: 2))

                Text(spinGame.unit)
                    .font(.caption.bold())
                    .foregroundColor(textMain)
            }
            .overlay(alignment: .top) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .offset(y: -12)
            }
            .padding(.top, 10)

            Text(spinText)
                .font(.subheadline.bold())
                .foregroundColor(textMain)
                .multilineTextAlignment(.center)

            if showRates {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(items) { r in
                        HStack {
                            Text(r.title)
                                .font(.caption.bold())
                                .foregroundColor(textMain)
                            Spacer()
                            Text("\(r.weight)%")
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(fieldColor)
                        .cornerRadius(8)
                    }
                }
            }

            Button(action: runSpin) {
                Text(spinning ? "Đang quay..." : "Quay \(spinGame.rawValue) (-\(formatMoney(spinGame.cost)))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(spinning ? Color.orange.opacity(0.6) : Color.orange)
                    .cornerRadius(12)
            }
            .disabled(spinning)
        }
        .padding(14)
        .background(cardColor)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(lineColor, lineWidth: 1))
    }

    private func runSpin() {
        guard let idx = userIndex, !spinning else { return }
        tapHaptic()

        let cost = spinGame.cost
        if accounts[idx].balance < cost {
            spinText = "Không đủ số dư (\(formatMoney(cost))). Qua mục Nạp tiền."
            return
        }

        accounts[idx].balance -= cost
        saveAccounts()

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
        let curMod = wheelDeg.truncatingRemainder(dividingBy: 360.0)
        var diff = ((360.0 - targetDeg).truncatingRemainder(dividingBy: 360.0)) - curMod
        if diff < 0 { diff += 360.0 }
        let spinTotal = 1800.0 + diff + Double.random(in: -step * 0.2 ... step * 0.2)

        spinning = true
        spinText = "Đang quay \(spinGame.rawValue)..."

        withAnimation(.timingCurve(0.14, 0.88, 0.25, 1.0, duration: 2.2)) {
            wheelDeg += spinTotal
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
            guard let uIdx = userIndex else {
                spinning = false
                return
            }
            switch spinGame {
            case .lienQuan: accounts[uIdx].quanHuy += chosen.amount
            case .freeFire: accounts[uIdx].kimCuong += chosen.amount
            case .fcMobile: accounts[uIdx].fv += chosen.amount
            }
            saveAccounts()
            tapHaptic()
            spinText = "Trúng \(chosen.title)!"
            spinning = false
        }
    }

    private var postTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Đăng bán acc")
                .font(.headline)
                .foregroundColor(textMain)

            Picker("Game", selection: $postGame) {
                ForEach(GameKind.allCases) { g in
                    Text(g.rawValue).tag(g)
                }
            }
            .pickerStyle(.segmented)

            TextField("Tên / mô tả acc", text: $postTitle)
                .foregroundColor(textMain)
                .padding(12)
                .background(fieldColor)
                .cornerRadius(10)

            TextField("Giá bán (vd: 100000)", text: $postPrice)
                .keyboardType(.numberPad)
                .foregroundColor(textMain)
                .padding(12)
                .background(fieldColor)
                .cornerRadius(10)

            Picker("Cách đăng nhập", selection: $postAuth) {
                ForEach(AuthModeKind.allCases) { a in
                    Text(a.rawValue).tag(a)
                }
            }
            .pickerStyle(.segmented)

            Button(action: {
                tapHaptic()
                pickerOpen = true
            }) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(previewImg == nil ? "Chọn ảnh acc" : "Đổi ảnh acc")
                }
                .font(.subheadline.bold())
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(fieldColor)
                .cornerRadius(10)
            }

            if let img = previewImg {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 190)
                    .background(fieldColor)
                    .cornerRadius(12)
            }

            if let msg = postStatus {
                Text(msg)
                    .font(.caption.bold())
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }

            Button(action: savePost) {
                Text("Đăng lên màn chính")
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

    private func packImage(_ img: UIImage) -> (UIImage, Data?) {
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

    private func savePost() {
        tapHaptic()
        guard let u = activeUser else { return }
        let title = postTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let price = Int(postPrice.filter { $0.isNumber }) ?? 0
        if title.isEmpty {
            postStatus = "Nhập tên acc trước."
            return
        }
        if price <= 0 {
            postStatus = "Nhập giá hợp lệ."
            return
        }

        let item = ShopListing(
            id: UUID(),
            seller: u.username,
            game: postGame,
            title: title,
            price: price,
            authType: postAuth,
            imageData: pickedData
        )
        listings.insert(item, at: 0)
        saveListings()
        filterGame = nil
        postTitle = ""
        postPrice = ""
        previewImg = nil
        pickedData = nil
        postStatus = nil
        tabIndex = 0
    }

    private var topUpTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nạp tiền")
                .font(.headline)
                .foregroundColor(textMain)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(topUpList, id: \.self) { amt in
                    Button(action: {
                        tapHaptic()
                        guard let idx = userIndex else { return }
                        accounts[idx].balance += amt
                        saveAccounts()
                        topUpMsg = "Đã nạp +\(formatMoney(amt))."
                    }) {
                        Text("+ \(formatMoney(amt))")
                            .font(.subheadline.bold())
                            .foregroundColor(textMain)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(fieldColor)
                            .cornerRadius(10)
                    }
                }
            }

            if let m = topUpMsg {
                Text(m)
                    .font(.caption.bold())
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }
        }
        .padding(14)
        .background(cardColor)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(lineColor, lineWidth: 1))
    }

    private func settingsTab(user: ShopAccount) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cài đặt")
                .font(.headline)
                .foregroundColor(textMain)

            Picker("Giao diện", selection: $isDarkMode) {
                Text("Nền đen").tag(true)
                Text("Nền trắng").tag(false)
            }
            .pickerStyle(.segmented)
            .onChange(of: isDarkMode) { val in
                tapHaptic()
                UserDefaults.standard.set(val, forKey: darkThemeKey)
                settingMsg = val ? "Đã bật nền đen." : "Đã bật nền trắng."
            }

            Toggle("Hiện tỉ lệ vòng quay", isOn: $showRates)
                .tint(.orange)
                .foregroundColor(textMain)
                .onChange(of: showRates) { val in
                    UserDefaults.standard.set(val, forKey: showRatesKey)
                }

            Toggle("Rung phản hồi", isOn: $hapticOn)
                .tint(.orange)
                .foregroundColor(textMain)
                .onChange(of: hapticOn) { val in
                    UserDefaults.standard.set(val, forKey: hapticKey)
                }

            Text("Tài khoản: \(user.username) • Tin đăng: \(listings.count)")
                .font(.caption)
                .foregroundColor(textSub)

            Button(action: {
                tapHaptic()
                listings.removeAll()
                saveListings()
                settingMsg = "Đã xóa hết tin đăng."
            }) {
                Text("Xóa toàn bộ tin đăng")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red.opacity(0.14))
                    .cornerRadius(10)
            }

            if let sm = settingMsg {
                Text(sm)
                    .font(.caption.bold())
                    .foregroundColor(Color(red: 0.16, green: 0.78, blue: 0.44))
            }
        }
        .padding(14)
        .background(cardColor)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(lineColor, lineWidth: 1))
    }

    private func formatMoney(_ v: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return "\(f.string(from: NSNumber(value: v)) ?? "\(v)")đ"
    }

    private func loadStore() {
        if let d = UserDefaults.standard.data(forKey: accountsKey),
           let dec = try? JSONDecoder().decode([ShopAccount].self, from: d) {
            accounts = dec
        }
        currentUsername = UserDefaults.standard.string(forKey: currentUserKey) ?? ""
        if let d = UserDefaults.standard.data(forKey: listingsKey),
           let dec = try? JSONDecoder().decode([ShopListing].self, from: d) {
            listings = dec
        }
        if UserDefaults.standard.object(forKey: darkThemeKey) != nil {
            isDarkMode = UserDefaults.standard.bool(forKey: darkThemeKey)
        }
        if UserDefaults.standard.object(forKey: showRatesKey) != nil {
            showRates = UserDefaults.standard.bool(forKey: showRatesKey)
        }
        if UserDefaults.standard.object(forKey: hapticKey) != nil {
            hapticOn = UserDefaults.standard.bool(forKey: hapticKey)
        }
    }

    private func saveAccounts() {
        if let enc = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(enc, forKey: accountsKey)
        }
    }

    private func saveListings() {
        if let enc = try? JSONEncoder().encode(listings) {
            UserDefaults.standard.set(enc, forKey: listingsKey)
        }
    }
}
