import CalendarCore
import SwiftUI

struct PlannerSheetView: View {
    let sheet: PlannerSheet
    let dates: CalendarDateMath
    let onJump: (Date) -> Void

    @State private var draftDate: Date
    @Environment(\.dismiss) private var dismiss

    init(sheet: PlannerSheet, date: Date, dates: CalendarDateMath, onJump: @escaping (Date) -> Void) {
        self.sheet = sheet
        self.dates = dates
        self.onJump = onJump
        _draftDate = State(initialValue: date)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(isDateJump ? "キャンセル" : "閉じる") { dismiss() }
                    }
                    if isDateJump {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("移動") {
                                onJump(draftDate)
                                dismiss()
                            }
                        }
                    }
                }
        }
        .tint(PlannerStyle.blue)
    }

    @ViewBuilder
    private var content: some View {
        switch sheet {
        case .dateJump:
            ScrollView {
                DatePicker("移動先の日付", selection: $draftDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .accessibilityLabel(Text("移動先の日付"))
                    .frame(maxWidth: .infinity)
                    .padding(PlannerStyle.pageInset)
            }
        case .add(let date):
            ContentUnavailableView {
                Label("予定の追加は準備中です", systemImage: "calendar.badge.plus")
            } description: {
                Text(PlannerDateText.fullDate(date, calendar: dates.calendar))
            }
        case .event(let event):
            eventDetail(event)
        }
    }

    private var title: String {
        switch sheet {
        case .dateJump: return "日付を指定"
        case .add: return "新規予定"
        case .event: return "予定の詳細"
        }
    }

    private var isDateJump: Bool {
        if case .dateJump = sheet { return true }
        return false
    }

    private func eventDetail(_ event: CalendarEvent) -> some View {
        let calendar = dates.calendar
        return List {
            Section {
                Text(event.title)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Label(event.calendar.name, systemImage: "circle.fill")
                    .foregroundStyle(PlannerStyle.eventInk(event.calendar.tint))
            }
            Section("日時") {
                if event.isAllDay {
                    Label("終日", systemImage: "calendar")
                    Text(PlannerDateText.fullDate(event.start, calendar: calendar))
                    let lastDay = dates.addingDays(-1, to: event.end)
                    if !calendar.isDate(event.start, inSameDayAs: lastDay) {
                        LabeledContent("最終日", value: PlannerDateText.fullDate(lastDay, calendar: calendar))
                    }
                } else {
                    LabeledContent("開始", value: dateTime(event.start))
                    LabeledContent("終了", value: dateTime(event.end))
                }
            }
            if !event.location.isEmpty {
                Section("場所") { Text(event.location) }
            }
            if !event.notes.isEmpty {
                Section("メモ") { Text(event.notes) }
            }
        }
    }

    private func dateTime(_ date: Date) -> String {
        let calendar = dates.calendar
        return "\(PlannerDateText.fullDate(date, calendar: calendar)) \(PlannerDateText.time(date, calendar: calendar))"
    }
}
