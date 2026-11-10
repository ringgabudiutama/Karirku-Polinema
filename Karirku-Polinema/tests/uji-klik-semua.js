/**
 * ROBOT PENGGUNA: membuka setiap halaman untuk 4 peran, mengklik setiap tombol,
 * lalu mengisi dan mengirim SETIAP formulir lewat browser sungguhan (Playwright).
 *
 * Yang dilaporkan sebagai masalah:
 *  - error JavaScript di halaman
 *  - tombol yang diklik tetapi tidak terjadi apa-apa (tombol mati)
 *  - halaman error / 404 / 500 / "tidak ditemukan" setelah klik atau kirim formulir
 *  - formulir yang dikirim dengan isian wajar tetapi ditolak (pesan merah)
 *
 * Jalankan (server harus hidup, database baru dimuat):
 *   node tests/uji-klik-semua.js            (NODE_PATH ke playwright bila perlu)
 * Skrip ini MENGUBAH data. Muat ulang database (00-INSTAL-ULANG.sql) setelahnya.
 */
const { chromium } = require('playwright');
const { execFileSync } = require('child_process');
const path = require('path');

const B = (process.env.APP_URL || 'http://127.0.0.1:8000').replace(/\/$/, '');
const ROOT = path.join(__dirname, '..');
const JPG = path.join(ROOT, 'public/assets/img/dok-ktm.jpg');
const PDF = path.join(__dirname, 'contoh.pdf');
const PGENV = { ...process.env, PGPASSWORD: process.env.DB_PASS || 'postgres' };
const sql = (q) => execFileSync('psql', ['-h', process.env.DB_HOST || '127.0.0.1', '-U', process.env.DB_USER || 'postgres', '-d', process.env.DB_NAME || 'karirku_polinema', '-tAc', q], { env: PGENV }).toString().trim();

const AKUN = {
  tamu: null,
  mahasiswa: ['mahasiswa@polinema.ac.id', 'mahasiswa123', 'mahasiswa/dashboard'],
  perusahaan: ['perusahaan@polinema.ac.id', 'perusahaan123', 'perusahaan/dashboard'],
  admin: ['admin@polinema.ac.id', 'admin123', 'admin/dashboard'],
};
const AWAL = {
  tamu: ['beranda', 'masuk', 'daftar', 'auth/lupa-sandi', 'mitra/1'],
  mahasiswa: ['mahasiswa/dashboard'], perusahaan: ['perusahaan/dashboard'], admin: ['admin/dashboard'],
};
// Alamat yang sengaja tidak dibuka robot (mengakhiri sesi robot sendiri).
const LEWATI = /(^|\/)(keluar|auth\/keluar)(\?|$)|unduh\.php|generate-cv|unduh-|\.pdf$/;

// Simpan sandi asli akun demo agar bisa dipulihkan setelah formulir ganti sandi diuji.
const HASH = {};
for (const e of ['admin@polinema.ac.id', 'mahasiswa@polinema.ac.id', 'perusahaan@polinema.ac.id']) {
  HASH[e] = sql(`select password_hash from pengguna where email='${e}'`);
}
function pulihkanAkunDemo() {
  for (const [e, h] of Object.entries(HASH)) {
    sql(`update pengguna set password_hash='${h}', status_akun='aktif', wajib_ganti_sandi=false where email='${e}'`);
  }
}

const masalah = [];
const lapor = (peran, hal, jenis, info) => {
  const baris = `${peran.padEnd(10)} /${hal}  [${jenis}] ${String(info).replace(/\s+/g, ' ').slice(0, 260)}`;
  if (!masalah.includes(baris)) { masalah.push(baris); console.log('  MASALAH ' + baris); }
};

const POLA_GALAT = /(Fatal error|Warning<\/b>|Notice<\/b>|Uncaught|SQLSTATE|Terjadi kesalahan pada server|Halaman tidak ditemukan|Data tidak ditemukan|Berkas tidak ditemukan|tidak ditemukan\.<\/)/i;

function polaJalur(u) { return u.split('?')[0].replace(/\/\d+(?=\/|$)/g, '/N').replace(/[a-f0-9]{16,64}/g, 'K'); }

async function masuk(p, peran) {
  const a = AKUN[peran];
  if (!a) return;
  await p.goto(B + '/masuk');
  await p.fill('input[name=email]', a[0]);
  await p.fill('input[name=password]', a[1]);
  await Promise.all([p.waitForNavigation(), p.click('form button[type=submit]')]);
  if (p.url().includes('ganti-sandi-wajib')) { pulihkanAkunDemo(); await masuk(p, peran); }
}

async function buka(p, url) {
  for (let k = 0; k < 3; k++) {
    try { return await p.goto(url, { waitUntil: 'load' }); } catch (e) { if (!/interrupted|destroyed|ERR_ABORTED/.test(e.message) || k === 2) throw e; await p.waitForTimeout(300); }
  }
}

async function pastikanMasuk(p, peran) {
  if (!AKUN[peran]) return;
  const r = await buka(p, B + '/' + AKUN[peran][2]);
  if (p.url().includes('/masuk') || p.url().includes('status-akun') || p.url().includes('ganti-sandi')) {
    pulihkanAkunDemo();
    await masuk(p, peran);
  }
}

/** Isi semua field formulir dengan data wajar, lalu kirim. */
async function isiDanKirim(p, peran, idx) {
  const info = await p.evaluate(({ idx, sandi, aneh }) => {
    const f = document.querySelectorAll('form')[idx];
    if (!f) return null;
    // Robot mengirim formulir sendiri di akhir: matikan kirim-otomatis saat field berubah.
    document.querySelectorAll('[onchange*="submit"]').forEach((el) => el.removeAttribute('onchange'));
    document.querySelectorAll('[data-kirim-otomatis]').forEach((el) => el.removeAttribute('data-kirim-otomatis'));
    const hariIni = new Date();
    const tgl = (d) => { const x = new Date(hariIni.getTime() + d * 864e5); return x.toISOString().slice(0, 10); };
    const acak = Math.floor(Math.random() * 1e6);
    const ANEH = ['x'.repeat(600), '-5', '99999999999', "' OR 1=1 --", '<script>alert(1)</script>', '1900-01-01', '2999-12-31', '   ', '0'];
    const pilihAneh = () => ANEH[Math.floor(Math.random() * ANEH.length)];
    const isiTeks = (el) => {
      const n = (el.name || '').toLowerCase();
      if (aneh) { el.value = pilihAneh(); return; }
      if (el.value && el.value.trim() !== '') return;          // pertahankan isian otomatis dari server
      if (/nim/.test(n)) return el.value = String(2241700000 + acak).slice(0, 10);
      if (/kode_pos/.test(n)) return el.value = '65141';
      if (/(whatsapp|wa|telepon|hp|kontak_wa|nomor)/.test(n)) return el.value = '0812' + String(10000000 + acak).slice(0, 8);
      if (/email/.test(n)) return el.value = 'uji' + acak + '@uji.id';
      if (/(website|tautan|link|url)/.test(n)) return el.value = 'https://contoh.id/uji';
      if (/(tahun|angkatan)/.test(n)) return el.value = '2023';
      if (/ipk/.test(n)) return el.value = '3.50';
      if (/kuota/.test(n)) return el.value = '3';
      if (/jam/.test(n)) return el.value = '10:00';
      if (/(tanggal|batas)/.test(n)) return el.value = tgl(14);
      if (/(alasan|catatan|keterangan|pesan)/.test(n)) return el.value = 'Alasan uji otomatis yang cukup panjang dan jelas.';
      return el.value = 'Uji otomatis ' + acak;
    };
    const fields = [...f.querySelectorAll('input, select, textarea')].filter((el) => el.name && !el.disabled);
    const berkas = [];
    for (const el of fields) {
      const t = (el.type || '').toLowerCase();
      if (t === 'hidden' || t === 'submit' || t === 'button') continue;
      if (t === 'file') { berkas.push({ name: el.name, accept: el.accept || '' }); continue; }
      if (t === 'password') {
        const n = el.name.toLowerCase();
        el.value = /(lama|admin|saat_ini|sekarang)/.test(n) ? sandi : (/sementara/.test(n) ? 'Sementara123' : 'GantiUji123');
        continue;
      }
      if (t === 'checkbox') { if (el.required || /setuju|benar|data_benar|bukan_outsourcing|agree/.test(el.name) || !f.querySelector(`input[name="${el.name}"]:checked`)) el.checked = true; continue; }
      if (t === 'radio') { if (!f.querySelector(`input[name="${CSS.escape(el.name)}"]:checked`)) { const r = [...f.querySelectorAll(`input[name="${CSS.escape(el.name)}"]`)].find((x) => !x.disabled); if (r) r.checked = true; } continue; }
      if (el.tagName === 'SELECT') {
        if (!el.value) { const o = [...el.options].find((x) => x.value !== '' && !x.disabled && !x.hidden); if (o) el.value = o.value; }
        el.dispatchEvent(new Event('change', { bubbles: true }));
        if (!el.value) { const o = [...el.options].find((x) => x.value !== '' && !x.disabled); if (o) el.value = o.value; }
        continue;
      }
      if (aneh && t === 'date') { el.value = ['1900-01-01', '2999-12-31', tgl(-400)][acak % 3]; continue; }
      if (aneh && t === 'number') { el.value = ['-5', '0', '99999999999', '3.7'][acak % 4]; continue; }
      if (aneh && (t === 'email' || t === 'url' || t === 'tel')) { el.value = pilihAneh(); continue; }
      if (aneh && el.tagName === 'SELECT' && el.options.length) { const o = document.createElement('option'); o.value = '999999'; el.appendChild(o); el.value = acak % 2 ? '999999' : el.options[0].value; continue; }
      if (t === 'date') { if (!el.value) el.value = tgl(14); continue; }
      if (t === 'time') { if (!el.value) el.value = '10:00'; continue; }
      if (t === 'number') { if (!el.value) el.value = el.min && +el.min > 0 ? el.min : '3'; continue; }
      if (t === 'email') { if (!el.value) el.value = 'uji' + acak + '@uji.id'; continue; }
      if (t === 'url') { if (!el.value) el.value = 'https://contoh.id/uji'; continue; }
      if (t === 'tel') { if (!el.value) el.value = '081234567890'; continue; }
      isiTeks(el);
    }
    // Konfirmasi sandi harus sama dengan sandi baru.
    const baru = f.querySelector('input[name*="baru"][type=password], input[name="password"][type=password]');
    f.querySelectorAll('input[type=password][name*="konfirmasi"], input[type=password][name*="ulang"]').forEach((k) => { if (baru) k.value = baru.value; });
    const tombol = [...f.querySelectorAll('button[type=submit], button:not([type]), input[type=submit]')].filter((b) => !b.disabled);
    return {
      action: f.getAttribute('action') || location.pathname, method: (f.method || 'get').toLowerCase(),
      berkas, tombol: tombol.map((b) => (b.name ? b.name + '=' + b.value : '') + '|' + (b.textContent || b.value || '').trim().slice(0, 40)),
    };
  }, { idx, sandi: AKUN[peran] ? AKUN[peran][1] : '', aneh: !!process.env.ANEH });
  if (!info) return null;
  if (!info.tombol.length) return null;          // semua tombol kirim sengaja dinonaktifkan (mis. SMTP belum diisi)

  for (const b of info.berkas) {
    const pdf = /pdf/.test(b.accept) && !/jpg|jpeg|png|image/.test(b.accept);
    const pilih = /cv|surat|ijazah|sertifikat|transkrip/.test(b.name) && /pdf/.test(b.accept) ? PDF : (pdf ? PDF : JPG);
    try { await p.locator('form').nth(idx).locator(`input[type=file][name="${b.name}"]`).first().setInputFiles(pilih, { timeout: 3000 }); } catch (_) {}
  }
  return info;
}

async function cekHasil(p, peran, asal, label, resp) {
  const st = resp ? resp.status() : 0;
  let html = '';
  try { html = await p.content(); } catch (_) { return; }
  const hal = p.url().replace(B + '/', '');
  if (st >= 400) lapor(peran, asal, label, `HTTP ${st} di /${hal}`);
  const g = html.match(POLA_GALAT);
  if (g) lapor(peran, asal, label, `halaman error "${g[0].replace(/<[^>]+>/g, '')}" di /${hal}`);
  if (AKUN[peran] && /\/masuk(\?|$)/.test(p.url())) lapor(peran, asal, label, 'terlempar ke halaman masuk');
  const merah = await p.$$eval('.alert.flash.alert-bad', (xs) => xs.map((x) => x.textContent.trim().replace(/\s+/g, ' ')));
  return merah;
}

(async () => {
  const br = await chromium.launch();
  const ringkas = {};
  for (const peran of Object.keys(AKUN).filter((r) => !process.env.PERAN || process.env.PERAN.split(',').includes(r))) {
    console.log(`=== ${peran} ===`);
    const ctx = await br.newContext({ viewport: { width: 1280, height: 900 } });
    const p = await ctx.newPage();
    await p.route(/fonts\.(googleapis|gstatic)/, (r) => r.abort());
    const errJs = [];
    p.on('pageerror', (e) => errJs.push(e.message));
    p.on('dialog', (d) => d.accept().catch(() => {}));
    await masuk(p, peran);

    // ---------- 1. Kumpulkan halaman ----------
    const antre = [...AWAL[peran]], sudah = new Set(), perPola = {};
    const halaman = [];
    while (antre.length && halaman.length < 140) {
      const h = antre.shift();
      if (sudah.has(h) || LEWATI.test(h)) continue;
      sudah.add(h);
      const pol = polaJalur(h);
      perPola[pol] = (perPola[pol] || 0) + 1;
      if (perPola[pol] > 2) continue;
      errJs.length = 0;
      let resp;
      try { resp = await p.goto(B + '/' + h, { waitUntil: 'load' }); } catch (e) { lapor(peran, h, 'buka', e.message); continue; }
      await cekHasil(p, peran, h, 'buka', resp);
      if (errJs.length) lapor(peran, h, 'error JS', errJs.join(' | '));
      halaman.push(h);
      const tautan = await p.$$eval('a[href]', (as) => as.map((a) => a.getAttribute('href')));
      for (let t of tautan) {
        if (!t || /^(#|mailto:|tel:|javascript:|https?:\/\/(?!127\.0\.0\.1|localhost))/i.test(t)) continue;
        try { const u = new URL(t, p.url()); if (u.origin !== new URL(B).origin) continue; t = (u.pathname + u.search).replace(new URL(B).pathname.replace(/\/$/, ''), '').replace(/^\//, ''); } catch (_) { continue; }
        if (t && !sudah.has(t) && !t.startsWith('assets/')) antre.push(t);
      }
    }
    console.log(`  ${halaman.length} halaman unik dibuka`);

    // ---------- 2. Klik setiap tombol non-kirim ----------
    let tombolDiuji = 0;
    for (const h of halaman) {
      await pastikanMasuk(p, peran);
      await buka(p, B + '/' + h);
      const jumlah = await p.$$eval('button', (bs) => bs.length);
      for (let i = 0; i < jumlah; i++) {
        const b = p.locator('button').nth(i);
        let meta;
        try {
          meta = await b.evaluate((el) => ({
            submit: el.type === 'submit' && !!el.form, terlihat: !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length),
            teks: (el.textContent || el.getAttribute('aria-label') || '').trim().replace(/\s+/g, ' ').slice(0, 40),
            dalamModal: !!el.closest('.modal'), disabled: el.disabled,
          }));
        } catch (_) { continue; }
        if (meta.submit || !meta.terlihat || meta.disabled || meta.dalamModal) continue;
        tombolDiuji++;
        errJs.length = 0;
        const urlSebelum = p.url();
        await p.evaluate(() => { window.__ubah = 0; window.__mo && window.__mo.disconnect(); window.__mo = new MutationObserver((m) => { window.__ubah += m.length; }); window.__mo.observe(document.body, { subtree: true, childList: true, attributes: true, characterData: true }); });
        try { await b.click({ timeout: 3000 }); } catch (e) { continue; }
        await p.waitForTimeout(250);
        let berubah = 0;
        try { berubah = await p.evaluate(() => window.__ubah || 0); } catch (_) { berubah = 1; }
        if (errJs.length) lapor(peran, h, `klik "${meta.teks}"`, 'error JS: ' + errJs.join(' | '));
        if (p.url() === urlSebelum && berubah === 0) lapor(peran, h, `klik "${meta.teks}"`, 'tombol tidak melakukan apa-apa');
        if (p.url() !== urlSebelum) { await cekHasil(p, peran, h, `klik "${meta.teks}"`, null); await buka(p, B + '/' + h); }
        else { await p.keyboard.press('Escape').catch(() => {}); await p.evaluate(() => document.querySelectorAll('.modal.open, .modal.show, .modal[open]').forEach((m) => m.classList.remove('open', 'show'))).catch(() => {}); }
      }
    }
    console.log(`  ${tombolDiuji} tombol diklik`);

    // ---------- 3. Isi dan kirim setiap formulir ----------
    let formDiuji = 0; const formSudah = new Set();
    for (const h of halaman) {
      await pastikanMasuk(p, peran);
      await buka(p, B + '/' + h);
      const nForm = await p.$$eval('form', (fs) => fs.length);
      for (let i = 0; i < nForm; i++) {
        await pastikanMasuk(p, peran);
        await buka(p, B + '/' + h);
        const sebelum = await p.$$eval('form', (fs, i) => fs[i] ? (fs[i].getAttribute('action') || '') + '|' + fs[i].method + '|' + fs[i].querySelectorAll('[name]').length : '', i);
        if (!sebelum) continue;
        const kunciForm = polaJalur(h) + '#' + polaJalur(sebelum);
        if (formSudah.has(kunciForm)) continue;
        formSudah.add(kunciForm);
        if (/keluar/.test(sebelum)) continue;
        if (/proses-daftar/.test(sebelum)) continue;   // pendaftaran diuji khusus (uji-daftar di uji-browser.js)
        if (peran === 'tamu' && /proses-masuk|proses-lupa-sandi/.test(sebelum)) continue; // robot memakai email acak: ditolak itu benar
        errJs.length = 0;
        const info = await isiDanKirim(p, peran, i);
        if (!info) continue;
        formDiuji++;
        let resp = null;
        try {
          const nav = p.waitForNavigation({ timeout: 10000 }).catch(() => null);
          await p.evaluate((i) => setTimeout(() => {
            const f = document.querySelectorAll('form')[i];
            const t = [...f.querySelectorAll('button[type=submit], button:not([type]), input[type=submit]')].find((b) => !b.disabled && !/tolak|nonaktif|hapus|batal|revisi/i.test(b.textContent + ' ' + (b.value || '')))
              || [...f.querySelectorAll('button[type=submit], button:not([type]), input[type=submit]')].find((b) => !b.disabled);
            f.noValidate = true;
            if (t) f.requestSubmit(t); else f.requestSubmit();
          }, 0), i);
          // Revisi tahap 2: form berisi berkas memunculkan jendela konfirmasi dulu -> tekan "Ya, simpan".
          const ya = await p.waitForSelector('#mKonfirmasiBerkas [data-ya]', { timeout: 1500 }).catch(() => null);
          if (ya) await ya.click().catch(() => {});
          resp = await nav;
        } catch (e) { lapor(peran, h, `kirim form ${info.action}`, e.message); continue; }
        if (!resp) {
          const pesan = await p.$$eval('.has-err .err, .pratinjau-pesan.galat', (xs) => xs.filter((x) => x.offsetParent).map((x) => x.textContent.trim())).catch(() => []);
          lapor(peran, h, `kirim form ${info.action}`, 'formulir tidak terkirim' + (pesan.length ? ': ' + pesan.join('; ') : ' (tidak ada reaksi)'));
          continue;
        }
        const merah = await cekHasil(p, peran, h, `kirim form ${info.action}`, resp);
        if (errJs.length) lapor(peran, h, `kirim form ${info.action}`, 'error JS: ' + errJs.join(' | '));
        if (merah && merah.length && !process.env.ANEH) lapor(peran, h, `kirim form ${info.action}`, 'DITOLAK: ' + merah.join(' / '));
        if (merah && merah.length && process.env.ANEH && /gangguan sistem|tidak sesuai aturan|Struktur database|terlalu panjang\. Persingkat|format tidak valid \(|terlalu besar/.test(merah.join(' '))) lapor(peran, h, `kirim form ${info.action}`, 'LOLOS KE DATABASE: ' + merah.join(' / '));
        pulihkanAkunDemo();
      }
    }
    console.log(`  ${formDiuji} formulir dikirim`);
    ringkas[peran] = { halaman: halaman.length, tombol: tombolDiuji, form: formDiuji };
    pulihkanAkunDemo();
    await ctx.close();
  }
  await br.close();
  console.log('\nRingkasan:', JSON.stringify(ringkas));
  console.log(`TOTAL MASALAH: ${masalah.length}`);
  process.exit(masalah.length ? 1 : 0);
})();
