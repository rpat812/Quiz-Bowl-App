import Link from "next/link";
import { ShieldCheck } from "lucide-react";
import { adminLogin } from "./actions";

export default async function AdminLoginPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams;
  return <main className="admin-login-shell">
    <section className="admin-login-brand"><span className="admin-brand-mark">QF</span><div><p>Internal operations</p><h1>QuizForge<br />Admin Console</h1><span>Restricted access · All privileged actions are audited</span></div></section>
    <section className="admin-login-panel"><form action={adminLogin}>
      <ShieldCheck aria-hidden="true" /><h2>Admin sign in</h2><p>Use an authorized QuizForge staff account.</p>
      {error && <div className="admin-alert error" role="alert">{error}</div>}
      <label>Email<input name="email" type="email" autoComplete="email" required /></label>
      <label>Password<input name="password" type="password" autoComplete="current-password" required /></label>
      <button className="admin-button primary" type="submit">Enter admin console</button>
      <Link href="/login">Return to learner sign in</Link>
    </form></section>
  </main>;
}
