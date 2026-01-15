import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .topLeading) {
            BackButton {
                dismiss()
            }
            .padding(.leading, 16)
            .padding(.top, 16)
        }
    }
}
