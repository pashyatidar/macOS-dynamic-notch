import SwiftUI
import Combine
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isExpanded = false
    
    // Live Spotify Data States
    @State private var trackName = "Not Playing"
    @State private var artistName = "---"
    @State private var artworkURL = ""
    
    // MULTI-VAULT STATES
    @State private var stashedFiles: [URL] = []
    @State private var showFullVault = false
    @State private var isTargeted = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 🚨 PHYSICS: isExpanded must be checked first to prevent the infinite flickering loop!
    var currentWidth: CGFloat {
        if isExpanded { return 320 } // Keep massive if open
        if isTargeted { return 150 } // Pop out only if closed
        return 90 // Idle size
    }
    
    var currentHeight: CGFloat {
        if isExpanded { return showFullVault ? 350 : 185 } // Keep tall if open
        if isTargeted { return 45 }
        return 15
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // 1. THE CATCHER'S MITT (Placed at the BACK so it doesn't block buttons)
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: isExpanded ? 320 : 150, height: isExpanded ? currentHeight : 45)
                .onDrop(of: [.item], isTargeted: $isTargeted) { providers in
                    for provider in providers {
                        
                        // 🟢 CATCH 1: DESKTOP FILES (PDFs, PPTXs, local images)
                        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                            _ = provider.loadObject(ofClass: URL.self) { item, _ in
                                DispatchQueue.main.async {
                                    if let validURL = item as? URL {
                                        self.appendFile(validURL)
                                    }
                                }
                            }
                        }
                        // 🟢 CATCH 2: RAW CHROME IMAGES (Forces macOS to build a temp file)
                        else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
                                if let tempURL = url {
                                    let safeURL = FileManager.default.temporaryDirectory.appendingPathComponent(tempURL.lastPathComponent)
                                    try? FileManager.default.removeItem(at: safeURL)
                                    try? FileManager.default.copyItem(at: tempURL, to: safeURL)
                                    self.appendFile(safeURL)
                                }
                            }
                        }
                        // 🟢 CATCH 3: WEB LINKS (Chrome/Safari Links)
                        else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                            _ = provider.loadObject(ofClass: URL.self) { item, _ in
                                DispatchQueue.main.async {
                                    if let validURL = item as? URL {
                                        self.appendFile(validURL)
                                    }
                                }
                            }
                        }
                        // 🟢 CATCH 4: FALLBACK TEXT LINKS
                        else if provider.canLoadObject(ofClass: String.self) {
                            _ = provider.loadObject(ofClass: String.self) { item, _ in
                                if let text = item as? String, let url = URL(string: text), url.scheme != nil {
                                    self.appendFile(url)
                                }
                            }
                        }
                    }
                    return true
                }
            
            // 2. THE VISUAL SHAPE (Renders over the invisible drop zone)
            BottomRoundedCornerShape(radius: 16)
                .fill(Color.black.opacity(isExpanded || isTargeted ? 1.0 : 0.001))
                .frame(width: currentWidth, height: currentHeight)
                .shadow(color: isTargeted ? .blue.opacity(0.6) : .black.opacity(isExpanded ? 0.4 : 0), radius: 10, x: 0, y: 5)
                .overlay(
                    BottomRoundedCornerShape(radius: 16)
                        .stroke(Color.blue.opacity(isTargeted ? 1.0 : 0), lineWidth: 2)
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isTargeted)
                .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isExpanded)
                .allowsHitTesting(false)
            
            // 3. THE UI ELEMENTS (Rendered on the very top, fully clickable)
            if isExpanded {
                // 🚨 STATE 1: Expanded Mode (Checked first so it doesn't vanish while dropping!)
                VStack(spacing: 12) {
                    
                    // SPOTIFY INFO ROW
                    HStack(spacing: 15) {
                        if let url = URL(string: artworkURL), !artworkURL.isEmpty {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                            .shadow(radius: 3)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                                .overlay(Text("🎵").font(.title3))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trackName).font(.system(size: 15, weight: .bold)).foregroundColor(.white).lineLimit(1)
                            Text(artistName).font(.system(size: 13, weight: .regular)).foregroundColor(.gray).lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 25).padding(.top, 15)
                    
                    // PREMIUM MEDIA CONTROLS
                    HStack(spacing: 30) {
                        Button(action: { runAppleScript("if application \"Spotify\" is running then tell application \"Spotify\" to previous track") }) {
                            Image(systemName: "backward.fill").font(.system(size: 18)).foregroundColor(.white).frame(width: 36, height: 36).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }.buttonStyle(.plain)
                        
                        Button(action: { runAppleScript("if application \"Spotify\" is running then tell application \"Spotify\" to playpause") }) {
                            Image(systemName: "playpause.fill").font(.system(size: 22)).foregroundColor(.black).frame(width: 44, height: 44).background(Color.white).clipShape(Circle())
                        }.buttonStyle(.plain)
                        
                        Button(action: { runAppleScript("if application \"Spotify\" is running then tell application \"Spotify\" to next track") }) {
                            Image(systemName: "forward.fill").font(.system(size: 18)).foregroundColor(.white).frame(width: 36, height: 36).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }.buttonStyle(.plain)
                    }
                    
                    // MULTI-VAULT UI
                    if !stashedFiles.isEmpty {
                        Divider().background(Color.gray.opacity(0.5)).padding(.horizontal, 25)
                        
                        VStack(spacing: 8) {
                            
                            // Top Row: Vault Status & Toggle
                            // Top Row: Vault Status & Toggle (The WHOLE ROW is now clickable)
                                                        Button(action: {
                                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                                                                showFullVault.toggle()
                                                            }
                                                        }) {
                                                            HStack {
                                                                Image(systemName: "archivebox.fill").foregroundColor(.blue)
                                                                Text("\(stashedFiles.count) items stashed")
                                                                    .font(.system(size: 12, weight: .bold))
                                                                    .foregroundColor(.white)
                                                                
                                                                Spacer() // This empty space is now clickable too!
                                                                
                                                                Image(systemName: showFullVault ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                                                    .foregroundColor(.gray)
                                                            }
                                                            .padding(.horizontal, 25)
                                                            .padding(.vertical, 5) // Adds a little breathing room for the click
                                                            .contentShape(Rectangle()) // 🚨 MAGIC: Makes the empty Spacer() catch mouse clicks
                                                        }
                                                        .buttonStyle(.plain)
                            
                            if showFullVault {
                                ScrollView {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                                        ForEach(stashedFiles, id: \.self) { url in
                                            
                                            // Individual Item UI
                                            ZStack(alignment: .topTrailing) {
                                                
                                                // 🚨 Click to open item
                                                Button(action: { NSWorkspace.shared.open(url) }) {
                                                    VStack {
                                                        Image(systemName: url.isFileURL ? "doc.fill" : "link").font(.system(size: 18)).foregroundColor(.blue)
                                                        Text(url.isFileURL ? url.lastPathComponent : (url.host ?? "Link"))
                                                            .font(.system(size: 8))
                                                            .foregroundColor(.white)
                                                            .lineLimit(1)
                                                    }
                                                    .frame(width: 55, height: 55)
                                                    .background(Color.white.opacity(0.1))
                                                    .cornerRadius(8)
                                                }
                                                .buttonStyle(.plain)
                                                // 🚨 Dynamic Dragging (Files act as Files, Links act as Text)
                                                .onDrag {
                                                    if url.isFileURL {
                                                        return NSItemProvider(object: url as NSURL)
                                                    } else {
                                                        return NSItemProvider(object: url.absoluteString as NSString)
                                                    }
                                                }
                                                
                                                // 🚨 Individual Delete Button (iOS style)
                                                Button(action: {
                                                    withAnimation(.spring()) {
                                                        stashedFiles.removeAll(where: { $0 == url })
                                                        if stashedFiles.isEmpty { showFullVault = false; isExpanded = false }
                                                    }
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.gray)
                                                        .background(Circle().fill(Color.black))
                                                }
                                                .buttonStyle(.plain)
                                                .offset(x: 6, y: -6)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 5) // Prevent X marks from clipping
                                }
                                .frame(height: 120)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                }
                .transition(.opacity)
                
            } else if isTargeted {
                // 🚨 STATE 2: Pop-Out Catch (Only shows if notch was closed)
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc.fill").foregroundColor(.blue)
                    Text("Drop to Stash").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                }
                .frame(width: 150, height: 45)
                .transition(.opacity)
            }
        }
        .frame(width: 350, height: 400, alignment: .top)
        .contentShape(Rectangle())
        // 🚨 HOVER PHYSICS: Dynamically reads the height so no "edge cliffs"
        .onContinuousHover { phase in
            guard !isTargeted else { return }
            
            switch phase {
            case .active(let location):
                let inSmallArea = location.x >= 130 && location.x <= 220 && location.y >= 0 && location.y <= 15
                let inLargeArea = location.x >= 15 && location.x <= 335 && location.y >= 0 && location.y <= (currentHeight + 20)
                
                if !isExpanded && inSmallArea {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isExpanded = true
                    }
                    fetchSpotifyData()
                } else if isExpanded && !inLargeArea {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isExpanded = false
                        showFullVault = false
                    }
                }
                
            case .ended:
                if isExpanded {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isExpanded = false
                        showFullVault = false
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            if isExpanded { fetchSpotifyData() }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // --- HELPER FUNCTIONS ---
    func runAppleScript(_ script: String) {
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }
    
    func fetchSpotifyData() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing or player state is paused then
                    set tName to name of current track
                    set tArtist to artist of current track
                    set aUrl to artwork url of current track
                    return tName & "|||" & tArtist & "|||" & aUrl
                end if
            end tell
        end if
        return "Not Playing|||---|||"
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if let output = result.stringValue {
                let parts = output.components(separatedBy: "|||")
                if parts.count == 3 {
                    trackName = parts[0]
                    artistName = parts[1]
                    artworkURL = parts[2]
                }
            }
        }
    }
    
    func appendFile(_ url: URL) {
        DispatchQueue.main.async {
            if !self.stashedFiles.contains(url) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                    self.stashedFiles.append(url)
                    self.isExpanded = true
                    self.showFullVault = true // Auto-open grid
                }
            }
        }
    }
}

// Custom Shape
struct BottomRoundedCornerShape: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y - radius))
        path.addArc(center: CGPoint(x: bottomRight.x - radius, y: bottomRight.y - radius), radius: radius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: bottomLeft.x + radius, y: bottomLeft.y))
        path.addArc(center: CGPoint(x: bottomLeft.x + radius, y: bottomLeft.y - radius), radius: radius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: topLeft)
        return path
    }
}
