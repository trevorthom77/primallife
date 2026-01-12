import SwiftUI
import UIKit
import Combine
import CoreLocation
import MapboxMaps

struct MapTribeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingCreateForm = false

    private let exampleTrips: [(title: String, count: Int, imageName: String)] = [
        ("Beach Hike in Maui", 92, "maui"),
        ("Island Hopping in Fiji", 124, "fiji"),
        ("Lagoon Escape in Aruba", 117, "aruba"),
        ("Surf Trip in Costa Rica", 101, "costa rica"),
        ("Sailing the Bahamas", 139, "bahamas"),
        ("Snorkel Week in Belize", 86, "belize")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                Text("Create a Map Tribe")
                    .font(.customTitle)
                    .foregroundStyle(Colors.primaryText)

                Text("Your tribe shows up on the map wherever your plans take place.")
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)

                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(exampleTrips, id: \.title) { example in
                        VStack(alignment: .leading, spacing: 14) {
                            AssetAsyncImage(name: example.imageName)
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Text(example.title)
                                .font(.tripsfont)
                                .foregroundStyle(Colors.primaryText)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: -8) {
                                Image("profile4")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile5")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile6")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile9")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                ZStack {
                                    Circle()
                                        .fill(Colors.background)
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Circle()
                                                .stroke(Colors.card, lineWidth: 3)
                                        }

                                    Text("\(example.count)+")
                                        .font(.badgeDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    isShowingCreateForm = true
                }) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingCreateForm) {
            MapTribeCreateFormView()
        }
    }
}

private struct AssetAsyncImage: View {
    let name: String

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { proxy in
            let pixelWidth = Int(proxy.size.width * displayScale)
            let pixelHeight = Int(proxy.size.height * displayScale)

            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.clear
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .task(id: "\(pixelWidth)x\(pixelHeight)") {
                await loadImage(pixelWidth: pixelWidth, pixelHeight: pixelHeight)
            }
        }
    }

    private func loadImage(pixelWidth: Int, pixelHeight: Int) async {
        guard pixelWidth > 0, pixelHeight > 0, image == nil else { return }
        let name = name
        let targetSize = CGSize(width: pixelWidth, height: pixelHeight)
        let renderedImage = await Task.detached(priority: .userInitiated) {
            let baseImage = UIImage(named: name)
            return baseImage?.preparingThumbnail(of: targetSize) ?? baseImage
        }.value
        await MainActor.run {
            image = renderedImage
        }
    }
}

private struct MapTribeCreateFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName: String = ""
    @State private var isShowingDetails = false
    @State private var groupPhoto: UIImage?
    @State private var groupPhotoData: Data?
    @State private var isShowingPhotoPicker = false
    @FocusState private var isGroupNameFocused: Bool
    private let nameLimit = 60
    private let unsplashURL = URL(string: "https://unsplash.com")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name your tribe")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    VStack(spacing: 8) {
                        TextField("Group name", text: $groupName)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .focused($isGroupNameFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                isGroupNameFocused = false
                            }
                            .onChange(of: groupName) { _, newValue in
                                if newValue.count > nameLimit {
                                    groupName = String(newValue.prefix(nameLimit))
                                }
                            }

                        HStack {
                            Text("Up to \(nameLimit) characters")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                            Spacer()
                            Text("\(groupName.count)/\(nameLimit)")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tribe photo")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    Button {
                        isShowingPhotoPicker = true
                    } label: {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Colors.card)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if let image = groupPhoto {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .clipped()
                                } else {
                                    VStack(spacing: 8) {
                                        Text("Add photo")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)

                                        Text("Tap to upload a cover for this tribe.")
                                            .font(.travelBody)
                                            .foregroundStyle(Colors.secondaryText)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $isShowingPhotoPicker) {
                        CroppingImagePicker(image: $groupPhoto, imageData: $groupPhotoData)
                            .ignoresSafeArea()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Use free, beautiful photos from Unsplash for your tribe image.")
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)

                        Link(destination: unsplashURL) {
                            HStack {
                                Spacer()
                                Image("unsplashblack")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 28)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .contentShape(Rectangle())
        .onTapGesture {
            isGroupNameFocused = false
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    isShowingDetails = true
                }) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .disabled(!isContinueEnabled)
                .opacity(isContinueEnabled ? 1 : 0.6)
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingDetails) {
            MapTribeDetailsView()
        }
    }

    private var isContinueEnabled: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && groupPhoto != nil
    }
}

private struct MapTribeDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var aboutText: String = ""
    @State private var isShowingLocation = false
    @State private var selectedInterests: Set<String> = []
    @FocusState private var isAboutFocused: Bool
    private let interests = InterestOptions.all
    private let interestsLimit = 6

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("About this tribe")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    ZStack(alignment: .topLeading) {
                        if aboutText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Share what travelers should know about this tribe.")
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $aboutText)
                            .font(.travelBody)
                            .foregroundStyle(Colors.primaryText)
                            .padding(12)
                            .frame(height: 140)
                            .scrollContentBackground(.hidden)
                            .focused($isAboutFocused)
                    }
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Interests")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(interests, id: \.self) { interest in
                            let isSelected = selectedInterests.contains(interest)

                            Button(action: {
                                toggleInterest(interest)
                            }) {
                                Text(interest)
                                    .font(isSelected ? .custom(Fonts.semibold, size: 18) : .travelBody)
                                    .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? Colors.accent : Colors.card)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .contentShape(Rectangle())
        .onTapGesture {
            isAboutFocused = false
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    isShowingLocation = true
                }) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .disabled(!isContinueEnabled)
                .opacity(isContinueEnabled ? 1 : 0.6)
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingLocation) {
            MapTribeLocationView()
        }
    }

    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else if selectedInterests.count < interestsLimit {
            selectedInterests.insert(interest)
        }
    }

    private var isContinueEnabled: Bool {
        !aboutText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedInterests.isEmpty
    }
}

private struct MapTribeLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("mapSavedDestinationLatitude") private var savedDestinationLatitude: Double = 0
    @AppStorage("mapSavedDestinationLongitude") private var savedDestinationLongitude: Double = 0
    @AppStorage("mapHasSavedDestination") private var hasSavedDestination = false
    @State private var isShowingGender = false
    @State private var locationViewport: Viewport = .styleDefault
    @State private var hasCenteredMap = false
    @StateObject private var locationManager = MapTribeLocationManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                Text("Where is your tribe located")
                    .font(.travelTitle)
                    .foregroundStyle(Colors.primaryText)

                Map(viewport: $locationViewport) {
                }
                .ornamentOptions(
                    OrnamentOptions(
                        scaleBar: ScaleBarViewOptions(
                            position: .topLeading,
                            margins: .zero,
                            visibility: .hidden,
                            useMetricUnits: true
                        )
                    )
                )
                .mapStyle(
                    MapStyle(
                        uri: StyleURI(
                            rawValue: "mapbox://styles/trevorthom7/cmi6lppz6001i01sachln4nbu"
                        )!
                    )
                )
                .cameraBounds(
                    CameraBoundsOptions(
                        minZoom: 3.0
                    )
                )
                .frame(height: 500)
                .frame(maxWidth: .infinity)
                .background(Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .center) {
                    Image("map")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundStyle(Colors.secondaryText)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .onAppear {
            applySavedDestination()
            locationManager.requestPermission()
        }
        .onReceive(locationManager.$coordinate) { coordinate in
            guard !hasCenteredMap, let coordinate else { return }
            setInitialViewport(center: coordinate)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    isShowingGender = true
                }) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .navigationDestination(isPresented: $isShowingGender) {
            MapTribeGenderView()
        }
    }

    private func applySavedDestination() {
        guard hasSavedDestination else { return }
        let coordinate = CLLocationCoordinate2D(
            latitude: savedDestinationLatitude,
            longitude: savedDestinationLongitude
        )
        setInitialViewport(center: coordinate)
    }

    private func setInitialViewport(center coordinate: CLLocationCoordinate2D) {
        locationViewport = .camera(
            center: coordinate,
            zoom: 10,
            bearing: 0,
            pitch: 0
        )
        hasCenteredMap = true
    }
}

private final class MapTribeLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.last?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

private struct CroppingImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CroppingImagePicker

        init(parent: CroppingImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let selectedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            guard let selectedImage else {
                parent.dismiss()
                return
            }

            parent.image = selectedImage
            parent.imageData = selectedImage.jpegData(compressionQuality: 0.9)
            parent.dismiss()
        }
    }
}

private struct MapTribeGenderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGender: MapTribeGenderOption = .everyone
    @State private var showReturnPicker = false
    @State private var returnDate = Date()
    @State private var hasSelectedReturn = false
    private let genderOptions = MapTribeGenderOption.allCases
    
    private var accentColor: Color {
        selectedGender == .girlsOnly ? Colors.girlsPink : Colors.accent
    }

    private var tribeStartDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tribe dates")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    Text("Lock in when this tribe is traveling.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                }

                VStack(spacing: 12) {
                    Button(action: {
                        showReturnPicker = true
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tribe end date")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(hasSelectedReturn ? returnDateText : "When does the tribe wrap up?")
                                    .font(.travelBody)
                                    .foregroundStyle(hasSelectedReturn ? Colors.primaryText : Colors.secondaryText)

                                Spacer()
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Select gender")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    Text("Choose who can join this tribe.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                }

                VStack(spacing: 12) {
                    ForEach(genderOptions) { option in
                        Button(action: {
                            selectedGender = option
                        }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(option.label)
                                    .font(.travelDetail)
                                    .foregroundStyle(selectedGenderTextColor(for: option))

                                Text(option.description)
                                    .font(.travelBody)
                                    .foregroundStyle(selectedGenderSubtextColor(for: option))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(selectedGender == option ? accentColor : Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {}) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(accentColor)
                        .cornerRadius(16)
                }
                .disabled(!isContinueEnabled)
                .opacity(isContinueEnabled ? 1 : 0.6)
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .sheet(isPresented: $showReturnPicker) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        Spacer()

                        Button("Done") {
                            showReturnPicker = false
                            hasSelectedReturn = true
                        }
                        .font(.travelDetail)
                        .foregroundStyle(Colors.accent)
                    }

                    DatePicker(
                        "",
                        selection: $returnDate,
                        in: tribeStartDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .tint(Colors.accent)
                    .onChange(of: returnDate) {
                        hasSelectedReturn = true
                    }
                }
                .padding(20)
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
            .preferredColorScheme(.light)
        }
    }

    private func selectedGenderTextColor(for option: MapTribeGenderOption) -> Color {
        option == selectedGender ? Colors.tertiaryText : Colors.primaryText
    }

    private func selectedGenderSubtextColor(for option: MapTribeGenderOption) -> Color {
        option == selectedGender ? Colors.tertiaryText.opacity(0.9) : Colors.secondaryText
    }

    private var returnDateText: String {
        returnDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var isContinueEnabled: Bool {
        hasSelectedReturn && returnDate >= tribeStartDate
    }
}

private enum MapTribeGenderOption: String, CaseIterable, Identifiable {
    case everyone = "Everyone"
    case girlsOnly = "Girls Only"
    case boysOnly = "Boys Only"

    var id: String { rawValue }
    var label: String { rawValue }
    var description: String {
        switch self {
        case .everyone:
            return "Open to all travelers."
        case .girlsOnly:
            return "Only women travelers can join."
        case .boysOnly:
            return "Only men travelers can join."
        }
    }
}
