import { AlertTriangle } from "lucide-react";
import { AdminHeader, Metric, Notice } from "@/components/admin/ui";
import { requireAdmin } from "@/lib/admin/auth";
import { adminRpc, single } from "@/lib/admin/data";

type Overview = { dau: number; mau: number; newUsers: number; sessions: number; questionsAnswered: number; accuracy: number; completionRate: number; totalUsers: number; publishedQuestions: number; suspendedUsers: number; trend: Array<{ day: string; active_users: number; sessions: number }>; categories: Array<{ category: string; answers: number; accuracy: number }> };
type ProfileInsights = { completedProfiles:number;incompleteProfiles:number;missingEmail:number;missingPhone:number;genderDistribution:Array<{label:string;count:number}>;ageDistribution:Array<{label:string;count:number}> };

export default async function AdminOverview({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  await requireAdmin("overview.view");
  const params = await searchParams;
  const today = new Date().toISOString().slice(0, 10);
  const prior = new Date(Date.now() - 29 * 86400000).toISOString().slice(0, 10);
  const from = single(params.from, prior); const to = single(params.to, today);
  const [data, profiles] = await Promise.all([adminRpc<Overview>("admin_overview", { p_from: from, p_to: to }), adminRpc<ProfileInsights>("admin_profile_insights")]);
  const peak = Math.max(1, ...data.trend.map((row) => Number(row.sessions)));
  return <><AdminHeader title="Platform overview" description="Operational health, engagement, and content coverage from one trusted view." action={<form className="admin-date-range"><input type="date" name="from" defaultValue={from} /><span>to</span><input type="date" name="to" defaultValue={to} /><button>Apply</button></form>} />
    <Notice error={single(params.error)} message={single(params.message)} />
    <section className="admin-metrics"><Metric label="Daily active users" value={data.dau} note="Today" /><Metric label="Monthly active users" value={data.mau} note="Trailing 30 days" /><Metric label="New users" value={data.newUsers} note="Selected range" /><Metric label="Sessions completed" value={data.sessions} /><Metric label="Questions answered" value={data.questionsAnswered.toLocaleString()} /><Metric label="Average accuracy" value={`${data.accuracy}%`} /></section>
    <div className="admin-grid two"><section className="admin-panel"><div className="admin-section-heading"><h2>Session activity</h2><span>{from} — {to}</span></div><div className="admin-bars" aria-label="Daily completed sessions">{data.trend.map((row) => <div key={row.day} title={`${row.day}: ${row.sessions} sessions`}><i style={{ height: `${Math.max(4, Number(row.sessions) / peak * 100)}%` }} /><span>{new Date(`${row.day}T12:00:00`).getDate()}</span></div>)}</div></section>
      <section className="admin-panel"><div className="admin-section-heading"><h2>Category performance</h2><span>Answered / accuracy</span></div><div className="admin-ranked-list">{data.categories.length ? data.categories.map((row) => <div key={row.category}><strong>{row.category}</strong><span>{row.answers} answers</span><b>{row.accuracy}%</b></div>) : <p className="admin-empty">No activity in this range.</p>}</div></section></div>
    <section className="admin-metrics compact"><Metric label="Completed profiles" value={profiles.completedProfiles} /><Metric label="Incomplete profiles" value={profiles.incompleteProfiles} /><Metric label="Missing email" value={profiles.missingEmail} /><Metric label="Missing phone" value={profiles.missingPhone} /></section>
    <div className="admin-grid two"><section className="admin-panel"><div className="admin-section-heading"><h2>Gender distribution</h2><span>All registered users</span></div><div className="admin-ranked-list">{profiles.genderDistribution.map(row=><div key={row.label}><strong>{row.label.replaceAll("_"," ")}</strong><span>{row.count} users</span><b>{data.totalUsers ? Math.round(row.count/data.totalUsers*100) : 0}%</b></div>)}</div></section><section className="admin-panel"><div className="admin-section-heading"><h2>Age distribution</h2><span>All registered users</span></div><div className="admin-ranked-list">{profiles.ageDistribution.map(row=><div key={row.label}><strong>{row.label}</strong><span>{row.count} users</span><b>{data.totalUsers ? Math.round(row.count/data.totalUsers*100) : 0}%</b></div>)}</div></section></div>
    <section className="admin-panel"><div className="admin-section-heading"><h2>Operational attention</h2><span>Current state</span></div><div className="admin-alert-grid"><div><AlertTriangle /><span>Suspended accounts</span><strong>{data.suspendedUsers}</strong></div><div><AlertTriangle /><span>Published questions</span><strong>{data.publishedQuestions}</strong></div><div><AlertTriangle /><span>Total registered users</span><strong>{data.totalUsers}</strong></div></div></section>
  </>;
}
