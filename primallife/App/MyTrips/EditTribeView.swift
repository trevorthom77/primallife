import SwiftUI
import Supabase

struct EditTribeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    let tribeID: UUID?
    private let originalName: String
    private let onUpdate: ((String) -> Void)?
    @State private var tribeName: String
    @State private var isUpdating = false

    init(tribeID: UUID?, currentName: String, onUpdate: ((String) -> Void)? = nil) {
        self.tribeID = tribeID
        originalName = currentName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.onUpdate = onUpdate
        _tribeName = State(initialValue: currentName)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()

                    Button("Update") {
                        guard isUpdateEnabled else { return }
                        Task {
                            await updateTribeName()
                        }
                    }
                        .font(.travelDetail)
                        .foregroundStyle(Colors.accent)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .buttonStyle(.plain)
                        .disabled(!isUpdateEnabled || isUpdating)
                        .opacity(isUpdateEnabled && !isUpdating ? 1 : 0.6)
                }

                Text("Edit Tribe")
                    .font(.customTitle)
                    .foregroundStyle(Colors.primaryText)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tribe name")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    TextField("Enter tribe name", text: $tribeName)
                        .font(.travelDetail)
                        .foregroundStyle(Colors.primaryText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .submitLabel(.done)
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
    }

    private var trimmedName: String {
        tribeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isUpdateEnabled: Bool {
        !trimmedName.isEmpty && trimmedName != originalName
    }

    @MainActor
    private func updateTribeName() async {
        guard let supabase,
              let tribeID,
              let userID = supabase.auth.currentUser?.id else { return }

        let updatedName = trimmedName
        guard !updatedName.isEmpty, updatedName != originalName else { return }
        guard !isUpdating else { return }

        struct TribeNameUpdate: Encodable {
            let name: String
        }

        isUpdating = true
        defer { isUpdating = false }

        do {
            try await supabase
                .from("tribes")
                .update(TribeNameUpdate(name: updatedName))
                .eq("id", value: tribeID.uuidString)
                .eq("owner_id", value: userID.uuidString)
                .execute()

            onUpdate?(updatedName)
            dismiss()
        } catch {
            return
        }
    }
}
