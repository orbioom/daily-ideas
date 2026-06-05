# Lexical Distance Map

An interactive force-positioned map of 38 world languages, clustered by linguistic family and distance.

## The Idea

Which languages are closest to each other? If you speak English and want to learn a new language,
which is the shortest path? Linguists measure this with lexicostatistics — comparing core vocabulary
lists across languages to calculate genetic distance.

This map plots 38 languages in 2D space based on their approximate linguistic distances, colored by
family. Germanic languages cluster together; Romance languages form their own group; Uralic languages
(Finnish, Hungarian, Estonian) float alone, unrelated to their geographic neighbors.

## How to Run

Open `index.html` in any browser. No install required.

- **Hover** any language node to see name, family, speaker count, and an interesting linguistic note
- **Drag** nodes to rearrange the map
- **Filter** by family using the chips in the top bar

## Families Included

| Family | Languages |
|--------|-----------|
| Germanic | English, German, Dutch, Swedish, Norwegian, Danish, Afrikaans |
| Romance | French, Spanish, Portuguese, Italian, Romanian, Catalan |
| Slavic | Russian, Ukrainian, Polish, Czech, Croatian |
| Celtic | Irish, Welsh |
| Hellenic | Greek |
| Semitic | Arabic, Hebrew |
| Iranic/Indo-Iranian | Persian, Hindi, Urdu |
| Baltic | Lithuanian, Latvian |
| Uralic | Finnish, Hungarian, Estonian |
| Turkic | Turkish |
| Sino-Tibetan | Mandarin |
| Japonic/Koreanic | Japanese, Korean |

## Why It's Interesting

Most language-learning apps rank languages by difficulty. This shows *structure*: the genealogical
tree that explains why English learners find Dutch easy and Turkish hard; why Spanish and Italian are
mutually partially intelligible; why Finnish is an island in Northern Europe.

The map is also a reminder that language families are real biological-style genealogies — languages
evolve, split, migrate, and influence each other.

## Data Notes

Node positions are hand-placed based on linguistic distance research (ASJP lexicostatistics, Ethnologue
genetic classifications) and adjusted for visual clarity. Not a precise metric embedding — a
communicative approximation for exploration and learning.

## V2 Ideas

- Load actual ASJP pairwise distance matrix and use t-SNE or UMAP for automatic positioning
- Add a "path" tool: highlight the genealogical path between any two languages
- Show mutual intelligibility scores between nearby languages
- Animate historically: show how the family tree branched over time

## Orbioom Feeling

Mist gradient background. Nodes use the dark text color palette per family with soft glow halos.
Glass panels for the info card and legend. Filter chips in the top raised-glass bar. The map itself
is calm and inspectable — no animation loops, no constant motion. Draggable to encourage exploration.
