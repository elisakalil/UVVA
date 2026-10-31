import Core
import DesignSystem
import SwiftUI

/// The countries of the phone, by name in the device's language (D8).
struct CountryPicker: View {
    var selected: PhoneCountry
    var onPick: (PhoneCountry) -> Void

    private var countries: [PhoneCountry] {
        PhoneCountries.all.sorted { $0.name().localizedStandardCompare($1.name()) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(countries) { country in
                    Button { onPick(country) } label: {
                        HStack(spacing: 12) {
                            Text(country.name()).font(UVVAFont.sans(14))
                            Spacer()
                            Text("+" + country.callingCode).font(UVVAFont.sans(13)).opacity(0.6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14)
                            .fill(UVVAColor.creamFill.opacity(country == selected ? 0.16 : 0)))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(country == selected ? .isSelected : [])
                }
            }
            .padding(10)
            .padding(.top, 14)
        }
        .foregroundStyle(UVVAColor.creamFill)
    }
}
