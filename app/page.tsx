"use client";

import { useEffect, useState } from "react";
import {
  ArrowRight, BarChart3, BookOpen, Check, ChevronRight, CircleHelp,
  Flame, Home as HomeIcon, Library, Settings, Target, Trophy, User, X, Zap,
} from "lucide-react";
import { createClient } from "@/utils/supabase/client";
import { isCorrectAnswer, questions as qs, type QuizQuestion as Q } from "@/lib/question-bank";
import { toProfileStats, type ProfileRow, type ProfileStats as Stats } from "@/types/database";

type View = "home" | "practice" | "categories" | "progress" | "leaders" | "profile" | "results";
type Answer = { q: Q; correct: boolean; submitted: string };

const categories = [
  ["History", "Timelines, leaders & turning points"],
  ["Science", "Biology, chemistry & physics"],
  ["Literature", "Authors, works & movements"],
  ["Fine Arts", "Painting, music & architecture"],
  ["Geography", "Places, people & landscapes"],
  ["Civics", "Government, law & institutions"],
  ["Mythology", "Gods, heroes & traditions"],
  ["Math", "Numbers, proofs & patterns"],
] as const;
const categoryScores = [82, 76, 68, 61, 74, 72, 66, 79];
const initial: Stats = { xp: 0, streak: 0, longest: 0, answered: 0, correct: 0, done: null };

export default function App() {
  const [view, setView] = useState<View>("home");
  const [stats, setStats] = useState(initial);
  const [questionSet, setQuestionSet] = useState(qs);
  const [title, setTitle] = useState("Daily practice");
  const [questionIndex, setQuestionIndex] = useState(0);
  const [input, setInput] = useState("");
  const [feedback, setFeedback] = useState<boolean | null>(null);
  const [answers, setAnswers] = useState<Answer[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState("");
  const [sessionXp, setSessionXp] = useState(0);
  const [profile, setProfile] = useState({ username: "player", display_name: "QuizForge Player" });

  useEffect(() => {
    let active = true;
    const load = async () => {
      const supabase = createClient();
      const { data, error } = await supabase
        .from("profiles")
        .select("username,display_name,total_xp,current_streak,longest_streak,total_answered,total_correct,last_daily_completed_on")
        .single();
      if (!active) return;
      if (error) {
        setSaveError("Your profile could not be loaded. Confirm the Supabase migration has been applied.");
      } else {
        const row = data as ProfileRow;
        setStats(toProfileStats(row));
        setProfile({ username: row.username, display_name: row.display_name });
      }
      setLoaded(true);
    };
    load();
    return () => { active = false; };
  }, []);

  const accuracy = stats.answered ? Math.round((stats.correct / stats.answered) * 100) : 0;
  const today = new Intl.DateTimeFormat("en-CA").format(new Date());
  const done = stats.done === today;
  const nav: Array<[View, string, typeof HomeIcon]> = [
    ["home", "Dashboard", HomeIcon],
    ["categories", "Categories", Library],
    ["progress", "Progress", BarChart3],
    ["leaders", "Leaderboard", Trophy],
    ["profile", "Profile", User],
  ];
  const activeLabel = nav.find(([destination]) => destination === view)?.[1] ?? "Practice";
  const initials = profile.display_name.split(" ").map((name) => name[0]).join("").slice(0, 2).toUpperCase();

  const go = (nextView: View) => { setView(nextView); scrollTo(0, 0); };
  const start = (category?: string) => {
    let pool = category ? qs.filter((question) => question.category === category) : qs;
    if (pool.length < 5) {
      pool = [...pool, ...qs.filter((question) => question.category !== category)].slice(0, 5);
    }
    setQuestionSet(pool);
    setTitle(category ? `${category} practice` : "Daily practice");
    setQuestionIndex(0);
    setInput("");
    setFeedback(null);
    setAnswers([]);
    go("practice");
  };
  const submit = () => {
    if (!input.trim()) return;
    const question = questionSet[questionIndex];
    const correct = isCorrectAnswer(question, input);
    setFeedback(correct);
    setAnswers((current) => [...current, { q: question, correct, submitted: input }]);
  };
  const next = async () => {
    if (questionIndex + 1 < questionSet.length) {
      setQuestionIndex(questionIndex + 1);
      setInput("");
      setFeedback(null);
      return;
    }
    setSaving(true);
    setSaveError("");
    try {
      const response = await fetch("/api/progress/complete", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          sessionType: title === "Daily practice" ? "daily" : "category",
          category: title.replace(" practice", ""),
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
          answers: answers.map((answer) => ({ questionId: answer.q.id, submitted: answer.submitted })),
        }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Progress could not be saved.");
      setStats(data.profile as Stats);
      setSessionXp(data.xpEarned);
      go("results");
    } catch (error) {
      setSaveError(error instanceof Error ? error.message : "Progress could not be saved.");
    } finally {
      setSaving(false);
    }
  };
  const saveProfile = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const username = String(form.get("username") || "").trim().toLowerCase();
    const display_name = String(form.get("displayName") || "").trim();
    setSaveError("");
    const { error } = await createClient().from("profiles").update({ username, display_name }).eq("username", profile.username);
    if (error) setSaveError(error.message);
    else setProfile({ username, display_name });
  };
  const signOut = async () => {
    await createClient().auth.signOut();
    window.location.assign("/login");
  };

  if (!loaded) {
    return <div className="app-loading" role="status"><span className="brand-mark">QF</span><strong>Opening your practice archive</strong></div>;
  }

  const focusMode = view === "practice" || view === "results";

  return (
    <div className={`shell ${focusMode ? "focus-mode" : ""}`}>
      <aside className="sidebar">
        <div className="brand"><span>QuizForge</span><i aria-hidden="true" /></div>
        <nav aria-label="Primary navigation">
          {nav.map(([destination, label, Icon]) => (
            <button className={view === destination ? "active" : ""} onClick={() => go(destination)} aria-current={view === destination ? "page" : undefined} key={destination}>
              <Icon />{label}
            </button>
          ))}
        </nav>
        <div className="sidebar-record">
          <span className="micro-label">Current run</span>
          <div><Flame /><p><strong>{stats.streak} day streak</strong><small>Best {Math.max(stats.longest, stats.streak)} days</small></p></div>
        </div>
        <button className="sidebar-profile" onClick={() => go("profile")}>
          <span>{initials}</span><p><strong>{profile.display_name}</strong><small>Varsity Scholar</small></p>
        </button>
      </aside>

      <main>
        <header className="topbar">
          <div className="mobile-brand"><strong>QuizForge</strong><i aria-hidden="true" /></div>
          <span className="breadcrumb">Practice archive / {activeLabel}</span>
          <div className="topbar-stats">
            <span><Flame /> {stats.streak} day streak</span><span>{stats.xp.toLocaleString()} XP</span>
            <button className="avatar-button" onClick={() => go("profile")} aria-label="Open profile" title="Open profile">{initials}</button>
          </div>
        </header>
        <div className="content">
          {saveError && <div className="app-error" role="alert">{saveError}</div>}
          {view === "home" && <HomeView stats={stats} accuracy={accuracy} done={done} start={start} go={go} />}
          {view === "practice" && <Practice q={questionSet[questionIndex]} i={questionIndex} total={questionSet.length} title={title} input={input} setInput={setInput} feedback={feedback} submit={submit} next={next} saving={saving} exit={() => go("home")} />}
          {view === "categories" && <Categories start={start} />}
          {view === "progress" && <Progress stats={stats} accuracy={accuracy} />}
          {view === "leaders" && <Leaders xp={stats.xp} />}
          {view === "profile" && <Profile stats={stats} accuracy={accuracy} profile={profile} save={saveProfile} signOut={signOut} />}
          {view === "results" && <Results answers={answers} daily={title === "Daily practice"} xp={sessionXp} start={start} home={() => go("home")} />}
        </div>
      </main>

      <nav className="bottom" aria-label="Mobile navigation">
        {nav.map(([destination, label, Icon]) => (
          <button className={view === destination ? "active" : ""} onClick={() => go(destination)} aria-current={view === destination ? "page" : undefined} key={destination}>
            <Icon /><small>{label === "Leaderboard" ? "Leaders" : label}</small>
          </button>
        ))}
      </nav>
    </div>
  );
}

function HomeView({ stats, accuracy, done, start, go }: { stats: Stats; accuracy: number; done: boolean; start: (category?: string) => void; go: (view: View) => void }) {
  const completed = done ? 10 : 0;
  const edition = new Intl.DateTimeFormat("en-US", { month: "2-digit", day: "2-digit" }).format(new Date()).replace("/", "");
  return (
    <>
      <div className="page-heading dashboard-heading"><h1>Build your range.</h1><p>A focused round today. A stronger recall tomorrow.</p></div>
      <div className="daily-layout">
        <section className="daily-edition">
          <div className="edition-stamp"><span>Daily set</span><small>Edition</small><strong>{edition}</strong><b>Mixed</b></div>
          <div className="daily-copy">
            <h2>{done ? "Daily goal complete" : "Your daily 10"}</h2>
            <p>{done ? "Your streak is secure. Open another edition to keep building depth." : "Ten mixed-category clues selected to build your range."}</p>
            <div className="edition-meta"><span>10 questions</span><span>Mixed topics</span><span>Up to 145 XP</span></div>
          </div>
          <button className="primary primary-ink" onClick={() => start()}>{done ? "Practice another set" : "Start practice"}<ArrowRight /></button>
        </section>
        <aside className="daily-ledger" aria-label="Daily progress">
          <span className="micro-label">Today</span><strong>{completed}/10</strong><b>Completed</b>
          <div className="ledger-segments" aria-hidden="true">{Array.from({ length: 10 }).map((_, index) => <i className={index < completed ? "filled" : ""} key={index} />)}</div>
          <small>{done ? "Daily record complete" : "Ready when you are"}</small>
        </aside>
      </div>
      <div className="metric-ledger">
        <Stat icon={<Flame />} label="Current streak" value={`${stats.streak} days`} note={`Best ${Math.max(stats.longest, stats.streak)} days`} />
        <Stat icon={<Zap />} label="Total XP" value={stats.xp.toLocaleString()} note="Your lifetime score" />
        <Stat icon={<Target />} label="Overall accuracy" value={`${accuracy}%`} note={`Across ${stats.answered} questions`} />
      </div>
      <SectionTitle label="Subject collection" action="View all" onAction={() => go("categories")} />
      <div className="edition-grid">
        {categories.slice(0, 6).map(([category], index) => (
          <button className="edition-card" onClick={() => start(category)} key={category}>
            <span className="edition-number"><small>Edition</small>{String(index + 1).padStart(2, "0")}</span>
            <span className="edition-name"><strong>{category}</strong><small>54 questions</small></span>
            <b>{categoryScores[index]}%</b><ArrowRight />
          </button>
        ))}
      </div>
      <div className="dashboard-lower">
        <section className="recommendation"><span className="edition-tab">03</span><div><h2>Strengthen Literature</h2><p>Your 68% accuracy is trending up. Five more clues can make it stick.</p></div><button className="secondary" onClick={() => start("Literature")}>Practice Literature <ArrowRight /></button></section>
        <section className="rank-record"><Trophy /><span><small>Weekly rank</small><strong>#12</strong><b>90 XP from the top 10</b></span></section>
      </div>
      <SectionTitle label="Category pulse" action="Full progress" onAction={() => go("progress")} />
      <div className="pulse">
        {[["History", 82], ["Science", 76], ["Literature", 68], ["Fine Arts", 61]].map(([category, score]) => (
          <section key={category as string}><span>{category}<b>{score}%</b></span><i><b style={{ width: `${score}%` }} /></i><small>Last 30 questions</small></section>
        ))}
      </div>
    </>
  );
}

function Categories({ start }: { start: (category?: string) => void }) {
  return <><Title over="Targeted practice" title="Choose an edition." sub="Build depth in one subject. Each round focuses your recall around that selection." /><div className="category-list">{categories.map(([category, description], index) => (
    <button className="category-row" onClick={() => start(category)} key={category}>
      <span className="edition-number"><small>Edition</small>{String(index + 1).padStart(2, "0")}</span>
      <span className="category-copy"><strong>{category}</strong><small>{description}</small></span>
      <span className="category-count">{54 + index * 11} questions</span><span className="category-score">{categoryScores[index]}%</span><ChevronRight />
    </button>
  ))}</div></>;
}

function Practice({ q, i, total, title, input, setInput, feedback, submit, next, saving, exit }: { q: Q; i: number; total: number; title: string; input: string; setInput: (value: string) => void; feedback: boolean | null; submit: () => void; next: () => void; saving: boolean; exit: () => void }) {
  const edition = String(categories.findIndex(([category]) => category === q.category) + 1).padStart(2, "0");
  return <div className="practice">
    <div className="practice-top"><button onClick={exit} aria-label="Exit practice" title="Exit practice"><X /></button><div><span>{title}</span><div className="practice-progress" aria-label={`Question ${i + 1} of ${total}`}>{Array.from({ length: total }).map((_, index) => <i className={index < i ? "done" : index === i ? "now" : ""} key={index} />)}</div></div><strong>{String(i + 1).padStart(2, "0")} / {String(total).padStart(2, "0")}</strong></div>
    <article className="question-sheet"><div className="question-label"><span>Edition {edition}</span><b>{q.category}</b><small>{q.topic}</small></div><h1>{q.prompt}</h1>
      {feedback === null ? <form onSubmit={(event) => { event.preventDefault(); submit(); }}><label>Your answer<input autoFocus value={input} onChange={(event) => setInput(event.target.value)} placeholder="Type your answer" /></label><button className="primary primary-ink" disabled={!input.trim()}>Submit answer <ArrowRight /></button></form>
        : <div className={`feedback ${feedback ? "correct" : "wrong"}`}><div className="feedback-title"><span>{feedback ? <Check /> : <X />}</span><div><small>{feedback ? "Correct / +10 XP" : "Not quite"}</small><h2>{feedback ? "Nice recall." : `Answer: ${q.answer}`}</h2></div></div><section><strong>Why it matters</strong><p>{q.explanation}</p></section><button className="primary primary-ink" disabled={saving} onClick={next}>{saving ? "Saving progress" : i + 1 === total ? "See results" : "Next question"}<ArrowRight /></button></div>}
    </article><button className="report"><CircleHelp /> Report this question</button>
  </div>;
}

function Progress({ stats, accuracy }: { stats: Stats; accuracy: number }) {
  return <><Title over="Your record" title="Progress, indexed." sub="See what is sticking and where your next breakthrough lives." /><div className="kpis metric-ledger">
    <Stat icon={<BookOpen />} label="Questions answered" value={String(stats.answered)} note="Lifetime" /><Stat icon={<Target />} label="Overall accuracy" value={`${accuracy}%`} note="All categories" /><Stat icon={<Flame />} label="Longest streak" value={`${stats.longest} days`} note="Personal best" /><Stat icon={<Zap />} label="Lifetime XP" value={stats.xp.toLocaleString()} note="Varsity Scholar" />
  </div><section className="mastery"><div className="section-heading-static"><h2>Accuracy by category</h2></div>{[["History", 82, 38], ["Science", 76, 33], ["Literature", 68, 29], ["Fine Arts", 61, 21], ["Geography", 74, 25]].map(([category, score, answered], index) => <div key={category as string}><span className="row-index">{String(index + 1).padStart(2, "0")}</span><strong>{category}</strong><i><b style={{ width: `${score}%` }} /></i><b>{score}%</b><small>{answered} answered</small></div>)}</section></>;
}

function Leaders({ xp }: { xp: number }) {
  const players = [["Ava M.", 1760], ["Jordan L.", 1580], ["Sam K.", 1490], ["Nina P.", 1375], ["You", xp], ["Eli T.", 1180]].sort((a, b) => (b[1] as number) - (a[1] as number));
  return <><Title over="Friendly competition" title="Weekly leaderboard." sub="Rankings reset every Monday. Learn consistently and the points follow." /><div className="tabs" role="tablist" aria-label="Leaderboard period"><button role="tab" aria-selected="true">This week</button><button role="tab" aria-selected="false">All time</button></div><div className="leaders"><div className="leader-header" aria-hidden="true"><span>Rank</span><span>Scholar</span><span>Level</span><span>Score</span></div>{players.map(([name, score], index) => <div className={name === "You" ? "you" : ""} key={name as string}><b>#{index + 1}</b><span className="leader-avatar">{(name as string).split(" ").map((part) => part[0]).join("")}</span><p><strong>{name}</strong><small>{index < 3 ? "Varsity Scholar" : "Rising Scholar"}</small></p><strong>{(score as number).toLocaleString()} <small>XP</small></strong></div>)}</div></>;
}

function Profile({ stats, accuracy, profile, save, signOut }: { stats: Stats; accuracy: number; profile: { username: string; display_name: string }; save: (event: React.FormEvent<HTMLFormElement>) => void; signOut: () => void }) {
  const initials = profile.display_name.split(" ").map((name) => name[0]).join("").slice(0, 2).toUpperCase();
  return <><Title over="Your account" title="Scholar profile." sub="Your QuizForge identity and lifetime record." /><div className="profile"><section className="profile-record"><span className="profile-avatar">{initials}</span><p className="micro-label">Varsity scholar</p><h2>{profile.display_name}</h2><p>@{profile.username}</p><div><span><strong>{stats.xp.toLocaleString()}</strong>XP</span><span><strong>{stats.answered}</strong>Answers</span><span><strong>{accuracy}%</strong>Accuracy</span></div></section><section className="profile-settings"><div className="section-heading-static"><h2><Settings /> Profile details</h2><p>Update how you appear on QuizForge.</p></div><form onSubmit={save}><label>Display name<input name="displayName" required maxLength={40} defaultValue={profile.display_name} /></label><label>Username<input name="username" required minLength={3} maxLength={24} pattern="[a-z0-9_]+" defaultValue={profile.username} /></label><div className="form-actions"><button className="primary primary-ink" type="submit">Save changes</button><button className="profile-signout" type="button" onClick={signOut}>Sign out</button></div></form></section></div></>;
}

function Results({ answers, daily, xp, start, home }: { answers: Answer[]; daily: boolean; xp: number; start: (category?: string) => void; home: () => void }) {
  const correct = answers.filter((answer) => answer.correct).length;
  const accuracy = Math.round((correct / answers.length) * 100);
  return <div className="results"><div className="results-mark"><Trophy /></div><h1>That round is in the books.</h1><p>You showed up, tested your recall, and left sharper.</p><div className="results-ledger"><span><strong>{correct}/{answers.length}</strong>Correct</span><span><strong>+{xp}</strong>XP earned</span><span><strong>{accuracy}%</strong>Accuracy</span></div><section className="result-note"><Flame /><p><strong>{daily ? "Your daily streak is secure" : "Targeted work pays off"}</strong><small>{daily ? "Come back tomorrow to keep it moving." : "Your progress has been updated."}</small></p></section><div className="result-actions"><button className="primary primary-ink" onClick={() => start("Literature")}>Practice a weak area <ArrowRight /></button><button className="secondary" onClick={home}>Back to dashboard</button></div></div>;
}

function Title({ title, sub }: { over: string; title: string; sub: string }) { return <div className="page-heading"><h1>{title}</h1><p>{sub}</p></div>; }
function SectionTitle({ label, action, onAction }: { label: string; action: string; onAction: () => void }) { return <div className="section-title"><h2>{label}</h2><button onClick={onAction}>{action} <ArrowRight /></button></div>; }
function Stat({ icon, label, value, note }: { icon: React.ReactNode; label: string; value: string; note: string }) { return <div className="stat"><span className="stat-label">{label}</span><strong>{value}</strong><small>{icon}{note}</small></div>; }
