import Foundation

/// The static reference catalog of biomarkers Assay understands.
/// Ranges are realistic, clinically-accepted adult values. They are provided
/// for personal tracking and education only — see DisclaimerView.
enum BiomarkerCatalog {

    /// Fast lookup by id.
    static let byId: [String: Biomarker] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }()

    static func marker(_ id: String) -> Biomarker? { byId[id] }

    static func markers(in category: MarkerCategory) -> [Biomarker] {
        all.filter { $0.category == category }
    }

    static let all: [Biomarker] = [
        // MARK: - Lipids
        Biomarker(
            id: "total_chol", name: "Total Cholesterol", shortName: "Total Chol",
            category: .lipids, unit: "mg/dL",
            altUnit: AltUnit(unit: "mmol/L", factor: 1.0 / 38.67),
            standard: SexRanges(ClinicalRange(nil, 200)),
            optimal: SexRanges(ClinicalRange(nil, 180)),
            direction: .higherWorse,
            info: "Sum of all cholesterol in your blood. On its own it is a coarse marker — LDL and ApoB carry more signal.",
            displayMin: 100, displayMax: 300),

        Biomarker(
            id: "ldl", name: "LDL Cholesterol", shortName: "LDL",
            category: .lipids, unit: "mg/dL",
            altUnit: AltUnit(unit: "mmol/L", factor: 1.0 / 38.67),
            standard: SexRanges(ClinicalRange(nil, 100)),
            optimal: SexRanges(ClinicalRange(nil, 70)),
            direction: .higherWorse,
            info: "The classic 'bad' cholesterol that drives plaque. Lower is generally better for cardiovascular risk.",
            displayMin: 40, displayMax: 220),

        Biomarker(
            id: "hdl", name: "HDL Cholesterol", shortName: "HDL",
            category: .lipids, unit: "mg/dL",
            altUnit: AltUnit(unit: "mmol/L", factor: 1.0 / 38.67),
            standard: SexRanges(female: ClinicalRange(50, nil), male: ClinicalRange(40, nil)),
            optimal: SexRanges(female: ClinicalRange(65, nil), male: ClinicalRange(55, nil)),
            direction: .higherBetter,
            info: "The 'good' cholesterol that helps clear excess lipids. Higher is generally protective.",
            displayMin: 20, displayMax: 110),

        Biomarker(
            id: "triglycerides", name: "Triglycerides", shortName: "Trig",
            category: .lipids, unit: "mg/dL",
            altUnit: AltUnit(unit: "mmol/L", factor: 1.0 / 88.57),
            standard: SexRanges(ClinicalRange(nil, 150)),
            optimal: SexRanges(ClinicalRange(nil, 90)),
            direction: .higherWorse,
            info: "Circulating fat. High values often track with insulin resistance and sugary/refined-carb diets.",
            displayMin: 40, displayMax: 300),

        Biomarker(
            id: "apob", name: "Apolipoprotein B", shortName: "ApoB",
            category: .lipids, unit: "mg/dL", altUnit: nil,
            standard: SexRanges(ClinicalRange(nil, 90)),
            optimal: SexRanges(ClinicalRange(nil, 70)),
            direction: .higherWorse,
            info: "Counts the atherogenic particles directly — often the single best lipid marker of cardiovascular risk.",
            displayMin: 40, displayMax: 160),

        // MARK: - Metabolic
        Biomarker(
            id: "glucose", name: "Fasting Glucose", shortName: "Glucose",
            category: .metabolic, unit: "mg/dL",
            altUnit: AltUnit(unit: "mmol/L", factor: 0.0555),
            standard: SexRanges(ClinicalRange(70, 99)),
            optimal: SexRanges(ClinicalRange(75, 88)),
            direction: .midOptimal,
            info: "Blood sugar after an overnight fast. Persistently high values signal impaired glucose control.",
            displayMin: 55, displayMax: 160),

        Biomarker(
            id: "hba1c", name: "Hemoglobin A1c", shortName: "HbA1c",
            category: .metabolic, unit: "%", altUnit: nil,
            standard: SexRanges(ClinicalRange(nil, 5.7)),
            optimal: SexRanges(ClinicalRange(nil, 5.3)),
            direction: .higherWorse,
            info: "Your average blood sugar over ~3 months. A steady, low value reflects good long-term glucose control.",
            displayMin: 4.0, displayMax: 8.0),

        Biomarker(
            id: "insulin", name: "Fasting Insulin", shortName: "Insulin",
            category: .metabolic, unit: "µIU/mL", altUnit: nil,
            standard: SexRanges(ClinicalRange(2, 19)),
            optimal: SexRanges(ClinicalRange(2, 6)),
            direction: .higherWorse,
            info: "How hard your pancreas is working to keep glucose in check. Lower (within range) suggests good insulin sensitivity.",
            displayMin: 1, displayMax: 30),

        // MARK: - Inflammation
        Biomarker(
            id: "hscrp", name: "hs-CRP", shortName: "hs-CRP",
            category: .inflammation, unit: "mg/L", altUnit: nil,
            standard: SexRanges(ClinicalRange(nil, 3.0)),
            optimal: SexRanges(ClinicalRange(nil, 1.0)),
            direction: .higherWorse,
            info: "High-sensitivity marker of systemic inflammation, linked to cardiovascular risk. Lower is better.",
            displayMin: 0, displayMax: 6),

        Biomarker(
            id: "homocysteine", name: "Homocysteine", shortName: "Hcy",
            category: .inflammation, unit: "µmol/L", altUnit: nil,
            standard: SexRanges(ClinicalRange(nil, 15)),
            optimal: SexRanges(ClinicalRange(nil, 8)),
            direction: .higherWorse,
            info: "An amino acid that, when elevated, is associated with cardiovascular and cognitive risk. Often responsive to B vitamins.",
            displayMin: 3, displayMax: 25),

        // MARK: - Thyroid
        Biomarker(
            id: "tsh", name: "TSH", shortName: "TSH",
            category: .thyroid, unit: "µIU/mL", altUnit: nil,
            standard: SexRanges(ClinicalRange(0.4, 4.0)),
            optimal: SexRanges(ClinicalRange(1.0, 2.5)),
            direction: .midOptimal,
            info: "The pituitary's signal to your thyroid. Both high and low values can indicate thyroid dysfunction.",
            displayMin: 0, displayMax: 6),

        Biomarker(
            id: "ft4", name: "Free T4", shortName: "Free T4",
            category: .thyroid, unit: "ng/dL", altUnit: nil,
            standard: SexRanges(ClinicalRange(0.8, 1.8)),
            optimal: SexRanges(ClinicalRange(1.1, 1.5)),
            direction: .midOptimal,
            info: "The main thyroid hormone in circulation, mostly inactive until converted to T3.",
            displayMin: 0.5, displayMax: 2.2),

        Biomarker(
            id: "ft3", name: "Free T3", shortName: "Free T3",
            category: .thyroid, unit: "pg/mL", altUnit: nil,
            standard: SexRanges(ClinicalRange(2.3, 4.2)),
            optimal: SexRanges(ClinicalRange(3.0, 4.0)),
            direction: .midOptimal,
            info: "The active thyroid hormone that sets your metabolic rate at the cellular level.",
            displayMin: 1.5, displayMax: 5.0),

        // MARK: - CBC
        Biomarker(
            id: "hemoglobin", name: "Hemoglobin", shortName: "Hgb",
            category: .cbc, unit: "g/dL", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(12.0, 15.5), male: ClinicalRange(13.5, 17.5)),
            optimal: SexRanges(female: ClinicalRange(13.0, 14.5), male: ClinicalRange(14.5, 16.0)),
            direction: .midOptimal,
            info: "The oxygen-carrying protein in red blood cells. Low values suggest anemia.",
            displayMin: 9, displayMax: 19),

        Biomarker(
            id: "hematocrit", name: "Hematocrit", shortName: "Hct",
            category: .cbc, unit: "%", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(36, 46), male: ClinicalRange(41, 50)),
            optimal: SexRanges(female: ClinicalRange(38, 44), male: ClinicalRange(43, 48)),
            direction: .midOptimal,
            info: "The fraction of blood volume that is red cells. Sex-specific and tied to hydration and oxygen capacity.",
            displayMin: 30, displayMax: 55),

        Biomarker(
            id: "wbc", name: "White Blood Cells", shortName: "WBC",
            category: .cbc, unit: "10³/µL", altUnit: nil,
            standard: SexRanges(ClinicalRange(4.0, 11.0)),
            optimal: SexRanges(ClinicalRange(5.0, 8.0)),
            direction: .midOptimal,
            info: "Your immune cell count. Both very high and very low values can be meaningful.",
            displayMin: 2, displayMax: 14),

        Biomarker(
            id: "platelets", name: "Platelets", shortName: "Plt",
            category: .cbc, unit: "10³/µL", altUnit: nil,
            standard: SexRanges(ClinicalRange(150, 400)),
            optimal: SexRanges(ClinicalRange(200, 350)),
            direction: .midOptimal,
            info: "Cell fragments that drive clotting. Out-of-range values can affect bleeding or clotting risk.",
            displayMin: 100, displayMax: 450),

        Biomarker(
            id: "rbc", name: "Red Blood Cells", shortName: "RBC",
            category: .cbc, unit: "10⁶/µL", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(4.0, 5.2), male: ClinicalRange(4.5, 5.9)),
            optimal: SexRanges(female: ClinicalRange(4.2, 5.0), male: ClinicalRange(4.7, 5.6)),
            direction: .midOptimal,
            info: "The number of red blood cells. Works alongside hemoglobin and hematocrit to assess oxygen capacity.",
            displayMin: 3.5, displayMax: 6.5),

        // MARK: - Iron
        Biomarker(
            id: "ferritin", name: "Ferritin", shortName: "Ferritin",
            category: .iron, unit: "ng/mL", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(15, 150), male: ClinicalRange(30, 300)),
            optimal: SexRanges(female: ClinicalRange(40, 100), male: ClinicalRange(50, 150)),
            direction: .midOptimal,
            info: "Your iron storage protein. Low values mean depleted iron; very high can reflect inflammation or overload.",
            displayMin: 5, displayMax: 350),

        Biomarker(
            id: "iron", name: "Serum Iron", shortName: "Iron",
            category: .iron, unit: "µg/dL", altUnit: nil,
            standard: SexRanges(ClinicalRange(50, 170)),
            optimal: SexRanges(ClinicalRange(70, 140)),
            direction: .midOptimal,
            info: "Iron currently circulating in blood. Best interpreted with ferritin and TIBC.",
            displayMin: 30, displayMax: 200),

        Biomarker(
            id: "tibc", name: "TIBC", shortName: "TIBC",
            category: .iron, unit: "µg/dL", altUnit: nil,
            standard: SexRanges(ClinicalRange(250, 450)),
            optimal: SexRanges(ClinicalRange(280, 400)),
            direction: .midOptimal,
            info: "Total iron-binding capacity — how much iron your blood could carry. Rises when iron is low.",
            displayMin: 200, displayMax: 500),

        // MARK: - Vitamins
        Biomarker(
            id: "vitd", name: "Vitamin D (25-OH)", shortName: "Vit D",
            category: .vitamins, unit: "ng/mL",
            altUnit: AltUnit(unit: "nmol/L", factor: 2.496),
            standard: SexRanges(ClinicalRange(30, 100)),
            optimal: SexRanges(ClinicalRange(40, 60)),
            direction: .midOptimal,
            info: "Crucial for bone, immune and hormonal health. Many people run low, especially in winter.",
            displayMin: 10, displayMax: 90),

        Biomarker(
            id: "b12", name: "Vitamin B12", shortName: "B12",
            category: .vitamins, unit: "pg/mL", altUnit: nil,
            standard: SexRanges(ClinicalRange(200, 900)),
            optimal: SexRanges(ClinicalRange(500, 900)),
            direction: .higherBetter,
            info: "Essential for nerves and red blood cells. Low-normal values can still cause symptoms.",
            displayMin: 150, displayMax: 1000),

        Biomarker(
            id: "folate", name: "Folate", shortName: "Folate",
            category: .vitamins, unit: "ng/mL", altUnit: nil,
            standard: SexRanges(ClinicalRange(3, 20)),
            optimal: SexRanges(ClinicalRange(10, 20)),
            direction: .higherBetter,
            info: "A B vitamin needed for DNA synthesis and methylation; works with B12 to keep homocysteine low.",
            displayMin: 2, displayMax: 24),

        Biomarker(
            id: "magnesium", name: "Magnesium", shortName: "Mg",
            category: .vitamins, unit: "mg/dL", altUnit: nil,
            standard: SexRanges(ClinicalRange(1.7, 2.4)),
            optimal: SexRanges(ClinicalRange(2.0, 2.3)),
            direction: .midOptimal,
            info: "Involved in hundreds of enzyme reactions. Serum values can miss deficiency, so trend matters.",
            displayMin: 1.4, displayMax: 2.8),

        // MARK: - Liver
        Biomarker(
            id: "alt", name: "ALT", shortName: "ALT",
            category: .liver, unit: "U/L", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(nil, 33), male: ClinicalRange(nil, 41)),
            optimal: SexRanges(female: ClinicalRange(nil, 20), male: ClinicalRange(nil, 25)),
            direction: .higherWorse,
            info: "A liver enzyme. Elevations often track with fatty liver, alcohol, or medications.",
            displayMin: 5, displayMax: 70),

        Biomarker(
            id: "ast", name: "AST", shortName: "AST",
            category: .liver, unit: "U/L", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(nil, 32), male: ClinicalRange(nil, 40)),
            optimal: SexRanges(female: ClinicalRange(nil, 22), male: ClinicalRange(nil, 26)),
            direction: .higherWorse,
            info: "A liver and muscle enzyme. Often interpreted alongside ALT.",
            displayMin: 5, displayMax: 70),

        Biomarker(
            id: "ggt", name: "GGT", shortName: "GGT",
            category: .liver, unit: "U/L", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(nil, 40), male: ClinicalRange(nil, 55)),
            optimal: SexRanges(female: ClinicalRange(nil, 18), male: ClinicalRange(nil, 25)),
            direction: .higherWorse,
            info: "Sensitive to alcohol and bile-flow problems; also a marker of oxidative stress.",
            displayMin: 5, displayMax: 80),

        Biomarker(
            id: "albumin", name: "Albumin", shortName: "Albumin",
            category: .liver, unit: "g/dL", altUnit: nil,
            standard: SexRanges(ClinicalRange(3.5, 5.0)),
            optimal: SexRanges(ClinicalRange(4.3, 5.0)),
            direction: .higherBetter,
            info: "The main protein your liver makes. Higher-normal values track with good nutrition and longevity.",
            displayMin: 3.0, displayMax: 5.5),

        // MARK: - Kidney
        Biomarker(
            id: "creatinine", name: "Creatinine", shortName: "Creat",
            category: .kidney, unit: "mg/dL", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(0.6, 1.1), male: ClinicalRange(0.7, 1.3)),
            optimal: SexRanges(female: ClinicalRange(0.7, 1.0), male: ClinicalRange(0.8, 1.1)),
            direction: .midOptimal,
            info: "A muscle byproduct cleared by the kidneys. Used to estimate kidney function.",
            displayMin: 0.4, displayMax: 1.6),

        Biomarker(
            id: "egfr", name: "eGFR", shortName: "eGFR",
            category: .kidney, unit: "mL/min", altUnit: nil,
            standard: SexRanges(ClinicalRange(90, nil)),
            optimal: SexRanges(ClinicalRange(100, nil)),
            direction: .higherBetter,
            info: "Estimated kidney filtration rate. Higher is better; values under 60 warrant attention.",
            displayMin: 40, displayMax: 130),

        Biomarker(
            id: "bun", name: "BUN", shortName: "BUN",
            category: .kidney, unit: "mg/dL", altUnit: nil,
            standard: SexRanges(ClinicalRange(7, 20)),
            optimal: SexRanges(ClinicalRange(10, 16)),
            direction: .midOptimal,
            info: "Blood urea nitrogen — a kidney and hydration marker, interpreted with creatinine.",
            displayMin: 4, displayMax: 28),

        Biomarker(
            id: "uric_acid", name: "Uric Acid", shortName: "Uric",
            category: .kidney, unit: "mg/dL", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(2.5, 6.0), male: ClinicalRange(3.5, 7.2)),
            optimal: SexRanges(female: ClinicalRange(3.0, 5.0), male: ClinicalRange(3.5, 5.5)),
            direction: .midOptimal,
            info: "High values can cause gout and track with metabolic risk; very low is uncommon.",
            displayMin: 2, displayMax: 9),

        // MARK: - Hormones
        Biomarker(
            id: "testosterone", name: "Total Testosterone", shortName: "Test",
            category: .hormones, unit: "ng/dL", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(15, 70), male: ClinicalRange(300, 1000)),
            optimal: SexRanges(female: ClinicalRange(25, 60), male: ClinicalRange(550, 900)),
            direction: .midOptimal,
            info: "A key hormone for both sexes (very different ranges). Affects energy, mood, muscle and libido.",
            displayMin: 10, displayMax: 1100),

        Biomarker(
            id: "free_test", name: "Free Testosterone", shortName: "Free T",
            category: .hormones, unit: "pg/mL", altUnit: nil,
            standard: SexRanges(female: ClinicalRange(0.3, 1.9), male: ClinicalRange(5.0, 21.0)),
            optimal: SexRanges(female: ClinicalRange(0.6, 1.6), male: ClinicalRange(9.0, 18.0)),
            direction: .midOptimal,
            info: "The biologically active fraction of testosterone not bound to proteins.",
            displayMin: 0.2, displayMax: 25)
    ]
}
