import Foundation

extension Date {
    /// Returns a localized string representing the date/time according to Clipmighty's rules:
    /// - Today: "HH:mm" (e.g., 10:30 AM)
    /// - Yesterday: "Yesterday, HH:mm"
    /// - Older: "D MMM, HH:mm" or "MMM D, HH:mm" (Locale aware)
    func relativeTimestamp() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            // Today: Only show the time component
            return self.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(self) {
            // Yesterday: "Yesterday, HH:mm"
            let time = self.formatted(date: .omitted, time: .shortened)
            return "Yesterday, \(time)"
        } else {
            // More than 2 days ago: Date + Time
            // .dateTime.day().month().hour().minute() automatically handles the order
            // based on the user's current locale (e.g., "Jan 17, 8:59 AM" vs "17 Jan, 08:59")
            return self.formatted(.dateTime.day().month().hour().minute())
        }
    }
}
