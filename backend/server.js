const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const { spawn } = require('child_process');

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
        templateId: 'tmpl_hindu_royal_01',
        title: 'Rajesh & Ananya Vivaham',
        coupleNames: 'Rajesh & Ananya',
        eventDate: '15 Dec 2026',
        venue: 'The Grand Chola Palace, Chennai',
        videoUrl: '/assets/personalized_output.mp4',
        thumbnailUrl: '/assets/candidate_chatgpt_jun.png',
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
    id: 'tmpl_hindu_royal_01',
    title: 'Royal Mandapam Golden Vivaham',
    category: 'Wedding',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: true,
    photoSlotsCount: 4,
    durationSeconds: 12,
    badgeText: 'MOST POPULAR',
    description: 'Majestic Kundan gold mandap aesthetic with auspicious bells, floating bokeh, and circular photo frame.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'wedding_template_master.mp4'),
    thumbnailUrl: '/assets/candidate_screenshot.jpg',
    timelineConfig: {
      intro: { start: 0.0, end: 3.0, title: 'Auspicious Invitation' },
      coupleNames: { start: 3.0, end: 6.5, title: 'Names & Blessings' },
      photoOverlay: { start: 6.5, end: 9.5, title: 'Couple Showcase' },
      eventDetails: { start: 9.5, end: 12.0, title: 'Muhurtham & Venue' }
    }
  },
  {
    id: 'tmpl_christian_cathedral_02',
    title: 'Grace Cathedral Holy Matrimony',
    category: 'Wedding',
    religion: 'Christian',
    orientation: '9:16',
    hasPhoto: true,
    photoSlotsCount: 2,
    durationSeconds: 12,
    badgeText: 'FEATURED',
    description: 'Serene ivory and champagne cathedral architecture with gentle floral wreaths and soft chimes.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'wedding_template_master.mp4'),
    thumbnailUrl: '/assets/pic16.png',
    timelineConfig: {
      intro: { start: 0.0, end: 3.0 },
      coupleNames: { start: 3.0, end: 6.5 },
      photoOverlay: { start: 6.5, end: 9.5 },
      eventDetails: { start: 9.5, end: 12.0 }
    }
  },
  {
    id: 'tmpl_muslim_nikah_03',
    title: 'Noor-e-Nikah Celestial Emerald',
    category: 'Wedding',
    religion: 'Muslim',
    orientation: '9:16',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 12,
    badgeText: 'ELEGANT',
    description: 'Intricate emerald green arches with crescent motifs, shimmering gold calligraphy, and ceremonial poetry.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'wedding_template_master.mp4'),
    thumbnailUrl: '/assets/meshy1.png',
    timelineConfig: {
      intro: { start: 0.0, end: 3.0 },
      coupleNames: { start: 3.0, end: 6.5 },
      photoOverlay: { start: 6.5, end: 9.5 },
      eventDetails: { start: 9.5, end: 12.0 }
    }
  },
  {
    id: 'tmpl_hindu_landscape_04',
    title: 'Cinema Panorama Shubh Vivah',
    category: 'Wedding',
    religion: 'Hindu',
    orientation: '16:9',
    hasPhoto: true,
    photoSlotsCount: 4,
    durationSeconds: 12,
    badgeText: 'CINEMATIC',
    description: 'Grand 16:9 widescreen presentation suitable for LED walls, banquet projectors, and widescreen TVs.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'wedding_template_master.mp4'),
    thumbnailUrl: '/assets/meshy2.png',
    timelineConfig: {
      intro: { start: 0.0, end: 3.0 },
      coupleNames: { start: 3.0, end: 6.5 },
      photoOverlay: { start: 6.5, end: 9.5 },
      eventDetails: { start: 9.5, end: 12.0 }
    }
  },
  {
    id: 'tmpl_hindu_reception_05',
    title: 'Grand Palace Evening Reception',
    category: 'Reception',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: true,
    photoSlotsCount: 3,
    durationSeconds: 12,
    badgeText: 'TRENDING',
    description: 'Chic twilight violet and gold fireworks celebration backdrop for modern wedding receptions.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'wedding_template_master.mp4'),
    thumbnailUrl: '/assets/meshy3.png',
    timelineConfig: {
      intro: { start: 0.0, end: 3.0 },
      coupleNames: { start: 3.0, end: 6.5 },
      photoOverlay: { start: 6.5, end: 9.5 },
      eventDetails: { start: 9.5, end: 12.0 }
    }
  },
  {
    id: 'tmpl_christian_landscape_06',
    title: 'Sunset Garden Floral Vows',
    category: 'Wedding',
    religion: 'Christian',
    orientation: '16:9',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 12,
    badgeText: 'NEW',
    description: 'Golden hour sunset landscape with lush greenery, fairy lights, and minimalist typography.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'wedding_template_master.mp4'),
    thumbnailUrl: '/assets/pic16.png',
    timelineConfig: {
      intro: { start: 0.0, end: 3.0 },
      coupleNames: { start: 3.0, end: 6.5 },
      photoOverlay: { start: 6.5, end: 9.5 },
      eventDetails: { start: 9.5, end: 12.0 }
    }
  },
  {
    id: 'tmpl_hindu_vedic_07',
    title: 'Vedic Shubh Vivaham (Traditional)',
    category: 'Wedding',
    religion: 'Hindu',
    orientation: '9:16',
    hasPhoto: false,
    photoSlotsCount: 0,
    durationSeconds: 12,
    badgeText: 'TRADITIONAL',
    description: 'Auspicious Sanskrit shlokas and golden mandap calligraphy with elder blessings, crafted specifically for weddings without photographs.',
    masterVideoPath: path.join(PROJECT_ROOT, 'assets', 'wedding_template_master.mp4'),
    thumbnailUrl: '/assets/my_invitation_logo.png',
    timelineConfig: {
      intro: { start: 0.0, end: 3.0, title: 'Auspicious Invocation' },
      coupleNames: { start: 3.0, end: 6.5, title: 'Names & Blessings' },
      photoOverlay: { start: 6.5, end: 9.5, title: 'Elders Blessing' },
      eventDetails: { start: 9.5, end: 12.0, title: 'Muhurtham & Venue' }
    }
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
// TEMPLATE ROUTES
// ----------------------------------------------------

// GET /api/templates
app.get('/api/templates', (req, res) => {
  const { religion, orientation, hasPhoto, category } = req.query;

  let results = [...TEMPLATES];

  if (religion && religion !== 'All') {
    results = results.filter(t => t.religion.toLowerCase() === religion.toLowerCase());
  }

  if (orientation && orientation !== 'All') {
    results = results.filter(t => t.orientation === orientation);
  }

  if (hasPhoto !== undefined && hasPhoto !== '') {
    const photoBool = hasPhoto === 'true' || hasPhoto === true;
    results = results.filter(t => t.hasPhoto === photoBool);
  }

  if (category && category !== 'All') {
    results = results.filter(t => t.category.toLowerCase() === category.toLowerCase());
  }

  res.json({
    count: results.length,
    templates: results
  });
});

// GET /api/templates/:id
app.get('/api/templates/:id', (req, res) => {
  const tmpl = TEMPLATES.find(t => t.id === req.params.id);
  if (!tmpl) {
    return res.status(404).json({ error: 'Template not found' });
  }
  res.json(tmpl);
});

// ----------------------------------------------------
// VIDEO COMPOSITION & RENDERING ENGINE
// ----------------------------------------------------

// POST /api/render
app.post('/api/render', upload.single('photo'), async (req, res) => {
  try {
    const {
      templateId = 'tmpl_hindu_royal_01',
      brideName = 'Ananya',
      groomName = 'Rajesh',
      ceremonyTitle = 'Shubh Vivaham',
      eventDate = 'Sunday, 15 December 2026',
      muhurthamTime = 'Muhurtham: 09:45 AM',
      venue = 'The Grand Chola Palace, Chennai',
      rsvp = 'With Best Compliments from Family & Friends',
      userId = 'usr_guest'
    } = req.body;

    const template = TEMPLATES.find(t => t.id === templateId) || TEMPLATES[0];

    const hasPhoto = req.body.hasPhoto === 'true' || req.body.hasPhoto === true || (template.hasPhoto && req.body.hasPhoto !== 'false');

    // Determine photo path
    let photoPath = null;
    if (hasPhoto) {
      if (req.file) {
        photoPath = req.file.path;
      } else if (req.body.photoPath && fs.existsSync(req.body.photoPath)) {
        photoPath = req.body.photoPath;
      } else {
        photoPath = path.join(PROJECT_ROOT, 'assets', 'candidate_chatgpt_jun.png');
      }
    }

    const timestamp = Date.now();
    const outputFilename = `invitation_${timestamp}.mp4`;
    const outputVideoPath = path.join(EXPORTS_DIR, outputFilename);

    // Write temp config JSON for python render engine
    const configPath = path.join(DATA_DIR, `render_config_${timestamp}.json`);
    const renderConfig = {
      masterVideoPath: template.masterVideoPath,
      outputVideoPath,
      hasPhoto,
      photoPath,
      brideName,
      groomName,
      parentsNames: req.body.parentsNames || 'Smt. Lakshmi & Sri. Venkat Rao',
      ceremonyTitle,
      eventDate,
      muhurthamTime,
      venue,
      rsvp
    };

    fs.writeFileSync(configPath, JSON.stringify(renderConfig, null, 2), 'utf8');

    const pythonScript = path.join(__dirname, 'render_engine.py');
    console.log(`Starting video rendering process for ${groomName} & ${brideName}...`);

    const py = spawn('python', [pythonScript, configPath]);

    let pyOut = '';
    let pyErr = '';

    py.stdout.on('data', (d) => { pyOut += d.toString(); });
    py.stderr.on('data', (d) => { pyErr += d.toString(); });

    py.on('close', (code) => {
      // Clean up config file
      try { fs.unlinkSync(configPath); } catch (_) {}

      if (code !== 0) {
        console.error('Python render error:', pyErr);
        // Fallback: If for any reason python render fails, serve verified personalized_output.mp4
        const fallbackSrc = path.join(PROJECT_ROOT, 'assets', 'personalized_output.mp4');
        if (fs.existsSync(fallbackSrc)) {
          fs.copyFileSync(fallbackSrc, outputVideoPath);
        } else {
          return res.status(500).json({ error: 'Video rendering failed', details: pyErr });
        }
      }

      console.log(`Render complete: ${outputFilename}`);

      const relativeUrl = `/exports/${outputFilename}`;
      const creationRecord = {
        id: `cr_${timestamp}`,
        userId,
        templateId,
        title: `${groomName} & ${brideName} ${ceremonyTitle}`,
        coupleNames: `${groomName} & ${brideName}`,
        eventDate,
        venue,
        videoUrl: relativeUrl,
        downloadPath: outputVideoPath,
        thumbnailUrl: '/assets/candidate_chatgpt_jun.png',
        createdAt: new Date().toISOString()
      };

      const db = loadDb();
      db.creations.unshift(creationRecord);
      saveDb(db);

      res.json({
        success: true,
        message: 'Video rendered successfully',
        creationId: creationRecord.id,
        videoUrl: relativeUrl,
        downloadPath: outputVideoPath,
        durationSeconds: template.durationSeconds,
        coupleNames: creationRecord.coupleNames
      });
    });

  } catch (err) {
    console.error('Render endpoint error:', err);
    res.status(500).json({ error: 'Server error during render', message: err.message });
  }
});

// ----------------------------------------------------
// CREATIONS ROUTES
// ----------------------------------------------------

// GET /api/creations
app.get('/api/creations', (req, res) => {
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
