import SwiftUI

/// Row displaying a national hotline contact
struct NationalHotlineRow: View {
    let name: String
    let phone: String
    let description: String
    let icon: String
    let color: Color
    var isTextLine: Bool = false
    
    var body: some View {
        Button {
            callNumber(phone)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if isTextLine {
                    Image(systemName: "message.fill")
                        .foregroundColor(color)
                } else {
                    Image(systemName: "phone.fill")
                        .foregroundColor(color)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func callNumber(_ number: String) {
        let cleanNumber = number.filter { $0.isNumber }
        if let url = URL(string: isTextLine ? "sms:\(cleanNumber)" : "tel://\(cleanNumber)") {
            UIApplication.shared.open(url)
        }
    }
}
