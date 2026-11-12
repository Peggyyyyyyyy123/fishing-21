import numpy as np
import random
from collections import defaultdict

from pathlib import Path
import re

RESOURCE = Path(__file__).resolve().parents[1] / "config/default_game_config.tres"
text = RESOURCE.read_text(encoding="utf-8")
sections = re.findall(r'\[sub_resource[^\n]+\]\n(.*?)(?=\n\[|\Z)', text, re.S)
def number(section, key):
    return float(re.search(r"^"+re.escape(key)+r" = ([0-9.]+)$", section, re.M).group(1))
P=[number(s,"probability") for s in sections]
LO=[int(number(s,"min_weight_kg")) for s in sections]
HI=[int(number(s,"max_weight_kg")) for s in sections]
PRICE=[int(number(s,"price_per_kg")) for s in sections]
BONUS=[int(number(s,"discovery_reward")) for s in sections]
QUOTAS=[int(x) for x in re.search(r"daily_quotas = Array\[int\]\(\[([^]]+)\]\)",text).group(1).split(",")]
assert abs(sum(P)-1)<1e-9 and len(P)==10
assert "net_slots = 5" in text and "bait_per_day = 6" in text and "weight_cap_kg = 21" in text and "perfect_multiplier = 2" in text
assert max(HI)*max(PRICE)<=420, "Expand the DP value axis before changing prices/weights"
atoms=defaultdict(float)
for p,lo,hi,price in zip(P,LO,HI,PRICE):
    for x in range(lo,hi+1): atoms[x,x*price]+=p/(hi-lo+1)

def solve(quota):
    # State: bait left, occupied slots, weight, accumulated sale value.
    # Bonus omitted: this is a fully discovered catalogue baseline.
    a=np.zeros((7,6,22,421),dtype=np.float64)
    v=np.arange(421)
    terminal=np.array([v*(2 if w==21 else 1)>=quota for w in range(22)])
    a[0,:,:,:]=terminal
    a[:,5,:,:]=terminal
    for b in range(1,7):
        for n in range(4,-1,-1):
            for w in range(22):
                skip=a[b-1,n,w]
                expected=np.zeros(421)
                for (x,value),p in atoms.items():
                    if w+x>21:
                        expected+=p*skip
                    else:
                        keep=a[b-1,n+1,w+x,np.minimum(v+value,420)]
                        expected+=p*np.maximum(skip,keep)
                a[b,n,w]=np.maximum(terminal[w],expected)
    return a

if __name__=='__main__':
    quotas=QUOTAS
    tables={q:solve(q) for q in range(5,5*((max(quotas)+4)//5)+1,5)}
    print('tables ready',flush=True)
    rng=random.Random(2112)
    N=30000
    reached=np.zeros(7,dtype=int); passed=np.zeros(7,dtype=int)
    bonus_sum=np.zeros(7); alive=N
    for run in range(N):
        seen=set()
        for d,q in enumerate(quotas):
            reached[d]+=1
            w=v=n=bonus=0
            for cast in range(6):
                i=rng.choices(range(10),P)[0]
                x=rng.randint(LO[i],HI[i]); value=x*PRICE[i]
                if i not in seen:
                    seen.add(i); bonus+=BONUS[i]
                effective=max(5,5*((q-bonus+4)//5))
                a=tables[effective]; b=5-cast
                if w+x<=21 and a[b,n+1,w+x,min(v+value,420)]>=a[b,n,w,v]:
                    w+=x; v+=value; n+=1
                revenue=v*(2 if w==21 else 1)+bonus
                if revenue>=q or n==5: break
            bonus_sum[d]+=bonus
            if revenue<q: break
            passed[d]+=1
    print('quotas',quotas)
    print('reached',reached.tolist(),'passed',passed.tolist())
    print('conditional_pass_percent',(100*passed/reached).round(2).tolist())
    print('cumulative_pass_percent',(100*passed/N).round(2).tolist())
    print('average_discovery_for_reached',(bonus_sum/reached).round(2).tolist())
    print('complete_catalog_optimal_percent',[round(tables[q][6,0,0,0]*100,2) for q in quotas])
