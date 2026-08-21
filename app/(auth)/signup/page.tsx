import Link from "next/link";
import { ArrowRight, Check, Zap } from "lucide-react";
import { signup } from "@/app/auth/actions";

export default async function SignupPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;
  return (
    <div className="auth-shell">
      <section className="auth-intro">
        <div className="auth-brand"><span>QuizForge</span><i aria-hidden="true" /></div>
        <div className="auth-intro-copy">
          <h1>Start your record.</h1>
          <p>Build a practice habit with clear questions, useful explanations, and progress you can trust.</p>
          <div className="auth-record signup-record">
            <span><Check /><strong>Daily mixed rounds</strong></span>
            <span><Check /><strong>Category practice</strong></span>
            <span><Check /><strong>Persistent XP and accuracy</strong></span>
          </div>
        </div>
        <p className="auth-footnote"><Zap /> Ten focused questions at a time</p>
      </section>

      <section className="auth-form auth-form-signup">
        <div>
          <h2>Join QuizForge</h2>
          <p>Free to practice. Built for Quiz Bowl.</p>
          {error && <div className="auth-alert error" role="alert">{error}</div>}
          <form action={signup}>
            <div className="auth-form-row">
              <label>Display name<input name="displayName" required maxLength={40} autoComplete="name" placeholder="Ada Lovelace" /></label>
              <label>Username<input name="username" required minLength={3} maxLength={24} pattern="[A-Za-z0-9_]+" autoComplete="username" placeholder="ada_quizzes" /></label>
            </div>
            <label>Email<input name="email" type="email" autoComplete="email" required placeholder="you@example.com" /></label>
            <label>Password<input name="password" type="password" autoComplete="new-password" minLength={8} required placeholder="At least 8 characters" /></label>
            <button className="auth-submit" type="submit">Create account <ArrowRight /></button>
          </form>
          <p className="auth-switch">Already have an account? <Link href="/login">Sign in</Link></p>
        </div>
      </section>
    </div>
  );
}
