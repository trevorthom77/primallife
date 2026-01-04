import SwiftUI

struct AddPlanView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            Colors.background
                .ignoresSafeArea()

            HStack {
                BackButton {
                    dismiss()
                }

                Spacer()
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
    }
}
