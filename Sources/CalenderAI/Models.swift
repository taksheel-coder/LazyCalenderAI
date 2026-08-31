import Foundation
import EventKit

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
    case tool
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: ChatRole
    let content: String?
    let toolCalls: [ToolCall]?
    let toolCallId: String?
    let name: String?
    let timestamp: Date
    
    // UI specifics
    var events: [CalendarEventInfo] = []
    var isError: Bool = false
    
    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String? = nil,
        toolCalls: [ToolCall]? = nil,
        toolCallId: String? = nil,
        name: String? = nil,
        events: [CalendarEventInfo] = [],
        isError: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
        self.name = name
        self.events = events
        self.isError = isError
        self.timestamp = timestamp
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

struct CalendarEventInfo: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let notes: String?
    let calendarName: String?
    let isAllDay: Bool
    
    init(ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title?.isEmpty == false ? ekEvent.title : "Untitled Event"
        self.startDate = ekEvent.startDate ?? Date()
        self.endDate = ekEvent.endDate ?? Date().addingTimeInterval(3600)
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.calendarName = ekEvent.calendar?.title
        self.isAllDay = ekEvent.isAllDay
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        notes: String? = nil,
        calendarName: String? = nil,
        isAllDay: Bool = false
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.calendarName = calendarName
        self.isAllDay = isAllDay
    }
}

// OpenAI-compatible Chat Completion structures for Gemini
struct GeminiMessage: Codable {
    let role: String
    let content: String?
    let name: String?
    let tool_calls: [ToolCall]?
    let tool_call_id: String?
}

struct ToolCall: Codable, Equatable {
    let id: String
    let type: String // always "function"
    let function: FunctionCall
}

struct FunctionCall: Codable, Equatable {
    let name: String
    let arguments: String // JSON string
}

struct GeminiRequest: Codable {
    let model: String
    let messages: [GeminiMessage]
    let tools: [ToolDefinition]?
    let tool_choice: String?
    let temperature: Double?
}

struct ToolDefinition: Codable {
    let type: String
    let function: FunctionDefinition
}

struct FunctionDefinition: Codable {
    let name: String
    let description: String
    let parameters: JSONSchema
}

struct JSONSchema: Codable {
    let type: String
    let properties: [String: JSONSchemaProperty]
    let required: [String]?
}

struct JSONSchemaProperty: Codable {
    let type: String
    let description: String?
    let items: JSONSchemaItems? // For array types
}

struct JSONSchemaItems: Codable {
    let type: String
}

struct GeminiResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: GeminiResponseMessage
    let finish_reason: String?
}

struct GeminiResponseMessage: Codable {
    let role: String?
    let content: String?
    let tool_calls: [ToolCall]?
}

struct GeminiModelOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let subtitle: String
    let badge: String
    let isRecommended: Bool
}

let availableGeminiModels: [GeminiModelOption] = [
    GeminiModelOption(
        id: "gemini-2.0-flash",
        displayName: "Gemini 2.0 Flash",
        subtitle: "Fastest & most versatile, high free tier quota",
        badge: "Recommended",
        isRecommended: true
    ),
    GeminiModelOption(
        id: "gemini-2.0-flash-lite",
        displayName: "Gemini 2.0 Flash-Lite",
        subtitle: "Minimal token usage & ultra lightweight",
        badge: "Lowest Tokens",
        isRecommended: false
    ),
    GeminiModelOption(
        id: "gemini-2.5-flash",
        displayName: "Gemini 2.5 Flash",
        subtitle: "Next-gen Flash model with deep reasoning",
        badge: "Smart & Fast",
        isRecommended: false
    ),
    GeminiModelOption(
        id: "gemini-1.5-flash-8b",
        displayName: "Gemini 1.5 Flash 8B",
        subtitle: "Ultra compact 8B model for high frequency usage",
        badge: "Economical",
        isRecommended: false
    ),
    GeminiModelOption(
        id: "gemini-1.5-flash",
        displayName: "Gemini 1.5 Flash",
        subtitle: "Battle-tested legacy flash model",
        badge: "Stable",
        isRecommended: false
    )
]
