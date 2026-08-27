import Link from "next/link";

export function AdminHeader({ title, description, action }: { title: string; description: string; action?: React.ReactNode }) {
  return <header className="admin-page-header"><div><h1>{title}</h1><p>{description}</p></div>{action}</header>;
}

export function Metric({ label, value, note }: { label: string; value: string | number; note?: string }) {
  return <div className="admin-metric"><span>{label}</span><strong>{value}</strong>{note && <small>{note}</small>}</div>;
}

export function Notice({ error, message }: { error?: string; message?: string }) {
  if (!error && !message) return null;
  return <div className={`admin-alert ${error ? "error" : "success"}`} role={error ? "alert" : "status"}>{error || message}</div>;
}

export function Pagination({ base, page, totalPages, params }: { base: string; page: number; totalPages: number; params: Record<string, string> }) {
  const href = (next: number) => `${base}?${new URLSearchParams({ ...params, page: String(next) })}`;
  return <nav className="admin-pagination" aria-label="Pagination"><span>Page {page} of {Math.max(1, totalPages)}</span><div>
    {page > 1 ? <Link href={href(page - 1)}>Previous</Link> : <span>Previous</span>}
    {page < totalPages ? <Link href={href(page + 1)}>Next</Link> : <span>Next</span>}
  </div></nav>;
}

export function StatusBadge({ value }: { value?: string | null }) {
  const status = typeof value === "string" && value.trim() ? value.trim() : "unknown";
  const className = status.toLowerCase().replaceAll("_", "-").replaceAll(" ", "-");
  const label = status.replaceAll("_", " ");

  return <span className={`admin-status ${className}`}>{label}</span>;
}
