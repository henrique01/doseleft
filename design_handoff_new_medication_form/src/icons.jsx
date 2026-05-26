// DoseLeft — icon set
// Original abstract glyphs representing medication forms. NOT recreations of
// SF Symbols; minimal geometric shapes designed to read clearly inside a 44pt
// accent circle and at small sizes (widget / watch / app icon).

function DLIcon({ name, size = 22, color = '#fff', stroke = 1.8, ...rest }) {
  const s = size;
  const c = color;
  const sw = stroke;
  const props = { width: s, height: s, viewBox: '0 0 24 24', fill: 'none', xmlns: 'http://www.w3.org/2000/svg', ...rest };
  switch (name) {
    case 'inhaler':
      // Two soft lobes — abstract respiratory glyph
      return (
        <svg {...props}>
          <path d="M9 5c-2.6 0-4 2.4-4 6 0 4 2 8 4 8 1.4 0 2-1.3 2-3v-8c0-2-.6-3-2-3z" fill={c}/>
          <path d="M15 5c2.6 0 4 2.4 4 6 0 4-2 8-4 8-1.4 0-2-1.3-2-3v-8c0-2 .6-3 2-3z" fill={c}/>
          <rect x="11" y="4" width="2" height="3" rx="1" fill={c}/>
        </svg>
      );
    case 'drop':
      return (
        <svg {...props}>
          <path d="M12 3.5c0 0 5.5 6 5.5 10.5a5.5 5.5 0 1 1-11 0C6.5 9.5 12 3.5 12 3.5z" fill={c}/>
        </svg>
      );
    case 'pills':
      // Two capsule halves
      return (
        <svg {...props}>
          <rect x="3" y="9.5" width="13" height="6" rx="3" fill={c} opacity="0.55"/>
          <rect x="3" y="9.5" width="6.5" height="6" rx="3" fill={c}/>
          <rect x="13" y="4.5" width="6" height="13" rx="3" transform="rotate(35 16 11)" fill={c} opacity="0.85"/>
        </svg>
      );
    case 'bottle':
      // Spray / squeeze bottle
      return (
        <svg {...props}>
          <rect x="9" y="3" width="6" height="3" rx="0.8" fill={c}/>
          <path d="M7.5 8h9l-.7 11.2A2 2 0 0 1 13.8 21h-3.6a2 2 0 0 1-2-1.8L7.5 8z" fill={c}/>
          <rect x="9" y="11" width="6" height="1.2" rx="0.6" fill={c} opacity="0.3"/>
        </svg>
      );
    case 'tube':
      return (
        <svg {...props}>
          <path d="M5 7h11l3 4-3 4H5z" fill={c}/>
          <rect x="3" y="6" width="2.5" height="10" rx="0.6" fill={c}/>
        </svg>
      );
    case 'syringe':
      return (
        <svg {...props}>
          <path d="M14 4l6 6-1.5 1.5-2-2-7 7-3.5.5.5-3.5 7-7-2-2L13 3z" fill={c}/>
        </svg>
      );
    case 'patch':
      return (
        <svg {...props}>
          <rect x="4" y="7" width="16" height="10" rx="1.5" fill={c}/>
          <circle cx="8" cy="12" r="0.8" fill={c} opacity="0.4"/>
          <circle cx="12" cy="12" r="0.8" fill={c} opacity="0.4"/>
          <circle cx="16" cy="12" r="0.8" fill={c} opacity="0.4"/>
        </svg>
      );
    case 'vial':
      return (
        <svg {...props}>
          <rect x="8" y="3" width="8" height="2.5" rx="0.6" fill={c}/>
          <path d="M9 6h6v12a3 3 0 0 1-6 0z" fill={c}/>
        </svg>
      );
    // UI glyphs (chevrons, gears, bells, etc.) — line-style
    case 'plus':
      return <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round"><path d="M12 5v14M5 12h14"/></svg>;
    case 'gear':
      return (
        <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
          <circle cx="12" cy="12" r="3"/>
          <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 0 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 0 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>
        </svg>
      );
    case 'chev-left':
      return <svg {...props} stroke={c} strokeWidth={sw + 0.4} strokeLinecap="round" strokeLinejoin="round"><polyline points="15 6 9 12 15 18"/></svg>;
    case 'chev-right':
      return <svg {...props} stroke={c} strokeWidth={sw + 0.4} strokeLinecap="round" strokeLinejoin="round"><polyline points="9 6 15 12 9 18"/></svg>;
    case 'check':
      return <svg {...props} stroke={c} strokeWidth={sw + 0.6} strokeLinecap="round" strokeLinejoin="round"><polyline points="5 12.5 10 17 19 7"/></svg>;
    case 'bell':
      return (
        <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
          <path d="M6 8a6 6 0 0 1 12 0c0 7 3 8 3 8H3s3-1 3-8"/>
          <path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>
        </svg>
      );
    case 'lock':
      return (
        <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
          <rect x="4" y="11" width="16" height="10" rx="2"/>
          <path d="M8 11V7a4 4 0 0 1 8 0v4"/>
        </svg>
      );
    case 'minus':
      return <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round"><path d="M5 12h14"/></svg>;
    case 'pencil':
      return (
        <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
          <path d="M12 20h9"/>
          <path d="M16.5 3.5a2.121 2.121 0 1 1 3 3L7 19l-4 1 1-4z"/>
        </svg>
      );
    case 'chev-down':
      return <svg {...props} stroke={c} strokeWidth={sw + 0.4} strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 12 15 18 9"/></svg>;
    case 'camera':
      return (
        <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" fill="none">
          <path d="M3 8a2 2 0 0 1 2-2h2.2l1.4-1.8a1 1 0 0 1 .8-.4h5.2a1 1 0 0 1 .8.4L16.8 6H19a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
          <circle cx="12" cy="13" r="3.6"/>
        </svg>
      );
    case 'sparkle':
      // Tiny "auto-filled / AI suggested" mark — 4-point star + small accent dot
      return (
        <svg {...props} fill={c} stroke="none">
          <path d="M12 2.5l1.6 5.4 5.4 1.6-5.4 1.6L12 16.5l-1.6-5.4L5 9.5l5.4-1.6z"/>
          <circle cx="18.5" cy="4.5" r="1.4"/>
        </svg>
      );
    case 'close':
      return <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>;
    case 'flash':
      return (
        <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" fill="none">
          <path d="M13 2L4 14h7l-1 8 9-12h-7z"/>
        </svg>
      );
    case 'keyboard':
      return (
        <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" fill="none">
          <rect x="3" y="6" width="18" height="12" rx="2"/>
          <path d="M7 10h.01M11 10h.01M15 10h.01M7 14h10"/>
        </svg>
      );
    case 'app':
      return <svg {...props} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9"/></svg>;
    default:
      return <svg {...props}><circle cx="12" cy="12" r="6" fill={c}/></svg>;
  }
}

// 44pt accent circle with icon inside — the leading element for med rows.
function DLMedBadge({ icon, accent, size = 44, iconSize }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size / 2,
      background: accent, flex: '0 0 auto',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <DLIcon name={icon} size={iconSize ?? Math.round(size * 0.5)} color="#fff" />
    </div>
  );
}

Object.assign(window, { DLIcon, DLMedBadge });
