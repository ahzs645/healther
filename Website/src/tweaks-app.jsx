const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#14B8A6",
  "headlineStyle": "stacked",
  "heroBg": "soft",
  "phoneVariant": "summary",
  "showFloats": true,
  "ctaCopy": "Bring your health exports into one place."
}/*EDITMODE-END*/;

function App(){
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  React.useEffect(()=>{
    document.documentElement.style.setProperty('--teal', t.accent);
    // derive a darker variant
    const darker = shade(t.accent, -14);
    document.documentElement.style.setProperty('--teal-deep', darker);
  }, [t.accent]);

  React.useEffect(()=>{
    const h1 = document.querySelector('.hero-copy h1');
    if(!h1) return;
    if(t.headlineStyle === 'inline'){
      h1.innerHTML = 'A native, manual way to bring your health data <span class="accent">into Apple Health.</span>';
    } else if (t.headlineStyle === 'punchy'){
      h1.innerHTML = '<span class="accent">Health data,</span><br/>imported by hand.';
    } else {
      h1.innerHTML = 'A native, manual way to bring your<br/><span class="accent">health data into Apple Health.</span>';
    }
  }, [t.headlineStyle]);

  React.useEffect(()=>{
    const bg = document.querySelector('.hero-bg');
    if(!bg) return;
    bg.style.opacity = t.heroBg === 'plain' ? '0' : '1';
    bg.style.filter = t.heroBg === 'vivid' ? 'saturate(160%)' : 'none';
  }, [t.heroBg]);

  React.useEffect(()=>{
    document.querySelectorAll('.float').forEach(f=>{
      f.style.display = t.showFloats ? '' : 'none';
    });
  }, [t.showFloats]);

  return (
    <TweaksPanel title="Tweaks">
      <TweakSection label="Brand" />
      <TweakColor  label="Accent" value={t.accent}
                   onChange={(v)=>setTweak('accent', v)} />

      <TweakSection label="Hero" />
      <TweakRadio  label="Headline" value={t.headlineStyle}
                   options={['stacked','inline','punchy']}
                   onChange={(v)=>setTweak('headlineStyle', v)} />
      <TweakRadio  label="Background" value={t.heroBg}
                   options={['plain','soft','vivid']}
                   onChange={(v)=>setTweak('heroBg', v)} />
      <TweakToggle label="Floating bubbles" value={t.showFloats}
                   onChange={(v)=>setTweak('showFloats', v)} />
    </TweaksPanel>
  );
}

// quick HSL-ish darken/lighten
function shade(hex, pct){
  const n = parseInt(hex.slice(1),16);
  let r = (n>>16)&255, g=(n>>8)&255, b=n&255;
  const f = (1 + pct/100);
  r = Math.max(0,Math.min(255,Math.round(r*f)));
  g = Math.max(0,Math.min(255,Math.round(g*f)));
  b = Math.max(0,Math.min(255,Math.round(b*f)));
  return '#'+[r,g,b].map(x=>x.toString(16).padStart(2,'0')).join('');
}

function renderTweaks() {
  ReactDOM.createRoot(document.getElementById('tweaks-root')).render(<App/>);
}

if (document.querySelector('.hero-copy h1')) {
  renderTweaks();
} else {
  window.addEventListener('healther-components-loaded', renderTweaks, { once: true });
}
