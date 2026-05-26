// DoseLeft — Add medication, Schedule editor, History, Settings

// ─────────────────────────────────────────────────────────────────
// 5. ADD MEDICATION
//
// Rethink: instead of an "Icon & color" row that asks the user to pick from
// 8 + 8 = 16 things up front, the screen now has a single hero "preview
// badge" (the colored circle + icon) and three smaller decisions:
//   1. Type    — dropdown (Tablet / Inhaler / Drops …). Auto-picks a default
//                icon and renames the dose unit elsewhere on the screen.
//   2. Color   — a row of inline color "balls" (quicker than a swatch grid).
//   3. Icon    — tap the big badge itself to open a popup. The popup shows
//                the 8 glyphs with a small dot marking the "suggested for
//                this type" default, so changing icon is opt-in.

const DL_MED_TYPES = [
  { id: 'tablet',    label: 'Tablet',         icon: 'pills',   unit: 'tablet',      plural: 'tablets' },
  { id: 'capsule',   label: 'Capsule',        icon: 'pills',   unit: 'capsule',     plural: 'capsules' },
  { id: 'inhaler',   label: 'Inhaler',        icon: 'inhaler', unit: 'puff',        plural: 'puffs' },
  { id: 'drops',     label: 'Drops',          icon: 'drop',    unit: 'drop',        plural: 'drops' },
  { id: 'spray',     label: 'Spray',          icon: 'bottle',  unit: 'spray',       plural: 'sprays' },
  { id: 'cream',     label: 'Cream / gel',    icon: 'tube',    unit: 'application', plural: 'applications' },
  { id: 'patch',     label: 'Patch',          icon: 'patch',   unit: 'patch',       plural: 'patches' },
  { id: 'injection', label: 'Injection / pen', icon: 'syringe', unit: 'dose',       plural: 'doses' },
  { id: 'liquid',    label: 'Liquid',         icon: 'vial',    unit: 'ml',          plural: 'ml' },
];

const DL_ICON_LIST = ['pills','inhaler','drop','bottle','tube','syringe','patch','vial'];

const DL_PALETTE = [
  { key: 'lavender',   hex: dlTokens.accents.lavender },
  { key: 'sage',       hex: dlTokens.accents.sage },
  { key: 'ochre',      hex: dlTokens.accents.ochre },
  { key: 'terracotta', hex: dlTokens.accents.terracotta },
  { key: 'dustyRose',  hex: dlTokens.accents.dustyRose },
  { key: 'plum',       hex: dlTokens.accents.plum },
  { key: 'slate',      hex: dlTokens.accents.slate },
  { key: 'moss',       hex: dlTokens.accents.moss },
];

// `entry` controls which state of the multi-step flow renders:
//   'scan-empty' — landing state with a big Scan card hero + manual fallback
//   'scanning'   — camera viewfinder taking over the screen
//   'scanned'    — form pre-filled from the photo, with sparkle markers
//                  indicating which fields were auto-detected
//   'manual'     — same form, no scan provenance (user opted to type)
function DLAdd({
  entry = 'scan-empty',
  initialType = 'tablet',
  initialColor,
  initialName = 'Singulair',
  initialIcon,
  openSheet = null,
  scanned = false,        // true when fields were populated from a photo
}) {
  const t = dlTokens.light;
  const [mode, setMode] = React.useState(entry);
  const [type, setType] = React.useState(initialType);
  const [iconOverride, setIconOverride] = React.useState(initialIcon || null);
  const [color, setColor] = React.useState(initialColor || dlTokens.accents.sage);
  const [name, setName] = React.useState(initialName);
  const [sheet, setSheet] = React.useState(openSheet); // 'icon' | 'type' | null

  const typeMeta = DL_MED_TYPES.find(x => x.id === type) || DL_MED_TYPES[0];
  const iconName = iconOverride || typeMeta.icon;
  const fromScan = mode === 'scanned' || scanned;

  const changeType = (id) => {
    setType(id);
    setIconOverride(null);
    setSheet(null);
  };

  // CAMERA VIEWFINDER MODE
  if (mode === 'scanning') {
    return (
      <DLPhone>
        <DLScanCamera
          onCancel={() => setMode('scan-empty')}
          onCapture={() => setMode('scanned')}
        />
      </DLPhone>
    );
  }

  // SCAN-EMPTY MODE — big Scan hero card, manual fallback
  if (mode === 'scan-empty') {
    return (
      <DLPhone>
        <DLStatusBar />
        <DLNavBar
          title="New medication"
          leading={<DLNavBtn color="#8A8A8E">Cancel</DLNavBtn>}
        />
        <div style={{ height: 'calc(100% - 54px - 44px - 34px)', overflowY: 'auto', padding: '8px 20px 24px' }}>
          {/* Hero scan card */}
          <button
            onClick={() => setMode('scanning')}
            style={{
              width: '100%', border: 'none', background: '#fff',
              borderRadius: 20, padding: '32px 24px 28px',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
              cursor: 'pointer', fontFamily: 'inherit',
              boxShadow: '0 1px 3px rgba(0,0,0,0.04), 0 0 0 0.5px rgba(0,0,0,0.04)',
              position: 'relative', overflow: 'hidden',
            }}
          >
            {/* Soft accent backdrop */}
            <div style={{
              position: 'absolute', top: -40, right: -40,
              width: 180, height: 180, borderRadius: 90,
              background: dlTokens.tint(dlTokens.accents.lavender, 0.10),
            }}/>
            <div style={{
              position: 'absolute', bottom: -60, left: -30,
              width: 160, height: 160, borderRadius: 80,
              background: dlTokens.tint(dlTokens.accents.sage, 0.08),
            }}/>

            {/* Camera badge */}
            <div style={{
              width: 76, height: 76, borderRadius: 22,
              background: '#1A1A1C', display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 8px 20px rgba(0,0,0,0.16)',
              position: 'relative', zIndex: 1,
              transform: 'rotate(-4deg)',
            }}>
              <DLIcon name="camera" size={36} color="#fff" stroke={1.7}/>
              <div style={{
                position: 'absolute', top: -6, right: -6,
                width: 22, height: 22, borderRadius: 11,
                background: dlTokens.accents.lavender,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 2px 6px rgba(0,0,0,0.12)',
              }}>
                <DLIcon name="sparkle" size={12} color="#fff"/>
              </div>
            </div>

            <div style={{ textAlign: 'center', position: 'relative', zIndex: 1, marginTop: 4 }}>
              <div style={{ fontSize: 22, fontWeight: 700, color: t.text, letterSpacing: -0.5 }}>
                Scan the box
              </div>
              <div style={{ fontSize: 15, color: t.text2, marginTop: 6, lineHeight: 1.4, maxWidth: 280 }}>
                We'll fill in the name, form and how many doses are inside automatically.
              </div>
            </div>

            <div style={{
              marginTop: 10, padding: '12px 24px',
              background: dlTokens.accents.lavender, color: '#fff',
              borderRadius: 14, fontSize: 16, fontWeight: 600,
              display: 'flex', alignItems: 'center', gap: 8,
              position: 'relative', zIndex: 1,
            }}>
              <DLIcon name="camera" size={18} color="#fff" stroke={2}/>
              Open camera
            </div>
          </button>

          {/* What gets filled — small reassurance list */}
          <div style={{ marginTop: 20, padding: '0 4px', display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[
              { icon: 'sparkle', label: 'Medication name' },
              { icon: 'sparkle', label: 'Form (tablet, inhaler, drops…)' },
              { icon: 'sparkle', label: 'Total doses in the container' },
            ].map((row, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div style={{
                  width: 22, height: 22, borderRadius: 11,
                  background: dlTokens.tint(dlTokens.accents.lavender, 0.16),
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <DLIcon name="sparkle" size={11} color={dlTokens.accents.lavender}/>
                </div>
                <div style={{ fontSize: 14, color: t.text2 }}>{row.label}</div>
              </div>
            ))}
          </div>

          {/* Divider with "or" */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '28px 0 16px' }}>
            <div style={{ flex: 1, height: 0.5, background: t.sep }}/>
            <div style={{ fontSize: 12, color: t.text3, letterSpacing: 0.4, textTransform: 'uppercase' }}>or</div>
            <div style={{ flex: 1, height: 0.5, background: t.sep }}/>
          </div>

          <button
            onClick={() => setMode('manual')}
            style={{
              width: '100%', height: 50, borderRadius: 14,
              background: t.fill, color: t.text,
              border: 'none', cursor: 'pointer',
              fontFamily: 'inherit', fontSize: 16, fontWeight: 500,
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            }}
          >
            <DLIcon name="keyboard" size={18} color={t.text} stroke={1.8}/>
            Enter manually
          </button>
        </div>
      </DLPhone>
    );
  }

  // SCANNED or MANUAL — the actual form (sparkles only when scanned)
  return (
    <DLPhone>
      <DLStatusBar />
      <DLNavBar
        title="New medication"
        leading={<DLNavBtn color="#8A8A8E">Cancel</DLNavBtn>}
        trailing={<DLNavBtn color={color} weight={600}>Save</DLNavBtn>}
      />
      <div style={{ height: 'calc(100% - 54px - 44px - 34px)', overflowY: 'auto', position: 'relative' }}>

        {/* Scan provenance strip — only on scanned mode */}
        {fromScan && (
          <div style={{
            margin: '10px 16px 4px',
            padding: '8px 10px 8px 8px',
            background: dlTokens.tint(dlTokens.accents.lavender, 0.10),
            borderRadius: 12,
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <DLBoxThumb size={36}/>
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: t.text, display: 'flex', alignItems: 'center', gap: 5 }}>
                <DLIcon name="sparkle" size={12} color={dlTokens.accents.lavender}/>
                Auto-filled from photo
              </div>
              <div style={{ fontSize: 11, color: t.text2 }}>Tap any field to edit · please verify</div>
            </div>
            <button
              onClick={() => setMode('scanning')}
              style={{
                background: '#fff', border: 'none', cursor: 'pointer',
                padding: '6px 12px', borderRadius: 8,
                fontFamily: 'inherit', fontSize: 13, fontWeight: 600,
                color: dlTokens.accents.lavender,
                display: 'flex', alignItems: 'center', gap: 4,
              }}
            >
              <DLIcon name="camera" size={13} color={dlTokens.accents.lavender} stroke={2}/>
              Retake
            </button>
          </div>
        )}

        {/* HERO: tappable preview badge + name input. The badge is the icon
            picker entry point — tap it to open the popup. */}
        <div style={{ padding: '12px 20px 20px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
          <button
            onClick={() => setSheet('icon')}
            aria-label="Change icon"
            style={{
              width: 96, height: 96, borderRadius: 48,
              background: color, border: 'none', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              position: 'relative', padding: 0,
              boxShadow: `0 10px 24px ${dlTokens.tint(color, 0.32)}, 0 2px 6px ${dlTokens.tint(color, 0.18)}`,
              transition: 'transform .15s, box-shadow .15s',
            }}
          >
            <DLIcon name={iconName} size={48} color="#fff"/>
            {/* edit affordance: pencil chip in the corner */}
            <div style={{
              position: 'absolute', right: -4, bottom: -4,
              width: 30, height: 30, borderRadius: 15,
              background: '#fff', border: `2px solid ${t.bg}`,
              boxShadow: '0 1px 3px rgba(0,0,0,0.14)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <DLIcon name="pencil" size={13} color={t.text2} stroke={2}/>
            </div>
          </button>
          <div style={{ width: '100%', position: 'relative', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <input
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="Medication name"
              style={{
                width: '100%', textAlign: 'center', border: 'none', outline: 'none',
                fontSize: 24, fontWeight: 600, color: t.text, letterSpacing: -0.5,
                background: 'transparent', fontFamily: dlTokens.font.text,
                padding: '2px 0',
              }}
            />
            {fromScan && (
              <DLScanDot/>
            )}
          </div>
        </div>

        {/* FORM (TYPE) + COLOR */}
        <DLGroup style={{ marginTop: 4 }}>
          <DLRow onClick={() => setSheet('type')}>
            <div style={{ flex: 1, fontSize: 17, color: t.text }}>Form</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              {fromScan && <DLScanDot inline/>}
              <div style={{ fontSize: 17, color: t.text2 }}>{typeMeta.label}</div>
            </div>
            <DLIcon name="chev-down" size={16} color={t.text3} stroke={1.8}/>
          </DLRow>
          <DLRow last>
            <div style={{ fontSize: 17, color: t.text }}>Color</div>
            <div style={{ flex: 1, display: 'flex', gap: 0, justifyContent: 'flex-end' }}>
              <div style={{ display: 'flex', gap: 8 }}>
                {DL_PALETTE.map(p => {
                  const selected = p.hex === color;
                  return (
                    <button
                      key={p.key}
                      onClick={() => setColor(p.hex)}
                      aria-label={p.key}
                      style={{
                        width: 22, height: 22, borderRadius: 11,
                        background: p.hex, border: 'none', cursor: 'pointer',
                        outline: selected ? `2px solid ${p.hex}` : 'none',
                        outlineOffset: 2, padding: 0, flex: '0 0 auto',
                        transition: 'transform .12s',
                        transform: selected ? 'scale(1.0)' : 'scale(1.0)',
                      }}
                    />
                  );
                })}
              </div>
            </div>
          </DLRow>
        </DLGroup>

        {/* QUANTITY */}
        <DLGroupHeader>
          Quantity {fromScan && <span style={{ textTransform: 'none', letterSpacing: 0, color: dlTokens.accents.lavender, fontWeight: 500, marginLeft: 4 }}>· detected on label</span>}
        </DLGroupHeader>
        <DLGroup>
          <DLRow last>
            <div style={{ flex: 1, fontSize: 17, color: t.text, display: 'flex', alignItems: 'center', gap: 6 }}>
              Total <span style={{ color: t.text2, fontSize: 15 }}>· {typeMeta.plural}</span>
              {fromScan && <DLScanDot inline/>}
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <DLStepperBtn small><DLIcon name="minus" size={16} color={t.text} stroke={2}/></DLStepperBtn>
              <div style={{ fontFamily: dlTokens.font.rounded, fontSize: 24, fontWeight: 700, letterSpacing: -0.5, minWidth: 40, textAlign: 'center', color: t.text }} className="dl-tabnums">30</div>
              <DLStepperBtn small><DLIcon name="plus" size={16} color={t.text} stroke={2}/></DLStepperBtn>
            </div>
          </DLRow>
        </DLGroup>

        {/* SCHEDULE */}
        <DLGroupHeader>Schedule</DLGroupHeader>
        <DLGroup>
          <DLRow>
            <div style={{ flex: 1, display: 'flex', alignItems: 'baseline', gap: 8, flexWrap: 'wrap' }}>
              <div style={{ fontFamily: dlTokens.font.rounded, fontSize: 17, fontWeight: 600, color: t.text }}>9:00 PM</div>
              <div style={{ fontSize: 13, color: t.text2 }}>· 1 {typeMeta.unit} · Every day</div>
            </div>
            <DLIcon name="chev-right" size={16} color={t.text3} stroke={1.8}/>
          </DLRow>
          <DLRow last>
            <div style={{ flex: 1, fontSize: 17, color: color, fontWeight: 500 }}>+ Add another time</div>
          </DLRow>
        </DLGroup>

        {/* REMINDER */}
        <DLGroupHeader>Remind me</DLGroupHeader>
        <DLGroup>
          <DLRow last>
            <div style={{ flex: 1, fontSize: 17, color: t.text }}>Days before empty</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <DLStepperBtn small><DLIcon name="minus" size={16} color={t.text} stroke={2}/></DLStepperBtn>
              <div style={{ fontFamily: dlTokens.font.rounded, fontSize: 22, fontWeight: 700, minWidth: 28, textAlign: 'center', color: t.text }} className="dl-tabnums">7</div>
              <DLStepperBtn small><DLIcon name="plus" size={16} color={t.text} stroke={2}/></DLStepperBtn>
            </div>
          </DLRow>
        </DLGroup>

        <div style={{ height: 32 }}/>

        {/* Sheets overlay inside the phone frame */}
        {sheet === 'icon' && (
          <DLIconPickerSheet
            color={color}
            selected={iconName}
            defaultIcon={typeMeta.icon}
            typeLabel={typeMeta.label}
            onPick={(n) => { setIconOverride(n === typeMeta.icon ? null : n); setSheet(null); }}
            onClose={() => setSheet(null)}
          />
        )}
        {sheet === 'type' && (
          <DLTypePickerSheet
            color={color}
            selected={type}
            onPick={changeType}
            onClose={() => setSheet(null)}
          />
        )}
      </div>
    </DLPhone>
  );
}

// Tiny stepper button — extracted because it appears twice.
function DLStepperBtn({ children, small }) {
  const t = dlTokens.light;
  const s = small ? 28 : 32;
  return (
    <button style={{
      width: s, height: s, borderRadius: s / 2, background: t.fill,
      border: 'none', cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>{children}</button>
  );
}

// Bottom-sheet popup for picking the icon. Suggested-for-type icon gets a
// small accent dot so the user knows what was preselected.
function DLIconPickerSheet({ color, selected, defaultIcon, typeLabel, onPick, onClose }) {
  const t = dlTokens.light;
  return (
    <React.Fragment>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.32)', zIndex: 20,
      }}/>
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: t.bg,
        borderTopLeftRadius: 20, borderTopRightRadius: 20,
        padding: '10px 20px 36px',
        zIndex: 21,
        boxShadow: '0 -8px 30px rgba(0,0,0,0.16)',
      }}>
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 8 }}>
          <div style={{ width: 36, height: 5, borderRadius: 3, background: 'rgba(0,0,0,0.18)' }}/>
        </div>
        <div style={{ textAlign: 'center', fontSize: 17, fontWeight: 600, color: t.text, marginBottom: 2 }}>
          Choose icon
        </div>
        <div style={{ textAlign: 'center', fontSize: 13, color: t.text2, marginBottom: 20 }}>
          Suggested for <span style={{ color: t.text, fontWeight: 500 }}>{typeLabel.toLowerCase()}</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', rowGap: 18, columnGap: 8 }}>
          {DL_ICON_LIST.map(name => {
            const isSelected = name === selected;
            const isDefault = name === defaultIcon;
            return (
              <button
                key={name}
                onClick={() => onPick(name)}
                style={{
                  background: 'none', border: 'none', cursor: 'pointer', padding: 0,
                  display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
                }}
              >
                <div style={{
                  width: 60, height: 60, borderRadius: 30,
                  background: isSelected ? color : '#fff',
                  border: isSelected ? `2px solid ${color}` : `0.5px solid ${t.sep}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  position: 'relative',
                  transition: 'all .15s',
                }}>
                  <DLIcon name={name} size={30} color={isSelected ? '#fff' : '#8A8A8E'}/>
                  {isDefault && !isSelected && (
                    <div style={{
                      position: 'absolute', top: 0, right: 0,
                      width: 12, height: 12, borderRadius: 6,
                      background: color, border: `2px solid ${t.bg}`,
                    }}/>
                  )}
                </div>
                <div style={{
                  fontSize: 11,
                  color: isSelected ? t.text : t.text2,
                  fontWeight: isSelected ? 600 : 400,
                  letterSpacing: 0.1,
                }}>
                  {isDefault ? 'Default' : ''}
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </React.Fragment>
  );
}

// Bottom-sheet popup for picking the form / type.
function DLTypePickerSheet({ color, selected, onPick, onClose }) {
  const t = dlTokens.light;
  return (
    <React.Fragment>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.32)', zIndex: 20,
      }}/>
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: t.bg,
        borderTopLeftRadius: 20, borderTopRightRadius: 20,
        padding: '10px 0 28px',
        zIndex: 21, maxHeight: '70%', overflowY: 'auto',
        boxShadow: '0 -8px 30px rgba(0,0,0,0.16)',
      }}>
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 8 }}>
          <div style={{ width: 36, height: 5, borderRadius: 3, background: 'rgba(0,0,0,0.18)' }}/>
        </div>
        <div style={{ textAlign: 'center', fontSize: 17, fontWeight: 600, color: t.text, marginBottom: 12 }}>
          Form
        </div>
        <div>
          {DL_MED_TYPES.map((opt, i) => {
            const isSelected = opt.id === selected;
            return (
              <div
                key={opt.id}
                onClick={() => onPick(opt.id)}
                style={{
                  display: 'flex', alignItems: 'center', gap: 14,
                  padding: '12px 20px',
                  borderBottom: i === DL_MED_TYPES.length - 1 ? 'none' : `0.5px solid ${t.sep}`,
                  cursor: 'pointer',
                  background: isSelected ? dlTokens.tint(color, 0.08) : 'transparent',
                }}
              >
                <div style={{
                  width: 36, height: 36, borderRadius: 18,
                  background: isSelected ? color : t.fill,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <DLIcon name={opt.icon} size={18} color={isSelected ? '#fff' : '#8A8A8E'}/>
                </div>
                <div style={{ flex: 1, fontSize: 17, color: t.text, fontWeight: isSelected ? 600 : 400 }}>{opt.label}</div>
                {isSelected && <DLIcon name="check" size={18} color={color} stroke={2.2}/>}
              </div>
            );
          })}
        </div>
      </div>
    </React.Fragment>
  );
}

// Sparkle marker placed inline next to an auto-filled value. Two variants —
// floating (absolute, used next to large hero text) or inline (sized chip).
function DLScanDot({ inline = false }) {
  if (inline) {
    return (
      <span style={{
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        width: 16, height: 16, borderRadius: 8,
        background: dlTokens.tint(dlTokens.accents.lavender, 0.18),
      }}>
        <DLIcon name="sparkle" size={9} color={dlTokens.accents.lavender}/>
      </span>
    );
  }
  return (
    <span style={{
      position: 'absolute', right: 0, top: '50%', transform: 'translateY(-50%)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      width: 20, height: 20, borderRadius: 10,
      background: dlTokens.tint(dlTokens.accents.lavender, 0.18),
    }}>
      <DLIcon name="sparkle" size={11} color={dlTokens.accents.lavender}/>
    </span>
  );
}

// Small inline SVG of a medicine box — used as the photo thumbnail in the
// "Auto-filled from photo" strip. (No real photo available; this stands in.)
function DLBoxThumb({ size = 40 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: 8,
      background: '#E6E1D4', overflow: 'hidden',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flex: '0 0 auto', position: 'relative',
    }}>
      <svg width={size} height={size} viewBox="0 0 40 40">
        <rect x="8" y="6" width="24" height="30" rx="2" fill="#F5F0E4" stroke="#D5C9AC" strokeWidth="0.6"/>
        <rect x="11" y="11" width="18" height="2" rx="1" fill="#9CAF88"/>
        <rect x="11" y="16" width="14" height="1.4" rx="0.7" fill="#C5BBA0"/>
        <rect x="11" y="19" width="10" height="1.4" rx="0.7" fill="#C5BBA0"/>
        <rect x="11" y="26" width="18" height="6" rx="1" fill="#fff" stroke="#D5C9AC" strokeWidth="0.4"/>
        <text x="20" y="30.4" textAnchor="middle" fontSize="3.4" fontWeight="700" fill="#1A1A1C" fontFamily="system-ui">30</text>
      </svg>
    </div>
  );
}

// CAMERA VIEWFINDER — covers the phone area minus the home indicator
function DLScanCamera({ onCancel, onCapture }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: '#0A0A0A',
      color: '#fff', display: 'flex', flexDirection: 'column',
      overflow: 'hidden',
    }}>
      <DLStatusBar dark/>
      {/* Top bar */}
      <div style={{
        position: 'relative', zIndex: 2,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '4px 18px', height: 44,
      }}>
        <button onClick={onCancel} style={{
          width: 34, height: 34, borderRadius: 17,
          background: 'rgba(255,255,255,0.12)', border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <DLIcon name="close" size={18} color="#fff" stroke={2}/>
        </button>
        <div style={{ fontSize: 15, fontWeight: 600, color: '#fff' }}>Scan medication</div>
        <button style={{
          width: 34, height: 34, borderRadius: 17,
          background: 'rgba(255,255,255,0.12)', border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <DLIcon name="flash" size={16} color="#fff" stroke={1.8}/>
        </button>
      </div>

      {/* Viewfinder — fake camera scene of a medicine box being scanned */}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {/* Faux camera background — subtle gradient + scene */}
        <div style={{
          position: 'absolute', inset: 0,
          background: 'radial-gradient(ellipse at 50% 60%, #2a2520 0%, #100c0a 70%)',
        }}/>
        {/* Tilted "box" being detected */}
        <div style={{
          position: 'absolute', left: '50%', top: '50%',
          transform: 'translate(-50%, -50%) rotate(-3deg)',
          width: 200, height: 260, borderRadius: 6,
          background: 'linear-gradient(180deg, #F5F0E4 0%, #E6E1D4 100%)',
          boxShadow: '0 30px 60px rgba(0,0,0,0.5), 0 8px 18px rgba(0,0,0,0.35)',
          padding: '24px 18px',
          fontFamily: dlTokens.font.text,
        }}>
          <div style={{ width: 60, height: 4, background: '#9CAF88', borderRadius: 2 }}/>
          <div style={{ marginTop: 14, fontSize: 18, fontWeight: 700, color: '#1A1A1C', letterSpacing: -0.4 }}>SINGULAIR</div>
          <div style={{ marginTop: 2, fontSize: 9, color: '#6A6A6E', letterSpacing: 0.4 }}>MONTELUKAST SODIUM</div>
          <div style={{ marginTop: 10, fontSize: 8, color: '#6A6A6E' }}>10 mg film-coated tablets</div>
          <div style={{ marginTop: 14, padding: '6px 8px', background: '#fff', border: '0.5px solid #C5BBA0', borderRadius: 3, fontSize: 8, color: '#3a3a3c', textAlign: 'center' }}>
            30 TABLETS
          </div>
          <div style={{ marginTop: 24, display: 'flex', gap: 2, alignItems: 'flex-end', height: 22 }}>
            {[3,5,2,7,4,6,3,5,4,7,2,6,3,5].map((h,i) => (
              <div key={i} style={{ width: 1.5, height: h * 3, background: '#1A1A1C' }}/>
            ))}
          </div>
        </div>

        {/* Detection brackets framing the box */}
        <DLScanBrackets/>

        {/* Caption */}
        <div style={{
          position: 'absolute', left: 0, right: 0, top: 30,
          display: 'flex', justifyContent: 'center',
        }}>
          <div style={{
            padding: '8px 14px', background: 'rgba(0,0,0,0.55)',
            backdropFilter: 'blur(8px)', borderRadius: 999,
            fontSize: 13, color: '#fff', fontWeight: 500,
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <span style={{
              width: 8, height: 8, borderRadius: 4, background: dlTokens.accents.sage,
              boxShadow: `0 0 8px ${dlTokens.accents.sage}`,
            }}/>
            Detecting label…
          </div>
        </div>

        {/* Detected label chip — appears near the box */}
        <div style={{
          position: 'absolute', left: '50%', bottom: 130,
          transform: 'translateX(-50%)',
        }}>
          <div style={{
            padding: '6px 10px', background: '#fff', borderRadius: 8,
            fontSize: 12, fontWeight: 600, color: '#1A1A1C',
            display: 'flex', alignItems: 'center', gap: 6,
            boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
          }}>
            <DLIcon name="sparkle" size={11} color={dlTokens.accents.lavender}/>
            Singulair · 30 tablets
          </div>
        </div>
      </div>

      {/* Bottom control area */}
      <div style={{
        padding: '20px 0 40px',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        gap: 56, position: 'relative', zIndex: 2,
      }}>
        <button onClick={onCancel} style={{
          background: 'transparent', border: 'none', color: '#fff', fontSize: 15,
          cursor: 'pointer', fontFamily: 'inherit', opacity: 0.8,
        }}>Cancel</button>
        <button
          onClick={onCapture}
          style={{
            width: 72, height: 72, borderRadius: 36, border: '4px solid #fff',
            background: 'transparent', cursor: 'pointer', padding: 4,
          }}
        >
          <div style={{ width: '100%', height: '100%', borderRadius: '50%', background: '#fff' }}/>
        </button>
        <div style={{ width: 50, fontSize: 13, color: '#fff', opacity: 0.6, textAlign: 'center' }}>
          Auto
        </div>
      </div>
    </div>
  );
}

// Corner brackets that frame the medication box being scanned.
function DLScanBrackets() {
  const c = '#fff';
  const len = 22;
  const w = 3;
  // Rectangle centered, roughly 230x290
  const box = { left: '50%', top: '50%', width: 230, height: 290 };
  const corner = (extra) => ({
    position: 'absolute', width: len, height: len, borderColor: c, borderStyle: 'solid', ...extra,
  });
  return (
    <div style={{
      position: 'absolute', left: box.left, top: box.top,
      width: box.width, height: box.height,
      transform: 'translate(-50%, -50%) rotate(-3deg)',
      pointerEvents: 'none',
    }}>
      <div style={corner({ left: -6, top: -6, borderWidth: `${w}px 0 0 ${w}px`, borderRadius: '4px 0 0 0' })}/>
      <div style={corner({ right: -6, top: -6, borderWidth: `${w}px ${w}px 0 0`, borderRadius: '0 4px 0 0' })}/>
      <div style={corner({ left: -6, bottom: -6, borderWidth: `0 0 ${w}px ${w}px`, borderRadius: '0 0 0 4px' })}/>
      <div style={corner({ right: -6, bottom: -6, borderWidth: `0 ${w}px ${w}px 0`, borderRadius: '0 0 4px 0' })}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────
// 6. SCHEDULE EDITOR (sheet)

function DLSchedule() {
  const accent = dlTokens.accents.lavender;
  const t = dlTokens.light;
  const days = ['S','M','T','W','T','F','S'];
  const dayChip = (letter, on) => (
    <div style={{
      width: 28, height: 28, borderRadius: 14,
      background: on ? accent : t.fill,
      color: on ? '#fff' : t.text2,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 12, fontWeight: 600,
    }}>{letter}</div>
  );

  return (
    <DLPhone>
      {/* Sheet handle */}
      <div style={{
        height: 8, position: 'absolute', top: 60, left: 0, right: 0,
        display: 'flex', justifyContent: 'center', zIndex: 4,
      }}>
        <div style={{ width: 36, height: 5, borderRadius: 3, background: 'rgba(0,0,0,0.18)' }}/>
      </div>
      <DLStatusBar />
      <div style={{ height: 16 }}/>
      <DLNavBar
        title="Schedule"
        leading={<div style={{ width: 60 }}/>}
        trailing={<DLNavBtn color={accent} weight={600}>Done</DLNavBtn>}
      />

      <div style={{ padding: '0 0 24px', overflowY: 'auto', height: 'calc(100% - 54px - 44px - 16px - 34px)' }}>
        <DLGroupHeader>Dose times</DLGroupHeader>
        {[{ time: '8:00 AM', count: 2, on: [1,1,1,1,1,1,1] }, { time: '8:00 PM', count: 2, on: [1,1,1,1,1,1,1] }].map((row, i, arr) => (
          <DLGroup key={i} style={{ marginBottom: 12 }}>
            <DLRow>
              <div style={{ flex: 1, fontSize: 17, color: t.text }}>Time</div>
              <div style={{
                padding: '6px 12px', background: t.fill, borderRadius: 8,
                fontFamily: dlTokens.font.rounded, fontSize: 17, fontWeight: 600, color: t.text,
              }}>{row.time}</div>
            </DLRow>
            <DLRow>
              <div style={{ flex: 1, fontSize: 17, color: t.text }}>Puffs</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <button style={{ width: 28, height: 28, borderRadius: 14, background: t.fill, border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <DLIcon name="minus" size={16} color={t.text} stroke={2}/>
                </button>
                <div style={{ fontFamily: dlTokens.font.rounded, fontSize: 22, fontWeight: 700, minWidth: 28, textAlign: 'center', color: t.text }}>{row.count}</div>
                <button style={{ width: 28, height: 28, borderRadius: 14, background: t.fill, border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <DLIcon name="plus" size={16} color={t.text} stroke={2}/>
                </button>
              </div>
            </DLRow>
            <DLRow last>
              <div style={{ flex: 1, fontSize: 15, color: t.text2 }}>Days</div>
              <div style={{ display: 'flex', gap: 5 }}>
                {days.map((d, di) => <React.Fragment key={di}>{dayChip(d, row.on[di])}</React.Fragment>)}
              </div>
            </DLRow>
          </DLGroup>
        ))}
        <DLGroup>
          <DLRow last>
            <div style={{ flex: 1, textAlign: 'left', fontSize: 17, color: accent, fontWeight: 500 }}>+ Add dose time</div>
          </DLRow>
        </DLGroup>
      </div>
    </DLPhone>
  );
}

// ─────────────────────────────────────────────────────────────────
// 7. HISTORY

function DLHistory() {
  const med = dlMeds[0]; // Flixotide
  const accent = med.accent;
  const t = dlTokens.light;
  const sections = [
    { label: 'Today', rows: [
      { time: '8:00 AM', dose: '2 puffs', tag: 'Scheduled' },
    ]},
    { label: 'Yesterday', rows: [
      { time: '8:12 PM', dose: '2 puffs', tag: 'Manual' },
      { time: '8:00 AM', dose: '2 puffs', tag: 'Scheduled' },
    ]},
    { label: 'This week', rows: [
      { time: 'Tue 8:00 PM', dose: '2 puffs', tag: 'Scheduled' },
      { time: 'Tue 8:00 AM', dose: '2 puffs', tag: 'Scheduled' },
      { time: 'Mon 8:00 PM', dose: '2 puffs', tag: 'Scheduled' },
      { time: 'Mon 8:04 AM', dose: '2 puffs', tag: 'Manual' },
    ]},
    { label: 'Earlier', rows: [
      { time: 'Sun, Feb 8',   dose: 'Container reset', tag: 'Reset' },
      { time: 'Sat, Feb 7',   dose: '2 puffs',         tag: 'Scheduled' },
      { time: 'Fri, Feb 6',   dose: 'Adjusted −2',     tag: 'Correction' },
    ]},
  ];
  return (
    <DLPhone>
      <DLStatusBar />
      <DLNavBar
        title="Flixotide"
        leading={
          <DLNavBtn color={accent}>
            <DLIcon name="chev-left" size={26} color={accent} stroke={1.5}/>
            <span style={{ marginLeft: -2 }}>Back</span>
          </DLNavBtn>
        }
      />
      <div style={{ padding: '8px 20px 4px' }}>
        <div style={{ fontSize: 34, fontWeight: 700, letterSpacing: -0.8, color: t.text }}>History</div>
        <div style={{ fontSize: 15, color: t.text2, marginTop: 2 }}>All logged doses for this medication.</div>
      </div>
      <div style={{ height: 'calc(100% - 54px - 44px - 80px - 34px)', overflowY: 'auto' }}>
        {sections.map((sec) => (
          <div key={sec.label}>
            <DLGroupHeader>{sec.label}</DLGroupHeader>
            <DLGroup>
              {sec.rows.map((r, i) => (
                <DLActivityRow key={i} time={r.time} dose={r.dose}
                  tag={r.tag}
                  tagColor={r.tag === 'Manual' ? accent : null}
                  last={i === sec.rows.length - 1}
                />
              ))}
            </DLGroup>
          </div>
        ))}
        <div style={{ height: 32 }}/>
      </div>
    </DLPhone>
  );
}

// ─────────────────────────────────────────────────────────────────
// 8. SETTINGS

function DLSettings() {
  const t = dlTokens.light;
  const accent = dlTokens.accents.lavender;
  return (
    <DLPhone>
      <DLStatusBar />
      <DLNavBar large title="Settings"
        leading={
          <DLNavBtn color={accent}>
            <DLIcon name="chev-left" size={26} color={accent} stroke={1.5}/>
            <span style={{ marginLeft: -2 }}>Medications</span>
          </DLNavBtn>
        }
      />
      <div style={{ height: 'calc(100% - 54px - 92px - 34px)', overflowY: 'auto' }}>
        <DLGroupHeader>Notifications</DLGroupHeader>
        <DLGroup>
          <DLRow>
            <div style={{ flex: 1, fontSize: 17, color: t.text }}>Default lead time</div>
            <div style={{ fontSize: 15, color: t.text2 }}>
              <span style={{ fontFamily: dlTokens.font.rounded, fontWeight: 600, color: t.text }}>7</span>
              <span> days</span>
            </div>
            <DLIcon name="chev-right" size={16} color={t.text3} stroke={1.8}/>
          </DLRow>
          <DLRow>
            <div style={{ flex: 1, fontSize: 17, color: t.text }}>Sound</div>
            <div style={{ fontSize: 15, color: t.text2 }}>Subtle</div>
            <DLIcon name="chev-right" size={16} color={t.text3} stroke={1.8}/>
          </DLRow>
          <DLRow last>
            <div style={{ flex: 1, fontSize: 17, color: t.text }}>Time-sensitive</div>
            <DLToggle on />
          </DLRow>
        </DLGroup>

        <DLGroupHeader>Appearance</DLGroupHeader>
        <DLGroup>
          <DLRow last>
            <div style={{ flex: 1, fontSize: 17, color: t.text }}>Theme</div>
            <div style={{ height: 32, background: t.fill, borderRadius: 9, padding: 2, display: 'flex', width: 220 }}>
              {['System','Light','Dark'].map((s,i) => (
                <div key={s} style={{
                  flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 13, fontWeight: 600, color: i === 0 ? t.text : t.text2,
                  background: i === 0 ? '#fff' : 'transparent',
                  borderRadius: 7,
                  boxShadow: i === 0 ? '0 1px 2px rgba(0,0,0,0.06)' : 'none',
                }}>{s}</div>
              ))}
            </div>
          </DLRow>
        </DLGroup>

        <DLGroupHeader>Privacy</DLGroupHeader>
        <DLGroup>
          <DLRow last>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, color: t.text, lineHeight: 1.4 }}>
                All medication data is stored only on this device. DoseLeft has no servers and no accounts.
              </div>
            </div>
          </DLRow>
        </DLGroup>

        <DLGroupHeader>About</DLGroupHeader>
        <DLGroup>
          <DLRow>
            <div style={{ flex: 1, fontSize: 17, color: t.text }}>Version</div>
            <div style={{ fontSize: 15, color: t.text2, fontFamily: dlTokens.font.rounded }}>1.0.2</div>
          </DLRow>
          <DLRow last>
            <div style={{ flex: 1, fontSize: 17, color: t.text }}>Acknowledgments</div>
            <DLIcon name="chev-right" size={16} color={t.text3} stroke={1.8}/>
          </DLRow>
        </DLGroup>

        <div style={{ height: 40 }}/>
      </div>
    </DLPhone>
  );
}

function DLToggle({ on, color }) {
  const c = color || dlTokens.accents.sage;
  return (
    <div style={{
      width: 51, height: 31, borderRadius: 16,
      background: on ? c : '#E5E5E0', position: 'relative',
      transition: 'background .2s',
    }}>
      <div style={{
        position: 'absolute', top: 2, left: on ? 22 : 2,
        width: 27, height: 27, borderRadius: 14, background: '#fff',
        boxShadow: '0 2px 4px rgba(0,0,0,0.15), 0 1px 1px rgba(0,0,0,0.05)',
        transition: 'left .2s',
      }}/>
    </div>
  );
}

Object.assign(window, { DLAdd, DLSchedule, DLHistory, DLSettings, DLToggle, DLIconPickerSheet, DLTypePickerSheet, DLStepperBtn, DLScanDot, DLBoxThumb, DLScanCamera, DL_MED_TYPES, DL_PALETTE });
