import Foundation

/// Static catalog of built-in starter templates seeded on first launch.
enum TemplateSeed {
    struct Spec {
        let name: String
        let detail: String
        let symbol: String
        /// (name, quantity, category)
        let items: [(String, Int, PackCategory)]
    }

    static let builtIns: [Spec] = [
        Spec(
            name: "Carry-On Essentials",
            detail: "The non-negotiables for any flight",
            symbol: "bag.fill",
            items: [
                ("Passport / ID", 1, .documents),
                ("Boarding passes", 1, .documents),
                ("Wallet & cards", 1, .documents),
                ("Phone", 1, .electronics),
                ("Phone charger", 1, .electronics),
                ("Power bank", 1, .electronics),
                ("Headphones", 1, .electronics),
                ("Reusable water bottle", 1, .misc),
                ("Snacks", 1, .misc),
                ("Neck pillow", 1, .gear),
                ("Medications", 1, .toiletries),
                ("Hand sanitiser", 1, .toiletries),
            ]
        ),
        Spec(
            name: "Toiletry Kit",
            detail: "Bathroom basics, TSA-friendly sizes",
            symbol: "drop.fill",
            items: [
                ("Toothbrush", 1, .toiletries),
                ("Toothpaste", 1, .toiletries),
                ("Deodorant", 1, .toiletries),
                ("Shampoo", 1, .toiletries),
                ("Conditioner", 1, .toiletries),
                ("Body wash", 1, .toiletries),
                ("Razor", 1, .toiletries),
                ("Moisturiser", 1, .toiletries),
                ("Sunscreen SPF 50", 1, .toiletries),
                ("Comb / brush", 1, .toiletries),
                ("Nail clippers", 1, .toiletries),
                ("Toiletry bag", 1, .toiletries),
            ]
        ),
        Spec(
            name: "Tech Bag",
            detail: "Cables, chargers and gadgets",
            symbol: "bolt.fill",
            items: [
                ("Laptop", 1, .electronics),
                ("Laptop charger", 1, .electronics),
                ("Travel adapter", 1, .electronics),
                ("USB-C cables", 2, .electronics),
                ("Power bank", 1, .electronics),
                ("Noise-cancelling headphones", 1, .electronics),
                ("Camera", 1, .electronics),
                ("Spare batteries & cards", 1, .electronics),
                ("E-reader", 1, .electronics),
                ("Cable organiser", 1, .gear),
            ]
        ),
        Spec(
            name: "Beach Day",
            detail: "Everything for a day in the sun",
            symbol: "beach.umbrella.fill",
            items: [
                ("Swimsuit", 2, .clothing),
                ("Beach towel", 1, .gear),
                ("Sunscreen SPF 50", 1, .toiletries),
                ("After-sun lotion", 1, .toiletries),
                ("Sunglasses", 1, .gear),
                ("Sun hat", 1, .gear),
                ("Flip-flops", 1, .clothing),
                ("Beach bag", 1, .gear),
                ("Water bottle", 1, .misc),
                ("Waterproof phone pouch", 1, .gear),
            ]
        ),
        Spec(
            name: "Baby & Toddler",
            detail: "Travelling with little ones",
            symbol: "figure.and.child.holdinghands",
            items: [
                ("Nappies / diapers", 1, .misc),
                ("Wet wipes", 1, .toiletries),
                ("Baby clothes sets", 6, .clothing),
                ("Bottles & formula", 1, .misc),
                ("Favourite toys", 1, .misc),
                ("Pram / stroller", 1, .gear),
                ("Baby carrier", 1, .gear),
                ("Snacks for kids", 1, .misc),
                ("Sun hat", 1, .clothing),
                ("Comfort blanket", 1, .misc),
            ]
        ),
    ]
}
