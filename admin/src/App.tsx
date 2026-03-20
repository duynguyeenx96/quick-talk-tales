import { useState, useEffect, useCallback } from 'react';
import {
  login,
  fetchStats,
  fetchUsers,
  fetchUserDetail,
  fetchOrders,
  updateSubscription,
  toggleUserActive,
  getCurrentUser,
  setOnForceLogout,
} from './api';
import type { Stats, User, Order } from './api';
import './App.css';

// ── Login ─────────────────────────────────────────────────────────────────────
function LoginPage({ onLogin }: { onLogin: (email: string, password: string) => Promise<void> }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async () => {
    if (!email || !password) return;
    setLoading(true);
    setError('');
    try {
      await onLogin(email, password);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-wrap">
      <div className="login-card">
        <h1>🛠️ Admin Dashboard</h1>
        <p className="sub">Quick Talk Tales</p>
        {error && <p className="err" style={{ margin: 0 }}>{error}</p>}
        <input
          type="email"
          placeholder="Admin email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSubmit()}
          autoComplete="username"
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSubmit()}
          autoComplete="current-password"
        />
        <button onClick={handleSubmit} disabled={loading}>
          {loading ? 'Signing in…' : 'Sign in'}
        </button>
      </div>
    </div>
  );
}

// ── Stat card ─────────────────────────────────────────────────────────────────
function StatCard({ label, value, icon }: { label: string; value: number | string; icon: string }) {
  return (
    <div className="stat-card">
      <span className="stat-icon">{icon}</span>
      <span className="stat-value">{value}</span>
      <span className="stat-label">{label}</span>
    </div>
  );
}

// ── User Detail Modal ─────────────────────────────────────────────────────────
function UserDetailModal({ userId, onClose, onChanged }: { userId: string; onClose: () => void; onChanged: () => void }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [subPlan, setSubPlan] = useState('premium');
  const [subDays, setSubDays] = useState(30);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const u = await fetchUserDetail(userId);
      setUser(u);
      setSubPlan(u.subscriptionPlan === 'premium' ? 'premium' : 'free');
    } catch { /* ignore */ }
    finally { setLoading(false); }
  }, [userId]);

  useEffect(() => { load(); }, [load]);

  const handleToggleActive = async () => {
    if (!user) return;
    const next = !user.isActive;
    if (!confirm(`${next ? 'Activate' : 'Deactivate'} this user?`)) return;
    setActionLoading(true);
    try {
      const updated = await toggleUserActive(user.id, next);
      setUser(updated);
      onChanged();
    } catch { alert('Action failed'); }
    finally { setActionLoading(false); }
  };

  const handleUpdateSub = async () => {
    if (!user) return;
    setActionLoading(true);
    try {
      await updateSubscription(user.id, subPlan as 'free' | 'premium', subPlan === 'premium' ? subDays : undefined);
      await load();
      onChanged();
    } catch { alert('Failed to update subscription'); }
    finally { setActionLoading(false); }
  };

  const fmt = (d?: string | null) => d ? new Date(d).toLocaleString() : '—';
  const fmtDate = (d?: string | null) => d ? new Date(d).toLocaleDateString() : '—';

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-box" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>👤 User Detail</h3>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>

        {loading ? (
          <p className="center-msg">Loading…</p>
        ) : !user ? (
          <p className="center-msg err">User not found</p>
        ) : (
          <div className="modal-body">
            {/* Avatar + name */}
            <div className="detail-avatar">
              <div className={`avatar-circle ${user.subscriptionPlan === 'premium' ? 'avatar-premium' : ''}`}>
                {(user.username[0] ?? '?').toUpperCase()}
              </div>
              <div>
                <div className="detail-name">{user.fullName || `@${user.username}`}</div>
                {user.fullName && <div className="detail-sub">@{user.username}</div>}
                <div className="badge-row">
                  <span className={`badge ${user.subscriptionPlan === 'premium' ? 'badge-premium' : 'badge-free'}`}>
                    {user.subscriptionPlan === 'premium' ? '⭐ Premium' : '🆓 Free'}
                  </span>
                  {user.isActive === false && <span className="badge badge-danger">BANNED</span>}
                </div>
              </div>
            </div>

            {/* Info grid */}
            <div className="detail-grid">
              <div className="detail-section">
                <h4>Account</h4>
                <table className="detail-table">
                  <tbody>
                    <tr><td>Email</td><td>{user.email} {user.emailVerified ? '✅' : '❌'}</td></tr>
                    <tr><td>Auth</td><td>{user.authProvider}</td></tr>
                    <tr><td>Status</td><td>{user.isActive !== false ? '🟢 Active' : '🔴 Banned'}</td></tr>
                    <tr><td>Joined</td><td>{fmtDate(user.createdAt)}</td></tr>
                    <tr><td>ID</td><td className="mono small">{user.id}</td></tr>
                  </tbody>
                </table>
              </div>

              <div className="detail-section">
                <h4>Subscription & Activity</h4>
                <table className="detail-table">
                  <tbody>
                    <tr><td>Plan</td><td>{user.subscriptionPlan}</td></tr>
                    <tr><td>Expires</td><td>{fmt(user.subscriptionExpiresAt)}</td></tr>
                    <tr><td>Streak</td><td>🔥 {user.currentStreak ?? 0} days</td></tr>
                    <tr><td>Best streak</td><td>🏆 {user.longestStreak ?? 0} days</td></tr>
                  </tbody>
                </table>
              </div>

              <div className="detail-section" style={{ gridColumn: '1 / -1' }}>
                <h4>Referral</h4>
                <table className="detail-table">
                  <tbody>
                    <tr>
                      <td>My code</td>
                      <td><code className="ref-code">{user.referralCode ?? '—'}</code></td>
                    </tr>
                    <tr>
                      <td>Referred by</td>
                      <td>
                        {user.referredByUsername
                          ? <><span className="ref-user">@{user.referredByUsername}</span> <span className="ref-id">({user.referredByUserId?.slice(0, 8)}…)</span></>
                          : <span style={{ color: '#94a3b8' }}>— (organic signup)</span>
                        }
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            {/* Actions */}
            <div className="detail-actions">
              <div className="action-block">
                <h4>Update Subscription</h4>
                <div className="action-row">
                  <select value={subPlan} onChange={(e) => setSubPlan(e.target.value)} disabled={actionLoading}>
                    <option value="free">Free</option>
                    <option value="premium">Premium</option>
                  </select>
                  {subPlan === 'premium' && (
                    <div className="days-picker">
                      <input
                        type="number"
                        min={1}
                        max={365}
                        value={subDays}
                        onChange={(e) => setSubDays(Number(e.target.value))}
                        disabled={actionLoading}
                      />
                      <span>days</span>
                    </div>
                  )}
                  <button className="btn-sm btn-success" onClick={handleUpdateSub} disabled={actionLoading}>
                    {actionLoading ? '…' : 'Apply'}
                  </button>
                </div>
              </div>

              <div className="action-block">
                <h4>Account Status</h4>
                <button
                  className={`btn-sm ${user.isActive !== false ? 'btn-danger' : 'btn-success'}`}
                  onClick={handleToggleActive}
                  disabled={actionLoading}
                >
                  {actionLoading ? '…' : user.isActive !== false ? '🚫 Deactivate' : '✅ Activate'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Users tab ─────────────────────────────────────────────────────────────────
function UsersTab() {
  const [data, setData] = useState<{ total: number; users: User[] } | null>(null);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [upgrading, setUpgrading] = useState<string | null>(null);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchUsers(search || undefined, page);
      setData(res);
    } catch {
      /* ignore */
    } finally {
      setLoading(false);
    }
  }, [search, page]);

  useEffect(() => { load(); }, [load]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    load();
  };

  const handleTogglePlan = async (user: User) => {
    const newPlan = user.subscriptionPlan === 'premium' ? 'free' : 'premium';
    setUpgrading(user.id);
    try {
      await updateSubscription(user.id, newPlan, 30);
      load();
    } catch {
      alert('Failed to update subscription');
    } finally {
      setUpgrading(null);
    }
  };

  const totalPages = data ? Math.ceil(data.total / 20) : 1;

  return (
    <div>
      {selectedUserId && (
        <UserDetailModal
          userId={selectedUserId}
          onClose={() => setSelectedUserId(null)}
          onChanged={load}
        />
      )}
      <form className="search-bar" onSubmit={handleSearch}>
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search by username or email…"
        />
        <button type="submit">Search</button>
        <button type="button" onClick={() => { setSearch(''); setPage(1); }}>Clear</button>
      </form>

      {loading ? (
        <p className="center-msg">Loading…</p>
      ) : (
        <>
          <p className="total-label">Total: {data?.total ?? 0} users</p>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Username</th>
                  <th>Email</th>
                  <th>Provider</th>
                  <th>Verified</th>
                  <th>Plan</th>
                  <th>Expires</th>
                  <th>Joined</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {(data?.users ?? []).map((u) => (
                  <tr key={u.id} className={u.isActive === false ? 'row-banned' : ''}>
                    <td>{u.username}</td>
                    <td className="email">{u.email}</td>
                    <td>{u.authProvider}</td>
                    <td>{u.emailVerified ? '✅' : '❌'}</td>
                    <td>
                      <span className={`badge ${u.subscriptionPlan === 'premium' ? 'badge-premium' : 'badge-free'}`}>
                        {u.subscriptionPlan === 'premium' ? '⭐ Premium' : 'Free'}
                      </span>
                    </td>
                    <td className="small">
                      {u.subscriptionExpiresAt
                        ? new Date(u.subscriptionExpiresAt).toLocaleDateString()
                        : '—'}
                    </td>
                    <td className="small">{new Date(u.createdAt).toLocaleDateString()}</td>
                    <td className="action-cell">
                      <button
                        className="btn-sm btn-view"
                        onClick={() => setSelectedUserId(u.id)}
                      >
                        👁 View
                      </button>
                      <button
                        className={`btn-sm ${u.subscriptionPlan === 'premium' ? 'btn-danger' : 'btn-success'}`}
                        disabled={upgrading === u.id}
                        onClick={() => handleTogglePlan(u)}
                      >
                        {upgrading === u.id
                          ? '…'
                          : u.subscriptionPlan === 'premium'
                          ? 'Revoke'
                          : 'Grant 30d'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="pagination">
            <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>← Prev</button>
            <span>Page {page} / {totalPages}</span>
            <button disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>Next →</button>
          </div>
        </>
      )}
    </div>
  );
}

// ── Orders tab ────────────────────────────────────────────────────────────────
function OrdersTab() {
  const [data, setData] = useState<{ total: number; orders: Order[] } | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchOrders(page);
      setData(res);
    } catch {
      /* ignore */
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => { load(); }, [load]);

  const totalPages = data ? Math.ceil(data.total / 20) : 1;

  const statusColor = (s: string) => {
    if (s === 'completed') return '#22c55e';
    if (s === 'expired') return '#ef4444';
    return '#f59e0b';
  };

  return (
    <div>
      {loading ? (
        <p className="center-msg">Loading…</p>
      ) : (
        <>
          <p className="total-label">Total: {data?.total ?? 0} orders</p>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Plan</th>
                  <th>Amount (VND)</th>
                  <th>Transfer Content</th>
                  <th>Status</th>
                  <th>Created</th>
                  <th>Paid At</th>
                </tr>
              </thead>
              <tbody>
                {(data?.orders ?? []).map((o) => (
                  <tr key={o.id}>
                    <td>{o.planId}</td>
                    <td>{o.amount.toLocaleString()}</td>
                    <td className="mono">{o.transferContent}</td>
                    <td>
                      <span style={{ color: statusColor(o.status), fontWeight: 600 }}>
                        ● {o.status}
                      </span>
                    </td>
                    <td className="small">{new Date(o.createdAt).toLocaleString()}</td>
                    <td className="small">{o.paidAt ? new Date(o.paidAt).toLocaleString() : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="pagination">
            <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>← Prev</button>
            <span>Page {page} / {totalPages}</span>
            <button disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>Next →</button>
          </div>
        </>
      )}
    </div>
  );
}

// ── Main App ──────────────────────────────────────────────────────────────────
export default function App() {
  const [authed, setAuthed] = useState(false);
  const [tab, setTab] = useState<'dashboard' | 'users' | 'orders'>('dashboard');
  const [stats, setStats] = useState<Stats | null>(null);
  const [statsErr, setStatsErr] = useState('');

  const handleLogin = async (email: string, password: string) => {
    await login(email, password);
    // Verify the account is actually admin role
    const profile = await getCurrentUser();
    if (profile.role !== 'admin') {
      throw new Error('Access denied: account is not an admin');
    }
    // Register force-logout: fires when refresh token expires
    setOnForceLogout(() => {
      setAuthed(false);
      setStats(null);
    });
    const s = await fetchStats();
    setStats(s);
    setAuthed(true);
  };

  if (!authed) return <LoginPage onLogin={handleLogin} />;

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="brand">🛠️ Admin</div>
        <nav>
          {(['dashboard', 'users', 'orders'] as const).map((t) => (
            <button
              key={t}
              className={`nav-item ${tab === t ? 'active' : ''}`}
              onClick={() => setTab(t)}
            >
              {t === 'dashboard' ? '📊 Dashboard' : t === 'users' ? '👥 Users' : '🧾 Orders'}
            </button>
          ))}
        </nav>
      </aside>

      <main className="main">
        {tab === 'dashboard' && (
          <div>
            <h2>Dashboard</h2>
            {statsErr && <p className="err">{statsErr}</p>}
            <div className="stats-grid">
              <StatCard label="Total Users" value={stats?.totalUsers ?? '—'} icon="👥" />
              <StatCard label="Premium Users" value={stats?.premiumUsers ?? '—'} icon="⭐" />
              <StatCard label="Total Orders" value={stats?.totalOrders ?? '—'} icon="🧾" />
              <StatCard label="Completed Payments" value={stats?.completedOrders ?? '—'} icon="✅" />
            </div>
            <button
              className="btn-refresh"
              onClick={async () => {
                try {
                  setStatsErr('');
                  setStats(await fetchStats());
                } catch {
                  setStatsErr('Failed to refresh stats');
                }
              }}
            >
              🔄 Refresh Stats
            </button>
          </div>
        )}
        {tab === 'users' && (
          <div>
            <h2>Users</h2>
            <UsersTab />
          </div>
        )}
        {tab === 'orders' && (
          <div>
            <h2>Payment Orders</h2>
            <OrdersTab />
          </div>
        )}
      </main>
    </div>
  );
}
