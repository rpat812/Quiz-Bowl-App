"use client";

import { useEffect, useRef, useState } from "react";
import {
  ArrowRight, BarChart3, BookOpen, Check, ChevronRight, CircleHelp,
  Award, Bell, Clock3, Flame, Home as HomeIcon, Library, LoaderCircle, Settings, Target, Trophy, User, Users, X, Zap,
} from "lucide-react";
import { createClient } from "@/utils/supabase/client";
import { isCorrectAnswer, questions as qs, type QuizQuestion as Q } from "@/lib/question-bank";
import { toProfileStats, type ProfileRow, type ProfileStats as Stats } from "@/types/database";
import type { AnswerCheck, PracticeQuestion } from "@/types/questions";

type View = "home" | "practice" | "categories" | "progress" | "leaders" | "friends" | "profile" | "settings" | "results";
type Question = Q | PracticeQuestion;
type Answer = { questionId: string; correct: boolean; submitted: string; startedAt: string; submittedAt: string; responseTimeMs: number; timedOut: boolean };
type UserProfile = { username: string; display_name: string; email: string; phone: string; age: number | null; gender: string };
type LeaderboardPeriod = "weekly" | "all_time";
type LeaderboardEntry = {
  rank: number;
  display_name: string;
  username: string;
  xp: number;
  is_current_user: boolean;
};
type CategoryStat = { category: string; attempts: number; correct: number; accuracy: number | null; mastery: string; average_response_ms: number | null; last_practiced_at: string | null };
type ProductData = {
  overall: { attempted: number; correct: number; incorrect: number; accuracy: number | null; xp: number; streak: number; longestStreak: number; quizzesCompleted: number; averageResponseMs: number | null; timedOut: number };
  timeline: Array<{ day: string; attempted: number; correct: number; xp: number; quizzes: number }>;
  categories: CategoryStat[];
  badges: Array<{ key: string; name: string; description: string; type: string; icon: string; earnedAt: string }>;
  referral: { code?: string; qualified?: number };
  notifications: { enabled: boolean; time: string; timezone: string };
  recentActivity: Array<{ at: string; label: string; detail: string }>;
};

function isDatabaseQuestion(question: Question): question is PracticeQuestion {
  return "questionType" in question;
}

function formatDays(value: number) {
  return `${value} day${value === 1 ? "" : "s"}`;
}

const profileFieldLabels: Array<[keyof UserProfile, string]> = [
  ["display_name", "display name"], ["username", "username"], ["email", "email"],
  ["phone", "phone number"], ["age", "age"], ["gender", "gender"],
];

function profileCompletion(profile: UserProfile) {
  const missing = profileFieldLabels.filter(([key]) => profile[key] === null || String(profile[key]).trim() === "").map(([, label]) => label);
  return { missing, percentage: Math.round(((profileFieldLabels.length - missing.length) / profileFieldLabels.length) * 100) };
}

async function readApiResponse<T>(response: Response, fallbackMessage: string): Promise<T> {
  const contentType = response.headers.get("content-type") ?? "";

  if (!contentType.includes("application/json")) {
    throw new Error(response.ok ? fallbackMessage : `${fallbackMessage} (server error ${response.status})`);
  }

  const data = await response.json() as T & { error?: string };
  if (!response.ok) throw new Error(data.error || fallbackMessage);
  return data;
}

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
const categoryCounts: Record<string, string> = { History: "1,100 questions", Science: "500 questions" };
const initial: Stats = { xp: 0, streak: 0, longest: 0, answered: 0, correct: 0, done: null };
const QUESTION_TIME_LIMIT_MS = 15_000;
const TIMED_OUT_FEEDBACK_MS = 1_500;

export default function App() {
  const [view, setView] = useState<View>("home");
  const [stats, setStats] = useState(initial);
  const [questionSet, setQuestionSet] = useState<Question[]>([]);
  const [title, setTitle] = useState("Daily practice");
  const [questionIndex, setQuestionIndex] = useState(0);
  const [input, setInput] = useState("");
  const [feedback, setFeedback] = useState<AnswerCheck | null>(null);
  const [answers, setAnswers] = useState<Answer[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [saving, setSaving] = useState(false);
  const [checking, setChecking] = useState(false);
  const [loadingQuestions, setLoadingQuestions] = useState(false);
  const [questionError, setQuestionError] = useState("");
  const [saveError, setSaveError] = useState("");
  const [sessionXp, setSessionXp] = useState(0);
  const [profile, setProfile] = useState<UserProfile>({ username: "player", display_name: "QuizForge Player", email: "", phone: "", age: null, gender: "" });
  const [profileSaving, setProfileSaving] = useState(false);
  const [profileMessage, setProfileMessage] = useState("");
  const [productData, setProductData] = useState<ProductData | null>(null);
  const [productError, setProductError] = useState("");
  const questionStartedAt = useRef(new Date().toISOString());
  const completedQuestionIds = useRef(new Set<string>());
  const advancedQuestionIds = useRef(new Set<string>());

  const loadProductData = async (days = 30) => {
    try {
      const response = await fetch(`/api/me?days=${days}`, { cache: "no-store" });
      setProductData(await readApiResponse<ProductData>(response, "Your live progress could not be loaded."));
      setProductError("");
    } catch (error) {
      setProductError(error instanceof Error ? error.message : "Your live progress could not be loaded.");
    }
  };

  useEffect(() => {
    let active = true;
    const load = async () => {
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        window.location.assign("/login");
        return;
      }
      const { data, error } = await supabase
        .from("profiles")
        .select("username,display_name,total_xp,current_streak,longest_streak,total_answered,total_correct,last_daily_completed_on")
        .eq("id", user.id)
        .single();
      if (!active) return;
      if (error) {
        setSaveError("Your profile could not be loaded. Confirm the Supabase migration has been applied.");
      } else {
        const row = data as ProfileRow;
        setStats(toProfileStats(row));
        const { data: details } = await supabase.from("profile_details").select("email,phone,age,gender").eq("user_id", user.id).maybeSingle();
        setProfile({ username: row.username, display_name: row.display_name, email: details?.email ?? user.email ?? "", phone: details?.phone ?? "", age: details?.age ?? null, gender: details?.gender ?? "" });
      }
      void loadProductData();
      setLoaded(true);
    };
    load();
    return () => { active = false; };
  }, []);

  useEffect(() => {
    const requestedView = new URLSearchParams(window.location.search).get("view");
    if (requestedView === "settings") setView("settings");
  }, []);

  const accuracy = stats.answered ? Math.round((stats.correct / stats.answered) * 100) : 0;
  const today = new Intl.DateTimeFormat("en-CA").format(new Date());
  const done = stats.done === today;
  const nav: Array<[View, string, typeof HomeIcon]> = [
    ["home", "Dashboard", HomeIcon],
    ["categories", "Categories", Library],
    ["progress", "Progress", BarChart3],
    ["leaders", "Leaderboard", Trophy],
    ["friends", "Friends", Users],
    ["profile", "Profile", User],
    ["settings", "Settings", Settings],
  ];
  const activeLabel = nav.find(([destination]) => destination === view)?.[1] ?? "Practice";
  const initials = profile.display_name.split(" ").map((name) => name[0]).join("").slice(0, 2).toUpperCase();

  const go = (nextView: View) => { setView(nextView); scrollTo(0, 0); };
  const start = async (category?: string) => {
    setTitle(category ? `${category} practice` : "Daily practice");
    setQuestionIndex(0);
    setInput("");
    setFeedback(null);
    setAnswers([]);
    setQuestionError("");
    setQuestionSet([]);
    completedQuestionIds.current.clear();
    advancedQuestionIds.current.clear();
    questionStartedAt.current = new Date().toISOString();
    go("practice");

    if (category && category !== "History") {
      let pool: Question[] = qs.filter((question) => question.category === category);
      if (pool.length < 5) {
        pool = [...pool, ...qs.filter((question) => question.category !== category)].slice(0, 5);
      }
      setQuestionSet(pool);
      return;
    }

    setLoadingQuestions(true);
    try {
      const response = await fetch("/api/questions/session?category=History&count=10", {
        cache: "no-store",
      });
      const data = await readApiResponse<{ questions: PracticeQuestion[] }>(response, "Questions could not be loaded.");
      const questions = data.questions as PracticeQuestion[];
      if (!questions.length) throw new Error("No published History questions are available.");
      setQuestionSet(questions);
      questionStartedAt.current = new Date().toISOString();
    } catch (error) {
      setQuestionError(error instanceof Error ? error.message : "Questions could not be loaded.");
    } finally {
      setLoadingQuestions(false);
    }
  };
  const submit = async (timedOut = false) => {
    if ((!input.trim() && !timedOut) || checking || feedback) return;
    const question = questionSet[questionIndex];
    if (!question || completedQuestionIds.current.has(question.id)) return;
    completedQuestionIds.current.add(question.id);
    const submittedAt = new Date().toISOString();
    const responseTimeMs = Math.max(0, Date.parse(submittedAt) - Date.parse(questionStartedAt.current));
    const didTimeOut = timedOut || responseTimeMs >= QUESTION_TIME_LIMIT_MS;
    setChecking(true);
    setQuestionError("");
    try {
      let result: AnswerCheck;
      if (isDatabaseQuestion(question)) {
        const response = await fetch("/api/questions/check", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ questionId: question.id, submitted: didTimeOut ? "" : input, timedOut: didTimeOut }),
        });
        result = await readApiResponse<AnswerCheck>(response, "Your answer could not be checked.");
      } else {
        result = {
          correct: !didTimeOut && isCorrectAnswer(question, input),
          correctAnswer: question.answer,
          explanation: question.explanation,
        };
      }
      const resolved = didTimeOut ? { ...result, correct: false } : result;
      setFeedback(resolved);
      setAnswers((current) => [...current, { questionId: question.id, correct: resolved.correct, submitted: didTimeOut ? "" : input, startedAt: questionStartedAt.current, submittedAt, responseTimeMs, timedOut: didTimeOut }]);
    } catch (error) {
      completedQuestionIds.current.delete(question.id);
      setQuestionError(error instanceof Error ? error.message : "Your answer could not be checked.");
    } finally {
      setChecking(false);
    }
  };
  const next = async (expectedQuestionId: string) => {
    const currentQuestion = questionSet[questionIndex];
    if (!currentQuestion || currentQuestion.id !== expectedQuestionId || advancedQuestionIds.current.has(expectedQuestionId)) return;
    advancedQuestionIds.current.add(expectedQuestionId);
    if (questionIndex + 1 < questionSet.length) {
      setQuestionIndex((current) => current + 1);
      setInput("");
      setFeedback(null);
      setQuestionError("");
      questionStartedAt.current = new Date().toISOString();
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
          category: title === "Daily practice" ? "History" : title.replace(" practice", ""),
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
          answers,
        }),
      });
      const data = await readApiResponse<{ profile: Stats; xpEarned: number }>(response, "Progress could not be saved.");
      setStats(data.profile as Stats);
      setSessionXp(data.xpEarned);
      void loadProductData();
      go("results");
    } catch (error) {
      advancedQuestionIds.current.delete(expectedQuestionId);
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
    const email = String(form.get("email") || "").trim().toLowerCase();
    const phone = String(form.get("phone") || "").trim();
    const ageValue = String(form.get("age") || "").trim();
    const age = ageValue ? Number(ageValue) : null;
    const gender = String(form.get("gender") || "");
    setSaveError("");
    setProfileMessage("");
    setProfileSaving(true);
    const { data, error } = await createClient().rpc("update_my_profile", { p_display_name: display_name, p_username: username, p_email: email, p_phone: phone, p_age: age, p_gender: gender });
    setProfileSaving(false);
    if (error) setSaveError(error.message);
    else {
      const updated = data as UserProfile;
      setProfile({ ...updated, email: updated.email ?? "", phone: updated.phone ?? "", age: updated.age ?? null, gender: updated.gender ?? "" });
      setProfileMessage("Profile details saved.");
    }
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
          <div><Flame /><p><strong>{formatDays(stats.streak)} streak</strong><small>Best {formatDays(Math.max(stats.longest, stats.streak))}</small></p></div>
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
            <span><Flame /> {formatDays(stats.streak)} streak</span><span>{stats.xp.toLocaleString()} XP</span>
            <button className="avatar-button" onClick={() => go("profile")} aria-label="Open profile" title="Open profile">{initials}</button>
          </div>
        </header>
        <div className="content">
          {saveError && <div className="app-error" role="alert">{saveError}</div>}
          {view === "home" && <HomeView stats={stats} accuracy={accuracy} done={done} data={productData} profile={profile} start={start} go={go} />}
          {productError && !saveError && <div className="app-error" role="alert">{productError}</div>}
          {view === "practice" && <Practice key={questionSet[questionIndex]?.id ?? "loading"} q={questionSet[questionIndex]} i={questionIndex} total={questionSet.length} title={title} input={input} setInput={setInput} feedback={feedback} submit={submit} next={next} saving={saving} checking={checking} loading={loadingQuestions} error={questionError} startedAt={questionStartedAt.current} exit={() => go("home")} />}
          {view === "categories" && <Categories start={start} data={productData?.categories || []} />}
          {view === "progress" && <Progress data={productData} reload={loadProductData} start={start} />}
          {view === "leaders" && <Leaders />}
          {view === "friends" && <Friends referralCode={productData?.referral.code} />}
          {view === "profile" && <Profile stats={stats} accuracy={accuracy} profile={profile} data={productData} save={saveProfile} saving={profileSaving} message={profileMessage} signOut={signOut} />}
          {view === "settings" && <NotificationSettings data={productData?.notifications} reload={loadProductData} />}
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

function HomeView({ stats, accuracy, done, data, profile, start, go }: { stats: Stats; accuracy: number; done: boolean; data: ProductData | null; profile: UserProfile; start: (category?: string) => void; go: (view: View) => void }) {
  const completed = done ? 10 : 0;
  const edition = new Intl.DateTimeFormat("en-US", { month: "2-digit", day: "2-digit" }).format(new Date()).replace("/", "");
  const completion = profileCompletion(profile);
  return (
    <>
      <div className="page-heading dashboard-heading"><h1>Build your range.</h1><p>A focused round today. A stronger recall tomorrow.</p></div>
      <section className={`profile-completion ${completion.percentage === 100 ? "complete" : ""}`} aria-labelledby="profile-completion-title">
        <div><h2 id="profile-completion-title">{completion.percentage === 100 ? "Profile complete" : "Complete your profile"}</h2><p>{completion.percentage === 100 ? "Your scholar record is complete and up to date." : `${completion.percentage}% complete`}</p></div>
        <strong>{completion.percentage}%</strong>
        <div className="profile-completion-track" role="progressbar" aria-label="Profile completion" aria-valuemin={0} aria-valuemax={100} aria-valuenow={completion.percentage}><i style={{ width: `${completion.percentage}%` }} /></div>
        {completion.missing.length > 0 && <p className="profile-missing">Missing: {completion.missing.join(", ")}.</p>}
        {completion.percentage < 100 && <button className="secondary" onClick={() => go("profile")}>Complete profile <ArrowRight /></button>}
      </section>
      <div className="daily-layout">
        <section className="daily-edition">
          <div className="edition-stamp"><span>Daily set</span><small>Edition</small><strong>{edition}</strong><b>History</b></div>
          <div className="daily-copy">
            <h2>{done ? "Daily goal complete" : "Your daily 10"}</h2>
            <p>{done ? "Your streak is secure. Open another edition to keep building depth." : "Ten History clues selected across eras, regions, and formats."}</p>
            <div className="edition-meta"><span>10 questions</span><span>History archive</span><span>Up to 145 XP</span></div>
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
        <Stat icon={<Flame />} label="Current streak" value={formatDays(stats.streak)} note={`Best ${formatDays(Math.max(stats.longest, stats.streak))}`} />
        <Stat icon={<Zap />} label="Total XP" value={stats.xp.toLocaleString()} note="Your lifetime score" />
        <Stat icon={<Target />} label="Overall accuracy" value={`${accuracy}%`} note={`Across ${stats.answered} questions`} />
      </div>
      <SectionTitle label="Subject collection" action="View all" onAction={() => go("categories")} />
      <div className="edition-grid">
        {categories.slice(0, 6).map(([category], index) => { const categoryData=data?.categories.find(row=>row.category===category); return (
          <button className="edition-card" onClick={() => start(category)} key={category}>
            <span className="edition-number"><small>Edition</small>{String(index + 1).padStart(2, "0")}</span>
            <span className="edition-name"><strong>{category}</strong><small>{categoryData?`${categoryData.attempts} attempted`:'Unrated'}</small></span>
            <b>{categoryData?.accuracy==null?'—':`${categoryData.accuracy}%`}</b><ArrowRight />
          </button>
        );})}
      </div>
      <div className="dashboard-lower">
        <section className="recommendation"><span className="edition-tab">{String(Math.max(1,data?.categories.length||1)).padStart(2,'0')}</span><div><h2>{data?.categories.filter(row=>row.attempts>=10).sort((a,b)=>(a.accuracy||0)-(b.accuracy||0))[0]?.category?`Strengthen ${data.categories.filter(row=>row.attempts>=10).sort((a,b)=>(a.accuracy||0)-(b.accuracy||0))[0].category}`:'Build your first category record'}</h2><p>{data?.overall.attempted?"Your live record identifies the next useful practice area.":"Complete a set to unlock evidence-based recommendations."}</p></div><button className="secondary" onClick={() => start(data?.categories.filter(row=>row.attempts>=10).sort((a,b)=>(a.accuracy||0)-(b.accuracy||0))[0]?.category)}>Start focused practice <ArrowRight /></button></section>
        <section className="rank-record"><Trophy /><span><small>Completed sets</small><strong>{data?.overall.quizzesCompleted||0}</strong><b>{data?.overall.timedOut||0} timed-out answers</b></span></section>
      </div>
      <SectionTitle label="Category pulse" action="Full progress" onAction={() => go("progress")} />
      <div className="pulse">
        {(data?.categories.slice(0,4)||[]).map((row) => (
          <section key={row.category}><span>{row.category}<b>{row.accuracy==null?'—':`${row.accuracy}%`}</b></span><i><b style={{ width: `${row.accuracy||0}%` }} /></i><small>{row.attempts} saved attempts</small></section>
        ))}
        {!data?.categories.length&&<p className="empty-record">Category performance appears after your first practice set.</p>}
      </div>
    </>
  );
}

function Categories({ start, data }: { start: (category?: string) => void; data: CategoryStat[] }) {
  const indexed = new Map(data.map((row) => [row.category, row]));
  return <><Title over="Targeted practice" title="Choose an edition." sub="Every measure below comes from your own completed practice." /><div className="category-list">{categories.map(([category, description], index) => {
    const stat = indexed.get(category);
    return (
    <button className="category-row" onClick={() => start(category)} key={category}>
      <span className="edition-number"><small>Edition</small>{String(index + 1).padStart(2, "0")}</span>
      <span className="category-copy"><strong>{category}</strong><small>{description}</small></span>
      <span className="category-count">{stat ? `${stat.attempts} attempted · ${stat.mastery}` : "Unrated · No attempts"}</span><span className="category-score">{stat?.accuracy == null ? "—" : `${stat.accuracy}%`}</span><ChevronRight />
    </button>
  );})}</div></>;
}

function Practice({
  q, i, total, title, input, setInput, feedback, submit, next, saving,
  checking, loading, error, startedAt, exit,
}: {
  q?: Question;
  i: number;
  total: number;
  title: string;
  input: string;
  setInput: (value: string) => void;
  feedback: AnswerCheck | null;
  submit: (timedOut?: boolean) => Promise<void>;
  next: (questionId: string) => void;
  saving: boolean;
  checking: boolean;
  loading: boolean;
  error: string;
  startedAt: string;
  exit: () => void;
}) {
  const [remaining, setRemaining] = useState(QUESTION_TIME_LIMIT_MS);
  const expirationSubmitted = useRef(false);

  useEffect(() => {
    expirationSubmitted.current = false;
    setRemaining(QUESTION_TIME_LIMIT_MS);
  }, [q?.id, startedAt]);

  useEffect(() => {
    if (!q || feedback) return;

    const deadline = Date.parse(startedAt) + QUESTION_TIME_LIMIT_MS;
    const tick = () => setRemaining(Math.max(0, deadline - Date.now()));
    tick();
    const timer = window.setInterval(tick, 100);
    return () => window.clearInterval(timer);
  }, [q?.id, feedback, startedAt]);

  useEffect(() => {
    if (!q || feedback || remaining > 0 || checking || expirationSubmitted.current) return;
    expirationSubmitted.current = true;
    void submit(true);
  }, [q, feedback, remaining, checking, submit]);

  useEffect(() => {
    if (!feedback || remaining > 0) return;
    const questionId = q?.id;
    if (!questionId) return;
    const timer = window.setTimeout(() => next(questionId), TIMED_OUT_FEEDBACK_MS);
    return () => window.clearTimeout(timer);
  }, [feedback, remaining, next, q?.id]);
  if (loading && !q) {
    return <div className="assessment-loading" role="status" aria-live="polite" aria-busy="true">
      <LoaderCircle aria-hidden="true" />
      <strong>Loading assessment...</strong>
      <span>Preparing your first question</span>
    </div>;
  }

  if (!q) {
    return <div className="practice">
      <div className="practice-top"><button onClick={exit} aria-label="Exit practice" title="Exit practice"><X /></button><div><span>{title}</span></div><strong>00 / 00</strong></div>
      <article className="question-sheet question-state" aria-live="polite">
        <BookOpen />
        <h1>This edition could not be opened.</h1>
        <p>{error || "No questions are available for this edition."}</p>
        <button className="secondary" onClick={exit}>Back to dashboard</button>
      </article>
    </div>;
  }

  const databaseQuestion = isDatabaseQuestion(q);
  const prompt = databaseQuestion ? q.question : q.prompt;
  const topic = databaseQuestion ? `${q.subcategory} / ${q.difficulty}` : q.topic;
  const questionType = databaseQuestion ? q.questionType : "short_answer";
  const options = databaseQuestion ? q.options : [];
  const usesOptions = questionType === "multiple_choice" || questionType === "true_false";
  const timeExpired = remaining <= 0;
  const timeRemainingRatio = Math.max(0, Math.min(1, remaining / QUESTION_TIME_LIMIT_MS));
  const editionIndex = Math.max(0, categories.findIndex(([category]) => category === q.category));
  const edition = String(editionIndex + 1).padStart(2, "0");
  const correctAnswer = feedback
    ? typeof feedback.correctAnswer === "boolean"
      ? feedback.correctAnswer ? "True" : "False"
      : feedback.correctAnswer
    : "";

  return <div className="practice">
    <div className="practice-top"><button onClick={exit} aria-label="Exit practice" title="Exit practice"><X /></button><div><span>{title}</span><div className="practice-progress" style={{ "--segments": total } as React.CSSProperties} aria-label={`Question ${i + 1} of ${total}`}>{Array.from({ length: total }).map((_, index) => <i className={index < i ? "done" : index === i ? "now" : ""} key={index} />)}</div></div><strong>{String(i + 1).padStart(2, "0")} / {String(total).padStart(2, "0")}</strong></div>
    <article className="question-sheet"><div className={`question-timer ${remaining <= 5000 ? "urgent" : ""} ${timeExpired ? "expired" : ""}`} role="timer" aria-live="off" aria-label={timeExpired ? "Time expired" : `${Math.ceil(remaining / 1000)} seconds remaining`}><span><Clock3 aria-hidden="true" /> {timeExpired ? "Time expired" : "Time remaining"}</span><strong>{(remaining / 1000).toFixed(1)}s</strong><div className="question-timer-track" aria-hidden="true"><span className="question-timer-fill" style={{ transform: `scaleX(${timeRemainingRatio})` }} /></div></div><div className="question-label"><span>Edition {edition}</span><b>{q.category}</b><small>{topic}</small></div><h1>{prompt}</h1>
      {feedback === null ? <form onSubmit={(event) => { event.preventDefault(); void submit(); }}>
        {usesOptions
          ? <fieldset className="answer-options"><legend>Choose one answer</legend>{options.map((option, index) => {
              const value = questionType === "true_false" ? option.toLowerCase() : option;
              return <button className={input === value ? "selected" : ""} type="button" onClick={() => setInput(value)} disabled={checking || timeExpired} aria-pressed={input === value} key={option}><span>{String.fromCharCode(65 + index)}</span>{option}</button>;
            })}</fieldset>
          : <label>{questionType === "fill_in_the_blank" ? "Complete the blank" : "Your answer"}<input autoFocus value={input} onChange={(event) => setInput(event.target.value)} placeholder={questionType === "fill_in_the_blank" ? "Type the missing word or phrase" : "Type your answer"} maxLength={200} disabled={checking || timeExpired} /></label>}
        {error && <p className="question-error" role="alert">{error}</p>}
        <button className="primary primary-ink" disabled={!input.trim() || checking || timeExpired}>{timeExpired ? "Time expired" : checking ? "Checking answer" : "Submit answer"} <ArrowRight /></button>
      </form>
        : <div className={`feedback ${feedback.correct ? "correct" : "wrong"}`}><div className="feedback-title"><span>{feedback.correct ? <Check /> : <X />}</span><div><small>{feedback.correct ? "Correct / +10 XP" : "Not quite"}</small><h2>{feedback.correct ? "Nice recall." : `Answer: ${correctAnswer}`}</h2></div></div><section><strong>Why it matters</strong><p>{feedback.explanation}</p></section><button className="primary primary-ink" disabled={saving} onClick={() => next(q.id)}>{saving ? "Saving progress" : i + 1 === total ? "See results" : "Next question"}<ArrowRight /></button></div>}
    </article><button className="report"><CircleHelp /> Report this question</button>
  </div>;
}

function Progress({ data, reload, start }: { data: ProductData | null; reload: (days?: number) => Promise<void>; start: (category?: string) => void }) {
  const [days, setDays] = useState(30);
  if (!data) return <div className="assessment-loading" role="status"><LoaderCircle /><strong>Loading your progress...</strong></div>;
  const o = data.overall;
  if (!o.attempted) return <><Title over="Your record" title="Progress starts with practice." sub="Complete your first set to begin building a trustworthy record."/><button className="primary primary-ink" onClick={() => start()}>Start practice <ArrowRight/></button></>;
  return <><Title over="Your record" title="Progress, indexed." sub="Live performance calculated from your saved attempts."/><div className="progress-filters" aria-label="Progress range">{[7,30,90,0].map(value=><button className={days===value?"active":""} key={value} onClick={()=>{setDays(value);void reload(value);}}>{value||"All"}{value?" days":" time"}</button>)}</div><div className="kpis metric-ledger">
    <Stat icon={<BookOpen/>} label="Attempted" value={String(o.attempted)} note={`${o.correct} correct · ${o.incorrect} incorrect`}/><Stat icon={<Target/>} label="Accuracy" value={o.accuracy==null?"—":`${o.accuracy}%`} note={`${o.timedOut} timed out`}/><Stat icon={<Clock3/>} label="Average response" value={o.averageResponseMs==null?"—":`${(o.averageResponseMs/1000).toFixed(1)}s`} note={`${o.quizzesCompleted} completed sets`}/><Stat icon={<Zap/>} label="Lifetime XP" value={o.xp.toLocaleString()} note={`Best streak ${o.longestStreak} days`}/>
  </div><section className="trend-ledger"><div className="section-heading-static"><h2>Practice over time</h2></div>{data.timeline.length?data.timeline.map(row=><div key={row.day}><time>{new Date(row.day).toLocaleDateString(undefined,{month:"short",day:"numeric"})}</time><i><b style={{width:`${Math.max(4,Math.min(100,row.attempted*3))}%`}}/></i><span>{row.attempted} questions</span><strong>{row.attempted?Math.round(100*row.correct/row.attempted):0}%</strong><small>+{row.xp} XP</small></div>):<p className="empty-record">No activity in this range.</p>}</section><section className="mastery"><div className="section-heading-static"><h2>Accuracy by category</h2></div>{data.categories.map((row,index)=><div key={row.category}><span className="row-index">{String(index+1).padStart(2,"0")}</span><strong>{row.category}<small>{row.mastery}</small></strong><i><b style={{width:`${row.accuracy||0}%`}}/></i><b>{row.accuracy==null?"—":`${row.accuracy}%`}</b><small>{row.attempts} answered</small></div>)}</section></>;
}

function Leaders() {
  const [period, setPeriod] = useState<LeaderboardPeriod>("weekly");
  const [scope, setScope] = useState<"global"|"friends">("global");
  const [leaders, setLeaders] = useState<LeaderboardEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const controller = new AbortController();
    const loadLeaders = async () => {
      setLoading(true);
      setError("");
      try {
        const response = await fetch(`/api/leaderboard?period=${period}&scope=${scope}`, {
          cache: "no-store",
          signal: controller.signal,
        });
        const data = await readApiResponse<{ leaders: LeaderboardEntry[] }>(response, "The leaderboard could not be loaded.");
        setLeaders(data.leaders);
      } catch (loadError) {
        if (!controller.signal.aborted) {
          setError(loadError instanceof Error ? loadError.message : "The leaderboard could not be loaded.");
        }
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    };
    void loadLeaders();
    return () => controller.abort();
  }, [period, scope]);

  return <>
    <Title over="Friendly competition" title={scope === "friends" ? "Friends leaderboard." : period === "weekly" ? "Weekly leaderboard." : "All-time leaderboard."} sub={scope === "friends" ? "Only you and accepted friends appear here." : period === "weekly" ? "Rankings reset every Monday. Learn consistently and the points follow." : "Lifetime XP across every QuizForge scholar."} />
    <div className="tabs" role="tablist" aria-label="Leaderboard scope"><button role="tab" aria-selected={scope==="global"} onClick={()=>setScope("global")}>Global</button><button role="tab" aria-selected={scope==="friends"} onClick={()=>{setScope("friends");setPeriod("weekly");}}>Friends</button></div>
    <div className="tabs" role="tablist" aria-label="Leaderboard period">
      <button role="tab" aria-selected={period === "weekly"} onClick={() => setPeriod("weekly")}>This week</button>
      {scope === "global" && <button role="tab" aria-selected={period === "all_time"} onClick={() => setPeriod("all_time")}>All time</button>}
    </div>
    <div className="leaders" aria-live="polite" aria-busy={loading}>
      <div className="leader-header" aria-hidden="true"><span>Rank</span><span>Scholar</span><span>Level</span><span>Score</span></div>
      {loading && <div className="leader-state"><LoaderCircle /><strong>Loading rankings...</strong></div>}
      {!loading && error && <div className="leader-state leader-error"><strong>Rankings unavailable</strong><span>{error}</span><button className="secondary" onClick={() => setPeriod((current) => current === "weekly" ? "all_time" : "weekly")}>Try another period</button></div>}
      {!loading && !error && leaders.length === 0 && <div className="leader-state"><strong>No scores yet</strong><span>Complete a practice set to open the rankings.</span></div>}
      {!loading && !error && leaders.map((entry) => {
        const initials = entry.display_name.split(/\s+/).filter(Boolean).map((part) => part[0]).join("").slice(0, 2).toUpperCase() || "QF";
        return <div className={entry.is_current_user ? "you" : ""} key={entry.username}>
          <b>#{entry.rank}</b><span className="leader-avatar">{initials}</span>
          <p><strong>{entry.is_current_user ? `${entry.display_name} (You)` : entry.display_name}</strong><small>@{entry.username}</small></p>
          <strong>{entry.xp.toLocaleString()} <small>XP</small></strong>
        </div>;
      })}
    </div>
  </>;
}

function Profile({ stats, accuracy, profile, data, save, saving, message, signOut }: { stats: Stats; accuracy: number; profile: UserProfile; data: ProductData | null; save: (event: React.FormEvent<HTMLFormElement>) => void; saving: boolean; message: string; signOut: () => void }) {
  const initials = profile.display_name.split(" ").map((name) => name[0]).join("").slice(0, 2).toUpperCase();
  const referralLink = data?.referral.code ? `/signup?ref=${data.referral.code}` : "";
  return <><Title over="Your account" title="Scholar profile." sub="Your live QuizForge identity, achievements, and performance." /><div className="profile"><section className="profile-record"><span className="profile-avatar">{initials}</span><p className="micro-label">QuizForge scholar</p><h2>{profile.display_name}</h2><p>@{profile.username}</p><div><span><strong>{stats.xp.toLocaleString()}</strong>XP</span><span><strong>{stats.answered}</strong>Answers</span><span><strong>{accuracy}%</strong>Accuracy</span></div></section><section className="profile-settings"><div className="section-heading-static"><h2><Settings /> Profile details</h2><p>Keep your private contact details and scholar identity current.</p></div>{message && <p className="profile-save-message" role="status">{message}</p>}<form onSubmit={save}><div className="profile-field-grid"><label>Display name<input name="displayName" required maxLength={40} defaultValue={profile.display_name} /></label><label>Username<input name="username" required minLength={3} maxLength={24} pattern="[a-z0-9_]+" defaultValue={profile.username} /></label><label>Email address<input name="email" type="email" autoComplete="email" maxLength={254} defaultValue={profile.email} /></label><label>Phone number<input name="phone" type="tel" autoComplete="tel" maxLength={20} pattern="\+?[0-9][0-9 ()-]{6,19}" title="Enter 7 to 20 digits; spaces, parentheses, and hyphens are allowed." defaultValue={profile.phone} /></label><label>Age<input name="age" type="number" inputMode="numeric" min={13} max={120} defaultValue={profile.age ?? ""} /></label><label>Gender<select name="gender" defaultValue={profile.gender}><option value="">Select an option</option><option value="woman">Woman</option><option value="man">Man</option><option value="non_binary">Non-binary</option><option value="prefer_not_to_say">Prefer not to say</option></select></label></div><div className="form-actions"><button className="primary primary-ink" type="submit" disabled={saving}>{saving ? "Saving changes" : "Save changes"}</button><button className="profile-signout" type="button" onClick={signOut}>Sign out</button></div></form></section></div>
  <div className="profile-grid"><section className="record-panel"><div className="section-heading-static"><h2><Award/> Earned badges</h2><p>{data?.badges.length||0} milestones unlocked</p></div>{data?.badges.length?<div className="badge-grid">{data.badges.map(badge=><div key={badge.key}><Award/><strong>{badge.name}</strong><p>{badge.description}</p><small>Earned {new Date(badge.earnedAt).toLocaleDateString()}</small></div>)}</div>:<p className="empty-record">Your first badge will appear after a qualifying milestone.</p>}</section><section className="record-panel invite-panel"><div className="section-heading-static"><h2><Users/> Invite friends</h2><p>Earn 100 XP when an invited scholar completes a set.</p></div><strong className="referral-code">{data?.referral.code||"Preparing code"}</strong><p>{data?.referral.qualified||0} qualified referrals</p><button className="secondary" disabled={!referralLink} onClick={()=>void navigator.clipboard.writeText(`${window.location.origin}${referralLink}`)}>Copy referral link</button></section></div>
  <section className="activity-ledger"><div className="section-heading-static"><h2>Recent activity</h2></div>{data?.recentActivity.length?data.recentActivity.map(item=><div key={`${item.at}-${item.label}`}><time>{new Date(item.at).toLocaleDateString()}</time><strong>{item.label}</strong><span>{item.detail}</span></div>):<p className="empty-record">Complete a practice set to create activity.</p>}</section></>;
}

type FriendData={friends:Array<{id:string;username:string;displayName:string;xp:number;streak:number;accuracy:number|null;weeklyXp:number}>;incoming:Array<{id:string;userId:string;username:string;displayName:string}>;outgoing:Array<{id:string;userId:string;username:string;displayName:string}>};
function Friends({referralCode}:{referralCode?:string}) {
  const [data,setData]=useState<FriendData|null>(null);const [results,setResults]=useState<Array<{id:string;username:string;displayName:string;xp:number;streak:number}>>([]);const [error,setError]=useState("");
  const load=async()=>{try{const response=await fetch('/api/friends',{cache:'no-store'});setData(await readApiResponse<FriendData>(response,'Friends could not be loaded.'));setError('');}catch(e){setError(e instanceof Error?e.message:'Friends could not be loaded.');}};
  useEffect(()=>{void load();},[]);
  const act=async(action:string,target:string)=>{try{const response=await fetch('/api/friends',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,target})});await readApiResponse<{ok:boolean}>(response,'Friend action failed.');await load();}catch(e){setError(e instanceof Error?e.message:'Friend action failed.');}};
  const search=async(event:React.FormEvent<HTMLFormElement>)=>{event.preventDefault();const query=String(new FormData(event.currentTarget).get('search')||'').trim();if(!query)return;try{const response=await fetch(`/api/friends?search=${encodeURIComponent(query)}`);setResults(await readApiResponse<Array<{id:string;username:string;displayName:string;xp:number;streak:number}>>(response,'Search failed.'));}catch(e){setError(e instanceof Error?e.message:'Search failed.');}};
  return <><Title over="Your circle" title="Practice with friends." sub="Find scholars by username, manage requests, and compare real weekly progress."/>{error&&<div className="app-error" role="alert">{error}</div>}<form className="friend-search" onSubmit={search}><label>Find by username<input name="search" maxLength={40} placeholder="Search QuizForge scholars"/></label><button className="primary primary-ink">Search</button></form>{results.length>0&&<section className="people-ledger">{results.map(user=><div key={user.id}><span className="leader-avatar">{user.displayName.slice(0,2).toUpperCase()}</span><p><strong>{user.displayName}</strong><small>@{user.username} · {user.xp.toLocaleString()} XP</small></p><button className="secondary" onClick={()=>void act('send',user.id)}>Add friend</button></div>)}</section>}<div className="friends-layout"><section className="record-panel"><div className="section-heading-static"><h2>Friends</h2><p>{data?.friends.length||0} accepted</p></div>{data?.friends.length?data.friends.map(friend=><div className="friend-row" key={friend.id}><p><strong>{friend.displayName}</strong><small>@{friend.username}</small></p><span><b>{friend.weeklyXp}</b> weekly XP</span><span><b>{friend.accuracy??'—'}{friend.accuracy!=null?'%':''}</b> accuracy</span><button onClick={()=>void act('remove',friend.id)}>Remove</button></div>):<p className="empty-record">No friends yet. Search for a scholar or share your referral code.</p>}</section><section className="record-panel"><div className="section-heading-static"><h2>Requests</h2></div>{data?.incoming.map(request=><div className="request-row" key={request.id}><p><strong>{request.displayName}</strong><small>@{request.username}</small></p><button onClick={()=>void act('accept',request.id)}>Accept</button><button onClick={()=>void act('decline',request.id)}>Decline</button></div>)}{!data?.incoming.length&&<p className="empty-record">No incoming requests.</p>}<small>Your invite code: <strong>{referralCode||'—'}</strong></small></section></div></>;
}

function NotificationSettings({data,reload}:{data?:ProductData['notifications'];reload:(days?:number)=>Promise<void>}){
 const [message,setMessage]=useState('');const save=async(event:React.FormEvent<HTMLFormElement>)=>{event.preventDefault();const form=new FormData(event.currentTarget);const body={enabled:form.get('enabled')==='on',time:String(form.get('time')),timezone:String(form.get('timezone'))};try{const response=await fetch('/api/notifications',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});await readApiResponse<{ok:boolean}>(response,'Reminder settings could not be saved.');setMessage('Reminder settings saved.');await reload();}catch(e){setMessage(e instanceof Error?e.message:'Reminder settings could not be saved.');}};
 return <><Title over="Preferences" title="Notification settings." sub="Daily practice reminders are optional and always under your control."/>{message&&<div className="app-error" role="status">{message}</div>}<section className="settings-sheet"><div><Bell/><h2>Daily practice reminder</h2><p>We will skip the email whenever your daily set is already complete.</p></div><form onSubmit={save}><label className="check-row"><input type="checkbox" name="enabled" defaultChecked={data?.enabled}/> Email reminders enabled</label><label>Reminder time<input type="time" name="time" required defaultValue={data?.time?.slice(0,5)||'18:00'}/></label><label>Timezone<input name="timezone" required maxLength={80} defaultValue={data?.timezone||Intl.DateTimeFormat().resolvedOptions().timeZone}/></label><button className="primary primary-ink">Save reminder settings</button></form></section></>;
}

function Results({ answers, daily, xp, start, home }: { answers: Answer[]; daily: boolean; xp: number; start: (category?: string) => void; home: () => void }) {
  const correct = answers.filter((answer) => answer.correct).length;
  const accuracy = Math.round((correct / answers.length) * 100);
  return <div className="results"><div className="results-mark"><Trophy /></div><h1>That round is in the books.</h1><p>You showed up, tested your recall, and left sharper.</p><div className="results-ledger"><span><strong>{correct}/{answers.length}</strong>Correct</span><span><strong>+{xp}</strong>XP earned</span><span><strong>{accuracy}%</strong>Accuracy</span></div><section className="result-note"><Flame /><p><strong>{daily ? "Your daily streak is secure" : "Targeted work pays off"}</strong><small>{daily ? "Come back tomorrow to keep it moving." : "Your progress has been updated."}</small></p></section><div className="result-actions"><button className="primary primary-ink" onClick={() => start("Literature")}>Practice a weak area <ArrowRight /></button><button className="secondary" onClick={home}>Back to dashboard</button></div></div>;
}

function Title({ title, sub }: { over: string; title: string; sub: string }) { return <div className="page-heading"><h1>{title}</h1><p>{sub}</p></div>; }
function SectionTitle({ label, action, onAction }: { label: string; action: string; onAction: () => void }) { return <div className="section-title"><h2>{label}</h2><button onClick={onAction}>{action} <ArrowRight /></button></div>; }
function Stat({ icon, label, value, note }: { icon: React.ReactNode; label: string; value: string; note: string }) { return <div className="stat"><span className="stat-label">{label}</span><strong>{value}</strong><small>{icon}{note}</small></div>; }
