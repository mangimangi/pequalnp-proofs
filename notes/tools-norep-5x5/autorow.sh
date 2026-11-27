#!/bin/sh
# The desk loop. Needs PNP_SCRATCH (the notes branch unpacked there, so that the generators are
# $S/tools-norep-5x5, $S/tools-lb9, $S/tools-rect, $S/tools-onenot, $S/tools-mono6; state in
# $S/desk), PNP_RIVALS (path of the skill's rivals.sh if not in the default place),
# PNP_HANDLE, optionally PNP_REPO (fork clone on upstream main, with remote upstream fetched).
# A row "¬ RepSizeAtMost (5x5 mask) 10" or a 9-vertex lower bound the generator reaches: keep,
# beat, generate, build, exit with READY. A six-input monotone row: also commit and push,
# exit with PUSHED. Every kept row is checked for rivals first. Other new step: NEW. Steps in
# $S/desk/seen.txt: release with other. Kinds in the skip rule: release with missing_lemma.
S=${PNP_SCRATCH:?set PNP_SCRATCH to the session scratchpad}; H=${PNP_HANDLE:?set PNP_HANDLE}; R=${PNP_REPO:-/home/user/pequalnp-proofs}
export PATH=$HOME/.elan/bin:$PATH
mkdir -p $S/desk; cd $S/desk; touch seen.txt; n=0
while [ $n -lt 80 ]; do n=$((n+1))
 curl -sS "https://pequalnp.com/desk/next?handle=$H&another=1" -o auto.json
 r=$(python3 - <<'PY'
import json,re
try:
    d=json.load(open('auto.json')); g=d.get('gap')
except Exception: g=None
if not g: print('none')
else:
    l=d.get('lease'); tm=(l.get('terms') or {}) if isinstance(l,dict) else {}; l=l.get('id') if isinstance(l,dict) else l
    open('prices.log','a').write('%s %s %s %s %s\n'%(g['id'],tm.get('level'),tm.get('kind'),tm.get('points'),(g.get('title') or '')[:90]))
    st=g['statement'].strip()
    m=re.fullmatch(r'¬ \(?PEqualNP\.Represents\.RepSizeAtMost \(fun u v : Fin 5 => \((\d+) : ℕ\)\.testBit \(5 \* u\.val \+ v\.val\)\) 10\)?',st)
    seen=open('seen.txt').read().split()
    t=g.get('title') or ''
    lb=re.fullmatch(r'∀ t : ℕ, PEqualNP\.MetaComplexity\.HasCircuitSize \d+ \(fun x : Fin \d+ → Bool => .*\) t → \d+ ≤ t',st)
    if lb: open('stmt_'+g['id']+'.txt','w').write(st)
    mp=re.fullmatch(r'PEqualNP\.Represents\.RepSizeAtMost \(fun u v : Fin 5 => \((\d+) : ℕ\)\.testBit \(5 \* u\.val \+ v\.val\)\) 10',st)
    if 'List (Finset (Fin' in st and 'testBit' in st: open('stmt_'+g['id']+'.txt','w').write(st); print('rect',l,g['id']); raise SystemExit
    if st.startswith('∀ (gates : List PEqualNP.CircuitLowerBounds.Gate) (o : ℕ)') and 'GateOp.not' in st: open('stmt_'+g['id']+'.txt','w').write(st); print('onenot',l,g['id']); raise SystemExit
    if st.startswith('∀ s : ℕ, PEqualNP.MetaComplexity.HasCircuitSize') and 'Monotone2' in st: open('stmt_'+g['id']+'.txt','w').write(st); print('monohold',l,g['id']); raise SystemExit
    if m: print('rep',l,g['id'],m.group(1))
    elif mp: print('reppos',l,g['id'],mp.group(1))
    elif lb: print('lb',l,g['id'])
    elif 'one NOT gate saves nothing' in t or 'Cycle family' in t or t.startswith('False: ') or t.startswith('No run of clause learning') or t.startswith('No cutting planes') or (g.get('weight') or 0) >= 90 or ('computes the edge function of the listed graph' in t and not t.startswith('No ')) or t.startswith('No AND/OR') or (t.startswith('A step toward') and g.get('reductions')): print('skip',l,g['id'])
    elif g['id'] in seen: print('seen',l,g['id'])
    else: print('new',l,g['id'])
PY
)
 set -- $r
 case "$1" in rep|lb|rect|onenot|new)
   rv=$(cd $R && sh ${PNP_RIVALS:-/home/user/pequalsnp/.claude/skills/pequalsnp/rivals.sh} $3 2>/dev/null | grep -E "^PR #|^MERGED|^#[0-9]")
   if [ -n "$rv" ]; then curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=other" >/dev/null; echo "$(date -u +%H:%M) rival ahead on $3, released: $(echo "$rv" | head -1 | cut -c1-70)" >> $S/desk/auto.log; echo " $3" >> $S/desk/seen.txt; sleep 75; continue; fi;;
 esac
 case "$1" in
  rep) id=$3; mask=$4; name=$(echo $id | tr - _); cp auto.json row_$id.json
     nohup sh -c "while true; do c=\$(curl -s -o /dev/null -w '%{http_code}' -X POST 'https://pequalnp.com/desk/beat?lease=$2'); echo \"\$(date -u +%H:%M) \$c\" >> beat_$2.log; [ \"\$c\" = 410 ] && exit; sleep 450; done" >/dev/null 2>&1 &
     cd $R
     git fetch -q --depth 1 upstream main
     if git cat-file -e upstream/main:lean/PEqualNP/Outside/$name.lean 2>/dev/null; then echo "ALREADY MERGED $id"; curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=other" >/dev/null; cd $S/desk; sleep 75; continue; fi
     if python3 $S/tools-norep-5x5/gen.py $mask $name > $S/tools-norep-5x5/$name.lean 2> $S/tools-norep-5x5/$name.err; then
        cp $S/tools-norep-5x5/$name.lean lean/PEqualNP/Outside/$name.lean
        (cd lean && lake build PEqualNP.Outside.$name 2>&1 | tail -2)
        echo "READY $id lease $2 mask $mask"; date -u; exit 0
     else echo "GENFAIL $id lease $2 mask $mask: $(head -c 200 $S/tools-norep-5x5/$name.err)"; date -u; exit 0; fi;;
  skip) curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=missing_lemma" >/dev/null; echo "$(date -u +%H:%M) skipped $3" >> auto.log;;
  lb) id=$3; name=$(echo $id | tr - _); cp auto.json row_$id.json
     cd $R
     git fetch -q --depth 1 upstream main
     if git cat-file -e upstream/main:lean/PEqualNP/Outside/$name.lean 2>/dev/null; then curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=other" >/dev/null; echo "$(date -u +%H:%M) merged already $id" >> $S/desk/auto.log; cd $S/desk; sleep 75; continue; fi
     if (cd $S/tools-lb9 && python3 gen9.py $S/desk/stmt_$id.txt $name > $S/tools-lb9/$name.lean 2> $S/tools-lb9/$name.err) && head -1 $S/tools-lb9/$name.lean | grep -q "^import"; then
        nohup sh -c "while true; do c=\$(curl -s -o /dev/null -w '%{http_code}' -X POST 'https://pequalnp.com/desk/beat?lease=$2'); echo \"\$(date -u +%H:%M) \$c\" >> $S/desk/beat_$2.log; [ \"\$c\" = 410 ] && exit; sleep 450; done" >/dev/null 2>&1 &
        cp $S/tools-lb9/$name.lean lean/PEqualNP/Outside/$name.lean
        (cd lean && lake build PEqualNP.Outside.$name 2>&1 | tail -2)
        echo "READY $id lease $2 (9-vertex generator)"; date -u; exit 0
     else curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=missing_lemma" >/dev/null; echo "$(date -u +%H:%M) lb not reached $id: $(head -c 90 $S/tools-lb9/$name.err)" >> $S/desk/auto.log; cd $S/desk; fi;;
  reppos) if (cd $S/tools-norep-5x5 && python3 gen.py $4 X >/dev/null 2>&1); then curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=statement_seems_false" >/dev/null; echo "$(date -u +%H:%M) $3 false: no 10-gate circuit for mask $4" >> auto.log; else cp auto.json new_$3.json; echo "NEW (positive 5x5 row, generator does not refute) $3 lease $2 mask $4"; date -u; exit 0; fi;;
  rect) id=$3; name=$(echo $id | tr - _); cp auto.json row_$id.json
     nohup sh -c "while true; do c=\$(curl -s -o /dev/null -w '%{http_code}' -X POST 'https://pequalnp.com/desk/beat?lease=$2'); echo \"\$(date -u +%H:%M) \$c\" >> $S/desk/beat_$2.log; [ \"\$c\" = 410 ] && exit; sleep 450; done" >/dev/null 2>&1 &
     bp=$!
     (cd $S/tools-rect && python3 gen_rect.py $S/desk/stmt_$id.txt $name --timeout 300 > $S/tools-rect/$name.lean 2> $S/tools-rect/$name.err); rc=$?
     if [ $rc = 0 ] && head -1 $S/tools-rect/$name.lean | grep -q "^import"; then
        cp $S/tools-rect/$name.lean $R/lean/PEqualNP/Outside/$name.lean
        (cd $R/lean && lake build PEqualNP.Outside.$name 2>&1 | tail -2)
        echo "READY $id lease $2 (rectangle generator)"; date -u; exit 0
     else kill $bp 2>/dev/null; r=missing_lemma; [ $rc = 3 ] && r=statement_seems_false
        curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=$r" >/dev/null; echo "$(date -u +%H:%M) rect $id exit $rc released $r: $(head -c 80 $S/tools-rect/$name.err)" >> $S/desk/auto.log; fi;;
  onenot) id=$3; name=$(echo $id | tr - _); cp auto.json row_$id.json
     nohup sh -c "while true; do c=\$(curl -s -o /dev/null -w '%{http_code}' -X POST 'https://pequalnp.com/desk/beat?lease=$2'); echo \"\$(date -u +%H:%M) \$c\" >> $S/desk/beat_$2.log; [ \"\$c\" = 410 ] && exit; sleep 450; done" >/dev/null 2>&1 &
     bp=$!
     (cd $S/tools-onenot && timeout 900 python3 gen_onenot.py $S/desk/stmt_$id.txt $name --sat-seconds 40 > $S/tools-onenot/$name.lean 2> $S/tools-onenot/$name.err); rc=$?
     if [ $rc = 0 ] && head -1 $S/tools-onenot/$name.lean | grep -q "^import"; then
        cp $S/tools-onenot/$name.lean $R/lean/PEqualNP/Outside/$name.lean
        (cd $R/lean && lake build PEqualNP.Outside.$name 2>&1 | tail -2)
        echo "READY $id lease $2 (one-NOT generator)"; date -u; exit 0
     else kill $bp 2>/dev/null; curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=missing_lemma" >/dev/null; echo "$(date -u +%H:%M) onenot $id exit $rc released: $(tail -c 90 $S/tools-onenot/$name.err | tr '\n' ' ')" >> $S/desk/auto.log; fi;;
  monohold) id=$3; name=$(echo $id | tr - _); cp auto.json row_$id.json
     nohup sh -c "while true; do c=\$(curl -s -o /dev/null -w '%{http_code}' -X POST 'https://pequalnp.com/desk/beat?lease=$2'); echo \"\$(date -u +%H:%M) \$c\" >> $S/desk/beat_$2.log; [ \"\$c\" = 410 ] && exit; sleep 450; done" >/dev/null 2>&1 &
     bp=$!; mkdir -p $S/tools-mono6/out
     (cd $S/tools-mono6 && timeout 700 python3 gen_mono.py $S/desk/stmt_$id.txt $name $S/tools-mono6/out > $S/tools-mono6/out/$name.log 2>&1); rc=$?
     if [ $rc = 0 ] && [ -s $S/tools-mono6/out/$name.lean ]; then
        cd $R
        rv=$(sh ${PNP_RIVALS:-/home/user/pequalsnp/.claude/skills/pequalsnp/rivals.sh} $id 2>/dev/null | grep -E "^PR #|^MERGED|^#[0-9]")
        if [ -n "$rv" ]; then kill $bp 2>/dev/null; curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=other" >/dev/null; echo "$(date -u +%H:%M) six-input $id built but rival ahead: $(echo "$rv" | head -1 | cut -c1-60)" >> $S/desk/auto.log; cd $S/desk; sleep 30; continue; fi
        git fetch -q --depth 1 upstream main; git checkout -q -B $id upstream/main && cp $S/tools-mono6/out/$name.lean lean/PEqualNP/Outside/$name.lean && git add lean/PEqualNP/Outside/$name.lean && git commit -q -m "$id" && git push -q -u origin $id; pr=$?
        git checkout -q --detach upstream/main
        echo "PUSHED $id lease $2 push-exit $pr (six-input generator; link must go to the owner now, then release as submitted)"; date -u; exit 0
     else kill $bp 2>/dev/null; r=missing_lemma; [ $rc = 3 ] && r=statement_seems_false
        curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=$r" >/dev/null; echo "$(date -u +%H:%M) six-input $id exit $rc released $r: $(tail -c 100 $S/tools-mono6/out/$name.log | tr '\n' ' ')" >> $S/desk/auto.log; fi;;
  seen) curl -s -X POST "https://pequalnp.com/desk/release?lease=$2&reason=other" >/dev/null; echo "$(date -u +%H:%M) re-offered $3" >> auto.log;;
  new) cp auto.json new_$3.json; echo "NEW $3 lease $2"; date -u; python3 -c "
import json; g=json.load(open('auto.json'))['gap']; print(g['id'],'w',g.get('weight'),'red',g.get('reductions'),'terms',(json.load(open('auto.json')).get('lease') or {}).get('terms')); print(g.get('title')); print(g['statement'][:500])"; exit 0;;
 esac
 sleep 75
done; echo "no new step"
