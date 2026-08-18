import Link from "next/link";
import { Zap } from "lucide-react";
import { login } from "@/app/auth/actions";

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ error?: string; message?: string }> }) {
  const params = await searchParams;
  return <div className="auth-shell"><section className="auth-intro"><div className="auth-brand"><span><Zap fill="currentColor" /></span>QuizForge</div><div><p className="auth-kicker">RETURN TO THE FORGE</p><h1>Small sessions.<br />Serious recall.</h1><p>Pick up your streak, sharpen a weak subject, and keep moving.</p></div><blockquote>"The questions you miss today become the clues you own tomorrow."</blockquote></section><section className="auth-form"><div><p className="auth-kicker">WELCOME BACK</p><h2>Sign in to practice</h2><p>Your progress is waiting for you.</p>{params.error && <div className="auth-alert error">{params.error}</div>}{params.message && <div className="auth-alert success">{params.message}</div>}<form action={login}><label>Email<input name="email" type="email" autoComplete="email" required placeholder="you@example.com" /></label><label>Password<input name="password" type="password" autoComplete="current-password" required placeholder="At least 8 characters" /></label><button className="primary" type="submit">Sign in <Zap /></button></form><p className="auth-switch">New to QuizForge? <Link href="/signup">Create an account</Link></p></div></section></div>;
}
