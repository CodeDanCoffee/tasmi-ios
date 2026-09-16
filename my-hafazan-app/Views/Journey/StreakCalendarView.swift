import SwiftUI

struct StreakCalendarView: View {
    let activeDays: Set<Date>
    private let columns = 7
    private let rows = 5

    var body: some View {
        HCard {
            VStack(spacing: HSpacing.sm) {
                // Day labels
                HStack(spacing: 4) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(HFont.caption)
                            .foregroundStyle(Color.hSubtext)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar grid
                let today = Calendar.current.startOfDay(for: Date())
                let calendar = Calendar.current

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(calendarDays(from: today), id: \.self) { date in
                        let isActive = activeDays.contains(calendar.startOfDay(for: date))
                        let isToday = calendar.isDateInToday(date)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(isActive ? Color.hOliveGreen : Color.hOliveGreen.opacity(0.08))
                            .frame(height: 24)
                            .overlay {
                                if isToday {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.hOliveGreen, lineWidth: 1.5)
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func calendarDays(from today: Date) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        let totalCells = rows * columns

        // Start from totalCells days ago
        for i in (0..<totalCells).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.append(date)
            }
        }
        return dates
    }
}
