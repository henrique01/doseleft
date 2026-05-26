// DoseLeft — shared UI primitives
// Status bar, home indicator, progress ring, nav bars, list rows, etc.
// All sized in iOS pt (which we render 1:1 as CSS px).

const DL_W = 393;   // iPhone 15 Pro logical width
const DL_H = 852;   // iPhone 15 Pro logical height

// ─────────────────────────────────────────────────────────────────
// Status bar — 9:41, faux signal/wifi/battery
function DLStatusBar({ dark = false }) {
  const fg = dark ? '#F2F2F0' : '#1A1A1C';
  return (
    <div style={{
      height: 54, display: 'flex', alignItems: 'flex-end',
      padding: '0 30px 12px', justifyContent: 'space-between',
      fontFamily: dlTokens.font.text, color: fg,
      fontSize: 17, fontWeight: 600, letterSpacing: -0.2,
    }}>
      <div style={{ minWidth: 60 }}>9:41</div>
      <div style={{ width: 124, height: 36 }}/>{/* dynamic island gap */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, minWidth: 60, justifyContent: 'flex-end' }}>
        {/* signal */}
        <svg width="18" height="11" viewBox="0 0 18 11">
          {[2,5,8,11].map((h,i) => (
            <rect key={i} x={i*4.2} y={11-h} width="3" height={h} rx="0.6" fill={fg}/>
          ))}
        </svg>
        {/* wifi */}
        <svg width="16" height="11" viewBox="0 0 16 11">
          <path d="M8 11a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z" fill={fg}/>
          <path d="M4 7.2a5.5 5.5 0 0 1 8 0" stroke={fg} strokeWidth="1.4" fill="none" strokeLinecap="round"/>
          <path d="M1.5 4.5a9 9 0 0 1 13 0" stroke={fg} strokeWidth="1.4" fill="none" strokeLinecap="round"/>
        </svg>
        {/* battery */}
        <svg width="26" height="12" viewBox="0 0 26 12">
          <rect x="0.5" y="0.5" width="22" height="11" rx="3" stroke={fg} fill="none" opacity="0.5"/>
          <rect x="2" y="2" width="19" height="8" rx="1.8" fill={fg}/>
          <rect x="23" y="3.6" width="2" height="4.8" rx="1" fill={fg} opacity="0.5"/>
        </svg>
      </div>
    </div>
  );
}

function DLHomeIndicator({ dark = false }) {
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 8,
      display: 'flex', justifyContent: 'center', pointerEvents: 'none',
    }}>
      <div style={{
        width: 134, height: 5, borderRadius: 3,
        background: dark ? '#F2F2F0' : '#1A1A1C',
      }}/>
    </div>
  );
}

function DLDynamicIsland() {
  return (
    <div style={{
      position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
      width: 124, height: 37, borderRadius: 20, background: '#000', zIndex: 5,
    }}/>
  );
}

// ─────────────────────────────────────────────────────────────────
// Phone frame — 393×852 inner canvas with optional bezel & rounded corners.
// `bezel` = false renders just the screen (used inside artboards that already
// have their own frame at exactly 393×852); `bezel` = true draws the device
// shell for the App Icon presentation context.
function DLPhone({ children, theme = 'light', bezel = false, scroll = false, style }) {
  const t = dlTokens[theme];
  const content = (
    <div style={{
      width: DL_W, height: DL_H, background: t.bg,
      position: 'relative', overflow: 'hidden',
      fontFamily: dlTokens.font.text, color: t.text,
      ...style,
    }}>
      <DLDynamicIsland />
      {children}
      <DLHomeIndicator dark={theme === 'dark'} />
    </div>
  );
  if (!bezel) return content;
  return (
    <div style={{
      padding: 12, background: '#0a0a0a', borderRadius: 56,
      boxShadow: '0 0 0 2px #1d1d1d inset',
    }}>
      <div style={{ borderRadius: 44, overflow: 'hidden' }}>{content}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────
// Progress ring. `fill` is 0..1. Stroke is animated when `animate` true.
function DLRing({ size, stroke, fill, color, trackColor = 'rgba(0,0,0,0.06)', children, rotation = -90 }) {
  const r = (size - stroke) / 2;
  const C = 2 * Math.PI * r;
  const clamped = Math.max(0, Math.min(1, fill));
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: `rotate(${rotation}deg)` }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={trackColor} strokeWidth={stroke} fill="none"/>
        <circle
          cx={size/2} cy={size/2} r={r}
          stroke={color} strokeWidth={stroke} fill="none"
          strokeLinecap="round"
          strokeDasharray={`${C * clamped} ${C}`}
        />
      </svg>
      {children != null && (
        <div style={{
          position: 'absolute', inset: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexDirection: 'column',
        }}>{children}</div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────
// Nav bar — large title or compact. Used on most screens.
function DLNavBar({ title, large = false, leading, trailing, theme = 'light', subtitle }) {
  const t = dlTokens[theme];
  return (
    <div style={{ padding: large ? '0 20px 8px' : '0 16px', position: 'relative' }}>
      {!large && (
        <div style={{
          height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative',
        }}>
          <div style={{ position: 'absolute', left: 0, display: 'flex', alignItems: 'center', gap: 6 }}>{leading}</div>
          <div style={{ fontSize: 17, fontWeight: 600, letterSpacing: -0.3, color: t.text }}>{title}</div>
          <div style={{ position: 'absolute', right: 0, display: 'flex', alignItems: 'center', gap: 12 }}>{trailing}</div>
        </div>
      )}
      {large && (
        <div>
          <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>{leading}</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>{trailing}</div>
          </div>
          <div style={{
            fontSize: 34, fontWeight: 700, letterSpacing: -0.8, color: t.text,
            lineHeight: 1.1, marginTop: 4,
          }}>{title}</div>
          {subtitle && <div style={{ fontSize: 15, color: t.text2, marginTop: 4 }}>{subtitle}</div>}
        </div>
      )}
    </div>
  );
}

// Nav button — chevron + label or icon. Used for back/cancel/save.
function DLNavBtn({ children, color, onClick, disabled, weight = 400 }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      background: 'transparent', border: 'none', padding: 0,
      font: 'inherit', fontSize: 17, fontWeight: weight,
      color: disabled ? '#B8B8BC' : (color || '#A78BD5'),
      cursor: disabled ? 'default' : 'pointer',
      display: 'flex', alignItems: 'center', gap: 2,
      letterSpacing: -0.2,
    }}>{children}</button>
  );
}

// ─────────────────────────────────────────────────────────────────
// Primary action button (filled, accent bg, 50pt tall)
function DLPrimaryBtn({ children, color, onClick, theme = 'light', icon }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', height: 50, borderRadius: 14, border: 'none',
      background: color, color: '#fff', font: 'inherit',
      fontFamily: dlTokens.font.text,
      fontSize: 17, fontWeight: 600, letterSpacing: -0.2,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      cursor: 'pointer',
    }}>{icon}{children}</button>
  );
}

function DLSecondaryBtn({ children, onClick, theme = 'light' }) {
  const t = dlTokens[theme];
  return (
    <button onClick={onClick} style={{
      width: '100%', height: 50, borderRadius: 14, border: 'none',
      background: t.fill, color: t.text, font: 'inherit',
      fontFamily: dlTokens.font.text,
      fontSize: 17, fontWeight: 500, letterSpacing: -0.2,
      cursor: 'pointer',
    }}>{children}</button>
  );
}

// ─────────────────────────────────────────────────────────────────
// Grouped section helpers (iOS settings-style "inset grouped" lists).
function DLGroupHeader({ children, theme = 'light' }) {
  const t = dlTokens[theme];
  return (
    <div style={{
      fontSize: 13, color: t.text2, textTransform: 'uppercase',
      letterSpacing: 0.4, fontWeight: 500,
      padding: '20px 20px 8px',
    }}>{children}</div>
  );
}

function DLGroup({ children, theme = 'light', style }) {
  const t = dlTokens[theme];
  return (
    <div style={{
      margin: '0 16px', background: t.surface, borderRadius: 12,
      overflow: 'hidden', ...style,
    }}>{children}</div>
  );
}

function DLRow({ children, theme = 'light', last = false, onClick, style }) {
  const t = dlTokens[theme];
  return (
    <div onClick={onClick} style={{
      padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12,
      minHeight: 44, position: 'relative',
      borderBottom: last ? 'none' : `0.5px solid ${t.sep}`,
      cursor: onClick ? 'pointer' : 'default',
      ...style,
    }}>{children}</div>
  );
}

// "Running low" chip — accent-tinted, no red.
function DLChip({ children, color, dark = false }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center',
      padding: '3px 8px', borderRadius: 6,
      background: dlTokens.tint(color, dark ? 0.22 : 0.14),
      color: dlTokens.saturate(color),
      fontSize: 11, fontWeight: 600, letterSpacing: -0.1,
      lineHeight: 1.2, whiteSpace: 'nowrap',
    }}>{children}</div>
  );
}

Object.assign(window, {
  DL_W, DL_H,
  DLStatusBar, DLHomeIndicator, DLDynamicIsland, DLPhone,
  DLRing, DLNavBar, DLNavBtn, DLPrimaryBtn, DLSecondaryBtn,
  DLGroupHeader, DLGroup, DLRow, DLChip,
});
