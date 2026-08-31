import Foundation

@MainActor
class GeminiService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing: Bool = false
    @Published var currentActionStatus: String? = nil
    
    // Internal conversation history in native Gemini JSON format (preserves all thought_signatures and functionCall parts)
    private var geminiHistory: [[String: Any]] = []
    
    // Tools declaration in native Gemini schema
    private let toolDeclarations: [[String: Any]] = [
        [
            "functionDeclarations": [
                [
                    "name": "fetch_events",
                    "description": "Fetches events from the Apple Calendar between the specified start and end dates.",
                    "parameters": [
                        "type": "OBJECT",
                        "properties": [
                            "start_date": ["type": "STRING", "description": "Start date in ISO8601 format (e.g. 2026-08-31T00:00:00Z)"],
                            "end_date": ["type": "STRING", "description": "End date in ISO8601 format (e.g. 2026-08-31T23:59:59Z)"]
                        ],
                        "required": ["start_date", "end_date"]
                    ]
                ],
                [
                    "name": "create_event",
                    "description": "Creates a new event in the Apple Calendar.",
                    "parameters": [
                        "type": "OBJECT",
                        "properties": [
                            "title": ["type": "STRING", "description": "Title/Summary of the event"],
                            "start_date": ["type": "STRING", "description": "Start date and time in ISO8601 format"],
                            "end_date": ["type": "STRING", "description": "End date and time in ISO8601 format"],
                            "notes": ["type": "STRING", "description": "Optional notes or description for the event"],
                            "location": ["type": "STRING", "description": "Optional location/room or address"]
                        ],
                        "required": ["title", "start_date", "end_date"]
                    ]
                ],
                [
                    "name": "update_event",
                    "description": "Updates an existing event in the Apple Calendar by its unique identifier.",
                    "parameters": [
                        "type": "OBJECT",
                        "properties": [
                            "identifier": ["type": "STRING", "description": "The unique identifier of the event to update"],
                            "new_title": ["type": "STRING", "description": "New title of the event if changed"],
                            "new_start_date": ["type": "STRING", "description": "New start date in ISO8601 format if changed"],
                            "new_end_date": ["type": "STRING", "description": "New end date in ISO8601 format if changed"]
                        ],
                        "required": ["identifier"]
                    ]
                ],
                [
                    "name": "delete_event",
                    "description": "Deletes an event from the Apple Calendar given its identifier.",
                    "parameters": [
                        "type": "OBJECT",
                        "properties": [
                            "identifier": ["type": "STRING", "description": "The unique identifier of the event to delete"]
                        ],
                        "required": ["identifier"]
                    ]
                ]
            ]
        ]
    ]
    
    func clearHistory() {
        messages.removeAll()
        geminiHistory.removeAll()
    }
    
    func sendMessage(_ text: String, apiKey: String, model: String) async {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            messages.append(ChatMessage(
                role: .system,
                content: "⚠️ Please configure your Google Gemini API Key from Google AI Studio in Settings.",
                isError: true
            ))
            return
        }
        
        // Append user UI message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        
        // Append to native Gemini history
        geminiHistory.append([
            "role": "user",
            "parts": [
                ["text": text]
            ]
        ])
        
        isProcessing = true
        currentActionStatus = "Consulting Gemini..."
        
        let chosenModel = model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "gemini-2.0-flash" : model.trimmingCharacters(in: .whitespacesAndNewlines)
        await processChatLoop(apiKey: cleanKey, model: chosenModel)
        
        isProcessing = false
        currentActionStatus = nil
    }
    
    private func getSystemPrompt() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        dateFormatter.timeZone = TimeZone.current
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
        
        let tzName = TimeZone.current.identifier
        
        return """
        You are CalendarAI, an ultra-fast, intelligent native macOS calendar assistant powered by Google Gemini.
        Current Local Time: \(dateFormatter.string(from: now))
        Current ISO8601: \(isoFormatter.string(from: now))
        Time Zone: \(tzName)

        Guidelines:
        1. When the user asks to schedule, view, change, or remove events, ALWAYS call the appropriate tool.
        2. Keep token usage minimal and concise. Provide crisp, clear answers.
        3. For relative dates (e.g. 'tomorrow', 'next Monday at 2pm', 'today at 4pm', 'this week'), calculate exact ISO8601 timestamps using the local time above.
        4. If the duration isn't specified, default to 1 hour (e.g. 2:00 PM to 3:00 PM).
        5. After tool results are received, summarize calendar operations clearly.
        """
    }
    
    private func processChatLoop(apiKey: String, model: String, recursionDepth: Int = 0) async {
        if recursionDepth > 5 {
            messages.append(ChatMessage(
                role: .system,
                content: "⚠️ Tool execution limit reached. Please try asking again.",
                isError: true
            ))
            return
        }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            messages.append(ChatMessage(role: .system, content: "❌ Invalid URL for model \(model)", isError: true))
            return
        }
        
        let systemInstruction: [String: Any] = [
            "parts": [
                ["text": getSystemPrompt()]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "systemInstruction": systemInstruction,
            "contents": geminiHistory,
            "tools": toolDeclarations,
            "generationConfig": [
                "temperature": 0.1
            ]
        ]
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorObj = errorJson["error"] as? [String: Any],
                   let message = errorObj["message"] as? String {
                    messages.append(ChatMessage(
                        role: .system,
                        content: "❌ Gemini API Error (\(httpResponse.statusCode)): \(message)",
                        isError: true
                    ))
                } else {
                    let rawBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                    messages.append(ChatMessage(
                        role: .system,
                        content: "❌ Gemini API Error (\(httpResponse.statusCode)): \(rawBody)",
                        isError: true
                    ))
                }
                return
            }
            
            guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = jsonResponse["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]] else {
                messages.append(ChatMessage(
                    role: .system,
                    content: "⚠️ No valid response received from Gemini.",
                    isError: true
                ))
                return
            }
            
            // Crucial: Append the EXACT model response content into geminiHistory to preserve thought_signatures and metadata!
            geminiHistory.append(content)
            
            // Check for function calls or text in parts
            var functionCallsToExecute: [(name: String, args: [String: Any])] = []
            var combinedText = ""
            
            for part in parts {
                if let functionCall = part["functionCall"] as? [String: Any],
                   let funcName = functionCall["name"] as? String {
                    let args = (functionCall["args"] as? [String: Any]) ?? [:]
                    functionCallsToExecute.append((name: funcName, args: args))
                }
                if let text = part["text"] as? String, !text.isEmpty {
                    combinedText += text
                }
            }
            
            // If there are function calls, execute them
            if !functionCallsToExecute.isEmpty {
                var responseParts: [[String: Any]] = []
                
                for (funcName, args) in functionCallsToExecute {
                    currentActionStatus = "Executing \(funcName.replacingOccurrences(of: "_", with: " "))..."
                    let toolResult = executeToolByName(name: funcName, args: args)
                    
                    // Add UI tool message with event preview cards
                    let resultMsg = ChatMessage(
                        role: .tool,
                        content: toolResult.summaryStr,
                        name: funcName,
                        events: toolResult.events
                    )
                    messages.append(resultMsg)
                    
                    // Add native Gemini functionResponse part
                    responseParts.append([
                        "functionResponse": [
                            "name": funcName,
                            "response": [
                                "name": funcName,
                                "content": toolResult.resultObject
                            ]
                        ]
                    ])
                }
                
                // Append function response turn to geminiHistory with role 'user'
                geminiHistory.append([
                    "role": "user",
                    "parts": responseParts
                ])
                
                currentActionStatus = "Synthesizing answer..."
                await processChatLoop(apiKey: apiKey, model: model, recursionDepth: recursionDepth + 1)
            } else if !combinedText.isEmpty {
                // Final text response
                let assistantMsg = ChatMessage(
                    role: .assistant,
                    content: combinedText
                )
                messages.append(assistantMsg)
            }
            
        } catch {
            print("Gemini native request failed: \(error)")
            messages.append(ChatMessage(
                role: .system,
                content: "❌ Network error: \(error.localizedDescription)",
                isError: true
            ))
        }
    }
    
    private func executeToolByName(name: String, args: [String: Any]) -> (resultObject: Any, summaryStr: String, events: [CalendarEventInfo]) {
        let service = CalendarService.shared
        
        do {
            switch name {
            case "fetch_events":
                let start = args["start_date"] as? String ?? ""
                let end = args["end_date"] as? String ?? ""
                let events = service.fetchEvents(startDate: start, endDate: end)
                
                let eventsDicts = events.map { ev -> [String: Any] in
                    [
                        "identifier": ev.id,
                        "title": ev.title,
                        "startDate": ISO8601DateFormatter().string(from: ev.startDate),
                        "endDate": ISO8601DateFormatter().string(from: ev.endDate),
                        "location": ev.location ?? "",
                        "notes": ev.notes ?? "",
                        "calendar": ev.calendarName ?? ""
                    ]
                }
                return (eventsDicts, "Fetched \(events.count) event(s)", events)
                
            case "create_event":
                let title = args["title"] as? String ?? "New Event"
                let start = args["start_date"] as? String ?? ""
                let end = args["end_date"] as? String ?? ""
                let notes = args["notes"] as? String
                let loc = args["location"] as? String
                
                let event = try service.createEvent(title: title, startDate: start, endDate: end, notes: notes, location: loc)
                let resp: [String: Any] = [
                    "status": "success",
                    "identifier": event.id,
                    "title": event.title,
                    "startDate": ISO8601DateFormatter().string(from: event.startDate),
                    "endDate": ISO8601DateFormatter().string(from: event.endDate)
                ]
                return (resp, "Created '\(event.title)'", [event])
                
            case "update_event":
                let id = args["identifier"] as? String ?? ""
                let title = args["new_title"] as? String
                let start = args["new_start_date"] as? String
                let end = args["new_end_date"] as? String
                
                let event = try service.updateEvent(identifier: id, newTitle: title, newStartDate: start, newEndDate: end)
                let resp: [String: Any] = [
                    "status": "success",
                    "identifier": event.id,
                    "updatedTitle": event.title
                ]
                return (resp, "Updated '\(event.title)'", [event])
                
            case "delete_event":
                let id = args["identifier"] as? String ?? ""
                let success = try service.deleteEvent(identifier: id)
                let resp: [String: Any] = ["status": success ? "success" : "failed", "deletedIdentifier": id]
                return (resp, success ? "Deleted event" : "Failed to delete", [])
                
            default:
                return (["error": "Unknown tool name: \(name)"], "Unknown tool", [])
            }
        } catch {
            return (["error": error.localizedDescription], "Error: \(error.localizedDescription)", [])
        }
    }
    
    // Test connection helper for Settings
    func testConnection(apiKey: String, model: String) async -> Result<String, Error> {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            return .failure(NSError(domain: "Gemini", code: 400, userInfo: [NSLocalizedDescriptionKey: "API Key cannot be empty"]))
        }
        
        let testModel = model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "gemini-2.0-flash" : model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(testModel):generateContent?key=\(cleanKey)") else {
            return .failure(NSError(domain: "Gemini", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": "Hi! Reply 'OK'."]]
                ]
            ]
        ]
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorObj = errorJson["error"] as? [String: Any],
                   let message = errorObj["message"] as? String {
                    return .failure(NSError(domain: "Gemini", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message]))
                }
                let raw = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                return .failure(NSError(domain: "Gemini", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: raw]))
            }
            return .success("Connected to Gemini successfully!")
        } catch {
            return .failure(error)
        }
    }
}
