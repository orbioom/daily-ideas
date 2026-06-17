import Foundation

// MARK: - Fast seeded RNG (allocation-free, value type)

/// SplitMix64 — a tiny, fast, allocation-free PRNG suitable for the audio
/// thread. Each generator owns its own instance so render is deterministic
/// per-generator and never touches the system RNG (which can allocate/lock).
struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state.
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func nextU64() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A uniform Float in [-1, 1).
    mutating func nextBipolar() -> Float {
        // Use the top 24 bits for a Float mantissa-friendly value.
        let bits = nextU64() >> 40                // 24 bits → [0, 2^24)
        let unit = Float(bits) * (1.0 / 16_777_216.0)  // [0, 1)
        return unit * 2.0 - 1.0
    }

    /// A uniform Float in [0, 1).
    mutating func nextUnit() -> Float {
        let bits = nextU64() >> 40
        return Float(bits) * (1.0 / 16_777_216.0)
    }
}

// MARK: - One-pole filters (value types, no allocation)

/// A one-pole low-pass filter. `coef` in (0,1); higher = more smoothing.
struct OnePoleLP {
    var z: Float = 0
    var coef: Float

    init(coef: Float) { self.coef = min(0.9999, max(0.0001, coef)) }

    mutating func process(_ x: Float) -> Float {
        z = z + coef * (x - z)
        return z
    }
}

/// A one-pole high-pass derived from the low-pass complement.
struct OnePoleHP {
    var lp: OnePoleLP
    init(coef: Float) { lp = OnePoleLP(coef: coef) }
    mutating func process(_ x: Float) -> Float {
        return x - lp.process(x)
    }
}

// MARK: - Generator protocol

/// A pure-DSP sound generator. `render` produces the next sample given internal
/// state. Implementations MUST NOT allocate or lock — they run on the audio
/// thread. `sampleRate` is supplied at construction.
protocol SoundGenerator {
    /// Produce the next mono sample, nominally in [-1, 1] (the engine clamps).
    mutating func render() -> Float
}

// MARK: - White noise

struct WhiteNoiseGen: SoundGenerator {
    private var rng: SplitMix64
    init(seed: UInt64) { rng = SplitMix64(seed: seed) }
    mutating func render() -> Float {
        rng.nextBipolar() * 0.5
    }
}

// MARK: - Pink noise (Paul Kellet's economical −3dB/oct filter)

struct PinkNoiseGen: SoundGenerator {
    private var rng: SplitMix64
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0
    private var b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0

    init(seed: UInt64) { rng = SplitMix64(seed: seed) }

    mutating func render() -> Float {
        let w = rng.nextBipolar()
        b0 = 0.99886 * b0 + w * 0.0555179
        b1 = 0.99332 * b1 + w * 0.0750759
        b2 = 0.96900 * b2 + w * 0.1538520
        b3 = 0.86650 * b3 + w * 0.3104856
        b4 = 0.55000 * b4 + w * 0.5329522
        b5 = -0.7616 * b5 - w * 0.0168980
        let out = b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362
        b6 = w * 0.115926
        return out * 0.11
    }
}

// MARK: - Brown / red noise (leaky integrator of white)

struct BrownNoiseGen: SoundGenerator {
    private var rng: SplitMix64
    private var last: Float = 0
    init(seed: UInt64) { rng = SplitMix64(seed: seed) }

    mutating func render() -> Float {
        let w = rng.nextBipolar()
        last = (last + 0.02 * w) * 0.998   // integrate then leak toward 0
        // Keep bounded.
        if last > 1 { last = 1 } else if last < -1 { last = -1 }
        return last * 3.0
    }
}

// MARK: - Rain (high-passed noise + randomized droplet bursts)

struct RainGen: SoundGenerator {
    private var rng: SplitMix64
    private var hp: OnePoleHP
    private var lp: OnePoleLP
    private var dropletEnv: Float = 0

    init(seed: UInt64, sampleRate: Float) {
        rng = SplitMix64(seed: seed)
        // Shape a "hiss" band: high-pass to thin out the rumble, light low-pass
        // to soften the very top.
        hp = OnePoleHP(coef: 0.05)
        lp = OnePoleLP(coef: 0.6)
    }

    mutating func render() -> Float {
        let w = rng.nextBipolar()
        var s = hp.process(w)
        s = lp.process(s)
        // Steady background rain.
        var out = s * 0.7

        // Sparse droplet bursts: occasionally trigger a fast-decaying envelope.
        if dropletEnv < 0.001 && rng.nextUnit() < 0.0009 {
            dropletEnv = 0.6 + rng.nextUnit() * 0.4
        }
        if dropletEnv > 0.0001 {
            out += s * dropletEnv * 1.4
            dropletEnv *= 0.94    // quick decay (a few ms)
        }
        return out * 0.6
    }
}

// MARK: - Ocean waves (brown noise amplitude-modulated by a slow LFO swell)

struct OceanGen: SoundGenerator {
    private var brown: BrownNoiseGen
    private var phase: Float = 0
    private let phaseInc: Float
    private var swellRng: SplitMix64
    private var swellTarget: Float = 0.5
    private var swell: Float = 0.5

    init(seed: UInt64, sampleRate: Float) {
        brown = BrownNoiseGen(seed: seed ^ 0xA17C)
        swellRng = SplitMix64(seed: seed ^ 0x5151)
        // ~0.08 Hz swell (≈12 s per wave).
        phaseInc = (2.0 * Float.pi * 0.08) / max(1, sampleRate)
    }

    mutating func render() -> Float {
        phase += phaseInc
        if phase > 2 * Float.pi { phase -= 2 * Float.pi }
        // A raised-cosine swell, plus a slowly drifting amplitude target so no
        // two waves are identical.
        if swellRng.nextUnit() < 0.00002 {
            swellTarget = 0.35 + swellRng.nextUnit() * 0.55
        }
        swell += 0.0005 * (swellTarget - swell)
        let lfo = (sin(phase) * 0.5 + 0.5)        // 0…1
        let amp = lfo * lfo * swell                // squared for a steeper swell
        return brown.render() * amp * 0.9
    }
}

// MARK: - Wind (band-passed noise modulated by a slow random LFO)

struct WindGen: SoundGenerator {
    private var rng: SplitMix64
    private var hp: OnePoleHP
    private var lp: OnePoleLP
    private var gustRng: SplitMix64
    private var gust: Float = 0.4
    private var gustTarget: Float = 0.4

    init(seed: UInt64, sampleRate: Float) {
        rng = SplitMix64(seed: seed)
        gustRng = SplitMix64(seed: seed ^ 0xBEEF)
        // Band-pass: high-pass to remove rumble, low-pass to remove hiss → a
        // mid "whoosh".
        hp = OnePoleHP(coef: 0.02)
        lp = OnePoleLP(coef: 0.18)
    }

    mutating func render() -> Float {
        // Random-walk gust amplitude with occasional new targets.
        if gustRng.nextUnit() < 0.0002 {
            gustTarget = 0.15 + gustRng.nextUnit() * 0.85
        }
        gust += 0.0008 * (gustTarget - gust)

        let w = rng.nextBipolar()
        var s = hp.process(w)
        s = lp.process(s)
        return s * gust * 2.2
    }
}

// MARK: - Stream / brook (high-passed bubbling noise with fast burbles)

struct StreamGen: SoundGenerator {
    private var rng: SplitMix64
    private var hp: OnePoleHP
    private var lp: OnePoleLP
    private var burbleEnv: Float = 0
    private var burblePhase: Float = 0
    private var burbleInc: Float = 0

    init(seed: UInt64, sampleRate: Float) {
        rng = SplitMix64(seed: seed)
        hp = OnePoleHP(coef: 0.12)   // brighter than rain
        lp = OnePoleLP(coef: 0.7)
        self.sampleRate = max(1, sampleRate)
    }

    private let sampleRate: Float

    mutating func render() -> Float {
        let w = rng.nextBipolar()
        var s = hp.process(w)
        s = lp.process(s)
        var out = s * 0.5

        // Bubbling: short pitched chirps (a resonant-ish sine burst).
        if burbleEnv < 0.001 && rng.nextUnit() < 0.004 {
            burbleEnv = 0.5 + rng.nextUnit() * 0.5
            let freq = 600 + rng.nextUnit() * 1800   // 600–2400 Hz
            burbleInc = (2.0 * Float.pi * freq) / sampleRate
            burblePhase = 0
        }
        if burbleEnv > 0.0001 {
            burblePhase += burbleInc
            out += sin(burblePhase) * burbleEnv * 0.35
            burbleEnv *= 0.972
        }
        return out * 0.8
    }
}

// MARK: - Fan / hum (low-passed noise + faint tonal hum)

struct FanGen: SoundGenerator {
    private var rng: SplitMix64
    private var lp1: OnePoleLP
    private var lp2: OnePoleLP
    private var humPhase: Float = 0
    private let humInc: Float
    private var wobblePhase: Float = 0
    private let wobbleInc: Float

    init(seed: UInt64, sampleRate: Float) {
        rng = SplitMix64(seed: seed)
        // Two cascaded low-passes for a soft, airy whir.
        lp1 = OnePoleLP(coef: 0.08)
        lp2 = OnePoleLP(coef: 0.08)
        let sr = max(1, sampleRate)
        humInc = (2.0 * Float.pi * 120.0) / sr      // faint 120 Hz motor hum
        wobbleInc = (2.0 * Float.pi * 0.9) / sr     // slow blade wobble
    }

    mutating func render() -> Float {
        var air = lp1.process(rng.nextBipolar())
        air = lp2.process(air)

        humPhase += humInc
        if humPhase > 2 * Float.pi { humPhase -= 2 * Float.pi }
        wobblePhase += wobbleInc
        if wobblePhase > 2 * Float.pi { wobblePhase -= 2 * Float.pi }

        let wobble = 0.85 + 0.15 * sin(wobblePhase)
        let hum = sin(humPhase) * 0.06
        return (air * 2.4 * wobble + hum) * 0.6
    }
}

// MARK: - Campfire (brown-ish rumble + random crackle pops)

struct FireGen: SoundGenerator {
    private var rng: SplitMix64
    private var lp: OnePoleLP
    private var bed: Float = 0
    private var popEnv: Float = 0

    init(seed: UInt64, sampleRate: Float) {
        rng = SplitMix64(seed: seed)
        lp = OnePoleLP(coef: 0.04)   // low rumble bed
    }

    mutating func render() -> Float {
        // Soft low rumble bed (leaky-integrated, low-passed).
        let w = rng.nextBipolar()
        bed = lp.process(w)
        var out = bed * 1.6

        // Crackle: frequent tiny pops, occasional louder ones.
        if popEnv < 0.001 {
            let r = rng.nextUnit()
            if r < 0.01 {
                popEnv = (r < 0.0015 ? 0.9 : 0.35) + rng.nextUnit() * 0.1
            }
        }
        if popEnv > 0.0001 {
            out += rng.nextBipolar() * popEnv
            popEnv *= 0.6   // very fast decay — a click/crackle
        }
        return out * 0.55
    }
}

// MARK: - Night crickets (modulated band-passed chirps over a faint bed)

struct NightGen: SoundGenerator {
    private var rng: SplitMix64
    private var bedLP: OnePoleLP
    private var chirpPhase: Float = 0
    private let chirpInc: Float
    private var trillPhase: Float = 0
    private let trillInc: Float

    init(seed: UInt64, sampleRate: Float) {
        rng = SplitMix64(seed: seed)
        bedLP = OnePoleLP(coef: 0.05)
        let sr = max(1, sampleRate)
        chirpInc = (2.0 * Float.pi * 4500.0) / sr   // ~4.5 kHz cricket tone
        trillInc = (2.0 * Float.pi * 22.0) / sr     // ~22 Hz trill (chirp rate)
    }

    mutating func render() -> Float {
        // Faint low background.
        let bed = bedLP.process(rng.nextBipolar()) * 0.5

        chirpPhase += chirpInc
        if chirpPhase > 2 * Float.pi { chirpPhase -= 2 * Float.pi }
        trillPhase += trillInc
        if trillPhase > 2 * Float.pi { trillPhase -= 2 * Float.pi }

        // Gate the trill so chirps come in pulses, not continuously.
        let trill = sin(trillPhase)
        let gate: Float = trill > 0.3 ? (trill - 0.3) / 0.7 : 0
        let chirp = sin(chirpPhase) * gate * 0.18

        return bed * 0.4 + chirp
    }
}
