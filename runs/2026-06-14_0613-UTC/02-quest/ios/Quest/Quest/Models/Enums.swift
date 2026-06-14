import SwiftUI

enum Platform: String, Codable, CaseIterable, Identifiable {
    case pc = "PC"
    case playStation = "PlayStation"
    case xbox = "Xbox"
    case nintendoSwitch = "Switch"
    case mobile = "Mobile"
    case steamDeck = "Steam Deck"
    case retro = "Retro"
    case other = "Other"

    var id: String { rawValue }
    var label: String { rawValue }

    var symbol: String {
        switch self {
        case .pc: return "desktopcomputer"
        case .playStation: return "playstation.logo"
        case .xbox: return "xbox.logo"
        case .nintendoSwitch: return "gamecontroller"
        case .mobile: return "iphone"
        case .steamDeck: return "rectangle.on.rectangle.angled"
        case .retro: return "memorychip"
        case .other: return "square.grid.2x2"
        }
    }
}

enum Genre: String, Codable, CaseIterable, Identifiable {
    case action = "Action"
    case rpg = "RPG"
    case shooter = "Shooter"
    case strategy = "Strategy"
    case platformer = "Platformer"
    case puzzle = "Puzzle"
    case adventure = "Adventure"
    case sports = "Sports"
    case racing = "Racing"
    case sim = "Sim"
    case indie = "Indie"
    case fighting = "Fighting"
    case horror = "Horror"
    case mmo = "MMO"
    case other = "Other"

    var id: String { rawValue }
    var label: String { rawValue }

    var symbol: String {
        switch self {
        case .action: return "burst.fill"
        case .rpg: return "shield.lefthalf.filled"
        case .shooter: return "scope"
        case .strategy: return "brain.head.profile"
        case .platformer: return "figure.run"
        case .puzzle: return "puzzlepiece.fill"
        case .adventure: return "map.fill"
        case .sports: return "sportscourt.fill"
        case .racing: return "flag.checkered"
        case .sim: return "slider.horizontal.3"
        case .indie: return "sparkles"
        case .fighting: return "figure.boxing"
        case .horror: return "moon.stars.fill"
        case .mmo: return "person.3.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum GameStatus: String, Codable, CaseIterable, Identifiable {
    case backlog
    case playing
    case completed
    case abandoned
    case wishlist

    var id: String { rawValue }

    var label: String {
        switch self {
        case .backlog: return "Backlog"
        case .playing: return "Playing"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        case .wishlist: return "Wishlist"
        }
    }

    var symbol: String {
        switch self {
        case .backlog: return "tray.full.fill"
        case .playing: return "play.circle.fill"
        case .completed: return "checkmark.seal.fill"
        case .abandoned: return "xmark.bin.fill"
        case .wishlist: return "star.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .backlog: return Theme.info
        case .playing: return Theme.accent
        case .completed: return Theme.success
        case .abandoned: return Theme.danger
        case .wishlist: return Theme.warning
        }
    }
}
