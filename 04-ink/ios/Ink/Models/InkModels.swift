import Foundation
import SwiftData

@Model
final class TattooIdea {
    var title: String
    var body: String
    var style: String
    var placement: String
    var status: String
    var tags: [String]
    var estimatedCost: Double
    var colorScheme: String
    var size: String
    var artistId: UUID?
    var dateAdded: Date
    var isWishlist: Bool

    init(
        title: String = "",
        body: String = "",
        style: String = TattooStyle.blackwork.rawValue,
        placement: String = BodyPlacement.forearm.rawValue,
        status: String = IdeaStatus.wishlist.rawValue,
        tags: [String] = [],
        estimatedCost: Double = 0,
        colorScheme: String = "Black & Grey",
        size: String = "Medium",
        artistId: UUID? = nil,
        isWishlist: Bool = true
    ) {
        self.title = title
        self.body = body
        self.style = style
        self.placement = placement
        self.status = status
        self.tags = tags
        self.estimatedCost = estimatedCost
        self.colorScheme = colorScheme
        self.size = size
        self.artistId = artistId
        self.dateAdded = Date()
        self.isWishlist = isWishlist
    }
}

@Model
final class TattooArtist {
    var name: String
    var studio: String
    var instagram: String
    var city: String
    var specialties: [String]
    var rating: Int
    var notes: String
    var priceRange: String
    var portfolioUrl: String
    var dateAdded: Date

    init(
        name: String = "",
        studio: String = "",
        instagram: String = "",
        city: String = "",
        specialties: [String] = [],
        rating: Int = 5,
        notes: String = "",
        priceRange: String = "$150-250/hr",
        portfolioUrl: String = ""
    ) {
        self.name = name
        self.studio = studio
        self.instagram = instagram
        self.city = city
        self.specialties = specialties
        self.rating = rating
        self.notes = notes
        self.priceRange = priceRange
        self.portfolioUrl = portfolioUrl
        self.dateAdded = Date()
    }
}

@Model
final class TattooAppointment {
    var title: String
    var date: Date
    var artistName: String
    var studio: String
    var estimatedHours: Double
    var depositPaid: Double
    var totalCost: Double
    var notes: String
    var isCompleted: Bool
    var placement: String

    init(
        title: String = "",
        date: Date = Date(),
        artistName: String = "",
        studio: String = "",
        estimatedHours: Double = 2,
        depositPaid: Double = 0,
        totalCost: Double = 0,
        notes: String = "",
        isCompleted: Bool = false,
        placement: String = BodyPlacement.forearm.rawValue
    ) {
        self.title = title
        self.date = date
        self.artistName = artistName
        self.studio = studio
        self.estimatedHours = estimatedHours
        self.depositPaid = depositPaid
        self.totalCost = totalCost
        self.notes = notes
        self.isCompleted = isCompleted
        self.placement = placement
    }
}

@Model
final class InkSettings {
    var hasCompletedOnboarding: Bool
    var isPro: Bool
    var defaultStyle: String
    var currency: String
    var showEstimates: Bool
    var sortOrder: String

    init() {
        self.hasCompletedOnboarding = false
        self.isPro = false
        self.defaultStyle = TattooStyle.blackwork.rawValue
        self.currency = "USD"
        self.showEstimates = true
        self.sortOrder = "dateAdded"
    }
}
