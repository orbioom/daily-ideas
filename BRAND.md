# Orbioom Brand Assets and Design System

Universal developer handoff guide for Orbioom across websites, web apps, iOS apps, terminal tools, documents, and future product surfaces.

## Brand mission

Orbioom builds technology that feels like part of the human body and mind: a second brain, a third eye, a third hand. A user should not feel they are learning a machine. The product should feel like an extension of how they already think, see, write, learn, build, and play.

## 1. Brand Idea

Orbioom is a small software studio building calm, considered products for learning, writing, play, and thinking. The brand should feel quiet, intelligent, dimensional, and deeply crafted. The current website phrase is "Conjured, not just coded"; treat it as a core signal of the studio's taste: software is engineered, but the final feeling should carry atmosphere, mystery, and patience.

The product experience should feel like a place a person can step into. It should not feel like a tool that asks for constant explanation, onboarding, or technical literacy. The interface should reveal itself naturally through shape, motion, hierarchy, and familiar controls.

### Core Principles
- **Human extension first**: design every interaction as if it is augmenting thought, sight, memory, hand movement, or creative flow.
- **Calm by default**: quiet surfaces, generous spacing, one focal idea per screen, no visual noise unless earned.
- **Conjured, not just coded**: every detail intentionally shaped, not assembled from defaults.
- **One language, many worlds**: each product can have its own purpose, but the shared system of glass, ink, orb geometry, and motion must make it feel part of Orbioom.
- **Built to be lived in**: optimize for the hundredth session, not only the first impression.

## 2. Visual Identity

### Color System
Palette is mostly mist, glass, dark ink, and silver light. Green is a special accent, not a constant theme. Use it for live state, signal, magic, or controlled spark.

| Role | Token / Value | Usage |
|---|---|---|
| Page mist | #EDEEF3 / #E7E9F0 / #ECEEF2 | Fixed body background gradient and large calm surfaces. |
| Primary text | #1B1D2A | Headings, important labels, primary product names. |
| Secondary text | #565A70 | Paragraphs, supporting copy, interface descriptions. |
| Tertiary text | #8B8FA3 | Eyebrows, metadata, inactive details. |
| Ink / primary action | #23262F with #3A3E4C gradient top | Primary buttons, selected states, deep UI surfaces. |
| Glass fill | rgba(255,255,255,0.42) | Default liquid glass panels and secondary buttons. |
| Raised glass | rgba(255,255,255,0.78) | Scrolled nav, stronger cards, active panels. |
| Glass border | rgba(255,255,255,0.70–0.95) | Panel edges, chip borders, light bevels. |
| Live green | #86C79A | Status dots and subtle live indicators. |
| Racing green | #5EF0B0 / #AEFFD8 | Animated accent on the racer chip and optional highlight moments. |

### Typography
| Role | Font | Guideline |
|---|---|---|
| Primary UI and marketing | Manrope | Headings, body, buttons, labels, product cards. Letter spacing 0 except eyebrows. |
| Monospace details | JetBrains Mono | Eyebrows, code-like labels, command lines, terminal cues, compact metadata. |

## 3. Liquid Glass System

Liquid Glass is the main surface language. Translucent material over mist and light, with enough blur and border definition to stay readable. Avoid heavy frosted-glass gimmicks; quiet, tactile, premium.

| Class / Role | Token | Notes |
|---|---|---|
| .glass | fill 0.42 white, blur 22px, saturate 180% | Default panels, nav, cards, chips, secondary buttons. |
| .glass-raised | fill 0.78 white, blur 30px | Surfaces needing more presence (nav after scroll). |
| Border | 1px solid rgba(255,255,255,0.70–0.95) | Edges feel illuminated, not gray-outlined. |
| Inner highlight | inset 0 1px 0 rgba(255,255,255,0.6–0.7) | Gives the panel a real top edge. |
| Shadow | rgba(40,44,80,0.14–0.18) | Use sparingly; UI should not feel heavy. |

## 4. Orb, Portal, and Motion Language

The orb is the central visual metaphor: a compact world, an assistant presence, a product in orbit. Silver radial gradients, internal shadows, soft rings, particles, slow breathing motion.

- Use radial light, not flat circles. White highlight, silver midtones, deep gray lower volume.
- Rings and particles subtle. Suggest intelligence and orbit without sci-fi vibe.
- Motion: slow and purposeful — breathing, drifting, floating, racing accents. Avoid frantic animation.
- Portal scene: dark stage, grid floor, scrim, floating product orbs. Immersive and inspectable.

### Green Racing Accent
The "Conjured, not just coded" chip has a green conic-gradient racing border: transparent most of the loop, then emerald light, #5EF0B0, and #AEFFD8. Optional accent for moments of magic, live energy, completion, or premium interaction. Do not spread it everywhere.

## 5. Component Rules

| Component | Pattern | Rule |
|---|---|---|
| Navigation | Fixed pill glass nav with logo, links, dark CTA | Calm, compact, readable over mist. |
| Primary buttons | Dark ink gradient, white text, 12px radius, subtle lift | One main action per section. Hover lifts ~1px. |
| Secondary buttons | Glass fill, white border, ink text | Support without competing with primary. |
| Chips | Pill glass labels with small type | Phrases, states, metadata. Racer chip is special. |
| Cards | Glass panels with internal preview area | Show product character visually, not only text. |
| Status dots | Small live dot #86C79A with soft glow | Live/new/ready status. Keep text nearby for a11y. |
| Product previews | Mini worlds (AI orb, learning roadmap, doc lines, game cards) | Each product has its own motif; shared material system. |

## 6. Development Standards

- Use CSS variables for brand colors, glass fills, blur, easing, text colors, max width.
- Keep React declarative and data-driven (arrays for products, values, highlights).
- Reusable primitives: Nav, Footer, ProductHero, ProductPreview, FeatureRows, CTASection, PortalOrb.
- Stable dimensions for orbs, cards, previews, controls — hover/dynamic text must not shift layout.
- Every visual detail needs a reason: hierarchy, affordance, state, brand feeling, comprehension.
- Responsive layouts preserve first-screen brand signal: Orbioom visible through logo, orb, glass, product-world imagery.
- Motion respects reduced-motion; never blocks reading or interaction.

## 7. Universal Platform Translation

| Surface | Translation |
|---|---|
| Websites & landing | Mist BG, Liquid Glass panels, orb/product imagery, restrained motion, clear first-screen signal. |
| Web apps | Denser layouts, calm hierarchy, glass workspace regions, ink CTAs, readable controls, stable dimensions. |
| iOS apps | Translate Liquid Glass into native materials, translucency, depth, haptics, spatial hierarchy. Respect Apple conventions first. |
| Terminal / CLI | Calm command language, clear status, concise prompts, monospace rhythm, subtle green for live/success, no noisy banners. |
| Desktop | Persistent livable workspaces, quiet panels, strong keyboard ergonomics, restrained animation. |
| Documents / decks | Orbioom language, ink hierarchy, mist/glass light fills, restrained green callouts, practical checklists. |
| APIs / dev tools | Guided human setup. Errors explain next action, don't expose raw complexity unless asked. |

## 8. Implementation Tokens

```
--glass: rgba(255, 255, 255, 0.42)
--glass-2: rgba(255, 255, 255, 0.62)
--glass-strong: rgba(255, 255, 255, 0.52)
--glass-raised: rgba(255, 255, 255, 0.78)
--border: rgba(255, 255, 255, 0.7)
--border-2: rgba(255, 255, 255, 0.95)
--edge: rgba(38, 40, 70, 0.1)
--text: #1b1d2a
--text-2: #565a70
--text-3: #8b8fa3
--accent-grad: linear-gradient(180deg, #3a3e4c 0%, #23262f 100%)
--dot-live: #86c79a
--blur: 22px
--ease: cubic-bezier(0.16, 1, 0.3, 1)
--maxw: 1200px
```

## 9. Voice and Product Copy

Precise, calm, slightly atmospheric. Can be poetic but not vague. Best phrases describe both function and feeling.

- Use: calm, considered, product worlds, software you can step into, crafted in Liquid Glass, conjured not just coded.
- Avoid: generic SaaS language, loud hype, over-explaining, feature-checklist copy.
- Product descriptions: one clear sentence on what it does, then Orbioom feeling through design and interaction.

## 10. Do / Do Not

| Do | Do Not |
|---|---|
| Quiet surfaces with one clear focal action. | Competing cards, gradients, decorative clutter. |
| Green as a rare luminous accent. | Green as the whole brand palette. |
| Interfaces feel like natural extensions. | Force users to learn a complicated machine. |
| Reuse glass, ink, orb, motion. | Invent unrelated systems for each page. |
| Consider every border, shadow, radius, transition, label. | Ship accidental visual details. |
| Build real product on the first screen. | Hide product behind marketing-only layouts. |

## 11. Handoff Checklist

- Does the screen feel calm before clever?
- Is the main action obvious without extra explanation?
- Colors pulled from the Orbioom token system?
- Glass readable, with enough contrast, not too much blur?
- Green used only where it has strong reason?
- Does the product have a visual world, not just text blocks?
- Animations slow, useful, respectful of reading?
- Would it still feel good on the hundredth use?
