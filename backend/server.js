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

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

// Database seeding (runs automatically if SEED_DATABASE=true)
if (process.env.SEED_DATABASE === 'true') {
  const { seedDatabase } = require('./scripts/seed_default_data');
  // Run seeding asynchronously after server starts
  setTimeout(() => {
    seedDatabase().catch(err => {
      console.error('Database seeding failed:', err);
    });
  }, 2000); // Wait 2 seconds for database connection to be ready
}

server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
  console.log(`Socket.io server ready for connections`);
  
  if (process.env.SEED_DATABASE === 'true') {
    console.log(`Database seeding enabled - will run automatically`);
  }
});

