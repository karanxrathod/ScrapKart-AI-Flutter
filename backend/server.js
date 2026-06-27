const express = require('express');
const cors = require('cors');
const sequelize = require('./config/database');
const authRoutes = require('./routes/auth.routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Routes
app.use('/api/auth', authRoutes);
const scrapRoutes = require('./routes/scrap.routes');
app.use('/api/scrap', scrapRoutes);
const bookingRoutes = require('./routes/booking.routes');
app.use('/api/booking', bookingRoutes);
const chatRoutes = require('./routes/chat.routes');
app.use('/api/chat', chatRoutes);
const donateRoutes = require('./routes/donate.routes');
app.use('/api/donate', donateRoutes);

// Database Sync & Server Initialization
sequelize.sync({ alter: true }) // Adjust in production: alter/force should be used with caution
    .then(() => {
        console.log('✅ MySQL Database connected & synced.');
    })
    .catch((err) => {
        console.error('❌ Failed to connect database (App will run without DB):', err.message);
    });

const http = require('http');
const { Server } = require('socket.io');

const server = http.createServer(app);
const io = new Server(server, {
    cors: { origin: '*' }
});

io.on('connection', (socket) => {
    console.log('🔗 Client connected to Socket:', socket.id);
    
    // Join a room for a specific booking
    socket.on('join_booking', (bookingId) => {
        socket.join(bookingId);
        console.log(`User joined room: ${bookingId}`);
    });

    // Collector sends location updates
    socket.on('collector_location', (data) => {
        const { bookingId, lat, lng } = data;
        io.to(bookingId).emit('location_update', { lat, lng });
    });

    socket.on('disconnect', () => {
        console.log('❌ Client disconnected:', socket.id);
    });
});

server.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    
    // Initialize CRON jobs
    const pricingService = require('./services/pricing.service');
    pricingService.init();
});
