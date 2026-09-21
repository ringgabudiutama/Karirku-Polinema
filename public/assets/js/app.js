/* KarirKu Polinema - skrip bersama (prototipe) */
const ICONS = {
  home:'<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/><path d="M10 21v-6h4v6"/>',
  briefcase:'<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M3 12h18"/>',
  bookmark:'<path d="M6 3h12v18l-6-4-6 4z"/>',
  file:'<path d="M14 3H6v18h12V7z"/><path d="M14 3v4h4"/><path d="M9 13h6M9 17h6"/>',
  user:'<circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/>',
  users:'<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c1-3.5 3.5-5 6.5-5s5.5 1.5 6.5 5"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M18 15c1.8.6 3 2.2 3.5 5"/>',
  bell:'<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 21h4"/>',
  settings:'<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  logout:'<path d="M15 4h4v16h-4"/><path d="M10 8l-4 4 4 4"/><path d="M6 12h10"/>',
  search:'<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>',
  check:'<path d="M5 12.5 10 17l9-10"/>',
  checkc:'<circle cx="12" cy="12" r="9"/><path d="m8 12.5 3 3 5-6"/>',
  x:'<path d="M6 6l12 12M18 6 6 18"/>',
  building:'<rect x="4" y="3" width="16" height="18" rx="1"/><path d="M9 7h2M13 7h2M9 11h2M13 11h2M9 15h2M13 15h2M10 21v-3h4v3"/>',
  send:'<path d="M21 3 10 14"/><path d="M21 3 14 21l-4-7-7-4z"/>',
  chart:'<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>',
  clipboard:'<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V3h6v1"/><path d="m9 13 2 2 4-4"/>',
  shield:'<path d="M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z"/><path d="m9 12 2 2 4-4"/>',
  menu:'<path d="M4 6h16M4 12h16M4 18h16"/>',
  chevron:'<path d="m6 9 6 6 6-6"/>',
  left:'<path d="m15 18-6-6 6-6"/>',
  right:'<path d="m9 18 6-6-6-6"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  download:'<path d="M12 4v11"/><path d="m7 10 5 5 5-5"/><path d="M4 20h16"/>',
  upload:'<path d="M12 16V5"/><path d="m7 9 5-5 5 5"/><path d="M4 20h16"/>',
  eye:'<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  pin:'<path d="M12 21s-7-6.2-7-12a7 7 0 0 1 14 0c0 5.8-7 12-7 12z"/><circle cx="12" cy="9" r="2.5"/>',
  calendar:'<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  link:'<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
  image:'<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="m21 16-5-5-9 9"/>',
  copy:'<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h3"/>',
  lock:'<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  hourglass:'<path d="M7 3h10M7 21h10"/><path d="M8 3c0 5 8 5 8 9s-8 4-8 9M16 3c0 5-8 5-8 9s8 4 8 9"/>',
  alert:'<path d="M12 3 2 20h20z"/><path d="M12 10v4M12 17v.5"/>',
  info:'<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8v.5"/>',
  mail:'<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>',
  phone:'<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>',
  chat:'<path d="M4 5h16v11H9l-5 4z"/>',
  graduation:'<path d="M2 9 12 4l10 5-10 5z"/><path d="M6 11v5c3 2.5 9 2.5 12 0v-5"/><path d="M22 9v6"/>',
  target:'<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
  handshake:'<path d="m11 17 2 2a1.5 1.5 0 0 0 2-2"/><path d="m14 14 2.5 2.5a1.5 1.5 0 0 0 2-2L15 11"/><path d="M3 11l4-4 5 1 3-2 6 5-3 3"/><path d="M7 7 3 11l7 7a1.5 1.5 0 0 0 2-2"/>',
  wand:'<path d="m4 20 11-11"/><path d="m14 5 1-2 1 2 2 1-2 1-1 2-1-2-2-1zM19 12l.7-1.3L21 10l-1.3-.7L19 8l-.7 1.3L17 10l1.3.7z"/>',
  trending:'<path d="m3 17 6-6 4 4 8-8"/><path d="M15 7h6v6"/>',
  trash:'<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
  edit:'<path d="M4 20h4L19 9l-4-4L4 16z"/>',
  whatsapp:'<path d="M4 20l1.3-4A8 8 0 1 1 8 18.7z"/><path d="M9 9.5c.3 2 2.3 4.3 5 5l1-1.3 1.8.8c-.3 1.2-1.3 1.8-2.5 1.6-2.8-.5-5.8-3.3-6.3-6.3-.2-1.2.4-2.2 1.6-2.5l.8 1.8z"/>',
  ban:'<circle cx="12" cy="12" r="9"/><path d="m6 6 12 12"/>',
  instagram:'<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><path d="M17.5 6.5v.01"/>',
  facebook:'<path d="M15 3h-2.5A3.5 3.5 0 0 0 9 6.5V10H6.5v3.5H9V21h3.5v-7.5H15l.5-3.5h-3V7a1 1 0 0 1 1-1H15z"/>',
  external:'<path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/>',
  refresh:'<path d="M20 11a8 8 0 0 0-14-5l-2 2"/><path d="M4 4v4h4"/><path d="M4 13a8 8 0 0 0 14 5l2-2"/><path d="M20 20v-4h-4"/>'
};
function ic(name, cls=''){ return `<svg class="icon ${cls}" viewBox="0 0 24 24" aria-hidden="true">${ICONS[name]||''}</svg>`; }
function hydrateIcons(root=document){
  root.querySelectorAll('[data-ic]').forEach(el=>{ if(!el.dataset.done){ el.insertAdjacentHTML('afterbegin', ic(el.dataset.ic)); el.dataset.done=1; } });
}
const $ = (s,r=document)=>r.querySelector(s);
const $$ = (s,r=document)=>[...r.querySelectorAll(s)];

/* ---------- Toast ---------- */
function toast(msg){
  let w=$('.toast-wrap'); if(!w){ w=document.createElement('div'); w.className='toast-wrap'; w.setAttribute('role','status'); document.body.appendChild(w); }
  const t=document.createElement('div'); t.className='toast'; t.innerHTML=ic('checkc')+`<span>${msg}</span>`;
  w.appendChild(t); setTimeout(()=>t.remove(),3200);
}

/* ---------- Modal ---------- */
function openModal(id){ const m=document.getElementById(id); if(!m) return; m.classList.add('open'); const f=m.querySelector('input,select,textarea,button:not(.close)'); f&&f.focus(); }
function closeModal(el){ (el.closest? el.closest('.modal'):el).classList.remove('open'); }
document.addEventListener('click',e=>{
  const o=e.target.closest('[data-open]'); if(o){ e.preventDefault(); openModal(o.dataset.open); }
  if(e.target.closest('[data-close]')) closeModal(e.target.closest('.modal'));
  if(e.target.classList.contains('modal')) closeModal(e.target);
  const tt=e.target.closest('[data-toast]'); if(tt){ e.preventDefault(); toast(tt.dataset.toast); }
});
document.addEventListener('keydown',e=>{ if(e.key==='Escape'){ $$('.modal.open').forEach(m=>m.classList.remove('open')); $$('.pop.open').forEach(p=>p.classList.remove('open')); } });

/* ---------- Tabs (generic) ---------- */
document.addEventListener('click',e=>{
  const b=e.target.closest('[data-tab]'); if(!b) return;
  const group=b.closest('[data-tabs]'); if(!group) return;
  $$('[data-tab]',group).forEach(x=>x.classList.toggle('active',x===b));
  const scope=document.getElementById(group.dataset.tabs);
  if(scope) $$('[data-pane]',scope).forEach(p=>p.hidden = p.dataset.pane!==b.dataset.tab);
  group.dispatchEvent(new CustomEvent('tabchange',{detail:b.dataset.tab}));
});

/* ---------- Password toggle & upload name ---------- */
document.addEventListener('click',e=>{
  const b=e.target.closest('.pw button'); if(!b) return;
  const i=b.parentElement.querySelector('input'); i.type = i.type==='password'?'text':'password';
  b.setAttribute('aria-label', i.type==='password'?'Tampilkan kata sandi':'Sembunyikan kata sandi');
});
document.addEventListener('change',e=>{
  const i=e.target; if(i.type!=='file') return;
  const box=i.closest('.upload'); if(box){ let n=box.querySelector('.name'); if(!n){n=document.createElement('div');n.className='name';box.appendChild(n);} n.textContent = i.files[0] ? 'Terpilih: '+i.files[0].name : ''; }
  if(i.dataset.preview && i.files[0]){ const img=document.getElementById(i.dataset.preview); if(img){ img.src=URL.createObjectURL(i.files[0]); img.hidden=false; } }
});

/* ---------- Public navbar ---------- */
function initPublicNav(){
  const nav=$('.nav'); if(!nav) return;
  const fab=$('.fab'); const onScroll=()=>{ nav.classList.toggle('solid', window.scrollY>40 || nav.classList.contains('menu-open')); if(fab) fab.classList.toggle('show', window.scrollY>window.innerHeight*0.6); };
  onScroll(); window.addEventListener('scroll',onScroll,{passive:true});
  $$('.dropdown > button',nav).forEach(b=>b.addEventListener('click',e=>{ e.stopPropagation(); const d=b.parentElement; const open=!d.classList.contains('open'); $$('.dropdown',nav).forEach(x=>x.classList.remove('open')); d.classList.toggle('open',open); b.setAttribute('aria-expanded',open); }));
  document.addEventListener('click',()=>$$('.dropdown',nav).forEach(x=>x.classList.remove('open')));
  const t=$('.nav-toggle',nav); t&&t.addEventListener('click',()=>{ nav.classList.toggle('menu-open'); t.setAttribute('aria-expanded',nav.classList.contains('menu-open')); onScroll(); });
  $$('.nav-links a',nav).forEach(a=>a.addEventListener('click',()=>{ nav.classList.remove('menu-open'); onScroll(); }));
}

/* ---------- Hero slider ---------- */
function initHero(){
  const hero=$('.hero'); if(!hero) return;
  const slides=$$('.hero-slide',hero), tabs=$$('.hero-tab',hero), texts=$$('.hero-text',hero);
  const reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;
  let i=0, timer;
  function go(n){
    i=(n+slides.length)%slides.length;
    slides.forEach((s,k)=>s.classList.toggle('active',k===i));
    texts.forEach((s,k)=>s.hidden = k!==i);
    tabs.forEach((t,k)=>{ t.classList.remove('active'); void t.offsetWidth; t.classList.toggle('active',k===i); t.setAttribute('aria-selected',k===i); });
    clearTimeout(timer); if(!reduce && !hero.classList.contains('paused')) timer=setTimeout(()=>go(i+1),7000);
  }
  tabs.forEach((t,k)=>t.addEventListener('click',()=>go(k)));
  if(reduce) hero.classList.add('paused');
  hero.addEventListener('mouseenter',()=>{}); 
  go(0);
}

/* ---------- App shell ---------- */
function initApp(defaultView){
  // popovers
  $$('[data-pop]').forEach(b=>b.addEventListener('click',e=>{ e.stopPropagation(); const p=document.getElementById(b.dataset.pop); const open=!p.classList.contains('open'); $$('.pop').forEach(x=>x.classList.remove('open')); p.classList.toggle('open',open); }));
  document.addEventListener('click',e=>{ if(!e.target.closest('.pop')) $$('.pop').forEach(x=>x.classList.remove('open')); });
  // mobile menu
  const side=$('.side'); $$('.menu-toggle').forEach(b=>b.addEventListener('click',e=>{ e.stopPropagation(); side.classList.toggle('open'); }));
  document.addEventListener('click',e=>{ if(side && side.classList.contains('open') && !e.target.closest('.side')) side.classList.remove('open'); });
  // router
  function show(){
    const raw=(location.hash||'#'+defaultView).slice(1);
    const [view,param]=raw.split('/');
    const el=document.getElementById('v-'+view) || document.getElementById('v-'+defaultView);
    $$('.view').forEach(v=>v.classList.toggle('active',v===el));
    const key=el.dataset.menu || el.id.slice(2);
    $$('.menu a').forEach(a=>a.classList.toggle('active',a.getAttribute('href')==='#'+key));
    if(side) side.classList.remove('open');
    if(window.onView) window.onView(el.id.slice(2),param);
    window.scrollTo(0,0);
    document.title = (el.dataset.title||'KarirKu') + ' | KarirKu Polinema';
  }
  window.addEventListener('hashchange',show); show();
  // mark notifications read
  $$('[data-readall]').forEach(b=>b.addEventListener('click',e=>{ e.preventDefault(); $$('.unread').forEach(x=>x.classList.remove('unread')); $$('.dot').forEach(d=>d.remove()); toast('Semua notifikasi ditandai sudah dibaca'); }));
}
function go(hash){ location.hash=hash; }

/* ---------- Data dummy ---------- */
const JOBS=[
 {id:1,pos:'Web Developer',co:'PT Nusantara Digital',ini:'ND',color:'#1446A0',loc:'Malang',type:'Penuh waktu',mode:'Hybrid',field:'Teknologi Informasi',dl:'30 Okt 2026',days:43,quota:3,filled:1,salary:'Rp5-7 juta',jur:['Teknologi Informasi','Teknik Elektro'],status:'aktif',applicants:24},
 {id:2,pos:'Drafter Sipil',co:'PT Arta Konstruksi',ini:'AK',color:'#AA6414',loc:'Surabaya',type:'Kontrak',mode:'Di kantor',field:'Konstruksi',dl:'19 Sep 2026',days:2,quota:2,filled:0,salary:'Dirahasiakan',jur:['Teknik Sipil'],status:'aktif',applicants:11},
 {id:3,pos:'Teknisi Listrik',co:'CV Sinar Elektrik',ini:'SE',color:'#19785A',loc:'Malang',type:'Penuh waktu',mode:'Di lapangan',field:'Kelistrikan',dl:'12 Okt 2026',days:25,quota:4,filled:2,salary:'Rp4-5 juta',jur:['Teknik Elektro'],status:'aktif',applicants:9},
 {id:4,pos:'Analis Laboratorium',co:'PT Kimia Farma Jaya',ini:'KF',color:'#78286E',loc:'Pasuruan',type:'Penuh waktu',mode:'Di kantor',field:'Kimia',dl:'5 Nov 2026',days:49,quota:2,filled:0,salary:'Rp5 juta',jur:['Teknik Kimia'],status:'aktif',applicants:6},
 {id:5,pos:'Staf Akuntansi',co:'KAP Wijaya & Rekan',ini:'WR',color:'#1E5A8C',loc:'Malang',type:'Magang berbayar',mode:'Di kantor',field:'Keuangan',dl:'20 Sep 2026',days:3,quota:3,filled:0,salary:'Rp2,5 juta',jur:['Akuntansi','Administrasi Niaga'],status:'aktif',applicants:15},
 {id:6,pos:'Operator CNC',co:'PT Mesin Presisi',ini:'MP',color:'#962828',loc:'Sidoarjo',type:'Penuh waktu',mode:'Di pabrik',field:'Manufaktur',dl:'28 Okt 2026',days:41,quota:5,filled:5,salary:'Rp4,8 juta',jur:['Teknik Mesin'],status:'ditutup',applicants:31},
];
const jobById=id=>JOBS.find(j=>j.id==id)||JOBS[0];
const STATUS_LABEL={diajukan:'Diajukan',screening:'Screening CV',interview:'Interview',diterima:'Diterima',ditolak:'Ditolak',dibatalkan:'Dibatalkan',aktif:'Aktif',ditutup:'Ditutup',nonaktif:'Dinonaktifkan',menunggu:'Menunggu verifikasi',perbaikan:'Perlu perbaikan'};
const pill=s=>`<span class="pill p-${s}">${STATUS_LABEL[s]||s}</span>`;
const logo=j=>`<span class="logo-sq" style="background:${j.color}">${j.ini}</span>`;
const JURUSAN=['Teknik Sipil','Teknik Mesin','Teknik Elektro','Teknik Kimia','Akuntansi','Administrasi Niaga','Teknologi Informasi'];

document.addEventListener('DOMContentLoaded',()=>{ document.querySelectorAll('.jur-filter').forEach(s=>JURUSAN.forEach(j=>s.add(new Option(j,j)))); hydrateIcons(); initPublicNav(); initHero(); });
