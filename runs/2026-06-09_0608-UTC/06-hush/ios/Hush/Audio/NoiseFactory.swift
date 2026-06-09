import AVFoundation

/// Generates seamless, loopable PCM buffers for each `SoundType` entirely in
/// code. Coloured noise uses standard filters (Paul Kellet's pink filter, a
/// leaky integrator for brown); textured sounds modulate that noise. A short
/// cosine crossfade folds the buffer's tail into its head so looping is gapless.
final class NoiseFactory {
    static let shared = NoiseFactory()

    let sampleRate = 44_100.0
    let duration = 10.0
    let crossfade = 0.06

    private var cache: [SoundType: AVAudioPCMBuffer] = [:]

    func buffer(for type: SoundType) -> AVAudioPCMBuffer? {
        if let cached = cache[type] { return cached }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        else { return nil }

        let frames = Int(sampleRate * duration)
        let xf = max(1, Int(sampleRate * crossfade))
        guard frames > xf else { return nil }

        let raw = generate(type, count: frames + xf)
        guard raw.count == frames + xf else { return nil }

        guard let buf = AVAudioPCMBuffer(pcmFormat: format,
                                         frameCapacity: AVAudioFrameCount(frames)),
              let channel = buf.floatChannelData?[0]
        else { return nil }
        buf.frameLength = AVAudioFrameCount(frames)

        for i in 0..<frames {
            if i < xf {
                // Cosine crossfade: blend the tail (raw[frames+i]) into the head.
                let t = Float(i) / Float(xf)
                let w = 0.5 - 0.5 * cosf(Float.pi * t)   // 0 → 1 smooth
                channel[i] = raw[i] * w + raw[frames + i] * (1 - w)
            } else {
                channel[i] = raw[i]
            }
        }
        cache[type] = buf
        return buf
    }

    private func generate(_ type: SoundType, count: Int) -> [Float] {
        var out = [Float](repeating: 0, count: count)

        var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0, b6 = 0.0
        var brownLast = 0.0
        var lpLast = 0.0
        let sr = sampleRate
        let twoPi = 2.0 * Double.pi

        for i in 0..<count {
            let t = Double(i) / sr
            let white = Double.random(in: -1...1)

            // Pink (Paul Kellet's economy filter).
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            let pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11
            b6 = white * 0.115926

            // Brown (leaky integrator).
            brownLast = (brownLast + 0.02 * white) / 1.02
            let brown = brownLast * 3.5

            var s = 0.0
            switch type {
            case .white:
                s = white * 0.5
            case .pink:
                s = pink
            case .brown:
                s = brown
            case .rain:
                s = pink * 0.6 + white * 0.22
            case .ocean:
                let lfo = 0.5 - 0.5 * cos(twoPi * (1.0 / duration) * t)  // one swell per loop
                let env = 0.12 + 0.88 * pow(lfo, 1.6)
                s = brown * env
            case .wind:
                lpLast += 0.05 * (pink - lpLast)
                let gust = 0.4 + 0.6 * (0.5 - 0.5 * cos(twoPi * (3.0 / duration) * t))
                s = lpLast * gust * 1.7
            case .fan:
                lpLast += 0.08 * (brown - lpLast)
                let hum = sin(twoPi * 120.0 * t) * 0.05
                s = lpLast * 1.3 + hum
            case .drone:
                let base = sin(twoPi * 110.0 * t)
                let fifth = sin(twoPi * 165.0 * t) * 0.5
                let oct = sin(twoPi * 220.0 * t) * 0.25
                s = (base + fifth + oct) * 0.12
            }

            out[i] = Float(max(-1, min(1, s)))
        }
        return out
    }
}
