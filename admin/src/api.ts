import axios from 'axios';
import type { AxiosRequestConfig } from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

// Tokens stored only in memory (not localStorage) — cleared on page refresh
let _accessToken = '';
let _refreshToken = '';
let _onForceLogout: (() => void) | null = null;

export function setOnForceLogout(cb: () => void) {
  _onForceLogout = cb;
}

export function getToken() {
  return _accessToken;
}

const api = axios.create({ baseURL: BASE_URL });

// ── Request interceptor: attach access token ──────────────────────────────────
api.interceptors.request.use((config) => {
  if (_accessToken) config.headers['Authorization'] = `Bearer ${_accessToken}`;
  return config;
});

// ── Response interceptor: 401 → silent refresh → retry ───────────────────────
let _isRefreshing = false;
let _refreshQueue: Array<(token: string) => void> = [];

api.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original: AxiosRequestConfig & { _retry?: boolean } = error.config;
    if (error.response?.status !== 401 || original._retry) {
      return Promise.reject(error);
    }
    original._retry = true;

    if (_isRefreshing) {
      // Queue this request until refresh completes
      return new Promise((resolve, reject) => {
        _refreshQueue.push((token) => {
          original.headers = { ...original.headers, Authorization: `Bearer ${token}` };
          resolve(api(original));
        });
      });
    }

    _isRefreshing = true;
    try {
      const res = await axios.post(`${BASE_URL}/auth/refresh`, { refreshToken: _refreshToken });
      _accessToken = res.data.accessToken;
      if (res.data.refreshToken) _refreshToken = res.data.refreshToken;

      // Flush queued requests
      _refreshQueue.forEach((cb) => cb(_accessToken));
      _refreshQueue = [];

      original.headers = { ...original.headers, Authorization: `Bearer ${_accessToken}` };
      return api(original);
    } catch {
      _refreshQueue = [];
      _accessToken = '';
      _refreshToken = '';
      _onForceLogout?.();
      return Promise.reject(error);
    } finally {
      _isRefreshing = false;
    }
  },
);

export const login = async (email: string, password: string): Promise<void> => {
  const res = await axios.post(`${BASE_URL}/auth/login`, { email, password });
  const { accessToken, refreshToken } = res.data;
  if (!accessToken) throw new Error('No access token returned');
  _accessToken = accessToken;
  _refreshToken = refreshToken ?? '';
};

export interface Stats {
  totalUsers: number;
  premiumUsers: number;
  totalOrders: number;
  completedOrders: number;
}

export interface User {
  id: string;
  username: string;
  email: string;
  fullName: string | null;
  subscriptionPlan: string;
  subscriptionExpiresAt: string | null;
  emailVerified: boolean;
  authProvider: string;
  createdAt: string;
  isActive?: boolean;
  currentStreak?: number;
  longestStreak?: number;
  referralCode?: string | null;
  referredByUserId?: string | null;
  referredByUsername?: string | null;
}

export interface UsersResponse {
  total: number;
  page: number;
  limit: number;
  users: User[];
}

export interface Order {
  id: string;
  userId: string;
  planId: string;
  amount: number;
  transferContent: string;
  status: string;
  expiresAt: string;
  paidAt: string | null;
  sepayTransactionId: string | null;
  createdAt: string;
}

export interface OrdersResponse {
  total: number;
  page: number;
  limit: number;
  orders: Order[];
}

export const fetchStats = () => api.get<Stats>('/admin/stats').then((r) => r.data);

export const fetchUserDetail = (id: string) =>
  api.get<User>(`/admin/users/${id}`).then((r) => r.data);

export const toggleUserActive = (id: string, isActive: boolean) =>
  api.patch<User>(`/admin/users/${id}/active`, { isActive }).then((r) => r.data);

export const getCurrentUser = () =>
  api.get<{ role: string }>('/users/profile').then((r) => r.data);

export const fetchUsers = (search?: string, page = 1) =>
  api
    .get<UsersResponse>('/admin/users', { params: { search, page, limit: 20 } })
    .then((r) => r.data);

export const updateSubscription = (
  userId: string,
  plan: 'free' | 'premium',
  durationDays?: number,
) => api.patch(`/admin/users/${userId}/subscription`, { plan, durationDays }).then((r) => r.data);

export const fetchOrders = (page = 1) =>
  api.get<OrdersResponse>('/admin/orders', { params: { page, limit: 20 } }).then((r) => r.data);
