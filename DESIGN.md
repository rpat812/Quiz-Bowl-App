---
name: QuizForge Practice Archive
description: A precise, student-first practice archive for building Quiz Bowl range and recording progress.
colors:
  paper: "#f7f4ef"
  tissue: "#f9f7f3"
  white: "#fff"
  ink: "#171717"
  navigation-ink: "#121212"
  muted-ink: "#66645f"
  soft-ink: "#8a867f"
  rule: "#d6d0c7"
  rule-dark: "#393939"
  archive-orange: "#cd451a"
  archive-orange-dark: "#a93412"
  index-blue: "#024ec9"
  index-blue-dark: "#0f4cb1"
  success-forest: "#2f6f57"
  error-brick: "#a33e2e"
typography:
  display:
    fontFamily: '"Barlow Condensed", "Arial Narrow", sans-serif'
    fontSize: "clamp(42px, 5vw, 66px)"
    fontWeight: 700
    lineHeight: 0.92
    letterSpacing: "normal"
  headline:
    fontFamily: '"Barlow Condensed", "Arial Narrow", sans-serif'
    fontSize: "38px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "normal"
  title:
    fontFamily: '"Barlow Condensed", "Arial Narrow", sans-serif'
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "normal"
  body:
    fontFamily: '"Inter Variable", Inter, Arial, sans-serif'
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: "normal"
  label:
    fontFamily: '"Barlow Condensed", "Arial Narrow", sans-serif'
    fontSize: "12px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "0.08em"
rounded:
  square: "0"
  control: "2px"
  avatar: "50%"
spacing:
  compact: "8px"
  control-gap: "10px"
  inset: "14px"
  field-gap: "18px"
  section: "24px"
  page: "42px"
components:
  button-primary:
    backgroundColor: "{colors.navigation-ink}"
    textColor: "{colors.white}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "0 19px"
    height: "48px"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "0 19px"
    height: "48px"
  input:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "0 14px"
    height: "50px"
  edition-card:
    backgroundColor: "{colors.tissue}"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
    padding: "14px 15px 14px 18px"
    height: "92px"
  daily-ledger:
    backgroundColor: "{colors.tissue}"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
    padding: "24px 20px"
---

# Design System: QuizForge Practice Archive

## Overview

**Creative North Star: "The Practice Archive"**

QuizForge treats daily study as a trusted, accumulating record. The visual world combines the clarity of a labeled collection, the confidence of a tournament program, and the utility of a serious study tool. Numbered editions, precise rules, compact metadata, and tabular measures make progress feel recorded rather than merely decorated.

The archive reference stays flat and digital. Warm paper grounds the experience; an ink-black rail gives authenticated screens a stable spine; archive orange identifies the featured daily set; index blue marks selection, progress, and links. Warmth comes through plainspoken copy, generous breathing room, and controlled color rather than illustration or soft effects.

**Key Characteristics:**

- Flat, warm work surfaces framed by dark navigation and precise rules.
- Condensed, uppercase metadata paired with calm, highly legible body copy.
- Numbered subject editions and segmented progress as recurring identity devices.
- One dominant practice action per screen, with supporting records kept compact.
- Functional color, explicit state feedback, and restrained motion.

## Colors

The palette behaves like printed archive stock with a small set of functional inks: one warm feature color, one cool indexing color, and quiet semantic colors for feedback.

### Primary

- **Archive Orange:** The signature feature color for the daily edition, brand mark, active question, streak emphasis, and result accents. Use it in decisive fields or narrow markers, not as a general wash.
- **Archive Orange Dark:** The deeper companion for orange interaction states where stronger contrast is required.

### Secondary

- **Index Blue:** The selection and navigation accent for active rails, progress fills, links, tabs, focus borders, and supporting action cues.
- **Deep Index Blue:** A darker marker for blue states that need more visual weight.

### Tertiary

- **Success Forest:** Correct-answer labels, icons, and explanation boundaries.
- **Error Brick:** Incorrect-answer, load, and form-error boundaries and labels.

### Neutral

- **Paper:** The warm application ground behind authenticated content.
- **Tissue:** The cleaner focused surface used by forms, ledgers, cards, and the question sheet.
- **White:** High-contrast control text and hover surfaces.
- **Ink:** Primary text, strong borders, and secondary-control strokes.
- **Navigation Ink:** The desktop rail and primary-action fill.
- **Muted Ink:** Supporting copy and secondary metadata.
- **Soft Ink:** Low-priority indices and de-emphasized record details.
- **Rule / Dark Rule:** Structural dividers on light and dark surfaces.

### Named Rules

**The Functional Ink Rule.** Orange announces the featured practice object; blue marks navigation, selection, and progress. Do not swap their jobs for variety.

**The Solid Field Rule.** Large color fields are solid. Gradients, glows, translucent blobs, and decorative color haze do not belong in this system.

## Typography

**Display Font:** Barlow Condensed (with Arial Narrow and sans-serif fallbacks)

**Body Font:** Inter Variable (with Inter, Arial, and sans-serif fallbacks)

**Label Font:** Barlow Condensed

**Character:** Barlow Condensed gives headings, labels, numbers, and actions the compact authority of an archive index or tournament program. Inter keeps questions, explanations, form content, and supporting copy neutral and readable.

### Hierarchy

- **Display:** Bold condensed type with tight line height for page-level dashboard, authentication, and results headings only.
- **Headline:** Bold condensed type for the daily edition and other dominant section statements.
- **Title:** Bold condensed type for recommendations, focused panels, and record headings.
- **Body:** Regular Inter for reading, instructions, questions, explanations, and form copy; keep longer passages comfortably narrow.
- **Label:** Bold condensed type with open tracking, usually uppercase, for metadata, actions, breadcrumbs, tabs, and field labels.
- **Metrics:** Use condensed type with tabular numerals for XP, accuracy, streaks, edition numbers, ranks, and question progress.

### Named Rules

**The Two-Voice Rule.** Barlow Condensed identifies and organizes; Inter explains and supports. Do not set long-form reading text in the condensed face.

**The Earned Scale Rule.** Hero-scale type belongs to page-level headings. Panels and repeated records remain compact enough to scan.

## Layout

Authenticated desktop screens use a fixed `238px` navigation rail and a centered content sheet capped at `1280px`, with `42px` horizontal page padding. The top utility bar is `72px` high. Dashboard hierarchy runs from the page heading to the orange daily edition and adjacent ledger, then an unframed ruled metric row, a three-column subject collection, and lower supporting records.

The system uses grids and rules rather than floating section cards. Repeated records align labels, indices, metrics, and actions into stable tracks. Practice and results enter focus mode: navigation disappears, the content recenters, and the question sheet is capped at `840px` while results are capped at `720px`. Authentication uses a two-field composition, with the dark brand narrative occupying roughly two fifths and the light form surface the remaining width.

At `1120px`, the daily edition simplifies to two columns, the subject collection becomes two columns, and lower dashboard records stack. At `900px`, the desktop rail disappears, the utility header becomes a mobile brand bar, daily content stacks, and profile/KPI layouts simplify. At `760px`, authentication becomes a vertical composition and its supporting record list is removed. At `640px`, dashboard and KPI grids collapse, cards become single-column records, question-sheet elevation is removed, actions can span full width, and a fixed five-item bottom navigation appears. At `520px`, signup field pairs stack.

**The One Scan Rule.** The primary action, current record, and next practice path must remain legible in one scan at every breakpoint.

## Elevation & Depth

The system is flat by default. Hierarchy comes from solid tonal fields, one-pixel rules, colored edge markers, and deliberate adjacency. The only conventional elevation is the centered practice question sheet on larger screens; mobile removes even that shadow because the viewport edge already supplies separation.

### Shadow Vocabulary

- **Practice Sheet:** A restrained ambient shadow used only to lift the active question from the paper ground. It is removed at the compact breakpoint.
- **Selected Record:** Inset blue top rules may mark a current row, as on the signed-in learner's leaderboard entry; this is a state marker, not general elevation.

### Named Rules

**The Flat-by-Default Rule.** No dashboard section receives a shadow merely to become a card. Use rules, alignment, or a semantic color field first.

## Shapes

The form language is square to lightly softened. Edition records, ledgers, feedback panels, and focused work surfaces are square; fields, buttons, and icon controls use a restrained `2px` corner. Circular geometry is reserved for human identity, such as avatars. One-pixel neutral rules create structure, while `3px` to `5px` colored edges identify selected states, editions, and feedback.

**The Shape Means Role Rule.** Rectangles hold work and records; circles identify people. Do not turn text actions, tabs, filters, or labels into pills.

## Components

### Buttons

Buttons feel compact, explicit, and tournament-ready rather than soft or playful.

- **Shape:** Lightly softened rectangle with stable `48px` minimum height and inline icon gap.
- **Primary:** Navigation-ink fill with white label and right-arrow icon. Orange is also valid when the surrounding surface needs a signature action rather than a dark anchor.
- **Hover / Focus:** Primary actions darken subtly; secondary actions invert to ink. Keyboard focus uses the shared high-contrast outline. State transitions run for `140ms` only when reduced motion is not requested.
- **Secondary:** Transparent field with a visible ink rule; never a low-contrast pill.
- **Icon Controls:** Stable square dimensions, familiar Lucide icons, and an accessible label or tooltip.

### Cards / Containers

- **Edition Records:** Square tissue surfaces with a one-pixel border, a `5px` category edge, numbered label, compact metadata, score, and directional icon. Hover raises the record by only `1px` and shifts the surface to white.
- **Daily Ledger:** Square tissue surface with a strong ink border, large tabular completion count, ten fixed square segments, and a ruled status note.
- **Question Sheet:** Square focused surface with a strong ink border and the sole ambient shadow on desktop.
- **Metric Ledger:** Unframed ruled columns; it is a record structure, not a set of independent cards.

### Inputs / Fields

- **Style:** White field, one-pixel medium-neutral border, lightly softened corners, Inter input text, persistent uppercase Barlow Condensed label, and at least `48px` height.
- **Focus:** Index-blue border plus a visible translucent blue outline.
- **Error / Disabled:** Errors use brick text and a strong top edge in addition to color. Disabled actions remain visibly inactive and retain their stable dimensions.

### Navigation

- **Desktop:** Fixed dark rail with five icon-and-label destinations, a `4px` blue active edge, muted default labels, and white hover/active text. Streak and profile records occupy the lower rail.
- **Utility Header:** Compact breadcrumb, streak, XP, and circular avatar action separated by rules.
- **Mobile:** Fixed five-item bottom bar with icon above a compact uppercase label. The active item uses a blue top edge and ink text; labels truncate safely.

### Tabs

Tabs sit directly on a strong bottom rule. The selected tab uses a `3px` index-blue underline and ink label; unselected tabs remain muted. Tabs do not use filled capsules.

### Feedback

Correct and incorrect states pair a square status icon, a written label, the resolved answer when needed, and a bordered explanation panel. Forest and brick reinforce the result, but iconography and copy carry the state without relying on color alone.

### Daily Edition

The signature dashboard object is a solid archive-orange horizontal edition: bordered stamp at left, concise practice copy and ruled metadata in the center, and an ink primary action at right. Its adjacent segmented ledger remains separate so action and progress are immediately distinguishable.

## Do's and Don'ts

### Do:

- **Do** use numbering, short uppercase labels, strong rules, and tabular metrics to make practice feel indexed and trustworthy.
- **Do** keep one dominant task per screen and align supporting information into compact records.
- **Do** reserve orange for featured practice and blue for selection, navigation, focus, and progress.
- **Do** preserve visible focus, explicit labels, non-color feedback, stable touch targets, responsive wrapping, and reduced-motion behavior.
- **Do** let mobile reorganize the hierarchy rather than merely shrink desktop tracks.

### Don't:

- **Don't** literalize the archive with cardboard texture, perspective, three-dimensional boxes, or ornamental nostalgia.
- **Don't** introduce gradients, glows, translucent blobs, ambient motion, or decorative image fields.
- **Don't** float page sections as decorative cards or nest cards inside cards.
- **Don't** soften controls into pills or apply large radii to repeated records.
- **Don't** invent photography, illustration, testimonials, or proof assets that the product does not have.
