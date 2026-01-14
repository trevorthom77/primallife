import SwiftUI

struct UpcomingTripsFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filterCheckInDate: Date?
    @Binding var filterReturnDate: Date?
    @State private var checkInDate: Date
    @State private var returnDate: Date
    @State private var hasCheckInDate: Bool
    @State private var hasReturnDate: Bool
    @State private var activeDatePicker: DatePickerType?

    init(filterCheckInDate: Binding<Date?>, filterReturnDate: Binding<Date?>) {
        _filterCheckInDate = filterCheckInDate
        _filterReturnDate = filterReturnDate
        let initialCheckIn = filterCheckInDate.wrappedValue ?? Date()
        let initialReturn = filterReturnDate.wrappedValue ?? Date()
        _checkInDate = State(initialValue: initialCheckIn)
        _returnDate = State(initialValue: initialReturn)
        _hasCheckInDate = State(initialValue: filterCheckInDate.wrappedValue != nil)
        _hasReturnDate = State(initialValue: filterReturnDate.wrappedValue != nil)
    }

    private enum DatePickerType {
        case checkIn
        case returnDate
    }

    private var isReturnDateInvalid: Bool {
        hasCheckInDate && hasReturnDate && returnDate < checkInDate
    }

    private var isUpdateEnabled: Bool {
        hasCheckInDate && hasReturnDate && !isReturnDateInvalid
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()

                    Button("Reset") {
                        resetFilters()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Trip Filters")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Shows travelers whose dates overlap your selected range.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(spacing: 12) {
                    Button {
                        activeDatePicker = .checkIn
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Check-in date")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(hasCheckInDate ? formattedDate(checkInDate) : "Select check-in date")
                                    .font(.travelBody)
                                    .foregroundStyle(hasCheckInDate ? Colors.primaryText : Colors.secondaryText)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button {
                        activeDatePicker = .returnDate
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Return date")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(hasReturnDate ? formattedDate(returnDate) : "Select return date")
                                    .font(.travelBody)
                                    .foregroundStyle(hasReturnDate ? Colors.primaryText : Colors.secondaryText)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    filterCheckInDate = checkInDate
                    filterReturnDate = returnDate
                    dismiss()
                } label: {
                    Text("Update")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isUpdateEnabled ? Colors.accent : Colors.accent.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(!isUpdateEnabled)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
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
        case .checkIn:
            return $checkInDate
        case .returnDate:
            return $returnDate
        }
    }

    private func confirmDate(for type: DatePickerType) {
        switch type {
        case .checkIn:
            hasCheckInDate = true
        case .returnDate:
            hasReturnDate = true
        }

        activeDatePicker = nil
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func resetFilters() {
        filterCheckInDate = nil
        filterReturnDate = nil
        hasCheckInDate = false
        hasReturnDate = false
        checkInDate = Date()
        returnDate = Date()
    }
}
