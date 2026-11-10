// ===== FRONTEND · JS bersama (semua halaman) =====
// Daftar isi (cari judul bagiannya dengan Ctrl+F):
//   Ikon SVG · Helper DOM · Toast · Modal · Tab · Lihat kata sandi · Navbar publik · Hero slider
//   Kerangka dashboard · Tabel jadi kartu
//   REVISI DOSEN: A. Tombol kembali · G. Penjaga formulir · G. Draft formulir
//                 Konfirmasi berkas (tahap 2) · C. Pratinjau berkas · G. Berkas dari pengiriman gagal
//                 G. Pemulihan isian · F. Provinsi otomatis · B. Email terakhir · K. Isi cepat alasan
//                 Menu aksi "Kelola" (tahap 2)
//   Jalankan saat halaman siap (semua fungsi init dipanggil di paling bawah)

// --- Ikon SVG ---
const ICONS = {
  home: '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/><path d="M10 21v-6h4v6"/>',
  briefcase:
    '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M3 12h18"/>',
  bookmark: '<path d="M6 3h12v18l-6-4-6 4z"/>',
  file: '<path d="M14 3H6v18h12V7z"/><path d="M14 3v4h4"/><path d="M9 13h6M9 17h6"/>',
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/>',
  users:
    '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c1-3.5 3.5-5 6.5-5s5.5 1.5 6.5 5"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M18 15c1.8.6 3 2.2 3.5 5"/>',
  bell: '<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 21h4"/>',
  settings:
    '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  logout: '<path d="M15 4h4v16h-4"/><path d="M10 8l-4 4 4 4"/><path d="M6 12h10"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>',
  check: '<path d="M5 12.5 10 17l9-10"/>',
  checkc: '<circle cx="12" cy="12" r="9"/><path d="m8 12.5 3 3 5-6"/>',
  x: '<path d="M6 6l12 12M18 6 6 18"/>',
  building:
    '<rect x="4" y="3" width="16" height="18" rx="1"/><path d="M9 7h2M13 7h2M9 11h2M13 11h2M9 15h2M13 15h2M10 21v-3h4v3"/>',
  send: '<path d="M21 3 10 14"/><path d="M21 3 14 21l-4-7-7-4z"/>',
  chart: '<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>',
  clipboard:
    '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V3h6v1"/><path d="m9 13 2 2 4-4"/>',
  shield: '<path d="M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z"/><path d="m9 12 2 2 4-4"/>',
  menu: '<path d="M4 6h16M4 12h16M4 18h16"/>',
  chevron: '<path d="m6 9 6 6 6-6"/>',
  left: '<path d="m15 18-6-6 6-6"/>',
  sliders: '<path d="M4 6.5h9M17 6.5h3M4 12h3M11 12h9M4 17.5h11M19 17.5h1"/><circle cx="15" cy="6.5" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="17" cy="17.5" r="2"/>',
  grid: '<rect x="3.5" y="3.5" width="7" height="7" rx="2"/><rect x="13.5" y="3.5" width="7" height="7" rx="2"/><rect x="3.5" y="13.5" width="7" height="7" rx="2"/><rect x="13.5" y="13.5" width="7" height="7" rx="2"/>',
  right: '<path d="m9 18 6-6-6-6"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  download: '<path d="M12 4v11"/><path d="m7 10 5 5 5-5"/><path d="M4 20h16"/>',
  upload: '<path d="M12 16V5"/><path d="m7 9 5-5 5 5"/><path d="M4 20h16"/>',
  eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  pin: '<path d="M12 21s-7-6.2-7-12a7 7 0 0 1 14 0c0 5.8-7 12-7 12z"/><circle cx="12" cy="9" r="2.5"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  link: '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
  image:
    '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="m21 16-5-5-9 9"/>',
  copy: '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h3"/>',
  lock: '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  hourglass:
    '<path d="M7 3h10M7 21h10"/><path d="M8 3c0 5 8 5 8 9s-8 4-8 9M16 3c0 5-8 5-8 9s8 4 8 9"/>',
  alert: '<path d="M12 3 2 20h20z"/><path d="M12 10v4M12 17v.5"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8v.5"/>',
  mail: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>',
  phone:
    '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>',
  chat: '<path d="M4 5h16v11H9l-5 4z"/>',
  graduation:
    '<path d="M2 9 12 4l10 5-10 5z"/><path d="M6 11v5c3 2.5 9 2.5 12 0v-5"/><path d="M22 9v6"/>',
  target:
    '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
  handshake:
    '<path d="m11 17 2 2a1.5 1.5 0 0 0 2-2"/><path d="m14 14 2.5 2.5a1.5 1.5 0 0 0 2-2L15 11"/><path d="M3 11l4-4 5 1 3-2 6 5-3 3"/><path d="M7 7 3 11l7 7a1.5 1.5 0 0 0 2-2"/>',
  wand: '<path d="m4 20 11-11"/><path d="m14 5 1-2 1 2 2 1-2 1-1 2-1-2-2-1zM19 12l.7-1.3L21 10l-1.3-.7L19 8l-.7 1.3L17 10l1.3.7z"/>',
  trending: '<path d="m3 17 6-6 4 4 8-8"/><path d="M15 7h6v6"/>',
  trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
  edit: '<path d="M4 20h4L19 9l-4-4L4 16z"/>',
  whatsapp:
    '<path d="M4 20l1.3-4A8 8 0 1 1 8 18.7z"/><path d="M9 9.5c.3 2 2.3 4.3 5 5l1-1.3 1.8.8c-.3 1.2-1.3 1.8-2.5 1.6-2.8-.5-5.8-3.3-6.3-6.3-.2-1.2.4-2.2 1.6-2.5l.8 1.8z"/>',
  ban: '<circle cx="12" cy="12" r="9"/><path d="m6 6 12 12"/>',
  instagram:
    '<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><path d="M17.5 6.5v.01"/>',
  facebook:
    '<path d="M15 3h-2.5A3.5 3.5 0 0 0 9 6.5V10H6.5v3.5H9V21h3.5v-7.5H15l.5-3.5h-3V7a1 1 0 0 1 1-1H15z"/>',
  external:
    '<path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/>',
  refresh:
    '<path d="M20 11a8 8 0 0 0-14-5l-2 2"/><path d="M4 4v4h4"/><path d="M4 13a8 8 0 0 0 14 5l2-2"/><path d="M20 20v-4h-4"/>',
};
function ic(name, cls = '') {
  return `<svg class="icon ${cls}" viewBox="0 0 24 24" aria-hidden="true">${ICONS[name] || ''}</svg>`;
}
function hydrateIcons(root = document) {
  root.querySelectorAll('[data-ic]').forEach((el) => {
    if (!el.dataset.done) {
      el.insertAdjacentHTML('afterbegin', ic(el.dataset.ic));
      el.dataset.done = 1;
    }
  });
}

// --- Helper DOM ---
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];

// --- Toast ---
function toast(msg) {
  let w = $('.toast-wrap');
  if (!w) {
    w = document.createElement('div');
    w.className = 'toast-wrap';
    w.setAttribute('role', 'status');
    document.body.appendChild(w);
  }
  const t = document.createElement('div');
  t.className = 'toast';
  t.innerHTML = ic('checkc') + `<span>${msg}</span>`;
  w.appendChild(t);
  setTimeout(() => t.remove(), 3200);
}

// --- Modal ---
function openModal(id) {
  const m = document.getElementById(id);
  if (!m) return;
  m.classList.add('open');
  const f = m.querySelector('input,select,textarea,button:not(.close)');
  f && f.focus();
}
function closeModal(el) {
  (el.closest ? el.closest('.modal') : el).classList.remove('open');
}
document.addEventListener('click', (e) => {
  const o = e.target.closest('[data-open]');
  if (o) {
    e.preventDefault();
    openModal(o.dataset.open);
  }
  if (e.target.closest('[data-close]')) closeModal(e.target.closest('.modal'));
  if (e.target.classList.contains('modal')) closeModal(e.target);
  const tt = e.target.closest('[data-toast]');
  if (tt) {
    e.preventDefault();
    toast(tt.dataset.toast);
  }
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    $$('.modal.open').forEach((m) => m.classList.remove('open'));
    $$('.pop.open').forEach((p) => p.classList.remove('open'));
  }
});

// --- Tab ---
document.addEventListener('click', (e) => {
  const b = e.target.closest('[data-tab]');
  if (!b) return;
  const group = b.closest('[data-tabs]');
  if (!group) return;
  $$('[data-tab]', group).forEach((x) => x.classList.toggle('active', x === b));
  const scope = document.getElementById(group.dataset.tabs);
  if (scope) $$('[data-pane]', scope).forEach((p) => (p.hidden = p.dataset.pane !== b.dataset.tab));
  group.dispatchEvent(new CustomEvent('tabchange', { detail: b.dataset.tab }));
  // Revisi: tab aktif dicatat di alamat (#tab), jadi setelah menyimpan / muat ulang tetap di tab yang sama.
  if (e.isTrusted) { try { history.replaceState(null, '', '#' + b.dataset.tab); } catch (_) {} }
});

// --- Lihat kata sandi & nama berkas unggahan ---
document.addEventListener('click', (e) => {
  const b = e.target.closest('.pw button');
  if (!b) return;
  const i = b.parentElement.querySelector('input');
  i.type = i.type === 'password' ? 'text' : 'password';
  b.setAttribute(
    'aria-label',
    i.type === 'password' ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
  );
});
document.addEventListener('change', (e) => {
  const i = e.target;
  if (i.type !== 'file' || i.dataset.pratinjau) return;
  const box = i.closest('.upload');
  if (box) {
    let n = box.querySelector('.name');
    if (!n) {
      n = document.createElement('div');
      n.className = 'name';
      box.appendChild(n);
    }
    n.textContent = i.files[0] ? 'Terpilih: ' + i.files[0].name : '';
  }
  if (i.dataset.preview && i.files[0]) {
    const img = document.getElementById(i.dataset.preview);
    if (img) {
      img.src = URL.createObjectURL(i.files[0]);
      img.hidden = false;
    }
  }
});

// --- Navbar publik ---
function initPublicNav() {
  const nav = $('.nav');
  if (!nav) return;
  const fab = $('.fab');
  const onScroll = () => {
    nav.classList.toggle('solid', window.scrollY > 40 || nav.classList.contains('menu-open'));
    if (fab) fab.classList.toggle('show', window.scrollY > window.innerHeight * 0.6);
  };
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });
  $$('.dropdown > button', nav).forEach((b) =>
    b.addEventListener('click', (e) => {
      e.stopPropagation();
      const d = b.parentElement;
      const open = !d.classList.contains('open');
      $$('.dropdown', nav).forEach((x) => x.classList.remove('open'));
      d.classList.toggle('open', open);
      b.setAttribute('aria-expanded', open);
    }),
  );
  document.addEventListener('click', () =>
    $$('.dropdown', nav).forEach((x) => x.classList.remove('open')),
  );
  const t = $('.nav-toggle', nav);
  t &&
    t.addEventListener('click', () => {
      nav.classList.toggle('menu-open');
      t.setAttribute('aria-expanded', nav.classList.contains('menu-open'));
      onScroll();
    });
  $$('.nav-links a', nav).forEach((a) =>
    a.addEventListener('click', () => {
      nav.classList.remove('menu-open');
      onScroll();
    }),
  );
}

// --- Hero slider ---
function initHero() {
  const hero = $('.hero');
  if (!hero) return;
  const slides = $$('.hero-slide', hero),
    tabs = $$('.hero-tab', hero),
    texts = $$('.hero-text', hero);
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  let i = 0,
    timer;
  function go(n) {
    i = (n + slides.length) % slides.length;
    slides.forEach((s, k) => s.classList.toggle('active', k === i));
    texts.forEach((s, k) => (s.hidden = k !== i));
    tabs.forEach((t, k) => {
      t.classList.remove('active');
      void t.offsetWidth;
      t.classList.toggle('active', k === i);
      t.setAttribute('aria-selected', k === i);
    });
    clearTimeout(timer);
    if (!reduce && !hero.classList.contains('paused')) timer = setTimeout(() => go(i + 1), 7000);
  }
  tabs.forEach((t, k) => t.addEventListener('click', () => go(k)));
  if (reduce) hero.classList.add('paused');
  go(0);
}

// --- Kerangka dashboard (sidebar, popup, tab dari #hash) ---
function initAppShell() {
  $$('[data-pop]').forEach((b) =>
    b.addEventListener('click', (e) => {
      e.stopPropagation();
      const p = document.getElementById(b.dataset.pop);
      const open = !p.classList.contains('open');
      $$('.pop').forEach((x) => x.classList.remove('open'));
      p.classList.toggle('open', open);
    }),
  );
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.pop')) $$('.pop').forEach((x) => x.classList.remove('open'));
  });
  const side = $('.side');
  $$('.menu-toggle').forEach((b) =>
    b.addEventListener('click', (e) => {
      e.stopPropagation();
      side.classList.toggle('open');
    }),
  );
  document.addEventListener('click', (e) => {
    if (
      side &&
      side.classList.contains('open') &&
      !e.target.closest('.side') &&
      !e.target.closest('.menu-toggle')
    )
      side.classList.remove('open');
  });
  if (location.hash) {
    const btn = document.querySelector(`[data-tab="${CSS.escape(location.hash.slice(1))}"]`);
    if (btn) {
      btn.click();
      const grup = btn.closest('[data-tabs]');
      // Gulir ke tab yang dibuka (bukan ke atas halaman), memberi ruang untuk topbar.
      setTimeout(() => {
        const atas = (grup || btn).getBoundingClientRect().top + window.scrollY - 90;
        window.scrollTo({ top: Math.max(0, atas), behavior: 'auto' });
      }, 30);
    }
  }
  // Setelah mengirim formulir: kembali ke posisi gulir semula bila halaman yang sama dibuka lagi.
  try {
    const posisi = JSON.parse(sessionStorage.getItem('karirku:posisi') || 'null');
    sessionStorage.removeItem('karirku:posisi');
    if (posisi && posisi.path === location.pathname && Date.now() - posisi.t < 60000 && !location.hash) {
      if (posisi.tab) { const tb = document.querySelector(`[data-tab="${CSS.escape(posisi.tab)}"]`); if (tb) tb.click(); }
      setTimeout(() => window.scrollTo({ top: posisi.y, behavior: 'auto' }), 30);
    }
  } catch (_) {}
  document.addEventListener('submit', (e) => {
    const f = e.target;
    if (e.defaultPrevented || !(f instanceof HTMLFormElement) || (f.method || '').toLowerCase() !== 'post') return;
    const aktif = document.querySelector('[data-tabs] [data-tab].active');
    try { sessionStorage.setItem('karirku:posisi', JSON.stringify({ path: location.pathname, tab: aktif ? aktif.dataset.tab : '', y: window.scrollY, t: Date.now() })); } catch (_) {}
  });
}

// --- Tabel jadi kartu di layar kecil ---
function initTabelKartu() {
  $$('table.t').forEach((tabel) => {
    const kepala = tabel.querySelector('tr');
    if (!kepala) return;
    const judul = [...kepala.querySelectorAll('th')].map((th) => th.textContent.trim());
    if (!judul.length) return;
    tabel.querySelectorAll('tr').forEach((baris) => {
      [...baris.children].forEach((sel, i) => {
        if (sel.tagName !== 'TD') return;
        if (sel.colSpan > 1) {
          sel.classList.add('sel-penuh');
          return;
        }
        if (judul[i]) sel.setAttribute('data-kolom', judul[i]);
      });
    });
    tabel.classList.add('t-kartu');
  });
}


/* =====================================================================
   REVISI DOSEN (Oktober 2026)
     A. initTombolKembali   : tombol Kembali pakai riwayat browser bila dari situs ini,
                              cadangan ke halaman induk bila dibuka langsung
     G. initPenjagaFormulir : peringatan perubahan belum disimpan, cegah klik ganda,
                              konfirmasi aksi penting, alasan wajib
     G. initDraftFormulir   : draft otomatis per akun di browser + Pulihkan/Buang
     C. initPratinjauBerkas : pratinjau gambar/PDF sebelum unggah + validasi tipe & ukuran
     K. initTemplateAlasan  : tombol isi cepat alasan penolakan
   ===================================================================== */
const UID = () => (document.body && document.body.dataset.uid) || 'tamu';
const amanLS = {
  get(k) { try { return localStorage.getItem(k); } catch (_) { return null; } },
  set(k, v) { try { localStorage.setItem(k, v); return true; } catch (_) { return false; } },
  del(k) { try { localStorage.removeItem(k); } catch (_) {} },
  keys() { try { return Object.keys(localStorage); } catch (_) { return []; } },
};
const amanSS = {
  get(k) { try { return sessionStorage.getItem(k); } catch (_) { return null; } },
  set(k, v) { try { sessionStorage.setItem(k, v); } catch (_) {} },
  del(k) { try { sessionStorage.removeItem(k); } catch (_) {} },
};
function formatUkuran(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + ' MB' : Math.max(1, Math.round(b / 1024)) + ' KB'; }
function formatJam(t) {
  try { return new Date(t).toLocaleString('id-ID', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }); } catch (_) { return ''; }
}

/* ---------- A. Tombol kembali ---------- */
// Daftar isian yang nilainya BERBEDA dari yang dikirim server (kosong = tidak ada perubahan nyata).
// Autofill yang mengisi nilai sama, atau isian yang diketik lalu dikembalikan, bukan perubahan.
function isianBerbeda(f) {
  return Array.from(f.elements).filter((el) => {
    if (!el.name || el.name === 'csrf_token' || el.disabled) return false;
    const t = (el.type || '').toLowerCase();
    if (['hidden', 'submit', 'button', 'reset', 'image'].includes(t)) return false;
    // Kolom kata sandi hanya dihitung bila pengguna benar-benar mengetik di situ (mis. saat
    // mengganti email atau sandi). Terisi sendiri oleh browser/pengelola sandi tidak dihitung.
    if (t === 'password') return el.dataset.diketik === '1' && el.value !== el.defaultValue;
    if (t === 'file') return !!(el.files && el.files.length);
    if (t === 'checkbox' || t === 'radio') return el.checked !== el.defaultChecked;
    if (el.tagName === 'SELECT') {
      const opsi = Array.from(el.options);
      if (el.multiple) return !opsi.every((o) => o.selected === o.defaultSelected);
      const awal = opsi.findIndex((o) => o.defaultSelected);
      return el.selectedIndex !== (awal < 0 ? 0 : awal);
    }
    return el.value !== el.defaultValue;
  });
}
function formBelumDisimpan() {
  return $$('form[data-jaga]').filter((f) => f.dataset.berubah === '1' && f.dataset.mengirim !== '1' && isianBerbeda(f).length > 0);
}
function adaFormBelumDisimpan() { return formBelumDisimpan().length > 0; }

function labelIsian(el) {
  let t = el.dataset.label || '';
  if (!t && el.labels && el.labels[0]) t = el.labels[0].textContent;
  if (!t) t = el.getAttribute('aria-label') || el.placeholder || el.name;
  return t.replace(/\*|\(opsional\)/g, '').replace(/\s+/g, ' ').trim();
}
// Nama isian yang berubah, untuk ditampilkan di dialog (isian tersembunyi tidak ikut disebut).
function namaIsianBerubah() {
  const nama = [];
  formBelumDisimpan().forEach((f) => isianBerbeda(f).forEach((el) => {
    const t = (el.type || '').toLowerCase();
    const bebasTampil = ['file', 'checkbox', 'radio'].includes(t);
    if (!bebasTampil && el.getClientRects().length === 0) return;
    const l = labelIsian(el);
    if (l && !nama.includes(l)) nama.push(l);
  }));
  return nama;
}
function teksTautan(a) {
  const t = (a.getAttribute('aria-label') || a.textContent || '').replace(/\s+/g, ' ').trim().replace(/\s*\d+$/, '');
  return t.length > 0 && t.length <= 50 ? t : '';
}

// Dialog "Tinggalkan halaman?" di TENGAH layar (pengganti confirm() bawaan browser yang tampil di pojok atas).
// $tujuan: nama halaman yang akan dibuka (boleh kosong).
function tanyaTinggalkan(onYa, tujuan) {
  const lama = document.getElementById('mTinggalkan');
  if (lama) lama.remove();
  const adaDraft = formBelumDisimpan().some((f) => f.hasAttribute('data-draft'));
  const berubah = namaIsianBerubah();
  const m = document.createElement('div');
  m.className = 'modal open'; m.id = 'mTinggalkan';
  m.setAttribute('role', 'alertdialog'); m.setAttribute('aria-modal', 'true'); m.setAttribute('aria-labelledby', 'jTinggalkan');
  m.innerHTML = '<div class="modal-box"><div class="modal-head"><h3 id="jTinggalkan">Tinggalkan halaman ini?</h3>'
    + '<button class="close" type="button" data-batal aria-label="Tutup" data-ic="x"></button></div>'
    + '<div class="modal-body"><p class="m-0">Ada perubahan pada formulir yang <b>belum disimpan</b>. Bila Anda pindah sekarang, perubahan itu tidak ikut tersimpan.</p>'
    + '<div data-rincian></div></div>'
    + '<div class="modal-foot"><button type="button" class="btn btn-outline" data-batal>Tetap di halaman ini</button>'
    + '<button type="button" class="btn btn-danger" data-ya>Tinggalkan</button></div></div>';
  // Rincian disusun lewat textContent supaya teks dari halaman tidak pernah dibaca sebagai HTML.
  const rincian = m.querySelector('[data-rincian]');
  const baris = (label, isi, kelas) => {
    const p = document.createElement('p'); p.className = kelas || 'muted fs-88 mt-12 mb-0';
    const b = document.createElement('b'); b.textContent = isi;
    p.append(label, b); rincian.appendChild(p);
  };
  if (berubah.length) baris('Yang berubah: ', berubah.slice(0, 5).join(', ') + (berubah.length > 5 ? ' dan ' + (berubah.length - 5) + ' lainnya' : ''));
  if (tujuan) baris('Anda akan membuka: ', tujuan);
  if (adaDraft) {
    const p = document.createElement('p'); p.className = 'muted fs-88 mt-12 mb-0';
    p.textContent = 'Isian formulir ini disimpan sementara sebagai draft di browser ini, jadi masih bisa dipulihkan saat Anda kembali.';
    rincian.appendChild(p);
  }
  document.body.appendChild(m);
  hydrateIcons(m);
  const tutup = () => { m.remove(); document.removeEventListener('keydown', saatEsc, true); };
  const saatEsc = (ev) => { if (ev.key === 'Escape') tutup(); };
  document.addEventListener('keydown', saatEsc, true);
  m.addEventListener('click', (ev) => {
    if (ev.target.closest('[data-ya]')) { tutup(); document.body.dataset.izinkanKeluar = '1'; onYa(); return; }
    if (ev.target === m || ev.target.closest('[data-batal]')) tutup();
  });
  const tetap = m.querySelector('.modal-foot [data-batal]');
  if (tetap) tetap.focus();
}

// Isian yang diberi data-ingatkan="pesan" tetapi masih kosong (mis. Nomor WhatsApp di Profil Saya admin).
// Hanya isian yang sedang tampil (isian di tab lain yang tersembunyi tidak ikut diingatkan).
function isianPengingatKosong() {
  return $$('[data-ingatkan]').filter((el) => (el.value || '').trim() === '' && !el.disabled && el.getClientRects().length > 0);
}
// Dialog pengingat di tengah layar: isian penting belum diisi. Tidak memblokir; pengguna boleh lanjut pindah.
function tanyaIsi(daftar, onLanjut, tujuan) {
  const lama = document.getElementById('mIngatkanIsi');
  if (lama) lama.remove();
  const el = daftar[0];
  const m = document.createElement('div');
  m.className = 'modal open'; m.id = 'mIngatkanIsi';
  m.setAttribute('role', 'alertdialog'); m.setAttribute('aria-modal', 'true'); m.setAttribute('aria-labelledby', 'jIngatkanIsi');
  m.innerHTML = '<div class="modal-box"><div class="modal-head"><h3 id="jIngatkanIsi"></h3>'
    + '<button class="close" type="button" data-batal aria-label="Tutup" data-ic="x"></button></div>'
    + '<div class="modal-body"><p class="m-0" data-pesan></p><div data-rincian></div></div>'
    + '<div class="modal-foot"><button type="button" class="btn btn-outline" data-ya>Lewati, pindah halaman</button>'
    + '<button type="button" class="btn btn-primary" data-isi>Isi sekarang</button></div></div>';
  m.querySelector('h3').textContent = el.dataset.ingatkanJudul || (labelIsian(el) + ' belum diisi');
  m.querySelector('[data-pesan]').textContent = el.dataset.ingatkan;
  if (daftar.length > 1) {
    // Banyak isian sejenis kosong (mis. kontak admin tiap jurusan): sebutkan yang belum diisi.
    // Satu jurusan bisa punya dua isian kosong (nama dan nomor): sebut sekali saja.
    const nama = [...new Set(daftar.map((x) => x.dataset.ingatkanNama || labelIsian(x)))];
    const p = document.createElement('p'); p.className = 'muted fs-88 mt-12 mb-0';
    const b = document.createElement('b');
    b.textContent = nama.slice(0, 5).join(', ') + (nama.length > 5 ? ' dan ' + (nama.length - 5) + ' lainnya' : '');
    p.append('Belum diisi (' + nama.length + '): ', b);
    m.querySelector('[data-rincian]').appendChild(p);
  }
  if (tujuan) {
    const p = document.createElement('p'); p.className = 'muted fs-88 mt-12 mb-0';
    const b = document.createElement('b'); b.textContent = tujuan;
    p.append('Bila dilewati, Anda akan membuka: ', b);
    m.querySelector('[data-rincian]').appendChild(p);
  }
  document.body.appendChild(m);
  hydrateIcons(m);
  const tutup = () => { m.remove(); document.removeEventListener('keydown', saatEsc, true); };
  const saatEsc = (ev) => { if (ev.key === 'Escape') tutup(); };
  document.addEventListener('keydown', saatEsc, true);
  const isiSekarang = () => { tutup(); el.scrollIntoView({ block: 'center', behavior: 'smooth' }); el.focus(); };
  m.addEventListener('click', (ev) => {
    if (ev.target.closest('[data-ya]')) { tutup(); document.body.dataset.izinkanKeluar = '1'; onLanjut(); return; }
    if (ev.target.closest('[data-isi]') || ev.target.closest('[data-batal]') || ev.target === m) isiSekarang();
  });
  const tombol = m.querySelector('[data-isi]');
  if (tombol) tombol.focus();
}
// Satu pintu untuk semua peringatan sebelum meninggalkan halaman. Mengembalikan true bila ada dialog yang dibuka.
function cegatKeluar(onLanjut, tujuan) {
  if (adaFormBelumDisimpan()) { tanyaTinggalkan(onLanjut, tujuan); return true; }
  const kosong = isianPengingatKosong();
  if (kosong.length) { tanyaIsi(kosong, onLanjut, tujuan); return true; }
  return false;
}

function pergiKembali(a) {
  let dariSitusIni = false;
  try {
    dariSitusIni = document.referrer && new URL(document.referrer).origin === location.origin && document.referrer !== location.href;
  } catch (_) {}
  document.body.dataset.izinkanKeluar = '1';
  if (dariSitusIni && history.length > 1) history.back();
  else location.href = a.href;
}
function initTombolKembali() {
  document.addEventListener('click', (e) => {
    const a = e.target.closest('a[data-kembali]');
    if (!a) return;
    // Halaman galat/404 punya penangan sendiri (href="#"); jangan ikut mundur dua kali.
    if (a.getAttribute('href') === '#') return;
    if (adaFormBelumDisimpan() || isianPengingatKosong().length) {
      e.preventDefault();
      cegatKeluar(() => pergiKembali(a), 'Halaman sebelumnya');
      return;
    }
    let dariSitusIni = false;
    try {
      dariSitusIni = document.referrer && new URL(document.referrer).origin === location.origin && document.referrer !== location.href;
    } catch (_) {}
    if (dariSitusIni && history.length > 1) {
      e.preventDefault();
      document.body.dataset.izinkanKeluar = '1';
      history.back();
    }
  });
}

/* ---------- G. Penjaga formulir ---------- */
function initPenjagaFormulir() {
  $$('form[data-jaga]').forEach((f) => {
    const tandai = (ev) => {
      const el = ev.target;
      if (!el || !el.name || el.name === 'csrf_token') return;
      const jenis = (el.type || '').toLowerCase();
      const pilihan = el.tagName === 'SELECT' || ['checkbox', 'radio', 'file'].includes(jenis);
      // Isian teks yang terisi sendiri (autofill/pengelola sandi browser) bukan ketikan pengguna:
      // hanya isian yang sedang difokuskan yang dihitung sebagai diubah pengguna.
      if (!pilihan && el !== document.activeElement) return;
      el.dataset.diketik = '1';
      f.dataset.berubah = '1';
    };
    f.addEventListener('input', tandai);
    f.addEventListener('change', tandai);
  });
  // Klik tautan biasa (menu samping, breadcrumb, dll.) saat ada perubahan belum disimpan:
  // tampilkan dialog di tengah layar, bukan kotak "Leave site?" bawaan browser.
  document.addEventListener('click', (e) => {
    if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    const a = e.target.closest && e.target.closest('a[href]');
    if (!a || a.hasAttribute('data-kembali') || a.hasAttribute('download')) return;
    if (a.target && a.target !== '_self') return;
    const href = a.getAttribute('href') || '';
    if (href === '' || href.startsWith('#') || /^(javascript|mailto|tel):/i.test(href)) return;
    if (a.pathname === location.pathname && a.search === location.search && a.origin === location.origin && a.hash) return;
    if (!adaFormBelumDisimpan() && !isianPengingatKosong().length) return;
    e.preventDefault();
    cegatKeluar(() => { location.href = a.href; }, teksTautan(a));
  });
  // Cadangan untuk menutup tab, memuat ulang, atau tombol back browser: kotak bawaan browser
  // (isinya tidak bisa diubah dan posisinya diatur browser).
  window.addEventListener('beforeunload', (e) => {
    if (document.body.dataset.izinkanKeluar === '1') return;
    if (adaFormBelumDisimpan()) { e.preventDefault(); e.returnValue = ''; }
  });

  document.addEventListener('submit', (e) => {
    const f = e.target;
    if (!(f instanceof HTMLFormElement)) return;
    // Submit yang sudah dibatalkan skrip halaman (validasi, pindah langkah formulir
    // bertahap seperti pendaftaran) BUKAN pengiriman: jangan kunci tombolnya.
    if (e.defaultPrevented) return;
    const tombol = e.submitter || null;

    // Alasan wajib (min. 10 karakter) untuk tombol tolak/minta perbaikan.
    if (tombol && tombol.dataset.wajibAlasan) {
      const t = document.getElementById(tombol.dataset.wajibAlasan);
      if (t && t.value.trim().length < 10) {
        e.preventDefault();
        t.dataset.pesanSalah = 'Alasan wajib diisi minimal 10 karakter (sekarang ' + t.value.trim().length + '), supaya penerima tahu apa yang harus dilakukan.';
        tampilkanSalahIsian([t], 'Alasan belum diisi');
        t.addEventListener('input', () => { if (t.value.trim().length >= 10) { delete t.dataset.pesanSalah; tandaiIsian(t, ''); } }, { once: false });
        return;
      }
    }
    // Konfirmasi aksi penting: dialog di tengah layar (bukan confirm() bawaan browser).
    // Setelah pengguna menekan "Ya", formulir dikirim ulang dengan penanda supaya tidak ditanya dua kali.
    const tanya = (tombol && tombol.dataset.konfirmasi) || f.dataset.konfirmasi;
    if (tanya && f.dataset.dikonfirmasi !== '1') {
      e.preventDefault();
      const bahaya = (tombol && /btn-danger|bahaya/.test(tombol.className)) || /hapus|tolak|tutup|nonaktif|batal|keluar/i.test(tanya);
      tanyaDialog(tanya.replace(/&ldquo;|&rdquo;/g, '"'), { tipe: bahaya ? 'warn' : 'tanya', judul: bahaya ? 'Yakin ingin melanjutkan?' : 'Lanjutkan?', ya: (tombol && tombol.textContent.trim()) || 'Ya, lanjutkan', bahaya }).then((ya) => {
        if (!ya) return;
        f.dataset.dikonfirmasi = '1';
        if (f.requestSubmit) f.requestSubmit(tombol && tombol.form === f ? tombol : undefined); else f.submit();
      });
      return;
    }
    delete f.dataset.dikonfirmasi;

    // Revisi: berkas yang dipilih wajib dipratinjau & dikonfirmasi dulu sebelum tersimpan.
    if (f.dataset.konfirmasiBerkas !== '1' && berkasTerpilih(f).length && f.dataset.mengirim !== '1') {
      if (!f.noValidate && !f.checkValidity()) return;
      e.preventDefault();
      bukaKonfirmasiBerkas(f, tombol);
      return;
    }
    // Cegah submit ganda (klik dua kali / tekan Enter berulang).
    if (f.dataset.mengirim === '1') { e.preventDefault(); return; }
    if (!f.noValidate && !f.checkValidity()) return;
    f.dataset.mengirim = '1';
    document.body.dataset.izinkanKeluar = '1';
    if (tombol && tombol.name) {
      const h = document.createElement('input');
      h.type = 'hidden'; h.name = tombol.name; h.value = tombol.value;
      f.appendChild(h);
    }
    if (f.dataset.draft) amanSS.set('karirku:draftDikirim', UID() + ':' + f.dataset.draft);
    setTimeout(() => {
      $$('button[type="submit"], button:not([type])', f).forEach((b) => {
        b.disabled = true;
        if (b === tombol && b.dataset.proses) { b.dataset.teksAsli = b.innerHTML; b.textContent = b.dataset.proses; }
        b.classList.add('is-loading');
      });
    }, 0);
  });
  // Kembali lewat tombol Back (bfcache): aktifkan lagi tombolnya.
  window.addEventListener('pageshow', () => {
    $$('form[data-mengirim="1"]').forEach((f) => {
      f.dataset.mengirim = '';
      $$('button.is-loading', f).forEach((b) => {
        b.disabled = false; b.classList.remove('is-loading');
        if (b.dataset.teksAsli) b.innerHTML = b.dataset.teksAsli;
      });
    });
    document.body.dataset.izinkanKeluar = '';
  });
}

/* ---------- G. Draft formulir (per akun, di browser ini) ---------- */
function kunciDraft(nama) { return 'karirku:draft:' + UID() + ':' + nama; }
function fieldDraft(f) {
  return $$('input, select, textarea', f).filter((el) => el.name && !el.disabled
    && !['password', 'file', 'hidden', 'submit', 'button'].includes(el.type)
    && !/password|sandi|csrf|token/i.test(el.name));
}
function ambilNilai(f) {
  const v = {};
  fieldDraft(f).forEach((el) => {
    if (el.type === 'checkbox') {
      if (el.name.endsWith('[]')) { v[el.name] = v[el.name] || []; if (el.checked) v[el.name].push(el.value); }
      else v[el.name] = el.checked;
    } else if (el.type === 'radio') { if (el.checked) v[el.name] = el.value; }
    else v[el.name] = el.value;
  });
  return v;
}
function terapkanNilai(f, v) {
  fieldDraft(f).forEach((el) => {
    if (!(el.name in v)) return;
    const n = v[el.name];
    if (el.type === 'checkbox') el.checked = Array.isArray(n) ? n.includes(el.value) : !!n;
    else if (el.type === 'radio') el.checked = el.value === n;
    else el.value = n;
    el.dispatchEvent(new Event('change', { bubbles: true }));
  });
}
function initDraftFormulir() {
  // Draft dari formulir yang baru saja BERHASIL dikirim dibuang.
  const dikirim = amanSS.get('karirku:draftDikirim');
  if (dikirim) {
    amanSS.del('karirku:draftDikirim');
    const berhasil = !!$('.alert-ok') && !$('.alert-bad');
    if (berhasil) amanLS.del('karirku:draft:' + dikirim);
  }
  // Draft lebih dari 7 hari dihapus.
  amanLS.keys().filter((k) => k.startsWith('karirku:draft:')).forEach((k) => {
    try { if (Date.now() - JSON.parse(amanLS.get(k)).t > 7 * 864e5) amanLS.del(k); } catch (_) { amanLS.del(k); }
  });

  $$('form[data-draft]').forEach((f) => {
    const kunci = kunciDraft(f.dataset.draft);
    const status = $('[data-draft-status]', f);
    const awal = JSON.stringify(ambilNilai(f));
    let simpanan = null;
    try { simpanan = JSON.parse(amanLS.get(kunci) || 'null'); } catch (_) {}

    if (simpanan && simpanan.v && JSON.stringify(simpanan.v) !== awal) {
      const banner = document.createElement('div');
      banner.className = 'draft-banner';
      banner.innerHTML = '<span>Ada isian yang belum terkirim dari ' + formatJam(simpanan.t) + '. Pulihkan isian tersebut?</span>'
        + '<span class="draft-aksi"><button type="button" class="btn btn-sm btn-primary" data-aksi="pulihkan">Pulihkan</button>'
        + '<button type="button" class="btn btn-sm btn-outline" data-aksi="buang">Buang draft</button></span>';
      f.parentNode.insertBefore(banner, f);
      banner.addEventListener('click', (ev) => {
        const b = ev.target.closest('button'); if (!b) return;
        if (b.dataset.aksi === 'pulihkan') {
          terapkanNilai(f, simpanan.v);
          f.dataset.berubah = '1';
          if (status) status.textContent = 'Draft dipulihkan dari browser ini.' + ($('.berkas-sementara', f) ? '' : ' Berkas (pamflet, dokumen) perlu dipilih ulang karena browser tidak menyimpan berkas.');
        } else amanLS.del(kunci);
        banner.remove();
      });
    }

    let jeda;
    const simpan = () => {
      clearTimeout(jeda);
      jeda = setTimeout(() => {
        const v = ambilNilai(f);
        if (JSON.stringify(v) === awal) return;
        if (amanLS.set(kunci, JSON.stringify({ t: Date.now(), v })) && status) {
          status.textContent = 'Draft tersimpan otomatis di browser ini, ' + formatJam(Date.now()) + '.';
        }
      }, 600);
    };
    f.addEventListener('input', simpan);
    f.addEventListener('change', simpan);
  });
}


/* ---------- Konfirmasi berkas sebelum disimpan (revisi tahap 2) ----------
   Semua formulir yang membawa berkas menampilkan jendela pratinjau (gambar / PDF,
   nama, ukuran) dan baru tersimpan setelah pengguna menekan "Ya, simpan". */
function berkasTerpilih(f) {
  return $$('input[type="file"]', f).filter((i) => !i.disabled && i.files && i.files.length);
}
function labelBerkas(input) {
  const fld = input.closest('.field');
  const l = fld && fld.querySelector(':scope > label:not(.upload)');
  return (input.dataset.label || (l ? l.textContent : '') || input.getAttribute('aria-label') || 'Berkas').replace(/\*|\(opsional\)/g, '').trim();
}
let urlKonfirmasi = [];
function tutupKonfirmasiBerkas() {
  const m = document.getElementById('mKonfirmasiBerkas');
  if (m) m.remove();
  urlKonfirmasi.forEach((u) => URL.revokeObjectURL(u)); urlKonfirmasi = [];
  document.body.classList.remove('modal-terbuka');
}
function bukaKonfirmasiBerkas(f, tombol, otomatis) {
  tutupKonfirmasiBerkas();
  const daftar = berkasTerpilih(f);
  const m = document.createElement('div');
  m.className = 'modal open'; m.id = 'mKonfirmasiBerkas'; m.setAttribute('role', 'dialog'); m.setAttribute('aria-modal', 'true');
  m.innerHTML = '<div class="modal-box lg"><div class="modal-head"><h3>Periksa berkas sebelum disimpan</h3><button class="close" type="button" data-batal aria-label="Tutup">×</button></div>'
    + '<div class="modal-body"><p class="muted m-0 mb-12">Pastikan berkas yang dipilih sudah benar. Berkas baru tersimpan setelah Anda menekan <b>Ya, simpan</b>.</p><div class="konfirmasi-daftar"></div></div>'
    + '<div class="modal-foot"><button type="button" class="btn btn-outline" data-batal>Batal, pilih ulang</button><button type="button" class="btn btn-primary" data-ya>Ya, simpan</button></div></div>';
  const wadah = m.querySelector('.konfirmasi-daftar');
  daftar.forEach((input) => {
    Array.from(input.files).forEach((file) => {
      const ext = (file.name.split('.').pop() || '').toLowerCase();
      const url = URL.createObjectURL(file); urlKonfirmasi.push(url);
      const kartu = document.createElement('div'); kartu.className = 'konfirmasi-item';
      const pv = document.createElement('div'); pv.className = 'konfirmasi-pratinjau';
      if (/^image\//.test(file.type) || ['jpg', 'jpeg', 'png', 'webp', 'gif'].includes(ext)) {
        const img = document.createElement('img'); img.src = url; img.alt = 'Pratinjau ' + file.name;
        if (input.name === 'foto' || input.dataset.bulat !== undefined) pv.classList.add('bulat');
        if (input.dataset.kotak !== undefined) pv.classList.add('kotak');
        if (input.dataset.sekarang) {
          // Bandingkan gambar lama dengan gambar baru sebelum disimpan
          pv.classList.add('banding');
          const lama = document.createElement('figure'); const il = document.createElement('img'); il.src = input.dataset.sekarang; il.alt = 'Gambar saat ini';
          const fl = document.createElement('figcaption'); fl.textContent = 'Saat ini'; lama.append(il, fl);
          const panah = document.createElement('span'); panah.className = 'banding-panah'; panah.textContent = '→';
          const baru = document.createElement('figure'); const fb = document.createElement('figcaption'); fb.textContent = 'Baru'; baru.append(img, fb);
          pv.append(lama, panah, baru);
        } else pv.appendChild(img);
      } else if (ext === 'pdf' || file.type === 'application/pdf') {
        const o = document.createElement('object'); o.type = 'application/pdf'; o.data = url + '#toolbar=0&view=FitH';
        o.textContent = 'Pratinjau PDF tidak didukung di browser ini, tetapi berkas tetap bisa disimpan.'; pv.appendChild(o);
      } else { pv.textContent = ext.toUpperCase(); pv.classList.add('ikon'); }
      const info = document.createElement('div'); info.className = 'konfirmasi-info';
      const lb = document.createElement('small'); lb.textContent = labelBerkas(input);
      const nm = document.createElement('b'); nm.textContent = file.name;
      const uk = document.createElement('span'); uk.textContent = ext.toUpperCase() + ' · ' + formatUkuran(file.size);
      const buka = document.createElement('a'); buka.href = url; buka.target = '_blank'; buka.rel = 'noopener'; buka.textContent = 'Buka ukuran penuh';
      info.append(lb, nm, uk, buka);
      kartu.append(pv, info); wadah.appendChild(kartu);
    });
  });
  document.body.appendChild(m); document.body.classList.add('modal-terbuka');
  m.addEventListener('click', (ev) => {
    if (ev.target.closest('[data-ya]')) {
      tutupKonfirmasiBerkas();
      f.dataset.konfirmasiBerkas = '1';
      if (tombol && tombol.form === f) f.requestSubmit(tombol); else f.requestSubmit();
      setTimeout(() => { f.dataset.konfirmasiBerkas = ''; }, 2000);
      return;
    }
    if (ev.target.closest('[data-batal]') || ev.target === m) {
      tutupKonfirmasiBerkas();
      if (otomatis) daftar.forEach((i) => { i.value = ''; i.dispatchEvent(new Event('change', { bubbles: true })); });
    }
  });
  const ya = m.querySelector('[data-ya]'); ya && ya.focus();
}
document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && document.getElementById('mKonfirmasiBerkas')) tutupKonfirmasiBerkas(); });

/* ---------- C. Pratinjau berkas sebelum diunggah ---------- */
function initPratinjauBerkas() {
  let nomor = 0;
  $$('input[type="file"]:not([data-pratinjau])').forEach((input) => {
    if (input.closest('#regForm')) return;                  // pendaftaran punya ringkasan sendiri
    const id = 'pvAuto' + (++nomor);
    input.dataset.pratinjau = id;
    if (!input.dataset.tipe && input.accept) input.dataset.tipe = input.accept.split(',').map((x) => x.trim().replace(/^\./, '')).filter((x) => /^[a-z0-9]+$/.test(x)).join(',');
    const induk = input.closest('.upload') || input.closest('label') || input;
    const pesan = document.createElement('p'); pesan.className = 'pratinjau-pesan';
    const wadah = document.createElement('div'); wadah.className = 'pratinjau'; wadah.id = id;
    if (input.dataset.kirimOtomatis !== undefined || input.hidden || (induk !== input && induk.offsetParent === null && induk.classList.contains('btn'))) {
      induk.after(pesan);                                   // unggah cepat: pratinjau tampil di jendela konfirmasi
    } else induk.after(pesan, wadah);
  });
  $$('input[type="file"][data-pratinjau]').forEach((input) => {
    const wadah = document.getElementById(input.dataset.pratinjau);
    const blok = input.closest('.field') || input.closest('.panel') || input.parentNode;
    const indukInput = input.closest('.upload') || input.closest('label') || input;
    let pesan = indukInput.nextElementSibling && indukInput.nextElementSibling.classList.contains('pratinjau-pesan') ? indukInput.nextElementSibling : null;
    if (!pesan && wadah && wadah.previousElementSibling && wadah.previousElementSibling.classList.contains('pratinjau-pesan')) pesan = wadah.previousElementSibling;
    if (!pesan) pesan = $('.pratinjau-pesan', blok);
    const lama = $('[data-pamflet-lama]', blok);
    const tipe = (input.dataset.tipe || '').split(',').filter(Boolean);
    const maksKb = parseInt(input.dataset.maksKb || '2048', 10);
    let urlObjek = null;

    const tulisPesan = (t, galat) => { if (pesan) { pesan.textContent = t; pesan.classList.toggle('galat', !!galat); } };
    const bersihkan = () => {
      if (urlObjek) { URL.revokeObjectURL(urlObjek); urlObjek = null; }
      if (wadah) wadah.innerHTML = '';
      if (lama) lama.hidden = false;
    };

    input.addEventListener('change', () => {
      bersihkan();
      const f = input.files[0];
      if (!f) { tulisPesan(''); return; }
      const ext = (f.name.split('.').pop() || '').toLowerCase();
      if (tipe.length && !tipe.includes(ext)) {
        input.value = '';
        tulisPesan('Format .' + ext + ' tidak didukung. Gunakan ' + tipe.join(', ').toUpperCase() + '.', true);
        return;
      }
      if (f.size > maksKb * 1024) {
        input.value = '';
        tulisPesan('Ukuran ' + formatUkuran(f.size) + ' melebihi batas ' + formatUkuran(maksKb * 1024) + '. Perkecil berkasnya dulu.', true);
        return;
      }
      tulisPesan('');
      if (input.dataset.kirimOtomatis !== undefined) { bukaKonfirmasiBerkas(input.form, null, true); return; }
      if (!wadah) return;
      urlObjek = URL.createObjectURL(f);
      const pdf = ext === 'pdf' || f.type === 'application/pdf';
      const isi = document.createElement('div');
      if (pdf) {
        const o = document.createElement('object');
        o.className = 'pratinjau-pdf'; o.type = 'application/pdf'; o.data = urlObjek;
        o.textContent = 'Pratinjau PDF tidak didukung browser ini, tetapi berkas tetap bisa diunggah.';
        isi.appendChild(o);
      } else {
        const img = document.createElement('img');
        img.className = 'pratinjau-gambar'; img.alt = 'Pratinjau ' + f.name; img.src = urlObjek;
        img.onerror = () => { tulisPesan('Gambar tidak bisa dibaca. Pilih berkas lain.', true); input.value = ''; bersihkan(); };
        isi.appendChild(img);
      }
      const info = document.createElement('div');
      info.className = 'pratinjau-info';
      const nama = document.createElement('b'); nama.textContent = f.name;
      const detail = document.createElement('span'); detail.textContent = ext.toUpperCase() + ' · ' + formatUkuran(f.size) + (lama ? ' · menggantikan berkas lama setelah disimpan' : ' · belum disimpan');
      info.append(nama, detail);
      const aksi = document.createElement('div');
      aksi.className = 'pratinjau-aksi';
      aksi.innerHTML = '<button type="button" class="btn btn-sm btn-outline" data-aksi="ganti">Ganti</button><button type="button" class="btn btn-sm btn-outline btn-hapus-file" data-aksi="hapus">Hapus pilihan</button>';
      aksi.addEventListener('click', (ev) => {
        const b = ev.target.closest('button'); if (!b) return;
        if (b.dataset.aksi === 'ganti') input.click();
        else { input.value = ''; bersihkan(); tulisPesan(lama ? 'Pilihan dihapus. Berkas lama tetap dipakai.' : ''); }
      });
      wadah.append(isi, info, aksi);
      if (lama) lama.hidden = true;
    });
  });
}


/* ---------- G. Berkas dari pengiriman yang gagal tetap terpakai ----------
   Server menyimpan sementara berkas yang tadi sudah dipilih (BerkasSementara.php).
   Di sini ditampilkan kembali di samping kolom berkasnya, beserta pilihan
   "Ganti" (pilih berkas lain) dan "Jangan pakai". */
function initBerkasSementara() {
  const el = document.getElementById('dataBerkasSementara');
  if (!el) return;
  let data;
  try { data = JSON.parse(el.textContent); } catch (_) { return; }
  const base = data.base || '';
  $$('form').forEach((f) => {
    let jalur;
    try { jalur = new URL(f.getAttribute('action') || location.href, location.href).pathname; } catch (_) { return; }
    if (base && jalur.startsWith(base)) jalur = jalur.slice(base.length);
    jalur = jalur.replace(/^\/+|\/+$/g, '');
    const daftar = data.berkas[jalur];
    if (!daftar) return;
    Object.entries(daftar).forEach(([field, b]) => {
      const input = f.querySelector(`input[type="file"][name="${CSS.escape(field)}"]`);
      if (!input) return;
      input.dataset.adaSementara = '1';
      input.dataset.wajibAsli = input.required ? '1' : '';
      input.required = false;
      const kotak = document.createElement('div');
      kotak.className = 'berkas-sementara';
      const isi = document.createElement('div');
      isi.className = 'berkas-sementara-isi';
      if (b.gambar) { const img = document.createElement('img'); img.src = b.url; img.alt = ''; kotak.appendChild(img); }
      const judul = document.createElement('b'); judul.textContent = 'Berkas tadi masih tersimpan: ' + b.nama;
      const ket = document.createElement('span'); ket.textContent = formatUkuran(b.ukuran) + ' · dipakai otomatis saat formulir dikirim, tidak perlu memilih ulang.';
      const lihat = document.createElement('a'); lihat.href = b.url; lihat.target = '_blank'; lihat.rel = 'noopener'; lihat.textContent = 'Lihat';
      isi.append(judul, ket, lihat);
      const aksi = document.createElement('div');
      aksi.className = 'pratinjau-aksi';
      aksi.innerHTML = '<button type="button" class="btn btn-sm btn-outline" data-aksi="ganti">Ganti</button><button type="button" class="btn btn-sm btn-outline btn-hapus-file" data-aksi="buang">Jangan pakai</button>';
      kotak.append(isi, aksi);
      const wadah = input.closest('.upload, .field, label') || input;
      wadah.parentNode.insertBefore(kotak, wadah.nextSibling);
      aksi.addEventListener('click', (ev) => {
        const t = ev.target.closest('button'); if (!t) return;
        if (t.dataset.aksi === 'ganti') { input.click(); return; }
        const h = document.createElement('input');
        h.type = 'hidden'; h.name = 'hapus_sementara[' + field + ']'; h.value = '1';
        f.appendChild(h);
        delete input.dataset.adaSementara;
        input.required = input.dataset.wajibAsli === '1';
        kotak.remove();
      });
      input.addEventListener('change', () => { if (input.files.length) kotak.hidden = true; });
    });
  });
}


/* ---------- G. Pemulihan isian SEMUA formulir setelah gagal ----------
   Server mengirim isian terakhir (tanpa kata sandi/token) + jalur formulirnya.
   Formulir yang cocok diisi kembali; bila berada di dalam jendela modal,
   modalnya dibuka lagi supaya pengguna langsung melihat isiannya. */
function jalurForm(f, base) {
  let j;
  try { j = new URL(f.getAttribute('action') || location.href, location.href).pathname; } catch (_) { return ''; }
  if (base && j.startsWith(base)) j = j.slice(base.length);
  return j.replace(/^\/+|\/+$/g, '');
}
function initIsianLama() {
  const el = document.getElementById('dataIsianLama');
  if (!el) return;
  let data;
  try { data = JSON.parse(el.textContent); } catch (_) { return; }
  const isian = data.isian || {};
  const cocok = $$('form').filter((f) => {
    if ((f.method || '').toLowerCase() !== 'post' || jalurForm(f, data.base) !== data.jalur) return false;
    // Banyak formulir bisa ke alamat yang sama (mis. simpan-profil): cocokkan juga field "aksi"/"id".
    if ('aksi' in isian) {
      // Formulir harus benar-benar punya "aksi" yang sama (hidden, tombol, atau pilihan).
      const nilaiAksi = $$('[name="aksi"]', f).flatMap((x) => (x.tagName === 'SELECT' ? [...x.options].map((o) => o.value) : [x.value]));
      if (!nilaiAksi.includes(String(isian.aksi))) return false;
    }
    const hId = f.querySelector('input[type=hidden][name="id"]');
    if (hId && 'id' in isian && String(isian.id) !== hId.value) return false;
    return true;
  });
  // Beberapa formulir bisa cocok (mis. dua formulir "item_tambah"): pilih yang paling
  // banyak memiliki field dari isian tadi; bila seri, jangan menebak.
  const skor = (f) => Object.keys(isian).filter((k) => f.querySelector(`[name="${CSS.escape(k)}"], [name="${CSS.escape(k)}[]"]`)).length;
  cocok.sort((a, b) => skor(b) - skor(a));
  if (!cocok.length || (cocok.length > 1 && skor(cocok[0]) === skor(cocok[1]))) return;
  const f = cocok[0];
  // Formulir di dalam modal: buka lewat tombol pemicunya (yang mengatur judul/jenis), lalu isi.
  const modal = f.closest('.modal');
  if (modal && modal.id) {
    const pemicu = $$(`[data-open="${modal.id}"]`);
    const pas = pemicu.find((b) => Object.entries(b.dataset).some(([k, v]) => k !== 'open' && String(isian[k]) === v)) || null;
    if (pas) pas.click(); else openModal(modal.id);
    $$('input[type=hidden]', f).forEach((h) => { if (h.name in isian && !/csrf|token/i.test(h.name) && typeof isian[h.name] === 'string') h.value = isian[h.name]; });
  }
  Object.entries(isian).forEach(([nama, nilai]) => {
    if (/password|sandi|csrf|token/i.test(nama)) return;
    const namaField = Array.isArray(nilai) ? nama + '[]' : nama;
    const fields = $$(`[name="${CSS.escape(namaField)}"]`, f);
    fields.forEach((x) => {
      if (x.type === 'hidden' || x.type === 'file' || x.disabled) return;
      if (x.type === 'checkbox') x.checked = Array.isArray(nilai) ? nilai.map(String).includes(x.value) : String(nilai) === x.value || nilai === '1' || nilai === 'on';
      else if (x.type === 'radio') x.checked = String(nilai) === x.value;
      else if (typeof nilai === 'string' && x.value !== nilai) x.value = nilai;
      x.dispatchEvent(new Event('change', { bubbles: true }));
    });
  });
  const pane = f.closest('[data-pane]') || (f.hasAttribute('data-pane') ? f : null);
  if (pane) { const t = document.querySelector(`[data-tab="${pane.dataset.pane}"]`); if (t) t.click(); }
  const bawah = f.getBoundingClientRect().top > window.innerHeight;
  if (!modal && bawah) f.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/* ---------- F. Provinsi terisi otomatis dari kota/kabupaten ---------- */
function initIsiProvinsi() {
  const sumber = document.getElementById('petaKotaProvinsi');
  if (!sumber) return;
  let peta = {};
  try { peta = JSON.parse(sumber.textContent); } catch (_) { return; }
  const kunci = Object.keys(peta);
  const cari = (v) => {
    const t = v.trim().toLowerCase().replace(/^(kota|kabupaten|kab\.?)\s+/, '');
    if (!t) return null;
    const tepat = kunci.find((k) => k.toLowerCase() === v.trim().toLowerCase());
    if (tepat) return peta[tepat];
    const mirip = kunci.filter((k) => k.toLowerCase().replace(/^(kota|kabupaten)\s+/, '') === t);
    const prov = [...new Set(mirip.map((k) => peta[k]))];
    return prov.length === 1 ? prov[0] : null;   // "Malang" -> Jawa Timur (kota & kab. sama provinsinya)
  };
  $$('[data-isi-provinsi]').forEach((input) => {
    const sel = document.getElementById(input.dataset.isiProvinsi);
    if (!sel) return;
    const isi = () => {
      const p = cari(input.value);
      if (p && (!sel.value || sel.dataset.otomatis === '1')) {
        sel.value = p; sel.dataset.otomatis = '1';
        sel.dispatchEvent(new Event('change', { bubbles: true }));
      }
    };
    input.addEventListener('change', isi);
    input.addEventListener('input', isi);
    sel.addEventListener('change', (e) => { if (e.isTrusted) sel.dataset.otomatis = ''; });
    if (!sel.value) isi();
  });
}

/* ---------- B. Email terakhir di halaman Masuk / Lupa sandi ----------
   Disimpan hanya di browser ini (bukan kata sandi). */
function initIngatEmail() {
  $$('input[data-ingat-email]').forEach((i) => {
    if (!i.value) { const v = amanLS.get('karirku:emailTerakhir'); if (v) i.value = v; }
    const f = i.form;
    if (f) f.addEventListener('submit', () => { if (/^\S+@\S+\.\S+$/.test(i.value)) amanLS.set('karirku:emailTerakhir', i.value.trim()); });
  });
}

/* ---------- K. Isi cepat alasan ---------- */
function initTemplateAlasan() {
  document.addEventListener('click', (e) => {
    const b = e.target.closest('.chips-alasan button[data-alasan]');
    if (!b) return;
    const t = document.getElementById(b.closest('.chips-alasan').dataset.target);
    if (!t) return;
    const isi = b.dataset.alasan;
    t.value = t.value.trim() === '' ? isi : t.value.replace(/\s+$/, '') + '\n' + isi;
    t.focus();
    t.dispatchEvent(new Event('input', { bubbles: true }));
  });
  // Tombol buat sandi sementara acak (reset sandi oleh admin).
  document.addEventListener('click', (e) => {
    const b = e.target.closest('[data-sandi-acak]');
    if (!b) return;
    const t = document.getElementById(b.dataset.sandiAcak);
    if (!t) return;
    const h = 'abcdefghjkmnpqrstuvwxyz', a = '23456789';
    const pilih = (x) => x[Math.floor(Math.random() * x.length)];
    let v = pilih(h).toUpperCase();
    for (let i = 0; i < 5; i++) v += pilih(h);
    for (let i = 0; i < 4; i++) v += pilih(a);
    t.value = v; t.focus(); t.dispatchEvent(new Event('input', { bubbles: true })); t.select();
  });
  // Pilihan radio yang menampilkan kolom tambahan (reset sandi: kata sandi sementara).
  document.addEventListener('change', (e) => {
    const r = e.target;
    if (r.type !== 'radio' || !r.dataset.tampilkan) return;
    const target = $(r.dataset.tampilkan);
    if (!target) return;
    const tampil = !r.dataset.sembunyi;
    target.hidden = !tampil;
    $$('input', target).forEach((i) => { i.required = tampil; if (!tampil) i.value = ''; });
  });
}

/* ---------- Menu aksi "Kelola" (revisi tahap 2) ----------
   Hanya satu menu terbuka, tutup saat klik di luar / Esc,
   dan membuka ke atas bila ruang di bawah tidak cukup. */
function initMenuAksi() {
  const semua = () => $$('details.menu-aksi');
  document.addEventListener('toggle', (e) => {
    const d = e.target;
    if (!(d instanceof HTMLElement) || !d.matches('details.menu-aksi') || !d.open) return;
    semua().forEach((x) => { if (x !== d) x.open = false; });
    d.classList.remove('ke-atas');
    const isi = d.querySelector('.menu-aksi-isi');
    if (isi && isi.getBoundingClientRect().bottom > window.innerHeight - 8 && d.getBoundingClientRect().top > isi.offsetHeight + 16) {
      d.classList.add('ke-atas');
    }
  }, true);
  document.addEventListener('click', (e) => {
    semua().forEach((d) => {
      if (!d.open) return;
      if (!d.contains(e.target)) d.open = false;
      else if (e.target.closest('.menu-aksi-isi [data-open]')) d.open = false;
    });
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') semua().forEach((d) => { if (d.open) { d.open = false; d.querySelector('summary')?.focus(); } });
  });
}

// --- Jalankan saat halaman siap ---
document.addEventListener('DOMContentLoaded', () => {
  hydrateIcons();
  initPublicNav();
  initHero();
  initAppShell();
  initTabelKartu();
  initTombolKembali();
  initPenjagaFormulir();
  initDraftFormulir();
  initPratinjauBerkas();
  initTemplateAlasan();
  initBerkasSementara();
  initIsiProvinsi();
  initIsianLama();
  initIngatEmail();
  initMenuAksi();
});


/* ===== Penangan terpusat (pengganti atribut on* inline) ====================
   Atribut inline (onclick=, onchange=, javascript:) diblokir oleh Content-Security-
   Policy. Gantinya di HTML: data-auto-submit, data-href, data-konfirmasi, data-kembali. */
document.addEventListener('change', (e) => {
  const el = e.target;
  if (el && el.matches && el.matches('[data-auto-submit]') && el.form) el.form.submit();
});
document.addEventListener('click', (e) => {
  const t = e.target;
  if (!t || !t.closest) return;
  // [data-kembali] ditangani initTombolKembali() (riwayat browser bila dari situs ini, selain itu buka href).
  // Dulu baris ini ikut memanggil history.back() sehingga klik Kembali mundur DUA halaman.
  const ke = t.closest('[data-href]');
  if (ke) {
    try {
      const u = new URL(ke.dataset.href, location.href);
      if (u.origin === location.origin) location.href = u.href;   // hanya ke situs sendiri
    } catch (_) { /* abaikan */ }
  }
});
// (Konfirmasi form[data-konfirmasi] kini ditangani penjaga formulir dengan dialog di tengah layar.
//  Penangan lama di sini memanggil confirm() kedua kalinya, sehingga pengguna ditanya dua kali.)

// Beranda: tombol "Lihat semua mitra" membuka/menutup sisa daftar perusahaan mitra.
(function () {
  const tombol = document.getElementById('btn-mitra-semua');
  const daftar = document.getElementById('daftar-mitra');
  if (!tombol || !daftar) return;
  tombol.addEventListener('click', () => {
    const buka = daftar.classList.toggle('terbuka');
    tombol.setAttribute('aria-expanded', buka ? 'true' : 'false');
    tombol.textContent = buka ? tombol.dataset.tutup : tombol.dataset.lihat;
    if (!buka) daftar.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  });
})();

/* =====================================================================
   REVISI TAHAP 3
   R3a. Dialog pesan & konfirmasi di TENGAH layar
        (pengganti alert(), confirm(), dan gelembung validasi bawaan browser)
   R3b. Pesan validasi formulir dalam bahasa Indonesia + daftar isian yang salah
   R3c. Pesan galat dari server (flash merah) juga dibuka sebagai dialog
   R3d. Panduan kata sandi kuat (tampil sebelum pengguna menekan Lanjut/Simpan)
   ===================================================================== */

/* ---------- R3a. Dialog di tengah layar ---------- */
const DIALOG_TIPE = {
  bad:  { ikon: 'alert', judul: 'Ada yang perlu diperbaiki' },
  warn: { ikon: 'info',  judul: 'Perhatian' },
  ok:   { ikon: 'checkc', judul: 'Berhasil' },
  info: { ikon: 'info',  judul: 'Informasi' },
  tanya:{ ikon: 'info',  judul: 'Lanjutkan?' },
};
/**
 * bukaDialog({tipe, judul, pesan, daftar:[{label, pesan, el}], ya, batal, bahaya}) → Promise<boolean>
 * Semua teks dipasang lewat textContent, jadi isi dari pengguna/server tidak pernah dibaca sebagai HTML.
 */
function bukaDialog(opsi) {
  return new Promise((selesai) => {
    const o = Object.assign({ tipe: 'bad', ya: 'Mengerti', batal: null, bahaya: false, daftar: [] }, opsi || {});
    const t = DIALOG_TIPE[o.tipe] || DIALOG_TIPE.info;
    const lama = document.getElementById('dlgPusat');
    if (lama) lama.remove();
    const asal = document.activeElement;

    const m = document.createElement('div');
    m.className = 'dlg-pusat dlg-' + o.tipe;
    m.id = 'dlgPusat';
    m.setAttribute('role', o.batal ? 'alertdialog' : (o.tipe === 'bad' ? 'alertdialog' : 'dialog'));
    m.setAttribute('aria-modal', 'true');
    m.setAttribute('aria-labelledby', 'dlgJudul');
    m.setAttribute('aria-describedby', 'dlgIsi');
    m.innerHTML = '<div class="dlg-kotak" tabindex="-1">'
      + '<span class="dlg-ikon">' + ic(t.ikon) + '</span>'
      + '<h2 class="dlg-judul" id="dlgJudul"></h2>'
      + '<div class="dlg-isi" id="dlgIsi"><p class="dlg-pesan"></p><ul class="dlg-daftar"></ul></div>'
      + '<div class="dlg-aksi"></div></div>';
    m.querySelector('.dlg-judul').textContent = o.judul || t.judul;
    const p = m.querySelector('.dlg-pesan');
    if (o.pesan) p.textContent = o.pesan; else p.remove();

    const ul = m.querySelector('.dlg-daftar');
    (o.daftar || []).forEach((it) => {
      const li = document.createElement('li');
      if (it.el) {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'dlg-item';
        const lb = document.createElement('b'); lb.textContent = it.label;
        const ps = document.createElement('span'); ps.textContent = it.pesan;
        b.append(lb, ps);
        b.insertAdjacentHTML('beforeend', ic('right'));
        b.addEventListener('click', () => { tutup(false); fokusIsian(it.el); });
        li.appendChild(b);
      } else {
        const lb = document.createElement('b'); lb.textContent = it.label || '';
        const ps = document.createElement('span'); ps.textContent = it.pesan || '';
        li.className = 'dlg-item';
        if (it.label) li.append(lb);
        li.append(ps);
      }
      ul.appendChild(li);
    });
    if (!ul.children.length) ul.remove();

    const aksi = m.querySelector('.dlg-aksi');
    if (o.batal) {
      const bb = document.createElement('button');
      bb.type = 'button'; bb.className = 'btn btn-outline'; bb.textContent = o.batal;
      bb.addEventListener('click', () => tutup(false));
      aksi.appendChild(bb);
    }
    const by = document.createElement('button');
    by.type = 'button';
    by.className = 'btn ' + (o.bahaya ? 'btn-danger' : 'btn-primary');
    by.textContent = o.ya;
    by.addEventListener('click', () => tutup(true));
    aksi.appendChild(by);

    function tutup(hasil) {
      document.removeEventListener('keydown', tombol, true);
      m.classList.add('menutup');
      setTimeout(() => m.remove(), 140);
      document.documentElement.classList.remove('dlg-terbuka');
      if (!hasil && o.fokusSetelah) fokusIsian(o.fokusSetelah);
      else if (asal && asal.focus && document.contains(asal)) asal.focus({ preventScroll: true });
      selesai(hasil);
    }
    // Esc = batal; Tab dikunci di dalam dialog.
    function tombol(ev) {
      if (ev.key === 'Escape') { ev.preventDefault(); ev.stopPropagation(); tutup(false); return; }
      if (ev.key === 'Tab') {
        const f = [...m.querySelectorAll('button')];
        const i = f.indexOf(document.activeElement);
        if (ev.shiftKey && i <= 0) { ev.preventDefault(); f[f.length - 1].focus(); }
        else if (!ev.shiftKey && i === f.length - 1) { ev.preventDefault(); f[0].focus(); }
      }
    }
    document.addEventListener('keydown', tombol, true);
    m.addEventListener('click', (ev) => { if (ev.target === m) tutup(false); });

    document.body.appendChild(m);
    document.documentElement.classList.add('dlg-terbuka');
    (o.batal ? aksi.querySelector('.btn-outline') : by).focus();
  });
}
function fokusIsian(el) {
  if (!el) return;
  // Buka tab/langkah yang menyembunyikan isian bila ada (mis. tab di Profil).
  const panel = el.closest('[role="tabpanel"][hidden], .tab-pane:not(.active)');
  if (panel && panel.id) { const t = document.querySelector('[aria-controls="' + panel.id + '"], [data-tab="' + panel.id + '"]'); t && t.click(); }
  el.scrollIntoView({ block: 'center', behavior: 'smooth' });
  setTimeout(() => el.focus({ preventScroll: true }), 250);
}
const pesanDialog = (teks, judul, tipe) => bukaDialog({ tipe: tipe || 'bad', judul, pesan: teks });
const tanyaDialog = (teks, opsi) => bukaDialog(Object.assign({ tipe: 'tanya', pesan: teks, ya: 'Ya, lanjutkan', batal: 'Batal' }, opsi || {}));
window.KarirKu = Object.assign(window.KarirKu || {}, { dialog: bukaDialog, pesan: pesanDialog, tanya: tanyaDialog });

/* ---------- R3b. Validasi formulir: tanpa gelembung bawaan browser ---------- */
function labelIsian(el) {
  let t = '';
  if (el.id) { const l = document.querySelector('label[for="' + CSS.escape(el.id) + '"]'); if (l) t = l.textContent; }
  if (!t) { const f = el.closest('.field'); const l = f && f.querySelector('label'); if (l) t = l.textContent; }
  if (!t) t = el.getAttribute('aria-label') || el.placeholder || el.name || 'Isian';
  return t.replace(/\*|\(opsional\)|\(wajib\)/gi, '').replace(/\s+/g, ' ').trim();
}
function pesanIsian(el) {
  const v = el.validity;
  if (v.valueMissing) {
    if (el.type === 'checkbox') return 'Wajib dicentang untuk melanjutkan.';
    if (el.type === 'radio' || el.tagName === 'SELECT') return 'Belum dipilih.';
    if (el.type === 'file') return 'Berkas belum dipilih.';
    return 'Wajib diisi.';
  }
  if (v.typeMismatch) return el.type === 'email' ? 'Format email belum benar, contoh: nama@email.com.' : (el.type === 'url' ? 'Tautan harus lengkap, diawali https://' : 'Format belum benar.');
  if (v.tooShort) return 'Minimal ' + el.minLength + ' karakter (sekarang ' + el.value.length + ').';
  if (v.tooLong) return 'Maksimal ' + el.maxLength + ' karakter.';
  if (v.patternMismatch) return el.title || 'Format belum sesuai.';
  if (v.rangeUnderflow) return el.type === 'date' ? 'Tanggal paling cepat ' + el.min.split('-').reverse().join('/') + '.' : 'Paling kecil ' + el.min + '.';
  if (v.rangeOverflow) return el.type === 'date' ? 'Tanggal paling lambat ' + el.max.split('-').reverse().join('/') + '.' : 'Paling besar ' + el.max + '.';
  if (v.stepMismatch) return 'Nilainya tidak sesuai kelipatan yang diizinkan.';
  if (v.badInput) return 'Isian tidak valid.';
  return el.validationMessage || 'Isian belum benar.';
}
function tandaiIsian(el, pesan) {
  const f = el.closest('.field');
  if (!f) { el.classList.toggle('error', !!pesan); return; }
  f.classList.toggle('has-err', !!pesan);
  let err = f.querySelector(':scope > .err, :scope .err');
  if (pesan) {
    if (!err) { err = document.createElement('div'); err.className = 'err'; err.dataset.otomatis = '1'; f.appendChild(err); }
    if (err.dataset.otomatis || !err.textContent.trim()) err.textContent = pesan;
    else if (el.dataset.pesanSalah && err.textContent !== pesan) {
      // Pesan khusus (mis. kata sandi terlalu umum) menggantikan teks bawaan sementara.
      if (err.dataset.asli === undefined) err.dataset.asli = err.textContent;
      err.textContent = pesan;
    }
    el.setAttribute('aria-invalid', 'true');
  } else {
    el.removeAttribute('aria-invalid');
    if (err && err.dataset.asli !== undefined) { err.textContent = err.dataset.asli; delete err.dataset.asli; }
  }
}
/** Tampilkan daftar isian yang salah sebagai dialog di tengah layar. */
function tampilkanSalahIsian(daftarEl, judul) {
  const unik = [...new Set(daftarEl)];
  const daftar = unik.map((el) => {
    const pesan = el.dataset.pesanSalah || (el.validity && !el.validity.valid ? pesanIsian(el) : (el.closest('.field') && el.closest('.field').querySelector('.err') ? el.closest('.field').querySelector('.err').textContent.trim() : 'Isian belum benar.'));
    tandaiIsian(el, pesan);
    return { label: labelIsian(el), pesan, el };
  });
  return bukaDialog({
    tipe: 'bad',
    judul: judul || (daftar.length > 1 ? daftar.length + ' isian perlu diperbaiki' : 'Satu isian perlu diperbaiki'),
    pesan: 'Klik salah satu untuk langsung menuju isiannya.',
    daftar,
    ya: 'Perbaiki sekarang',
    fokusSetelah: unik[0],
  }).then(() => fokusIsian(unik[0]));
}
window.KarirKu.salahIsian = tampilkanSalahIsian;

(function () {
  let antre = [];
  let jadwal = null;
  // Peristiwa "invalid" muncul per isian saat form dikirim; kumpulkan dulu, tampilkan sekali.
  document.addEventListener('invalid', (e) => {
    const el = e.target;
    e.preventDefault();                       // matikan gelembung bawaan browser
    if (!el || el.disabled) return;
    if (el.type === 'radio' && antre.some((x) => x.type === 'radio' && x.name === el.name)) return;
    antre.push(el);
    clearTimeout(jadwal);
    jadwal = setTimeout(() => {
      const d = antre;
      antre = [];
      if (d.length) tampilkanSalahIsian(d);
    }, 0);
  }, true);
  // Begitu isian diperbaiki, tanda merahnya hilang (tanpa menunggu kirim ulang).
  const bersihkan = (e) => {
    const el = e.target;
    if (!el || !el.closest || !el.checkValidity) return;
    const f = el.closest('.field');
    if ((f && f.classList.contains('has-err')) || el.getAttribute('aria-invalid') === 'true') {
      if (el.checkValidity() && !el.dataset.pesanSalah) {
        tandaiIsian(el, '');
        const err = f && f.querySelector('.err[data-otomatis]');
        if (err) err.textContent = '';
      }
    }
  };
  document.addEventListener('input', bersihkan);
  document.addEventListener('change', bersihkan);
})();

/* ---------- R3c. Pesan galat dari server → dialog di tengah ---------- */
document.addEventListener('DOMContentLoaded', () => {
  const a = document.querySelector('.alert.flash.alert-bad');
  if (!a || a.dataset.tanpaDialog !== undefined) return;
  const butir = [...a.querySelectorAll('.daftar-error li')].map((li) => ({ pesan: li.textContent.trim() }));
  const teks = butir.length ? '' : [...a.querySelectorAll('span:not([data-ic])')].map((s) => s.textContent.trim()).join(' ').trim();
  const judul = a.closest('.auth-box, .auth') && /sandi|email|masuk/i.test(teks) ? 'Gagal masuk' : (butir.length ? 'Data belum disimpan' : 'Ada yang perlu diperbaiki');
  // Isian yang ditandai server (bila ada) jadi tujuan fokus setelah dialog ditutup.
  const pertama = document.querySelector('.field.has-err input, .field.has-err select, .field.has-err textarea');
  setTimeout(() => bukaDialog({ tipe: 'bad', judul, pesan: teks || 'Periksa hal berikut lalu kirim lagi:', daftar: butir, ya: 'Mengerti', fokusSetelah: pertama }), 120);
});

/* ---------- R3d. Panduan kata sandi kuat ---------- */
// Daftar & aturan WAJIB ini mengikuti validasiPassword() di app/helpers/validasi.php.
const SANDI_UMUM = ['password', 'password1', 'password12', 'password123', 'passw0rd', 'p@ssw0rd', '12345678', '123456789',
  '1234567890', '11111111', '00000000', '87654321', '12341234', '12344321', 'qwertyui', 'qwerty123',
  'qwertyuiop', 'asdfghjk', 'asdfgh123', 'zxcvbnm1', 'iloveyou', 'welcome1', 'admin123', 'admin1234',
  'administrator', 'abc12345', 'abcd1234', 'abcdefgh', 'a1234567', 'aa123456', '1q2w3e4r', '1qaz2wsx',
  'q1w2e3r4', 'qazwsx12', 'letmein1', 'monkey12', 'football', 'superman', 'princess', 'sunshine',
  'whatever', 'trustno1', 'master12', 'samsung1', 'bismillah', 'katasandi', 'kata sandi'];
const SANDI_DASAR = ['password', 'admin', 'qwerty', 'mahasiswa', 'perusahaan', 'polinema', 'indonesia', 'karirku', 'rahasia',
  'katasandi', 'welcome', 'iloveyou', 'letmein', 'bismillah', 'malang', 'sayang', 'cintaku', 'sandi'];
function sandiTerlaluUmum(s) {
  const p = s.toLowerCase();
  if (SANDI_UMUM.includes(p)) return true;
  const inti = p.replace(/[0-9!@#$%^&*._\-]+$/, '');
  if (inti !== p && SANDI_DASAR.includes(inti) && p.length - inti.length <= 4) return true;
  if (/^(.{1,3})\1+$/su.test(p)) return true;
  return false;
}
function nilaiSandi(s, pribadi) {
  const syarat = {
    panjang: s.length >= 8 && s.length <= 72,
    umum: s.length > 0 && !sandiTerlaluUmum(s),
    huruf: /[a-z]/.test(s) && /[A-Z]/.test(s),
    angka: /\d/.test(s),
    simbol: /[^A-Za-z0-9]/.test(s),
    pribadi: s.length > 0 && !pribadi.some((x) => x && x.length >= 3 && s.toLowerCase().includes(x.toLowerCase())),
    panjang12: s.length >= 12,
  };
  let skor = 0;
  if (syarat.panjang) skor++;
  if (syarat.huruf) skor++;
  if (syarat.angka) skor++;
  if (syarat.simbol) skor++;
  if (syarat.panjang12) skor++;
  if (!syarat.umum || !syarat.pribadi || !syarat.panjang) skor = Math.min(skor, 1);
  return { syarat, skor, wajibOk: syarat.panjang && syarat.umum };
}
function pasangPanduanSandi(input) {
  if (input.dataset.panduanTerpasang) return;
  input.dataset.panduanTerpasang = '1';
  const butuhAngkaHuruf = input.dataset.panduanSandi === 'huruf-angka';
  const kotak = document.createElement('div');
  kotak.className = 'panduan-sandi';
  kotak.id = (input.id || input.name) + 'Panduan';
  kotak.innerHTML = '<div class="ps-kepala"><span class="ps-ikon">' + ic('shield') + '</span><div><b>Cara membuat kata sandi yang aman</b>'
    + '<small>Wajib memenuhi 2 syarat pertama. Sisanya membuat kata sandi makin sulit ditebak.</small></div></div>'
    + '<div class="ps-meter" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i></div>'
    + '<p class="ps-level" aria-live="polite">Belum diisi</p>'
    + '<ul class="ps-daftar">'
    + '<li data-s="panjang" class="wajib">8 sampai 72 karakter <em>wajib</em></li>'
    + '<li data-s="umum" class="wajib">Bukan kata sandi umum seperti 12345678, password123, polinema2026 <em>wajib</em></li>'
    + '<li data-s="huruf"' + (butuhAngkaHuruf ? ' class="wajib"' : '') + '>Campuran huruf besar dan kecil' + (butuhAngkaHuruf ? ' <em>wajib</em>' : '') + '</li>'
    + '<li data-s="angka"' + (butuhAngkaHuruf ? ' class="wajib"' : '') + '>Mengandung angka' + (butuhAngkaHuruf ? ' <em>wajib</em>' : '') + '</li>'
    + '<li data-s="simbol">Mengandung simbol, misalnya ! ? # @ -</li>'
    + '<li data-s="pribadi">Tidak memuat nama, NIM, atau email kamu</li>'
    + '</ul>'
    + '<p class="ps-tips">' + ic('info') + '<span>Tips: gabungkan 3–4 kata acak yang mudah kamu ingat lalu tambahkan angka dan simbol, misalnya pola <b>Kata-Kata-Kata+Angka</b>. Jangan pakai kata sandi yang sama dengan akun lain.</span></p>';
  const field = input.closest('.field') || input.parentElement;
  const tempat = field.closest('.row2') || field;
  tempat.insertAdjacentElement('afterend', kotak);
  input.setAttribute('aria-describedby', ((input.getAttribute('aria-describedby') || '') + ' ' + kotak.id).trim());

  const form = input.form;
  const dataPribadi = () => {
    const ambil = (sel) => { const e = form && form.querySelector(sel); return e ? e.value : ''; };
    const email = ambil('[type=email], [name=email]') || (input.dataset.email || '');
    const nama = ambil('[name=nama]') || ambil('[name=nama_perusahaan]') || (input.dataset.nama || '');
    return [email.split('@')[0], ...nama.split(/\s+/), ambil('[name=nim]')].filter(Boolean);
  };
  const LEVEL = ['Belum diisi', 'Lemah', 'Cukup', 'Lumayan kuat', 'Kuat', 'Sangat kuat'];
  const perbarui = () => {
    const s = input.value;
    const tersimpan = input.dataset.tersimpan && s === '';
    const h = nilaiSandi(s, dataPribadi());
    kotak.querySelectorAll('.ps-daftar li').forEach((li) => {
      const ok = s.length > 0 && h.syarat[li.dataset.s];
      li.classList.toggle('ok', ok);
      li.classList.toggle('kurang', s.length > 0 && !ok);
    });
    const skor = s.length === 0 ? 0 : Math.max(1, h.skor);
    kotak.dataset.skor = tersimpan ? 'tersimpan' : skor;
    kotak.querySelectorAll('.ps-meter i').forEach((i, k) => i.classList.toggle('on', k < skor));
    kotak.querySelector('.ps-level').textContent = tersimpan ? 'Memakai kata sandi yang sudah tersimpan' : (s.length === 0 ? LEVEL[0] : (h.wajibOk ? LEVEL[skor] : 'Belum memenuhi syarat wajib'));
    let salah = '';
    if (s.length && !h.syarat.panjang) salah = 'Kata sandi harus 8 sampai 72 karakter.';
    else if (s.length && !h.syarat.umum) salah = 'Kata sandi ini terlalu umum dan mudah ditebak. Pilih yang lain.';
    else if (s.length && butuhAngkaHuruf && !(/[A-Za-z]/.test(s) && /\d/.test(s))) salah = 'Kata sandi harus berisi huruf dan angka.';
    input.setCustomValidity(salah);
    input.dataset.pesanSalah = salah;
    if (!salah) delete input.dataset.pesanSalah;
  };
  input.addEventListener('input', perbarui);
  form && form.addEventListener('input', (e) => { if (e.target !== input && /email|nama|nim/.test(e.target.name || '')) perbarui(); });
  perbarui();
}
function initPanduanSandi(root = document) {
  root.querySelectorAll('input[data-panduan-sandi]').forEach(pasangPanduanSandi);
}
document.addEventListener('DOMContentLoaded', () => initPanduanSandi());
// Dialog/modal yang dibuka belakangan (mis. reset sandi oleh admin) ikut dipasangi panduan.
document.addEventListener('click', (e) => { if (e.target.closest && e.target.closest('[data-open]')) setTimeout(() => initPanduanSandi(), 0); });
// Ulangi kata sandi: beri tahu langsung bila belum sama.
document.addEventListener('input', (e) => {
  const el = e.target;
  if (!el || !el.form || !/konfirmasi_password/.test(el.name || '')) return;
  const asal = el.form.querySelector('input[data-panduan-sandi]');
  if (!asal) return;
  el.setCustomValidity(el.value && el.value !== asal.value ? 'Belum sama dengan kata sandi di atas.' : '');
});


/* =====================================================================
   R4. MODE APLIKASI DI HP (<= 768px) — pasangan style.css bagian 33
   ===================================================================== */
const mqHp = window.matchMedia('(max-width: 768px)');

const LABEL_FILTER = {
  jurusan_id: 'Jurusan', bidang_id: 'Bidang', lokasi: 'Lokasi', jenis_pekerjaan: 'Jenis pekerjaan', urutan: 'Urutkan',
  status: 'Status', status_akun: 'Status akun', angkatan: 'Angkatan', lowongan_id: 'Lowongan', perusahaan_id: 'Perusahaan',
  prodi_id: 'Program studi', status_mahasiswa: 'Status mahasiswa', status_karier: 'Status karier', sistem_kerja: 'Sistem kerja',
  tanggal_dari: 'Dari tanggal', tanggal_sampai: 'Sampai tanggal', urut: 'Urutkan', sort: 'Urutkan',
};
function labelFilter(el) {
  const l = el.id && document.querySelector('label[for="' + CSS.escape(el.id) + '"]');
  if (l) return l.textContent.trim();
  const wadah = el.closest('label');
  if (wadah && wadah.querySelector('span')) {
    const t = wadah.querySelector('span').textContent.trim();
    if (t.length > 2) return t.charAt(0).toUpperCase() + t.slice(1);
  }
  if (LABEL_FILTER[el.name]) return LABEL_FILTER[el.name];
  const a = el.getAttribute('aria-label');
  if (a) return a;
  if (el.tagName === 'SELECT' && el.options.length) {
    const t = el.options[0].textContent.trim().replace(/^Semua\s+/i, '');
    return t.charAt(0).toUpperCase() + t.slice(1);
  }
  return el.placeholder || el.name;
}

/** Formulir filter (banyak pilihan) → kotak cari + tombol Filter yang membuka lembar dari bawah. */
function filterJadiLembar(form, i) {
  const pilihan = [...form.querySelectorAll('select, input:not([type=search]):not([type=hidden]):not([name=q]):not([type=submit])')]
    .filter((el) => !el.closest('noscript'));
  if (pilihan.length < 2) return;
  const id = 'lembarFilter' + i;
  const aktif = pilihan.filter((el) => (el.value || '') !== '' && !(el.tagName === 'SELECT' && el.selectedIndex === 0)).length;

  const tombol = document.createElement('button');
  tombol.type = 'button';
  tombol.className = 'btn-filter';
  tombol.dataset.open = id;
  tombol.setAttribute('aria-label', 'Filter' + (aktif ? ', ' + aktif + ' aktif' : ''));
  tombol.innerHTML = ic('sliders') + (aktif ? '<span class="jml">' + aktif + '</span>' : '');

  const m = document.createElement('div');
  m.className = 'modal';
  m.id = id;
  m.setAttribute('role', 'dialog');
  m.setAttribute('aria-modal', 'true');
  m.setAttribute('aria-labelledby', id + 'J');
  m.innerHTML = '<div class="modal-box"><div class="modal-head"><h3 id="' + id + 'J">Filter</h3>'
    + '<button class="close" type="button" data-close aria-label="Tutup" data-ic="x"></button></div>'
    + '<div class="modal-body filter-isi"></div>'
    + '<div class="modal-foot"><a class="btn btn-outline" data-reset>Reset</a><button class="btn btn-primary" type="submit">Terapkan</button></div></div>';
  const isi = m.querySelector('.filter-isi');
  pilihan.forEach((el, k) => {
    if (!el.id) el.id = id + 'f' + k;
    const f = document.createElement('div');
    f.className = 'field';
    const lb = document.createElement('label');
    lb.htmlFor = el.id;
    lb.textContent = labelFilter(el);
    // Di lembar, pilihan tidak langsung mengirim; pengguna menekan "Terapkan".
    el.removeAttribute('data-auto-submit');
    const wadahLama = el.closest('label');
    f.append(lb, el);
    isi.appendChild(f);
    if (wadahLama && wadahLama !== f && wadahLama.closest('form') === form) wadahLama.remove();
  });
  // Tombol kirim & "Hapus filter" lama digantikan tombol di lembar.
  const hapus = form.querySelector('a.btn-link');
  const reset = m.querySelector('[data-reset]');
  reset.href = hapus ? hapus.href : (form.getAttribute('action') || location.pathname);
  if (hapus) hapus.remove();
  form.querySelectorAll(':scope > button[type=submit], :scope > .btn[type=submit]').forEach((b) => b.remove());

  const cari = form.querySelector('input[type=search], input[name=q]');
  if (cari) cari.insertAdjacentElement('afterend', tombol); else form.prepend(tombol);
  form.appendChild(m);
  form.classList.add('filter-hp');
  hydrateIcons(m);
}

function initAppHp() {
  if (!document.querySelector('.nav-bawah')) return;
  // Judul besar (page-head) → judul kecil di app bar disembunyikan.
  if (document.querySelector('.page .page-head h1')) document.body.classList.add('ada-judul-besar');
  // Halaman turunan: tombol Kembali pindah ke app bar.
  // Halaman yang ada di menu bawah tidak perlu Kembali; halaman lain (Notifikasi, Pengaturan,
  // Disimpan, menu "Lainnya", detail, formulir) mendapat tombol Kembali di app bar.
  const tb = document.querySelector('.tb-kembali');
  const diMenuBawah = [...document.querySelectorAll('.nav-bawah a[href]')].some((a) => a.pathname === location.pathname);
  const asal = document.querySelector('.page .kepala-halaman' + (diMenuBawah ? ':not(.akar)' : '') + ' .btn-kembali');
  if (tb && asal) {
    tb.href = asal.href;
    if (!asal.hasAttribute('data-kembali')) tb.removeAttribute('data-kembali');
    tb.hidden = false;
    document.body.classList.add('ada-kembali');
  }
  if (mqHp.matches) {
    document.querySelectorAll('form.filters').forEach(filterJadiLembar);
  }
  // Pindah antara tampilan HP dan laptop (memutar tablet, mengubah ukuran jendela): susun ulang.
  let awal = mqHp.matches;
  const saatBerubah = (e) => {
    if (e.matches !== awal && document.querySelector('.filter-hp, form.filters')) location.reload();
    awal = e.matches;
  };
  if (mqHp.addEventListener) mqHp.addEventListener('change', saatBerubah); else mqHp.addListener(saatBerubah);
}
document.addEventListener('DOMContentLoaded', initAppHp);

// Tombol Bagikan (detail lowongan, HP): lembar bagikan bawaan HP, cadangannya salin tautan.
document.addEventListener('click', (e) => {
  const b = e.target.closest && e.target.closest('[data-bagikan]');
  if (!b) return;
  const data = { title: b.dataset.bagikan, url: location.href };
  if (navigator.share) {
    navigator.share(data).catch(() => {});
  } else if (navigator.clipboard) {
    navigator.clipboard.writeText(location.href).then(() => toast('Tautan lowongan disalin.')).catch(() => {});
  }
});
