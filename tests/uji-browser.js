const { chromium } = require('playwright');
const B=process.env.APP_URL||'http://127.0.0.1:8000';
const ok=(l,c,i='')=>console.log((c?'  ok     ':'  GAGAL  ')+l+(c?'':' -> '+i));
async function masuk(p,e,pw){await p.goto(B+'/masuk');await p.fill('input[name=email]',e);await p.fill('input[name=password]',pw);await Promise.all([p.waitForNavigation(),p.click('form button[type=submit]')]);}
(async()=>{
 const br=await chromium.launch(); const ctx=await br.newContext({viewport:{width:390,height:900}}); const p=await ctx.newPage();
 const err=[]; p.on('pageerror',e=>err.push(e.message)); await p.route(/fonts\.g/,r=>r.abort());
 p.on('dialog',d=>d.accept());
 await masuk(p,'perusahaan@polinema.ac.id','perusahaan123');
 await p.goto(B+'/lowongan/form-pasang');
 await p.fill('input[name=posisi]','Draft Uji Browser'); await p.fill('textarea[name=deskripsi]','isi deskripsi');
 await p.waitForTimeout(900);
 ok('status draft tampil', /Draft tersimpan/.test(await p.textContent('[data-draft-status]')||''));
 await p.setInputFiles('input[name=pamflet]',require('path').join(__dirname,'..','public/assets/img/hero-1.jpg'));
 ok('pratinjau gambar muncul', await p.locator('.pratinjau-gambar').count()===1);
 ok('nama & ukuran berkas tampil', /hero-1\.jpg/.test(await p.textContent('.pratinjau-info')));
 await p.click('.pratinjau-aksi [data-aksi=hapus]');
 ok('hapus pilihan mengosongkan', await p.locator('.pratinjau-gambar').count()===0 && await p.$eval('input[name=pamflet]',i=>i.files.length)===0);
 await p.setInputFiles('input[name=pamflet]',{name:'x.exe',mimeType:'application/octet-stream',buffer:Buffer.from('MZ')});
 ok('tipe salah ditolak di browser', /tidak didukung/.test(await p.textContent('.pratinjau-pesan')));
 p.removeAllListeners('dialog'); p.on('dialog',d=>d.accept());
 await p.goto(B+'/perusahaan/dashboard'); await p.goto(B+'/lowongan/form-pasang');
 ok('banner pulihkan draft muncul', await p.locator('.draft-banner').count()===1);
 await p.click('.draft-banner [data-aksi=pulihkan]');
 ok('draft dipulihkan', await p.inputValue('input[name=posisi]')==='Draft Uji Browser');
 // tombol kembali
 await p.goto(B+'/perusahaan/lowongan'); await p.goto(B+'/lowongan/form-pasang/4');
 await p.click('a[data-kembali]'); await p.waitForLoadState();
 ok('tombol Kembali ke halaman sebelumnya', p.url().endsWith('/perusahaan/lowongan'), p.url());
 // admin chips + modal reset
 const p2=await (await br.newContext({viewport:{width:390,height:900}})).newPage(); p2.on('pageerror',e=>err.push(e.message)); await p2.route(/fonts\.g/,r=>r.abort());
 await masuk(p2,'admin@polinema.ac.id','admin123');
 const lid=await (async()=>{await p2.goto(B+'/admin/persetujuan-lowongan'); const h=await p2.getAttribute('a[href*="detail-lowongan/"]','href'); return h;})();
 await p2.goto(new URL(lid, B + "/").href);
 if (await p2.locator('.chips-alasan button').count()) { await p2.locator('.chips-alasan button').first().click(); ok('chip mengisi alasan', (await p2.inputValue('#alasanLowongan')).length>10); }
 else ok('chip alasan ada',false,'tidak ada chip');
 await p2.fill('#alasanLowongan','');
 let dialog=''; p2.on('dialog',d=>{if(d.type()==='beforeunload'){d.accept();return;} dialog=d.message();d.dismiss();});
 await p2.click('button[value=revisi]'); await p2.waitForTimeout(300);
 ok('revisi tanpa alasan dicegah di browser', /minimal 10/.test(dialog), dialog);
 await p2.goto(B+'/admin/profil-mahasiswa/1');
 const tb=p2.locator('[data-open*="reset"], [data-open*="Reset"]').first();
 if (await tb.count()) { await tb.click(); const r=p2.locator('input[type=radio][value=sementara]'); await r.check(); ok('pilih sandi sementara menampilkan kolom', await p2.locator('input[name=password_sementara]').isVisible()); }
 else ok('tombol reset sandi ada',false);
 ok('tidak ada error JS', err.length===0, err.join(' | '));
 await br.close();
})();
