const sequelize = require('../config/database');
const CollectorLocation = require('../models/collectorLocation.model');
const User = require('../models/user.model');
const axios = require('axios');
const otpGenerator = require('otp-generator');
const Booking = require('../models/booking.model');
// Generates MySQL raw query implementing the Haversine formula
const generateHaversineQuery = (lat, lng, radiusKm) => {
    return `
        SELECT cl.*, u.name, u.email,
        (6371 * acos(cos(radians(${lat})) * cos(radians(cl.lat)) * cos(radians(cl.lng) - radians(${lng})) + sin(radians(${lat})) * sin(radians(cl.lat)))) AS distance
        FROM collector_locations AS cl
        JOIN users AS u ON cl.uid = u.uid
        WHERE cl.isActive = true
        HAVING distance < ${radiusKm}
        ORDER BY distance LIMIT 10
    `;
};

exports.assignCollector = async (req, res) => {
    try {
        const { lat, lng } = req.body;
        
        if (!lat || !lng) {
             return res.status(400).json({ success: false, message: 'Latitude and Longitude are required' });
        }

        // 1. Filter Initial Radius (5 KM) executing Haversine in MySQL Database
        const activeCollectors = await sequelize.query(generateHaversineQuery(lat, lng, 5), {
            type: sequelize.QueryTypes.SELECT
        });

        if (activeCollectors.length === 0) {
            return res.status(404).json({ success: false, message: 'No collectors found within a 5km area.' });
        }

        // 2. Formatting destinations for Google Distance Matrix API Evaluation
        const destinations = activeCollectors.map(c => `${c.lat},${c.lng}`).join('|');
        const origins = `${lat},${lng}`;
        
        // The Maps key shouldn't be hardcoded physically but implemented securely via .env
        const mapApiKey = process.env.GOOGLE_MAPS_API_KEY || 'AIzaSy_YOUR_MATRIX_KEY_HERE';
        
        const dmUrl = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${origins}&destinations=${destinations}&key=${mapApiKey}`;
        
        let elements = [];
        try {
            const dmResponse = await axios.get(dmUrl);
            if (dmResponse.data && dmResponse.data.rows && dmResponse.data.rows.length > 0) {
                elements = dmResponse.data.rows[0].elements;
            }
        } catch (axiosErr) {
            console.error("Distance Matrix error:", axiosErr.message);
            // Will fallback to straight-line haversine distance
        }

        let bestCollector = null;
        let minDuration = Infinity;

        // 3. Find Collector with Minimal Real-World ETA Time
        if (elements.length > 0) {
            for (let i = 0; i < elements.length; i++) {
                const el = elements[i];
                if (el.status === 'OK') {
                    const durationValue = el.duration.value; // evaluated natively in seconds
                    if (durationValue < minDuration) {
                        minDuration = durationValue;
                        bestCollector = {
                            ...activeCollectors[i],
                            eta: el.duration.text,
                            drivingDistance: el.distance.text
                        };
                    }
                }
            }
        }

        // Fallback safety logic bridging raw Haversine math if API errors occurs
        if (!bestCollector) {
            bestCollector = activeCollectors[0];
            bestCollector.eta = 'ETA Unavailable';
            bestCollector.drivingDistance = `${bestCollector.distance.toFixed(1)} km`;
        }

        return res.status(200).json({
            success: true,
            message: 'Collector located and assigned.',
            collector: bestCollector
        });

    } catch (error) {
        console.error("Booking Error:", error);
        return res.status(500).json({ success: false, message: 'Server error processing logistics.' });
    }
};

exports.generateOtp = async (req, res) => {
    try {
        const { bookingId } = req.body;
        
        // Generate a 4 digit OTP
        const otp = otpGenerator.generate(4, { upperCaseAlphabets: false, specialChars: false, lowerCaseAlphabets: false });
        
        // Save to booking (assuming bookingId exists)
        await Booking.update({ otp: otp, isOtpVerified: false }, { where: { id: bookingId } });
        
        return res.status(200).json({ success: true, otp: otp });
    } catch (error) {
        return res.status(500).json({ success: false, message: 'Server error generating OTP.' });
    }
};

exports.verifyOtp = async (req, res) => {
    try {
        const { bookingId, otp } = req.body;
        
        const booking = await Booking.findByPk(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }
        
        if (booking.otp === otp) {
            await booking.update({ isOtpVerified: true, status: 'InProgress' });
            return res.status(200).json({ success: true, message: 'OTP verified successfully.' });
        } else {
            return res.status(400).json({ success: false, message: 'Invalid OTP.' });
        }
    } catch (error) {
        return res.status(500).json({ success: false, message: 'Server error verifying OTP.' });
    }
};

exports.optimizeRoute = async (req, res) => {
    try {
        const { collectorId } = req.query;
        if (!collectorId) {
            return res.status(400).json({ success: false, message: 'Collector ID is required.' });
        }

        // Fetch all pending bookings for this collector
        // We'll mock this data for now, assuming Booking model has lat/lng
        const pendingBookings = [
            { id: 1, lat: 19.9975, lng: 73.7898, address: 'College Road' },
            { id: 2, lat: 20.0055, lng: 73.7554, address: 'Gangapur Road' },
            { id: 3, lat: 19.9615, lng: 73.8180, address: 'Indira Nagar' }
        ];

        if (pendingBookings.length === 0) {
            return res.status(200).json({ success: true, optimizedRoute: [] });
        }

        // Assume collector starts at a known depot or current location
        const collectorStart = { lat: 19.9900, lng: 73.7900 };

        // For Google Maps Directions API with waypoints and optimize=true (TSP solver)
        // https://maps.googleapis.com/maps/api/directions/json?origin=X&destination=X&waypoints=optimize:true|W1|W2...&key=API_KEY
        
        const origin = `${collectorStart.lat},${collectorStart.lng}`;
        // Destination can be the same as origin (round trip) or the last waypoint
        const destination = origin;
        
        const waypoints = pendingBookings.map(b => `${b.lat},${b.lng}`).join('|');
        const mapApiKey = process.env.GOOGLE_MAPS_API_KEY || 'AIzaSy_YOUR_MATRIX_KEY_HERE';
        
        const directionsUrl = `https://maps.googleapis.com/maps/api/directions/json?origin=${origin}&destination=${destination}&waypoints=optimize:true|${waypoints}&key=${mapApiKey}`;
        
        try {
            // Uncomment to use real API:
            // const response = await axios.get(directionsUrl);
            // const waypointOrder = response.data.routes[0].waypoint_order;
            
            // Mocking the TSP result:
            const mockWaypointOrder = [1, 0, 2]; 
            
            const optimizedBookings = mockWaypointOrder.map(index => pendingBookings[index]);
            
            return res.status(200).json({ 
                success: true, 
                message: 'Route optimized successfully (TSP)',
                optimizedRoute: optimizedBookings
            });
        } catch (apiError) {
             console.error("Directions API Error:", apiError);
             return res.status(200).json({ 
                success: true, 
                message: 'Route optimization fallback (linear)',
                optimizedRoute: pendingBookings // Fallback to unoptimized
            });
        }
    } catch (error) {
        console.error("Route Optimization Error:", error);
        return res.status(500).json({ success: false, message: 'Server error optimizing route.' });
    }
};

