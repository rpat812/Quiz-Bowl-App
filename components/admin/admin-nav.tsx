import Link from "next/link";
import { BarChart3, BookOpen, Gauge, ListChecks, Settings, ShieldCheck, Trophy, Users } from "lucide-react";
import type { AdminAccess } from "@/lib/admin/auth";

const entries = [
  ["/admin", "Overview", Gauge, "overview.view"],
  ["/admin/users", "Users", Users, "users.view"],
  ["/admin/leaderboards", "Leaderboards", Trophy, "leaderboards.view"],
  ["/admin/questions/analytics", "Question analytics", BarChart3, "questions.view"],
  ["/admin/content", "Content", BookOpen, "questions.view"],
  ["/admin/audit-log", "Audit log", ListChecks, "audit.view"],
  ["/admin/settings", "Settings & access", Settings, "settings.view"],
] as const;

export function AdminNav({ access }: { access: AdminAccess }) {
  return <aside className="admin-sidebar">
    <Link className="admin-logo" href="/admin"><span>QF</span><div><strong>QuizForge</strong><small>Admin console</small></div></Link>
    <nav aria-label="Admin navigation">{entries.filter((entry) => access.capabilities.includes(entry[3])).map(([href, label, Icon]) =>
      <Link href={href} key={href}><Icon aria-hidden="true" />{label}</Link>)}</nav>
    <div className="admin-identity"><ShieldCheck /><div><strong>{access.displayName}</strong><small>{access.roles.join(" · ").replaceAll("_", " ")}</small></div></div>
    <Link className="admin-return" href="/">Return to learner app</Link>
  </aside>;
}
