import SwiftUI

struct BellView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    BellView()
}
