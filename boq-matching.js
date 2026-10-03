/* BOQ -> Master Item matching (exact, item code, abbreviation, full form, approximate, unit-aware). */
const BOQM=(()=>{
  const ABBR={utp:'unshielded twisted pair',pp:'polypropylene',pvc:'polyvinyl chloride',lan:'local area network',mcb:'miniature circuit breaker',fh:'fume hood',i:'install',c:'commission',hp:'horsepower'};
  const norm=s=>s.toLowerCase().replace(/cat[\s-]*(\d)/g,'cat$1').replace(/[^a-z0-9 ]+/g,' ').replace(/\s+/g,' ').trim();
  const expand=s=>norm(s).split(' ').map(w=>ABBR[w]||w).join(' ');
  const tok=s=>new Set(expand(s).split(' ').filter(w=>w.length>1&&!['and','the','of','with'].includes(w)));
  const jac=(a,b)=>{const i=[...a].filter(x=>b.has(x)).length,u=new Set([...a,...b]).size;return u?i/u:0};
  function match(text,unit,masters){
    let best={m:null,type:'None',conf:0},n=norm(text);
    masters.forEach(m=>{
      let type='Approximate',c=0;
      if(norm(m.name)===n)[type,c]=['Exact',100];
      else if(n.includes(norm(m.code)))[type,c]=['Item code',98];
      else{
        const al=(m.aliases||'').split(',').map(norm).filter(Boolean);
        if(al.includes(n))[type,c]=['Abbreviation',92];
        else if(expand(m.name)===expand(text))[type,c]=['Full form',90];
        else c=Math.round(Math.max(jac(tok(text),tok(m.name)),...al.map(a=>jac(tok(text),tok(a))))*85);
      }
      if(unit&&m.unit&&unit.toUpperCase()!==m.unit)c=Math.max(0,c-10);   // unit-aware penalty
      if(c>best.conf)best={m,type,conf:c};
    });
    if(best.conf<35)best={m:null,type:'None',conf:best.conf};
    return best;
  }
  return{match};
})();
