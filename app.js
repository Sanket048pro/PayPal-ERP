const U=API.session(); if(!U) location.href='login.html';
const inr=n=>'₹'+Number(n||0).toLocaleString('en-IN');
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const badge=s=>`<span class="badge b-${esc(String(s).toLowerCase().replace(/ /g,'-'))}">${esc(s)}</span>`;
const $=s=>document.querySelector(s);
function toast(m){const d=document.createElement('div');d.textContent=m;$('#toast').append(d);setTimeout(()=>d.remove(),2800)}

/* Module definitions: cols for table, form fields [key,label,type,options] */
const ST={enq:['New','Under Review','Quotation','Approved','Rejected','Converted to Project'],proj:['Planning','Design','Estimation','Material','Execution','Testing','Completed','Closed'],pri:['Low','Medium','High']};
const MOD={
 clients:{t:'Clients',cols:[['name','Organization'],['contact','Contact'],['city','City'],['gst','GST'],['status','Status']],form:[['name','Organization'],['contact','Contact person'],['city','City'],['gst','GST no.'],['status','Status','select',['Active','Inactive']]]},
 enquiries:{t:'Enquiries',cols:[['date','Date'],['client','Client'],['requirement','Requirement'],['priority','Priority'],['status','Status']],form:[['client','Client'],['requirement','Requirement'],['priority','Priority','select',ST.pri],['status','Status','select',ST.enq]],defaults:{date:new Date().toISOString().slice(0,10)}},
 quotations:{t:'Quotations',cols:[['date','Date'],['client','Client'],['total','Total','inr'],['status','Status']],form:[['client','Client'],['total','Total (₹)','number'],['status','Status','select',['Draft','Sent','Approved','Rejected']]],defaults:{date:new Date().toISOString().slice(0,10)}},
 projects:{t:'Projects',cols:[['name','Project'],['client','Client'],['value','Value','inr'],['status','Stage'],['pct','Done','pct']],form:[['name','Project name'],['client','Client'],['value','Value (₹)','number'],['status','Stage','select',ST.proj],['pct','Completion %','number'],['priority','Priority','select',ST.pri]]},
 estimation:{t:'Estimation',cols:[['code','Code'],['boq','BOQ item'],['item','Estimation item (master)'],['unit','Unit'],['qty','Qty'],['rate','Rate','inr'],['amount','Amount','inr']],form:[['boq','BOQ item'],['item','Master item name'],['unit','Unit'],['qty','Quantity','number'],['rate','Rate','number']],calc:r=>r.amount=(+r.qty||0)*(+r.rate||0)},
 materials:{t:'Material requests',cols:[['project','Project'],['item','Item'],['qty','Qty'],['priority','Priority'],['status','Status']],form:[['project','Project no.'],['item','Item'],['qty','Quantity','number'],['priority','Priority','select',ST.pri],['status','Status','select',['Requested','Approved','Purchase','Received','Allocated','Completed']]]},
 inventory:{t:'Stock',cols:[['item','Item'],['qty','On hand'],['reorder','Reorder level']],form:[['item','Item'],['qty','On hand','number'],['reorder','Reorder level','number']]},
 invoices:{t:'Invoices & payments',cols:[['no','Invoice'],['client','Client'],['amount','Gross','inr'],['paid','Paid','inr'],['due','Due date'],['status','Status']],form:[['no','Invoice no.'],['client','Client'],['amount','Gross amount','number'],['paid','Paid so far','number'],['due','Due date','date'],['status','Status','select',['Issued','Part Paid','Paid','Overdue']]]},
 tickets:{t:'Support & service calls',cols:[['project','Project'],['subject','Subject'],['status','Status']],form:[['project','Project no.'],['subject','Subject'],['status','Status','select',['Open','In Progress','Resolved','Closed']]]},
 master_items:{t:'Master items / price list',cols:[['code','Code'],['name','Item name'],['unit','Unit'],['price','Price','inr'],['status','Status']],form:[['code','Item code'],['name','Item name (official)'],['unit','Unit'],['price','Price','number'],['aliases','Aliases (comma separated)'],['status','Status','select',['Active','Inactive']]]},
 employees:{t:'Employees',cols:[['name','Name'],['dept','Department'],['designation','Designation'],['status','Status']],form:[['name','Name'],['dept','Department'],['designation','Designation'],['status','Status','select',['Active','Inactive']]]},
 boq:{t:'BOQ matching',custom:true}, logs:{t:'Audit log',custom:true}
};
/* Department -> allowed modules. UI-level only; real enforcement = MySQL grants / server (see README). */
const ACC={ADMIN:Object.keys(MOD),SALES:['clients','enquiries','quotations','master_items'],ACCOUNTS:['invoices'],ENG:['projects','estimation','boq','tickets'],PURCHASE:['inventory','materials','master_items'],CLIENT:['projects','invoices','tickets','enquiries']};
const TITLE={ADMIN:'Management dashboard',SALES:'Sales & Marketing',ACCOUNTS:'Accounts & Billing',ENG:'Engineering / Technical',PURCHASE:'Purchase & Inventory',CLIENT:'Client portal'};
const mods=ACC[U.dept]||[];
const own=(t,rows)=>U.client_id&&rows[0]&&'client_id' in rows[0]?rows.filter(r=>r.client_id===U.client_id):rows;
const canWrite=t=>U.dept!=='CLIENT'||['enquiries','tickets'].includes(t);

function shell(){
  $('#side').innerHTML=`<h2>PayPal ERP</h2><small>${esc(U.role)}</small><br><br><a data-m="home" class="on">Dashboard</a>${mods.map(m=>`<a data-m="${m}">${MOD[m].t}</a>`).join('')}`;
  $('#who').textContent=U.name;
  $('#side').onclick=e=>{const m=e.target.dataset.m;if(!m)return;document.querySelectorAll('#side a').forEach(a=>a.classList.toggle('on',a===e.target));$('#side').classList.remove('open');m==='home'?dash():mod(m)};
  $('#out').onclick=()=>{API.logout();location.href='login.html'};
  $('#menu').onclick=()=>$('#side').classList.toggle('open');
  $('#gs').onkeydown=e=>{if(e.key==='Enter')gsearch(e.target.value)};
  dash();
}
function bars(obj,total){const t=total||Math.max(1,...Object.values(obj));return Object.entries(obj).map(([k,v])=>`<div class="row"><span>${esc(k)}</span><div class="bar"><i style="width:${v/t*100}%"></i></div><b>${v}</b></div>`).join('')}
const cnt=(rows,k)=>rows.reduce((o,r)=>(o[r[k]]=(o[r[k]]||0)+1,o),{});
function kpi(a){return `<div class="kpis">${a.map(([n,l])=>`<div class="card kpi"><b>${n}</b><span>${l}</span></div>`).join('')}</div>`}
function dash(){
  const L=t=>own(t,API.list(t)), P=L('projects'), E=L('enquiries'), I=L('invoices'), S=API.list('inventory');
  let h=`<h1>${TITLE[U.dept]}</h1>`, d=U.dept;
  if(d==='ADMIN'){const billed=I.reduce((s,i)=>s+i.amount,0),rec=I.reduce((s,i)=>s+i.paid,0),pur=API.list('materials').length*42000;
    h+=kpi([[API.list('clients').length,'Clients'],[P.filter(p=>p.status!=='Completed').length,'Active projects'],[inr(billed),'Total billing'],[inr(rec),'Received'],[inr(billed-rec),'Outstanding'],[inr(rec-pur),'Indicative profit (demo)']])+
    `<div class="grid"><div class="card"><h3>Project stages</h3>${bars(cnt(P,'status'))}</div><div class="card"><h3>Enquiry pipeline</h3>${bars(cnt(E,'status'))}</div><div class="card"><h3>Material status</h3>${bars(cnt(API.list('materials'),'status'))}</div></div>
    <div class="card" style="margin-top:1rem"><h3>Owner profile</h3>Sanket Santosh Dongare · sanket048pro@gmail.com · +91 8766707195 · India</div>`}
  if(d==='SALES')h+=kpi([[E.filter(e=>['New','Under Review'].includes(e.status)).length,'Open enquiries'],[API.list('quotations').filter(q=>q.status==='Sent').length,'Quotations sent'],[P.length,'Orders']])+`<div class="grid"><div class="card"><h3>Enquiry pipeline</h3>${bars(cnt(E,'status'))}</div><div class="card"><h3>Order status</h3>${bars(cnt(P,'status'))}</div></div>`;
  if(d==='ACCOUNTS'){const out=I.reduce((s,i)=>s+i.amount-i.paid,0);h+=kpi([[I.length,'Invoices'],[inr(I.reduce((s,i)=>s+i.paid,0)),'Payments received'],[inr(out),'Pending dues'],[inr(I.reduce((s,i)=>s+i.amount*.18/1.18,0)),'GST (approx.)']])+`<div class="card"><h3>Invoice status</h3>${bars(cnt(I,'status'))}</div>`}
  if(d==='ENG')h+=kpi([[P.length,'Lab setup projects'],[API.list('tickets').filter(t=>t.status!=='Closed').length,'Open service calls'],[P.filter(p=>p.status==='Execution').length,'In installation']])+`<div class="card"><h3>Project progress</h3>${P.map(p=>`<div class="row"><span>${esc(p.name)}</span><div class="bar"><i style="width:${p.pct}%"></i></div><b>${p.pct}%</b></div>`).join('')}</div>`;
  if(d==='PURCHASE')h+=kpi([[S.length,'Stocked items'],[S.filter(s=>s.qty<=s.reorder).length,'Low stock'],[API.list('materials').filter(m=>m.status==='Requested').length,'Pending requests']])+`<div class="card"><h3>Stock levels</h3>${S.map(s=>`<div class="row"><span>${esc(s.item.slice(0,20))}</span><div class="bar"><i style="width:${Math.min(100,s.qty/(s.reorder*2||1)*100)}%"></i></div><b>${s.qty}</b></div>`).join('')}</div><p class="demo">Google Sheets stock: export the sheet to CSV and import it (see README); live sheet access needs a server-side service.</p>`;
  if(d==='CLIENT')h+=kpi([[P.length,'My projects'],[I.length,'My invoices'],[API.list('tickets').filter(t=>t.client_id===U.client_id&&t.status==='Open').length,'Open tickets']])+`<div class="card"><h3>My project status</h3>${P.map(p=>`<div class="row"><span>${esc(p.name)}<br>${badge(p.status)}</span><div class="bar"><i style="width:${p.pct}%"></i></div><b>${p.pct}%</b></div>`).join('')||'No projects yet.'}</div>`;
  $('#view').innerHTML=h;
}
let page=1;
function mod(k,q='',f=''){
  const M=MOD[k]; if(!mods.includes(k))return toast('Access denied');
  if(k==='boq')return boqView(); if(k==='logs')return logView();
  let rows=own(k,API.list(k)); if(M.calc)rows.forEach(M.calc);
  if(q)rows=rows.filter(r=>JSON.stringify(r).toLowerCase().includes(q.toLowerCase()));
  if(f)rows=rows.filter(r=>r.status===f);
  const sts=[...new Set(own(k,API.list(k)).map(r=>r.status).filter(Boolean))], per=8, pages=Math.max(1,Math.ceil(rows.length/per)); page=Math.min(page,pages);
  $('#view').innerHTML=`<h1>${M.t}</h1><div class="bar-tools"><input id="q" placeholder="Search" value="${esc(q)}"><select id="f"><option value="">All statuses</option>${sts.map(s=>`<option ${s===f?'selected':''}>${esc(s)}</option>`).join('')}</select>
   ${canWrite(k)?'<button class="btn" id="add">Add</button>':''}<button class="btn alt" id="exp">Export CSV</button><button class="btn alt" onclick="print()">Print</button></div>
   <div class="tw"><table><thead><tr>${M.cols.map(c=>`<th>${c[1]}</th>`).join('')}<th></th></tr></thead><tbody>${rows.slice((page-1)*per,page*per).map(r=>`<tr>${M.cols.map(c=>`<td>${c[0]==='status'||c[0]==='priority'?badge(r[c[0]]):c[2]==='inr'?inr(r[c[0]]):c[2]==='pct'?`<div class="bar"><i style="width:${r[c[0]]}%"></i></div>`:esc(r[c[0]])}</td>`).join('')}<td>${canWrite(k)?`<button class="btn sm alt" data-e="${r.id}">Edit</button> <button class="btn sm red" data-d="${r.id}">Delete</button>`:''}</td></tr>`).join('')||`<tr><td colspan="9">Nothing here yet. Use Add to create the first record.</td></tr>`}</tbody></table></div>
   <div class="bar-tools">Page ${page} of ${pages} <button class="btn sm alt" id="pv">Prev</button><button class="btn sm alt" id="nx">Next</button></div>`;
  const re=()=>mod(k,$('#q').value,$('#f').value);
  $('#q').oninput=()=>{page=1;re();$('#q').focus()}; $('#f').onchange=()=>{page=1;re()};
  $('#pv').onclick=()=>{page=Math.max(1,page-1);re()}; $('#nx').onclick=()=>{page=Math.min(pages,page+1);re()};
  $('#exp').onclick=()=>csv(k,rows);
  if($('#add'))$('#add').onclick=()=>form(k);
  $('#view').onclick=e=>{const id=+e.target.dataset.e||+e.target.dataset.d; if(!id)return;
    if(e.target.dataset.e)form(k,API.list(k).find(r=>r.id===id));
    else if(confirm('Delete this record? This is written to the audit log.')){API.remove(k,id);toast('Deleted');mod(k)}};
}
function form(k,r){
  const M=MOD[k],m=document.createElement('div');m.className='modal';
  m.innerHTML=`<div><h3>${r?'Edit':'Add'} · ${M.t}</h3><form id="f">${M.form.map(([n,l,t,o])=>`<label>${l}</label>${t==='select'?`<select name="${n}">${o.map(x=>`<option ${r&&r[n]===x?'selected':''}>${x}</option>`).join('')}</select>`:`<input name="${n}" type="${t||'text'}" value="${esc(r?r[n]:'')}" ${t==='number'?'min="0" step="any"':''} required>`}`).join('')}<br><button class="btn">Save</button> <button type="button" class="btn alt" id="x">Cancel</button></form></div>`;
  document.body.append(m);$('#x').onclick=()=>m.remove();
  $('#f').onsubmit=e=>{e.preventDefault();const d=Object.fromEntries(new FormData(e.target));
    M.form.forEach(([n,,t])=>{if(t==='number')d[n]=+d[n]});
    if(U.client_id)d.client_id=U.client_id;
    if(k==='estimation'&&!API.list('master_items').some(i=>i.name===d.item))return toast('Estimation item must match a Master Item name exactly');
    r?API.update(k,r.id,d):API.add(k,{...M.defaults,...d});m.remove();toast('Saved');mod(k)};
}
function csv(k,rows){const M=MOD[k],t=[M.cols.map(c=>c[1]).join(',')].concat(rows.map(r=>M.cols.map(c=>`"${String(r[c[0]]??'').replace(/"/g,'""')}"`).join(',')));
  const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([t.join('\n')],{type:'text/csv'}));a.download=k+'.csv';a.click()}
function gsearch(q){if(!q)return;const out=[];mods.forEach(k=>{if(MOD[k].custom)return;own(k,API.list(k)).forEach(r=>{if(JSON.stringify(r).toLowerCase().includes(q.toLowerCase()))out.push([MOD[k].t,Object.values(r).slice(1,4).join(' · ')])})});
  $('#view').innerHTML=`<h1>Search: ${esc(q)}</h1><div class="tw"><table>${out.map(o=>`<tr><td>${esc(o[0])}</td><td>${esc(o[1])}</td></tr>`).join('')||'<tr><td>No results.</td></tr>'}</table></div>`}
function logView(){$('#view').innerHTML=`<h1>Audit log</h1><div class="tw"><table><tr><th>Time</th><th>User</th><th>Action</th><th>Module</th><th>Record</th></tr>${API.list('logs').map(l=>`<tr><td>${esc(l.t)}</td><td>${esc(l.user)}</td><td>${esc(l.a)}</td><td>${esc(l.m)}</td><td>${esc(l.r)}</td></tr>`).join('')}</table></div>`}
function boqView(){
  const sample='Cat 6 UTP Cable, mtr, 500\nPP Fume Hood, nos, 6\nBroen ball valve 25mm, nos, 40\nPolypropylene centrifugal blower, nos, 4\nInstall and commission, ls, 1\nStainless steel bracket, nos, 20';
  $('#view').innerHTML=`<h1>BOQ matching</h1><p class="demo">Paste BOQ lines as: item, unit, quantity (or export from Excel as CSV).</p><textarea id="bt" rows="6">${sample}</textarea><div class="bar-tools"><button class="btn" id="run">Match against master items</button></div><div id="res"></div>`;
  $('#run').onclick=()=>{const masters=API.list('master_items').filter(m=>m.status==='Active');
    const items=$('#bt').value.split('\n').filter(l=>l.trim()).map(l=>{const [t,u,q]=l.split(',').map(s=>s.trim());return{t,u,q:+q||0,...BOQM.match(t,u,masters),state:'Suggested'}});
    const draw=()=>$('#res').innerHTML=`<div class="tw"><table><tr><th>BOQ item</th><th>Suggested master item</th><th>Match type</th><th>Confidence</th><th>Unit</th><th>Action</th></tr>${items.map((x,i)=>`<tr><td>${esc(x.t)}</td><td>${x.m?esc(x.m.name):'—'}</td><td>${esc(x.type)}</td><td>${x.conf}%</td><td>${esc(x.u||'')}</td><td>${x.state!=='Suggested'?badge(x.state):`${x.m?`<button class="btn sm" data-a="${i}">Accept</button> `:''}<select data-c="${i}"><option value="">Change…</option>${masters.map(m=>`<option value="${m.id}">${esc(m.name)}</option>`).join('')}</select> <button class="btn sm red" data-r="${i}">Reject</button>`}</td></tr>`).join('')}</table></div>`;
    draw();
    const accept=x=>{API.add('estimation',{code:x.m.code,boq:x.t,item:x.m.name,unit:x.m.unit,qty:x.q,rate:x.m.price,amount:x.q*x.m.price});x.state='Accepted'};
    $('#res').onclick=e=>{const d=e.target.dataset;if(d.a!==undefined){accept(items[d.a]);API.update('master_items',items[d.a].m.id,{});toast('Added to estimation with the exact master item name');draw()}if(d.r!==undefined){items[d.r].state='Rejected';draw()}};
    $('#res').onchange=e=>{const i=e.target.dataset.c;if(i===undefined||!e.target.value)return;items[i].m=masters.find(m=>m.id==e.target.value);items[i].type='Manual';items[i].conf=100;accept(items[i]);items[i].state='Accepted';toast('Match changed and accepted');draw()};
  };
}
shell();
