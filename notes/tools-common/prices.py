# Usage: python3 prices.py [HANDLE]   (needs data.pequalnp.com; takes no lease)
# Prints what merged proofs were actually paid: tiers, families by total points, the paid
# families' medians and maxima, big proofs per six hours, the top of the board, and HANDLE's row.
import json,re,sys,collections,statistics as st,urllib.request
B='https://data.pequalnp.com/'
def get(rel):
    q=urllib.request.Request(B+rel,headers={'User-Agent':'curl/8'})
    with urllib.request.urlopen(q,timeout=90) as r: return json.load(r)
h=get('head.json'); c=get(h['files']['contributors'])['contributors']
print('status:',h['status']['text'][:160]); k=h['counters']
print('points total',k.get('points'),'last hour',k.get('points_last_hour'),'last 24h',k.get('points_last_24h'))
L=[(l['points'],l['at'],l['id'],x['github'],l['title']) for x in c for l in x['lemmas'] if not l.get('points_estimated')]
tot=sum(p[0] for p in L); print('paid proofs',len(L),'points',tot)
for lo,hi in ((0,29),(30,50),(51,199),(200,499),(500,999),(1000,10**6)):
    v=[p[0] for p in L if lo<=p[0]<=hi]; print('  %d to %d: %d proofs, %.0f%% of points'%(lo,hi,len(v),100*sum(v)/max(1,tot)))
def fam(t):
    t=re.sub(r'edges [0-9\- ]+','E ',t); t=re.sub(r'\(mask \d+\)','',t); return re.sub(r'\d+','#',t)[:95]
F=collections.defaultdict(list)
for p in L: F[fam(p[4])].append(p[0])
print('n sum median max | family')
for f,v in sorted(F.items(),key=lambda kv:-sum(kv[1]))[:40]: print(len(v),sum(v),int(st.median(v)),max(v),'|',f)
D=collections.defaultdict(list)
for p in L: D[p[1][:10]+' '+str(int(p[1][11:13])//6*6).zfill(2)].append(p[0])
print('six hours from | proofs | points | 500 or more | 100 to 499')
for d in sorted(D): print(d,len(D[d]),sum(D[d]),sum(v>=500 for v in D[d]),sum(100<=v<500 for v in D[d]))
W=collections.Counter()
for x in c:
    for w in x.get('work',[]): W[w['kind']]+=w['points']
print('points paid for cuts and other work:',dict(W))
top=sorted(c,key=lambda x:-x.get('points',0))
for i,x in enumerate(top[:10]): print(i+1,x['github'],x['steps'],x.get('points'))
me=(sys.argv[1] if len(sys.argv)>1 else '').lower()
for i,x in enumerate(top):
    if x['github'].lower()==me:
        print('rank',i+1,x['github'],x['steps'],x.get('points'))
        for l in x['lemmas']: print('  ',l['points'],l['id'],l['title'][:90])
