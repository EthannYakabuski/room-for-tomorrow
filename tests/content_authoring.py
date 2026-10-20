"""Portable commission authoring helper. Default is read-only validation.
Use --write explicitly to regenerate the recorded room JSON from authored briefs.
Included directional sprites are already part of the project; no external path
or asset download is needed. Runtime/Godot tests remain the authority for rules.
"""
from pathlib import Path
import argparse, json
ROOT=Path(__file__).resolve().parent
if ROOT.name == 'tests': ROOT=ROOT.parent
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--write',action='store_true',help='Regenerate commission definitions and recorded solutions')
args=parser.parse_args()
furniture={
 'desk':('Writing desk','desk',1,2), 'bed':('Single bed','bedSingle',2,1),
 'sofa':('Two-seat sofa','loungeSofa',1,2), 'chair':('Reading chair','loungeChair',1,1),
 'lamp':('Floor lamp','lampRoundFloor',1,1), 'plant':('Potted fern','pottedPlant',1,1),
 'shelf':('Bookcase','bookcaseOpen',1,1), 'table':('Coffee table','tableCoffee',1,2),
 'stool':('Dining chair','chairCushion',1,1), 'dining':('Dining table','tableRound',2,2),
 'cabinet':('Bedside cabinet','cabinetBed',1,1), 'coat':('Coat stand','coatRackStanding',1,1)}

# Sixty individually specified room briefs; no random-seed content. Each tuple
# authors dimensions, furnishing set, structural columns, daylight and optional wish.
chapters=['First Keys','Sunny Studios','Shared Corners','Old Town','Garden Rooms','Tomorrow’s Homes']
mixes={
 'read':['chair','lamp','plant','shelf'],
 'work':['desk','chair','lamp','plant'],
 'sleep':['bed','cabinet','lamp','plant'],
 'lounge':['sofa','table','lamp','plant','shelf'],
 'studio':['desk','bed','chair','lamp','plant'],
 'book':['desk','chair','lamp','shelf','plant','cabinet'],
 'family':['sofa','bed','lamp','plant','shelf','cabinet'],
 'dine':['dining','stool','lamp','plant','shelf'],
 'guest':['bed','desk','sofa','lamp','plant','cabinet'],
 'full':['desk','bed','sofa','lamp','plant','shelf','cabinet','coat']}
specs=[
 ('The First Page',5,5,'read',[],False,'plant'),('Morning Letter',5,5,'work',[],True,'plant'),('A Soft Landing',5,5,'sleep',[],False,'plant'),('Tea at Four',6,5,'lounge',[],False,'shelf'),('Window Seat',5,6,'read',[(4,0)],False,'plant'),('Night and Day',6,5,'studio',[],True,'plant'),('Books by the Door',5,6,'book',[(4,0)],True,'shelf'),('Sunday Dinner',6,6,'dine',[],False,'plant'),('A Friend Stays',6,6,'guest',[],True,'cabinet'),('Little Home',6,6,'full',[],True,'shelf'),
 ('East Light',6,5,'work',[(5,0)],True,'plant'),('The Green Alcove',5,6,'read',[(0,5)],False,'shelf'),('The Long Morning',7,5,'studio',[(6,0)],True,'plant'),('Sunbeam Supper',6,6,'dine',[(0,5)],False,'plant'),('A Spare Pillow',6,6,'family',[(5,0)],False,'cabinet'),('The Writer’s Nook',5,7,'book',[(4,0),(4,1)],True,'shelf'),('Orange Curtains',7,5,'lounge',[(0,4)],False,'plant'),('Two Windows',6,7,'guest',[(5,0)],True,'cabinet'),('The Quiet Desk',7,6,'book',[(6,0),(0,5)],True,'plant'),('Studio with a View',7,6,'full',[(6,0)],True,'shelf'),
 ('Room for Two',6,6,'family',[(0,5)],False,'plant'),('The Shared Shelf',6,7,'book',[(5,0),(5,1)],True,'shelf'),('Supper Club',7,6,'dine',[(0,5),(1,5)],False,'plant'),('A Welcome Back',7,6,'guest',[(6,0)],True,'cabinet'),('The Common Room',7,7,'lounge',[(0,6),(6,0)],False,'shelf'),('Homework Hour',6,7,'studio',[(5,0)],True,'plant'),('The Lending Library',7,7,'book',[(0,6),(1,6)],True,'shelf'),('One More Chair',7,6,'dine',[(6,0),(6,1)],False,'plant'),('A Place to Rest',6,7,'family',[(0,6),(1,6)],False,'cabinet'),('Keys for Everyone',7,7,'full',[(6,0),(0,6)],True,'shelf'),
 ('Brick and Books',6,6,'book',[(5,0),(0,5)],True,'shelf'),('The Narrow Landing',5,8,'studio',[(4,0),(4,1)],True,'plant'),('Old Town Tea',8,5,'lounge',[(7,0),(0,4)],False,'plant'),('The Corner Flat',7,7,'guest',[(0,6),(6,0),(6,1)],True,'cabinet'),('Between the Beams',6,8,'sleep',[(5,0),(5,1),(0,7)],False,'plant'),('A Well-read Home',8,6,'book',[(7,0),(7,1)],True,'shelf'),('Room for Stories',7,7,'family',[(0,6),(1,6),(6,0)],False,'cabinet'),('The Tucked-away Table',8,6,'dine',[(7,0),(0,5)],False,'plant'),('Above the Square',7,8,'guest',[(6,0),(6,1),(0,7)],True,'plant'),('A New Chapter',8,7,'full',[(7,0),(0,6),(1,6)],True,'shelf'),
 ('Fern House',6,7,'read',[(5,0),(0,6)],False,'plant'),('Rain on the Glass',7,6,'work',[(6,0),(0,5)],True,'plant'),('The Potting Corner',7,7,'lounge',[(6,0),(6,1),(0,6)],False,'plant'),('Green Morning',6,8,'studio',[(5,0),(0,7)],True,'plant'),('The Garden Table',8,6,'dine',[(7,0),(7,1),(0,5)],False,'plant'),('Botanical Notes',7,8,'book',[(6,0),(0,7),(1,7)],True,'shelf'),('A Gentle Evening',8,7,'family',[(7,0),(0,6),(1,6)],False,'cabinet'),('The Glasshouse',8,8,'guest',[(7,0),(7,1),(0,7)],True,'plant'),('Lemon Tree Lane',7,8,'full',[(6,0),(0,7)],True,'shelf'),('Rooted Here',8,8,'full',[(7,0),(0,7),(1,7)],True,'plant'),
 ('The Maker’s Room',6,8,'book',[(5,0),(5,1),(0,7)],True,'shelf'),('A Family Morning',8,6,'family',[(7,0),(0,5),(1,5)],False,'cabinet'),('The Open Table',7,8,'dine',[(6,0),(6,1),(0,7)],False,'plant'),('The Guest’s Window',8,7,'guest',[(7,0),(0,6),(1,6)],True,'plant'),('A Room Reimagined',8,8,'studio',[(7,0),(0,7),(1,7)],True,'plant'),('Quiet Company',7,8,'lounge',[(6,0),(6,1),(0,7)],False,'shelf'),('Across the Threshold',8,7,'full',[(7,0),(7,1),(0,6)],True,'plant'),('The Last Box',8,8,'full',[(7,0),(0,7),(1,7),(7,1)],True,'shelf'),('Always a Welcome',8,8,'guest',[(0,7),(1,7),(7,0)],True,'cabinet'),('Room for Tomorrow',8,8,'full',[(7,0),(7,1),(0,7),(1,7)],True,'plant')]

def dims(key,r):
 w,h=furniture[key][2:];return (h,w) if r%2 else (w,h)
def cells(p):
 w,h=dims(p['key'],p['r']);return {(p['x']+x,p['y']+y) for x in range(w) for y in range(h)}
def fronts(p):
 w,h=dims(p['key'],p['r']);x,y,r=p['x'],p['y'],p['r']
 return [[(x+w,y+i) for i in range(h)],[(x+i,y+h) for i in range(w)],[(x-1,y+i) for i in range(h)],[(x+i,y-1) for i in range(w)]][r]
def valid(room,ps):
 occ=set(room['blocked']);door=tuple(room['door']);clear=tuple(room['clearance'])
 if door in occ or clear in occ:return False
 for p in ps:
  cs=cells(p)
  if cs&occ or door in cs or clear in cs or any(x<0 or y<0 or x>=room['w'] or y>=room['h'] for x,y in cs):return False
  occ|=cs
 seen={door};stack=[door]
 while stack:
  x,y=stack.pop()
  for q in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]:
   if q not in seen and q not in occ and 0<=q[0]<room['w'] and 0<=q[1]<room['h']:seen.add(q);stack.append(q)
 for p in ps:
  if not seen.intersection(fronts(p)):return False
  if room['daylight'] and p['key']=='desk' and not any(y==0 and x in room['windows'] for x,y in cells(p)):return False
 if any(p['key']=='lamp' for p in ps):
  lamp=next(p for p in ps if p['key']=='lamp');seats=[p for p in ps if p['key'] in ['chair','sofa','bed','stool']]
  if seats and not any(min(abs(x-a)+abs(y-b) for x,y in cells(lamp) for a,b in cells(s))<=2 for s in seats):return False
 return True

def solution(room):
 # Hand-shaped arrangement: useful northern desk, furniture around the perimeter,
 # clear central circulation. Deterministic search only resolves footprint choices.
 keys=sorted(room['items'],key=lambda k:0 if k=='plant' and room['optional']=='plant' else (1 if k=='desk' else (3 if k in ['lamp','plant','shelf','cabinet','coat','stool'] else 2)))
 def rec(ps,occ,i):
  if i==len(keys):return ps if valid(room,ps) and optional_ok(room,ps) else None
  key=keys[i]; candidates=[]
  for r in range(4):
   for y in range(room['h']):
    for x in range(room['w']):
     p={'key':key,'x':x,'y':y,'r':r};cs=cells(p)
     if cs&occ or tuple(room['door']) in cs or tuple(room['clearance']) in cs:continue
     if any(a>=room['w'] or b>=room['h'] for a,b in cs):continue
     if room['daylight'] and key=='desk' and not any(b==0 and a in room['windows'] for a,b in cs):continue
     if key==room['optional'] and key=='plant' and (y!=0 or x not in room['windows']):continue
     if key==room['optional'] and key=='shelf' and x!=0 and y!=0:continue
     if key==room['optional'] and key=='cabinet':
      beds=[b for b in ps if b['key']=='bed']
      if beds and min(abs(a-c)+abs(b-d) for a,b in cs for c,d in cells(beds[0]))>2:continue
     if not valid_partial(room,ps+[p]):continue
     score=y*2+x + (0 if r==0 else 4)
     candidates.append((score,p,cs))
  for _,p,cs in sorted(candidates,key=lambda t:t[0]):
   out=rec(ps+[p],occ|cs,i+1)
   if out:return out
  return None
 return rec([],set(room['blocked']),0)
def optional_ok(room,ps):
 p=next(p for p in ps if p['key']==room['optional'])
 if p['key']=='plant':return p['y']==0 and p['x'] in room['windows']
 if p['key']=='shelf':return p['x']==0 or p['y']==0
 if p['key']=='cabinet':
  bed=next(b for b in ps if b['key']=='bed')
  return min(abs(x-a)+abs(y-b) for x,y in cells(p) for a,b in cells(bed))<=2
 return False
def valid_partial(room,ps):
 # Same reachability as final validation, without reading-lamp completion.
 test=dict(room);test['daylight']=False
 lamps=[p for p in ps if p['key']=='lamp']; seats=[p for p in ps if p['key'] in ['chair','sofa','bed','stool']]
 if lamps and seats:
  return valid(test,ps)
 return valid(test,[p for p in ps if p['key']!='lamp'])

# Structural details are authored per commission, introducing small pillars,
# dividing walls and garden courtyards after the introductory chapters.
interiors={
20:[(2,2)],21:[(3,2),(3,3)],22:[(2,3),(3,3)],23:[(3,2),(3,3)],24:[(3,2),(3,3),(3,4)],25:[(2,3),(2,4)],26:[(2,3),(3,3),(4,3)],27:[(3,2),(3,3)],28:[(2,3),(3,3)],29:[(3,2),(3,3),(3,4)],
30:[(2,2),(2,3)],31:[(2,3),(2,4)],32:[(3,2),(4,2)],33:[(3,3),(3,4),(4,4)],34:[(2,3),(2,4),(3,4)],35:[(3,2),(4,2),(4,3)],36:[(2,3),(3,3),(4,3)],37:[(3,3),(4,3),(5,3)],38:[(3,3),(3,4),(3,5)],39:[(3,2),(3,3),(4,3),(4,4)],
40:[(2,3),(3,3)],41:[(3,2),(3,3)],42:[(2,3),(3,3),(3,4)],43:[(2,3),(3,3),(3,4),(3,5)],44:[(3,2),(4,2),(4,3)],45:[(3,3),(3,4),(4,3),(4,4)],46:[(3,3),(3,4),(4,3),(4,4)],47:[(3,3),(4,3),(3,4),(4,4)],48:[(2,3),(3,3),(3,4),(3,5)],49:[(3,3),(4,3),(3,4),(4,4),(5,4)],
50:[(2,3),(2,4),(3,4)],51:[(3,2),(4,2),(4,3)],52:[(3,3),(3,4),(3,5),(4,5)],53:[(3,3),(3,4),(4,3),(5,3)],54:[(3,3),(4,3),(4,4),(4,5)],55:[(2,3),(3,3),(3,4),(3,5)],56:[(3,2),(3,3),(4,3),(5,3),(5,4)],57:[(3,3),(4,3),(3,4),(4,4),(4,5)],58:[(3,3),(3,4),(4,4),(5,4),(5,5)],59:[(2,3),(3,3),(4,3),(4,4),(4,5),(5,5)]}
if not args.write:
 existing=json.loads((ROOT/'game/commissions.json').read_text(encoding='utf8'))
 assert len(existing['rooms'])==60
 for room in existing['rooms']:
  room['blocked']=[tuple(value) for value in room['blocked']]
  assert valid(room,room['solution']),room['name']
  assert optional_ok(room,room['solution']),room['name']
 print('Read-only verification: all60 recorded mandatory and optional arrangements pass.')
 raise SystemExit(0)
rooms=[]
for i,(name,w,h,mix,blocked,daylight,optional) in enumerate(specs):
 blocked=blocked+interiors.get(i,[])
 door_x=1 if i>=10 and i%3==0 else w-2
 if (door_x,h-1) in blocked or (door_x,h-2) in blocked:
  door_x=next(x for x in [w-2,2,w-3,1,0,w-1] if (x,h-1) not in blocked and (x,h-2) not in blocked)
 windows=list(range(w-1)) if i<10 else [min(w-2,i%3),min(w-2,i%3+1)]
 room={'id':i,'name':name,'chapter':i//10,'w':w,'h':h,'items':mixes[mix], 'blocked':blocked,'door':[door_x,h-1],'clearance':[door_x,h-2], 'windows':windows,'daylight':daylight,'optional':optional,'brief':('A desk in daylight, a light for reading, and room to move.' if daylight else 'A restful corner, a useful lamp, and a clear welcome.')}
 sol=solution(room)
 assert sol, name
 assert valid(room,sol),name
 room['solution']=sol
 rooms.append(room)
 print(f'{i+1:02} {name}: verified')
(ROOT/'game/commissions.json').write_text(json.dumps({'chapters':chapters,'rooms':rooms},ensure_ascii=False,indent=2),encoding='utf8')
print('60 authored commissions, all recorded layouts verified.')
