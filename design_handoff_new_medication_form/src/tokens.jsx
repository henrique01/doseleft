// DoseLeft — design tokens
// Brand: soft, modern, quietly competent. No medical iconography, no gradients,
// no heavy shadows, no glassmorphism.

const dlTokens = {
  light: {
    bg:        '#FAFAF7',
    surface:   '#FFFFFF',
    text:      '#1A1A1C',
    text2:     '#8A8A8E',
    text3:     '#B8B8BC',
    sep:       '#E5E5E0',
    fill:      '#F0F0EB',     // grouped-list row bg (subtle)
    tertiary:  '#D5D5CF',     // empty-state illustration tint
    chipBg:    'rgba(0,0,0,0.04)',
  },
  dark: {
    bg:        '#18181A',
    surface:   '#1F1F22',
    text:      '#F2F2F0',
    text2:     '#8A8A8E',
    text3:     '#5A5A5E',
    sep:       '#2C2C2E',
    fill:      '#222226',
    tertiary:  '#3A3A3E',
    chipBg:    'rgba(255,255,255,0.06)',
  },
  // Per-medication accent palette. Muted, never pure primaries.
  accents: {
    sage:        '#9CAF88',
    lavender:   '#A78BD5',
    terracotta:  '#C97B5F',
    plum:        '#8B6B8E',
    ochre:       '#C9A961',
    dustyRose:   '#C49191',
    slate:       '#6F8390',
    moss:        '#7A8B6E',
  },
  // Warning state: same accent, slightly saturated. Never red.
  // Used for the "Running low" chip and banner tinting.
  saturate: (hex) => {
    // Naive ~15% saturation bump in HSL space.
    const h = hex.replace('#','');
    const r = parseInt(h.slice(0,2),16)/255;
    const g = parseInt(h.slice(2,4),16)/255;
    const b = parseInt(h.slice(4,6),16)/255;
    const max = Math.max(r,g,b), min = Math.min(r,g,b);
    let hh,s,l = (max+min)/2;
    if (max===min) { hh=s=0; }
    else {
      const d = max-min;
      s = l>0.5 ? d/(2-max-min) : d/(max+min);
      switch(max){
        case r: hh = (g-b)/d + (g<b?6:0); break;
        case g: hh = (b-r)/d + 2; break;
        default: hh = (r-g)/d + 4;
      }
      hh/=6;
    }
    s = Math.min(1, s * 1.55);
    l = Math.max(0, l - 0.06);
    // hsl→rgb
    const hue2 = (p,q,t) => {
      if(t<0)t+=1; if(t>1)t-=1;
      if(t<1/6) return p+(q-p)*6*t;
      if(t<1/2) return q;
      if(t<2/3) return p+(q-p)*(2/3-t)*6;
      return p;
    };
    const q = l<0.5 ? l*(1+s) : l+s-l*s;
    const p = 2*l-q;
    const R = Math.round(hue2(p,q,hh+1/3)*255);
    const G = Math.round(hue2(p,q,hh)*255);
    const B = Math.round(hue2(p,q,hh-1/3)*255);
    return '#' + [R,G,B].map(x=>x.toString(16).padStart(2,'0')).join('');
  },
  // Soft tint of an accent (for banners + chips). Returns rgba string.
  tint: (hex, alpha = 0.12) => {
    const h = hex.replace('#','');
    const r = parseInt(h.slice(0,2),16);
    const g = parseInt(h.slice(2,4),16);
    const b = parseInt(h.slice(4,6),16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  },
  font: {
    rounded: '-apple-system, BlinkMacSystemFont, "SF Pro Rounded", "Nunito", system-ui, sans-serif',
    text:    '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter", system-ui, sans-serif',
  },
};

// Five demo medications used throughout the mockups, sorted by urgency.
const dlMeds = [
  { id: 'flix',   name: 'Flixotide',       form: 'inhaler', icon: 'inhaler', accent: dlTokens.accents.lavender,  total: 120, remaining: 7,  daysLeft: 4,  nextTime: '8:00 PM', nextDose: '2 puffs',  perDay: 2,  low: true  },
  { id: 'vitd',   name: 'Vitamin D drops', form: 'drops',   icon: 'drop',    accent: dlTokens.accents.ochre,      total: 600, remaining: 96, daysLeft: 12, nextTime: '8:00 AM', nextDose: '4 drops',  perDay: 8,  low: false },
  { id: 'sing',   name: 'Singulair',       form: 'tablet',  icon: 'pills',   accent: dlTokens.accents.sage,       total: 30,  remaining: 23, daysLeft: 23, nextTime: '9:00 PM', nextDose: '1 tablet', perDay: 1,  low: false },
  { id: 'saline', name: 'Saline spray',    form: 'spray',   icon: 'bottle',  accent: dlTokens.accents.dustyRose,  total: 200, remaining: 124, daysLeft: 41, nextTime: '7:30 AM', nextDose: '1 spray',  perDay: 3,  low: false },
  { id: 'iron',   name: 'Iron supplement', form: 'tablet',  icon: 'pills',   accent: dlTokens.accents.plum,       total: 90,  remaining: 67, daysLeft: 67, nextTime: '8:00 AM', nextDose: '1 tablet', perDay: 1,  low: false },
];

Object.assign(window, { dlTokens, dlMeds });
