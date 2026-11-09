const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const { spawn } = require('child_process');
require('dotenv').config();
const supabaseDb = require('./supabase');

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'my_invitation_super_secret_jwt_key_2026';

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static assets and rendered exports
const PROJECT_ROOT = path.resolve(__dirname, '..');
const EXPORTS_DIR = path.join(__dirname, 'exports');
const UPLOADS_DIR = path.join(__dirname, 'uploads');
const DATA_DIR = path.join(__dirname, 'data');

if (!fs.existsSync(EXPORTS_DIR)) fs.mkdirSync(EXPORTS_DIR, { recursive: true });
if (!fs.existsSync(UPLOADS_DIR)) fs.mkdirSync(UPLOADS_DIR, { recursive: true });
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

app.use('/assets', express.static(path.join(PROJECT_ROOT, 'assets')));
app.use('/api/assets', express.static(path.join(PROJECT_ROOT, 'assets')));
app.use('/exports', express.static(EXPORTS_DIR));
app.use('/api/exports', express.static(EXPORTS_DIR));
app.use('/uploads', express.static(UPLOADS_DIR));
app.use('/api/uploads', express.static(UPLOADS_DIR));

// Configure multer for photo uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOADS_DIR),
  filename: (req, file, cb) => cb(null, `upload_${Date.now()}_${file.originalname.replace(/\s+/g, '_')}`)
});
const upload = multer({ storage });

// Local persistent file store
const DB_FILE = path.join(DATA_DIR, 'db.json');
const TEMPLATES_FILE = path.join(DATA_DIR, 'templates.json');

function loadTemplates() {
  if (fs.existsSync(TEMPLATES_FILE)) {
    try {
      const data = JSON.parse(fs.readFileSync(TEMPLATES_FILE, 'utf8'));
      if (Array.isArray(data) && data.length > 0) return data;
    } catch (e) {
      console.error('Error loading templates.json:', e);
    }
  }
  return TEMPLATES;
}

function saveTemplates(templates) {
  fs.writeFileSync(TEMPLATES_FILE, JSON.stringify(templates, null, 2), 'utf8');
}
function loadDb() {
  if (fs.existsSync(DB_FILE)) {
    try {
      return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    } catch (e) {
      console.error('Error reading db.json, initializing default:', e);
    }
  }
  const defaultDb = {
    users: [
      {
        id: 'usr_default_01',
        username: 'rajeshkumar',
        fullName: 'Rajesh Kumar',
        phone: '9876543210',
        passwordHash: bcrypt.hashSync('Password123!', 10),
        createdAt: new Date().toISOString()
      }
    ],
    creations: [
      {
        id: 'cr_01',
        userId: 'usr_default_01',
        templateId: 'tmpl_telugu_chroma_01',
        title: 'Sai Krishna & Deepika Subha Vivaham',
        coupleNames: 'Sai Krishna & Deepika',
        eventDate: 'Sunday, 15 Dec 2026',
        venue: 'Sri Venkateswara Kalyana Mandapam, Hyderabad',
        videoUrl: '/assets/templates/template_01_sample_result.mp4',
        thumbnailUrl: '/assets/templates/thumb_01_green.jpg',
        createdAt: new Date().toISOString()
      }
    ]
  };
  fs.writeFileSync(DB_FILE, JSON.stringify(defaultDb, null, 2), 'utf8');
  return defaultDb;
}

function saveDb(data) {
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf8');
}

// ----------------------------------------------------
// TEMPLATE CATALOG (Strictly matching approved Stitch specs)
// ----------------------------------------------------
const TEMPLATES = [
  {
    id: 'tmpl_telugu_chroma_01',
    title: 'Telugu Vivaham Mandapam (Chroma Key)',
    category: 'Wedding',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: true,
    photoSlotsCount: 2,
    durationSeconds: 102,
    badgeText: 'CHROMA KEY PRO',
    description: 'Traditional Telugu Vivaham with Lord Ganesha invocation, Vedic shlokas, and automatic green screen photo replacement for bride, groom & couple.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_01_green_screen.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_01_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_01_green.jpg',
    templateThumbUrl: '/assets/templates/thumb_01_green.jpg',
    timelineConfig: {
      intro: { start: 0.0, end: 28.0, title: 'Lord Ganesha & Vedic Shloka' },
      brideSolo: { start: 28.0, end: 38.0, title: 'Bride Photo (Chroma Screen)' },
      transition: { start: 38.0, end: 41.0, title: 'Sacred Mantras & Rings' },
      coupleReveal: { start: 41.0, end: 51.0, title: 'Couple Photo (Chroma Screen)' },
      eventDetails: { start: 51.0, end: 102.0, title: 'Muhurtham, Venue & Blessings' }
    }
  },
  {
    id: 'tmpl_telugu_gold_02',
    title: 'Royal Mandapam Vivaham (Gold 5.mp4)',
    category: 'Wedding',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: true,
    photoSlotsCount: 3,
    durationSeconds: 56,
    badgeText: 'ROYAL GOLD',
    description: 'Opulent Kundan gold Telugu wedding invitation with authentic Nadaswaram wedding music, auspicious diya lamps, and floral mandapam.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg',
    timelineConfig: {
      intro: { start: 0.0, end: 15.0, title: 'Shree Rastu Shubhamastu Invocation' },
      brideGroom: { start: 15.0, end: 30.0, title: 'Bride & Groom Names & Photos' },
      muhurtham: { start: 30.0, end: 45.0, title: 'Sumuhurtham & Auspicious Lagna' },
      venue: { start: 45.0, end: 56.0, title: 'Venue & Cordial Welcome' }
    }
  },
  {
    id: 'tmpl_telugu_divine_03',
    title: 'Divine Ganesha Shloka (God i)',
    category: 'Wedding',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: true,
    photoSlotsCount: 2,
    durationSeconds: 59,
    badgeText: 'SACRED 9:16',
    description: 'Sacred mobile portrait wedding invitation featuring glowing golden Lord Ganesha, Sanskrit mantras, and royal golden parchment styling.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg',
    timelineConfig: {
      intro: { start: 0.0, end: 15.0, title: 'Divine Ganesha Blessings' },
      names: { start: 15.0, end: 32.0, title: 'Couple Names & Auspicious Muhurtham' },
      venue: { start: 32.0, end: 59.0, title: 'Ceremonial Venue & Invitation' }
    }
  },
  {
    id: 'tmpl_telugu_classic_text_04',
    title: 'Classic Mandapam Vivaham (Traditional Text)',
    category: 'Wedding',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 56,
    badgeText: 'TRADITIONAL VEDIC',
    description: 'Classic Telugu wedding invitation without photo frames. Features golden floral mandapam, sacred Vedic shlokas, and traditional Nadaswaram wedding instruments.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg',
    timelineConfig: {
      intro: { start: 0.0, end: 15.0, title: 'Shree Rastu Shubhamastu Invocation' },
      brideGroom: { start: 15.0, end: 30.0, title: 'Bride & Groom Names & Auspicious Muhurtham' },
      venue: { start: 30.0, end: 56.0, title: 'Mandapam Venue & Cordial Welcome' }
    }
  },
  {
    id: 'tmpl_telugu_sacred_text_05',
    title: 'Sacred Vedic Shlokas (Divine Ganesha Text)',
    category: 'Wedding',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 59,
    badgeText: 'SACRED SHLOKA',
    description: 'Mobile vertical wedding invitation without couple photos. Features glowing golden Lord Ganesha animation, Mangala Snanam and Muhurtham mantras in Telugu.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg',
    timelineConfig: {
      intro: { start: 0.0, end: 15.0, title: 'Divine Ganesha Blessings' },
      names: { start: 15.0, end: 32.0, title: 'Couple Names & Auspicious Muhurtham' },
      venue: { start: 32.0, end: 59.0, title: 'Ceremonial Venue & Invitation' }
    }
  },
  // --- First Birthday Templates ---
  {
    id: 'tmpl_first_bday_chroma_01',
    title: 'First Birthday Grand Arch (Chroma Key)',
    category: 'First Birthday',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: true,
    photoSlotsCount: 2,
    durationSeconds: 56,
    badgeText: 'BABY SPECIAL',
    description: 'Grand First Birthday invitation video with photo frame and festive celebration music.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg'
  },
  {
    id: 'tmpl_first_bday_divine_02',
    title: 'Little Angel First Birthday (Portrait)',
    category: 'First Birthday',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: true,
    photoSlotsCount: 1,
    durationSeconds: 59,
    badgeText: 'PORTRAIT 9:16',
    description: 'Vertical mobile first birthday video invitation with baby photo and joyful festive animations.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg'
  },
  {
    id: 'tmpl_first_bday_text_03',
    title: 'Joyful First Birthday Celebration (Text)',
    category: 'First Birthday',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 56,
    badgeText: 'TRADITIONAL VEDIC',
    description: 'Festive first birthday celebration invitation with traditional Telugu blessings and auspicious mantras.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg'
  },
  {
    id: 'tmpl_first_bday_text_04',
    title: 'Divine Little Star Milestone (Text 9:16)',
    category: 'First Birthday',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 59,
    badgeText: 'SACRED SHLOKA',
    description: 'Vertical mobile first birthday invitation featuring glowing golden divine motifs and warm family greetings.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg'
  },
  // --- Birthday Templates ---
  {
    id: 'tmpl_bday_gold_01',
    title: 'Royal Birthday Celebration Mandap',
    category: 'Birthday',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: true,
    photoSlotsCount: 2,
    durationSeconds: 56,
    badgeText: 'ROYAL GOLD',
    description: 'Opulent golden birthday celebration invitation with music and grand celebratory motifs.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg'
  },
  {
    id: 'tmpl_bday_portrait_02',
    title: 'Grand Milestone Birthday (Portrait 9:16)',
    category: 'Birthday',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: true,
    photoSlotsCount: 1,
    durationSeconds: 59,
    badgeText: 'PORTRAIT 9:16',
    description: 'Vertical mobile birthday invitation featuring elegant golden animations and birthday person portrait.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg'
  },
  {
    id: 'tmpl_bday_text_03',
    title: 'Classic Birthday Celebration (Text 16:9)',
    category: 'Birthday',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 56,
    badgeText: 'GOLDEN TEXT',
    description: 'Classic landscape birthday invitation with golden party motifs and heartfelt cordial welcome.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg'
  },
  {
    id: 'tmpl_bday_text_04',
    title: 'Auspicious Birthday Greetings (Text 9:16)',
    category: 'Birthday',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 59,
    badgeText: 'SACRED SHLOKA',
    description: 'Mobile vertical birthday invitation with auspicious shlokas and celebratory Telugu greetings.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg'
  },
  // --- Anniversary Templates ---
  {
    id: 'tmpl_anniv_gold_01',
    title: 'Golden Wedding Anniversary Mandap',
    category: 'Anniversary',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: true,
    photoSlotsCount: 2,
    durationSeconds: 56,
    badgeText: 'ANNIVERSARY PRO',
    description: 'Royal wedding anniversary invitation video with romantic couple portraits and traditional music.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg'
  },
  {
    id: 'tmpl_anniv_divine_02',
    title: 'Eternal Love Milestone (Portrait 9:16)',
    category: 'Anniversary',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: true,
    photoSlotsCount: 1,
    durationSeconds: 59,
    badgeText: 'PORTRAIT 9:16',
    description: 'Vertical mobile anniversary celebration invitation featuring sacred blessings and couple memories.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg'
  },
  {
    id: 'tmpl_anniv_text_03',
    title: 'Dampatula Ashirvachanam (Text 16:9)',
    category: 'Anniversary',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 56,
    badgeText: 'TRADITIONAL VEDIC',
    description: 'Traditional wedding anniversary invitation with auspicious Vedic mantras and blessings.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg'
  },
  {
    id: 'tmpl_anniv_text_04',
    title: 'Sacred Silver & Gold Milestone (Text 9:16)',
    category: 'Anniversary',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 59,
    badgeText: 'SACRED SHLOKA',
    description: 'Vertical mobile anniversary celebration video with glowing Vedic blessings and floral design.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg'
  },
  // --- Festivals Templates ---
  {
    id: 'tmpl_fest_gold_01',
    title: 'Grand Festival Puja & Celebrations',
    category: 'Festivals',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: true,
    photoSlotsCount: 2,
    durationSeconds: 56,
    badgeText: 'FESTIVAL SPECIAL',
    description: 'Auspicious festival celebration invitation with family photo frame, traditional diya lamps and music.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg'
  },
  {
    id: 'tmpl_fest_divine_02',
    title: 'Divine Puja & Utsavam (Portrait 9:16)',
    category: 'Festivals',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: true,
    photoSlotsCount: 1,
    durationSeconds: 59,
    badgeText: 'PORTRAIT 9:16',
    description: 'Vertical mobile festival invitation featuring Lord Ganesha blessings, traditional mantras and puja timings.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg'
  },
  {
    id: 'tmpl_fest_text_03',
    title: 'Auspicious Festival Greetings (Text 16:9)',
    category: 'Festivals',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 56,
    badgeText: 'TRADITIONAL VEDIC',
    description: 'Traditional festival invitation with Vedic shlokas, auspicious temple motifs and warm cordial welcome.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_royal_gold.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_02_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_02_gold.jpg',
    templateThumbUrl: '/assets/templates/thumb_02_gold.jpg'
  },
  {
    id: 'tmpl_fest_text_04',
    title: 'Divine Vedic Festival Shlokas (Text 9:16)',
    category: 'Festivals',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 59,
    badgeText: 'SACRED SHLOKA',
    description: 'Mobile vertical festival invitation with glowing divine animations, sacred shlokas and ceremonial details.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_divine_god.mp4'),
    sampleResultPath: path.join(PROJECT_ROOT, 'assets', 'templates', 'template_03_sample_result.mp4'),
    thumbnailUrl: '/assets/templates/thumb_03_god.jpg',
    templateThumbUrl: '/assets/templates/thumb_03_god.jpg'
  }
];

// ----------------------------------------------------
// AUTHENTICATION ROUTES
// ----------------------------------------------------

// POST /api/auth/register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, phone, fullName, password } = req.body;

    if (!username || !phone || !fullName || !password) {
      return res.status(400).json({ error: 'All fields (username, phone, fullName, password) are required.' });
    }

    const db = loadDb();
    const existing = db.users.find(u => u.username.toLowerCase() === username.toLowerCase() || u.phone === phone);
    if (existing) {
      return res.status(409).json({ error: 'User with this username or phone number already exists.' });
    }

    // Secure password hashing
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const newUser = {
      id: `usr_${Date.now()}`,
      username: username.trim(),
      phone: phone.trim(),
      fullName: fullName.trim(),
      passwordHash,
      createdAt: new Date().toISOString()
    };

    db.users.push(newUser);
    saveDb(db);

    const token = jwt.sign({ id: newUser.id, username: newUser.username }, JWT_SECRET, { expiresIn: '30d' });

    res.status(201).json({
      message: 'Account created successfully',
      token,
      user: {
        id: newUser.id,
        username: newUser.username,
        fullName: newUser.fullName,
        phone: newUser.phone
      }
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Internal server error during registration' });
  }
});

// POST /api/auth/login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { identifier, username, phone, password } = req.body;
    const loginKey = (identifier || username || phone || '').trim().toLowerCase();

    if (!loginKey || !password) {
      return res.status(400).json({ error: 'Phone/username and password are required.' });
    }

    const db = loadDb();
    const user = db.users.find(u => u.username.toLowerCase() === loginKey || u.phone === loginKey);

    if (!user) {
      return res.status(401).json({ error: 'Invalid phone number / username or password.' });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid phone number / username or password.' });
    }

    const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, { expiresIn: '30d' });

    res.json({
      message: 'Logged in successfully',
      token,
      user: {
        id: user.id,
        username: user.username,
        fullName: user.fullName,
        phone: user.phone
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error during login' });
  }
});

// ----------------------------------------------------
// OCCASION & TEMPLATE ROUTES (SUPABASE + FALLBACK)
// ----------------------------------------------------

// GET /api/occasions
app.get('/api/occasions', async (req, res) => {
  try {
    const occasions = await supabaseDb.getOccasions();
    res.json({ count: occasions.length, occasions });
  } catch (err) {
    console.error('Fetch occasions error:', err);
    res.status(500).json({ error: 'Failed to fetch occasions', message: err.message });
  }
});

// GET /api/templates
app.get('/api/templates', async (req, res) => {
  try {
    const results = await supabaseDb.getTemplates(req.query);
    if (results && results.length > 0) {
      return res.json({
        count: results.length,
        templates: results
      });
    }
  } catch (err) {
    console.warn('Supabase getTemplates failed, falling back to local JSON:', err.message);
  }

  // Fallback to local templates
  const { religion, orientation, hasPhoto, category } = req.query;
  const allTemplates = loadTemplates();
  let results = [...allTemplates];

  if (religion && religion !== 'All') {
    results = results.filter(t => (t.religion || '').toLowerCase() === religion.toLowerCase());
  }

  if (orientation && orientation !== 'All') {
    results = results.filter(t => t.orientation === orientation);
  }

  if (hasPhoto !== undefined && hasPhoto !== '') {
    const photoBool = hasPhoto === 'true' || hasPhoto === true;
    results = results.filter(t => t.hasPhoto === photoBool);
  }

  if (category && category !== 'All') {
    results = results.filter(t => (t.category || '').toLowerCase() === category.toLowerCase());
  }

  res.json({
    count: results.length,
    templates: results
  });
});

// GET /api/templates/:id
app.get('/api/templates/:id', async (req, res) => {
  try {
    const tmpl = await supabaseDb.getTemplateById(req.params.id);
    if (tmpl) {
      return res.json(tmpl);
    }
  } catch (err) {
    console.warn(`Supabase getTemplateById failed for ${req.params.id}:`, err.message);
  }

  const allTemplates = loadTemplates();
  const tmpl = allTemplates.find(t => t.id === req.params.id);
  if (!tmpl) {
    return res.status(404).json({ error: 'Template not found' });
  }
  res.json(tmpl);
});

// POST /api/templates - Admin creates a new invitation template
app.post('/api/templates', async (req, res) => {
  try {
    const created = await supabaseDb.createTemplate(req.body);
    // Also keep local fallback synced
    const allTemplates = loadTemplates();
    allTemplates.unshift(created);
    saveTemplates(allTemplates);

    res.status(201).json({
      success: true,
      message: 'Template created successfully in Supabase',
      template: created
    });
  } catch (err) {
    console.error('Create template error:', err);
    res.status(500).json({ error: 'Failed to create template', message: err.message });
  }
});

// PUT /api/templates/:id - Admin publishes/saves template configuration
app.put('/api/templates/:id', async (req, res) => {
  try {
    const updated = await supabaseDb.updateTemplate(req.params.id, req.body);
    // Also keep local fallback synced
    const allTemplates = loadTemplates();
    const idx = allTemplates.findIndex(t => t.id === req.params.id);
    if (idx !== -1) {
      allTemplates[idx] = { ...allTemplates[idx], ...updated };
      saveTemplates(allTemplates);
    }

    res.json({
      success: true,
      message: 'Template configuration published successfully to Supabase template_versions',
      template: updated
    });
  } catch (err) {
    console.error('Update template error:', err);
    res.status(500).json({ error: 'Failed to update template', message: err.message });
  }
});

// DELETE /api/templates/:id - Delete template
app.delete('/api/templates/:id', async (req, res) => {
  try {
    await supabaseDb.deleteTemplate(req.params.id);
    // Also keep local fallback synced
    let allTemplates = loadTemplates();
    allTemplates = allTemplates.filter(t => t.id !== req.params.id);
    saveTemplates(allTemplates);

    res.json({ success: true, message: 'Template removed successfully from Supabase' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete template', message: err.message });
  }
});

// ----------------------------------------------------
// ADMIN MEDIA ASSETS
// ----------------------------------------------------

// GET /api/admin/media-assets - List available background videos and images for editor
app.get('/api/admin/media-assets', (req, res) => {
  try {
    const media = [];
    const scanDirs = [
      { dir: path.join(PROJECT_ROOT, 'assets', 'templates'), relPrefix: '/assets/templates' },
      { dir: path.join(PROJECT_ROOT, 'assets'), relPrefix: '/assets' }
    ];

    for (const item of scanDirs) {
      if (fs.existsSync(item.dir)) {
        const files = fs.readdirSync(item.dir);
        for (const file of files) {
          const fullPath = path.join(item.dir, file);
          const stat = fs.statSync(fullPath);
          if (stat.isFile()) {
            const ext = path.extname(file).toLowerCase();
            const isVideo = ['.mp4', '.mov', '.webm', '.mkv'].includes(ext);
            const isImage = ['.png', '.jpg', '.jpeg', '.webp'].includes(ext);
            if (isVideo || isImage) {
              const relPath = path.relative(PROJECT_ROOT, fullPath).replace(/\\/g, '/');
              media.push({
                name: file,
                filePath: relPath,
                url: `${item.relPrefix}/${file}`,
                type: isVideo ? 'video' : 'image',
                sizeBytes: stat.size
              });
            }
          }
        }
      }
    }
    res.json({ count: media.length, assets: media });
  } catch (err) {
    res.status(500).json({ error: 'Failed to read media assets', message: err.message });
  }
});

// POST /api/admin/upload-asset - Upload new background video or asset
app.post('/api/admin/upload-asset', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }
  const relUrl = `/uploads/${path.basename(req.file.path)}`;
  res.json({
    success: true,
    message: 'Asset uploaded successfully',
    filename: req.file.filename,
    filePath: path.relative(PROJECT_ROOT, req.file.path).replace(/\\/g, '/'),
    url: relUrl
  });
});

// ----------------------------------------------------
// VIDEO COMPOSITION & RENDERING ENGINE
// ----------------------------------------------------

// In-memory render job tracking for live progress
const RENDER_JOBS = new Map();

// GET /api/render/status/:jobId
app.get('/api/render/status/:jobId', async (req, res) => {
  const { jobId } = req.params;
  const job = RENDER_JOBS.get(jobId);
  if (job) {
    return res.json(job);
  }

  // Check Supabase invitation_generations
  try {
    const { data: sJob, error } = await supabaseDb.supabase
      .from('invitation_generations')
      .select('*')
      .eq('id', jobId)
      .maybeSingle();

    if (sJob) {
      return res.json({
        jobId: sJob.id,
        status: sJob.status,
        progress: parseFloat(sJob.progress) || 0,
        step: sJob.current_step,
        videoUrl: sJob.output_video_url,
        createdAt: sJob.created_at
      });
    }
  } catch (err) {
    console.error('Error fetching job from Supabase:', err);
  }

  res.status(404).json({ error: 'Render job not found' });
});

// GET /api/render/jobs
app.get('/api/render/jobs', (req, res) => {
  res.json(Array.from(RENDER_JOBS.values()));
});

// POST /api/render - Multi-image & dynamic text rendering with Supabase Storage & Database integration
app.post('/api/render', upload.fields([
  { name: 'photo_1', maxCount: 1 },
  { name: 'photo_2', maxCount: 1 },
  { name: 'photo_3', maxCount: 1 },
  { name: 'photo_4', maxCount: 1 },
  { name: 'photo_5', maxCount: 1 },
  { name: 'womanPhoto', maxCount: 1 },
  { name: 'manPhoto', maxCount: 1 },
  { name: 'photo', maxCount: 1 }
]), async (req, res) => {
  try {
    const {
      templateId = 'tmpl_telugu_chroma_01',
      brideName = 'Deepika',
      groomName = 'Sai Krishna',
      ceremonyTitle = 'Subha Vivaham',
      eventDate = 'Sunday, 15 December 2026',
      muhurthamTime = 'Sumuhurtham: 10:24 AM',
      venue = 'Sri Venkateswara Kalyana Mandapam, Hyderabad',
      rsvp = 'With Best Compliments from Family & Friends',
      userId = 'usr_guest'
    } = req.body;

    let template = null;
    try {
      template = await supabaseDb.getTemplateById(templateId);
    } catch (e) {
      console.warn('Failed to load template from Supabase, trying fallback:', e.message);
    }
    if (!template) {
      const allTemplates = loadTemplates();
      template = allTemplates.find(t => t.id === templateId) || allTemplates[0];
    }

    // Support inline dynamic template configuration (e.g. from Admin preview mode)
    if (req.body.templateConfig) {
      try {
        const parsed = typeof req.body.templateConfig === 'string'
          ? JSON.parse(req.body.templateConfig)
          : req.body.templateConfig;
        if (parsed && typeof parsed === 'object') {
          template = { ...template, ...parsed };
        }
      } catch (_) { }
    }

    const previewMode = req.body.previewMode === 'true' || req.body.previewMode === true;
    const hasPhoto = (req.body.hasPhoto === 'false' || req.body.hasPhoto === false)
      ? false
      : (req.body.hasPhoto === 'true' || req.body.hasPhoto === true || (template.hasPhoto === true && req.body.hasPhoto !== 'false'));

    // Collect uploaded photos across multi-photo slots (strictly only when hasPhoto is true)
    const photos = {};
    if (hasPhoto) {
      const photoKeys = ['photo_1', 'photo_2', 'photo_3', 'photo_4', 'photo_5', 'womanPhoto', 'manPhoto', 'photo'];
      for (const pk of photoKeys) {
        if (req.files && req.files[pk] && req.files[pk][0]) {
          photos[pk] = req.files[pk][0].path;
        } else if (req.body[`${pk}Path`] && fs.existsSync(req.body[`${pk}Path`])) {
          photos[pk] = req.body[`${pk}Path`];
        } else if (req.body[`${pk}Url`]) {
          // Photo uploaded to Supabase Storage - download for FFmpeg processing
          const pUrl = req.body[`${pk}Url`];
          const localDest = path.join(UPLOADS_DIR, `remote_${Date.now()}_${pk}.jpg`);
          try {
            const https = require('https');
            await new Promise((resolve, reject) => {
              https.get(pUrl, (resp) => {
                const fStream = fs.createWriteStream(localDest);
                resp.pipe(fStream);
                fStream.on('finish', () => { fStream.close(); resolve(); });
                fStream.on('error', reject);
              }).on('error', reject);
            });
            if (fs.existsSync(localDest)) {
              photos[pk] = localDest;
            }
          } catch (dlErr) {
            console.warn(`Failed to download remote photo ${pUrl}:`, dlErr);
          }
        }
      }

      // Fallback bindings between woman/man and photo_1/photo_2
      if (!photos['photo_1'] && photos['womanPhoto']) photos['photo_1'] = photos['womanPhoto'];
      if (!photos['photo_2'] && photos['manPhoto']) photos['photo_2'] = photos['manPhoto'];
      if (!photos['womanPhoto'] && photos['photo_1']) photos['womanPhoto'] = photos['photo_1'];
      if (!photos['manPhoto'] && photos['photo_2']) photos['manPhoto'] = photos['photo_2'];
      if (!photos['photo_1'] && photos['photo']) photos['photo_1'] = photos['photo'];
    }

    const timestamp = Date.now();
    const jobId = `job_${timestamp}`;
    const outputFilename = `invitation_${timestamp}.mp4`;
    const outputVideoPath = path.join(EXPORTS_DIR, outputFilename);

    // Resolve master video path (local file priority for accelerated FFmpeg execution)
    let masterVideoPath = template.masterVideoPath || 'assets/templates/template_01_green_screen.mp4';
    if (masterVideoPath.startsWith('http://') || masterVideoPath.startsWith('https://')) {
      const baseName = path.basename(masterVideoPath.split('?')[0]);
      const localCandidate = path.join(PROJECT_ROOT, 'assets/templates', baseName);
      if (fs.existsSync(localCandidate)) {
        masterVideoPath = path.relative(PROJECT_ROOT, localCandidate).replace(/\\/g, '/');
      }
    }

    // Write temp config JSON for data-driven python render engine
    const configPath = path.join(DATA_DIR, `render_config_${timestamp}.json`);
    const renderConfig = {
      template,
      templateId: template.id,
      masterVideoPath,
      outputVideoPath,
      hasPhoto,
      photos,
      userData: {
        ...req.body,
        brideName,
        groomName,
        parentsNames: req.body.parentsNames || 'Smt. Lakshmi & Sri. Venkat Rao',
        ceremonyTitle,
        eventDate,
        muhurthamTime,
        venue,
        rsvp
      },
      previewMode,
      sampleResultPath: template.sampleResultPath
    };

    fs.writeFileSync(configPath, JSON.stringify(renderConfig, null, 2), 'utf8');

    // Register job in memory
    const jobRecord = {
      jobId,
      status: 'processing',
      progress: 0.05,
      step: 'Initializing invitation engine...',
      templateId: template.id,
      outputFilename,
      createdAt: new Date().toISOString()
    };
    RENDER_JOBS.set(jobId, jobRecord);

    // Register job in Supabase invitation_generations table
    supabaseDb.createGenerationRecord(jobId, {
      userId,
      templateId: template.id,
      templateVersionId: template.templateVersionId,
      title: `${groomName} & ${brideName} ${ceremonyTitle}`,
      coupleNames: `${groomName} & ${brideName}`,
      userData: renderConfig.userData,
      inputPhotos: photos
    }).catch(err => console.error('Supabase createGenerationRecord error:', err.message));

    const isAsync = req.query.async === 'true' || req.body.async === 'true' || req.headers['x-async-render'] === 'true';

    // If client requested async processing, return jobId immediately
    if (isAsync) {
      res.status(202).json({
        success: true,
        jobId,
        status: 'processing',
        progress: 0.10,
        step: 'Preparing your invitation...',
        message: 'Video rendering initiated'
      });
    }

    const pythonScript = path.join(__dirname, 'render_engine.py');
    console.log(`[Job ${jobId}] Starting video render for ${groomName} & ${brideName}...`);

    const py = spawn('python', [pythonScript, configPath]);

    let pyOut = '';
    let pyErr = '';

    // Interval to advance estimated progress if python doesn't emit explicit tags
    const progressTimer = setInterval(() => {
      const cur = RENDER_JOBS.get(jobId);
      if (cur && cur.status === 'processing' && cur.progress < 0.94) {
        cur.progress = Math.min(0.94, +(cur.progress + 0.03).toFixed(2));
        if (cur.progress >= 0.15 && cur.progress < 0.35) {
          cur.step = 'Processing wedding details...';
        } else if (cur.progress >= 0.35 && cur.progress < 0.55) {
          cur.step = 'Preparing uploaded photos...';
        } else if (cur.progress >= 0.55 && cur.progress < 0.75) {
          cur.step = 'Creating invitation scenes...';
        } else if (cur.progress >= 0.75 && cur.progress < 0.92) {
          cur.step = 'Rendering your invitation video...';
        } else if (cur.progress >= 0.92) {
          cur.step = 'Finalizing video...';
        }
        supabaseDb.updateGenerationProgress(jobId, cur.progress, cur.step).catch(() => {});
      }
    }, 1200);

    py.stdout.on('data', (d) => {
      const text = d.toString();
      pyOut += text;
      const match = text.match(/PROGRESS:\s*([0-9.]+)\s*\|\s*(.+)/);
      if (match) {
        const p = parseFloat(match[1]);
        const step = match[2].trim();
        const cur = RENDER_JOBS.get(jobId);
        if (cur) {
          cur.progress = p;
          cur.step = step;
          supabaseDb.updateGenerationProgress(jobId, p, step).catch(() => {});
        }
      }
    });

    py.stderr.on('data', (d) => { pyErr += d.toString(); });

    py.on('close', async (code) => {
      clearInterval(progressTimer);
      try { fs.unlinkSync(configPath); } catch (_) { }

      if (code !== 0) {
        console.error(`[Job ${jobId}] Python render returned non-zero (${code}):`, pyErr);
        const cur = RENDER_JOBS.get(jobId) || {};
        cur.status = 'failed';
        cur.error = pyErr || `Render exited with code ${code}`;
        cur.step = 'Rendering encountered an error';
        RENDER_JOBS.set(jobId, cur);

        supabaseDb.failGenerationRecord(jobId, cur.error).catch(() => {});

        if (!isAsync) {
          return res.status(500).json({ success: false, error: cur.error });
        }
        return;
      }

      console.log(`[Job ${jobId}] Render complete: ${outputFilename}`);

      const relativeUrl = `/exports/${outputFilename}`;

      // Upload rendered video to Supabase Storage bucket 'generated-videos'
      let supabaseVideoUrl = null;
      try {
        supabaseVideoUrl = await supabaseDb.uploadRenderedVideo(jobId, outputVideoPath, userId);
      } catch (uploadErr) {
        console.error(`[Job ${jobId}] Failed to upload final video to Supabase Storage:`, uploadErr.message);
      }

      const finalVideoUrl = supabaseVideoUrl || relativeUrl;

      // Update Supabase invitation_generations record
      supabaseDb.completeGenerationRecord(jobId, finalVideoUrl, template.thumbnailUrl).catch(() => {});

      const creationRecord = {
        id: `cr_${timestamp}`,
        userId,
        templateId: template.id,
        title: `${groomName} & ${brideName} ${ceremonyTitle}`,
        coupleNames: `${groomName} & ${brideName}`,
        eventDate,
        venue,
        videoUrl: finalVideoUrl,
        downloadPath: outputVideoPath,
        thumbnailUrl: template.thumbnailUrl || '/assets/templates/thumb_01_green.jpg',
        createdAt: new Date().toISOString()
      };

      const db = loadDb();
      db.creations.unshift(creationRecord);
      saveDb(db);

      // Update job record to completed
      const cur = RENDER_JOBS.get(jobId) || {};
      cur.status = 'completed';
      cur.progress = 1.0;
      cur.step = 'Video ready!';
      cur.creationId = creationRecord.id;
      cur.videoUrl = finalVideoUrl;
      cur.downloadPath = outputVideoPath;
      cur.durationSeconds = template.durationSeconds;
      cur.coupleNames = creationRecord.coupleNames;
      RENDER_JOBS.set(jobId, cur);

      if (!isAsync) {
        res.json({
          success: true,
          jobId,
          message: 'Video rendered successfully',
          creationId: creationRecord.id,
          videoUrl: finalVideoUrl,
          downloadPath: outputVideoPath,
          durationSeconds: template.durationSeconds,
          coupleNames: creationRecord.coupleNames
        });
      }
    });

  } catch (err) {
    console.error('Render endpoint error:', err);
    res.status(500).json({ error: 'Server error during render', message: err.message });
  }
});

// GET /api/creations
app.get('/api/creations', async (req, res) => {
  try {
    const { data, error } = await supabaseDb.supabase
      .from('invitation_generations')
      .select('*')
      .eq('status', 'completed')
      .order('created_at', { ascending: false });

    if (!error && data && data.length > 0) {
      return res.json({
        count: data.length,
        creations: data.map(row => ({
          id: row.id,
          userId: row.user_id,
          templateId: row.template_id,
          title: row.title,
          coupleNames: row.couple_names,
          videoUrl: row.output_video_url,
          thumbnailUrl: row.thumbnail_url,
          createdAt: row.created_at
        }))
      });
    }
  } catch (e) {
    console.error('Error fetching creations from Supabase:', e);
  }

  const db = loadDb();
  res.json({
    count: db.creations.length,
    creations: db.creations
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', app: 'My Invitation API', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`My Invitation backend running on http://localhost:${PORT}`);
});
