"""Original synthesized arrangement of the traditional Korobeiniki melody. No sampled recordings."""
from pathlib import Path
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
SR=32000;BEAT=60/148; rng=np.random.default_rng(721)
# Traditional melody, newly harmonized and transposed from A minor into D minor.
phrase=[(76,1),(71,.5),(72,.5),(74,1),(72,.5),(71,.5),(69,1),(69,.5),(72,.5),(76,1),(74,.5),(72,.5),(71,1.5),(72,.5),(74,1),(76,1),(72,1),(69,1),(69,2),
(74,1.5),(77,.5),(81,1),(79,.5),(77,.5),(76,1.5),(72,.5),(76,1),(74,.5),(72,.5),(71,1),(71,.5),(72,.5),(74,1),(76,1),(72,1),(69,1),(69,2)]
beats=sum(d for _,d in phrase);TOTAL=(8+beats*4+8)*BEAT;out=np.zeros((int((TOTAL+4)*SR),2))
def add(w,start,gain=.1,pan=0):
    i=int(start*SR);n=min(len(w),len(out)-i)
    if n>0: out[i:i+n,0]+=w[:n]*gain*np.sqrt((1-pan)/2);out[i:i+n,1]+=w[:n]*gain*np.sqrt((1+pan)/2)
def voice(note,dur,kind='horn'):
    t=np.arange(int((dur+.45)*SR))/SR;f=440*2**((note-69)/12)
    env=np.minimum(1,t/(.025 if kind=='horn' else (.008 if kind=='strings' else .3)))*np.minimum(1,np.maximum(0,(dur+.45-t)/.5))
    v=np.zeros_like(t)
    for k in range(1,10):
        weight=(1/k**1.55) if kind=='horn' else (np.exp(-((k*f-700)/900)**2)/k**1.5)
        v+=weight*np.sin(2*np.pi*k*f*t+.035*k*np.sin(2*np.pi*4.3*t))
    if kind=='strings': env*=np.exp(-t/max(.035,dur*.6))
    return v*env*(.96+.04*np.sin(2*np.pi*4.3*t))
def drum(start,large=True):
    t=np.arange(int(1.8*SR))/SR
    w=np.sin(2*np.pi*(43*t+35*.045*(1-np.exp(-t/.045))))*np.exp(-t/ .46)
    noise=rng.normal(0,1,len(t));noise=np.convolve(noise,np.ones(13)/13,'same')
    w+=noise*np.exp(-t/.07)*.6;add(w,start,.19 if large else .07,-.18)
chords=[(38,45,53),(45,52,56),(38,45,53),(43,50,58),(46,53,62),(45,52,56),(38,45,53),(45,52,56)]
for bar in range(int((TOTAL/BEAT)//4)):
    chord=chords[max(0,bar-2)%len(chords)]
    for j,n in enumerate(chord):add(voice(n,4*BEAT,'choir'),bar*4*BEAT,.07,[-.6,.45,.1][j])
    for beat in range(4):
        start=(bar*4+beat)*BEAT;drum(start,beat%2==0)
        if beat%2:
            t=np.arange(int(.22*SR))/SR
            noise=rng.normal(0,1,len(t));noise-=np.convolve(noise,np.ones(9)/9,'same')
            add(noise*np.exp(-t/.045)+.3*np.sin(2*np.pi*175*t)*np.exp(-t/.07),start,.055,.1)
    for eighth in range(8):
        start=(bar*4+eighth*.5)*BEAT
        add(voice(chord[eighth%3]+24,.19*BEAT,'strings'),start,.072,-.7 if eighth%2 else .7)
        t=np.arange(int(.09*SR))/SR;noise=rng.normal(0,1,len(t));noise-=np.convolve(noise,np.ones(5)/5,'same')
        add(noise*np.exp(-t/.014),start,.018,.45)
    if bar%4==0:
        t=np.arange(int(1.6*SR))/SR;noise=rng.normal(0,1,len(t))
        add(noise*np.exp(-t/.35),bar*4*BEAT,.025,.5)
for repeat in range(4):
    pos=(8+repeat*beats)*BEAT
    for note,d in phrase:
        add(voice(note-7,d*BEAT*.88),pos,.135,-.15)
        if repeat: add(voice(note-19,d*BEAT*.95,'horn'),pos,.075,.35)
        if repeat>=2: add(voice(note+5,d*BEAT*.8,'strings'),pos,.05,-.45)
        pos+=d*BEAT
# Long chamber reflections with alternating stereo spread.
dry=out.copy()
for delay,g in [(.113,.19),(.227,.15),(.389,.12),(.617,.1),(.997,.08),(1.61,.055),(2.13,.04)]:
    offset=int(delay*SR);out[offset:]+=dry[:-offset,::-1]*g
out*=np.minimum(1,np.arange(len(out))/(SR*2))[:,None]
out*=np.minimum(1,np.arange(len(out))[::-1]/(SR*4))[:,None]
out=np.tanh(out*1.1);out*=.88/max(1e-9,np.max(np.abs(out)))
assert np.isfinite(out).all()
with wave.open(str(ROOT/'audio/stone-and-snow-epic.wav'),'wb') as f:
    f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes((out*32767).astype('<i2').tobytes())
print(f'148 BPM epic arrangement: {len(out)/SR:.1f}s stereo, peak {np.max(np.abs(out)):.2f}')
