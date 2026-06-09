import Foundation

/// A single country in the static reference dataset. Identity is the stable
/// ISO 3166-1 alpha-2 `code`. The flag emoji is computed from that code via
/// Unicode regional-indicator symbols, so it's always correct and we never
/// have to hand-author 195 emoji.
struct Country: Identifiable, Hashable {
    let code: String          // ISO alpha-2, uppercase
    let name: String
    let continent: Continent
    let region: String        // sub-region, e.g. "Western Europe"
    let capital: String

    var id: String { code }

    /// The Unicode flag emoji for this country, built from its ISO code:
    /// each letter A…Z maps to a regional-indicator symbol (0x1F1E6 + offset).
    /// Returns a globe fallback if the code isn't two valid A–Z letters.
    var flagEmoji: String {
        let base: UInt32 = 0x1F1E6
        let scalars = code.uppercased().unicodeScalars
        guard code.count == 2 else { return "🌐" }
        var result = ""
        for scalar in scalars {
            guard scalar.value >= 65, scalar.value <= 90 else { return "🌐" }
            let offset = scalar.value - 65
            if let flagScalar = Unicode.Scalar(base + offset) {
                result.unicodeScalars.append(flagScalar)
            } else {
                return "🌐"
            }
        }
        return result.isEmpty ? "🌐" : result
    }
}

/// The static collection of every UN member / observer state across the six
/// inhabited continents (~195 entries). Lookups by code are O(1) via `byCode`.
enum CountryData {

    /// Fast code → Country index.
    static let byCode: [String: Country] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.code, $0) })
    }()

    static func country(for code: String) -> Country? {
        byCode[code.uppercased()]
    }

    static let total: Int = all.count

    /// Countries grouped by continent, each group name-sorted. Continents in
    /// canonical CaseIterable order.
    static let byContinent: [(continent: Continent, countries: [Country])] = {
        Continent.allCases.map { continent in
            (continent, all.filter { $0.continent == continent }.sorted { $0.name < $1.name })
        }
    }()

    static let all: [Country] = [
        // MARK: - Africa
        Country(code: "DZ", name: "Algeria", continent: .africa, region: "Northern Africa", capital: "Algiers"),
        Country(code: "AO", name: "Angola", continent: .africa, region: "Middle Africa", capital: "Luanda"),
        Country(code: "BJ", name: "Benin", continent: .africa, region: "Western Africa", capital: "Porto-Novo"),
        Country(code: "BW", name: "Botswana", continent: .africa, region: "Southern Africa", capital: "Gaborone"),
        Country(code: "BF", name: "Burkina Faso", continent: .africa, region: "Western Africa", capital: "Ouagadougou"),
        Country(code: "BI", name: "Burundi", continent: .africa, region: "Eastern Africa", capital: "Gitega"),
        Country(code: "CV", name: "Cabo Verde", continent: .africa, region: "Western Africa", capital: "Praia"),
        Country(code: "CM", name: "Cameroon", continent: .africa, region: "Middle Africa", capital: "Yaoundé"),
        Country(code: "CF", name: "Central African Republic", continent: .africa, region: "Middle Africa", capital: "Bangui"),
        Country(code: "TD", name: "Chad", continent: .africa, region: "Middle Africa", capital: "N'Djamena"),
        Country(code: "KM", name: "Comoros", continent: .africa, region: "Eastern Africa", capital: "Moroni"),
        Country(code: "CG", name: "Congo", continent: .africa, region: "Middle Africa", capital: "Brazzaville"),
        Country(code: "CD", name: "DR Congo", continent: .africa, region: "Middle Africa", capital: "Kinshasa"),
        Country(code: "CI", name: "Côte d'Ivoire", continent: .africa, region: "Western Africa", capital: "Yamoussoukro"),
        Country(code: "DJ", name: "Djibouti", continent: .africa, region: "Eastern Africa", capital: "Djibouti"),
        Country(code: "EG", name: "Egypt", continent: .africa, region: "Northern Africa", capital: "Cairo"),
        Country(code: "GQ", name: "Equatorial Guinea", continent: .africa, region: "Middle Africa", capital: "Malabo"),
        Country(code: "ER", name: "Eritrea", continent: .africa, region: "Eastern Africa", capital: "Asmara"),
        Country(code: "SZ", name: "Eswatini", continent: .africa, region: "Southern Africa", capital: "Mbabane"),
        Country(code: "ET", name: "Ethiopia", continent: .africa, region: "Eastern Africa", capital: "Addis Ababa"),
        Country(code: "GA", name: "Gabon", continent: .africa, region: "Middle Africa", capital: "Libreville"),
        Country(code: "GM", name: "Gambia", continent: .africa, region: "Western Africa", capital: "Banjul"),
        Country(code: "GH", name: "Ghana", continent: .africa, region: "Western Africa", capital: "Accra"),
        Country(code: "GN", name: "Guinea", continent: .africa, region: "Western Africa", capital: "Conakry"),
        Country(code: "GW", name: "Guinea-Bissau", continent: .africa, region: "Western Africa", capital: "Bissau"),
        Country(code: "KE", name: "Kenya", continent: .africa, region: "Eastern Africa", capital: "Nairobi"),
        Country(code: "LS", name: "Lesotho", continent: .africa, region: "Southern Africa", capital: "Maseru"),
        Country(code: "LR", name: "Liberia", continent: .africa, region: "Western Africa", capital: "Monrovia"),
        Country(code: "LY", name: "Libya", continent: .africa, region: "Northern Africa", capital: "Tripoli"),
        Country(code: "MG", name: "Madagascar", continent: .africa, region: "Eastern Africa", capital: "Antananarivo"),
        Country(code: "MW", name: "Malawi", continent: .africa, region: "Eastern Africa", capital: "Lilongwe"),
        Country(code: "ML", name: "Mali", continent: .africa, region: "Western Africa", capital: "Bamako"),
        Country(code: "MR", name: "Mauritania", continent: .africa, region: "Western Africa", capital: "Nouakchott"),
        Country(code: "MU", name: "Mauritius", continent: .africa, region: "Eastern Africa", capital: "Port Louis"),
        Country(code: "MA", name: "Morocco", continent: .africa, region: "Northern Africa", capital: "Rabat"),
        Country(code: "MZ", name: "Mozambique", continent: .africa, region: "Eastern Africa", capital: "Maputo"),
        Country(code: "NA", name: "Namibia", continent: .africa, region: "Southern Africa", capital: "Windhoek"),
        Country(code: "NE", name: "Niger", continent: .africa, region: "Western Africa", capital: "Niamey"),
        Country(code: "NG", name: "Nigeria", continent: .africa, region: "Western Africa", capital: "Abuja"),
        Country(code: "RW", name: "Rwanda", continent: .africa, region: "Eastern Africa", capital: "Kigali"),
        Country(code: "ST", name: "São Tomé and Príncipe", continent: .africa, region: "Middle Africa", capital: "São Tomé"),
        Country(code: "SN", name: "Senegal", continent: .africa, region: "Western Africa", capital: "Dakar"),
        Country(code: "SC", name: "Seychelles", continent: .africa, region: "Eastern Africa", capital: "Victoria"),
        Country(code: "SL", name: "Sierra Leone", continent: .africa, region: "Western Africa", capital: "Freetown"),
        Country(code: "SO", name: "Somalia", continent: .africa, region: "Eastern Africa", capital: "Mogadishu"),
        Country(code: "ZA", name: "South Africa", continent: .africa, region: "Southern Africa", capital: "Pretoria"),
        Country(code: "SS", name: "South Sudan", continent: .africa, region: "Eastern Africa", capital: "Juba"),
        Country(code: "SD", name: "Sudan", continent: .africa, region: "Northern Africa", capital: "Khartoum"),
        Country(code: "TZ", name: "Tanzania", continent: .africa, region: "Eastern Africa", capital: "Dodoma"),
        Country(code: "TG", name: "Togo", continent: .africa, region: "Western Africa", capital: "Lomé"),
        Country(code: "TN", name: "Tunisia", continent: .africa, region: "Northern Africa", capital: "Tunis"),
        Country(code: "UG", name: "Uganda", continent: .africa, region: "Eastern Africa", capital: "Kampala"),
        Country(code: "ZM", name: "Zambia", continent: .africa, region: "Eastern Africa", capital: "Lusaka"),
        Country(code: "ZW", name: "Zimbabwe", continent: .africa, region: "Eastern Africa", capital: "Harare"),

        // MARK: - Asia
        Country(code: "AF", name: "Afghanistan", continent: .asia, region: "Southern Asia", capital: "Kabul"),
        Country(code: "AM", name: "Armenia", continent: .asia, region: "Western Asia", capital: "Yerevan"),
        Country(code: "AZ", name: "Azerbaijan", continent: .asia, region: "Western Asia", capital: "Baku"),
        Country(code: "BH", name: "Bahrain", continent: .asia, region: "Western Asia", capital: "Manama"),
        Country(code: "BD", name: "Bangladesh", continent: .asia, region: "Southern Asia", capital: "Dhaka"),
        Country(code: "BT", name: "Bhutan", continent: .asia, region: "Southern Asia", capital: "Thimphu"),
        Country(code: "BN", name: "Brunei", continent: .asia, region: "South-Eastern Asia", capital: "Bandar Seri Begawan"),
        Country(code: "KH", name: "Cambodia", continent: .asia, region: "South-Eastern Asia", capital: "Phnom Penh"),
        Country(code: "CN", name: "China", continent: .asia, region: "Eastern Asia", capital: "Beijing"),
        Country(code: "CY", name: "Cyprus", continent: .asia, region: "Western Asia", capital: "Nicosia"),
        Country(code: "GE", name: "Georgia", continent: .asia, region: "Western Asia", capital: "Tbilisi"),
        Country(code: "IN", name: "India", continent: .asia, region: "Southern Asia", capital: "New Delhi"),
        Country(code: "ID", name: "Indonesia", continent: .asia, region: "South-Eastern Asia", capital: "Jakarta"),
        Country(code: "IR", name: "Iran", continent: .asia, region: "Southern Asia", capital: "Tehran"),
        Country(code: "IQ", name: "Iraq", continent: .asia, region: "Western Asia", capital: "Baghdad"),
        Country(code: "IL", name: "Israel", continent: .asia, region: "Western Asia", capital: "Jerusalem"),
        Country(code: "JP", name: "Japan", continent: .asia, region: "Eastern Asia", capital: "Tokyo"),
        Country(code: "JO", name: "Jordan", continent: .asia, region: "Western Asia", capital: "Amman"),
        Country(code: "KZ", name: "Kazakhstan", continent: .asia, region: "Central Asia", capital: "Astana"),
        Country(code: "KW", name: "Kuwait", continent: .asia, region: "Western Asia", capital: "Kuwait City"),
        Country(code: "KG", name: "Kyrgyzstan", continent: .asia, region: "Central Asia", capital: "Bishkek"),
        Country(code: "LA", name: "Laos", continent: .asia, region: "South-Eastern Asia", capital: "Vientiane"),
        Country(code: "LB", name: "Lebanon", continent: .asia, region: "Western Asia", capital: "Beirut"),
        Country(code: "MY", name: "Malaysia", continent: .asia, region: "South-Eastern Asia", capital: "Kuala Lumpur"),
        Country(code: "MV", name: "Maldives", continent: .asia, region: "Southern Asia", capital: "Malé"),
        Country(code: "MN", name: "Mongolia", continent: .asia, region: "Eastern Asia", capital: "Ulaanbaatar"),
        Country(code: "MM", name: "Myanmar", continent: .asia, region: "South-Eastern Asia", capital: "Naypyidaw"),
        Country(code: "NP", name: "Nepal", continent: .asia, region: "Southern Asia", capital: "Kathmandu"),
        Country(code: "KP", name: "North Korea", continent: .asia, region: "Eastern Asia", capital: "Pyongyang"),
        Country(code: "OM", name: "Oman", continent: .asia, region: "Western Asia", capital: "Muscat"),
        Country(code: "PK", name: "Pakistan", continent: .asia, region: "Southern Asia", capital: "Islamabad"),
        Country(code: "PS", name: "Palestine", continent: .asia, region: "Western Asia", capital: "Ramallah"),
        Country(code: "PH", name: "Philippines", continent: .asia, region: "South-Eastern Asia", capital: "Manila"),
        Country(code: "QA", name: "Qatar", continent: .asia, region: "Western Asia", capital: "Doha"),
        Country(code: "SA", name: "Saudi Arabia", continent: .asia, region: "Western Asia", capital: "Riyadh"),
        Country(code: "SG", name: "Singapore", continent: .asia, region: "South-Eastern Asia", capital: "Singapore"),
        Country(code: "KR", name: "South Korea", continent: .asia, region: "Eastern Asia", capital: "Seoul"),
        Country(code: "LK", name: "Sri Lanka", continent: .asia, region: "Southern Asia", capital: "Sri Jayawardenepura Kotte"),
        Country(code: "SY", name: "Syria", continent: .asia, region: "Western Asia", capital: "Damascus"),
        Country(code: "TW", name: "Taiwan", continent: .asia, region: "Eastern Asia", capital: "Taipei"),
        Country(code: "TJ", name: "Tajikistan", continent: .asia, region: "Central Asia", capital: "Dushanbe"),
        Country(code: "TH", name: "Thailand", continent: .asia, region: "South-Eastern Asia", capital: "Bangkok"),
        Country(code: "TL", name: "Timor-Leste", continent: .asia, region: "South-Eastern Asia", capital: "Dili"),
        Country(code: "TR", name: "Turkey", continent: .asia, region: "Western Asia", capital: "Ankara"),
        Country(code: "TM", name: "Turkmenistan", continent: .asia, region: "Central Asia", capital: "Ashgabat"),
        Country(code: "AE", name: "United Arab Emirates", continent: .asia, region: "Western Asia", capital: "Abu Dhabi"),
        Country(code: "UZ", name: "Uzbekistan", continent: .asia, region: "Central Asia", capital: "Tashkent"),
        Country(code: "VN", name: "Vietnam", continent: .asia, region: "South-Eastern Asia", capital: "Hanoi"),
        Country(code: "YE", name: "Yemen", continent: .asia, region: "Western Asia", capital: "Sana'a"),

        // MARK: - Europe
        Country(code: "AL", name: "Albania", continent: .europe, region: "Southern Europe", capital: "Tirana"),
        Country(code: "AD", name: "Andorra", continent: .europe, region: "Southern Europe", capital: "Andorra la Vella"),
        Country(code: "AT", name: "Austria", continent: .europe, region: "Western Europe", capital: "Vienna"),
        Country(code: "BY", name: "Belarus", continent: .europe, region: "Eastern Europe", capital: "Minsk"),
        Country(code: "BE", name: "Belgium", continent: .europe, region: "Western Europe", capital: "Brussels"),
        Country(code: "BA", name: "Bosnia and Herzegovina", continent: .europe, region: "Southern Europe", capital: "Sarajevo"),
        Country(code: "BG", name: "Bulgaria", continent: .europe, region: "Eastern Europe", capital: "Sofia"),
        Country(code: "HR", name: "Croatia", continent: .europe, region: "Southern Europe", capital: "Zagreb"),
        Country(code: "CZ", name: "Czechia", continent: .europe, region: "Eastern Europe", capital: "Prague"),
        Country(code: "DK", name: "Denmark", continent: .europe, region: "Northern Europe", capital: "Copenhagen"),
        Country(code: "EE", name: "Estonia", continent: .europe, region: "Northern Europe", capital: "Tallinn"),
        Country(code: "FI", name: "Finland", continent: .europe, region: "Northern Europe", capital: "Helsinki"),
        Country(code: "FR", name: "France", continent: .europe, region: "Western Europe", capital: "Paris"),
        Country(code: "DE", name: "Germany", continent: .europe, region: "Western Europe", capital: "Berlin"),
        Country(code: "GR", name: "Greece", continent: .europe, region: "Southern Europe", capital: "Athens"),
        Country(code: "HU", name: "Hungary", continent: .europe, region: "Eastern Europe", capital: "Budapest"),
        Country(code: "IS", name: "Iceland", continent: .europe, region: "Northern Europe", capital: "Reykjavík"),
        Country(code: "IE", name: "Ireland", continent: .europe, region: "Northern Europe", capital: "Dublin"),
        Country(code: "IT", name: "Italy", continent: .europe, region: "Southern Europe", capital: "Rome"),
        Country(code: "XK", name: "Kosovo", continent: .europe, region: "Southern Europe", capital: "Pristina"),
        Country(code: "LV", name: "Latvia", continent: .europe, region: "Northern Europe", capital: "Riga"),
        Country(code: "LI", name: "Liechtenstein", continent: .europe, region: "Western Europe", capital: "Vaduz"),
        Country(code: "LT", name: "Lithuania", continent: .europe, region: "Northern Europe", capital: "Vilnius"),
        Country(code: "LU", name: "Luxembourg", continent: .europe, region: "Western Europe", capital: "Luxembourg"),
        Country(code: "MT", name: "Malta", continent: .europe, region: "Southern Europe", capital: "Valletta"),
        Country(code: "MD", name: "Moldova", continent: .europe, region: "Eastern Europe", capital: "Chișinău"),
        Country(code: "MC", name: "Monaco", continent: .europe, region: "Western Europe", capital: "Monaco"),
        Country(code: "ME", name: "Montenegro", continent: .europe, region: "Southern Europe", capital: "Podgorica"),
        Country(code: "NL", name: "Netherlands", continent: .europe, region: "Western Europe", capital: "Amsterdam"),
        Country(code: "MK", name: "North Macedonia", continent: .europe, region: "Southern Europe", capital: "Skopje"),
        Country(code: "NO", name: "Norway", continent: .europe, region: "Northern Europe", capital: "Oslo"),
        Country(code: "PL", name: "Poland", continent: .europe, region: "Eastern Europe", capital: "Warsaw"),
        Country(code: "PT", name: "Portugal", continent: .europe, region: "Southern Europe", capital: "Lisbon"),
        Country(code: "RO", name: "Romania", continent: .europe, region: "Eastern Europe", capital: "Bucharest"),
        Country(code: "RU", name: "Russia", continent: .europe, region: "Eastern Europe", capital: "Moscow"),
        Country(code: "SM", name: "San Marino", continent: .europe, region: "Southern Europe", capital: "San Marino"),
        Country(code: "RS", name: "Serbia", continent: .europe, region: "Southern Europe", capital: "Belgrade"),
        Country(code: "SK", name: "Slovakia", continent: .europe, region: "Eastern Europe", capital: "Bratislava"),
        Country(code: "SI", name: "Slovenia", continent: .europe, region: "Southern Europe", capital: "Ljubljana"),
        Country(code: "ES", name: "Spain", continent: .europe, region: "Southern Europe", capital: "Madrid"),
        Country(code: "SE", name: "Sweden", continent: .europe, region: "Northern Europe", capital: "Stockholm"),
        Country(code: "CH", name: "Switzerland", continent: .europe, region: "Western Europe", capital: "Bern"),
        Country(code: "UA", name: "Ukraine", continent: .europe, region: "Eastern Europe", capital: "Kyiv"),
        Country(code: "GB", name: "United Kingdom", continent: .europe, region: "Northern Europe", capital: "London"),
        Country(code: "VA", name: "Vatican City", continent: .europe, region: "Southern Europe", capital: "Vatican City"),

        // MARK: - North America
        Country(code: "AG", name: "Antigua and Barbuda", continent: .northAmerica, region: "Caribbean", capital: "Saint John's"),
        Country(code: "BS", name: "Bahamas", continent: .northAmerica, region: "Caribbean", capital: "Nassau"),
        Country(code: "BB", name: "Barbados", continent: .northAmerica, region: "Caribbean", capital: "Bridgetown"),
        Country(code: "BZ", name: "Belize", continent: .northAmerica, region: "Central America", capital: "Belmopan"),
        Country(code: "CA", name: "Canada", continent: .northAmerica, region: "Northern America", capital: "Ottawa"),
        Country(code: "CR", name: "Costa Rica", continent: .northAmerica, region: "Central America", capital: "San José"),
        Country(code: "CU", name: "Cuba", continent: .northAmerica, region: "Caribbean", capital: "Havana"),
        Country(code: "DM", name: "Dominica", continent: .northAmerica, region: "Caribbean", capital: "Roseau"),
        Country(code: "DO", name: "Dominican Republic", continent: .northAmerica, region: "Caribbean", capital: "Santo Domingo"),
        Country(code: "SV", name: "El Salvador", continent: .northAmerica, region: "Central America", capital: "San Salvador"),
        Country(code: "GD", name: "Grenada", continent: .northAmerica, region: "Caribbean", capital: "Saint George's"),
        Country(code: "GT", name: "Guatemala", continent: .northAmerica, region: "Central America", capital: "Guatemala City"),
        Country(code: "HT", name: "Haiti", continent: .northAmerica, region: "Caribbean", capital: "Port-au-Prince"),
        Country(code: "HN", name: "Honduras", continent: .northAmerica, region: "Central America", capital: "Tegucigalpa"),
        Country(code: "JM", name: "Jamaica", continent: .northAmerica, region: "Caribbean", capital: "Kingston"),
        Country(code: "MX", name: "Mexico", continent: .northAmerica, region: "Central America", capital: "Mexico City"),
        Country(code: "NI", name: "Nicaragua", continent: .northAmerica, region: "Central America", capital: "Managua"),
        Country(code: "PA", name: "Panama", continent: .northAmerica, region: "Central America", capital: "Panama City"),
        Country(code: "KN", name: "Saint Kitts and Nevis", continent: .northAmerica, region: "Caribbean", capital: "Basseterre"),
        Country(code: "LC", name: "Saint Lucia", continent: .northAmerica, region: "Caribbean", capital: "Castries"),
        Country(code: "VC", name: "Saint Vincent and the Grenadines", continent: .northAmerica, region: "Caribbean", capital: "Kingstown"),
        Country(code: "TT", name: "Trinidad and Tobago", continent: .northAmerica, region: "Caribbean", capital: "Port of Spain"),
        Country(code: "US", name: "United States", continent: .northAmerica, region: "Northern America", capital: "Washington, D.C."),

        // MARK: - South America
        Country(code: "AR", name: "Argentina", continent: .southAmerica, region: "South America", capital: "Buenos Aires"),
        Country(code: "BO", name: "Bolivia", continent: .southAmerica, region: "South America", capital: "Sucre"),
        Country(code: "BR", name: "Brazil", continent: .southAmerica, region: "South America", capital: "Brasília"),
        Country(code: "CL", name: "Chile", continent: .southAmerica, region: "South America", capital: "Santiago"),
        Country(code: "CO", name: "Colombia", continent: .southAmerica, region: "South America", capital: "Bogotá"),
        Country(code: "EC", name: "Ecuador", continent: .southAmerica, region: "South America", capital: "Quito"),
        Country(code: "GY", name: "Guyana", continent: .southAmerica, region: "South America", capital: "Georgetown"),
        Country(code: "PY", name: "Paraguay", continent: .southAmerica, region: "South America", capital: "Asunción"),
        Country(code: "PE", name: "Peru", continent: .southAmerica, region: "South America", capital: "Lima"),
        Country(code: "SR", name: "Suriname", continent: .southAmerica, region: "South America", capital: "Paramaribo"),
        Country(code: "UY", name: "Uruguay", continent: .southAmerica, region: "South America", capital: "Montevideo"),
        Country(code: "VE", name: "Venezuela", continent: .southAmerica, region: "South America", capital: "Caracas"),

        // MARK: - Oceania
        Country(code: "AU", name: "Australia", continent: .oceania, region: "Australia and New Zealand", capital: "Canberra"),
        Country(code: "FJ", name: "Fiji", continent: .oceania, region: "Melanesia", capital: "Suva"),
        Country(code: "KI", name: "Kiribati", continent: .oceania, region: "Micronesia", capital: "South Tarawa"),
        Country(code: "MH", name: "Marshall Islands", continent: .oceania, region: "Micronesia", capital: "Majuro"),
        Country(code: "FM", name: "Micronesia", continent: .oceania, region: "Micronesia", capital: "Palikir"),
        Country(code: "NR", name: "Nauru", continent: .oceania, region: "Micronesia", capital: "Yaren"),
        Country(code: "NZ", name: "New Zealand", continent: .oceania, region: "Australia and New Zealand", capital: "Wellington"),
        Country(code: "PW", name: "Palau", continent: .oceania, region: "Micronesia", capital: "Ngerulmud"),
        Country(code: "PG", name: "Papua New Guinea", continent: .oceania, region: "Melanesia", capital: "Port Moresby"),
        Country(code: "WS", name: "Samoa", continent: .oceania, region: "Polynesia", capital: "Apia"),
        Country(code: "SB", name: "Solomon Islands", continent: .oceania, region: "Melanesia", capital: "Honiara"),
        Country(code: "TO", name: "Tonga", continent: .oceania, region: "Polynesia", capital: "Nuku'alofa"),
        Country(code: "TV", name: "Tuvalu", continent: .oceania, region: "Polynesia", capital: "Funafuti"),
        Country(code: "VU", name: "Vanuatu", continent: .oceania, region: "Melanesia", capital: "Port Vila")
    ]
}
