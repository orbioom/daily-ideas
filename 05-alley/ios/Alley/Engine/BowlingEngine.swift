import Foundation

struct BowlingEngine {

    // Compute running frame scores for one player's balls array.
    // Returns array of up to 10 cumulative frame scores.
    // Each element is nil if score not yet determinable.
    static func frameScores(balls: [Int]) -> [Int?] {
        var scores: [Int?] = []
        var ballIdx = 0
        var cumulative = 0

        for frame in 0..<10 {
            if ballIdx >= balls.count {
                scores.append(nil)
                continue
            }

            if frame == 9 {
                // 10th frame: 2 or 3 balls
                let b1 = balls.count > ballIdx     ? balls[ballIdx]     : -1
                let b2 = balls.count > ballIdx + 1 ? balls[ballIdx + 1] : -1
                let b3 = balls.count > ballIdx + 2 ? balls[ballIdx + 2] : -1

                if b1 < 0 {
                    scores.append(nil)
                    break
                }
                if b1 == 10 {
                    // Strike on first ball of 10th
                    if b2 < 0 || b3 < 0 {
                        scores.append(nil)
                    } else {
                        cumulative += 10 + b2 + b3
                        scores.append(cumulative)
                    }
                } else if b2 >= 0 && b1 + b2 == 10 {
                    // Spare
                    if b3 < 0 {
                        scores.append(nil)
                    } else {
                        cumulative += 10 + b3
                        scores.append(cumulative)
                    }
                } else {
                    // Open frame
                    if b2 < 0 {
                        scores.append(nil)
                    } else {
                        cumulative += b1 + b2
                        scores.append(cumulative)
                    }
                }
            } else {
                let b1 = balls[ballIdx]
                if b1 == 10 {
                    // Strike
                    let b2 = balls.count > ballIdx + 1 ? balls[ballIdx + 1] : -1
                    let b3 = balls.count > ballIdx + 2 ? balls[ballIdx + 2] : -1
                    if b2 < 0 || b3 < 0 {
                        scores.append(nil)
                    } else {
                        cumulative += 10 + b2 + b3
                        scores.append(cumulative)
                    }
                    ballIdx += 1
                } else {
                    let b2 = balls.count > ballIdx + 1 ? balls[ballIdx + 1] : -1
                    if b2 < 0 {
                        scores.append(nil)
                        ballIdx += 1
                    } else if b1 + b2 == 10 {
                        // Spare
                        let b3 = balls.count > ballIdx + 2 ? balls[ballIdx + 2] : -1
                        if b3 < 0 {
                            scores.append(nil)
                        } else {
                            cumulative += 10 + b3
                            scores.append(cumulative)
                        }
                        ballIdx += 2
                    } else {
                        // Open frame
                        cumulative += b1 + b2
                        scores.append(cumulative)
                        ballIdx += 2
                    }
                }
            }
        }
        return scores
    }

    // Returns frame display strings like [("", "X"), ("7", "/"), ("8", "1"), ...]
    // First element is ball 1, second is ball 2 (or combined for 10th frame)
    static func frameDisplayStrings(balls: [Int]) -> [(String, String)] {
        var result: [(String, String)] = []
        var ballIdx = 0

        for frame in 0..<10 {
            if ballIdx >= balls.count { break }

            if frame == 9 {
                let b1 = balls.count > ballIdx     ? balls[ballIdx]     : -1
                let b2 = balls.count > ballIdx + 1 ? balls[ballIdx + 1] : -1
                let b3 = balls.count > ballIdx + 2 ? balls[ballIdx + 2] : -1

                let s1 = b1 == 10 ? "X" : b1 == 0 ? "-" : b1 >= 0 ? "\(b1)" : ""
                let s2: String
                if b2 < 0 {
                    s2 = ""
                } else if b1 == 10 && b2 == 10 {
                    s2 = "X"
                } else if b1 == 10 && b2 == 0 {
                    s2 = "-"
                } else if b1 != 10 && b2 >= 0 && b1 + b2 == 10 {
                    s2 = "/"
                } else {
                    s2 = b2 == 0 ? "-" : "\(b2)"
                }
                let s3: String
                if b3 < 0 {
                    s3 = ""
                } else if b3 == 10 {
                    s3 = "X"
                } else if b3 == 0 {
                    s3 = "-"
                } else {
                    s3 = "\(b3)"
                }
                // For the 10th frame we pack everything into the first string slot
                result.append(("\(s1)\(s2)\(s3)", ""))
            } else {
                let b1 = balls[ballIdx]
                if b1 == 10 {
                    result.append(("", "X"))
                    ballIdx += 1
                } else {
                    let b2 = balls.count > ballIdx + 1 ? balls[ballIdx + 1] : -1
                    let s1 = b1 == 0 ? "-" : "\(b1)"
                    let s2: String
                    if b2 < 0 {
                        s2 = ""
                    } else if b1 + b2 == 10 {
                        s2 = "/"
                    } else if b2 == 0 {
                        s2 = "-"
                    } else {
                        s2 = "\(b2)"
                    }
                    result.append((s1, s2))
                    ballIdx += 2
                }
            }
        }
        return result
    }

    // Returns how many pins can be knocked down on the current (next) ball
    static func maxPinsForBall(balls: [Int]) -> Int {
        var ballIdx = 0

        for frame in 0..<10 {
            if ballIdx >= balls.count { return 10 }

            if frame == 9 {
                let remaining = balls.count - ballIdx
                let b1 = balls[ballIdx]
                if remaining == 0 { return 10 }
                if remaining == 1 {
                    return b1 == 10 ? 10 : 10 - b1
                }
                let b2 = balls[ballIdx + 1]
                if remaining == 2 {
                    if b1 == 10 {
                        return b2 == 10 ? 10 : 10 - b2
                    }
                    // spare in 10th
                    return 10
                }
                // 3 balls done — game over for this player
                return 0
            } else {
                let b1 = balls[ballIdx]
                if b1 == 10 {
                    ballIdx += 1
                    continue
                }
                // First ball of non-strike frame
                if ballIdx + 1 == balls.count {
                    return 10 - b1
                }
                ballIdx += 2
            }
        }
        return 0
    }

    static func isGameComplete(balls: [Int]) -> Bool {
        var ballIdx = 0

        for frame in 0..<10 {
            if frame == 9 {
                let b1 = balls.count > ballIdx     ? balls[ballIdx]     : -1
                if b1 < 0 { return false }
                let b2 = balls.count > ballIdx + 1 ? balls[ballIdx + 1] : -1
                if b2 < 0 { return false }
                if b1 == 10 || b1 + b2 == 10 {
                    return balls.count > ballIdx + 2
                }
                return true
            } else {
                if ballIdx >= balls.count { return false }
                let b1 = balls[ballIdx]
                if b1 == 10 {
                    ballIdx += 1
                } else {
                    if ballIdx + 1 >= balls.count { return false }
                    ballIdx += 2
                }
            }
        }
        return false
    }

    // Returns the current frame index (0-based) for a given balls array
    static func currentFrame(balls: [Int]) -> Int {
        var ballIdx = 0
        for frame in 0..<10 {
            if frame == 9 { return 9 }
            if ballIdx >= balls.count { return frame }
            let b1 = balls[ballIdx]
            if b1 == 10 {
                ballIdx += 1
            } else {
                if ballIdx + 1 >= balls.count { return frame }
                ballIdx += 2
            }
        }
        return 9
    }

    // Returns whether this is the first or second ball in the current frame (0 or 1)
    static func currentBallInFrame(balls: [Int]) -> Int {
        var ballIdx = 0
        for frame in 0..<10 {
            if frame == 9 {
                let pos = balls.count - ballIdx
                return pos  // 0, 1, or 2 inside 10th frame
            }
            if ballIdx >= balls.count { return 0 }
            let b1 = balls[ballIdx]
            if b1 == 10 {
                ballIdx += 1
            } else {
                if ballIdx + 1 >= balls.count { return 1 }
                ballIdx += 2
            }
        }
        return 0
    }
}
