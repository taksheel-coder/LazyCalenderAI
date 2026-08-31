import SwiftUI
import AppKit

struct SettingsView: View {
    @Binding var isPresented: Bool
    @AppStorage("geminiApiKey") private var geminiApiKey: String = ""
    @AppStorage("geminiModel") private var geminiModel: String = "gemini-2.0-flash"
    @AppStorage("isCustomModel") private var isCustomModel: Bool = false
    @AppStorage("customModelName") private var customModelName: String = ""
    
    @StateObject private var calendarService = CalendarService.shared
    @StateObject private var geminiService = GeminiService()
    
    @State private var isKeyVisible: Bool = false
    @State private var testStatus: String? = nil
    @State private var isTesting: Bool = false
    @State private var isTestSuccess: Bool = false
    
    var activeModelString: String {
        isCustomModel && !customModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? customModelName.trimmingCharacters(in: .whitespacesAndNewlines)
            : geminiModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                    Text("Gemini & Calendar Preferences")
                        .font(.system(size: 14, weight: .bold))
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.05))
            
            Divider()
            
            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Section 1: Google Gemini API Key
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Google Gemini API Key")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("From Google AI Studio (Free Tier)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Link("Get Key ↗", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        HStack(spacing: 6) {
                            if isKeyVisible {
                                TextField("AIzaSy...", text: $geminiApiKey)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, design: .monospaced))
                            } else {
                                SecureField("AIzaSy...", text: $geminiApiKey)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, design: .monospaced))
                            }
                            
                            Button(action: { isKeyVisible.toggle() }) {
                                Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        
                        // Test connection row
                        HStack(spacing: 8) {
                            Button(action: runConnectionTest) {
                                HStack(spacing: 4) {
                                    if isTesting {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 10))
                                    }
                                    Text(isTesting ? "Testing..." : "Test Connection")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.08))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(isTesting || geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            if let testStatus = testStatus {
                                Text(testStatus)
                                    .font(.system(size: 11))
                                    .foregroundColor(isTestSuccess ? .green : .red)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    
                    // Section 2: Gemini Model Selection (Low Token Footprint)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gemini Model")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("Select a low token consumption model")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("Custom", isOn: $isCustomModel)
                                .toggleStyle(.switch)
                                .controlSize(.mini)
                        }
                        
                        if isCustomModel {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("e.g. gemini-2.0-flash", text: $customModelName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 12, design: .monospaced))
                                Text("Enter any valid Gemini model identifier.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(spacing: 6) {
                                ForEach(availableGeminiModels) { model in
                                    Button(action: {
                                        geminiModel = model.id
                                    }) {
                                        HStack(alignment: .center, spacing: 8) {
                                            Image(systemName: geminiModel == model.id ? "largecircle.fill.circle" : "circle")
                                                .font(.system(size: 12))
                                                .foregroundColor(geminiModel == model.id ? .blue : .secondary)
                                            
                                            VStack(alignment: .leading, spacing: 1) {
                                                HStack {
                                                    Text(model.displayName)
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                    
                                                    Text(model.badge)
                                                        .font(.system(size: 9, weight: .bold))
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 2)
                                                        .background(model.isRecommended ? Color.blue.opacity(0.15) : Color.green.opacity(0.12))
                                                        .foregroundColor(model.isRecommended ? .blue : .green)
                                                        .cornerRadius(4)
                                                }
                                                
                                                Text(model.subtitle)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(8)
                                        .background(geminiModel == model.id ? Color.blue.opacity(0.08) : Color.clear)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(geminiModel == model.id ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    
                    // Section 3: Apple Calendar Permissions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calendar Integration")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            Circle()
                                .fill(calendarService.hasAccess ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            
                            Text(calendarService.hasAccess ? "Calendar Access Granted" : "Access Needed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if !calendarService.hasAccess {
                                Button("Grant Access") {
                                    Task {
                                        await calendarService.requestAccess()
                                    }
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            } else {
                                Button("Open Calendar") {
                                    calendarService.openCalendarApp()
                                }
                                .font(.system(size: 11))
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
                .padding(14)
            }
            
            Divider()
            
            // Bottom Close
            HStack {
                Text("Saved automatically")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.03))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
    }
    
    private func runConnectionTest() {
        isTesting = true
        testStatus = nil
        
        Task {
            let res = await geminiService.testConnection(apiKey: geminiApiKey, model: activeModelString)
            switch res {
            case .success:
                isTestSuccess = true
                testStatus = "✓ Ready"
            case .failure(let err):
                isTestSuccess = false
                testStatus = "✕ \(err.localizedDescription)"
            }
            isTesting = false
        }
    }
}
