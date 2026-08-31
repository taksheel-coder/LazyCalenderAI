import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var geminiService = GeminiService()
    @StateObject private var calendarService = CalendarService.shared
    
    @State private var inputText: String = ""
    @AppStorage("geminiApiKey") private var geminiApiKey: String = ""
    @AppStorage("geminiModel") private var geminiModel: String = "gemini-2.0-flash"
    @AppStorage("isCustomModel") private var isCustomModel: Bool = false
    @AppStorage("customModelName") private var customModelName: String = ""
    
    @State private var showingSettings: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var effectiveModel: String {
        isCustomModel && !customModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? customModelName.trimmingCharacters(in: .whitespacesAndNewlines)
            : geminiModel
    }
    
    var body: some View {
        ZStack {
            // Main Chat Interface
            VStack(spacing: 0) {
                // Header Bar
                headerView
                
                Divider()
                    .opacity(0.3)
                
                // Chat / Content Area
                if geminiService.messages.isEmpty {
                    emptyStateView
                } else {
                    chatListView
                }
                
                // Status bar when processing
                if geminiService.isProcessing {
                    processingIndicator
                }
                
                Divider()
                    .opacity(0.3)
                
                // Input Bar
                inputBarView
            }
            .background(.ultraThinMaterial)
            
            // In-Window Settings Overlay
            if showingSettings {
                SettingsView(isPresented: $showingSettings)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .zIndex(10)
            }
        }
        .frame(width: 390, height: 540)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            isInputFocused = true
            calendarService.checkCurrentAuthorization()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 8) {
            // App Icon & Title
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("CalendarAI")
                    .font(.system(size: 13, weight: .bold))
            }
            
            // Status Pill
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                
                Text(statusText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(10)
            
            Spacer()
            
            // Clear History Button
            if !geminiService.messages.isEmpty {
                Button(action: {
                    withAnimation {
                        geminiService.clearHistory()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear Chat History")
            }
            
            // Settings Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingSettings.toggle()
                }
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(showingSettings ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .help("Preferences")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.04))
    }
    
    private var statusColor: Color {
        if geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .red
        }
        if !calendarService.hasAccess {
            return .orange
        }
        return .green
    }
    
    private var statusText: String {
        if geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Set Gemini Key"
        }
        if !calendarService.hasAccess {
            return "No Cal Access"
        }
        return "Ready"
    }
    
    // MARK: - Empty / Welcome State
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer(minLength: 12)
                
                // Welcome Card
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.indigo.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("CalendarAI with Google Gemini")
                        .font(.system(size: 15, weight: .bold))
                    
                    Text("Ultra-efficient, lightweight calendar automation via Google AI Studio.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // Missing Setup Warnings
                if geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    setupPromptCard(
                        icon: "key.fill",
                        title: "Gemini API Key Required",
                        subtitle: "Tap to configure your free Google AI Studio API key",
                        action: {
                            withAnimation { showingSettings = true }
                        }
                    )
                } else if !calendarService.hasAccess {
                    setupPromptCard(
                        icon: "calendar.badge.exclamationmark",
                        title: "Calendar Permission Required",
                        subtitle: "Grant access to manage and view Apple Calendar events",
                        action: {
                            Task { await calendarService.requestAccess() }
                        }
                    )
                }
                
                // Quick Suggestion Chips
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Commands")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    suggestionButton("📅 What's on my schedule today?")
                    suggestionButton("⚡ Schedule Coffee with Alex tomorrow at 10 AM")
                    suggestionButton("🔍 Show all events for this week")
                    suggestionButton("📝 Create 'Deep Focus' block on Friday from 2 to 4 PM")
                }
                
                Spacer(minLength: 16)
            }
            .padding(16)
        }
    }
    
    private func setupPromptCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func suggestionButton(_ prompt: String) -> some View {
        Button(action: {
            inputText = prompt
            sendMessage()
        }) {
            HStack {
                Text(prompt)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Chat List View
    private var chatListView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(geminiService.messages) { msg in
                        MessageRowView(message: msg)
                            .id(msg.id)
                    }
                }
                .padding(14)
                .onChange(of: geminiService.messages.count) {
                    if let last = geminiService.messages.last {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Processing Indicator
    private var processingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            
            Text(geminiService.currentActionStatus ?? "Thinking...")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.08))
    }
    
    // MARK: - Input Bar
    private var inputBarView: some View {
        HStack(spacing: 8) {
            TextField("Ask CalendarAI anything...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
            
            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSendDisabled ? [Color.gray.opacity(0.3), Color.gray.opacity(0.3)] : [Color.blue, Color.indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(isSendDisabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.03))
    }
    
    private var isSendDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || geminiService.isProcessing
    }
    
    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !geminiService.isProcessing else { return }
        
        inputText = ""
        Task {
            await geminiService.sendMessage(trimmed, apiKey: geminiApiKey, model: effectiveModel)
        }
    }
}

// MARK: - Message Row View
struct MessageRowView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if message.role == .tool {
                if !message.events.isEmpty {
                    ForEach(message.events) { event in
                        EventCardView(event: event)
                    }
                }
            } else if message.role == .user {
                HStack {
                    Spacer(minLength: 40)
                    
                    Text(message.content ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if message.role == .assistant {
                HStack(alignment: .top, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.18))
                            .frame(width: 22, height: 22)
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.content ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.65))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    
                    Spacer(minLength: 20)
                }
            } else if message.role == .system {
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: message.isError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(message.isError ? .red : .blue)
                        
                        Text(message.content ?? "")
                            .font(.system(size: 11))
                            .foregroundColor(message.isError ? .red : .secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(message.isError ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    Spacer()
                }
            }
        }
    }
}
