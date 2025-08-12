import SwiftUI

struct VolumeSlider: View {
    @Binding var volume: Float
    let title: String
    
    init(volume: Binding<Float>, title: String = "Volume") {
        self._volume = volume
        self.title = title
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(Int(volume * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .monospacedDigit()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.textSecondary)
                        .font(.caption)
                    
                    Slider(
                        value: $volume,
                        in: 0...1,
                        step: 0.01
                    )
                    .tint(.appPrimary)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.textSecondary)
                        .font(.caption)
                }
                
                HStack {
                    Text("Quiet")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                    
                    Spacer()
                    
                    Text("Loud")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding()
            .background(Color.appSecondaryBackground)
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        VolumeSlider(volume: .constant(0.5))
        
        VolumeSlider(volume: .constant(0.8), title: "Alarm Volume")
        
        VolumeSlider(volume: .constant(0.2), title: "Notification Volume")
        
        VolumeSlider(volume: .constant(1.0), title: "Max Volume")
    }
    .padding()
    .background(Color.appBackground)
}