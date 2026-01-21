import SwiftUI
import UIKit
import Supabase

private let planDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private struct NewPlan: Encodable {
    let title: String
    let startDate: Date
    let endDate: Date
    let tribeID: UUID
    let creatorID: UUID
    let imagePath: String?

    enum CodingKeys: String, CodingKey {
        case title
        case startDate = "start_date"
        case endDate = "end_date"
        case tribeID = "tribe_id"
        case creatorID = "creator_id"
        case imagePath = "image_path"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(planDateFormatter.string(from: startDate), forKey: .startDate)
        try container.encode(planDateFormatter.string(from: endDate), forKey: .endDate)
        try container.encode(tribeID, forKey: .tribeID)
        try container.encode(creatorID, forKey: .creatorID)
        if let imagePath {
            try container.encode(imagePath, forKey: .imagePath)
        }
    }
}

struct AddPlanView: View {
    let tribeID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var planTitle: String = ""
    @FocusState private var isTitleFocused: Bool
    @State private var planImage: UIImage?
    @State private var isShowingPhotoPicker = false
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var hasStartDate = false
    @State private var hasEndDate = false
    @State private var activeDatePicker: DatePickerType?
    @State private var isCreating = false

    private var isAddPlanEnabled: Bool {
        let trimmedTitle = planTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && hasStartDate && hasEndDate
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
                    Text("Plan title")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    TextField("What are you doing?", text: $planTitle)
                        .font(.travelDetail)
                        .foregroundStyle(Colors.primaryText)
                        .padding()
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isTitleFocused = false
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Plan photo")
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
                                if let image = planImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .clipped()
                                } else {
                                    Text("Add photo")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $isShowingPhotoPicker) {
                        PlanImagePicker(image: $planImage)
                            .ignoresSafeArea()
                    }

                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Dates")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    VStack(spacing: 12) {
                        dateButton(
                            title: "Start date",
                            placeholder: "Select start date",
                            date: startDate,
                            hasDate: hasStartDate,
                            type: .start
                        )
                        dateButton(
                            title: "End date",
                            placeholder: "Select end date",
                            date: endDate,
                            hasDate: hasEndDate,
                            type: .end
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button {
                    guard !isCreating else { return }
                    isCreating = true
                    Task {
                        await addPlan()
                        await MainActor.run {
                            isCreating = false
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Create Plan")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)

                        if isCreating {
                            ProgressView()
                                .tint(Colors.tertiaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Colors.accent)
                    .cornerRadius(16)
                }
                .disabled(!isAddPlanEnabled)
                .opacity(isAddPlanEnabled ? 1 : 0.6)
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .scrollDismissesKeyboard(.immediately)
        .contentShape(Rectangle())
        .onTapGesture {
            isTitleFocused = false
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .sheet(
            isPresented: Binding(
                get: { activeDatePicker != nil },
                set: { isPresented in
                    if !isPresented {
                        activeDatePicker = nil
                    }
                }
            )
        ) {
            if let picker = activeDatePicker {
                datePickerSheet(for: picker)
            }
        }
    }

    private func dateButton(
        title: String,
        placeholder: String,
        date: Date,
        hasDate: Bool,
        type: DatePickerType
    ) -> some View {
        Button {
            activeDatePicker = type
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                HStack {
                    Text(hasDate ? formattedDate(date) : placeholder)
                        .font(.travelBody)
                        .foregroundStyle(hasDate ? Colors.primaryText : Colors.secondaryText)

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

    @ViewBuilder
    private func datePickerSheet(for type: DatePickerType) -> some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("Done") {
                        confirmDate(for: type)
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                }

                DatePicker(
                    "",
                    selection: dateBinding(for: type),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .tint(Colors.accent)
            }
            .padding(20)
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
        .preferredColorScheme(.light)
    }

    private func dateBinding(for type: DatePickerType) -> Binding<Date> {
        switch type {
        case .start:
            return $startDate
        case .end:
            return $endDate
        }
    }

    private func confirmDate(for type: DatePickerType) {
        switch type {
        case .start:
            hasStartDate = true
        case .end:
            hasEndDate = true
        }

        activeDatePicker = nil
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    @MainActor
    private func addPlan() async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        let trimmedTitle = planTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, hasStartDate, hasEndDate else { return }

        do {
            let imagePath = try await uploadPlanPhotoIfNeeded(supabase: supabase, userID: userID)
            let payload = NewPlan(
                title: trimmedTitle,
                startDate: startDate,
                endDate: endDate,
                tribeID: tribeID,
                creatorID: userID,
                imagePath: imagePath
            )

            try await supabase
                .from("plans")
                .insert(payload)
                .execute()
            dismiss()
        } catch {
            return
        }
    }

    private func uploadPlanPhotoIfNeeded(supabase: SupabaseClient, userID: UUID) async throws -> String? {
        guard let planImage,
              let imageData = planImage.jpegData(compressionQuality: 0.9) else { return nil }

        let path = "\(userID)/plans/\(UUID().uuidString).jpg"

        try await supabase.storage
            .from("plan-photos")
            .upload(
                path,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        return path
    }
}

private enum DatePickerType {
    case start
    case end
}

private struct PlanImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
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
        private let parent: PlanImagePicker

        init(parent: PlanImagePicker) {
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
            parent.dismiss()
        }
    }
}
