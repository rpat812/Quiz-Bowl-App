import { AdminHeader } from "@/components/admin/ui";
import { requireAdmin } from "@/lib/admin/auth";
import { adminRpc, formatAdminDate } from "@/lib/admin/data";

type AuditRow={id:number;admin:string;action:string;resourceType:string;resourceId:string|null;createdAt:string};
export default async function AuditLog(){await requireAdmin("audit.view");const data=await adminRpc<AuditRow[]>("admin_audit_data",{p_limit:100});return <><AdminHeader title="Audit log" description="Append-only history of privileged changes made through the admin console."/><div className="admin-table-wrap"><table className="admin-table"><thead><tr><th>Time</th><th>Admin</th><th>Action</th><th>Resource</th><th>Resource ID</th></tr></thead><tbody>{data.map(row=><tr key={row.id}><td>{formatAdminDate(row.createdAt)}</td><td>@{row.admin}</td><td><code>{row.action}</code></td><td>{row.resourceType}</td><td>{row.resourceId||"—"}</td></tr>)}</tbody></table>{!data.length&&<p className="admin-empty">No admin actions have been recorded.</p>}</div></>}
