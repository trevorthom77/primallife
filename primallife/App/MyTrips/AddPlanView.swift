import SwiftUI
import UIKit

struct AddPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var planTitle: String = ""
    @FocusState private var isTitleFocused: Bool
    @State private var planImage: UIImage?
    @State private var isShowingPhotoPicker = false
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var hasStartDate = false
    @State private var hasEndDate = false
    @State private var activeDatePicker: DatePickerType?

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
