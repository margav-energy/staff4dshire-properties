const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
// CORS configuration - update with your production URLs
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:8080', 'http://localhost:3000']; // Default for development

const io = new Server(server, {
  cors: {
    origin: process.env.NODE_ENV === 'production' 
      ? allowedOrigins 
      : "*", // Allow all in development
    methods: ["GET", "POST"],
    credentials: true
  }
});

const PORT = process.env.PORT || 3001;

// CORS configuration
const corsOptions = {
  origin: process.env.NODE_ENV === 'production'
    ? allowedOrigins
    : "*", // Allow all in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

app.use(cors(corsOptions));
// Increase body size limit to handle base64 images (50MB limit)
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Routes
app.use('/api/auth', require('./routes/auth')); // Authentication routes
app.use('/api/password-reset', require('./routes/password-reset')); // Password reset routes
app.use('/api/companies', require('./routes/companies'));
app.use('/api/company-invitations', require('./routes/company-invitations'));
app.use('/api/invitation-requests', require('./routes/invitation-requests'));
app.use('/api/users', require('./routes/users'));
app.use('/api/projects', require('./routes/projects'));
app.use('/api/timesheets', require('./routes/timesheets'));
app.use('/api/job-completions', require('./routes/job-completions'));
app.use('/api/invoices', require('./routes/invoices'));
app.use('/api/incidents', require('./routes/incidents'));
app.use('/api/onboarding', require('./routes/onboarding'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/chat', require('./routes/chat'));

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  // Join user to their personal room for direct notifications
  socket.on('join-user-room', (userId) => {
    socket.join(`user-${userId}`);
    console.log(`User ${userId} joined their room`);
  });
  
  // Join conversation room
  socket.on('join-conversation', (conversationId) => {
    socket.join(`conversation-${conversationId}`);
    console.log(`User joined conversation ${conversationId}`);
  });
  
  // Leave conversation room
  socket.on('leave-conversation', (conversationId) => {
    socket.leave(`conversation-${conversationId}`);
    console.log(`User left conversation ${conversationId}`);
  });
  
  // Handle typing indicator
  socket.on('typing', (data) => {
    socket.to(`conversation-${data.conversationId}`).emit('user-typing', {
      userId: data.userId,
      userName: data.userName,
      conversationId: data.conversationId,
    });
  });
  
  // Handle stop typing
  socket.on('stop-typing', (data) => {
    socket.to(`conversation-${data.conversationId}`).emit('user-stopped-typing', {
      userId: data.userId,
      conversationId: data.conversationId,
    });
  });
  
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Make io accessible to routes
app.set('io', io);

// Root route - API information
app.get('/', (req, res) => {
  res.json({
    name: 'Staff4dshire Properties API',
    version: '1.0.0',
    status: 'running',
    message: 'Welcome to Staff4dshire Properties API',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      users: '/api/users',
      companies: '/api/companies',
      projects: '/api/projects',
      timesheets: '/api/timesheets',
      chat: '/api/chat',
      notifications: '/api/notifications',
      jobCompletions: '/api/job-completions',
      invoices: '/api/invoices',
      incidents: '/api/incidents',
    },
    documentation: 'See /api/health for server status',
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Staff4dshire API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
  });
});

// Manual migration endpoint (for troubleshooting)
app.post('/api/admin/migrate', async (req, res) => {
  try {
    const { runSchema } = require('./scripts/auto_migrate');
    console.log('🔄 Manual migration triggered via API');
    const success = await runSchema();
    
    if (success) {
      res.json({ 
        status: 'success', 
        message: 'Database schema migration completed successfully' 
      });
    } else {
      res.status(500).json({ 
        status: 'error', 
        message: 'Migration completed with errors. Check server logs.' 
      });
    }
  } catch (error) {
    console.error('Migration endpoint error:', error);
    res.status(500).json({ 
      status: 'error', 
      message: error.message 
    });
  }
});

// Create superadmin endpoint (for initial setup)
app.post('/api/admin/create-superadmin', async (req, res) => {
  try {
    const pool = require('./db');
    const bcrypt = require('bcrypt');
    const { v4: uuidv4 } = require('uuid');
    
    const { email, password, first_name = 'Super', last_name = 'Admin' } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Email and password are required',
        example: {
          email: 'superadmin@staff4dshire.com',
          password: 'Admin123!',
          first_name: 'Super',
          last_name: 'Admin'
        }
      });
    }
    
    // Check if user already exists
    const existing = await pool.query('SELECT id, email FROM users WHERE email = $1', [email.toLowerCase().trim()]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ 
        error: 'User with this email already exists',
        userId: existing.rows[0].id
      });
    }
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    
    // Check which columns exist
    const columnCheck = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name IN ('company_id', 'is_superadmin')
    `);
    const existingColumns = columnCheck.rows.map(row => row.column_name);
    const hasCompanyId = existingColumns.includes('company_id');
    const hasIsSuperadmin = existingColumns.includes('is_superadmin');
    
    // Build insert query
    const columns = ['id', 'email', 'password_hash', 'first_name', 'last_name', 'role', 'is_active'];
    const values = [userId, email.toLowerCase().trim(), passwordHash, first_name, last_name, 'superadmin', true];
    
    if (hasIsSuperadmin) {
      columns.push('is_superadmin');
      values.push(true);
    }
    
    if (hasCompanyId) {
      columns.push('company_id');
      values.push(null); // Superadmins don't need company_id
    }
    
    const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');
    
    await pool.query(
      `INSERT INTO users (${columns.join(', ')})
       VALUES (${placeholders})
       RETURNING id, email, first_name, last_name, role`,
      values
    );
    
    console.log(`✅ Superadmin created: ${email}`);
    
    res.json({
      success: true,
      message: 'Superadmin created successfully',
      user: {
        email: email.toLowerCase().trim(),
        first_name,
        last_name,
        role: 'superadmin'
      },
      note: 'You can now log in with these credentials'
    });
  } catch (error) {
    console.error('Create superadmin error:', error);
    res.status(500).json({ 
      error: 'Failed to create superadmin',
      message: error.message 
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

// Auto-migration: Run schema if tables don't exist
const { runSchema } = require('./scripts/auto_migrate');

// Retry migration with exponential backoff
async function runMigrationWithRetry(maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    const delay = Math.pow(2, i) * 2000; // 2s, 4s, 8s
    await new Promise(resolve => setTimeout(resolve, delay));
    
    console.log(`🔄 Attempting database migration (attempt ${i + 1}/${maxRetries})...`);
    const success = await runSchema();
    
    if (success) {
      // After schema is ready, run seeding if enabled
      if (process.env.SEED_DATABASE === 'true') {
        const { seedDatabase } = require('./scripts/seed_default_data');
        setTimeout(() => {
          seedDatabase().catch(err => {
            console.error('Database seeding failed:', err);
          });
        }, 1000); // Wait 1 second after schema
      }
      return;
    }
    
    if (i < maxRetries - 1) {
      console.log(`⏳ Migration failed, retrying in ${delay/1000} seconds...`);
    }
  }
  
  console.error('❌ Migration failed after all retries. Manual intervention required.');
  console.log('💡 To fix: Run the schema manually using Render database connection tools.');
}

// Start migration after server starts
setTimeout(() => {
  runMigrationWithRetry().catch(err => {
    console.error('Migration retry failed:', err);
  });
}, 5000); // Wait 5 seconds for database connection to be ready

server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
  console.log(`Socket.io server ready for connections`);
  
  if (process.env.SEED_DATABASE === 'true') {
    console.log(`Database seeding enabled - will run automatically`);
  }
});

