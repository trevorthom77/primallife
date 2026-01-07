import SwiftUI

struct TravelStatsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Colors.background
                .ignoresSafeArea()
            
            BackButton {
                dismiss()
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
    }
}
