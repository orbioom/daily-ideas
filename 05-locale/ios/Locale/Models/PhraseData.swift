import Foundation
import AVFoundation

// MARK: - Data Models

struct Language: Identifiable, Hashable {
    let id: String
    let name: String
    let nativeName: String
    let flag: String
    let avLocale: String  // BCP 47 for AVSpeechSynthesisVoice
    let isPro: Bool
}

struct PhraseCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
}

struct Phrase: Identifiable {
    let id: String
    let english: String
    let translation: String
    let phonetic: String   // romanized pronunciation guide
    let categoryId: String
    let languageId: String
}

// MARK: - Language Registry

enum LanguageRegistry {
    static let all: [Language] = [
        Language(id: "es", name: "Spanish", nativeName: "Español", flag: "🇪🇸", avLocale: "es-ES", isPro: false),
        Language(id: "fr", name: "French", nativeName: "Français", flag: "🇫🇷", avLocale: "fr-FR", isPro: false),
        Language(id: "it", name: "Italian", nativeName: "Italiano", flag: "🇮🇹", avLocale: "it-IT", isPro: true),
        Language(id: "de", name: "German", nativeName: "Deutsch", flag: "🇩🇪", avLocale: "de-DE", isPro: true),
        Language(id: "ja", name: "Japanese", nativeName: "日本語", flag: "🇯🇵", avLocale: "ja-JP", isPro: true),
        Language(id: "pt", name: "Portuguese", nativeName: "Português", flag: "🇧🇷", avLocale: "pt-BR", isPro: true)
    ]
}

// MARK: - Category Registry

enum CategoryRegistry {
    static let all: [PhraseCategory] = [
        PhraseCategory(id: "basics", name: "Basics", emoji: "👋"),
        PhraseCategory(id: "numbers", name: "Numbers & Time", emoji: "🔢"),
        PhraseCategory(id: "directions", name: "Directions", emoji: "🗺️"),
        PhraseCategory(id: "transport", name: "Transport", emoji: "🚆"),
        PhraseCategory(id: "hotel", name: "Hotel", emoji: "🏨"),
        PhraseCategory(id: "restaurant", name: "Restaurant", emoji: "🍽️"),
        PhraseCategory(id: "shopping", name: "Shopping", emoji: "🛍️"),
        PhraseCategory(id: "emergency", name: "Emergency", emoji: "🆘")
    ]
}

// MARK: - Phrase Database

enum PhraseDatabase {
    static let all: [Phrase] = spanishPhrases + frenchPhrases + italianPhrases + germanPhrases + japanesePhrases + portuguesePhrases

    // MARK: Spanish

    static let spanishPhrases: [Phrase] = [
        // Basics
        Phrase(id:"es-b01",english:"Hello",translation:"Hola",phonetic:"OH-lah",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b02",english:"Good morning",translation:"Buenos días",phonetic:"BWEH-nos DEE-as",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b03",english:"Good afternoon",translation:"Buenas tardes",phonetic:"BWEH-nas TAR-des",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b04",english:"Good night",translation:"Buenas noches",phonetic:"BWEH-nas NOH-ches",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b05",english:"Goodbye",translation:"Adiós",phonetic:"ah-dee-OHS",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b06",english:"Please",translation:"Por favor",phonetic:"por fah-VOR",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b07",english:"Thank you",translation:"Gracias",phonetic:"GRAH-see-as",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b08",english:"You're welcome",translation:"De nada",phonetic:"deh NAH-dah",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b09",english:"Yes",translation:"Sí",phonetic:"see",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b10",english:"No",translation:"No",phonetic:"noh",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b11",english:"Sorry / Excuse me",translation:"Lo siento / Perdón",phonetic:"loh see-EN-toh / pehr-DON",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b12",english:"Do you speak English?",translation:"¿Habla inglés?",phonetic:"AH-blah een-GLES",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b13",english:"I don't understand",translation:"No entiendo",phonetic:"noh en-tee-EN-doh",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b14",english:"Can you help me?",translation:"¿Me puede ayudar?",phonetic:"meh PWEH-deh ah-yoo-DAR",categoryId:"basics",languageId:"es"),
        Phrase(id:"es-b15",english:"My name is…",translation:"Me llamo…",phonetic:"meh YAH-moh",categoryId:"basics",languageId:"es"),
        // Numbers & Time
        Phrase(id:"es-n01",english:"One",translation:"Uno",phonetic:"OO-noh",categoryId:"numbers",languageId:"es"),
        Phrase(id:"es-n02",english:"Two",translation:"Dos",phonetic:"dohs",categoryId:"numbers",languageId:"es"),
        Phrase(id:"es-n03",english:"Three",translation:"Tres",phonetic:"trehs",categoryId:"numbers",languageId:"es"),
        Phrase(id:"es-n04",english:"Five",translation:"Cinco",phonetic:"SEEN-koh",categoryId:"numbers",languageId:"es"),
        Phrase(id:"es-n05",english:"Ten",translation:"Diez",phonetic:"dee-EHS",categoryId:"numbers",languageId:"es"),
        Phrase(id:"es-n06",english:"What time is it?",translation:"¿Qué hora es?",phonetic:"keh OH-rah ehs",categoryId:"numbers",languageId:"es"),
        Phrase(id:"es-n07",english:"Today",translation:"Hoy",phonetic:"oy",categoryId:"numbers",languageId:"es"),
        Phrase(id:"es-n08",english:"Tomorrow",translation:"Mañana",phonetic:"mah-NYAH-nah",categoryId:"numbers",languageId:"es"),
        Phrase(id:"es-n09",english:"Yesterday",translation:"Ayer",phonetic:"ah-YEHR",categoryId:"numbers",languageId:"es"),
        Phrase(id:"es-n10",english:"In the morning",translation:"Por la mañana",phonetic:"por lah mah-NYAH-nah",categoryId:"numbers",languageId:"es"),
        // Directions
        Phrase(id:"es-d01",english:"Where is…?",translation:"¿Dónde está…?",phonetic:"DON-deh es-TAH",categoryId:"directions",languageId:"es"),
        Phrase(id:"es-d02",english:"Turn left",translation:"Gire a la izquierda",phonetic:"HEE-reh ah lah ees-kee-EHR-dah",categoryId:"directions",languageId:"es"),
        Phrase(id:"es-d03",english:"Turn right",translation:"Gire a la derecha",phonetic:"HEE-reh ah lah deh-REH-chah",categoryId:"directions",languageId:"es"),
        Phrase(id:"es-d04",english:"Straight ahead",translation:"Todo recto",phonetic:"TOH-doh REK-toh",categoryId:"directions",languageId:"es"),
        Phrase(id:"es-d05",english:"How far is it?",translation:"¿A qué distancia está?",phonetic:"ah keh dees-TAN-see-ah es-TAH",categoryId:"directions",languageId:"es"),
        Phrase(id:"es-d06",english:"Is it far?",translation:"¿Está lejos?",phonetic:"es-TAH LEH-hos",categoryId:"directions",languageId:"es"),
        Phrase(id:"es-d07",english:"On the corner",translation:"En la esquina",phonetic:"en lah es-KEE-nah",categoryId:"directions",languageId:"es"),
        // Transport
        Phrase(id:"es-t01",english:"One ticket, please",translation:"Un billete, por favor",phonetic:"oon bee-YEH-teh por fah-VOR",categoryId:"transport",languageId:"es"),
        Phrase(id:"es-t02",english:"Where is the station?",translation:"¿Dónde está la estación?",phonetic:"DON-deh es-TAH lah es-tah-see-ON",categoryId:"transport",languageId:"es"),
        Phrase(id:"es-t03",english:"The train to…",translation:"El tren a…",phonetic:"el tren ah",categoryId:"transport",languageId:"es"),
        Phrase(id:"es-t04",english:"Taxi!",translation:"¡Taxi!",phonetic:"TAK-see",categoryId:"transport",languageId:"es"),
        Phrase(id:"es-t05",english:"Airport",translation:"Aeropuerto",phonetic:"ah-eh-roh-PWEHR-toh",categoryId:"transport",languageId:"es"),
        // Hotel
        Phrase(id:"es-h01",english:"I have a reservation",translation:"Tengo una reserva",phonetic:"TEN-goh OO-nah reh-SEHR-vah",categoryId:"hotel",languageId:"es"),
        Phrase(id:"es-h02",english:"What time is checkout?",translation:"¿A qué hora es el check-out?",phonetic:"ah keh OH-rah es el check-out",categoryId:"hotel",languageId:"es"),
        Phrase(id:"es-h03",english:"Room service",translation:"Servicio de habitación",phonetic:"sehr-VEE-see-oh deh ah-bee-tah-see-ON",categoryId:"hotel",languageId:"es"),
        Phrase(id:"es-h04",english:"Do you have Wi-Fi?",translation:"¿Tiene Wi-Fi?",phonetic:"tee-EH-neh wee-fee",categoryId:"hotel",languageId:"es"),
        Phrase(id:"es-h05",english:"The key, please",translation:"La llave, por favor",phonetic:"lah YAH-veh por fah-VOR",categoryId:"hotel",languageId:"es"),
        // Restaurant
        Phrase(id:"es-r01",english:"A table for two",translation:"Una mesa para dos",phonetic:"OO-nah MEH-sah PAH-rah dohs",categoryId:"restaurant",languageId:"es"),
        Phrase(id:"es-r02",english:"The menu, please",translation:"La carta, por favor",phonetic:"lah KAR-tah por fah-VOR",categoryId:"restaurant",languageId:"es"),
        Phrase(id:"es-r03",english:"I am vegetarian",translation:"Soy vegetariano/a",phonetic:"soy veh-heh-tah-ree-AH-noh",categoryId:"restaurant",languageId:"es"),
        Phrase(id:"es-r04",english:"The bill, please",translation:"La cuenta, por favor",phonetic:"lah KWEN-tah por fah-VOR",categoryId:"restaurant",languageId:"es"),
        Phrase(id:"es-r05",english:"Delicious!",translation:"¡Delicioso!",phonetic:"deh-lee-see-OH-soh",categoryId:"restaurant",languageId:"es"),
        Phrase(id:"es-r06",english:"Water, please",translation:"Agua, por favor",phonetic:"AH-gwah por fah-VOR",categoryId:"restaurant",languageId:"es"),
        // Shopping
        Phrase(id:"es-s01",english:"How much does it cost?",translation:"¿Cuánto cuesta?",phonetic:"KWAN-toh KWES-tah",categoryId:"shopping",languageId:"es"),
        Phrase(id:"es-s02",english:"Too expensive",translation:"Demasiado caro",phonetic:"deh-mah-see-AH-doh KAH-roh",categoryId:"shopping",languageId:"es"),
        Phrase(id:"es-s03",english:"Do you accept cards?",translation:"¿Aceptan tarjetas?",phonetic:"ah-SEP-tan tar-HEH-tas",categoryId:"shopping",languageId:"es"),
        Phrase(id:"es-s04",english:"I'll take it",translation:"Me lo llevo",phonetic:"meh loh YEH-voh",categoryId:"shopping",languageId:"es"),
        Phrase(id:"es-s05",english:"Do you have a smaller size?",translation:"¿Tiene una talla más pequeña?",phonetic:"tee-EH-neh OO-nah TAH-yah mas peh-KEHN-yah",categoryId:"shopping",languageId:"es"),
        // Emergency
        Phrase(id:"es-e01",english:"Help!",translation:"¡Socorro!",phonetic:"soh-KOR-roh",categoryId:"emergency",languageId:"es"),
        Phrase(id:"es-e02",english:"Call the police",translation:"Llame a la policía",phonetic:"YAH-meh ah lah poh-lee-SEE-ah",categoryId:"emergency",languageId:"es"),
        Phrase(id:"es-e03",english:"I need a doctor",translation:"Necesito un médico",phonetic:"neh-seh-SEE-toh oon MEH-dee-koh",categoryId:"emergency",languageId:"es"),
        Phrase(id:"es-e04",english:"Fire!",translation:"¡Fuego!",phonetic:"FWEH-goh",categoryId:"emergency",languageId:"es"),
        Phrase(id:"es-e05",english:"I've lost my passport",translation:"He perdido mi pasaporte",phonetic:"eh pehr-DEE-doh mee pah-sah-POR-teh",categoryId:"emergency",languageId:"es")
    ]

    // MARK: French

    static let frenchPhrases: [Phrase] = [
        Phrase(id:"fr-b01",english:"Hello",translation:"Bonjour",phonetic:"bon-ZHOOR",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b02",english:"Good morning",translation:"Bonjour",phonetic:"bon-ZHOOR",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b03",english:"Good evening",translation:"Bonsoir",phonetic:"bon-SWAHR",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b04",english:"Goodbye",translation:"Au revoir",phonetic:"oh reh-VWAHR",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b05",english:"Please",translation:"S'il vous plaît",phonetic:"seel voo PLEH",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b06",english:"Thank you",translation:"Merci",phonetic:"mehr-SEE",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b07",english:"You're welcome",translation:"De rien",phonetic:"deh ree-AHN",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b08",english:"Yes",translation:"Oui",phonetic:"wee",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b09",english:"No",translation:"Non",phonetic:"nohn",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b10",english:"Sorry",translation:"Pardon / Désolé",phonetic:"par-DON / deh-zoh-LEH",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b11",english:"Do you speak English?",translation:"Parlez-vous anglais?",phonetic:"par-leh-VOO ang-GLEH",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b12",english:"I don't understand",translation:"Je ne comprends pas",phonetic:"zheh neh com-PRAN pah",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b13",english:"My name is…",translation:"Je m'appelle…",phonetic:"zheh mah-PEL",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b14",english:"Can you help me?",translation:"Pouvez-vous m'aider?",phonetic:"poo-veh-VOO meh-DEH",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-b15",english:"How are you?",translation:"Comment allez-vous?",phonetic:"koh-mahn ah-leh-VOO",categoryId:"basics",languageId:"fr"),
        Phrase(id:"fr-n01",english:"One",translation:"Un / Une",phonetic:"ahn / oon",categoryId:"numbers",languageId:"fr"),
        Phrase(id:"fr-n02",english:"Two",translation:"Deux",phonetic:"duh",categoryId:"numbers",languageId:"fr"),
        Phrase(id:"fr-n03",english:"Three",translation:"Trois",phonetic:"trwah",categoryId:"numbers",languageId:"fr"),
        Phrase(id:"fr-n04",english:"Ten",translation:"Dix",phonetic:"dees",categoryId:"numbers",languageId:"fr"),
        Phrase(id:"fr-n05",english:"What time is it?",translation:"Quelle heure est-il?",phonetic:"kel ur eh-TEEL",categoryId:"numbers",languageId:"fr"),
        Phrase(id:"fr-n06",english:"Today",translation:"Aujourd'hui",phonetic:"oh-zhoor-DWEE",categoryId:"numbers",languageId:"fr"),
        Phrase(id:"fr-n07",english:"Tomorrow",translation:"Demain",phonetic:"deh-MAHN",categoryId:"numbers",languageId:"fr"),
        Phrase(id:"fr-d01",english:"Where is…?",translation:"Où est…?",phonetic:"oo eh",categoryId:"directions",languageId:"fr"),
        Phrase(id:"fr-d02",english:"Turn left",translation:"Tournez à gauche",phonetic:"toor-NEH ah GOHSH",categoryId:"directions",languageId:"fr"),
        Phrase(id:"fr-d03",english:"Turn right",translation:"Tournez à droite",phonetic:"toor-NEH ah DRWAHT",categoryId:"directions",languageId:"fr"),
        Phrase(id:"fr-d04",english:"Straight ahead",translation:"Tout droit",phonetic:"too DRWAH",categoryId:"directions",languageId:"fr"),
        Phrase(id:"fr-d05",english:"Is it far?",translation:"C'est loin?",phonetic:"seh LWAHN",categoryId:"directions",languageId:"fr"),
        Phrase(id:"fr-t01",english:"One ticket please",translation:"Un billet, s'il vous plaît",phonetic:"ahn bee-YEH seel voo PLEH",categoryId:"transport",languageId:"fr"),
        Phrase(id:"fr-t02",english:"Where is the station?",translation:"Où est la gare?",phonetic:"oo eh lah gar",categoryId:"transport",languageId:"fr"),
        Phrase(id:"fr-t03",english:"Taxi!",translation:"Taxi!",phonetic:"tak-SEE",categoryId:"transport",languageId:"fr"),
        Phrase(id:"fr-h01",english:"I have a reservation",translation:"J'ai une réservation",phonetic:"zheh oon reh-zehr-vah-SYOHN",categoryId:"hotel",languageId:"fr"),
        Phrase(id:"fr-h02",english:"The key, please",translation:"La clé, s'il vous plaît",phonetic:"lah kleh seel voo PLEH",categoryId:"hotel",languageId:"fr"),
        Phrase(id:"fr-h03",english:"Do you have Wi-Fi?",translation:"Avez-vous le Wi-Fi?",phonetic:"ah-veh-VOO leh wee-fee",categoryId:"hotel",languageId:"fr"),
        Phrase(id:"fr-r01",english:"A table for two",translation:"Une table pour deux",phonetic:"oon TAH-bleh poor duh",categoryId:"restaurant",languageId:"fr"),
        Phrase(id:"fr-r02",english:"The menu, please",translation:"La carte, s'il vous plaît",phonetic:"lah kart seel voo PLEH",categoryId:"restaurant",languageId:"fr"),
        Phrase(id:"fr-r03",english:"The bill, please",translation:"L'addition, s'il vous plaît",phonetic:"lah-dee-SYOHN seel voo PLEH",categoryId:"restaurant",languageId:"fr"),
        Phrase(id:"fr-r04",english:"Delicious!",translation:"Délicieux!",phonetic:"deh-lee-SYUH",categoryId:"restaurant",languageId:"fr"),
        Phrase(id:"fr-s01",english:"How much?",translation:"Combien ça coûte?",phonetic:"com-BYAHN sah koot",categoryId:"shopping",languageId:"fr"),
        Phrase(id:"fr-s02",english:"Too expensive",translation:"Trop cher",phonetic:"troh shehr",categoryId:"shopping",languageId:"fr"),
        Phrase(id:"fr-s03",english:"Do you accept cards?",translation:"Acceptez-vous les cartes?",phonetic:"ak-sep-TEH-voo leh kart",categoryId:"shopping",languageId:"fr"),
        Phrase(id:"fr-e01",english:"Help!",translation:"Au secours!",phonetic:"oh seh-KOOR",categoryId:"emergency",languageId:"fr"),
        Phrase(id:"fr-e02",english:"Call the police",translation:"Appelez la police",phonetic:"ah-peh-LEH lah poh-LEES",categoryId:"emergency",languageId:"fr"),
        Phrase(id:"fr-e03",english:"I need a doctor",translation:"J'ai besoin d'un médecin",phonetic:"zheh beh-ZWAHN duhn meh-DSAN",categoryId:"emergency",languageId:"fr"),
        Phrase(id:"fr-e04",english:"I've lost my passport",translation:"J'ai perdu mon passeport",phonetic:"zheh pehr-DOO mohn pahs-POR",categoryId:"emergency",languageId:"fr")
    ]

    // MARK: Italian

    static let italianPhrases: [Phrase] = [
        Phrase(id:"it-b01",english:"Hello",translation:"Ciao / Buongiorno",phonetic:"CHOW / bwon-JOR-no",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-b02",english:"Good evening",translation:"Buonasera",phonetic:"bwo-nah-SEH-rah",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-b03",english:"Goodbye",translation:"Arrivederci",phonetic:"ah-ree-veh-DEHR-chee",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-b04",english:"Please",translation:"Per favore",phonetic:"pehr fah-VOH-reh",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-b05",english:"Thank you",translation:"Grazie",phonetic:"GRAH-tsyeh",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-b06",english:"Yes / No",translation:"Sì / No",phonetic:"see / noh",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-b07",english:"Do you speak English?",translation:"Parla inglese?",phonetic:"PAR-lah een-GLEH-zeh",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-b08",english:"I don't understand",translation:"Non capisco",phonetic:"non kah-PEE-skoh",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-b09",english:"Sorry",translation:"Mi dispiace / Scusi",phonetic:"mee dees-PYAH-cheh / SKOO-zee",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-b10",english:"My name is…",translation:"Mi chiamo…",phonetic:"mee KYAH-moh",categoryId:"basics",languageId:"it"),
        Phrase(id:"it-d01",english:"Where is…?",translation:"Dov'è…?",phonetic:"doh-VEH",categoryId:"directions",languageId:"it"),
        Phrase(id:"it-d02",english:"Turn left / right",translation:"Girare a sinistra / destra",phonetic:"jee-RAH-reh ah see-NEES-trah / DES-trah",categoryId:"directions",languageId:"it"),
        Phrase(id:"it-d03",english:"Straight ahead",translation:"Dritto",phonetic:"DREET-toh",categoryId:"directions",languageId:"it"),
        Phrase(id:"it-t01",english:"One ticket",translation:"Un biglietto",phonetic:"oon beel-YET-toh",categoryId:"transport",languageId:"it"),
        Phrase(id:"it-t02",english:"Where is the station?",translation:"Dov'è la stazione?",phonetic:"doh-VEH lah stah-TSYOH-neh",categoryId:"transport",languageId:"it"),
        Phrase(id:"it-h01",english:"I have a reservation",translation:"Ho una prenotazione",phonetic:"oh OO-nah preh-noh-tah-TSYOH-neh",categoryId:"hotel",languageId:"it"),
        Phrase(id:"it-h02",english:"The key, please",translation:"La chiave, per favore",phonetic:"lah KYAH-veh pehr fah-VOH-reh",categoryId:"hotel",languageId:"it"),
        Phrase(id:"it-r01",english:"A table for two",translation:"Un tavolo per due",phonetic:"oon TAH-voh-loh pehr DOO-eh",categoryId:"restaurant",languageId:"it"),
        Phrase(id:"it-r02",english:"The bill, please",translation:"Il conto, per favore",phonetic:"eel KON-toh pehr fah-VOH-reh",categoryId:"restaurant",languageId:"it"),
        Phrase(id:"it-r03",english:"Delicious!",translation:"Delizioso!",phonetic:"deh-lee-TSYOH-zoh",categoryId:"restaurant",languageId:"it"),
        Phrase(id:"it-s01",english:"How much?",translation:"Quanto costa?",phonetic:"KWAN-toh KOS-tah",categoryId:"shopping",languageId:"it"),
        Phrase(id:"it-s02",english:"Do you accept cards?",translation:"Accettate le carte?",phonetic:"ah-chet-TAH-teh leh KAR-teh",categoryId:"shopping",languageId:"it"),
        Phrase(id:"it-e01",english:"Help!",translation:"Aiuto!",phonetic:"ah-YOO-toh",categoryId:"emergency",languageId:"it"),
        Phrase(id:"it-e02",english:"Call the police",translation:"Chiamate la polizia",phonetic:"kyah-MAH-teh lah poh-lee-TSEE-ah",categoryId:"emergency",languageId:"it"),
        Phrase(id:"it-e03",english:"I need a doctor",translation:"Ho bisogno di un medico",phonetic:"oh bee-ZOH-nyoh dee oon MEH-dee-koh",categoryId:"emergency",languageId:"it"),
        Phrase(id:"it-n01",english:"What time is it?",translation:"Che ora è?",phonetic:"keh OH-rah EH",categoryId:"numbers",languageId:"it"),
        Phrase(id:"it-n02",english:"Today / Tomorrow",translation:"Oggi / Domani",phonetic:"OH-jee / doh-MAH-nee",categoryId:"numbers",languageId:"it")
    ]

    // MARK: German

    static let germanPhrases: [Phrase] = [
        Phrase(id:"de-b01",english:"Hello",translation:"Hallo / Guten Tag",phonetic:"HAH-loh / GOO-ten tahk",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-b02",english:"Good morning",translation:"Guten Morgen",phonetic:"GOO-ten MOR-gen",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-b03",english:"Goodbye",translation:"Auf Wiedersehen / Tschüss",phonetic:"owf VEE-der-zeh-en / choos",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-b04",english:"Please",translation:"Bitte",phonetic:"BIT-teh",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-b05",english:"Thank you",translation:"Danke",phonetic:"DAHN-keh",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-b06",english:"Yes / No",translation:"Ja / Nein",phonetic:"yah / nyne",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-b07",english:"Do you speak English?",translation:"Sprechen Sie Englisch?",phonetic:"SHPREH-khen zee ENG-lish",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-b08",english:"I don't understand",translation:"Ich verstehe nicht",phonetic:"ikh fehr-SHTEH-eh nicht",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-b09",english:"Sorry",translation:"Entschuldigung",phonetic:"ent-SHOOL-dee-goong",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-b10",english:"My name is…",translation:"Ich heiße…",phonetic:"ikh HY-seh",categoryId:"basics",languageId:"de"),
        Phrase(id:"de-d01",english:"Where is…?",translation:"Wo ist…?",phonetic:"voh ist",categoryId:"directions",languageId:"de"),
        Phrase(id:"de-d02",english:"Turn left / right",translation:"Links / Rechts abbiegen",phonetic:"links / rechts AB-bee-gen",categoryId:"directions",languageId:"de"),
        Phrase(id:"de-d03",english:"Straight ahead",translation:"Geradeaus",phonetic:"geh-RAH-deh-ows",categoryId:"directions",languageId:"de"),
        Phrase(id:"de-t01",english:"One ticket",translation:"Eine Fahrkarte",phonetic:"EYE-neh FAHR-kar-teh",categoryId:"transport",languageId:"de"),
        Phrase(id:"de-t02",english:"Where is the train station?",translation:"Wo ist der Bahnhof?",phonetic:"voh ist dehr BAHN-hof",categoryId:"transport",languageId:"de"),
        Phrase(id:"de-h01",english:"I have a reservation",translation:"Ich habe eine Reservierung",phonetic:"ikh HAH-beh EYE-neh reh-zehr-VEE-roong",categoryId:"hotel",languageId:"de"),
        Phrase(id:"de-h02",english:"The key, please",translation:"Den Schlüssel, bitte",phonetic:"dehn SHLOOS-el BIT-teh",categoryId:"hotel",languageId:"de"),
        Phrase(id:"de-r01",english:"A table for two",translation:"Einen Tisch für zwei",phonetic:"EYE-nen tish voor tsvy",categoryId:"restaurant",languageId:"de"),
        Phrase(id:"de-r02",english:"The bill, please",translation:"Die Rechnung, bitte",phonetic:"dee REKH-noong BIT-teh",categoryId:"restaurant",languageId:"de"),
        Phrase(id:"de-s01",english:"How much?",translation:"Wie viel kostet das?",phonetic:"vee feel KOS-tet das",categoryId:"shopping",languageId:"de"),
        Phrase(id:"de-s02",english:"Do you accept cards?",translation:"Nehmen Sie Karten?",phonetic:"NEH-men zee KAR-ten",categoryId:"shopping",languageId:"de"),
        Phrase(id:"de-e01",english:"Help!",translation:"Hilfe!",phonetic:"HIL-feh",categoryId:"emergency",languageId:"de"),
        Phrase(id:"de-e02",english:"Call the police",translation:"Rufen Sie die Polizei",phonetic:"ROO-fen zee dee poh-lee-TSYE",categoryId:"emergency",languageId:"de"),
        Phrase(id:"de-e03",english:"I need a doctor",translation:"Ich brauche einen Arzt",phonetic:"ikh BROW-kheh EYE-nen artst",categoryId:"emergency",languageId:"de"),
        Phrase(id:"de-n01",english:"What time is it?",translation:"Wie spät ist es?",phonetic:"vee shpeht ist es",categoryId:"numbers",languageId:"de"),
        Phrase(id:"de-n02",english:"Today / Tomorrow",translation:"Heute / Morgen",phonetic:"HOY-teh / MOR-gen",categoryId:"numbers",languageId:"de")
    ]

    // MARK: Japanese

    static let japanesePhrases: [Phrase] = [
        Phrase(id:"ja-b01",english:"Hello",translation:"こんにちは",phonetic:"Kon-ni-chi-wa",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-b02",english:"Good morning",translation:"おはようございます",phonetic:"O-ha-yo go-za-i-mas",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-b03",english:"Good evening",translation:"こんばんは",phonetic:"Kom-ban-wa",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-b04",english:"Goodbye",translation:"さようなら",phonetic:"Sa-yo-na-ra",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-b05",english:"Please (request)",translation:"お願いします",phonetic:"O-ne-gai shi-mas",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-b06",english:"Thank you",translation:"ありがとうございます",phonetic:"A-ri-ga-to go-za-i-mas",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-b07",english:"Yes / No",translation:"はい / いいえ",phonetic:"Hai / I-ie",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-b08",english:"Sorry / Excuse me",translation:"すみません",phonetic:"Su-mi-ma-sen",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-b09",english:"I don't understand",translation:"わかりません",phonetic:"Wa-ka-ri-ma-sen",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-b10",english:"Do you speak English?",translation:"英語が話せますか？",phonetic:"Ei-go ga ha-na-se-mas-ka",categoryId:"basics",languageId:"ja"),
        Phrase(id:"ja-d01",english:"Where is…?",translation:"…はどこですか？",phonetic:"… wa do-ko des-ka",categoryId:"directions",languageId:"ja"),
        Phrase(id:"ja-d02",english:"Turn left",translation:"左に曲がってください",phonetic:"Hi-da-ri ni ma-gat-te ku-da-sai",categoryId:"directions",languageId:"ja"),
        Phrase(id:"ja-d03",english:"Turn right",translation:"右に曲がってください",phonetic:"Mi-gi ni ma-gat-te ku-da-sai",categoryId:"directions",languageId:"ja"),
        Phrase(id:"ja-d04",english:"Straight ahead",translation:"まっすぐ",phonetic:"Mas-su-gu",categoryId:"directions",languageId:"ja"),
        Phrase(id:"ja-t01",english:"One ticket please",translation:"きっぷを一枚ください",phonetic:"Kip-pu o i-chi-mai ku-da-sai",categoryId:"transport",languageId:"ja"),
        Phrase(id:"ja-t02",english:"Where is the station?",translation:"駅はどこですか？",phonetic:"E-ki wa do-ko des-ka",categoryId:"transport",languageId:"ja"),
        Phrase(id:"ja-r01",english:"Two people",translation:"二人です",phonetic:"Fu-ta-ri des",categoryId:"restaurant",languageId:"ja"),
        Phrase(id:"ja-r02",english:"The bill, please",translation:"お会計をお願いします",phonetic:"O-kai-kei o o-ne-gai shi-mas",categoryId:"restaurant",languageId:"ja"),
        Phrase(id:"ja-r03",english:"Delicious!",translation:"おいしい！",phonetic:"O-i-shii",categoryId:"restaurant",languageId:"ja"),
        Phrase(id:"ja-h01",english:"I have a reservation",translation:"予約しています",phonetic:"Yo-ya-ku shi-te i-mas",categoryId:"hotel",languageId:"ja"),
        Phrase(id:"ja-s01",english:"How much?",translation:"いくらですか？",phonetic:"I-ku-ra des-ka",categoryId:"shopping",languageId:"ja"),
        Phrase(id:"ja-s02",english:"Do you accept cards?",translation:"クレジットカードは使えますか？",phonetic:"Ku-re-jit-to-ka-do wa tsu-ka-e-mas-ka",categoryId:"shopping",languageId:"ja"),
        Phrase(id:"ja-e01",english:"Help!",translation:"助けて！",phonetic:"Ta-su-ke-te",categoryId:"emergency",languageId:"ja"),
        Phrase(id:"ja-e02",english:"Call the police",translation:"警察を呼んでください",phonetic:"Kei-sa-tsu o yon-de ku-da-sai",categoryId:"emergency",languageId:"ja"),
        Phrase(id:"ja-n01",english:"What time is it?",translation:"今何時ですか？",phonetic:"I-ma nan-ji des-ka",categoryId:"numbers",languageId:"ja"),
        Phrase(id:"ja-n02",english:"Today / Tomorrow",translation:"今日 / 明日",phonetic:"Kyo / A-shi-ta",categoryId:"numbers",languageId:"ja")
    ]

    // MARK: Portuguese

    static let portuguesePhrases: [Phrase] = [
        Phrase(id:"pt-b01",english:"Hello",translation:"Olá",phonetic:"oh-LAH",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-b02",english:"Good morning",translation:"Bom dia",phonetic:"bom JEE-ah",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-b03",english:"Goodbye",translation:"Tchau / Adeus",phonetic:"chow / ah-DEH-oos",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-b04",english:"Please",translation:"Por favor",phonetic:"por fah-VOR",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-b05",english:"Thank you",translation:"Obrigado/a",phonetic:"oh-bree-GAH-doh",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-b06",english:"Yes / No",translation:"Sim / Não",phonetic:"seen / now",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-b07",english:"Do you speak English?",translation:"Você fala inglês?",phonetic:"voh-SEH FAH-lah een-GLESH",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-b08",english:"I don't understand",translation:"Não entendo",phonetic:"now en-TEN-doh",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-b09",english:"Sorry",translation:"Desculpe",phonetic:"desh-KOOL-peh",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-b10",english:"My name is…",translation:"Meu nome é…",phonetic:"MEH-oo NOH-meh eh",categoryId:"basics",languageId:"pt"),
        Phrase(id:"pt-d01",english:"Where is…?",translation:"Onde fica…?",phonetic:"ON-jee FEE-kah",categoryId:"directions",languageId:"pt"),
        Phrase(id:"pt-d02",english:"Turn left / right",translation:"Vire à esquerda / direita",phonetic:"VEE-reh ah esh-KEHR-dah / dee-REI-tah",categoryId:"directions",languageId:"pt"),
        Phrase(id:"pt-t01",english:"One ticket",translation:"Uma passagem",phonetic:"OO-mah pah-SAH-zhehn",categoryId:"transport",languageId:"pt"),
        Phrase(id:"pt-t02",english:"Where is the station?",translation:"Onde fica a estação?",phonetic:"ON-jee FEE-kah ah es-tah-SOW",categoryId:"transport",languageId:"pt"),
        Phrase(id:"pt-r01",english:"A table for two",translation:"Uma mesa para dois",phonetic:"OO-mah MEH-zah PAH-rah doysh",categoryId:"restaurant",languageId:"pt"),
        Phrase(id:"pt-r02",english:"The bill, please",translation:"A conta, por favor",phonetic:"ah KON-tah por fah-VOR",categoryId:"restaurant",languageId:"pt"),
        Phrase(id:"pt-r03",english:"Delicious!",translation:"Delicioso!",phonetic:"deh-lee-SYOH-zoo",categoryId:"restaurant",languageId:"pt"),
        Phrase(id:"pt-h01",english:"I have a reservation",translation:"Tenho uma reserva",phonetic:"TEN-yoh OO-mah reh-ZEHR-vah",categoryId:"hotel",languageId:"pt"),
        Phrase(id:"pt-s01",english:"How much?",translation:"Quanto custa?",phonetic:"KWAN-toh KOOS-tah",categoryId:"shopping",languageId:"pt"),
        Phrase(id:"pt-s02",english:"Do you accept cards?",translation:"Aceitam cartão?",phonetic:"ah-SAY-tahm kar-TOW",categoryId:"shopping",languageId:"pt"),
        Phrase(id:"pt-e01",english:"Help!",translation:"Socorro!",phonetic:"soh-KOR-roh",categoryId:"emergency",languageId:"pt"),
        Phrase(id:"pt-e02",english:"Call the police",translation:"Chame a polícia",phonetic:"SHA-meh ah poh-LEE-see-ah",categoryId:"emergency",languageId:"pt"),
        Phrase(id:"pt-e03",english:"I need a doctor",translation:"Preciso de um médico",phonetic:"preh-SEE-zoo dee oom MEH-dee-koo",categoryId:"emergency",languageId:"pt"),
        Phrase(id:"pt-n01",english:"What time is it?",translation:"Que horas são?",phonetic:"keh OH-ras sow",categoryId:"numbers",languageId:"pt"),
        Phrase(id:"pt-n02",english:"Today / Tomorrow",translation:"Hoje / Amanhã",phonetic:"OH-zheh / ah-mah-NYAH",categoryId:"numbers",languageId:"pt")
    ]

    static func phrases(for languageId: String, categoryId: String? = nil) -> [Phrase] {
        let filtered = all.filter { $0.languageId == languageId }
        if let cat = categoryId {
            return filtered.filter { $0.categoryId == cat }
        }
        return filtered
    }
}
