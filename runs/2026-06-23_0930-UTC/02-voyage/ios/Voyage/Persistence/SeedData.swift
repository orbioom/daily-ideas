import Foundation
import SwiftData

/// Curated, offline mock fixtures: four language decks, each with 50+ travel
/// phrases spanning all six categories. No network, no API keys.
enum SeedData {

    /// A lightweight blueprint used to construct `Phrase` models.
    struct PhraseSpec {
        let source: String
        let target: String
        let pron: String
        let category: PhraseCategory
    }

    struct DeckSpec {
        let name: String
        let endonym: String
        let flag: String
        let locale: String
        let subtitle: String
        let phrases: [PhraseSpec]
    }

    /// Build and insert all decks into the given context.
    static func seed(into context: ModelContext) {
        for (index, spec) in allDecks.enumerated() {
            let deck = Deck(
                name: spec.name,
                endonym: spec.endonym,
                flag: spec.flag,
                localeIdentifier: spec.locale,
                subtitle: spec.subtitle,
                sortIndex: index
            )
            context.insert(deck)
            for (i, p) in spec.phrases.enumerated() {
                let phrase = Phrase(
                    source: p.source,
                    target: p.target,
                    pronunciation: p.pron,
                    category: p.category,
                    orderIndex: i,
                    deck: deck
                )
                context.insert(phrase)
            }
        }
    }

    static var allDecks: [DeckSpec] {
        [spanish, french, italian, japanese]
    }

    // MARK: - Spanish
    static let spanish = DeckSpec(
        name: "Spanish", endonym: "Español", flag: "🇪🇸", locale: "es-ES",
        subtitle: "Survival phrases for Spain & Latin America",
        phrases: [
            // Greetings
            .init(source: "Hello", target: "Hola", pron: "OH-lah", category: .greetings),
            .init(source: "Good morning", target: "Buenos días", pron: "BWEH-nos DEE-as", category: .greetings),
            .init(source: "Good evening", target: "Buenas tardes", pron: "BWEH-nas TAR-des", category: .greetings),
            .init(source: "Goodbye", target: "Adiós", pron: "ah-dee-OHS", category: .greetings),
            .init(source: "Please", target: "Por favor", pron: "por fah-VOR", category: .greetings),
            .init(source: "Thank you", target: "Gracias", pron: "GRAH-see-as", category: .greetings),
            .init(source: "You're welcome", target: "De nada", pron: "deh NAH-dah", category: .greetings),
            .init(source: "Nice to meet you", target: "Mucho gusto", pron: "MOO-cho GOOS-toh", category: .greetings),
            // Basics
            .init(source: "Yes", target: "Sí", pron: "see", category: .basics),
            .init(source: "No", target: "No", pron: "noh", category: .basics),
            .init(source: "Excuse me", target: "Perdón", pron: "per-DOHN", category: .basics),
            .init(source: "I'm sorry", target: "Lo siento", pron: "loh see-EN-toh", category: .basics),
            .init(source: "Do you speak English?", target: "¿Habla inglés?", pron: "AH-blah een-GLES", category: .basics),
            .init(source: "I don't understand", target: "No entiendo", pron: "noh en-tee-EN-doh", category: .basics),
            .init(source: "Can you help me?", target: "¿Puede ayudarme?", pron: "PWEH-deh ah-yoo-DAR-meh", category: .basics),
            .init(source: "How much is it?", target: "¿Cuánto cuesta?", pron: "KWAN-toh KWES-tah", category: .basics),
            .init(source: "Where is the bathroom?", target: "¿Dónde está el baño?", pron: "DON-deh es-TAH el BAH-nyo", category: .basics),
            // Dining
            .init(source: "A table for two, please", target: "Una mesa para dos, por favor", pron: "OO-nah MEH-sah PAH-rah dos", category: .dining),
            .init(source: "The menu, please", target: "La carta, por favor", pron: "lah KAR-tah", category: .dining),
            .init(source: "Water, please", target: "Agua, por favor", pron: "AH-gwah", category: .dining),
            .init(source: "I'd like a coffee", target: "Quiero un café", pron: "kee-EH-roh oon kah-FEH", category: .dining),
            .init(source: "I'm vegetarian", target: "Soy vegetariano", pron: "soy veh-heh-tah-ree-AH-no", category: .dining),
            .init(source: "The check, please", target: "La cuenta, por favor", pron: "lah KWEN-tah", category: .dining),
            .init(source: "It was delicious", target: "Estaba delicioso", pron: "es-TAH-bah deh-lee-see-OH-so", category: .dining),
            .init(source: "I have an allergy", target: "Tengo una alergia", pron: "TEN-go OO-nah ah-LER-hee-ah", category: .dining),
            // Directions
            .init(source: "Where is the station?", target: "¿Dónde está la estación?", pron: "DON-deh es-TAH lah es-tah-see-OHN", category: .directions),
            .init(source: "Turn left", target: "Gire a la izquierda", pron: "HEE-reh ah lah ees-kee-ER-dah", category: .directions),
            .init(source: "Turn right", target: "Gire a la derecha", pron: "HEE-reh ah lah deh-REH-cha", category: .directions),
            .init(source: "Straight ahead", target: "Todo recto", pron: "TOH-doh REK-toh", category: .directions),
            .init(source: "Is it far?", target: "¿Está lejos?", pron: "es-TAH LEH-hos", category: .directions),
            .init(source: "I'm lost", target: "Estoy perdido", pron: "es-TOY per-DEE-doh", category: .directions),
            .init(source: "How do I get to the center?", target: "¿Cómo llego al centro?", pron: "KOH-mo YEH-go al SEN-troh", category: .directions),
            .init(source: "A taxi, please", target: "Un taxi, por favor", pron: "oon TAK-see", category: .directions),
            // Shopping
            .init(source: "Do you accept cards?", target: "¿Aceptan tarjetas?", pron: "ah-SEP-tan tar-HEH-tas", category: .shopping),
            .init(source: "I'm just looking", target: "Solo estoy mirando", pron: "SOH-loh es-TOY mee-RAN-doh", category: .shopping),
            .init(source: "Do you have a smaller size?", target: "¿Tiene una talla más pequeña?", pron: "tee-EH-neh OO-nah TAH-yah", category: .shopping),
            .init(source: "It's too expensive", target: "Es demasiado caro", pron: "es deh-mah-see-AH-doh KAH-roh", category: .shopping),
            .init(source: "Can I try it on?", target: "¿Puedo probármelo?", pron: "PWEH-doh proh-BAR-meh-loh", category: .shopping),
            .init(source: "I'll take it", target: "Me lo llevo", pron: "meh loh YEH-voh", category: .shopping),
            .init(source: "A receipt, please", target: "Un recibo, por favor", pron: "oon reh-SEE-boh", category: .shopping),
            // Emergencies
            .init(source: "Help!", target: "¡Ayuda!", pron: "ah-YOO-dah", category: .emergencies),
            .init(source: "Call the police", target: "Llame a la policía", pron: "YAH-meh ah lah po-lee-SEE-ah", category: .emergencies),
            .init(source: "Call a doctor", target: "Llame a un médico", pron: "YAH-meh ah oon MEH-dee-koh", category: .emergencies),
            .init(source: "I need a hospital", target: "Necesito un hospital", pron: "neh-seh-SEE-toh oon os-pee-TAL", category: .emergencies),
            .init(source: "I feel sick", target: "Me siento mal", pron: "meh see-EN-toh mal", category: .emergencies),
            .init(source: "It's an emergency", target: "Es una emergencia", pron: "es OO-nah eh-mer-HEN-see-ah", category: .emergencies),
            .init(source: "I lost my passport", target: "Perdí mi pasaporte", pron: "per-DEE mee pah-sah-POR-teh", category: .emergencies),
            .init(source: "Where is the pharmacy?", target: "¿Dónde está la farmacia?", pron: "DON-deh es-TAH lah far-MAH-see-ah", category: .emergencies),
            .init(source: "I have been robbed", target: "Me han robado", pron: "meh an roh-BAH-doh", category: .emergencies),
            .init(source: "Please hurry", target: "Por favor, dese prisa", pron: "por fah-VOR DEH-seh PREE-sah", category: .emergencies),
            .init(source: "My friend is hurt", target: "Mi amigo está herido", pron: "mee ah-MEE-go es-TAH eh-REE-doh", category: .emergencies),
            .init(source: "I need an ambulance", target: "Necesito una ambulancia", pron: "neh-seh-SEE-toh OO-nah am-boo-LAN-see-ah", category: .emergencies)
        ]
    )

    // MARK: - French
    static let french = DeckSpec(
        name: "French", endonym: "Français", flag: "🇫🇷", locale: "fr-FR",
        subtitle: "Essentials for France & francophone travel",
        phrases: [
            .init(source: "Hello", target: "Bonjour", pron: "bon-ZHOOR", category: .greetings),
            .init(source: "Good evening", target: "Bonsoir", pron: "bon-SWAR", category: .greetings),
            .init(source: "Goodbye", target: "Au revoir", pron: "oh ruh-VWAR", category: .greetings),
            .init(source: "Please", target: "S'il vous plaît", pron: "seel voo PLEH", category: .greetings),
            .init(source: "Thank you", target: "Merci", pron: "mehr-SEE", category: .greetings),
            .init(source: "You're welcome", target: "De rien", pron: "duh ree-EN", category: .greetings),
            .init(source: "Nice to meet you", target: "Enchanté", pron: "on-shon-TAY", category: .greetings),
            .init(source: "See you soon", target: "À bientôt", pron: "ah bee-en-TOH", category: .greetings),
            .init(source: "Yes", target: "Oui", pron: "wee", category: .basics),
            .init(source: "No", target: "Non", pron: "nohn", category: .basics),
            .init(source: "Excuse me", target: "Excusez-moi", pron: "ex-koo-zay MWAH", category: .basics),
            .init(source: "I'm sorry", target: "Je suis désolé", pron: "zhuh swee day-zoh-LAY", category: .basics),
            .init(source: "Do you speak English?", target: "Parlez-vous anglais?", pron: "par-lay voo on-GLEH", category: .basics),
            .init(source: "I don't understand", target: "Je ne comprends pas", pron: "zhuh nuh kom-PRON pah", category: .basics),
            .init(source: "Can you help me?", target: "Pouvez-vous m'aider?", pron: "poo-vay voo may-DAY", category: .basics),
            .init(source: "How much is it?", target: "Combien ça coûte?", pron: "kom-bee-EN sah KOOT", category: .basics),
            .init(source: "Where is the bathroom?", target: "Où sont les toilettes?", pron: "oo son lay twah-LET", category: .basics),
            .init(source: "A table for two, please", target: "Une table pour deux, s'il vous plaît", pron: "oon TAH-bluh poor duh", category: .dining),
            .init(source: "The menu, please", target: "La carte, s'il vous plaît", pron: "lah KART", category: .dining),
            .init(source: "Water, please", target: "De l'eau, s'il vous plaît", pron: "duh LOH", category: .dining),
            .init(source: "I'd like a coffee", target: "Je voudrais un café", pron: "zhuh voo-DREH un kah-FAY", category: .dining),
            .init(source: "I'm vegetarian", target: "Je suis végétarien", pron: "zhuh swee vay-zhay-tah-ree-EN", category: .dining),
            .init(source: "The check, please", target: "L'addition, s'il vous plaît", pron: "lah-dee-see-OHN", category: .dining),
            .init(source: "It was delicious", target: "C'était délicieux", pron: "say-TEH day-lee-see-UH", category: .dining),
            .init(source: "I have an allergy", target: "J'ai une allergie", pron: "zhay oon ah-lehr-ZHEE", category: .dining),
            .init(source: "Where is the station?", target: "Où est la gare?", pron: "oo eh lah GAR", category: .directions),
            .init(source: "Turn left", target: "Tournez à gauche", pron: "toor-NAY ah GOHSH", category: .directions),
            .init(source: "Turn right", target: "Tournez à droite", pron: "toor-NAY ah DRWAHT", category: .directions),
            .init(source: "Straight ahead", target: "Tout droit", pron: "too DRWAH", category: .directions),
            .init(source: "Is it far?", target: "C'est loin?", pron: "say LWAN", category: .directions),
            .init(source: "I'm lost", target: "Je suis perdu", pron: "zhuh swee pehr-DOO", category: .directions),
            .init(source: "How do I get to the center?", target: "Comment aller au centre?", pron: "koh-mon ah-LAY oh SON-truh", category: .directions),
            .init(source: "A taxi, please", target: "Un taxi, s'il vous plaît", pron: "un tak-SEE", category: .directions),
            .init(source: "Do you accept cards?", target: "Acceptez-vous les cartes?", pron: "ak-sep-tay voo lay KART", category: .shopping),
            .init(source: "I'm just looking", target: "Je regarde seulement", pron: "zhuh ruh-GARD suhl-MON", category: .shopping),
            .init(source: "Do you have a smaller size?", target: "Avez-vous une taille plus petite?", pron: "ah-vay voo oon TAH-yuh", category: .shopping),
            .init(source: "It's too expensive", target: "C'est trop cher", pron: "say troh SHEHR", category: .shopping),
            .init(source: "Can I try it on?", target: "Puis-je l'essayer?", pron: "pwee zhuh leh-say-YAY", category: .shopping),
            .init(source: "I'll take it", target: "Je le prends", pron: "zhuh luh PRON", category: .shopping),
            .init(source: "A receipt, please", target: "Un reçu, s'il vous plaît", pron: "un ruh-SOO", category: .shopping),
            .init(source: "Help!", target: "Au secours!", pron: "oh suh-KOOR", category: .emergencies),
            .init(source: "Call the police", target: "Appelez la police", pron: "ah-puh-lay lah po-LEES", category: .emergencies),
            .init(source: "Call a doctor", target: "Appelez un médecin", pron: "ah-puh-lay un mayd-SAN", category: .emergencies),
            .init(source: "I need a hospital", target: "J'ai besoin d'un hôpital", pron: "zhay buh-zwan dun oh-pee-TAL", category: .emergencies),
            .init(source: "I feel sick", target: "Je me sens mal", pron: "zhuh muh son MAL", category: .emergencies),
            .init(source: "It's an emergency", target: "C'est une urgence", pron: "say toon oor-ZHONS", category: .emergencies),
            .init(source: "I lost my passport", target: "J'ai perdu mon passeport", pron: "zhay pehr-DOO mon pas-POR", category: .emergencies),
            .init(source: "Where is the pharmacy?", target: "Où est la pharmacie?", pron: "oo eh lah far-mah-SEE", category: .emergencies),
            .init(source: "I have been robbed", target: "On m'a volé", pron: "on mah voh-LAY", category: .emergencies),
            .init(source: "Please hurry", target: "Dépêchez-vous, s'il vous plaît", pron: "day-peh-shay VOO", category: .emergencies),
            .init(source: "I need an ambulance", target: "J'ai besoin d'une ambulance", pron: "zhay buh-zwan doon om-boo-LONS", category: .emergencies)
        ]
    )

    // MARK: - Italian
    static let italian = DeckSpec(
        name: "Italian", endonym: "Italiano", flag: "🇮🇹", locale: "it-IT",
        subtitle: "From Rome to the Amalfi Coast",
        phrases: [
            .init(source: "Hello", target: "Ciao", pron: "chow", category: .greetings),
            .init(source: "Good morning", target: "Buongiorno", pron: "bwon-JOR-no", category: .greetings),
            .init(source: "Good evening", target: "Buonasera", pron: "bwoh-nah-SEH-rah", category: .greetings),
            .init(source: "Goodbye", target: "Arrivederci", pron: "ah-ree-veh-DER-chee", category: .greetings),
            .init(source: "Please", target: "Per favore", pron: "per fah-VOH-reh", category: .greetings),
            .init(source: "Thank you", target: "Grazie", pron: "GRAH-tsee-eh", category: .greetings),
            .init(source: "You're welcome", target: "Prego", pron: "PREH-go", category: .greetings),
            .init(source: "Nice to meet you", target: "Piacere", pron: "pee-ah-CHEH-reh", category: .greetings),
            .init(source: "Yes", target: "Sì", pron: "see", category: .basics),
            .init(source: "No", target: "No", pron: "noh", category: .basics),
            .init(source: "Excuse me", target: "Mi scusi", pron: "mee SKOO-zee", category: .basics),
            .init(source: "I'm sorry", target: "Mi dispiace", pron: "mee dis-pee-AH-cheh", category: .basics),
            .init(source: "Do you speak English?", target: "Parla inglese?", pron: "PAR-lah een-GLEH-zeh", category: .basics),
            .init(source: "I don't understand", target: "Non capisco", pron: "non kah-PEES-koh", category: .basics),
            .init(source: "Can you help me?", target: "Può aiutarmi?", pron: "pwoh ah-yoo-TAR-mee", category: .basics),
            .init(source: "How much is it?", target: "Quanto costa?", pron: "KWAN-toh KOS-tah", category: .basics),
            .init(source: "Where is the bathroom?", target: "Dov'è il bagno?", pron: "doh-VEH eel BAH-nyo", category: .basics),
            .init(source: "A table for two, please", target: "Un tavolo per due, per favore", pron: "oon TAH-vo-lo per DOO-eh", category: .dining),
            .init(source: "The menu, please", target: "Il menù, per favore", pron: "eel meh-NOO", category: .dining),
            .init(source: "Water, please", target: "Acqua, per favore", pron: "AH-kwah", category: .dining),
            .init(source: "I'd like a coffee", target: "Vorrei un caffè", pron: "vor-RAY oon kahf-FEH", category: .dining),
            .init(source: "I'm vegetarian", target: "Sono vegetariano", pron: "SOH-no veh-jeh-tah-ree-AH-no", category: .dining),
            .init(source: "The check, please", target: "Il conto, per favore", pron: "eel KON-toh", category: .dining),
            .init(source: "It was delicious", target: "Era squisito", pron: "EH-rah skwee-ZEE-toh", category: .dining),
            .init(source: "I have an allergy", target: "Ho un'allergia", pron: "oh oon ah-ler-JEE-ah", category: .dining),
            .init(source: "Where is the station?", target: "Dov'è la stazione?", pron: "doh-VEH lah stah-tsee-OH-neh", category: .directions),
            .init(source: "Turn left", target: "Giri a sinistra", pron: "JEE-ree ah see-NEES-trah", category: .directions),
            .init(source: "Turn right", target: "Giri a destra", pron: "JEE-ree ah DES-trah", category: .directions),
            .init(source: "Straight ahead", target: "Sempre dritto", pron: "SEM-preh DREET-toh", category: .directions),
            .init(source: "Is it far?", target: "È lontano?", pron: "eh lon-TAH-no", category: .directions),
            .init(source: "I'm lost", target: "Mi sono perso", pron: "mee SOH-no PER-so", category: .directions),
            .init(source: "How do I get to the center?", target: "Come arrivo al centro?", pron: "KOH-meh ar-REE-vo al CHEN-troh", category: .directions),
            .init(source: "A taxi, please", target: "Un taxi, per favore", pron: "oon TAK-see", category: .directions),
            .init(source: "Do you accept cards?", target: "Accettate carte?", pron: "ah-cheht-TAH-teh KAR-teh", category: .shopping),
            .init(source: "I'm just looking", target: "Sto solo guardando", pron: "stoh SOH-lo gwar-DAN-doh", category: .shopping),
            .init(source: "Do you have a smaller size?", target: "Avete una taglia più piccola?", pron: "ah-VEH-teh OO-nah TAH-lyah", category: .shopping),
            .init(source: "It's too expensive", target: "È troppo caro", pron: "eh TROP-po KAH-roh", category: .shopping),
            .init(source: "Can I try it on?", target: "Posso provarlo?", pron: "POS-so pro-VAR-lo", category: .shopping),
            .init(source: "I'll take it", target: "Lo prendo", pron: "lo PREN-doh", category: .shopping),
            .init(source: "A receipt, please", target: "Uno scontrino, per favore", pron: "OO-no skon-TREE-no", category: .shopping),
            .init(source: "Help!", target: "Aiuto!", pron: "ah-YOO-toh", category: .emergencies),
            .init(source: "Call the police", target: "Chiami la polizia", pron: "kee-AH-mee lah po-lee-TSEE-ah", category: .emergencies),
            .init(source: "Call a doctor", target: "Chiami un medico", pron: "kee-AH-mee oon MEH-dee-koh", category: .emergencies),
            .init(source: "I need a hospital", target: "Ho bisogno di un ospedale", pron: "oh bee-ZOH-nyo dee oon os-peh-DAH-leh", category: .emergencies),
            .init(source: "I feel sick", target: "Mi sento male", pron: "mee SEN-toh MAH-leh", category: .emergencies),
            .init(source: "It's an emergency", target: "È un'emergenza", pron: "eh oon eh-mer-JEN-tsah", category: .emergencies),
            .init(source: "I lost my passport", target: "Ho perso il passaporto", pron: "oh PER-so eel pas-sah-POR-toh", category: .emergencies),
            .init(source: "Where is the pharmacy?", target: "Dov'è la farmacia?", pron: "doh-VEH lah far-mah-CHEE-ah", category: .emergencies),
            .init(source: "I have been robbed", target: "Sono stato derubato", pron: "SOH-no STAH-toh deh-roo-BAH-toh", category: .emergencies),
            .init(source: "Please hurry", target: "Si sbrighi, per favore", pron: "see ZBREE-ghee", category: .emergencies),
            .init(source: "I need an ambulance", target: "Ho bisogno di un'ambulanza", pron: "oh bee-ZOH-nyo dee oon am-boo-LAN-tsah", category: .emergencies)
        ]
    )

    // MARK: - Japanese
    static let japanese = DeckSpec(
        name: "Japanese", endonym: "日本語", flag: "🇯🇵", locale: "ja-JP",
        subtitle: "Polite, practical phrases for Japan",
        phrases: [
            .init(source: "Hello", target: "こんにちは", pron: "kon-nee-chee-wah", category: .greetings),
            .init(source: "Good morning", target: "おはようございます", pron: "oh-hah-yoh goh-zah-ee-mas", category: .greetings),
            .init(source: "Good evening", target: "こんばんは", pron: "kon-ban-wah", category: .greetings),
            .init(source: "Goodbye", target: "さようなら", pron: "sah-yoh-nah-rah", category: .greetings),
            .init(source: "Please", target: "お願いします", pron: "oh-neh-gah-ee shee-mas", category: .greetings),
            .init(source: "Thank you", target: "ありがとうございます", pron: "ah-ree-gah-toh goh-zah-ee-mas", category: .greetings),
            .init(source: "You're welcome", target: "どういたしまして", pron: "doh ee-tah-shee-mah-shteh", category: .greetings),
            .init(source: "Nice to meet you", target: "はじめまして", pron: "hah-jee-meh-mah-shteh", category: .greetings),
            .init(source: "Yes", target: "はい", pron: "hah-ee", category: .basics),
            .init(source: "No", target: "いいえ", pron: "ee-eh", category: .basics),
            .init(source: "Excuse me", target: "すみません", pron: "soo-mee-mah-sen", category: .basics),
            .init(source: "I'm sorry", target: "ごめんなさい", pron: "goh-men-nah-sah-ee", category: .basics),
            .init(source: "Do you speak English?", target: "英語を話せますか", pron: "ay-goh oh hah-nah-seh-mas-kah", category: .basics),
            .init(source: "I don't understand", target: "わかりません", pron: "wah-kah-ree-mah-sen", category: .basics),
            .init(source: "Can you help me?", target: "助けてください", pron: "tah-soo-keh-teh koo-dah-sah-ee", category: .basics),
            .init(source: "How much is it?", target: "いくらですか", pron: "ee-koo-rah des-kah", category: .basics),
            .init(source: "Where is the bathroom?", target: "トイレはどこですか", pron: "toh-ee-reh wah doh-koh des-kah", category: .basics),
            .init(source: "A table for two, please", target: "二人席をお願いします", pron: "foo-tah-ree seh-kee oh oh-neh-gah-ee", category: .dining),
            .init(source: "The menu, please", target: "メニューをください", pron: "meh-nyoo oh koo-dah-sah-ee", category: .dining),
            .init(source: "Water, please", target: "お水をください", pron: "oh-mee-zoo oh koo-dah-sah-ee", category: .dining),
            .init(source: "I'd like a coffee", target: "コーヒーをください", pron: "koh-hee oh koo-dah-sah-ee", category: .dining),
            .init(source: "I'm vegetarian", target: "ベジタリアンです", pron: "beh-jee-tah-ree-an des", category: .dining),
            .init(source: "The check, please", target: "お会計をお願いします", pron: "oh-kah-ee-keh oh oh-neh-gah-ee", category: .dining),
            .init(source: "It was delicious", target: "おいしかったです", pron: "oh-ee-shee-kah-tah des", category: .dining),
            .init(source: "I have an allergy", target: "アレルギーがあります", pron: "ah-reh-roo-gee gah ah-ree-mas", category: .dining),
            .init(source: "Where is the station?", target: "駅はどこですか", pron: "eh-kee wah doh-koh des-kah", category: .directions),
            .init(source: "Turn left", target: "左に曲がってください", pron: "hee-dah-ree nee mah-gah-teh", category: .directions),
            .init(source: "Turn right", target: "右に曲がってください", pron: "mee-gee nee mah-gah-teh", category: .directions),
            .init(source: "Straight ahead", target: "まっすぐです", pron: "mas-soo-goo des", category: .directions),
            .init(source: "Is it far?", target: "遠いですか", pron: "toh-oh-ee des-kah", category: .directions),
            .init(source: "I'm lost", target: "道に迷いました", pron: "mee-chee nee mah-yoh-ee-mah-shtah", category: .directions),
            .init(source: "How do I get to the center?", target: "中心部へどう行きますか", pron: "choo-shin-boo eh doh ee-kee-mas-kah", category: .directions),
            .init(source: "A taxi, please", target: "タクシーをお願いします", pron: "tak-shee oh oh-neh-gah-ee", category: .directions),
            .init(source: "Do you accept cards?", target: "カードは使えますか", pron: "kah-doh wah tsoo-kah-eh-mas-kah", category: .shopping),
            .init(source: "I'm just looking", target: "見ているだけです", pron: "mee-teh ee-roo dah-keh des", category: .shopping),
            .init(source: "Do you have a smaller size?", target: "小さいサイズはありますか", pron: "chee-sah-ee sah-ee-zoo wah ah-ree-mas-kah", category: .shopping),
            .init(source: "It's too expensive", target: "高すぎます", pron: "tah-kah-soo-gee-mas", category: .shopping),
            .init(source: "Can I try it on?", target: "試着できますか", pron: "shee-chah-koo deh-kee-mas-kah", category: .shopping),
            .init(source: "I'll take it", target: "これをください", pron: "koh-reh oh koo-dah-sah-ee", category: .shopping),
            .init(source: "A receipt, please", target: "領収書をください", pron: "ryoh-shoo-shoh oh koo-dah-sah-ee", category: .shopping),
            .init(source: "Help!", target: "助けて！", pron: "tah-soo-keh-teh", category: .emergencies),
            .init(source: "Call the police", target: "警察を呼んでください", pron: "kay-sah-tsoo oh yon-deh", category: .emergencies),
            .init(source: "Call a doctor", target: "医者を呼んでください", pron: "ee-shah oh yon-deh", category: .emergencies),
            .init(source: "I need a hospital", target: "病院が必要です", pron: "byoh-een gah hee-tsoo-yoh des", category: .emergencies),
            .init(source: "I feel sick", target: "気分が悪いです", pron: "kee-boon gah wah-roo-ee des", category: .emergencies),
            .init(source: "It's an emergency", target: "緊急事態です", pron: "kin-kyoo jee-tah-ee des", category: .emergencies),
            .init(source: "I lost my passport", target: "パスポートをなくしました", pron: "pas-poh-toh oh nah-koo-shee-mah-shtah", category: .emergencies),
            .init(source: "Where is the pharmacy?", target: "薬局はどこですか", pron: "yah-kyoh-koo wah doh-koh des-kah", category: .emergencies),
            .init(source: "I have been robbed", target: "盗まれました", pron: "noo-soo-mah-reh-mah-shtah", category: .emergencies),
            .init(source: "Please hurry", target: "急いでください", pron: "ee-soh-ee-deh koo-dah-sah-ee", category: .emergencies),
            .init(source: "I need an ambulance", target: "救急車が必要です", pron: "kyoo-kyoo-shah gah hee-tsoo-yoh des", category: .emergencies)
        ]
    )
}
