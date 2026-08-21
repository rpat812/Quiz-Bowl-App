# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

The primary users are middle- and high-school Quiz Bowl students practicing independently on personal devices. Coaches may become a secondary audience later, but the current product is student-first.

## Product Purpose

QuizForge helps students build Quiz Bowl knowledge through focused daily practice, category-based drills, progress tracking, and immediate answer feedback. Success means students can enter practice quickly, understand how they are improving, and return consistently.

## Positioning

QuizForge combines short Quiz Bowl practice sessions with persistent streak, XP, accuracy, category mastery, and daily-progress feedback in one focused student experience.

## Operating Context

Students use the product independently for repeat practice on desktop and mobile devices. The core workflow is authentication, reviewing progress, choosing a practice path or category, answering questions, receiving immediate feedback, and reviewing session results.

## Capabilities and Constraints

- Preserve all current functionality, routes, flows, authentication, Supabase data integration, application state, and quiz logic.
- Preserve existing product terminology and factual copy unless a wording adjustment is required for interface clarity.
- The current surface set includes login, signup, dashboard, practice, results, category selection, progress, leaderboard, and profile views.
- This redesign may change only UI/UX, styling, layout, spacing, typography, colors, and component design.

## Brand Commitments

- Product name: QuizForge.
- Student-friendly, high-trust tone.
- The interface should feel clean, modern, minimal, polished, and intentionally designed rather than generically generated.

## Evidence on Hand

- Existing functional Next.js application and interface copy in `app/`.
- Existing question content in `lib/question-bank.ts`.
- Existing Supabase schema and persistence behavior in `supabase/`, `utils/supabase/`, and `app/api/`.
- No approved photography, illustration system, testimonials, or external proof assets are present; future work must not fabricate them.

## Product Principles

- Put practice within immediate reach.
- Make progress understandable at a glance.
- Keep feedback clear, encouraging, and academically credible.
- Support repeat use with consistent, predictable interaction patterns.
- Keep the experience equally usable on desktop and mobile.

## Accessibility & Inclusion

The interface must retain strong contrast, visible focus states, keyboard-operable controls, clear form labels, responsive layouts, and reduced-motion support.
