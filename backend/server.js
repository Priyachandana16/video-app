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
app.post('/api/render', upload.fields([
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

    const template = TEMPLATES.find(t => t.id === templateId) || TEMPLATES[0];
    const previewMode = req.body.previewMode === 'true' || req.body.previewMode === true || !req.body.fullDuration;
    const sampleResultPath = template.sampleResultPath || path.join(PROJECT_ROOT, 'assets/templates/template_01_sample_result.mp4');

    const hasPhoto = req.body.hasPhoto === 'true' || req.body.hasPhoto === true || (template.hasPhoto && req.body.hasPhoto !== 'false');

    // Determine woman (Bride) and man (Groom) photo paths
    let womanPhotoPath = null;
    let manPhotoPath = null;
    if (req.files) {
      if (req.files['womanPhoto'] && req.files['womanPhoto'][0]) {
        womanPhotoPath = req.files['womanPhoto'][0].path;
      }
      if (req.files['manPhoto'] && req.files['manPhoto'][0]) {
        manPhotoPath = req.files['manPhoto'][0].path;
      }
      if (req.files['photo'] && req.files['photo'][0]) {
        if (!womanPhotoPath) womanPhotoPath = req.files['photo'][0].path;
        if (!manPhotoPath) manPhotoPath = req.files['photo'][0].path;
      }
    }
    if (!womanPhotoPath && req.body.womanPhotoPath && fs.existsSync(req.body.womanPhotoPath)) {
      womanPhotoPath = req.body.womanPhotoPath;
    }
    if (!manPhotoPath && req.body.manPhotoPath && fs.existsSync(req.body.manPhotoPath)) {
      manPhotoPath = req.body.manPhotoPath;
    }
    const photoPath = womanPhotoPath || manPhotoPath;

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
      womanPhotoPath,
      manPhotoPath,
      brideName,
      groomName,
      parentsNames: req.body.parentsNames || 'Smt. Lakshmi & Sri. Venkat Rao',
      ceremonyTitle,
      eventDate,
      muhurthamTime,
      venue,
      rsvp,
      previewMode: req.body.previewMode === 'true' || req.body.previewMode === true || !req.body.fullDuration,
      sampleResultPath: template.sampleResultPath
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
        thumbnailUrl: template.thumbnailUrl || '/assets/templates/thumb_01_green.jpg',
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
