
export const API_BASE = '/api/v1/admin';
window.API_BASE = API_BASE;
// ===== AUTH TOKEN =====
        let authToken = localStorage.getItem('at');
        if (!authToken) {
            location.replace('/admin/login');
            throw new Error('auth_required');
        }

        function getAuthHeaders() {
            const token = localStorage.getItem('at');
            if (!token) return null;
            return { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' };
        }

        async function api(url, opts) {
            opts = opts || {};
            const headers = getAuthHeaders();
            if (!headers) {
                location.replace('/admin/login');
                return null;
            }
            opts.headers = Object.assign({}, headers, opts.headers || {});
            try {
                const r = await fetch(url, opts);
                if (r.status === 401) {
                    localStorage.removeItem('at');
                    localStorage.removeItem('rt');
                    location.replace('/admin/login');
                }
                return r;
            } catch(e) {
                console.error('API error:', e);
                return null;
            }
        }

        function logout() {
            localStorage.removeItem('at');
            localStorage.removeItem('rt');
            location.replace('/admin/login');
        }

        function emptyPage() {
            return { items: [], total: 0, pages: 1 };
        }

        function apiError(msg) {
            window.showToast(msg || 'API xatoligi', 'error');
        }

        

// Exports for ES6 modules
export { apiError, api, getAuthHeaders, emptyPage, logout };
// Expose to window for inline onclick handlers
window.apiError = apiError;
window.api = api;
window.getAuthHeaders = getAuthHeaders;
window.emptyPage = emptyPage;
window.logout = logout;
