import SwiftUI
import Combine

struct ContentView: View {
    @State private var isHovering = false
    
    // Live Spotify Data States
    @State private var trackName = "Not Playing"
    @State private var artistName = "---"
    @State private var artworkURL = ""
    
    // A live engine that updates the UI every 1 second while expanded
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // THE GHOST BACKGROUND: Invisible (0.001) when collapsed, Black when expanded!
                BottomRoundedCornerShape(radius: 16)
                    .fill(Color.black.opacity(isHovering ? 1.0 : 0.001))
                    .frame(width: isHovering ? 320 : 90, height: isHovering ? 150 : 15)
                    .shadow(color: .black.opacity(isHovering ? 0.4 : 0), radius: 10, x: 0, y: 5)
                
                if isHovering {
                    VStack(spacing: 16) {
                        // SPOTIFY INFO ROW
                        HStack(spacing: 15) {
                            // The Live Album Art
                            if let url = URL(string: artworkURL), !artworkURL.isEmpty {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.3) // Shows while loading
                                }
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                                .shadow(radius: 3)
                            } else {
                                // Fallback if Spotify is closed
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                    .overlay(Text("🎵").font(.title3))
                            }
                            
                            // Track & Artist Text
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trackName)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1) // Prevents super long titles from breaking the UI
                                Text(artistName)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            Spacer() // Pushes everything to the left
                        }
                        .padding(.horizontal, 25)
                        .padding(.top, 20)
                        
                        // MEDIA CONTROLS
                        // PREMIUM MEDIA CONTROLS
                                                HStack(spacing: 30) {
                                                    // Previous Track
                                                    Button(action: { runAppleScript("if application \"Spotify\" is running then tell application \"Spotify\" to previous track") }) {
                                                        Image(systemName: "backward.fill")
                                                            .font(.system(size: 18))
                                                            .foregroundColor(.white)
                                                            .frame(width: 36, height: 36)
                                                            .background(Color.white.opacity(0.1)) // Subtle grey circle
                                                            .clipShape(Circle())
                                                    }
                                                    .buttonStyle(.plain)
                                                    
                                                    // Play/Pause
                                                    Button(action: { runAppleScript("if application \"Spotify\" is running then tell application \"Spotify\" to playpause") }) {
                                                        Image(systemName: "playpause.fill")
                                                            .font(.system(size: 22)) // Slightly larger for emphasis
                                                            .foregroundColor(.black)
                                                            .frame(width: 44, height: 44)
                                                            .background(Color.white) // High contrast play button
                                                            .clipShape(Circle())
                                                    }
                                                    .buttonStyle(.plain)
                                                    
                                                    // Next Track
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
                }
            }
            // THE TRIGGERS
            .onHover { hovering in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                    isHovering = hovering
                }
                if hovering { fetchSpotifyData() } // Fetch instantly when hovered
            }
            .onReceive(timer) { _ in
                if isHovering { fetchSpotifyData() } // Keep fetching while open
            }
            
            Spacer()
        }
        .frame(width: 350, height: 200) // Matches AppDelegate size
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

// Our custom shape (stays exactly the same!)
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
