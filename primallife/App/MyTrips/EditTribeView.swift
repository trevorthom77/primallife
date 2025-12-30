import SwiftUI

struct EditTribeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()

                    Button("Update") { }
                        .font(.travelDetail)
                        .foregroundStyle(Colors.accent)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .buttonStyle(.plain)
                }

                Text("Edit Tribe")
                    .font(.customTitle)
                    .foregroundStyle(Colors.primaryText)
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
}
