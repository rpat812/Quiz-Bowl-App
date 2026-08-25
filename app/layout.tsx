import type { Metadata } from "next";
import "@fontsource-variable/inter";
import "@fontsource/barlow-condensed/600.css";
import "@fontsource/barlow-condensed/700.css";
import "@fontsource/barlow-condensed/800.css";
import "./globals.css";
import "./auth.css";

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_URL
    ? `https://${process.env.VERCEL_URL}`
    : process.env.VERCEL_PROJECT_PRODUCTION_URL
      ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
      : "http://localhost:3000");

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "QuizForge — Daily Quiz Bowl Practice",
  description: "Daily quiz bowl practice with streaks, XP, and weak-area review.",
  openGraph: {
    type: "website",
    title: "QuizForge — Daily Quiz Bowl Practice",
    description: "Daily quiz bowl practice with streaks, XP, and weak-area review.",
    url: "/",
    siteName: "QuizForge",
    images: [
      {
        url: "/quizforge-og.png",
        width: 1200,
        height: 630,
        alt: "QuizForge — daily quiz bowl practice with streaks, XP, and weak-area review",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "QuizForge — Daily Quiz Bowl Practice",
    description: "Daily quiz bowl practice with streaks, XP, and weak-area review.",
    images: ["/quizforge-og.png"],
  },
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <template
          data-design-contract="quizforge-practice-archive"
          dangerouslySetInnerHTML={{
            __html:
              "<!-- THESIS: Practice as a trusted archive, refusing the generic soft-card learning dashboard. OWN-WORLD: warm paper, ink-black rail, archive orange, index blue, condensed labels, numbered editions, and precise rules. STORY: students open a daily set, read their record, choose a subject edition, practice, and archive the result. FIRST VIEWPORT: compact dark rail; bold heading; dominant horizontal orange daily edition beside a segmented ledger; ruled metrics and a 3x2 subject grid below. FORM: Practice Archive, selected challenger from seed 0f70f44f. FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance -->",
          }}
        />
        {children}
      </body>
    </html>
  );
}
