import CalendarCore
import Combine
import Foundation
import SwiftUI

@MainActor
struct CalendarRootView: View {
    let model: CalendarViewModel

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("firstWeekday") private var firstWeekday = 2
    @AppStorage("eventTextSize") private var textSize = EventTextSize.standard

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            navigationBar
            Rectangle().fill(PlannerStyle.rule).frame(height: 1)
            if model.tab.page != nil {
                calendarPage
                    .simultaneousGesture(pageSwipe)
            } else if model.tab == .tasks {
                ContentUnavailableView("タスク機能は準備中です", systemImage: "checklist")
                    .frame(maxHeight: .infinity)
            } else {
                morePage
            }
            tabBar
        }
        .foregroundStyle(PlannerStyle.ink)
        .background(PlannerStyle.paper.ignoresSafeArea())
        .sheet(item: $model.sheet) { sheet in
            PlannerSheetView(sheet: sheet, date: model.selectedDate, dates: model.dates, onJump: model.jump)
        }
        .environment(\.locale, Locale(identifier: "ja_JP"))
        .environment(\.calendar, model.dates.calendar)
        .environment(\.timeZone, model.dates.calendar.timeZone)
        .onChange(of: firstWeekday, initial: true) { _, weekday in
            model.setFirstWeekday(weekday == 1 ? 1 : 2)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.updateClock() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            model.updateClock()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange).receive(on: RunLoop.main)) { _ in
            model.updateClock()
        }
    }

    @ViewBuilder
    private var calendarPage: some View {
        switch model.tab.page {
        case .month:
            MonthCalendarView(
                weeks: model.visibleWeeks, selection: model.selectedDate, today: model.today,
                dates: model.dates, events: model.visibleEvents, textSize: textSize,
                onSelect: model.select, onEvent: showEvent
            )
        case .week:
            WeekCalendarView(
                days: model.visibleWeeks.first ?? [], selection: model.selectedDate, today: model.today,
                dates: model.dates, events: model.visibleEvents, textSize: textSize,
                onSelect: model.select, onEvent: showEvent
            )
        case .day:
            DayCalendarView(
                date: model.selectedDate, today: model.today, dates: model.dates,
                events: model.visibleEvents, textSize: textSize, onEvent: showEvent
            )
        case nil:
            EmptyView()
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            if model.tab.page != nil {
                Button { model.sheet = .dateJump } label: {
                    HStack(spacing: 5) {
                        Text(periodTitle)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(periodInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(PlannerStyle.blue)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("日付を指定"))
                .accessibilityValue(Text(periodTitle))

                Spacer(minLength: 2)
                toolbarButton("chevron.left", label: "前のページ") { model.step(by: -1) }
                toolbarButton("chevron.right", label: "次のページ") { model.step(by: 1) }
                toolbarButton("plus", label: "予定を追加") { model.sheet = .add(model.selectedDate) }
            } else {
                Text(model.tab.rawValue)
                    .font(.title2.weight(.semibold))
                    .frame(minHeight: 44)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
        }
        .padding(.leading, PlannerStyle.pageInset)
        .padding(.trailing, 4)
        .padding(.vertical, 3)
    }

    private var periodTitle: String {
        let calendar = model.dates.calendar
        switch model.tab.page {
        case .month:
            return PlannerDateText.month(model.selectedDate, calendar: calendar)
        case .week:
            let days = model.dates.week(containing: model.selectedDate)
            guard let first = days.first, let last = days.last else { return "" }
            return "\(PlannerDateText.abbreviated(first, calendar: calendar)) – \(PlannerDateText.abbreviated(last, calendar: calendar))"
        case .day:
            return PlannerDateText.day(model.selectedDate, calendar: calendar)
        case nil:
            return model.tab.rawValue
        }
    }

    private var periodInk: Color {
        guard model.tab == .day else { return PlannerStyle.ink }
        let weekday = model.dates.calendar.component(.weekday, from: model.selectedDate)
        return PlannerStyle.dayInk(weekday: weekday, holiday: model.visibleEvents.contains { $0.calendar.isHoliday })
    }

    private func toolbarButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(PlannerStyle.blue)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(PlannerStyle.rule).frame(height: 1)
            HStack(spacing: 0) {
                ForEach(PlannerTab.allCases) { tab in
                    let selected = tab == model.tab
                    Button { model.selectTab(tab) } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.symbol).font(.system(size: 15, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                        }
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .foregroundStyle(selected ? PlannerStyle.blue : PlannerStyle.secondaryInk)
                        .background(selected ? PlannerStyle.selection : PlannerStyle.margin)
                        .overlay(alignment: .top) {
                            if selected { Rectangle().fill(PlannerStyle.blue).frame(height: 2) }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(tab.rawValue))
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                    .accessibilityHint(selected && tab.page != nil ? Text("もう一度タップすると今日に移動") : Text(""))
                }
            }
        }
        .background(PlannerStyle.margin.ignoresSafeArea(edges: .bottom))
    }

    private var morePage: some View {
        Form {
            Section("日付") {
                Button("今日へ", action: model.goToToday)
                Button("日付を指定") { model.sheet = .dateJump }
            }
            Section("カレンダーの表示") {
                Picker("週の開始曜日", selection: $firstWeekday) {
                    Text("月曜日").tag(2)
                    Text("日曜日").tag(1)
                }
                Picker("予定の文字サイズ", selection: $textSize) {
                    ForEach(EventTextSize.allCases) { size in Text(size.rawValue).tag(size) }
                }
            }
            .pickerStyle(.menu)
        }
        .scrollContentBackground(.hidden)
        .tint(PlannerStyle.blue)
    }

    private var pageSwipe: some Gesture {
        DragGesture(minimumDistance: 24).onEnded { value in
            let horizontal = value.translation.width
            let vertical = value.translation.height
            guard abs(horizontal) >= 46, abs(horizontal) > abs(vertical) * 1.35 else { return }
            model.step(by: horizontal < 0 ? 1 : -1)
        }
    }

    private func showEvent(_ event: CalendarEvent) {
        model.sheet = .event(event)
    }
}
