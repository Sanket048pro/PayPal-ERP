/* PayPal ERP data layer.
   LIMITATION: a browser cannot (and must not) open a MySQL connection, and HTML/CSS/JS alone cannot talk to port 3306.
   Until a server-side bridge is provided, this file runs in DEMO MODE on localStorage using the same entity names
   as database/schema.sql. A bridge only needs to implement the methods below over HTTPS. No credentials live here. */
const API=(()=>{
  const K='paypal_erp_demo_v1', today=(d=0)=>new Date(Date.now()+d*864e5).toISOString().slice(0,10);
  const seed={
    users:[
      {id:1,email:'sanket048pro@gmail.com',pw:'ChangeMe#2026',name:'Sanket Santosh Dongare',mobile:'+91 8766707195',role:'Owner / Director',dept:'ADMIN'},
      {id:2,email:'sales@demo.erp',pw:'Demo@123',name:'Priya Nair',role:'Sales Manager',dept:'SALES'},
      {id:3,email:'accounts@demo.erp',pw:'Demo@123',name:'Vikas Rane',role:'Accounts Manager',dept:'ACCOUNTS'},
      {id:4,email:'eng@demo.erp',pw:'Demo@123',name:'Arjun Patil',role:'Project Manager',dept:'ENG'},
      {id:5,email:'store@demo.erp',pw:'Demo@123',name:'Sunil Pawar',role:'Store Keeper',dept:'PURCHASE'},
      {id:6,email:'dow@demo.erp',pw:'Demo@123',name:'Rahul Mehta (Dow)',role:'Client Company',dept:'CLIENT',client_id:1}],
    clients:[{id:1,name:'Dow Chemical International',contact:'Rahul Mehta',city:'Mumbai',gst:'27AAAAA0000A1Z5',status:'Active'},{id:2,name:'Asian Paints Ltd',contact:'Neha Kulkarni',city:'Mumbai',gst:'27BBBBB0000B1Z5',status:'Active'},{id:3,name:'Sunrise Pharma Labs',contact:'Amit Shah',city:'Pune',gst:'27CCCCC0000C1Z5',status:'Active'}],
    enquiries:[{id:1,client_id:1,client:'Dow Chemical International',requirement:'R&D lab, 6 fume hoods',priority:'High',status:'Converted to Project',date:today(-20)},{id:2,client_id:2,client:'Asian Paints Ltd',requirement:'Exhaust blowers QC lab',priority:'Medium',status:'Quotation',date:today(-9)},{id:3,client_id:3,client:'Sunrise Pharma Labs',requirement:'Broen valve fittings',priority:'Low',status:'New',date:today(-2)}],
    quotations:[{id:1,client:'Asian Paints Ltd',date:today(-6),total:780000,status:'Sent'},{id:2,client:'Dow Chemical International',date:today(-18),total:2450000,status:'Approved'}],
    projects:[{id:1,client_id:1,name:'Dow R&D Laboratory Setup',client:'Dow Chemical International',value:2450000,status:'Execution',pct:45,priority:'High',end:today(75)},{id:2,client_id:2,name:'Asian Paints QC Exhaust Upgrade',client:'Asian Paints Ltd',value:780000,status:'Estimation',pct:20,priority:'Medium',end:today(40)}],
    estimation:[],
    materials:[{id:1,project:'PRJ-001',item:'FUME HOOD 1500MM POLYPROPYLENE',qty:6,status:'Purchase',priority:'High'},{id:2,project:'PRJ-002',item:'PP CENTRIFUGAL BLOWER 2HP',qty:4,status:'Requested',priority:'Medium'}],
    inventory:[{id:1,item:'FUME HOOD 1500MM POLYPROPYLENE',qty:3,reorder:2},{id:2,item:'PP CENTRIFUGAL BLOWER 2HP',qty:1,reorder:2},{id:3,item:'BROEN BALLOREX VALVE 25MM',qty:120,reorder:50}],
    invoices:[{id:1,client_id:1,client:'Dow Chemical International',no:'INV-001',amount:867300,paid:400000,due:today(20),status:'Part Paid'},{id:2,client_id:2,client:'Asian Paints Ltd',no:'INV-002',amount:184080,paid:0,due:today(-10),status:'Overdue'}],
    tickets:[{id:1,client_id:1,subject:'Blower noise on hood 3',status:'Open',project:'PRJ-001'}],
    master_items:[['FH-1500','FUME HOOD 1500MM POLYPROPYLENE','NOS',185000,'fh,fume cupboard,pp fume hood'],['BL-PP-02','PP CENTRIFUGAL BLOWER 2HP','NOS',42000,'polypropylene centrifugal blower,pp blower'],['BR-BV-25','BROEN BALLOREX VALVE 25MM','NOS',6800,'broen ball valve,ballorex'],['CB-C6-UTP','CAT6 UTP LAN CABLE','MTR',38,'cat 6 utp cable,cat-6 unshielded twisted pair'],['SV-INST','INSTALLATION & COMMISSIONING','LS',95000,'install and commission,i&c']].map((m,i)=>({id:i+1,code:m[0],name:m[1],unit:m[2],price:m[3],aliases:m[4],status:'Active'})),
    employees:[{id:1,name:'Priya Nair',dept:'Sales & Marketing',designation:'Sales Manager',status:'Active'},{id:2,name:'Arjun Patil',dept:'Engineering',designation:'Project Manager',status:'Active'}],
    logs:[],demo:true};
  let db=JSON.parse(localStorage.getItem(K)||'null')||seed; const save=()=>localStorage.setItem(K,JSON.stringify(db));
  const log=(a,m,r)=>{db.logs.unshift({t:new Date().toLocaleString(),user:(API.session()||{}).name,a,m,r});db.logs=db.logs.slice(0,200);save()};
  return{
    login(e,p){const u=db.users.find(x=>x.email===e.trim().toLowerCase()&&x.pw===p);if(!u)return null;sessionStorage.setItem('erp_user',JSON.stringify(u));log('Login','auth',u.id);return u},
    session(){return JSON.parse(sessionStorage.getItem('erp_user')||'null')},
    logout(){log('Logout','auth','');sessionStorage.removeItem('erp_user')},
    list(t){return db[t]||[]},
    add(t,r){r.id=Math.max(0,...db[t].map(x=>x.id))+1;db[t].push(r);log('Create',t,r.id);save();return r},
    update(t,id,p){const r=db[t].find(x=>x.id===id);Object.assign(r,p);log('Update',t,id);save()},
    remove(t,id){db[t]=db[t].filter(x=>x.id!==id);log('Delete',t,id);save()},
    reset(){localStorage.removeItem(K);location.reload()}};
})();
