import Foundation

struct IngredientDatabase {
    static let all: [IngredientInfo] = actives + emollients + preservatives + emulsifiers + surfactants + sunscreens + fragrances + soothing + exfoliants + thickeners + solvents + phAdjusters + colorants + problematic + additional

    // MARK: - Actives

    static let actives: [IngredientInfo] = [
        IngredientInfo(
            id: "niacinamide",
            iciName: "Niacinamide",
            commonNames: ["Vitamin B3", "Nicotinamide"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Brightening", "Pore-minimizing", "Barrier-strengthening", "Anti-inflammatory"],
            goodFor: [.oily, .acneProne, .combination, .sensitive, .normal],
            avoidFor: [],
            category: .active,
            description: "A form of vitamin B3 that reduces pore appearance, evens skin tone, and strengthens the skin barrier. One of the most well-researched and universally tolerated actives."
        ),
        IngredientInfo(
            id: "l-ascorbic-acid",
            iciName: "L-Ascorbic Acid",
            commonNames: ["Vitamin C", "Ascorbic Acid"],
            safetyRating: 1,
            concerns: ["Can oxidize and become less effective if not stored properly", "May cause tingling at high concentrations"],
            benefits: ["Antioxidant", "Brightening", "Collagen synthesis", "Hyperpigmentation reduction"],
            goodFor: [.normal, .dry, .combination, .matureAging],
            avoidFor: [.sensitive],
            category: .active,
            description: "The purest and most potent form of vitamin C, effective at brightening skin and boosting collagen. Works best at pH 2.5–3.5 and should be stored away from light and air."
        ),
        IngredientInfo(
            id: "retinol",
            iciName: "Retinol",
            commonNames: ["Vitamin A", "Vitamin A Alcohol"],
            safetyRating: 1,
            concerns: ["Retinization period (dryness, peeling)", "Sun sensitivity", "Not for pregnancy"],
            benefits: ["Anti-aging", "Cell turnover", "Acne-clearing", "Collagen stimulation"],
            goodFor: [.matureAging, .acneProne, .oily],
            avoidFor: [.sensitive],
            category: .active,
            description: "A vitamin A derivative that accelerates cell turnover and stimulates collagen production. Gold standard for anti-aging; start low and build tolerance gradually."
        ),
        IngredientInfo(
            id: "hyaluronic-acid",
            iciName: "Hyaluronic Acid",
            commonNames: ["HA", "Hyaluronan"],
            safetyRating: 1,
            concerns: ["May feel tacky in dry climates without occlusive layered on top"],
            benefits: ["Deep hydration", "Plumping", "Soothing", "Wound healing"],
            goodFor: [.dry, .normal, .combination, .sensitive, .matureAging],
            avoidFor: [],
            category: .active,
            description: "A naturally occurring polysaccharide that holds up to 1000x its weight in water. Suitable for all skin types and an excellent hydrator at multiple molecular weights."
        ),
        IngredientInfo(
            id: "glycolic-acid",
            iciName: "Glycolic Acid",
            commonNames: ["AHA", "Alpha Hydroxy Acid"],
            safetyRating: 2,
            concerns: ["Sun sensitivity", "Potential irritant at high concentrations", "Stinging"],
            benefits: ["Exfoliation", "Brightening", "Texture improvement", "Anti-aging"],
            goodFor: [.oily, .normal, .matureAging, .acneProne],
            avoidFor: [.sensitive, .dry],
            category: .active,
            description: "The smallest AHA with the best skin penetration, effective at dissolving dead skin cells and improving texture. Always follow with SPF during the day."
        ),
        IngredientInfo(
            id: "salicylic-acid",
            iciName: "Salicylic Acid",
            commonNames: ["BHA", "Beta Hydroxy Acid", "SA"],
            safetyRating: 2,
            concerns: ["Drying at high concentrations", "Not for aspirin-sensitive individuals", "Sun sensitivity"],
            benefits: ["Acne-clearing", "Pore-unclogging", "Anti-inflammatory", "Exfoliation"],
            goodFor: [.oily, .acneProne, .combination],
            avoidFor: [.dry, .sensitive],
            category: .active,
            description: "A lipid-soluble BHA that penetrates into pores to dissolve sebum and dead skin cells. The go-to ingredient for acne and blackheads."
        ),
        IngredientInfo(
            id: "lactic-acid",
            iciName: "Lactic Acid",
            commonNames: ["AHA", "Milk Acid"],
            safetyRating: 1,
            concerns: ["Sun sensitivity", "Mild stinging for very sensitive skin"],
            benefits: ["Gentle exfoliation", "Hydration", "Brightening", "Barrier support"],
            goodFor: [.dry, .sensitive, .normal, .combination, .matureAging],
            avoidFor: [],
            category: .active,
            description: "A gentle AHA derived from milk that exfoliates while also hydrating. Ideal as an introduction to chemical exfoliants for sensitive or dry skin types."
        ),
        IngredientInfo(
            id: "azelaic-acid",
            iciName: "Azelaic Acid",
            commonNames: ["Nonanedioic Acid"],
            safetyRating: 1,
            concerns: ["Mild tingling at first use"],
            benefits: ["Anti-acne", "Anti-redness", "Brightening", "Anti-inflammatory", "Rosacea relief"],
            goodFor: [.sensitive, .acneProne, .combination, .normal],
            avoidFor: [],
            category: .active,
            description: "A multitasking acid that treats acne, reduces redness, and fades hyperpigmentation. Safe during pregnancy (at OTC concentrations) and excellent for rosacea-prone skin."
        ),
        IngredientInfo(
            id: "mandelic-acid",
            iciName: "Mandelic Acid",
            commonNames: ["AHA", "Almond-derived Acid"],
            safetyRating: 1,
            concerns: ["Sun sensitivity"],
            benefits: ["Gentle exfoliation", "Anti-acne", "Brightening", "Texture improvement"],
            goodFor: [.sensitive, .acneProne, .dry, .combination],
            avoidFor: [],
            category: .active,
            description: "A large-molecule AHA derived from almonds that exfoliates more slowly and gently than glycolic acid, making it ideal for sensitive skin and beginners."
        ),
        IngredientInfo(
            id: "tranexamic-acid",
            iciName: "Tranexamic Acid",
            commonNames: ["TXA"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Brightening", "Hyperpigmentation reduction", "Melasma treatment"],
            goodFor: [.normal, .sensitive, .combination, .dry, .matureAging],
            avoidFor: [],
            category: .active,
            description: "A synthetic amino acid derivative that inhibits melanin production pathways. Excellent for melasma and post-inflammatory hyperpigmentation, even for sensitive skin."
        ),
        IngredientInfo(
            id: "kojic-acid",
            iciName: "Kojic Acid",
            commonNames: ["Kojic Acid Dipalmitate"],
            safetyRating: 2,
            concerns: ["Potential irritant at high concentrations", "May cause contact dermatitis"],
            benefits: ["Brightening", "Hyperpigmentation reduction", "Anti-fungal"],
            goodFor: [.normal, .combination, .matureAging],
            avoidFor: [.sensitive],
            category: .active,
            description: "A naturally derived brightening agent from fungi that inhibits tyrosinase (the enzyme responsible for melanin). Effective but can be sensitizing for some individuals."
        ),
        IngredientInfo(
            id: "alpha-arbutin",
            iciName: "Alpha-Arbutin",
            commonNames: ["Arbutin", "Bearberry Extract derivative"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Brightening", "Hyperpigmentation reduction", "Gentle whitening"],
            goodFor: [.sensitive, .normal, .dry, .combination, .matureAging],
            avoidFor: [],
            category: .active,
            description: "A stable, gentle brightening ingredient that slowly releases hydroquinone at the skin surface to inhibit melanin. Safe for sensitive skin and pregnancy-safe."
        ),
        IngredientInfo(
            id: "ceramide-np",
            iciName: "Ceramide NP",
            commonNames: ["Ceramide 3", "N-stearoylsphinganine"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Barrier repair", "Hydration retention", "Soothing"],
            goodFor: [.dry, .sensitive, .matureAging, .normal],
            avoidFor: [],
            category: .active,
            description: "A natural lipid that forms a critical part of the skin barrier, helping to retain moisture and protect against environmental aggressors. Essential for dry and compromised skin."
        ),
        IngredientInfo(
            id: "ceramide-ap",
            iciName: "Ceramide AP",
            commonNames: ["Ceramide 6-II", "Alpha-hydroxy Ceramide"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Barrier repair", "Skin renewal", "Hydration"],
            goodFor: [.dry, .sensitive, .matureAging, .normal],
            avoidFor: [],
            category: .active,
            description: "A ceramide variant that supports the skin's lamellar structure, reinforcing the moisture barrier and supporting healthy desquamation (natural skin renewal)."
        ),
        IngredientInfo(
            id: "ceramide-eop",
            iciName: "Ceramide EOP",
            commonNames: ["Ceramide 1", "Ceramide EOS"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Barrier integrity", "Moisture retention", "Anti-aging"],
            goodFor: [.dry, .sensitive, .matureAging, .normal],
            avoidFor: [],
            category: .active,
            description: "A long-chain ceramide essential for maintaining the lamellar structure of the stratum corneum. Works synergistically with other ceramides to restore compromised barriers."
        ),
        IngredientInfo(
            id: "ferulic-acid",
            iciName: "Ferulic Acid",
            commonNames: ["Hydroxycinnamic Acid"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Antioxidant", "Vitamin C stabilizer", "Anti-aging"],
            goodFor: [.matureAging, .normal, .dry, .combination],
            avoidFor: [],
            category: .active,
            description: "A plant-derived antioxidant that significantly stabilizes and boosts the efficacy of vitamins C and E. Commonly found in high-performance antioxidant serums."
        ),
        IngredientInfo(
            id: "resveratrol",
            iciName: "Resveratrol",
            commonNames: ["3,4,5-trihydroxystilbene", "Grape Skin Extract"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Antioxidant", "Anti-aging", "Anti-inflammatory", "Skin brightening"],
            goodFor: [.matureAging, .normal, .sensitive],
            avoidFor: [],
            category: .active,
            description: "A potent polyphenol antioxidant found naturally in grape skins and red wine. Protects against oxidative stress and supports anti-aging mechanisms."
        ),
        IngredientInfo(
            id: "tocopherol",
            iciName: "Tocopherol",
            commonNames: ["Vitamin E", "d-Alpha-Tocopherol"],
            safetyRating: 1,
            concerns: ["May be comedogenic for some in high concentrations"],
            benefits: ["Antioxidant", "Moisturizing", "Skin healing", "UV protection support"],
            goodFor: [.dry, .normal, .matureAging, .sensitive],
            avoidFor: [.acneProne],
            category: .active,
            description: "A fat-soluble antioxidant vitamin that protects cell membranes from oxidative damage, moisturizes, and enhances barrier function. Often paired with vitamin C for synergistic effect."
        ),
        IngredientInfo(
            id: "ubiquinone",
            iciName: "Ubiquinone",
            commonNames: ["Coenzyme Q10", "CoQ10"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Antioxidant", "Anti-aging", "Cellular energy support", "Firming"],
            goodFor: [.matureAging, .dry, .normal],
            avoidFor: [],
            category: .active,
            description: "A naturally occurring antioxidant found in human cells that declines with age. In skincare, it neutralizes free radicals and may improve skin firmness."
        ),
        IngredientInfo(
            id: "palmitoyl-tripeptide-1",
            iciName: "Palmitoyl Tripeptide-1",
            commonNames: ["Peptide", "Matrixyl", "Pal-GHK"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Anti-aging", "Collagen stimulation", "Firming", "Wrinkle reduction"],
            goodFor: [.matureAging, .normal, .dry],
            avoidFor: [],
            category: .active,
            description: "A lipopeptide that mimics collagen fragments to signal the skin to produce more collagen and elastin. A key active in many anti-aging and firming formulas."
        ),
        IngredientInfo(
            id: "bakuchiol",
            iciName: "Bakuchiol",
            commonNames: ["Babchi Plant Extract", "Natural Retinol Alternative"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Anti-aging", "Cell turnover", "Brightening", "Retinol-like without irritation"],
            goodFor: [.sensitive, .dry, .normal, .matureAging],
            avoidFor: [],
            category: .active,
            description: "A plant-derived ingredient from Psoralea corylifolia with clinically demonstrated retinol-like activity. Suitable for sensitive skin and pregnancy, unlike retinol."
        ),
        IngredientInfo(
            id: "adenosine",
            iciName: "Adenosine",
            commonNames: ["ATP precursor", "Anti-wrinkle"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Anti-wrinkle", "Firming", "Soothing", "Collagen synthesis"],
            goodFor: [.matureAging, .sensitive, .normal, .dry],
            avoidFor: [],
            category: .active,
            description: "A naturally occurring purine nucleoside with anti-wrinkle properties recognized by the FDA. Often found in K-beauty formulations for its firming and soothing effects."
        ),
    ]

    // MARK: - Emollients / Occlusives / Humectants

    static let emollients: [IngredientInfo] = [
        IngredientInfo(
            id: "dimethicone",
            iciName: "Dimethicone",
            commonNames: ["Silicone", "Polydimethylsiloxane"],
            safetyRating: 2,
            concerns: ["Environmental accumulation", "Can trap debris in pores if not cleansed thoroughly"],
            benefits: ["Skin smoothing", "Barrier protection", "Texture enhancement", "Moisture sealing"],
            goodFor: [.normal, .dry, .combination, .sensitive],
            avoidFor: [.acneProne],
            category: .emollient,
            description: "A synthetic silicone polymer that creates a smooth, slip-enhancing film on skin. Non-comedogenic in most formulations, though some find heavy silicone products clog pores."
        ),
        IngredientInfo(
            id: "cyclopentasiloxane",
            iciName: "Cyclopentasiloxane",
            commonNames: ["D5 Silicone", "Volatile Silicone", "Cyclosiloxane"],
            safetyRating: 2,
            concerns: ["Environmental persistence concern", "EU restriction under review"],
            benefits: ["Light texture", "Quick-drying", "Smooth application", "Carrier solvent"],
            goodFor: [.oily, .combination, .normal],
            avoidFor: [],
            category: .emollient,
            description: "A volatile silicone that evaporates after application, leaving a smooth feel without residue. Used to improve spreadability of products; under increasing regulatory scrutiny in the EU."
        ),
        IngredientInfo(
            id: "squalane",
            iciName: "Squalane",
            commonNames: ["Plant Squalane", "Olive-derived Squalane"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Emollient", "Non-comedogenic", "Anti-aging", "Skin softening"],
            goodFor: [.dry, .oily, .acneProne, .sensitive, .normal, .matureAging],
            avoidFor: [],
            category: .emollient,
            description: "A stable, saturated form of squalene (naturally found in human sebum) that mimics the skin's own oils. Lightweight, non-greasy, and suitable for all skin types including oily."
        ),
        IngredientInfo(
            id: "simmondsia-chinensis-seed-oil",
            iciName: "Simmondsia Chinensis Seed Oil",
            commonNames: ["Jojoba Oil", "Jojoba Wax"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Balancing", "Non-comedogenic", "Moisturizing", "Anti-bacterial"],
            goodFor: [.oily, .acneProne, .combination, .sensitive, .normal],
            avoidFor: [],
            category: .emollient,
            description: "Technically a liquid wax closely resembling human sebum. Non-comedogenic, balances oil production, and is well-tolerated by sensitive skin. One of the most versatile facial oils."
        ),
        IngredientInfo(
            id: "rosa-canina-fruit-oil",
            iciName: "Rosa Canina Fruit Oil",
            commonNames: ["Rosehip Oil", "Rosehip Seed Oil"],
            safetyRating: 1,
            concerns: ["Rich in linoleic acid — store away from light to prevent oxidation"],
            benefits: ["Brightening", "Anti-aging", "Scar fading", "Rich in vitamins A and C"],
            goodFor: [.dry, .matureAging, .normal, .combination],
            avoidFor: [.acneProne],
            category: .emollient,
            description: "A nutrient-rich facial oil high in linoleic acid, vitamin A, and vitamin C. Renowned for fading scars and hyperpigmentation, though oxidized oil can trigger breakouts."
        ),
        IngredientInfo(
            id: "argania-spinosa-kernel-oil",
            iciName: "Argania Spinosa Kernel Oil",
            commonNames: ["Argan Oil", "Liquid Gold"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Moisturizing", "Antioxidant", "Anti-aging", "Hair and skin nourishment"],
            goodFor: [.dry, .normal, .matureAging, .combination],
            avoidFor: [],
            category: .emollient,
            description: "A luxurious oil from the Moroccan argan tree rich in oleic acid, linoleic acid, and vitamin E. Softens skin, reduces inflammation, and is absorbed relatively quickly."
        ),
        IngredientInfo(
            id: "sclerocarya-birrea-seed-oil",
            iciName: "Sclerocarya Birrea Seed Oil",
            commonNames: ["Marula Oil"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Moisturizing", "Antioxidant", "Absorbs quickly", "Non-greasy"],
            goodFor: [.dry, .normal, .matureAging, .combination, .sensitive],
            avoidFor: [],
            category: .emollient,
            description: "A lightweight African oil rich in oleic acid and antioxidants. Penetrates quickly without leaving a greasy residue, making it suitable for daytime use."
        ),
        IngredientInfo(
            id: "hippophae-rhamnoides-fruit-oil",
            iciName: "Hippophae Rhamnoides Fruit Oil",
            commonNames: ["Sea Buckthorn Oil", "Sea Buckthorn Berry Oil"],
            safetyRating: 1,
            concerns: ["Bright orange color can stain; often diluted"],
            benefits: ["Antioxidant-rich", "Anti-aging", "Wound healing", "Brightening"],
            goodFor: [.dry, .matureAging, .sensitive, .normal],
            avoidFor: [],
            category: .emollient,
            description: "One of the most nutrient-dense plant oils, rich in carotenoids, vitamin C, and omega fatty acids. Potent antioxidant and anti-inflammatory, but distinctive orange color requires dilution."
        ),
        IngredientInfo(
            id: "butyrospermum-parkii-butter",
            iciName: "Butyrospermum Parkii Butter",
            commonNames: ["Shea Butter"],
            safetyRating: 1,
            concerns: ["May be comedogenic for some individuals"],
            benefits: ["Deep moisturizing", "Anti-inflammatory", "Barrier protection", "Vitamins A and E"],
            goodFor: [.dry, .sensitive, .matureAging, .normal],
            avoidFor: [.acneProne, .oily],
            category: .emollient,
            description: "A rich, fatty butter from the African shea tree with excellent moisturizing and anti-inflammatory properties. Very popular in body creams but can feel heavy on oily or acne-prone faces."
        ),
        IngredientInfo(
            id: "theobroma-cacao-seed-butter",
            iciName: "Theobroma Cacao Seed Butter",
            commonNames: ["Cocoa Butter"],
            safetyRating: 2,
            concerns: ["Comedogenic — clogs pores for acne-prone skin", "Heavy texture"],
            benefits: ["Deep moisturizing", "Antioxidant", "Skin softening"],
            goodFor: [.dry, .matureAging],
            avoidFor: [.acneProne, .oily, .combination],
            category: .emollient,
            description: "A solid fat from cacao beans that melts on contact with skin. Excellent for dry body skin but rated comedogenic and generally not recommended for facial use on acne-prone skin."
        ),
        IngredientInfo(
            id: "petrolatum",
            iciName: "Petrolatum",
            commonNames: ["Petroleum Jelly", "Vaseline", "White Petrolatum"],
            safetyRating: 1,
            concerns: ["Heavy texture; not ideal over active breakouts"],
            benefits: ["Occlusive barrier", "Wound healing", "Moisture locking", "Skin healing"],
            goodFor: [.dry, .sensitive, .matureAging, .normal],
            avoidFor: [.acneProne, .oily],
            category: .emollient,
            description: "A highly refined, dermatologist-endorsed occlusive that creates an impermeable barrier to lock in moisture. The gold standard for wound healing and severely dry skin."
        ),
        IngredientInfo(
            id: "mineral-oil",
            iciName: "Mineral Oil",
            commonNames: ["Paraffinum Liquidum", "White Mineral Oil"],
            safetyRating: 2,
            concerns: ["Comedogenic for some", "Environmental sourcing (petroleum-derived)"],
            benefits: ["Occlusive moisturizer", "Softening", "Cost-effective"],
            goodFor: [.dry, .normal],
            avoidFor: [.acneProne, .oily],
            category: .emollient,
            description: "A highly refined petroleum-derived oil used as an occlusive moisturizer. Cosmetic-grade mineral oil is non-toxic and non-sensitizing, though some find it comedogenic."
        ),
        IngredientInfo(
            id: "lanolin",
            iciName: "Lanolin",
            commonNames: ["Wool Wax", "Wool Fat", "Adeps Lanae"],
            safetyRating: 2,
            concerns: ["Common allergen for wool-sensitive individuals", "Animal-derived"],
            benefits: ["Intense moisturizing", "Occlusive", "Wound healing"],
            goodFor: [.dry, .matureAging],
            avoidFor: [.sensitive],
            category: .emollient,
            description: "A waxy substance secreted by wool-bearing animals. Extremely effective at moisturizing and wound healing, but is a known allergen for wool-sensitive individuals."
        ),
        IngredientInfo(
            id: "cera-alba",
            iciName: "Cera Alba",
            commonNames: ["Beeswax", "White Wax"],
            safetyRating: 1,
            concerns: ["Not vegan", "Rare pollen-related allergy"],
            benefits: ["Texture builder", "Occlusive", "Natural preservative"],
            goodFor: [.dry, .normal, .sensitive],
            avoidFor: [],
            category: .emollient,
            description: "A natural wax produced by honeybees that creates a protective barrier on the skin. Used to thicken balms and provides mild occlusive moisture retention."
        ),
        IngredientInfo(
            id: "carnauba-wax",
            iciName: "Carnauba Wax",
            commonNames: ["Brazil Wax", "Copernica Cerifera Wax"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Texture builder", "Natural gloss", "Vegan alternative to beeswax"],
            goodFor: [.normal, .dry, .sensitive],
            avoidFor: [],
            category: .emollient,
            description: "A plant-derived wax from Brazilian palm trees. Used as a vegan alternative to beeswax in lip products and balms for its glossy, hard texture."
        ),
        IngredientInfo(
            id: "glycerin",
            iciName: "Glycerin",
            commonNames: ["Glycerol", "Vegetable Glycerin"],
            safetyRating: 1,
            concerns: ["Can feel tacky in very high concentrations"],
            benefits: ["Humectant", "Hydration", "Barrier support", "Soothing"],
            goodFor: [.dry, .normal, .sensitive, .combination, .oily, .matureAging],
            avoidFor: [],
            category: .humectant,
            description: "A universal humectant that draws moisture from the environment into the skin. Incredibly well-tolerated, effective, and found in virtually every moisturizing product."
        ),
        IngredientInfo(
            id: "propylene-glycol",
            iciName: "Propylene Glycol",
            commonNames: ["1,2-Propanediol", "PG"],
            safetyRating: 2,
            concerns: ["Potential irritant at high concentrations", "Possible sensitizer"],
            benefits: ["Humectant", "Penetration enhancer", "Texture improvement"],
            goodFor: [.normal, .oily, .combination],
            avoidFor: [.sensitive],
            category: .humectant,
            description: "A small alcohol diol used as a humectant and penetration enhancer. Generally safe at low concentrations used in cosmetics, but can irritate sensitive skin."
        ),
        IngredientInfo(
            id: "butylene-glycol",
            iciName: "Butylene Glycol",
            commonNames: ["1,3-Butanediol", "BG"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Humectant", "Texture improvement", "Penetration enhancer", "Antimicrobial support"],
            goodFor: [.normal, .oily, .combination, .dry, .sensitive],
            avoidFor: [],
            category: .humectant,
            description: "A gentle, low-irritation glycol used as a humectant and texture agent. Helps other ingredients penetrate better and leaves a lighter feel than propylene glycol."
        ),
        IngredientInfo(
            id: "sodium-hyaluronate",
            iciName: "Sodium Hyaluronate",
            commonNames: ["Low molecular weight HA", "Hyaluronic Acid salt"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Deep hydration", "Penetrates deeper than HA", "Plumping", "Soothing"],
            goodFor: [.dry, .sensitive, .normal, .combination, .matureAging],
            avoidFor: [],
            category: .humectant,
            description: "The sodium salt of hyaluronic acid with a smaller molecular weight, allowing deeper penetration into the skin. Often used alongside hyaluronic acid for multi-level hydration."
        ),
        IngredientInfo(
            id: "urea",
            iciName: "Urea",
            commonNames: ["Carbamide"],
            safetyRating: 2,
            concerns: ["Keratolytic at concentrations above 10%", "Can sting broken skin"],
            benefits: ["Hydration", "Keratolytic", "Barrier support", "Anti-itch"],
            goodFor: [.dry, .matureAging, .normal],
            avoidFor: [.sensitive],
            category: .humectant,
            description: "A naturally occurring compound in skin that humectates at low concentrations (2-5%) and exfoliates dead skin cells at higher concentrations (10-20%). Excellent for very dry or keratotic skin."
        ),
    ]

    // MARK: - Preservatives

    static let preservatives: [IngredientInfo] = [
        IngredientInfo(
            id: "phenoxyethanol",
            iciName: "Phenoxyethanol",
            commonNames: ["PE", "Rose Ether"],
            safetyRating: 2,
            concerns: ["Potential irritant at high concentrations", "Not recommended for infants"],
            benefits: ["Broad-spectrum preservation", "Stable", "Widely accepted alternative to parabens"],
            goodFor: [.normal, .oily, .combination, .dry],
            avoidFor: [.sensitive],
            category: .preservative,
            description: "The most widely used cosmetic preservative, generally safe at concentrations up to 1%. Concentration-dependent irritant; the EWG and most authorities consider it acceptable in regulated amounts."
        ),
        IngredientInfo(
            id: "benzyl-alcohol",
            iciName: "Benzyl Alcohol",
            commonNames: ["Phenylmethanol", "BA"],
            safetyRating: 2,
            concerns: ["Potential irritant and allergen at higher concentrations", "Possible sensitizer"],
            benefits: ["Preservative", "Solvent", "Fragrance component", "Antimicrobial"],
            goodFor: [.normal, .oily],
            avoidFor: [.sensitive],
            category: .preservative,
            description: "A naturally derived preservative also used as a fragrance and solvent. Safe at the concentrations used in cosmetics (up to 1%), but can cause irritation in sensitive individuals."
        ),
        IngredientInfo(
            id: "potassium-sorbate",
            iciName: "Potassium Sorbate",
            commonNames: ["Sorbic Acid Potassium Salt"],
            safetyRating: 2,
            concerns: ["Can be an eye irritant at high concentrations"],
            benefits: ["Natural preservative", "Antifungal", "Gentle", "Used in food grade products"],
            goodFor: [.normal, .sensitive, .dry, .combination],
            avoidFor: [],
            category: .preservative,
            description: "A food-grade preservative also used in cosmetics, effective against mold and yeast. Generally considered one of the gentler preservatives and sometimes paired with sodium benzoate."
        ),
        IngredientInfo(
            id: "sodium-benzoate",
            iciName: "Sodium Benzoate",
            commonNames: ["Benzoic Acid Sodium Salt", "E211"],
            safetyRating: 2,
            concerns: ["May form benzene in presence of vitamin C (ascorbic acid) — formulation concern", "Mild irritant"],
            benefits: ["Antifungal", "Antibacterial", "Food-grade preservative"],
            goodFor: [.normal, .oily, .combination],
            avoidFor: [.sensitive],
            category: .preservative,
            description: "A food-safe preservative effective in acidic formulas. When combined with ascorbic acid at low pH, trace benzene may form — a formulation consideration, not a consumer risk at typical levels."
        ),
        IngredientInfo(
            id: "methylparaben",
            iciName: "Methylparaben",
            commonNames: ["Paraben", "Methyl p-hydroxybenzoate"],
            safetyRating: 3,
            concerns: ["Endocrine disruption debate (weak estrogenic activity)", "Allergen potential", "Controversial in EU"],
            benefits: ["Effective preservative", "Long history of use", "Antifungal and antibacterial"],
            goodFor: [],
            avoidFor: [.sensitive],
            category: .preservative,
            description: "The most common paraben preservative with decades of use. Studies show weak estrogenic activity at high doses, leading to consumer concern; current evidence does not confirm a risk at cosmetic concentrations."
        ),
        IngredientInfo(
            id: "dmdm-hydantoin",
            iciName: "DMDM Hydantoin",
            commonNames: ["Formaldehyde Releaser", "Dimethylol Dimethyl Hydantoin"],
            safetyRating: 4,
            concerns: ["Releases formaldehyde", "Significant allergen", "Contact dermatitis risk", "Linked to hair loss lawsuits"],
            benefits: ["Effective preservative"],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne, .dry],
            category: .preservative,
            description: "A formaldehyde-releasing preservative that has faced major legal action regarding hair loss and scalp irritation. The formaldehyde release makes it a significant skin allergen and sensitizer."
        ),
        IngredientInfo(
            id: "methylisothiazolinone",
            iciName: "Methylisothiazolinone",
            commonNames: ["MI", "MIT", "Kathon"],
            safetyRating: 4,
            concerns: ["Strong contact sensitizer", "Banned in leave-on products in EU", "Can cause allergic contact dermatitis"],
            benefits: ["Effective preservative", "Broad-spectrum antimicrobial"],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne, .dry, .normal],
            category: .preservative,
            description: "A powerful antimicrobial preservative that has been identified as a major cause of allergic contact dermatitis. Banned in leave-on cosmetics in the EU; still used in some rinse-off products."
        ),
        IngredientInfo(
            id: "chlorphenesin",
            iciName: "Chlorphenesin",
            commonNames: ["3-(4-Chlorophenoxy)-1,2-propanediol"],
            safetyRating: 3,
            concerns: ["Potential neurotoxicity at high doses", "Skin sensitizer at high concentrations"],
            benefits: ["Broad-spectrum preservative", "Antifungal"],
            goodFor: [.normal, .oily],
            avoidFor: [.sensitive],
            category: .preservative,
            description: "A synthetic preservative effective against a broad spectrum of microorganisms. Used at low concentrations in cosmetics; some concern exists around neurotoxicity at doses far exceeding cosmetic levels."
        ),
    ]

    // MARK: - Emulsifiers

    static let emulsifiers: [IngredientInfo] = [
        IngredientInfo(
            id: "cetearyl-alcohol",
            iciName: "Cetearyl Alcohol",
            commonNames: ["C16-18 Fatty Alcohol", "Emulsifying Wax"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Emulsifier", "Texture enhancer", "Conditioning", "Non-drying alcohol"],
            goodFor: [.dry, .normal, .sensitive, .combination, .matureAging],
            avoidFor: [],
            category: .emulsifier,
            description: "A fatty alcohol (not drying) derived from plant sources that stabilizes emulsions and leaves skin feeling soft. Despite 'alcohol' in the name, it is moisturizing and non-irritating."
        ),
        IngredientInfo(
            id: "cetyl-alcohol",
            iciName: "Cetyl Alcohol",
            commonNames: ["C16 Fatty Alcohol", "1-Hexadecanol"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Emulsifier", "Texture thickener", "Skin conditioning"],
            goodFor: [.dry, .normal, .sensitive, .matureAging],
            avoidFor: [],
            category: .emulsifier,
            description: "A fatty alcohol that acts as an emulsifier and texture thickener in creams and lotions. Derived from natural sources, it is mild and non-irritating despite the 'alcohol' name."
        ),
        IngredientInfo(
            id: "stearyl-alcohol",
            iciName: "Stearyl Alcohol",
            commonNames: ["1-Octadecanol", "C18 Fatty Alcohol"],
            safetyRating: 1,
            concerns: ["May be comedogenic for some"],
            benefits: ["Emulsifier", "Moisturizing", "Texture enhancer"],
            goodFor: [.dry, .normal, .matureAging],
            avoidFor: [.acneProne],
            category: .emulsifier,
            description: "A long-chain fatty alcohol used as an emulsifier and conditioner. Like other fatty alcohols, it is non-drying and can actually hydrate, though it may be comedogenic for some."
        ),
        IngredientInfo(
            id: "glyceryl-stearate",
            iciName: "Glyceryl Stearate",
            commonNames: ["Glyceryl Monostearate", "GMS"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Emulsifier", "Skin conditioning", "Smooth texture"],
            goodFor: [.dry, .normal, .sensitive, .matureAging],
            avoidFor: [],
            category: .emulsifier,
            description: "A naturally derived emulsifier from glycerin and stearic acid. One of the safest emulsifiers, it also conditions skin and helps create smooth, stable cream formulations."
        ),
        IngredientInfo(
            id: "polysorbate-80",
            iciName: "Polysorbate 80",
            commonNames: ["Tween 80", "Polyoxyethylene Sorbitan Monooleate"],
            safetyRating: 2,
            concerns: ["May contain trace contaminants like ethylene oxide in lower-quality grades", "Can disrupt skin microbiome at high concentrations"],
            benefits: ["Emulsifier", "Solubilizer", "Allows mixing of oil and water"],
            goodFor: [.normal, .oily, .combination],
            avoidFor: [.sensitive],
            category: .emulsifier,
            description: "A widely used emulsifier derived from sorbitol and oleic acid. Generally safe in cosmetics, though trace manufacturing contaminants are a concern with poor-quality sources."
        ),
        IngredientInfo(
            id: "peg-100-stearate",
            iciName: "PEG-100 Stearate",
            commonNames: ["Polyethylene Glycol Stearate", "PEG Compound"],
            safetyRating: 2,
            concerns: ["May enhance penetration of other chemicals", "Potential impurities in low-grade manufacturing"],
            benefits: ["Emulsifier", "Skin conditioning", "Smooth texture"],
            goodFor: [.normal, .dry, .combination],
            avoidFor: [.sensitive],
            category: .emulsifier,
            description: "A PEG-based emulsifier and skin conditioner. Safe at cosmetic concentrations, but the PEG group raises some concern about penetration enhancement and manufacturing purity."
        ),
    ]

    // MARK: - Surfactants

    static let surfactants: [IngredientInfo] = [
        IngredientInfo(
            id: "sodium-lauryl-sulfate",
            iciName: "Sodium Lauryl Sulfate",
            commonNames: ["SLS", "Sodium Dodecyl Sulfate"],
            safetyRating: 3,
            concerns: ["Irritating to skin and mucous membranes", "Strips natural oils", "Can worsen eczema and rosacea", "Canker sore association"],
            benefits: ["Effective cleansing", "Rich lather"],
            goodFor: [],
            avoidFor: [.sensitive, .dry, .matureAging, .acneProne],
            category: .surfactant,
            description: "A harsh anionic surfactant that creates rich lather but strips the skin's natural moisture barrier. Frequently implicated in irritant contact dermatitis and best avoided for sensitive or dry skin."
        ),
        IngredientInfo(
            id: "sodium-laureth-sulfate",
            iciName: "Sodium Laureth Sulfate",
            commonNames: ["SLES", "Sodium Lauryl Ether Sulfate"],
            safetyRating: 2,
            concerns: ["Milder than SLS but still a detergent", "May contain trace 1,4-dioxane (carcinogen) in poor-quality manufacturing"],
            benefits: ["Effective cleansing", "Good lather", "Milder than SLS"],
            goodFor: [.oily, .normal],
            avoidFor: [.sensitive, .dry],
            category: .surfactant,
            description: "A milder version of SLS with an added ethylene oxide group that reduces irritation potential. Still a detergent that can strip moisture, and manufacturing quality affects purity."
        ),
        IngredientInfo(
            id: "cocamidopropyl-betaine",
            iciName: "Cocamidopropyl Betaine",
            commonNames: ["CAPB", "Coconut Betaine"],
            safetyRating: 2,
            concerns: ["Potential allergen (impurities from manufacturing more than the compound itself)"],
            benefits: ["Gentle surfactant", "Amphoteric (milder)", "Conditioning", "Foam booster"],
            goodFor: [.normal, .oily, .combination, .sensitive],
            avoidFor: [],
            category: .surfactant,
            description: "An amphoteric surfactant derived from coconut oil that cleanses gently while also conditioning. Often used to reduce the harshness of other surfactants in formulations."
        ),
        IngredientInfo(
            id: "decyl-glucoside",
            iciName: "Decyl Glucoside",
            commonNames: ["APG Surfactant", "Plant-derived Glucoside"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Very gentle cleansing", "Biodegradable", "pH-compatible with skin", "Good for sensitive skin"],
            goodFor: [.sensitive, .dry, .acneProne, .normal, .combination],
            avoidFor: [],
            category: .surfactant,
            description: "A plant-derived gentle surfactant made from coconut/corn glucose that is biodegradable, non-irritating, and highly compatible with sensitive skin formulations."
        ),
        IngredientInfo(
            id: "lauryl-glucoside",
            iciName: "Lauryl Glucoside",
            commonNames: ["APG", "Coconut-Glucose Surfactant"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Gentle cleansing", "Plant-derived", "Biodegradable", "Foaming agent"],
            goodFor: [.sensitive, .dry, .normal, .combination, .acneProne],
            avoidFor: [],
            category: .surfactant,
            description: "A gentle, plant-derived alkyl polyglucoside surfactant with good foaming properties and excellent skin compatibility. Often used in baby care and sensitive skin products."
        ),
        IngredientInfo(
            id: "coco-glucoside",
            iciName: "Coco-Glucoside",
            commonNames: ["Coconut Glucoside", "Natural Surfactant"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Gentle cleansing", "Natural origin", "Moisturizing", "Biodegradable"],
            goodFor: [.sensitive, .dry, .normal, .acneProne, .combination],
            avoidFor: [],
            category: .surfactant,
            description: "A very mild glucoside surfactant derived from coconut and glucose. One of the gentlest cleansing agents available, ideal for baby products and sensitive or reactive skin."
        ),
    ]

    // MARK: - Sunscreen Filters

    static let sunscreens: [IngredientInfo] = [
        IngredientInfo(
            id: "zinc-oxide",
            iciName: "Zinc Oxide",
            commonNames: ["Mineral Sunscreen", "ZnO"],
            safetyRating: 1,
            concerns: ["Can leave white cast", "Nano form has some debate but considered safe"],
            benefits: ["Broad-spectrum UVA/UVB", "Anti-inflammatory", "Reef-safe", "Physical barrier"],
            goodFor: [.sensitive, .acneProne, .dry, .normal, .combination, .matureAging],
            avoidFor: [],
            category: .sunscreen,
            description: "A mineral UV filter that physically reflects UV rays across the full spectrum. The safest sunscreen option for sensitive skin, pregnant women, and reef-safe applications."
        ),
        IngredientInfo(
            id: "titanium-dioxide",
            iciName: "Titanium Dioxide",
            commonNames: ["Mineral Sunscreen", "TiO2"],
            safetyRating: 1,
            concerns: ["Primarily UVB protection; weaker UVA vs. zinc oxide", "Can leave white cast"],
            benefits: ["UVB protection", "Mineral/physical filter", "Reef-safe", "Gentle"],
            goodFor: [.sensitive, .dry, .normal, .combination],
            avoidFor: [],
            category: .sunscreen,
            description: "A mineral UV filter that provides strong UVB protection and is extremely well-tolerated. Often combined with zinc oxide for full-spectrum coverage without chemical filters."
        ),
        IngredientInfo(
            id: "butyl-methoxydibenzoylmethane",
            iciName: "Butyl Methoxydibenzoylmethane",
            commonNames: ["Avobenzone", "Parsol 1789"],
            safetyRating: 2,
            concerns: ["Photounstable — degrades in sunlight without stabilizers", "Mild potential sensitizer"],
            benefits: ["Broad UVA protection", "Chemical filter"],
            goodFor: [.normal, .oily, .combination],
            avoidFor: [.sensitive],
            category: .sunscreen,
            description: "The most widely used chemical UVA filter in the US. Effective but photounstable — requires stabilizers like octocrylene or ethylhexyl methoxycrylene to prevent breakdown."
        ),
        IngredientInfo(
            id: "ethylhexyl-methoxycinnamate",
            iciName: "Ethylhexyl Methoxycinnamate",
            commonNames: ["Octinoxate", "OMC"],
            safetyRating: 3,
            concerns: ["Endocrine disruption concern (estrogenic activity in animal studies)", "Reef-damaging", "Banned in Hawaii"],
            benefits: ["UVB protection", "Lightweight texture", "Well-tolerated historically"],
            goodFor: [],
            avoidFor: [.sensitive],
            category: .sunscreen,
            description: "A common UVB chemical sunscreen with endocrine disruption concerns from animal studies. Banned in Hawaii due to coral reef damage. Regulatory agencies are reviewing its status."
        ),
        IngredientInfo(
            id: "benzophenone-3",
            iciName: "Benzophenone-3",
            commonNames: ["Oxybenzone", "BP-3"],
            safetyRating: 4,
            concerns: ["Significant endocrine disruption concern", "High systemic absorption", "Reef-toxic", "Banned in several regions"],
            benefits: ["Broad-spectrum UVA/UVB chemical filter"],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne, .dry, .normal, .combination],
            category: .sunscreen,
            description: "A chemical UV filter with high systemic absorption rates and significant endocrine disruption concerns. Banned in Hawaii and several countries due to coral reef toxicity. Best avoided."
        ),
        IngredientInfo(
            id: "homosalate",
            iciName: "Homosalate",
            commonNames: ["3,3,5-Trimethylcyclohexyl Salicylate"],
            safetyRating: 3,
            concerns: ["Endocrine disruption concern", "Systemic absorption", "FDA re-evaluation pending"],
            benefits: ["UVB filter", "Widely used", "Helps dissolve other UV filters"],
            goodFor: [.normal, .oily],
            avoidFor: [.sensitive],
            category: .sunscreen,
            description: "A chemical UVB filter with potential endocrine disruption properties. The FDA has requested additional safety data. Often used alongside other filters to improve product stability."
        ),
        IngredientInfo(
            id: "octocrylene",
            iciName: "Octocrylene",
            commonNames: ["2-Cyano-3,3-diphenylacrylic acid", "OC"],
            safetyRating: 2,
            concerns: ["May degrade into benzophenone with age/sun exposure", "Mild photosensitizer"],
            benefits: ["UVB protection", "Stabilizes avobenzone", "Water-resistant formulations"],
            goodFor: [.normal, .oily, .combination],
            avoidFor: [.sensitive],
            category: .sunscreen,
            description: "A chemical sunscreen that also stabilizes avobenzone. Recent research suggests it may degrade into benzophenone (a concerning compound) over time, raising safety questions."
        ),
        IngredientInfo(
            id: "bis-ethylhexyloxyphenol-methoxyphenyl-triazine",
            iciName: "Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine",
            commonNames: ["Tinosorb S", "Bemotrizinol"],
            safetyRating: 1,
            concerns: ["Not yet approved in the US"],
            benefits: ["Broad-spectrum UVA/UVB", "Photostable", "Highly efficient", "Does not penetrate skin"],
            goodFor: [.sensitive, .normal, .dry, .combination, .matureAging],
            avoidFor: [],
            category: .sunscreen,
            description: "One of the most advanced UV filters, offering broad-spectrum, photostable protection while remaining on the skin surface. Widely used in Europe and Asia, pending FDA approval in the US."
        ),
        IngredientInfo(
            id: "tinosorb-m",
            iciName: "Methylene Bis-Benzotriazolyl Tetramethylbutylphenol",
            commonNames: ["Tinosorb M", "MBBT"],
            safetyRating: 1,
            concerns: ["Not yet approved in the US"],
            benefits: ["Broad-spectrum UVA/UVB", "Photostable", "Both physical and chemical mechanism"],
            goodFor: [.sensitive, .normal, .combination, .dry],
            avoidFor: [],
            category: .sunscreen,
            description: "A next-generation broad-spectrum UV filter with both physical and chemical UV-blocking mechanisms. Excellent photostability and safety profile; available in Europe and Asia."
        ),
    ]

    // MARK: - Fragrances & Essential Oils

    static let fragrances: [IngredientInfo] = [
        IngredientInfo(
            id: "parfum",
            iciName: "Parfum",
            commonNames: ["Fragrance", "Fragrance Blend", "Scent"],
            safetyRating: 3,
            concerns: ["Catch-all term hiding hundreds of potential chemicals", "Common sensitizer", "Can cause allergic contact dermatitis", "Respiratory irritant for some"],
            benefits: ["Sensory experience"],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne],
            category: .fragrance,
            description: "A regulatory catch-all term that can represent a blend of hundreds of undisclosed chemicals. One of the most common causes of skin sensitization and allergic contact dermatitis."
        ),
        IngredientInfo(
            id: "linalool",
            iciName: "Linalool",
            commonNames: ["Natural Fragrance", "Floral Scent"],
            safetyRating: 3,
            concerns: ["Allergen — especially when oxidized", "EU mandatory disclosure allergen", "Contact dermatitis risk"],
            benefits: ["Natural pleasant scent", "Mild antimicrobial"],
            goodFor: [],
            avoidFor: [.sensitive],
            category: .fragrance,
            description: "A naturally occurring terpene alcohol found in lavender and many plants that becomes a significant allergen when oxidized. Must be disclosed on EU cosmetic labels above 0.01% threshold."
        ),
        IngredientInfo(
            id: "limonene",
            iciName: "Limonene",
            commonNames: ["d-Limonene", "Citrus Scent"],
            safetyRating: 3,
            concerns: ["Oxidizes readily and oxidized form is a potent sensitizer", "EU mandatory disclosure allergen"],
            benefits: ["Pleasant citrus fragrance", "Natural origin"],
            goodFor: [],
            avoidFor: [.sensitive],
            category: .fragrance,
            description: "A citrus-scented terpene that becomes a significant allergen when it oxidizes on contact with air. A mandatory disclosure allergen in the EU; freshness of formulation matters greatly."
        ),
        IngredientInfo(
            id: "citronellol",
            iciName: "Citronellol",
            commonNames: ["Rose Alcohol", "Citronellyl Alcohol"],
            safetyRating: 3,
            concerns: ["Skin sensitizer", "EU disclosure allergen", "Contact dermatitis potential"],
            benefits: ["Rose-like fragrance", "Natural origin"],
            goodFor: [],
            avoidFor: [.sensitive],
            category: .fragrance,
            description: "A naturally occurring fragrance alcohol found in roses and citronella with known sensitizing potential. Listed as a mandatory disclosure allergen in EU cosmetics above threshold concentrations."
        ),
        IngredientInfo(
            id: "geraniol",
            iciName: "Geraniol",
            commonNames: ["Rose Fragrance", "Geranium-derived"],
            safetyRating: 3,
            concerns: ["Contact allergen", "EU disclosure allergen", "Potential sensitizer"],
            benefits: ["Pleasant rose/floral scent", "Natural insect repellent"],
            goodFor: [],
            avoidFor: [.sensitive],
            category: .fragrance,
            description: "A natural fragrance compound from rose and geranium with known allergenic potential. EU-listed fragrance allergen requiring disclosure. Oxidizes to produce stronger sensitizers."
        ),
        IngredientInfo(
            id: "lavandula-angustifolia-oil",
            iciName: "Lavandula Angustifolia Oil",
            commonNames: ["Lavender Essential Oil", "Lavender Oil"],
            safetyRating: 2,
            concerns: ["Contains linalool and linalyl acetate — potential sensitizers", "Potential hormone disruption at high concentrations in animal studies"],
            benefits: ["Calming fragrance", "Antimicrobial", "Wound-healing properties"],
            goodFor: [.normal, .combination],
            avoidFor: [.sensitive],
            category: .fragrance,
            description: "One of the most popular essential oils in skincare with calming and antimicrobial properties. Contains fragrance allergens and at high concentrations may have endocrine effects."
        ),
        IngredientInfo(
            id: "melaleuca-alternifolia-leaf-oil",
            iciName: "Melaleuca Alternifolia Leaf Oil",
            commonNames: ["Tea Tree Oil", "TTO"],
            safetyRating: 2,
            concerns: ["Irritant at concentrations above 5%", "Sensitizer with repeated use", "Potentially toxic if ingested"],
            benefits: ["Antimicrobial", "Anti-acne", "Antifungal", "Anti-inflammatory"],
            goodFor: [.acneProne, .oily],
            avoidFor: [.sensitive, .dry],
            category: .fragrance,
            description: "A potent antimicrobial essential oil effective against acne bacteria. Beneficial at low concentrations (0.5-5%) but irritating at higher percentages and with prolonged undiluted use."
        ),
        IngredientInfo(
            id: "peppermint-oil",
            iciName: "Mentha Piperita Oil",
            commonNames: ["Peppermint Oil", "Menthol source"],
            safetyRating: 3,
            concerns: ["Significant irritant", "Vasodilator — may worsen redness", "Not for use around infants", "Numbing sensation can mask irritation"],
            benefits: ["Cooling sensation", "Antimicrobial", "Energizing scent"],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne, .dry, .matureAging],
            category: .fragrance,
            description: "A stimulating essential oil providing a distinctive cooling sensation via menthol. The tingly feeling can be mistaken for efficacy but often signals irritation; not recommended for facial skincare."
        ),
        IngredientInfo(
            id: "eugenol",
            iciName: "Eugenol",
            commonNames: ["Clove Oil Component", "Phenylpropanoid"],
            safetyRating: 3,
            concerns: ["Significant skin sensitizer", "EU disclosure allergen", "Cytotoxic at high concentrations"],
            benefits: ["Antimicrobial", "Spicy clove-like fragrance"],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne, .dry],
            category: .fragrance,
            description: "A fragrance compound found in clove, cinnamon, and many essential oils with documented skin sensitization properties. One of the most common causes of fragrance-related allergic contact dermatitis."
        ),
        IngredientInfo(
            id: "citrus-bergamia-peel-oil",
            iciName: "Citrus Bergamia Peel Oil",
            commonNames: ["Bergamot Oil", "Bergamot Essential Oil"],
            safetyRating: 3,
            concerns: ["Phototoxic — causes burns and hyperpigmentation in sunlight", "Contains furanocoumarins", "Allergen risk"],
            benefits: ["Citrus fragrance", "Antiseptic properties", "Used in Earl Grey tea"],
            goodFor: [],
            avoidFor: [.sensitive, .matureAging],
            category: .fragrance,
            description: "A citrus essential oil that is significantly phototoxic due to furanocoumarins. Applying bergamot oil before sun exposure can cause severe burns and lasting hyperpigmentation. Bergapten-free versions are safer."
        ),
    ]

    // MARK: - Soothing / Anti-inflammatory

    static let soothing: [IngredientInfo] = [
        IngredientInfo(
            id: "centella-asiatica-extract",
            iciName: "Centella Asiatica Extract",
            commonNames: ["Cica", "Gotu Kola", "Tiger Grass"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Soothing", "Wound healing", "Anti-inflammatory", "Barrier repair", "Collagen synthesis"],
            goodFor: [.sensitive, .acneProne, .dry, .normal, .combination, .matureAging],
            avoidFor: [],
            category: .soothing,
            description: "A medicinal herb with powerful wound-healing and anti-inflammatory properties. Contains asiaticoside, madecassoside, and asiatic acid that calm redness and support barrier repair."
        ),
        IngredientInfo(
            id: "aloe-barbadensis-leaf-juice",
            iciName: "Aloe Barbadensis Leaf Juice",
            commonNames: ["Aloe Vera", "Aloe Vera Gel"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Soothing", "Hydrating", "Sunburn relief", "Anti-inflammatory", "Wound healing"],
            goodFor: [.sensitive, .acneProne, .oily, .dry, .normal, .combination],
            avoidFor: [],
            category: .soothing,
            description: "A universally soothing botanical gel with centuries of use for burns and irritation. Rich in polysaccharides that provide hydration while anti-inflammatory compounds calm redness."
        ),
        IngredientInfo(
            id: "allantoin",
            iciName: "Allantoin",
            commonNames: ["Comfrey Extract derivative", "ALS"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Soothing", "Wound healing", "Keratolytic", "Anti-irritant", "Cell proliferation"],
            goodFor: [.sensitive, .dry, .acneProne, .normal, .combination, .matureAging],
            avoidFor: [],
            category: .soothing,
            description: "A botanical compound (also synthesized) that soothes irritation, promotes wound healing, and is a natural anti-irritant. Often added to formulas with active ingredients to counteract irritation."
        ),
        IngredientInfo(
            id: "panthenol",
            iciName: "Panthenol",
            commonNames: ["Provitamin B5", "D-Panthenol"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Soothing", "Wound healing", "Hydrating", "Anti-inflammatory", "Barrier support"],
            goodFor: [.sensitive, .dry, .acneProne, .normal, .combination, .matureAging],
            avoidFor: [],
            category: .soothing,
            description: "Provitamin B5 that converts to pantothenic acid in skin, where it improves hydration, soothes inflammation, and promotes wound healing. A gentle, universally beneficial ingredient."
        ),
        IngredientInfo(
            id: "bisabolol",
            iciName: "Bisabolol",
            commonNames: ["Alpha-Bisabolol", "Chamomile-derived"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Calming", "Anti-inflammatory", "Antimicrobial", "Penetration enhancer", "Wound healing"],
            goodFor: [.sensitive, .acneProne, .dry, .normal, .combination],
            avoidFor: [],
            category: .soothing,
            description: "A terpene alcohol naturally found in chamomile with potent calming, anti-inflammatory, and skin-soothing properties. Also enhances penetration of other beneficial ingredients."
        ),
        IngredientInfo(
            id: "camellia-sinensis-leaf-extract",
            iciName: "Camellia Sinensis Leaf Extract",
            commonNames: ["Green Tea Extract", "EGCG Source"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Antioxidant", "Anti-inflammatory", "Anti-aging", "UV damage reduction", "Brightening"],
            goodFor: [.sensitive, .oily, .acneProne, .normal, .matureAging],
            avoidFor: [],
            category: .soothing,
            description: "Rich in polyphenols (especially EGCG), green tea extract is a powerful antioxidant and anti-inflammatory. It reduces UV-induced skin damage and has demonstrated anti-aging benefits."
        ),
        IngredientInfo(
            id: "matricaria-extract",
            iciName: "Matricaria Extract",
            commonNames: ["Chamomile Extract", "German Chamomile", "Matricaria Chamomilla"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Calming", "Anti-inflammatory", "Soothing", "Antioxidant"],
            goodFor: [.sensitive, .dry, .normal, .acneProne],
            avoidFor: [],
            category: .soothing,
            description: "An extract from German chamomile flowers rich in bisabolol and apigenin, providing significant calming and anti-inflammatory benefits. Classic botanical for irritated or reactive skin."
        ),
        IngredientInfo(
            id: "glycyrrhiza-uralensis-root-extract",
            iciName: "Glycyrrhiza Uralensis Root Extract",
            commonNames: ["Licorice Root Extract", "Glycyrrhizin", "Licorice"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Brightening", "Anti-inflammatory", "Hyperpigmentation reduction", "Soothing"],
            goodFor: [.sensitive, .acneProne, .normal, .combination, .matureAging],
            avoidFor: [],
            category: .soothing,
            description: "A root extract containing glabridin that inhibits melanin production and reduces inflammation. A gentle, effective brightening agent with anti-inflammatory benefits."
        ),
        IngredientInfo(
            id: "artemisia-vulgaris-extract",
            iciName: "Artemisia Vulgaris Extract",
            commonNames: ["Mugwort Extract", "Korean Wormwood", "Ssuk"],
            safetyRating: 1,
            concerns: ["Possible allergen for ragweed-sensitive individuals"],
            benefits: ["Soothing", "Antioxidant", "Antimicrobial", "K-beauty staple"],
            goodFor: [.sensitive, .acneProne, .normal, .combination],
            avoidFor: [],
            category: .soothing,
            description: "A popular K-beauty botanical known for its soothing and antioxidant properties. Rich in flavonoids and terpenes that calm reactive skin. Those with ragweed allergies should patch test."
        ),
    ]

    // MARK: - Exfoliants

    static let exfoliants: [IngredientInfo] = [
        IngredientInfo(
            id: "kaolin",
            iciName: "Kaolin",
            commonNames: ["White Clay", "China Clay"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Oil absorption", "Mild cleansing", "Mattifying", "Gentle exfoliation"],
            goodFor: [.oily, .acneProne, .combination, .normal],
            avoidFor: [.dry, .sensitive],
            category: .exfoliant,
            description: "A fine white clay mineral that absorbs excess oil and provides gentle cleansing. Milder than bentonite, making it suitable for combination and sensitive oily skin types."
        ),
        IngredientInfo(
            id: "bentonite",
            iciName: "Bentonite",
            commonNames: ["Montmorillonite Clay", "Smectite Clay"],
            safetyRating: 1,
            concerns: ["Very drying for dry or sensitive skin"],
            benefits: ["Deep pore cleansing", "Strong oil absorption", "Detoxifying", "Antibacterial"],
            goodFor: [.oily, .acneProne, .combination],
            avoidFor: [.dry, .sensitive, .matureAging],
            category: .exfoliant,
            description: "A highly absorbent volcanic clay that draws out impurities and excess oil from pores. More powerful than kaolin — excellent for oily skin but can be very drying."
        ),
        IngredientInfo(
            id: "polyethylene",
            iciName: "Polyethylene",
            commonNames: ["Microplastic Beads", "PE Beads", "Plastic Scrub"],
            safetyRating: 4,
            concerns: ["Microplastic pollution — harms aquatic ecosystems", "Non-biodegradable", "Banned in many countries"],
            benefits: ["Exfoliation (physical)"],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne, .dry, .normal],
            category: .exfoliant,
            description: "Synthetic plastic microbeads used as physical exfoliants. Banned in rinse-off cosmetics in the USA, UK, EU, and many other countries due to microplastic ocean pollution. Should be avoided."
        ),
        IngredientInfo(
            id: "silica",
            iciName: "Silica",
            commonNames: ["Silicon Dioxide", "Hydrated Silica"],
            safetyRating: 1,
            concerns: ["Inhalation concern for dry powder form only"],
            benefits: ["Gentle physical exfoliant", "Oil absorption", "Texture smoothing", "Mattifying"],
            goodFor: [.oily, .combination, .normal, .acneProne],
            avoidFor: [],
            category: .exfoliant,
            description: "A naturally occurring mineral used as a gentle physical exfoliant and oil absorber. Biodegradable, reef-safe alternative to microplastic beads. Safe in cosmetic formulations."
        ),
    ]

    // MARK: - Thickeners

    static let thickeners: [IngredientInfo] = [
        IngredientInfo(
            id: "carbomer",
            iciName: "Carbomer",
            commonNames: ["Carbopol", "Polyacrylic Acid"],
            safetyRating: 1,
            concerns: ["Manufacturing may involve benzene (trace impurity)"],
            benefits: ["Thickening", "Gel formation", "Stable at wide pH range", "Transparent gels"],
            goodFor: [.oily, .acneProne, .normal, .combination],
            avoidFor: [],
            category: .thickener,
            description: "A synthetic polymer widely used to create gel textures in skincare. Forms transparent, stable gels when neutralized. Generally considered safe, though manufacturing requires careful quality control."
        ),
        IngredientInfo(
            id: "xanthan-gum",
            iciName: "Xanthan Gum",
            commonNames: ["XG", "Corn Sugar Gum"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Natural thickener", "Biodegradable", "Stable", "Suspending agent"],
            goodFor: [.sensitive, .dry, .normal, .combination, .oily],
            avoidFor: [],
            category: .thickener,
            description: "A polysaccharide produced by bacterial fermentation, used as a natural thickener and stabilizer. Biodegradable, non-irritating, and approved for food use, making it a very safe cosmetic ingredient."
        ),
        IngredientInfo(
            id: "cellulose",
            iciName: "Cellulose",
            commonNames: ["Plant Cellulose", "Microcrystalline Cellulose"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Natural thickener", "Film former", "Skin feel improvement"],
            goodFor: [.normal, .sensitive, .dry, .combination],
            avoidFor: [],
            category: .thickener,
            description: "A natural polymer from plant cell walls used as a thickener and film-former. Completely natural, biodegradable, and extremely safe in cosmetic applications."
        ),
        IngredientInfo(
            id: "sodium-chloride",
            iciName: "Sodium Chloride",
            commonNames: ["Salt", "Table Salt", "NaCl"],
            safetyRating: 1,
            concerns: ["Can be drying at high concentrations", "May irritate eyes"],
            benefits: ["Viscosity modifier", "Preservative boost", "Mineral content"],
            goodFor: [.oily, .normal, .combination],
            avoidFor: [.dry, .sensitive],
            category: .thickener,
            description: "Common salt used to adjust viscosity and texture in cosmetics. Safe but can be drying at high concentrations, particularly in cleansers used by dry or sensitive skin types."
        ),
    ]

    // MARK: - Solvents

    static let solvents: [IngredientInfo] = [
        IngredientInfo(
            id: "water",
            iciName: "Aqua",
            commonNames: ["Water", "Eau", "H2O"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Universal solvent", "Hydration delivery", "Base for all water-based products"],
            goodFor: [.normal, .dry, .oily, .combination, .sensitive, .acneProne, .matureAging],
            avoidFor: [],
            category: .solvent,
            description: "The universal solvent and most common cosmetic ingredient. Forms the base of most water-based products and helps deliver water-soluble ingredients to the skin."
        ),
        IngredientInfo(
            id: "alcohol-denat",
            iciName: "Alcohol Denat.",
            commonNames: ["Denatured Alcohol", "SD Alcohol", "Ethanol"],
            safetyRating: 2,
            concerns: ["Drying at high concentrations", "Can disrupt skin barrier", "Sensitizing with repeated use"],
            benefits: ["Antiseptic", "Quick-drying", "Improves absorption", "Astringent"],
            goodFor: [.oily, .acneProne],
            avoidFor: [.dry, .sensitive, .matureAging],
            category: .solvent,
            description: "Ethanol denaturated to prevent consumption. In low concentrations in sophisticated formulas, it enhances ingredient delivery; in high concentrations or simple toners, it can be drying and barrier-disrupting."
        ),
        IngredientInfo(
            id: "isopropyl-alcohol",
            iciName: "Isopropyl Alcohol",
            commonNames: ["IPA", "Isopropanol", "Rubbing Alcohol"],
            safetyRating: 2,
            concerns: ["Drying", "Barrier disruption at high concentrations", "Solvent effect on lipids"],
            benefits: ["Antiseptic", "Solvent", "Astringent"],
            goodFor: [.oily],
            avoidFor: [.dry, .sensitive, .matureAging, .acneProne],
            category: .solvent,
            description: "A secondary alcohol used as a solvent and antiseptic. More drying and less skin-compatible than ethanol; best avoided in leave-on facial products for all but the oiliest skin types."
        ),
        IngredientInfo(
            id: "cyclomethicone",
            iciName: "Cyclomethicone",
            commonNames: ["Cyclic Silicone", "Volatile Silicone"],
            safetyRating: 2,
            concerns: ["Environmental persistence concern", "Similar to cyclopentasiloxane"],
            benefits: ["Light texture", "Quick evaporation", "Smooth skin feel"],
            goodFor: [.oily, .combination, .normal],
            avoidFor: [],
            category: .solvent,
            description: "A mixture of cyclic silicones that evaporate after application, delivering a lightweight feel. Under regulatory review in the EU for environmental persistence."
        ),
        IngredientInfo(
            id: "isododecane",
            iciName: "Isododecane",
            commonNames: ["Isoparaffin", "Hydrocarbon Solvent"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Light texture", "Quick-absorbing", "Non-greasy solvent", "Improves pigment dispersion"],
            goodFor: [.oily, .combination, .normal],
            avoidFor: [],
            category: .solvent,
            description: "A lightweight hydrocarbon solvent that evaporates quickly, leaving no residue. Excellent for dispersing pigments and creating lightweight, non-greasy product textures."
        ),
        IngredientInfo(
            id: "ethanol",
            iciName: "Ethanol",
            commonNames: ["Alcohol", "Grain Alcohol", "Ethyl Alcohol"],
            safetyRating: 2,
            concerns: ["Potentially drying at high concentrations", "Can disrupt acid mantle"],
            benefits: ["Antiseptic", "Solvent", "Penetration enhancer", "Astringent"],
            goodFor: [.oily, .acneProne],
            avoidFor: [.dry, .sensitive, .matureAging],
            category: .solvent,
            description: "Ethyl alcohol used as a solvent and antiseptic. Concentrations above 20% can be drying and disruptive to the skin barrier; many alcohol-containing products are well-formulated with lower amounts."
        ),
    ]

    // MARK: - pH Adjusters

    static let phAdjusters: [IngredientInfo] = [
        IngredientInfo(
            id: "citric-acid",
            iciName: "Citric Acid",
            commonNames: ["E330", "Lemon-derived Acid"],
            safetyRating: 1,
            concerns: ["At high concentrations may be irritating"],
            benefits: ["pH adjustment", "Antioxidant", "Mild AHA exfoliant", "Chelating agent"],
            goodFor: [.normal, .oily, .combination, .matureAging],
            avoidFor: [.sensitive],
            category: .phAdjuster,
            description: "A natural acid found in citrus fruits used primarily to adjust pH in cosmetics. At low concentrations primarily a pH adjuster; at higher concentrations provides mild AHA exfoliation."
        ),
        IngredientInfo(
            id: "sodium-hydroxide",
            iciName: "Sodium Hydroxide",
            commonNames: ["Lye", "Caustic Soda", "NaOH"],
            safetyRating: 2,
            concerns: ["Caustic in pure form — hazardous if mishandled", "In final product at neutralized pH, safe"],
            benefits: ["pH adjustment", "Saponification agent", "Neutralizer"],
            goodFor: [.normal, .oily, .combination],
            avoidFor: [],
            category: .phAdjuster,
            description: "A strong base used in tiny amounts to adjust pH in cosmetic formulations. While caustic in its pure form, at the trace concentrations used to neutralize formulas, it is completely safe in the final product."
        ),
        IngredientInfo(
            id: "triethanolamine",
            iciName: "Triethanolamine",
            commonNames: ["TEA", "Trolamine"],
            safetyRating: 3,
            concerns: ["Can form carcinogenic nitrosamines with certain other ingredients", "Eye irritant", "Potential sensitizer"],
            benefits: ["pH adjuster", "Emulsifier"],
            goodFor: [],
            avoidFor: [.sensitive],
            category: .phAdjuster,
            description: "An amine compound used to adjust pH and emulsify. The concern is nitrosamine formation when combined with nitrogen-donating preservatives. Well-formulated products manage this risk, but it remains a concern."
        ),
    ]

    // MARK: - Colorants

    static let colorants: [IngredientInfo] = [
        IngredientInfo(
            id: "talc",
            iciName: "Talc",
            commonNames: ["Talcum Powder", "Magnesium Silicate"],
            safetyRating: 2,
            concerns: ["Asbestos contamination in low-quality sourcing", "Inhalation risk in loose powder", "Linked to ovarian cancer controversy in talcum powder products"],
            benefits: ["Oil absorption", "Smoothing", "Soft skin feel"],
            goodFor: [.oily, .combination],
            avoidFor: [],
            category: .colorant,
            description: "A soft mineral used in cosmetics for oil absorption and silky texture. Well-documented asbestos contamination concerns with some sourcing; major manufacturers use asbestos-free cosmetic-grade talc."
        ),
        IngredientInfo(
            id: "mica",
            iciName: "Mica",
            commonNames: ["Sericite", "Shimmer Mineral"],
            safetyRating: 1,
            concerns: ["Child labor concerns in mining (ethical sourcing matters)", "Inhalation concern in loose powders"],
            benefits: ["Shimmer", "Light reflection", "Color", "Skin-smoothing appearance"],
            goodFor: [.normal, .dry, .matureAging, .combination],
            avoidFor: [],
            category: .colorant,
            description: "A naturally occurring mineral that provides shimmer, light reflection, and color in cosmetics. The ingredient itself is safe for skin, though ethical sourcing (avoiding child labor mines) is an important consumer concern."
        ),
        IngredientInfo(
            id: "iron-oxides",
            iciName: "Iron Oxides",
            commonNames: ["CI 77491", "CI 77492", "CI 77499", "Synthetic Iron Oxides"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Color pigmentation", "UV protection boost", "Stable colorant"],
            goodFor: [.normal, .sensitive, .dry, .combination, .oily, .matureAging],
            avoidFor: [],
            category: .colorant,
            description: "Synthetic iron oxide pigments used to impart color in foundations, concealers, and tinted products. Very stable, non-migrating, and safe. Provide some added protection against visible light and HEV light."
        ),
    ]

    // MARK: - Problematic / Flagged

    static let problematic: [IngredientInfo] = [
        IngredientInfo(
            id: "butylated-hydroxyanisole",
            iciName: "Butylated Hydroxyanisole",
            commonNames: ["BHA", "E320"],
            safetyRating: 3,
            concerns: ["Endocrine disruption concern", "Potential carcinogen (high dose animal studies)", "Environmental persistence"],
            benefits: ["Antioxidant preservative", "Prevents rancidity"],
            goodFor: [],
            avoidFor: [.sensitive],
            category: .problematic,
            description: "An antioxidant preservative (distinct from salicylic acid BHA) with endocrine disruption and carcinogenicity concerns in high-dose animal studies. Listed as reasonably anticipated carcinogen by NTP."
        ),
        IngredientInfo(
            id: "coal-tar",
            iciName: "Coal Tar",
            commonNames: ["Coal Tar Solution", "Liquor Carbonis Detergens", "LCD"],
            safetyRating: 5,
            concerns: ["Known human carcinogen", "Phototoxic", "EU cosmetics ban", "Impurities include PAHs"],
            benefits: ["Anti-dandruff (OTC drug in US)", "Anti-psoriasis", "Antipruritic"],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne, .dry, .normal, .combination, .matureAging],
            category: .problematic,
            description: "A byproduct of coal processing used in some anti-dandruff and anti-psoriasis products. Known human carcinogen containing polycyclic aromatic hydrocarbons (PAHs). Banned in EU cosmetics; classified OTC drug in US."
        ),
        IngredientInfo(
            id: "hydroquinone",
            iciName: "Hydroquinone",
            commonNames: ["1,4-Benzenediol", "HQ", "Bleaching Agent"],
            safetyRating: 4,
            concerns: ["Banned in EU OTC cosmetics", "Ochronosis (permanent skin darkening) with long-term use", "Potential carcinogen", "Requires prescription in many countries"],
            benefits: ["Potent melanin inhibitor", "Effective for severe hyperpigmentation"],
            goodFor: [],
            avoidFor: [.sensitive, .matureAging, .dry],
            category: .problematic,
            description: "The strongest topical skin brightening agent available — and also the most concerning. Banned in EU cosmetics due to cancer risk and ochronosis. Only available by prescription in many markets."
        ),
        IngredientInfo(
            id: "mercury",
            iciName: "Thimerosal",
            commonNames: ["Mercury", "Thiomersal", "Merbromin"],
            safetyRating: 5,
            concerns: ["Highly neurotoxic", "Heavy metal accumulation", "Banned in almost all cosmetics globally", "Kidney damage"],
            benefits: ["Preservative (obsolete)"],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne, .dry, .normal, .combination, .oily, .matureAging],
            category: .problematic,
            description: "A mercury-based preservative that is highly neurotoxic and banned in cosmetics in virtually every country. Still found in some counterfeit skin-lightening products. Avoid any product containing mercury compounds."
        ),
        IngredientInfo(
            id: "lead",
            iciName: "Lead",
            commonNames: ["Lead Acetate", "Heavy Metal Impurity", "Plumbum"],
            safetyRating: 5,
            concerns: ["Neurotoxin", "Developmental toxin", "Cumulative poison", "No safe exposure level"],
            benefits: [],
            goodFor: [],
            avoidFor: [.sensitive, .acneProne, .dry, .normal, .combination, .oily, .matureAging],
            category: .problematic,
            description: "A heavy metal with no safe exposure level that appears as an impurity in some cosmetics, particularly certain lip products and hair dyes. Neurotoxic and developmental toxin banned as an intentional cosmetic ingredient."
        ),
        IngredientInfo(
            id: "tocopheryl-acetate",
            iciName: "Tocopheryl Acetate",
            commonNames: ["Vitamin E Acetate", "Vitamin E Ester"],
            safetyRating: 1,
            concerns: ["Must convert to tocopherol on skin — less efficient than tocopherol directly", "Vaping form linked to lung injury (not skin concern)"],
            benefits: ["Antioxidant", "Skin conditioning", "Stable form of vitamin E"],
            goodFor: [.dry, .normal, .matureAging, .sensitive],
            avoidFor: [],
            category: .active,
            description: "The acetate ester of vitamin E that is more stable than pure tocopherol. Must be converted by skin enzymes to active tocopherol; less immediately potent but widely used in stable formulations."
        ),
        IngredientInfo(
            id: "retinyl-palmitate",
            iciName: "Retinyl Palmitate",
            commonNames: ["Vitamin A Palmitate", "Retinyl Ester"],
            safetyRating: 2,
            concerns: ["Controversial sun photosensitizer concern (inconclusive research)", "Less potent than retinol"],
            benefits: ["Vitamin A activity", "Anti-aging", "Gentler than retinol"],
            goodFor: [.sensitive, .matureAging, .dry, .normal],
            avoidFor: [],
            category: .active,
            description: "A mild vitamin A ester that converts slowly to retinol in skin. Gentler and more stable than retinol but also less potent. The sun-sensitivity concern from animal studies remains unconfirmed in humans at cosmetic concentrations."
        ),
        IngredientInfo(
            id: "zinc-sulfate",
            iciName: "Zinc Sulfate",
            commonNames: ["Zinc Salt", "Vitriol"],
            safetyRating: 2,
            concerns: ["Potential skin irritant at high concentrations"],
            benefits: ["Astringent", "Antimicrobial", "Anti-acne", "Zinc delivery"],
            goodFor: [.oily, .acneProne, .combination],
            avoidFor: [.dry, .sensitive],
            category: .active,
            description: "A zinc salt with astringent and antimicrobial properties used in some acne treatments and scalp products. May be irritating at higher concentrations; generally safe in diluted topical formulations."
        ),
        IngredientInfo(
            id: "ghk-cu",
            iciName: "Copper Tripeptide-1",
            commonNames: ["Copper Peptide", "GHK-Cu"],
            safetyRating: 1,
            concerns: ["May be inactivated by vitamin C — avoid layering"],
            benefits: ["Anti-aging", "Wound healing", "Collagen synthesis", "Hair growth", "Anti-inflammatory"],
            goodFor: [.matureAging, .dry, .normal, .combination],
            avoidFor: [],
            category: .active,
            description: "A naturally occurring copper complex with significant anti-aging, wound-healing, and collagen-stimulating properties. Should not be used alongside vitamin C, which can deactivate copper peptides."
        ),
        IngredientInfo(
            id: "sh-oligopeptide-1",
            iciName: "sh-Oligopeptide-1",
            commonNames: ["Epidermal Growth Factor", "EGF", "Human EGF"],
            safetyRating: 1,
            concerns: ["Theoretical concern: promotes cell growth — not suitable if immunocompromised or cancer history"],
            benefits: ["Cell renewal", "Anti-aging", "Wound healing", "Skin regeneration"],
            goodFor: [.matureAging, .normal, .dry],
            avoidFor: [],
            category: .active,
            description: "A signaling protein that stimulates epidermal cell growth and regeneration. Highly effective anti-aging ingredient; some practitioners advise caution for immunocompromised individuals due to growth-stimulating activity."
        ),
        IngredientInfo(
            id: "methyl-glucose-sesquistearate",
            iciName: "Methyl Glucose Sesquistearate",
            commonNames: ["Sugar Emollient", "MeGSS"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Emollient", "Skin conditioning", "Derived from glucose"],
            goodFor: [.dry, .normal, .sensitive, .matureAging],
            avoidFor: [],
            category: .emollient,
            description: "A glucose-derived emollient and skin conditioner that softens skin and improves texture. Gentle and well-tolerated, providing a silky skin feel."
        ),
    ]

    // MARK: - Additional Ingredients (to reach 150+)

    static let additional: [IngredientInfo] = [
        // More actives
        IngredientInfo(
            id: "ascorbyl-glucoside",
            iciName: "Ascorbyl Glucoside",
            commonNames: ["Vitamin C Derivative", "Stable Vitamin C"],
            safetyRating: 1,
            concerns: ["Less potent than L-Ascorbic Acid"],
            benefits: ["Brightening", "Antioxidant", "More stable than L-Ascorbic Acid", "Gentle"],
            goodFor: [.sensitive, .normal, .combination, .matureAging],
            avoidFor: [],
            category: .active,
            description: "A stable, water-soluble vitamin C derivative that converts to active ascorbic acid on skin. Less potent than L-Ascorbic Acid but gentler and more stable, ideal for sensitive skin."
        ),
        IngredientInfo(
            id: "ethyl-ascorbic-acid",
            iciName: "3-O-Ethyl Ascorbic Acid",
            commonNames: ["Ethyl Ascorbic Acid", "EAA", "Stable Vitamin C"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Brightening", "Antioxidant", "Highly stable", "Good penetration"],
            goodFor: [.sensitive, .normal, .combination, .matureAging, .dry],
            avoidFor: [],
            category: .active,
            description: "A highly stable vitamin C derivative with good skin penetration that converts to active vitamin C in the skin. Increasingly popular in K-beauty and Western formulations for its stability and efficacy."
        ),
        IngredientInfo(
            id: "magnesium-ascorbyl-phosphate",
            iciName: "Magnesium Ascorbyl Phosphate",
            commonNames: ["MAP", "Vitamin C Phosphate"],
            safetyRating: 1,
            concerns: ["Less potent than L-Ascorbic Acid"],
            benefits: ["Brightening", "Antioxidant", "Stable", "Hydrating"],
            goodFor: [.sensitive, .dry, .normal, .combination],
            avoidFor: [],
            category: .active,
            description: "A water-soluble vitamin C phosphate ester with high stability and gentle action. It hydrolyzes to release ascorbic acid in skin and has a secondary hydrating effect."
        ),
        IngredientInfo(
            id: "polyglutamic-acid",
            iciName: "Polyglutamic Acid",
            commonNames: ["PGA", "Fermented Soybean Derivative"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Superior hydration to HA", "Film-forming", "Smooth texture", "Barrier support"],
            goodFor: [.dry, .matureAging, .sensitive, .normal, .combination],
            avoidFor: [],
            category: .humectant,
            description: "A naturally fermented polypeptide that holds more water than hyaluronic acid. Creates a film on the skin surface that helps other humectants work more effectively."
        ),
        IngredientInfo(
            id: "beta-glucan",
            iciName: "Beta-Glucan",
            commonNames: ["Oat Beta-Glucan", "Yeast Beta-Glucan"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Deep hydration", "Soothing", "Antioxidant", "Wound healing", "Immune modulating"],
            goodFor: [.sensitive, .dry, .acneProne, .matureAging, .normal],
            avoidFor: [],
            category: .active,
            description: "A polysaccharide derived from oats or yeast with powerful anti-inflammatory and hydrating properties. Penetrates deeply, stimulates collagen synthesis, and soothes reactive skin."
        ),
        IngredientInfo(
            id: "palmitoyl-pentapeptide-4",
            iciName: "Palmitoyl Pentapeptide-4",
            commonNames: ["Matrixyl 3000 component", "Pal-KTTKS"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Anti-aging", "Collagen I & III stimulation", "Wrinkle reduction", "Firming"],
            goodFor: [.matureAging, .dry, .normal],
            avoidFor: [],
            category: .active,
            description: "A signal peptide that stimulates the production of collagen I, collagen III, fibronectin, and hyaluronic acid. One of the most studied peptides in anti-aging cosmetics."
        ),
        IngredientInfo(
            id: "acetyl-hexapeptide-3",
            iciName: "Acetyl Hexapeptide-3",
            commonNames: ["Argireline", "Botox-like peptide"],
            safetyRating: 1,
            concerns: ["Topical efficacy limited by penetration"],
            benefits: ["Expression line reduction", "Neuromuscular relaxing peptide", "Anti-aging"],
            goodFor: [.matureAging, .normal, .dry, .combination],
            avoidFor: [],
            category: .active,
            description: "A hexapeptide that inhibits neurotransmitter release at the neuromuscular junction, mimicking botulinum toxin topically. Used in expression-line serums and eye creams."
        ),
        IngredientInfo(
            id: "snap-8",
            iciName: "Acetyl Octapeptide-3",
            commonNames: ["SNAP-8", "Expression Line Peptide"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Expression line softening", "Anti-aging", "Neurotransmitter blocking peptide"],
            goodFor: [.matureAging, .normal, .dry],
            avoidFor: [],
            category: .active,
            description: "An extended version of Argireline (Acetyl Hexapeptide-3) designed to be more effective at reducing expression-line depth. Often used in combination with Argireline."
        ),
        IngredientInfo(
            id: "leontopodium-alpinum-extract",
            iciName: "Leontopodium Alpinum Callus Culture Extract",
            commonNames: ["Edelweiss Extract", "Alpine Edelweiss"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Antioxidant", "Anti-aging", "UV protection support", "Anti-inflammatory"],
            goodFor: [.matureAging, .sensitive, .normal, .dry],
            avoidFor: [],
            category: .soothing,
            description: "An extract from the legendary alpine edelweiss flower, rich in leontopodic acids with potent antioxidant properties. Protects against UV-induced oxidative stress and skin aging."
        ),
        IngredientInfo(
            id: "saccharomyces-ferment",
            iciName: "Saccharomyces Ferment",
            commonNames: ["Yeast Ferment", "Pitera", "Galactomyces Ferment"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Brightening", "Pore-refining", "Antioxidant", "Moisture balance"],
            goodFor: [.oily, .acneProne, .normal, .combination, .matureAging],
            avoidFor: [],
            category: .active,
            description: "A yeast-derived ferment filtrate rich in vitamins, amino acids, and minerals. Popularized by SK-II's Pitera, yeast ferments brighten, balance oil, and improve overall skin texture."
        ),
        IngredientInfo(
            id: "lactobacillus-ferment",
            iciName: "Lactobacillus Ferment",
            commonNames: ["Probiotic Ferment", "Lactic Acid Bacteria Ferment"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Microbiome balance", "Soothing", "Anti-inflammatory", "Barrier support"],
            goodFor: [.sensitive, .acneProne, .dry, .normal, .combination],
            avoidFor: [],
            category: .soothing,
            description: "A fermented filtrate from Lactobacillus bacteria containing postbiotics that support skin microbiome health, reduce inflammation, and strengthen barrier function."
        ),
        IngredientInfo(
            id: "sodium-pca",
            iciName: "Sodium PCA",
            commonNames: ["Sodium Pyrrolidone Carboxylic Acid", "Natural Moisturizing Factor"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Humectant", "Part of NMF", "Hydration", "Amino acid derivative"],
            goodFor: [.dry, .normal, .sensitive, .combination],
            avoidFor: [],
            category: .humectant,
            description: "The sodium salt of pyroglutamic acid, a naturally occurring amino acid in skin that is part of the Natural Moisturizing Factor (NMF). Excellent humectant that attracts and holds moisture."
        ),
        IngredientInfo(
            id: "trehalose",
            iciName: "Trehalose",
            commonNames: ["Mushroom Sugar", "Mycose"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Humectant", "Protective", "Stabilizes proteins", "Antioxidant support"],
            goodFor: [.dry, .sensitive, .normal, .matureAging],
            avoidFor: [],
            category: .humectant,
            description: "A naturally occurring disaccharide found in organisms that survive extreme desiccation. In skincare, it protects skin proteins and lipids from damage while providing moisture retention."
        ),
        IngredientInfo(
            id: "dipotassium-glycyrrhizate",
            iciName: "Dipotassium Glycyrrhizate",
            commonNames: ["Licorice Root Salt", "DPG"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Anti-inflammatory", "Soothing", "Itch relief", "Cortisone-like without steroids"],
            goodFor: [.sensitive, .acneProne, .dry, .normal, .combination],
            avoidFor: [],
            category: .soothing,
            description: "The potassium salt of glycyrrhizic acid from licorice root with cortisone-like anti-inflammatory action without the side effects of steroids. Highly effective for eczema, redness, and itch."
        ),
        IngredientInfo(
            id: "propanediol",
            iciName: "Propanediol",
            commonNames: ["1,3-Propanediol", "Corn-derived Glycol"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Humectant", "Plant-derived", "Penetration enhancer", "Smooth texture"],
            goodFor: [.normal, .dry, .sensitive, .combination, .oily],
            avoidFor: [],
            category: .humectant,
            description: "A naturally fermented corn-derived diol used as a humectant and solvent. A greener, gentler alternative to propylene glycol with comparable performance and better skin tolerance."
        ),
        IngredientInfo(
            id: "pentylene-glycol",
            iciName: "Pentylene Glycol",
            commonNames: ["1,2-Pentanediol"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Humectant", "Antimicrobial", "Preservative booster", "Smooth skin feel"],
            goodFor: [.normal, .oily, .combination, .acneProne],
            avoidFor: [],
            category: .humectant,
            description: "A multifunctional diol that acts as a humectant and natural preservative booster with mild antimicrobial properties. Often used to reduce the needed concentration of traditional preservatives."
        ),
        IngredientInfo(
            id: "natto-gum",
            iciName: "Polyglutamic Acid (from Bacillus subtilis)",
            commonNames: ["Natto Gum", "PGA Ferment"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Extreme hydration", "Film-forming", "Plumping", "Barrier sealing"],
            goodFor: [.dry, .matureAging, .normal],
            avoidFor: [],
            category: .humectant,
            description: "A high-molecular-weight polyglutamic acid from fermented soybean (natto) with moisture-binding capacity exceeding hyaluronic acid. Creates a protective film that prevents transepidermal water loss."
        ),
        IngredientInfo(
            id: "ergothioneine",
            iciName: "Ergothioneine",
            commonNames: ["EGT", "The Longevity Vitamin"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Powerful antioxidant", "Anti-aging", "Cytoprotective", "Mitochondrial protection"],
            goodFor: [.matureAging, .sensitive, .normal, .dry],
            avoidFor: [],
            category: .active,
            description: "An unusual amino acid antioxidant found in mushrooms that human cells actively accumulate. Protects mitochondria, DNA, and proteins from oxidative damage. Emerging superstar in anti-aging skincare."
        ),
        IngredientInfo(
            id: "madecassoside",
            iciName: "Madecassoside",
            commonNames: ["Cica Active", "Centella Active"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Wound healing", "Collagen synthesis", "Anti-inflammatory", "Barrier repair"],
            goodFor: [.sensitive, .acneProne, .dry, .normal, .matureAging],
            avoidFor: [],
            category: .soothing,
            description: "A triterpenoid saponin from Centella asiatica, one of four primary actives in cica extract. Promotes collagen synthesis, accelerates wound healing, and reduces inflammation. Higher purity than full Centella extract."
        ),
        IngredientInfo(
            id: "asiaticoside",
            iciName: "Asiaticoside",
            commonNames: ["Cica Saponin", "Centella Saponin"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Wound healing", "Collagen synthesis", "Skin regeneration", "Anti-scarring"],
            goodFor: [.sensitive, .acneProne, .dry, .matureAging, .normal],
            avoidFor: [],
            category: .soothing,
            description: "A triterpene glycoside from Centella asiatica that stimulates collagen synthesis and accelerates skin repair. Used in post-procedure skincare and wound healing products."
        ),
        IngredientInfo(
            id: "boswellia-serrata-extract",
            iciName: "Boswellia Serrata Extract",
            commonNames: ["Frankincense Extract", "Indian Frankincense"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Anti-inflammatory", "Anti-aging", "Elastin support", "Soothing"],
            goodFor: [.matureAging, .sensitive, .normal, .dry, .combination],
            avoidFor: [],
            category: .soothing,
            description: "An extract from the Boswellia tree rich in boswellic acids with potent anti-inflammatory effects and documented anti-aging properties including elastin synthesis support."
        ),
        IngredientInfo(
            id: "hydroxypinacolone-retinoate",
            iciName: "Hydroxypinacolone Retinoate",
            commonNames: ["HPR", "Granactive Retinoid", "Next-gen Retinoid"],
            safetyRating: 1,
            concerns: ["Less research than retinol"],
            benefits: ["Anti-aging", "Cell renewal", "Less irritating than retinol", "No conversion needed"],
            goodFor: [.sensitive, .matureAging, .dry, .normal, .combination],
            avoidFor: [],
            category: .active,
            description: "A next-generation retinoid ester that binds directly to retinoic acid receptors without conversion, providing retinol-like benefits with significantly reduced irritation. Excellent for retinol beginners."
        ),
        IngredientInfo(
            id: "sea-kelp-extract",
            iciName: "Macrocystis Pyrifera Extract",
            commonNames: ["Sea Kelp Extract", "Giant Kelp Extract"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Hydrating", "Antioxidant", "Mineral-rich", "Anti-inflammatory"],
            goodFor: [.dry, .sensitive, .normal, .matureAging],
            avoidFor: [],
            category: .soothing,
            description: "An extract from giant kelp rich in alginates, iodine, and antioxidant polyphenols. Provides hydration, anti-inflammatory activity, and mineral nutrients to skin."
        ),
        IngredientInfo(
            id: "niacinamide-mononucleotide",
            iciName: "Niacinamide Riboside",
            commonNames: ["NMN", "NAD+ precursor"],
            safetyRating: 1,
            concerns: ["Limited topical efficacy data"],
            benefits: ["Anti-aging", "Cellular energy", "Repair support", "NAD+ precursor"],
            goodFor: [.matureAging, .normal, .dry],
            avoidFor: [],
            category: .active,
            description: "A niacinamide derivative that serves as a precursor to NAD+, supporting cellular energy metabolism and DNA repair mechanisms. Emerging ingredient in longevity-focused skincare."
        ),
        IngredientInfo(
            id: "caprylyl-glycol",
            iciName: "Caprylyl Glycol",
            commonNames: ["1,2-Octanediol", "Caprylic Diol"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Preservative booster", "Emollient", "Antimicrobial", "Skin conditioning"],
            goodFor: [.normal, .oily, .combination, .sensitive],
            avoidFor: [],
            category: .preservative,
            description: "A multifunctional diol that acts as a preservative booster with antimicrobial properties and provides emollient skin conditioning. Often paired with phenoxyethanol to enhance preservation efficacy."
        ),
        IngredientInfo(
            id: "ethylhexylglycerin",
            iciName: "Ethylhexylglycerin",
            commonNames: ["Octylglycerin", "Preservative Booster"],
            safetyRating: 1,
            concerns: ["Mild potential sensitizer at high concentrations"],
            benefits: ["Preservative booster", "Skin conditioning", "Deodorizing", "Emollient"],
            goodFor: [.normal, .oily, .combination, .dry],
            avoidFor: [],
            category: .preservative,
            description: "A glycerin ether used as a preservative booster and skin conditioner. Inhibits odor-causing bacteria and helps phenoxyethanol work at lower, safer concentrations."
        ),
        IngredientInfo(
            id: "hydroxymethylglycinate",
            iciName: "Sodium Hydroxymethylglycinate",
            commonNames: ["Suttocide A", "Glycine Preservative"],
            safetyRating: 3,
            concerns: ["Formaldehyde releaser at high concentrations", "Potential sensitizer"],
            benefits: ["Broad-spectrum preservative", "Water-soluble"],
            goodFor: [],
            avoidFor: [.sensitive],
            category: .preservative,
            description: "A glycine-derived preservative that can release trace formaldehyde under certain conditions, making it controversial for leave-on products. Used at low concentrations in many rinse-off products."
        ),
        IngredientInfo(
            id: "polyisobutene",
            iciName: "Polyisobutene",
            commonNames: ["PIB", "Synthetic Hydrocarbon"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Emollient", "Film former", "Occlusant", "Tactile improvement"],
            goodFor: [.dry, .matureAging, .normal],
            avoidFor: [.acneProne],
            category: .emollient,
            description: "A synthetic polymer used as an emollient and film-former in lip products and skin care. Creates a breathable but protective film that prevents moisture loss without clogging pores in most concentrations."
        ),
        IngredientInfo(
            id: "c12-15-alkyl-benzoate",
            iciName: "C12-15 Alkyl Benzoate",
            commonNames: ["Finsolv TN", "Lightweight Emollient"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Light emollient", "Non-greasy", "SPF carrier", "Spreads evenly"],
            goodFor: [.oily, .combination, .normal],
            avoidFor: [],
            category: .emollient,
            description: "A lightweight synthetic emollient widely used in sunscreens and makeup for its excellent spreading properties and non-greasy dry feel. Helps dissolve and carry chemical UV filters evenly."
        ),
        IngredientInfo(
            id: "isononyl-isononanoate",
            iciName: "Isononyl Isononanoate",
            commonNames: ["Emollient Ester", "Lightweight Oil"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Light emollient", "Spreads easily", "Non-greasy", "Solvent for UV filters"],
            goodFor: [.oily, .combination, .normal, .acneProne],
            avoidFor: [],
            category: .emollient,
            description: "An isononyl ester emollient with a very light, dry skin feel. Used in sunscreens and light lotions where a non-greasy texture is desired."
        ),
        IngredientInfo(
            id: "triethyl-citrate",
            iciName: "Triethyl Citrate",
            commonNames: ["TEC", "Citrate Ester"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Fragrance fixative", "Deodorizing", "Film former", "Plasticizer"],
            goodFor: [.normal, .oily, .combination],
            avoidFor: [],
            category: .solvent,
            description: "A citrate ester used as a plasticizer, film former, and fragrance fixative. Helps deodorize products and is used in nail products. Generally considered safe at cosmetic concentrations."
        ),
        IngredientInfo(
            id: "amodimethicone",
            iciName: "Amodimethicone",
            commonNames: ["Amino Silicone", "Hair Conditioning Silicone"],
            safetyRating: 1,
            concerns: ["Buildup with repeated use without clarifying"],
            benefits: ["Hair conditioning", "Frizz control", "Silky feel", "Damage repair"],
            goodFor: [.dry, .normal],
            avoidFor: [],
            category: .emollient,
            description: "An amino-functionalized silicone that deposits preferentially on damaged hair areas and skin, providing targeted conditioning and repair. Leaves a silky, smooth feel."
        ),
        IngredientInfo(
            id: "dimethicone-crosspolymer",
            iciName: "Dimethicone Crosspolymer",
            commonNames: ["Silicone Elastomer", "Soft Focus Silicone"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Pore blurring", "Smooth texture", "Mattifying", "Long wear"],
            goodFor: [.oily, .combination, .normal],
            avoidFor: [],
            category: .emollient,
            description: "A crosslinked silicone that forms a soft, flexible network on skin, creating a blurring effect that minimizes pore and wrinkle appearance. Common in primers and HD-finish products."
        ),
        IngredientInfo(
            id: "sodium-ascorbyl-phosphate",
            iciName: "Sodium Ascorbyl Phosphate",
            commonNames: ["SAP", "Vitamin C Phosphate"],
            safetyRating: 1,
            concerns: ["Less potent than L-Ascorbic Acid"],
            benefits: ["Antioxidant", "Brightening", "Acne-fighting", "Very stable"],
            goodFor: [.acneProne, .sensitive, .oily, .combination, .normal],
            avoidFor: [],
            category: .active,
            description: "A highly stable water-soluble vitamin C derivative with antimicrobial properties effective against acne bacteria. Converts to active vitamin C in skin, making it a good all-rounder for acne-prone types."
        ),
        IngredientInfo(
            id: "hydroxyethyl-urea",
            iciName: "Hydroxyethyl Urea",
            commonNames: ["Hydrovance", "Functional Urea"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Humectant", "Exfoliant at high%", "Less irritating than urea", "Hydration"],
            goodFor: [.dry, .sensitive, .normal, .matureAging],
            avoidFor: [],
            category: .humectant,
            description: "A urea derivative with stronger humectant properties and less potential for irritation than regular urea. Provides moisture and, at higher concentrations, gentle exfoliation of dry skin."
        ),
        IngredientInfo(
            id: "tapioca-starch",
            iciName: "Tapioca Starch",
            commonNames: ["Cassava Starch", "Manihot Esculenta Starch"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Oil absorption", "Smooth finish", "Natural texture agent", "Mattifying"],
            goodFor: [.oily, .combination, .normal],
            avoidFor: [],
            category: .thickener,
            description: "A natural plant starch used as a mattifying agent and texture enhancer in cosmetics. Absorbs surface oil and provides a silky, smooth skin feel without synthetic additives."
        ),
        IngredientInfo(
            id: "hydroxypropyl-methylcellulose",
            iciName: "Hydroxypropyl Methylcellulose",
            commonNames: ["HPMC", "Hypromellose"],
            safetyRating: 1,
            concerns: [],
            benefits: ["Thickener", "Film former", "Eye drop-safe", "Viscosity control"],
            goodFor: [.normal, .sensitive, .dry, .combination],
            avoidFor: [],
            category: .thickener,
            description: "A semi-synthetic cellulose derivative used as a thickener, film former, and lubricant. Its extreme safety profile makes it a preferred ingredient in eye drops and highly sensitive formulations."
        ),
    ]
}
