import CalendarCore
import SwiftUI

@main
@MainActor
struct PaperCalendarApp: App {
    @State private var model = CalendarViewModel { now, dates in
        MockCalendarEventSource(anchor: now, dates: dates)
    }

    var body: some Scene {
        WindowGroup {
            CalendarRootView(model: model)
                .preferredColorScheme(.light)
        }
    }
}
