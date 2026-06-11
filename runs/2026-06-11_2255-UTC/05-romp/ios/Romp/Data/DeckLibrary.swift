import Foundation

/// Eight built-in decks, ~45 entries each, family-friendly.
enum DeckLibrary {
    static let decks: [PlayableDeck] = [
        PlayableDeck(
            id: "animals", name: "Animal Kingdom", emoji: "🦁",
            blurb: "Roar, waddle and flap — act the beast.",
            words: [
                "Elephant", "Penguin", "Kangaroo", "Octopus", "Giraffe", "T-Rex", "Sloth",
                "Flamingo", "Gorilla", "Crocodile", "Hummingbird", "Jellyfish", "Meerkat",
                "Peacock", "Hedgehog", "Walrus", "Chameleon", "Owl", "Lobster", "Llama",
                "Bat", "Beaver", "Cobra", "Dolphin", "Eagle", "Ferret", "Goat", "Hyena",
                "Iguana", "Koala", "Lemur", "Moose", "Narwhal", "Ostrich", "Panda",
                "Raccoon", "Seahorse", "Tarantula", "Vulture", "Woodpecker", "Yak",
                "Zebra", "Platypus", "Armadillo", "Mosquito",
            ],
            isCustom: false
        ),
        PlayableDeck(
            id: "actions", name: "Act It Out", emoji: "🎭",
            blurb: "Classic charades — no words allowed, ever.",
            words: [
                "Brushing your teeth", "Parallel parking", "Walking a huge dog",
                "Making pizza dough", "Tightrope walking", "Changing a diaper",
                "Shoveling snow", "Milking a cow", "Conducting an orchestra",
                "Doing the moonwalk", "Untangling headphones", "Building a sandcastle",
                "Riding a mechanical bull", "Catching a fish", "Blowing out candles",
                "Wrapping a gift", "Mowing the lawn", "Juggling", "Arm wrestling",
                "Ice skating", "Taking a selfie", "Painting a fence", "Karate chop",
                "Slipping on a banana peel", "Climbing a ladder", "Rowing a boat",
                "Playing air guitar", "Making a snow angel", "Defusing a bomb",
                "Walking against the wind", "Threading a needle", "Churning butter",
                "Stomping grapes", "Swatting a fly", "Putting up a tent",
                "Carrying hot soup", "Losing your keys", "Waiting in line",
                "Getting a flu shot", "Assembling flat-pack furniture",
                "Stepping on a LEGO", "Hailing a taxi", "Hula hooping",
                "Pulling a sword from a stone", "Robot dancing",
            ],
            isCustom: false
        ),
        PlayableDeck(
            id: "movies", name: "Movie Night", emoji: "🎬",
            blurb: "Describe the film without saying the title.",
            words: [
                "Jaws", "Titanic", "The Lion King", "Jurassic Park", "Frozen",
                "Star Wars", "The Wizard of Oz", "Finding Nemo", "Back to the Future",
                "Home Alone", "E.T.", "Ghostbusters", "The Matrix", "Shrek",
                "Pirates of the Caribbean", "Toy Story", "King Kong", "Rocky",
                "Indiana Jones", "Harry Potter", "The Godfather", "Forrest Gump",
                "Avatar", "Up", "Ratatouille", "The Incredibles", "Mary Poppins",
                "Grease", "The Sound of Music", "Jumanji", "Men in Black",
                "Mission Impossible", "The Hunger Games", "Spider-Man", "Batman",
                "Superman", "Aladdin", "Beauty and the Beast", "Cinderella",
                "The Avengers", "Godzilla", "Karate Kid", "Top Gun", "Encanto", "Moana",
            ],
            isCustom: false
        ),
        PlayableDeck(
            id: "characters", name: "Icons & Characters", emoji: "🦸",
            blurb: "Heroes, villains and legends — become them.",
            words: [
                "Sherlock Holmes", "Darth Vader", "Mickey Mouse", "Santa Claus",
                "Dracula", "Robin Hood", "Cleopatra", "Albert Einstein", "Tarzan",
                "Peter Pan", "Hercules", "Medusa", "Zorro", "James Bond",
                "Willy Wonka", "Mary Poppins", "Frankenstein's monster", "Bigfoot",
                "The Tooth Fairy", "Cupid", "King Arthur", "Pinocchio", "Godzilla",
                "SpongeBob", "Homer Simpson", "Yoda", "Gandalf", "Harry Potter",
                "Katniss Everdeen", "Wonder Woman", "Batman", "The Joker",
                "Captain Hook", "Genie", "Elsa", "Buzz Lightyear", "Shrek",
                "Napoleon", "Julius Caesar", "Mozart", "Shakespeare",
                "Leonardo da Vinci", "Neil Armstrong", "Houdini", "Pikachu",
            ],
            isCustom: false
        ),
        PlayableDeck(
            id: "food", name: "Snack Attack", emoji: "🌮",
            blurb: "Edible, describable, occasionally messy.",
            words: [
                "Spaghetti", "Tacos", "Sushi", "Pancakes", "Popcorn", "Guacamole",
                "Croissant", "Ramen", "Cheeseburger", "Burrito", "Waffles",
                "Mac and cheese", "Hot dog", "Donut", "Pretzel", "Nachos",
                "Ice cream sundae", "Cotton candy", "Garlic bread", "Dumplings",
                "Pad Thai", "Fish and chips", "Corn on the cob", "Deviled eggs",
                "Onion rings", "Milkshake", "Churros", "Lasagna", "Meatballs",
                "Fortune cookie", "Bubble tea", "Avocado toast", "Caesar salad",
                "Banana split", "Apple pie", "Brownies", "Marshmallows",
                "Peanut butter", "Pickles", "Sourdough bread", "Tiramisu",
                "Quesadilla", "Falafel", "Croutons", "Maple syrup",
            ],
            isCustom: false
        ),
        PlayableDeck(
            id: "sports", name: "Game On", emoji: "🏈",
            blurb: "Sports, moves and athlete energy.",
            words: [
                "Slam dunk", "Touchdown dance", "Penalty kick", "Home run",
                "Figure skating", "Synchronized swimming", "Curling", "Javelin throw",
                "Pole vault", "Sumo wrestling", "Fencing", "Archery", "Bowling strike",
                "Golf swing", "Tennis serve", "Skateboarding", "Snowboarding",
                "Surfing", "Rock climbing", "Marathon", "Hurdles", "Shot put",
                "Gymnastics", "Weightlifting", "Boxing", "Karate", "Judo",
                "Free throw", "Bicycle kick", "Goalkeeper save", "Cannonball dive",
                "Backstroke", "Dodgeball", "Tug of war", "Limbo", "Darts",
                "Ping pong", "Badminton", "Volleyball spike", "Cheerleading",
                "Referee's whistle", "Victory lap", "Photo finish", "Hat trick",
            ],
            isCustom: false
        ),
        PlayableDeck(
            id: "jobs", name: "On the Job", emoji: "👩‍🚒",
            blurb: "Occupations — mime the 9 to 5.",
            words: [
                "Firefighter", "Dentist", "Barista", "Air traffic controller",
                "Lifeguard", "Magician", "Auctioneer", "Mail carrier", "Plumber",
                "Hairdresser", "Surgeon", "Chef", "Orchestra conductor", "Mime",
                "News anchor", "Weather forecaster", "Astronaut", "Archaeologist",
                "Librarian", "Bus driver", "Flight attendant", "Photographer",
                "Carpenter", "Electrician", "Farmer", "Fisherman", "Judge",
                "Lawyer", "Detective", "Spy", "Zookeeper", "Veterinarian",
                "Teacher", "Principal", "Coach", "Personal trainer", "DJ",
                "Opera singer", "Ballet dancer", "Stunt double", "Clown",
                "Tattoo artist", "Tour guide", "Translator", "Beekeeper",
            ],
            isCustom: false
        ),
        PlayableDeck(
            id: "throwback", name: "Throwback", emoji: "📼",
            blurb: "Retro tech and pre-smartphone life.",
            words: [
                "Rotary phone", "Cassette tape", "VHS rewinder", "Floppy disk",
                "Dial-up internet", "Pager", "Walkman", "Boombox", "Typewriter",
                "Polaroid camera", "Record player", "8-track", "Phone booth",
                "Paper map", "Encyclopedia", "Card catalog", "Slide projector",
                "Overhead projector", "Fax machine", "Answering machine",
                "Disposable camera", "Film roll", "TV antenna", "Channel knob",
                "Game cartridge", "Arcade machine", "Pinball", "Jukebox",
                "Roller rink", "Drive-in movie", "Milkman", "Paperboy",
                "Mixtape", "CD burner", "MP3 player", "Flip phone", "T9 texting",
                "Dial tone", "Busy signal", "Collect call", "Phone book",
                "Library card", "Blockbuster night", "Tamagotchi", "Beeper",
            ],
            isCustom: false
        ),
    ]
}
