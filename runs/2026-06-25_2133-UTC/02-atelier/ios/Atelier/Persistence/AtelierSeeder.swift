import Foundation
import SwiftData

enum AtelierSeeder {
    static func seed(context: ModelContext) {
        seedSkills(context: context)
        seedSessions(context: context)
        seedGoal(context: context)
        try? context.save()
    }

    static func seedSkills(context: ModelContext) {
        let skillsData: [(String, SkillCategory, SkillStatus)] = [
            ("Gesture Drawing", .drawing, .comfortable),
            ("Contour Lines", .drawing, .mastered),
            ("Value Studies", .drawing, .practicing),
            ("Cross Hatching", .drawing, .comfortable),
            ("Figure Drawing", .anatomy, .learning),
            ("Hand Anatomy", .anatomy, .learning),
            ("Facial Proportions", .anatomy, .practicing),
            ("One-Point Perspective", .perspective, .comfortable),
            ("Two-Point Perspective", .perspective, .practicing),
            ("Foreshortening", .perspective, .learning),
            ("Color Mixing Basics", .color, .comfortable),
            ("Complementary Palettes", .color, .practicing),
            ("Warm/Cool Contrast", .color, .learning),
            ("Rule of Thirds", .composition, .comfortable),
            ("Negative Space", .composition, .practicing),
            ("Leading Lines", .composition, .comfortable),
            ("Rim Lighting", .lighting, .practicing),
            ("Soft Light Studies", .lighting, .learning),
            ("Cast Shadows", .lighting, .comfortable),
            ("Watercolor Wet-on-Wet", .painting, .practicing),
            ("Layering Glazes", .painting, .learning),
            ("Impasto Technique", .painting, .notStarted),
            ("Rendering Fabric", .texture, .learning),
            ("Metal & Glass", .texture, .notStarted),
            ("Developing Personal Voice", .style, .learning),
        ]
        for (name, cat, status) in skillsData {
            context.insert(ArtSkill(name: name, category: cat, status: status))
        }
    }

    static func seedSessions(context: ModelContext) {
        let cal = Calendar.current
        let now = Date.now

        let sessionData: [(Int, Int, ArtMedium, PracticeType, String, String, SessionMood, Int, String)] = [
            // daysAgo, minutes, medium, type, subject, skill, mood, rating, notes
            (1, 90, .pencil, .fundamentals, "Hand study", "Hand Anatomy", .good, 4, "Focused on knuckle structure. Getting better at the thumb joint."),
            (3, 60, .charcoal, .study, "Sphere value study", "Value Studies", .good, 4, "Really nailed the core shadow on this one."),
            (5, 45, .pencil, .exercise, "100 gesture drawings", "Gesture Drawing", .excellent, 5, "Did 2-minute gestures. Flow state! Great session."),
            (7, 120, .watercolor, .fullPiece, "Sunset landscape", "Warm/Cool Contrast", .good, 4, "First attempt at a full watercolor. Learned a lot."),
            (10, 60, .pencil, .study, "Perspective box drill", "Two-Point Perspective", .okay, 3, "Struggled with ellipses in perspective. Need more reps."),
            (12, 75, .ink, .sketch, "Urban sketching", "Contour Lines", .excellent, 5, "Out in the city sketching cafes. Love ink for this."),
            (15, 90, .pencil, .study, "Facial proportions grid", "Facial Proportions", .good, 4, "Loomis method is clicking. The 3/4 view still trips me up."),
            (18, 60, .charcoal, .exercise, "Value scale exercises", "Value Studies", .okay, 3, "Hand tired from previous session. Mediocre result."),
            (20, 120, .acrylic, .fullPiece, "Still life with fruit", "Color Mixing Basics", .good, 4, "Painted apples and a lemon. Color mixing getting more intuitive."),
            (23, 45, .pencil, .exercise, "50 gesture drawings", "Gesture Drawing", .frustrated, 2, "Not feeling it today. Poses looked stiff. Quit early."),
            (25, 90, .pencil, .study, "Figure drawing reference", "Figure Drawing", .good, 4, "Used Croquis Cafe. Torso proportions improving."),
            (28, 60, .pencil, .fundamentals, "Cross-hatching texture", "Cross Hatching", .good, 4, "Varied line spacing experiment. Getting more control."),
            (31, 75, .watercolor, .study, "Color wheel mixing", "Complementary Palettes", .okay, 3, "Muddy mixes from bad water. Started over twice."),
            (34, 120, .pencil, .fullPiece, "Portrait from photo", "Facial Proportions", .excellent, 5, "Best portrait to date! The eyes look alive."),
            (37, 60, .charcoal, .exercise, "Cast shadow studies", "Cast Shadows", .good, 4, "Geometric shapes. Light direction exercises."),
            (40, 90, .ink, .sketch, "Coffee shop sketches", "Contour Lines", .excellent, 5, "3 pages of people. Observation skills sharpening."),
            (44, 60, .pencil, .study, "One-point perspective room", "One-Point Perspective", .good, 4, "Interior perspective study. Feeling solid."),
            (48, 75, .acrylic, .study, "Color harmony swatches", "Complementary Palettes", .good, 4, "Explored triads and split-complementary. Fun!"),
            (52, 90, .pencil, .fundamentals, "Negative space exercises", "Negative Space", .okay, 3, "A bit tedious but I can already see improvement."),
            (56, 60, .pencil, .exercise, "Ellipse drills", "Two-Point Perspective", .frustrated, 2, "Ellipses in perspective are my nemesis. Kept erasing."),
            (60, 120, .watercolor, .fullPiece, "Botanical illustration", "Watercolor Wet-on-Wet", .excellent, 5, "Rose study. Wet-on-wet for soft petals. Turned out beautiful."),
            (65, 90, .pencil, .study, "Foreshortening arm", "Foreshortening", .good, 4, "Using cylinders to simplify. The method is working."),
            (70, 60, .charcoal, .fullPiece, "Dramatic portrait", "Rim Lighting", .good, 4, "Strong side lighting. Deep shadows. Really moody result."),
            (75, 45, .pencil, .freePlay, "Doodling", "Developing Personal Voice", .excellent, 5, "Just played with marks. Found some interesting patterns."),
            (80, 90, .pencil, .study, "Hands: different angles", "Hand Anatomy", .okay, 3, "Palm foreshortening is hard. Slow progress."),
            (85, 75, .ink, .sketch, "Architecture sketches", "Leading Lines", .good, 4, "Used buildings to practice leading lines consciously."),
            (90, 60, .pencil, .fundamentals, "Gesture: animals", "Gesture Drawing", .good, 4, "Animal gesture drawing is a fun change of pace."),
            (95, 90, .acrylic, .study, "Soft light portrait study", "Soft Light Studies", .good, 3, "Overworked the surface. Lesson: know when to stop."),
            (100, 60, .pencil, .exercise, "Box rotation drills", "Two-Point Perspective", .okay, 3, "Grinding through perspective fundamentals."),
            (107, 120, .watercolor, .fullPiece, "Harbor at sunset", "Warm/Cool Contrast", .excellent, 5, "Warm sky vs cool water. This painting is a keeper."),
            (115, 75, .pencil, .study, "Figure gesture × 60", "Figure Drawing", .good, 4, "Timed 30-second poses on posemaniacs. Great warmup."),
            (122, 60, .charcoal, .fundamentals, "Value range study", "Value Studies", .good, 4, "10-value scale, then applied to sphere. Clean results."),
            (130, 90, .pencil, .fullPiece, "Still life line drawing", "Contour Lines", .excellent, 5, "Contour only, no shading. Observational control at its best."),
            (138, 75, .pencil, .study, "Rule of thirds thumbnails", "Rule of Thirds", .good, 4, "Thumbnailed 20 compositions. Good habit to get into."),
            (146, 60, .acrylic, .exercise, "Impasto texture samples", "Impasto Technique", .okay, 3, "First time with thick paint. Interesting but messy."),
            (155, 90, .pencil, .study, "Portrait proportions", "Facial Proportions", .good, 4, "Systematic study of eye/nose/mouth relationships."),
            (163, 75, .ink, .freePlay, "Experimental mark making", "Developing Personal Voice", .excellent, 5, "Tried hatching, stippling, and gestural lines together."),
            (172, 60, .watercolor, .study, "Wet-on-dry leaves", "Watercolor Wet-on-Wet", .good, 4, "Contrast between wet and dry techniques. Learning control."),
            (180, 90, .pencil, .copy, "Sargent master copy", "Lighting", .good, 4, "Copied a John Singer Sargent charcoal portrait. Humbling."),
            (190, 60, .pencil, .fundamentals, "Freehand circles and ellipses", "Two-Point Perspective", .frustrated, 2, "Still struggling with smooth curves. Keep practicing."),
            (200, 90, .acrylic, .fullPiece, "Color study after Monet", "Color Mixing Basics", .excellent, 5, "Copied Monet water lily palette. Color mixing breakthrough!"),
            (212, 75, .pencil, .study, "Skull study", "Anatomy", .good, 4, "Front and 3/4 skull proportions. Good foundation session."),
            (225, 60, .charcoal, .exercise, "10 value sphere studies", "Value Studies", .good, 4, "Quick studies focusing on core shadow placement."),
            (240, 90, .pencil, .fundamentals, "Contour line warm-ups", "Contour Lines", .good, 4, "Day one of systematic contour practice."),
            (260, 60, .pencil, .sketch, "First gesture page", "Gesture Drawing", .okay, 3, "Stiff. But it was day one. Long way to go."),
            (280, 45, .pencil, .exercise, "Basic hatching samples", "Cross Hatching", .okay, 3, "Learning the basics. More muscle memory needed."),
            (300, 30, .pencil, .freePlay, "First sketches", "Drawing", .good, 3, "First dedicated practice session. Excited to start this journey."),
        ]

        for data in sessionData {
            guard let date = cal.date(byAdding: .day, value: -data.0, to: now) else { continue }
            let session = ArtSession(
                date: date,
                durationMinutes: data.1,
                medium: data.2,
                practiceType: data.3,
                subject: data.4,
                skillWorked: data.5,
                mood: data.6,
                notes: data.8,
                rating: data.7
            )
            context.insert(session)
        }
    }

    static func seedGoal(context: ModelContext) {
        let goal = StudyGoal(title: "Consistent daily practice", targetMinutesPerWeek: 300)
        context.insert(goal)
    }
}
