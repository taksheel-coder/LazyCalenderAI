import SwiftUI
import AppKit

struct EventCardView: View {
    let event: CalendarEventInfo
    @State private var isCopied: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Calendar accent indicator stripe
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                // Top row: Relative date badge & Calendar name
                HStack(alignment: .center, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .semibold))
                        Text(relativeDateString(for: event.startDate))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                    
                    if let cal = event.calendarName, !cal.isEmpty {
                        Text(cal)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    // Quick Action Buttons
                    Button(action: {
                        CalendarService.shared.openCalendarApp(for: event.startDate)
                    }) {
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open in Apple Calendar")
                    
                    Button(action: {
                        copyEventToClipboard()
                    }) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(isCopied ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy event summary")
                }
                
                // Title (No truncation)
                Text(event.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                
                // Time range & Duration
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if event.isAllDay {
                        Text("All-day event")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(timeFormatter.string(from: event.startDate)) – \(timeFormatter.string(from: event.endDate))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("• \(durationString(from: event.startDate, to: event.endDate))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
                
                // Location if available
                if let location = event.location, !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                        
                        Text(location)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }
                }
                
                // Notes if available
                if let notes = event.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding(.top, 2)
                        
                        Text(notes)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(3)
                    }
                    .padding(6)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(6)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func copyEventToClipboard() {
        let details = """
        \(event.title)
        Date: \(dateFormatter.string(from: event.startDate))
        Time: \(timeFormatter.string(from: event.startDate)) - \(timeFormatter.string(from: event.endDate))
        \(event.location != nil ? "Location: \(event.location!)" : "")
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(details, forType: .string)
        
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
    
    private func relativeDateString(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let df = DateFormatter()
            df.dateFormat = "EEE, MMM d"
            return df.string(from: date)
        }
    }
    
    private func durationString(from start: Date, to end: Date) -> String {
        let minutes = Int(end.timeIntervalSince(start) / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else if minutes % 60 == 0 {
            return "\(minutes / 60)h"
        } else {
            let h = minutes / 60
            let m = minutes % 60
            return "\(h)h \(m)m"
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()
