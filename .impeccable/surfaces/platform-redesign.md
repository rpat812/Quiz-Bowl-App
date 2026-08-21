# Platform Redesign Surface Brief

## Mode

Operate

## Scope

Login, signup, dashboard, categories, progress, leaderboard, profile, practice, feedback, loading, error, and results states.

## Direction

Practice Archive. Category practice sets are numbered editions; daily practice is the featured release; persistent progress is a precise archive record.

## First Viewport

A dark, compact navigation rail frames a warm-white content sheet. The dashboard opens with a decisive page heading and a dominant orange daily-set band. A ruled summary row follows, then a compact subject-edition grid. The student can identify the main action, current progress, and next subject in one scan.

## Interaction

Selecting a category should feel like pulling an edition forward: its colored edge, number, and metadata become the primary identity. Practice progress uses fixed segments and the current question is unambiguous. Correct, incorrect, saving, disabled, focus, and error states remain calm and explicit.

## Cross-Surface Reach

The edition label system carries category screens, recommendations, and results. Ruled metadata carries dashboard, progress, leaderboard, and profile. The dark rail and compact utility header unify authenticated screens; auth screens use the same ink, orange, type, and rule system without reproducing the full shell.

## Honest Risk

The archive reference can become visually heavy or overly literal. Keep materials flat, limit color fields, avoid perspective effects, and let semantic layout carry the metaphor.

## Approved Composition

`.impeccable/mocks/decision/challenger-archive.png`

Archive Grid was approved. Its dominant horizontal daily edition, adjacent daily-progress ledger, unframed metric row, and compact subject-edition grid define the dashboard topology. Other screens inherit its hierarchy and component grammar without copying dashboard regions that do not belong there.

Do not literalize the sneaker source, cardboard texture, product imagery, or 3D box behavior. The archive idea is carried by numbering, edge markers, compact metadata, strong rules, and the act of selecting an edition.

## Sampled Tokens

- Page ground: `#f7f4ef`
- Work surface: `#f9f7f3`
- Navigation ink: `#121212`
- Archive orange: `#cd451a`
- Index blue: `#024ec9`
- Deep blue marker: `#0f4cb1`
- Rule: `#d6d0c7`
- Body ink: `#171717`
- Muted ink: `#66645f`

## Component Grammar

- Corners: `0-4px` for controls and focused work surfaces; repeated edition records remain square.
- Rules: `1px` neutral rules, with `2-4px` colored edition-edge markers.
- Elevation: no dashboard elevation; only the practice work surface may use a minimal shadow to separate it from the page.
- Type: condensed uppercase display/metadata face paired with a neutral sans-serif body; tabular numerals for XP, accuracy, streaks, editions, and question progress.
- Controls: solid ink primary action, ruled secondary action, blue link action, icon buttons at stable square dimensions.

## Implementation Inventory

| Ingredient | Commitment | Medium |
| --- | --- | --- |
| Desktop navigation | 238px dark rail, five labeled icon destinations, selected blue edge, streak record, student identity | Semantic HTML/CSS + Lucide icons |
| Utility header | Compact XP, streak/accuracy summary and avatar action | Semantic HTML/CSS + Lucide icons |
| Page heading | One large dashboard-level heading with date/eyebrow and supporting line | Semantic HTML/CSS |
| Daily edition | Dominant orange horizontal field, edition label, challenge copy, metadata, primary action | Semantic HTML/CSS |
| Daily ledger | Bordered adjacent progress record with stable segmented question row | Semantic HTML/CSS |
| Metrics | Three unframed ruled columns with tabular values | Semantic HTML/CSS + Lucide icons |
| Subject collection | Six edition records in a 3x2 desktop grid with numbered labels and colored edge markers | Semantic HTML/CSS + Lucide icons |
| Practice | Centered work sheet, segmented progress rail, category label, answer field, explicit feedback states | Semantic HTML/CSS + Lucide icons |
| Auth | Ink brand field, focused tissue-white form, archive-orange accent label | Semantic HTML/CSS + Lucide icons |
| Typography | Condensed display/label face plus neutral body face | Local package font assets |
| Raster imagery | None; the approved composition contains no image-native product content | Accepted omission |

The primary action remains a high-contrast rectangular ink button with a right-arrow icon and stable 48px minimum height. It does not inherit a pill shape or decorative effect.
