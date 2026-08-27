import { AdminNav } from "@/components/admin/admin-nav";
import { requireAdmin } from "@/lib/admin/auth";
import "../../admin.css";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const access = await requireAdmin();
  return <div className="admin-app"><AdminNav access={access} /><main className="admin-main"><div className="admin-topbar"><span>Internal operations</span><strong>{access.username}</strong></div><div className="admin-content">{children}</div></main></div>;
}
