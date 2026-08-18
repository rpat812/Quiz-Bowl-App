import type { Metadata } from "next";
import "./globals.css";
import "./auth.css";
export const metadata: Metadata={title:"QuizForge — Daily Quiz Bowl Practice",description:"Build Quiz Bowl mastery one clue at a time."};
export default function Layout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
