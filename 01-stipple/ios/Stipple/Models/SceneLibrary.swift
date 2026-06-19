import SwiftUI

// MARK: - Scene Data

struct PixelSceneData: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let category: SceneCategory
    let isPro: Bool
    let width: Int
    let height: Int
    let palette: [Color]
    let paletteNames: [String]
    // Cells: palette index (0-based). Rendered from shapes at init.
    let cells: [Int]

    enum SceneCategory: String, CaseIterable {
        case nature = "Nature"
        case animals = "Animals"
        case food = "Food"
        case places = "Places"
        case holidays = "Holidays"
    }
}

// MARK: - Scene Library

enum SceneLibrary {
    static let all: [PixelSceneData] = [
        makeHouse(),
        makeSunflower(),
        makeCat(),
        makeMushroom(),
        makeRocket(),
        makeButterfly(),
        makePizza(),
        makeBeach(),
        makeOwl(),
        makeStrawberry(),
        makeChristmasTree(),
        makeRainbow(),
        makeHotAirBalloon(),
        makeApple(),
        makeSnowman()
    ]

    static var free: [PixelSceneData] { all.filter { !$0.isPro } }
    static var pro: [PixelSceneData] { all.filter { $0.isPro } }

    // MARK: - Scene Renderers

    private static func makeHouse() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#87CEEB"), // 0: sky blue
            Color(hex: "#E74C3C"), // 1: red roof
            Color(hex: "#DEB887"), // 2: tan walls
            Color(hex: "#8B4513"), // 3: brown door
            Color(hex: "#4CAF50"), // 4: green grass
            Color(hex: "#ECF0F1")  // 5: white windows
        ]
        var cells = [Int](repeating: 0, count: w * h)
        func fill(x: Int, y: Int, w: Int, h: Int, c: Int, grid: inout [Int], gw: Int) {
            for row in y..<(y+h) {
                for col in x..<(x+w) {
                    if row >= 0 && row < 20 && col >= 0 && col < gw {
                        grid[row * gw + col] = c
                    }
                }
            }
        }
        // Sky
        fill(x: 0, y: 0, w: 20, h: 17, c: 0, grid: &cells, gw: w)
        // Grass
        fill(x: 0, y: 17, w: 20, h: 3, c: 4, grid: &cells, gw: w)
        // Walls
        fill(x: 2, y: 10, w: 16, h: 8, c: 2, grid: &cells, gw: w)
        // Roof (triangle approximation)
        for row in 0..<8 {
            let spread = row * 2
            let left = 8 - spread / 2
            let right = 12 + spread / 2
            for col in max(0, left)...min(19, right) {
                cells[(row + 3) * w + col] = 1
            }
        }
        // Windows
        fill(x: 3, y: 12, w: 4, h: 3, c: 5, grid: &cells, gw: w)
        fill(x: 13, y: 12, w: 4, h: 3, c: 5, grid: &cells, gw: w)
        // Door
        fill(x: 8, y: 14, w: 4, h: 4, c: 3, grid: &cells, gw: w)
        return PixelSceneData(id: "house", name: "Cozy House", emoji: "🏠",
            category: .places, isPro: false, width: w, height: h,
            palette: palette, paletteNames: ["Sky", "Roof", "Walls", "Door", "Grass", "Window"],
            cells: cells)
    }

    private static func makeSunflower() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#87CEEB"), // 0: sky
            Color(hex: "#F4D03F"), // 1: yellow petal
            Color(hex: "#784212"), // 2: brown center
            Color(hex: "#27AE60"), // 3: green stem
            Color(hex: "#1E8449")  // 4: dark green leaf
        ]
        var cells = [Int](repeating: 0, count: w * h)
        // Sky fill
        for i in 0..<(w*h) { cells[i] = 0 }
        // Stem
        for y in 11...19 { cells[y * w + 10] = 3; cells[y * w + 9] = 3 }
        // Leaves
        for y in 14...16 { cells[y * w + 7] = 4 }
        for y in 15...17 { cells[y * w + 12] = 4 }
        // Flower center (circle-like, 3x3)
        for dy in -1...1 { for dx in -1...1 { cells[(9+dy)*w+(10+dx)] = 2 } }
        // Petals (8 directions)
        let petalOffsets = [(-3,0),(-3,-1),(3,0),(3,-1),(0,-3),(-1,-3),(0,3),(-1,3),
                            (-2,-2),(-2,1),(2,-2),(2,1),(-2,2),(1,-2),(2,2),(1,2)]
        for (dy, dx) in petalOffsets {
            let py = 9 + dy, px = 10 + dx
            if py >= 0 && py < h && px >= 0 && px < w { cells[py*w+px] = 1 }
        }
        for (dy, dx) in [(-1,-2),(0,-2),(1,-2),(-1,2),(0,2),(1,2),(-2,-1),(-2,0),(-2,1),(2,-1),(2,0),(2,1)] {
            let py = 9+dy, px = 10+dx
            if py >= 0 && py < h && px >= 0 && px < w { cells[py*w+px] = 1 }
        }
        return PixelSceneData(id: "sunflower", name: "Sunflower", emoji: "🌻",
            category: .nature, isPro: false, width: w, height: h,
            palette: palette, paletteNames: ["Sky", "Petal", "Center", "Stem", "Leaf"],
            cells: cells)
    }

    private static func makeCat() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#F5F5F5"), // 0: white bg
            Color(hex: "#B0B0B0"), // 1: gray body
            Color(hex: "#6D6D6D"), // 2: dark gray
            Color(hex: "#FFB6C1"), // 3: pink nose/inner ear
            Color(hex: "#228B22"), // 4: green eyes
            Color(hex: "#000000")  // 5: black pupils/outline
        ]
        var cells = [Int](repeating: 0, count: w * h)
        // Head oval (roughly)
        for y in 3...14 {
            for x in 3...16 {
                let dx = Double(x - 9), dy = Double(y - 9)
                if dx*dx/36.0 + dy*dy/30.0 < 1.0 { cells[y*w+x] = 1 }
            }
        }
        // Ears
        for y in 1...4 { for x in 3...6 { if x+y < 10 { cells[y*w+x] = 1 } } }
        for y in 1...4 { for x in 13...16 { if (19-x)+y < 10 { cells[y*w+x] = 1 } } }
        // Inner ears
        cells[3*w+4] = 3; cells[3*w+5] = 3; cells[2*w+5] = 3
        cells[3*w+14] = 3; cells[3*w+13] = 3; cells[2*w+14] = 3
        // Eyes
        for dx in -1...1 { for dy in -1...1 { cells[(7+dy)*w+(6+dx)] = 4; cells[(7+dy)*w+(13+dx)] = 4 } }
        cells[7*w+6] = 5; cells[7*w+13] = 5  // pupils
        // Nose
        cells[10*w+9] = 3; cells[10*w+10] = 3; cells[9*w+9] = 3
        // Mouth
        cells[11*w+8] = 2; cells[11*w+11] = 2; cells[12*w+9] = 2; cells[12*w+10] = 2
        // Whiskers
        cells[10*w+4] = 2; cells[10*w+3] = 2; cells[10*w+16] = 2; cells[10*w+17] = 2
        cells[11*w+4] = 2; cells[11*w+3] = 2; cells[11*w+16] = 2; cells[11*w+17] = 2
        // Body
        for y in 14...19 {
            for x in 4...15 {
                let dx = Double(x-9), dy = Double(y-17)
                if dx*dx/30.0 + dy*dy/10.0 < 1.0 { cells[y*w+x] = 1 }
            }
        }
        // Tail
        cells[17*w+15] = 1; cells[17*w+16] = 1; cells[16*w+17] = 1
        cells[15*w+18] = 2; cells[16*w+18] = 2
        return PixelSceneData(id: "cat", name: "Sleepy Cat", emoji: "🐱",
            category: .animals, isPro: false, width: w, height: h,
            palette: palette, paletteNames: ["Background", "Fur", "Dark Fur", "Pink", "Eyes", "Outline"],
            cells: cells)
    }

    private static func makeMushroom() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#90EE90"), // 0: green grass
            Color(hex: "#E74C3C"), // 1: red cap
            Color(hex: "#FFFFFF"), // 2: white spots & stem
            Color(hex: "#F5F5DC")  // 3: cream stem shadow
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Grass base
        for y in 15...19 { for x in 0..<w { cells[y*w+x] = 0 } }
        // Stem
        for y in 11...15 { for x in 8...11 { cells[y*w+x] = 2 } }
        for y in 11...15 { for x in 9...10 { cells[y*w+x] = 3 } }
        // Cap (half-circle)
        for y in 4...11 {
            for x in 0...19 {
                let dx = Double(x-9), dy = Double(y-11)
                if dx*dx/49.0 + dy*dy/49.0 < 1.0 && dy <= 0 { cells[y*w+x] = 1 }
            }
        }
        // White spots
        for (py, px) in [(6,6),(6,12),(8,4),(8,14),(5,9),(7,8),(7,11)] {
            if py < h && px < w {
                cells[py*w+px] = 2
                if px+1 < w { cells[py*w+px+1] = 2 }
                if py+1 < h { cells[(py+1)*w+px] = 2 }
            }
        }
        return PixelSceneData(id: "mushroom", name: "Magic Mushroom", emoji: "🍄",
            category: .nature, isPro: false, width: w, height: h,
            palette: palette, paletteNames: ["Grass", "Red Cap", "White", "Cream"],
            cells: cells)
    }

    private static func makeRocket() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#0A0A2E"), // 0: dark space
            Color(hex: "#C0C0C0"), // 1: silver rocket body
            Color(hex: "#E74C3C"), // 2: red nose cone & fins
            Color(hex: "#3498DB"), // 3: blue window
            Color(hex: "#F39C12"), // 4: orange flame
            Color(hex: "#F1C40F")  // 5: yellow flame
        ]
        var cells = [Int](repeating: 0, count: w * h)
        // Space background
        for i in 0..<w*h { cells[i] = 0 }
        // Stars (white = color 1 reused)
        for (sy, sx) in [(1,3),(2,15),(4,7),(3,18),(6,2),(7,16),(9,5),(0,12)] {
            if sy < h && sx < w { cells[sy*w+sx] = 1 }
        }
        // Rocket body
        for y in 6...15 { for x in 8...11 { cells[y*w+x] = 1 } }
        // Nose cone
        cells[3*w+9] = 2; cells[3*w+10] = 2
        cells[4*w+8] = 2; cells[4*w+9] = 2; cells[4*w+10] = 2; cells[4*w+11] = 2
        cells[5*w+8] = 2; cells[5*w+11] = 2
        // Window
        cells[9*w+9] = 3; cells[9*w+10] = 3
        cells[10*w+9] = 3; cells[10*w+10] = 3
        // Fins
        for y in 13...15 { cells[y*w+6] = 2; cells[y*w+7] = 2 }
        for y in 13...15 { cells[y*w+12] = 2; cells[y*w+13] = 2 }
        cells[13*w+7] = 2; cells[13*w+12] = 2
        // Flames
        for y in 16...17 { cells[y*w+9] = 4; cells[y*w+10] = 4 }
        cells[17*w+8] = 5; cells[17*w+11] = 5
        cells[18*w+9] = 5; cells[18*w+10] = 5
        cells[19*w+9] = 4
        return PixelSceneData(id: "rocket", name: "Rocket Ship", emoji: "🚀",
            category: .places, isPro: false, width: w, height: h,
            palette: palette, paletteNames: ["Space", "Silver", "Red", "Window", "Orange Flame", "Yellow Flame"],
            cells: cells)
    }

    private static func makeButterfly() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#E8F5E9"), // 0: light bg
            Color(hex: "#FF7043"), // 1: orange wing
            Color(hex: "#FFF176"), // 2: yellow wing
            Color(hex: "#212121"), // 3: black body/outline
            Color(hex: "#AB47BC")  // 4: purple wing tip
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Body
        for y in 7...13 { cells[y*w+9] = 3; cells[y*w+10] = 3 }
        // Antennae
        cells[4*w+7] = 3; cells[5*w+8] = 3; cells[6*w+9] = 3
        cells[4*w+12] = 3; cells[5*w+11] = 3; cells[6*w+10] = 3
        // Upper left wing
        for y in 5...10 {
            for x in 1...8 {
                let dx = Double(x-8), dy = Double(y-9)
                if dx*dx/36.0 + dy*dy/20.0 < 1.0 { cells[y*w+x] = 1 }
            }
        }
        // Upper right wing
        for y in 5...10 {
            for x in 11...18 {
                let dx = Double(x-11), dy = Double(y-9)
                if dx*dx/36.0 + dy*dy/20.0 < 1.0 { cells[y*w+x] = 1 }
            }
        }
        // Lower wings (smaller, yellow)
        for y in 10...15 {
            for x in 2...8 {
                let dx = Double(x-7), dy = Double(y-11)
                if dx*dx/25.0 + dy*dy/16.0 < 1.0 { cells[y*w+x] = 2 }
            }
        }
        for y in 10...15 {
            for x in 11...17 {
                let dx = Double(x-12), dy = Double(y-11)
                if dx*dx/25.0 + dy*dy/16.0 < 1.0 { cells[y*w+x] = 2 }
            }
        }
        // Wing tips
        cells[5*w+2] = 4; cells[5*w+3] = 4; cells[6*w+2] = 4
        cells[5*w+16] = 4; cells[5*w+17] = 4; cells[6*w+17] = 4
        return PixelSceneData(id: "butterfly", name: "Butterfly", emoji: "🦋",
            category: .animals, isPro: false, width: w, height: h,
            palette: palette, paletteNames: ["Background", "Orange Wing", "Yellow Wing", "Black", "Purple"],
            cells: cells)
    }

    private static func makePizza() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#FFF8E1"), // 0: light bg
            Color(hex: "#D2691E"), // 1: crust
            Color(hex: "#F4A460"), // 2: dough
            Color(hex: "#E53935"), // 3: tomato sauce
            Color(hex: "#FFFDE7"), // 4: cheese
            Color(hex: "#4CAF50"), // 5: green olive/basil
            Color(hex: "#B71C1C")  // 6: pepperoni
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Pizza circle
        for y in 1...18 {
            for x in 1...18 {
                let dx = Double(x-9), dy = Double(y-9)
                let dist = sqrt(dx*dx + dy*dy)
                if dist < 8.5 {
                    if dist > 7.0 { cells[y*w+x] = 1 }  // crust
                    else if dist > 6.0 { cells[y*w+x] = 2 }  // dough rim
                    else { cells[y*w+x] = 3 }  // sauce
                }
            }
        }
        // Cheese dollops
        for (py, px) in [(6,7),(7,11),(9,6),(10,12),(12,8),(11,10),(8,9)] {
            cells[py*w+px] = 4
            if px+1 < w { cells[py*w+px+1] = 4 }
            if py+1 < h && py < 18 { cells[(py+1)*w+px] = 4 }
        }
        // Pepperoni
        for (py, px) in [(6,9),(8,7),(9,11),(11,6),(12,11),(10,9)] {
            cells[py*w+px] = 6
        }
        // Basil
        cells[7*w+13] = 5; cells[12*w+5] = 5; cells[5*w+12] = 5
        return PixelSceneData(id: "pizza", name: "Pizza Slice", emoji: "🍕",
            category: .food, isPro: true, width: w, height: h,
            palette: palette, paletteNames: ["Background", "Crust", "Dough", "Sauce", "Cheese", "Basil", "Pepperoni"],
            cells: cells)
    }

    private static func makeBeach() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#64B5F6"), // 0: sky blue
            Color(hex: "#F9A825"), // 1: sun yellow
            Color(hex: "#1976D2"), // 2: ocean blue
            Color(hex: "#FFF176"), // 3: sand
            Color(hex: "#388E3C"), // 4: palm green
            Color(hex: "#5D4037")  // 5: palm trunk brown
        ]
        var cells = [Int](repeating: 0, count: w * h)
        // Sky
        for y in 0...9 { for x in 0..<w { cells[y*w+x] = 0 } }
        // Ocean
        for y in 10...13 { for x in 0..<w { cells[y*w+x] = 2 } }
        // Sand
        for y in 14...19 { for x in 0..<w { cells[y*w+x] = 3 } }
        // Sun
        for y in 1...4 { for x in 13...17 {
            let dx = Double(x-15), dy = Double(y-3)
            if dx*dx + dy*dy < 4.0 { cells[y*w+x] = 1 }
        } }
        // Sun rays
        cells[0*w+15] = 1; cells[4*w+19] = 1; cells[4*w+11] = 1
        // Palm trunk
        for y in 7...14 { cells[y*w+5] = 5 }
        cells[6*w+6] = 5; cells[5*w+7] = 5
        // Palm leaves
        for x in 0...4 { cells[4*w+x] = 4 }
        for x in 6...10 { cells[3*w+x] = 4 }
        cells[5*w+4] = 4; cells[5*w+3] = 4
        cells[2*w+9] = 4; cells[2*w+10] = 4
        return PixelSceneData(id: "beach", name: "Tropical Beach", emoji: "🏖️",
            category: .places, isPro: true, width: w, height: h,
            palette: palette, paletteNames: ["Sky", "Sun", "Ocean", "Sand", "Palm", "Trunk"],
            cells: cells)
    }

    private static func makeOwl() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#1A237E"), // 0: night sky
            Color(hex: "#8D6E63"), // 1: brown owl body
            Color(hex: "#FFFFFF"), // 2: white face disk
            Color(hex: "#F9A825"), // 3: yellow eyes/beak
            Color(hex: "#4E342E"), // 4: dark brown
            Color(hex: "#FFF9C4")  // 5: cream belly
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Stars
        for (sy, sx) in [(1,2),(2,17),(3,9),(1,14),(4,5),(0,18)] {
            if sy < h && sx < w { cells[sy*w+sx] = 2 }
        }
        // Branch
        for x in 0..<w { cells[17*w+x] = 4 }
        // Owl body
        for y in 6...16 { for x in 6...13 {
            let dx = Double(x-9), dy = Double(y-12)
            if dx*dx/16.0 + dy*dy/25.0 < 1.0 { cells[y*w+x] = 1 }
        } }
        // Belly
        for y in 10...15 { for x in 8...11 { cells[y*w+x] = 5 } }
        // Face disk
        for y in 5...10 { for x in 6...13 {
            let dx = Double(x-9), dy = Double(y-8)
            if dx*dx/16.0 + dy*dy/9.0 < 1.0 { cells[y*w+x] = 2 }
        } }
        // Ears
        cells[4*w+7] = 1; cells[3*w+7] = 1; cells[3*w+8] = 1
        cells[4*w+12] = 1; cells[3*w+12] = 1; cells[3*w+11] = 1
        // Eyes
        cells[7*w+7] = 3; cells[7*w+8] = 3; cells[8*w+7] = 3; cells[8*w+8] = 3
        cells[7*w+11] = 3; cells[7*w+12] = 3; cells[8*w+11] = 3; cells[8*w+12] = 3
        cells[7*w+8] = 4; cells[8*w+11] = 4  // pupils
        // Beak
        cells[9*w+9] = 3; cells[9*w+10] = 3; cells[10*w+9] = 3
        return PixelSceneData(id: "owl", name: "Night Owl", emoji: "🦉",
            category: .animals, isPro: true, width: w, height: h,
            palette: palette, paletteNames: ["Night Sky", "Brown", "White", "Yellow", "Dark Brown", "Cream"],
            cells: cells)
    }

    private static func makeStrawberry() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#FAFAFA"), // 0: white bg
            Color(hex: "#E53935"), // 1: red berry
            Color(hex: "#FFCDD2"), // 2: light red
            Color(hex: "#4CAF50"), // 3: green leaves/stem
            Color(hex: "#FFFDE7")  // 4: yellow seeds
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Berry shape (heart-ish rounded triangle)
        for y in 4...17 {
            for x in 3...16 {
                let dx = Double(x-9), dy = Double(y-10)
                // Rounded cone/triangle: narrowing toward bottom
                let halfWidth = max(0.0, 7.0 - max(0.0, dy) * 0.5)
                if abs(dx) <= halfWidth && y >= 4 && y <= 17 {
                    // Top rounding
                    if y < 7 {
                        let r = Double(3 - (y - 4))
                        if dx*dx + Double((y-6)*(y-6)) < 16.0 || (y > 4 && abs(dx) < halfWidth) {
                            cells[y*w+x] = 1
                        }
                    } else {
                        cells[y*w+x] = 1
                    }
                }
            }
        }
        // Lighter inside
        for y in 6...15 {
            for x in 6...13 {
                let dx = Double(x-9), dy = Double(y-10)
                let halfWidth = max(0.0, 4.0 - max(0.0, dy) * 0.3)
                if abs(dx) <= halfWidth { cells[y*w+x] = 2 }
            }
        }
        // Seeds
        for (sy, sx) in [(7,8),(7,11),(9,7),(9,10),(9,13),(11,8),(11,12),(13,9),(13,11)] {
            if sy < h && sx < w { cells[sy*w+sx] = 4 }
        }
        // Leaves (top)
        cells[2*w+9] = 3; cells[2*w+10] = 3
        cells[3*w+8] = 3; cells[3*w+11] = 3; cells[3*w+9] = 3; cells[3*w+10] = 3
        cells[2*w+7] = 3; cells[2*w+12] = 3
        cells[1*w+8] = 3; cells[1*w+11] = 3
        return PixelSceneData(id: "strawberry", name: "Strawberry", emoji: "🍓",
            category: .food, isPro: true, width: w, height: h,
            palette: palette, paletteNames: ["Background", "Red", "Light Red", "Green", "Yellow Seeds"],
            cells: cells)
    }

    private static func makeChristmasTree() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#E8F5E9"), // 0: light bg / snow
            Color(hex: "#2E7D32"), // 1: dark green tree
            Color(hex: "#81C784"), // 2: light green
            Color(hex: "#F9A825"), // 3: gold star/lights
            Color(hex: "#E53935"), // 4: red ornaments
            Color(hex: "#8D6E63")  // 5: brown trunk
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Three tiers of tree
        // Bottom tier
        for y in 12...15 { let hw = (y-11)*2; for x in (10-hw)...(10+hw) { if x >= 0 && x < w { cells[y*w+x] = 1 } } }
        // Middle tier
        for y in 8...12 { let hw = (y-7)*2; for x in (10-hw)...(10+hw) { if x >= 0 && x < w { cells[y*w+x] = 1 } } }
        // Top tier
        for y in 4...9 { let hw = (y-3)*1; for x in (10-hw)...(10+hw) { if x >= 0 && x < w { cells[y*w+x] = 2 } } }
        // Star on top
        cells[2*w+9] = 3; cells[2*w+10] = 3; cells[3*w+9] = 3; cells[3*w+10] = 3
        cells[2*w+8] = 3; cells[2*w+11] = 3
        // Trunk
        cells[16*w+9] = 5; cells[16*w+10] = 5; cells[17*w+9] = 5; cells[17*w+10] = 5
        // Snow base
        for x in 0..<w { cells[18*w+x] = 0; cells[19*w+x] = 0 }
        // Ornaments
        for (oy, ox) in [(7,8),(7,12),(10,7),(10,13),(13,8),(13,12),(14,10)] {
            if oy < h && ox < w { cells[oy*w+ox] = 4 }
        }
        // Light strings
        for (oy, ox) in [(6,9),(9,9),(12,9),(9,11),(6,11),(12,11)] {
            if oy < h && ox < w { cells[oy*w+ox] = 3 }
        }
        return PixelSceneData(id: "christmas", name: "Christmas Tree", emoji: "🎄",
            category: .holidays, isPro: true, width: w, height: h,
            palette: palette, paletteNames: ["Snow", "Dark Green", "Light Green", "Gold", "Red", "Brown"],
            cells: cells)
    }

    private static func makeRainbow() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#87CEEB"), // 0: sky
            Color(hex: "#E53935"), // 1: red arc
            Color(hex: "#FF9800"), // 2: orange
            Color(hex: "#F9A825"), // 3: yellow
            Color(hex: "#4CAF50"), // 4: green
            Color(hex: "#1976D2"), // 5: blue
            Color(hex: "#7B1FA2"), // 6: violet
            Color(hex: "#FFFFFF")  // 7: clouds
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Rainbow arcs (semicircles at different radii)
        let cx = 10.0, cy = 17.0
        let arcColors: [(Int, Double, Double)] = [(1,13,14.5),(2,11.5,13),(3,10,11.5),(4,8.5,10),(5,7,8.5),(6,5.5,7)]
        for (col, rMin, rMax) in arcColors {
            for y in 0...17 {
                for x in 0..<w {
                    let dx = Double(x)-cx, dy = Double(y)-cy
                    let dist = sqrt(dx*dx+dy*dy)
                    if dist >= rMin && dist <= rMax && dy <= 0 { cells[y*w+x] = col }
                }
            }
        }
        // Clouds
        for (cy2, cx2) in [(2,3),(3,3),(2,4),(2,15),(3,15),(2,16)] {
            if cy2 < h && cx2 < w { cells[cy2*w+cx2] = 7 }
        }
        // Ground / grass
        for x in 0..<w { cells[18*w+x] = 4; cells[19*w+x] = 4 }
        return PixelSceneData(id: "rainbow", name: "Rainbow", emoji: "🌈",
            category: .nature, isPro: true, width: w, height: h,
            palette: palette, paletteNames: ["Sky", "Red", "Orange", "Yellow", "Green", "Blue", "Violet", "White"],
            cells: cells)
    }

    private static func makeHotAirBalloon() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#B3E5FC"), // 0: light blue sky
            Color(hex: "#E53935"), // 1: red stripe
            Color(hex: "#F9A825"), // 2: yellow stripe
            Color(hex: "#4CAF50"), // 3: green stripe
            Color(hex: "#8D6E63"), // 4: basket brown
            Color(hex: "#BDBDBD")  // 5: rope gray
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Balloon (oval)
        let stripeCols = [1,2,3,1,2,3]
        for y in 1...12 {
            for x in 3...16 {
                let dx = Double(x-9), dy = Double(y-7)
                if dx*dx/36.0 + dy*dy/36.0 < 1.0 {
                    // Stripes by x column
                    let stripeIdx = (x / 3) % 6
                    cells[y*w+x] = stripeCols[min(stripeIdx, stripeCols.count-1)]
                }
            }
        }
        // Ropes
        cells[13*w+7] = 5; cells[13*w+12] = 5
        cells[14*w+8] = 5; cells[14*w+11] = 5
        // Basket
        for y in 15...17 { for x in 7...12 { cells[y*w+x] = 4 } }
        // Little people (simplified)
        cells[14*w+9] = 0; cells[14*w+10] = 0
        return PixelSceneData(id: "balloon", name: "Hot Air Balloon", emoji: "🎈",
            category: .places, isPro: true, width: w, height: h,
            palette: palette, paletteNames: ["Sky", "Red", "Yellow", "Green", "Basket", "Rope"],
            cells: cells)
    }

    private static func makeApple() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#FAFAFA"), // 0: bg
            Color(hex: "#E53935"), // 1: red apple
            Color(hex: "#EF9A9A"), // 2: light red highlight
            Color(hex: "#4CAF50"), // 3: green leaf
            Color(hex: "#795548"), // 4: brown stem
            Color(hex: "#FFEB3B")  // 5: yellow shine
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Apple body
        for y in 4...17 {
            for x in 3...16 {
                let dx = Double(x-9), dy = Double(y-11)
                if dx*dx/36.0 + dy*dy/36.0 < 1.0 { cells[y*w+x] = 1 }
            }
        }
        // Highlight
        for y in 5...8 { for x in 5...8 {
            let dx = Double(x-6), dy = Double(y-6)
            if dx*dx+dy*dy < 5.0 { cells[y*w+x] = 2 }
        } }
        // Shine dot
        cells[6*w+7] = 5
        // Indent at top
        cells[3*w+9] = 0; cells[3*w+10] = 0; cells[4*w+9] = 0; cells[4*w+10] = 0
        // Stem
        cells[2*w+10] = 4; cells[1*w+11] = 4
        // Leaf
        cells[2*w+11] = 3; cells[1*w+12] = 3; cells[2*w+12] = 3; cells[1*w+13] = 3
        return PixelSceneData(id: "apple", name: "Red Apple", emoji: "🍎",
            category: .food, isPro: true, width: w, height: h,
            palette: palette, paletteNames: ["Background", "Red", "Light Red", "Green", "Brown", "Yellow"],
            cells: cells)
    }

    private static func makeSnowman() -> PixelSceneData {
        let w = 20, h = 20
        let palette: [Color] = [
            Color(hex: "#B3E5FC"), // 0: winter sky
            Color(hex: "#ECEFF1"), // 1: white snow body
            Color(hex: "#E53935"), // 2: red scarf
            Color(hex: "#212121"), // 3: black hat/eyes/buttons
            Color(hex: "#FF9800"), // 4: orange carrot nose
            Color(hex: "#FFFDE7")  // 5: light yellow snow ground
        ]
        var cells = [Int](repeating: 0, count: w * h)
        for i in 0..<w*h { cells[i] = 0 }
        // Snow ground
        for y in 17...19 { for x in 0..<w { cells[y*w+x] = 5 } }
        // Bottom ball
        for y in 11...17 { for x in 4...15 {
            let dx = Double(x-9), dy = Double(y-15)
            if dx*dx/25.0+dy*dy/16.0 < 1.0 { cells[y*w+x] = 1 }
        } }
        // Top ball (head)
        for y in 4...11 { for x in 5...14 {
            let dx = Double(x-9), dy = Double(y-8)
            if dx*dx/16.0+dy*dy/16.0 < 1.0 { cells[y*w+x] = 1 }
        } }
        // Hat brim & top
        for x in 5...13 { cells[3*w+x] = 3 }
        for y in 0...3 { for x in 7...12 { cells[y*w+x] = 3 } }
        // Eyes
        cells[6*w+7] = 3; cells[6*w+11] = 3
        // Nose
        cells[8*w+9] = 4; cells[8*w+10] = 4
        // Smile
        for (sy, sx) in [(10,7),(10,11),(11,8),(11,10)] { cells[sy*w+sx] = 3 }
        // Scarf
        for x in 5...13 { cells[11*w+x] = 2 }
        cells[12*w+5] = 2; cells[12*w+6] = 2
        // Buttons
        for sy in [13,14,15] { cells[sy*w+9] = 3 }
        return PixelSceneData(id: "snowman", name: "Snowman", emoji: "☃️",
            category: .holidays, isPro: true, width: w, height: h,
            palette: palette, paletteNames: ["Sky", "White", "Red Scarf", "Black", "Orange", "Snow"],
            cells: cells)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
