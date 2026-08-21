import Link from "next/link";
import { ArrowRight, Flame, Target, Zap } from "lucide-react";
import { login } from "@/app/auth/actions";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; message?: string }>;
}) {
  const params = await searchParams;
  return (
    <div className="auth-shell">
      <section className="auth-intro">
        <div className="auth-brand"><span>QuizForge</span><i aria-hidden="true" /></div>
        <div className="auth-intro-copy">
          <h1>Build your range.</h1>
          <p>Focused Quiz Bowl practice, recorded one thoughtful round at a time.</p>
          <div className="auth-record">
            <span><Flame /><strong>Keep your streak</strong><small>Return to today&apos;s practice</small></span>
            <span><Target /><strong>Track your recall</strong><small>Accuracy and XP stay with you</small></span>
          </div>
        </div>
        <p className="auth-footnote"><Zap /> Built for daily Quiz Bowl practice</p>
      </section>

      <section className="auth-form">
        <div>
          <h2>Sign in to QuizForge</h2>
          <p>Your progress is ready when you are.</p>
          {params.error && <div className="auth-alert error" role="alert">{params.error}</div>}
          {params.message && <div className="auth-alert success" role="status">{params.message}</div>}
          <form action={login}>
            <label>Email<input name="email" type="email" autoComplete="email" required placeholder="you@example.com" /></label>
            <label>Password<input name="password" type="password" autoComplete="current-password" required placeholder="At least 8 characters" /></label>
            <button className="auth-submit" type="submit">Sign in <ArrowRight /></button>
          </form>
          <p className="auth-switch">New to QuizForge? <Link href="/signup">Create an account</Link></p>
        </div>
      </section>
    </div>
  );
}
