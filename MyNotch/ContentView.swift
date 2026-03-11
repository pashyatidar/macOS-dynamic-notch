import SwiftUI
import Combine

struct ContentView: View {
    @State private var isExpanded = false
    
    // Live Spotify Data States
    @State private var trackName = "Not Playing"
    @State private var artistName = "---"
    @State private var artworkURL = ""
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        // 🚨 THE CANVAS: Force the ZStack to be exactly 350x200
        ZStack(alignment: .top) {
            
            // 1. THE VISUALS (Smoothly animates)
            BottomRoundedCornerShape(radius: 16)
                .fill(Color.black.opacity(isExpanded ? 1.0 : 0.001))
                .frame(width: isExpanded ? 320 : 90, height: isExpanded ? 150 : 15)
                .shadow(color: .black.opacity(isExpanded ? 0.4 : 0), radius: 10, x: 0, y: 5)
                // The visual shape is a ghost. It CANNOT catch your mouse.
                .allowsHitTesting(false)
            
            // 2. THE UI ELEMENTS
            if isExpanded {
                VStack(spacing: 16) {
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
                            Text(trackName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(artistName)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 20)
                    
                    // PREMIUM MEDIA CONTROLS
                    HStack(spacing: 30) {
                        Button(action: { runAppleScript("if application \"Spotify\" is running then tell application \"Spotify\" to previous track") }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { runAppleScript("if application \"Spotify\" is running then tell application \"Spotify\" to playpause") }) {
                            Image(systemName: "playpause.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { runAppleScript("if application \"Spotify\" is running then tell application \"Spotify\" to next track") }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(width: 350, height: 200, alignment: .top)
        .contentShape(Rectangle()) // Makes the ENTIRE invisible 350x200 canvas active
        
        // 🚨 MATHEMATICAL HIT-TESTING 🚨
        // This tracks the exact X/Y pixel of your mouse, bypassing macOS View bugs entirely!
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                // Canvas width is 350. Center is 175.
                // Small Notch bounds (90x15): X from 130 to 220, Y from 0 to 15
                let inSmallArea = location.x >= 130 && location.x <= 220 && location.y >= 0 && location.y <= 15
                
                // Large Notch bounds (320x150): X from 15 to 335, Y from 0 to 150
                let inLargeArea = location.x >= 15 && location.x <= 335 && location.y >= 0 && location.y <= 150
                
                if !isExpanded && inSmallArea {
                    // Mouse mathematically hit the tiny 90x15 box. Open it!
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isExpanded = true
                    }
                    fetchSpotifyData()
                } else if isExpanded && !inLargeArea {
                    // Mouse mathematically completely left the 320x150 box. Close it!
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isExpanded = false
                    }
                }
                // NOTE: If mouse is in Large Area but NOT Small Area while closed, nothing happens.
                // This perfectly solves your glitch!
                
            case .ended:
                // Mouse completely left the entire 350x200 canvas area
                if isExpanded {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        isExpanded = false
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            if isExpanded { fetchSpotifyData() }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // Executes basic commands like Play/Pause
    func runAppleScript(_ script: String) {
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }
    
    // The Data Pipeline: Pulls name, artist, and image URL
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
}

// Our custom shape
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
