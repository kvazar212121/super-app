import { showToast } from '../ui.js';

// Tanlangan chat holati (module-scope)
var _supActiveTicket = null;
var _supPollTimer = null;

async function renderSupport() {
    if (_supPollTimer) { clearInterval(_supPollTimer); _supPollTimer = null; }

    mainContent.innerHTML =
        '<div class="page-header"><h1 class="page-title">Qo\'llab-quvvatlash</h1>' +
        '<p class="page-subtitle">Foydalanuvchilardan kelgan xabarlar — javob bering</p></div>' +
        '<div class="card"><div class="card-body" style="padding:0;">' +
        '<div style="display:flex;min-height:560px;">' +
        // Chap: ticket ro'yxati
        '<div id="supList" style="width:320px;border-right:1px solid var(--border,#e2e8f0);overflow-y:auto;max-height:640px;">' +
        '<div style="padding:20px;color:#94a3b8;">Yuklanmoqda…</div></div>' +
        // O'ng: yozishma
        '<div id="supChat" style="flex:1;display:flex;flex-direction:column;">' +
        '<div style="flex:1;display:flex;align-items:center;justify-content:center;color:#94a3b8;">Chatni tanlang</div>' +
        '</div>' +
        '</div></div></div>';

    await loadTickets();
    // Har 10 soniyada ro'yxatni yangilaymiz
    _supPollTimer = setInterval(function () {
        loadTickets();
        if (_supActiveTicket) loadMessages(_supActiveTicket, true);
    }, 10000);
}

async function loadTickets() {
    var tickets = [];
    try {
        var r = await window.api(window.API_BASE + '/admin/support/tickets');
        if (r && r.ok) { var d = await r.json(); tickets = d.tickets || []; }
    } catch (e) {}

    var el = document.getElementById('supList');
    if (!el) return;
    if (!tickets.length) {
        el.innerHTML = '<div style="padding:20px;color:#94a3b8;">Hozircha xabar yo\'q</div>';
        return;
    }
    el.innerHTML = tickets.map(function (t) {
        var active = _supActiveTicket === t.id;
        var badge = t.unread > 0
            ? '<span style="background:#ef4444;color:#fff;border-radius:10px;padding:1px 7px;font-size:11px;font-weight:700;">' + t.unread + '</span>'
            : '';
        var time = t.last_message_at ? new Date(t.last_message_at).toLocaleString() : '';
        var closed = t.status === 'closed' ? ' <span style="color:#94a3b8;font-size:11px;">(yopilgan)</span>' : '';
        return '<div onclick="openSupTicket(' + t.id + ')" style="padding:12px 14px;cursor:pointer;border-bottom:1px solid var(--border,#f1f5f9);' +
            (active ? 'background:rgba(99,102,241,0.1);' : '') + '">' +
            '<div style="display:flex;justify-content:space-between;align-items:center;">' +
            '<strong style="font-size:14px;">' + window.escapeHtml(t.user_name) + closed + '</strong>' + badge + '</div>' +
            '<div style="color:#64748b;font-size:12px;">' + window.escapeHtml(t.user_phone || '') + '</div>' +
            '<div style="color:#94a3b8;font-size:12px;margin-top:3px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' +
            window.escapeHtml(t.last_message || '') + '</div>' +
            '<div style="color:#cbd5e1;font-size:11px;margin-top:2px;">' + time + '</div>' +
            '</div>';
    }).join('');
}

async function openSupTicket(id) {
    _supActiveTicket = id;
    loadTickets();
    await loadMessages(id, false);
}

async function loadMessages(ticketId, silent) {
    var data = { messages: [], status: 'open' };
    try {
        var r = await window.api(window.API_BASE + '/admin/support/tickets/' + ticketId + '/messages');
        if (r && r.ok) data = await r.json();
    } catch (e) {}

    var el = document.getElementById('supChat');
    if (!el) return;

    var bubbles = (data.messages || []).map(function (m) {
        var isAdmin = m.sender === 'admin';
        var time = m.created_at ? new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '';
        var name = isAdmin ? window.escapeHtml(m.admin_name || 'Operator') : 'Foydalanuvchi';
        return '<div style="display:flex;justify-content:' + (isAdmin ? 'flex-end' : 'flex-start') + ';margin-bottom:10px;">' +
            '<div style="max-width:70%;padding:9px 13px;border-radius:14px;' +
            (isAdmin ? 'background:#6366f1;color:#fff;border-bottom-right-radius:4px;' : 'background:#f1f5f9;color:#0f172a;border-bottom-left-radius:4px;') + '">' +
            '<div style="font-size:11px;font-weight:700;opacity:0.8;margin-bottom:2px;">' + name + '</div>' +
            '<div style="font-size:14px;white-space:pre-wrap;">' + window.escapeHtml(m.text || '') + '</div>' +
            '<div style="font-size:10px;opacity:0.6;text-align:right;margin-top:2px;">' + time + '</div>' +
            '</div></div>';
    }).join('');

    var closed = data.status === 'closed';
    el.innerHTML =
        '<div id="supMsgs" style="flex:1;overflow-y:auto;padding:18px;max-height:520px;">' +
        (bubbles || '<div style="color:#94a3b8;text-align:center;padding-top:40px;">Xabarlar yo\'q</div>') +
        '</div>' +
        '<div style="border-top:1px solid var(--border,#e2e8f0);padding:12px;display:flex;gap:8px;align-items:flex-end;">' +
        '<textarea id="supReply" rows="1" placeholder="Javob yozing..." style="flex:1;resize:none;padding:10px 14px;border:1px solid var(--border,#cbd5e1);border-radius:20px;font-size:14px;font-family:inherit;"></textarea>' +
        '<button class="btn btn-primary" onclick="sendSupReply()" style="border-radius:20px;">Yuborish</button>' +
        '<button class="btn" onclick="closeSupTicket()" title="Chatni yopish" style="border-radius:20px;">' + (closed ? 'Yopilgan' : '✓ Yopish') + '</button>' +
        '</div>';

    var msgs = document.getElementById('supMsgs');
    if (msgs) msgs.scrollTop = msgs.scrollHeight;
    var ta = document.getElementById('supReply');
    if (ta && !silent) ta.focus();
    if (ta) {
        ta.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendSupReply(); }
        });
    }
}

function sendSupReply() {
    if (!_supActiveTicket) return;
    var ta = document.getElementById('supReply');
    var text = (ta && ta.value || '').trim();
    if (!text) return;
    if (ta) ta.value = '';
    window.api(window.API_BASE + '/admin/support/tickets/' + _supActiveTicket + '/reply', {
        method: 'POST', body: JSON.stringify({ text: text }),
    }).then(function (r) {
        if (r && r.ok) { loadMessages(_supActiveTicket, true); loadTickets(); }
        else window.showToast('Xatolik', 'error');
    });
}

function closeSupTicket() {
    if (!_supActiveTicket) return;
    if (!confirm('Chatni yopiq deb belgilaysizmi?')) return;
    window.api(window.API_BASE + '/admin/support/tickets/' + _supActiveTicket + '/close', { method: 'POST' })
        .then(function (r) {
            window.showToast(r && r.ok ? 'Chat yopildi' : 'Xatolik', r && r.ok ? 'success' : 'error');
            loadTickets(); loadMessages(_supActiveTicket, true);
        });
}

export { renderSupport };
window.renderSupport = renderSupport;
window.openSupTicket = openSupTicket;
window.sendSupReply = sendSupReply;
window.closeSupTicket = closeSupTicket;
