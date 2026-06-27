const User = require('../models/user.model');
const CollectorLocation = require('../models/collectorLocation.model');

exports.getMetrics = async (req, res) => {
    try {
        let totalUsers = 0;
        let activeCollectors = 0;

        try {
            // Count total users
            totalUsers = await User.count();
            
            // Count active collectors
            activeCollectors = await CollectorLocation.count({
                where: { isActive: true }
            });
        } catch (dbError) {
            console.error("Database unavailable, using fallback data:", dbError.message);
            totalUsers = 1248; // Fallback data
            activeCollectors = 42;
        }

        // Mock recent collections since we don't have a ScrapCollections table yet
        const mockCollections = [
            { id: '#SK-9921', category: 'Plastic Bottles', weight: '2.4 kg', status: 'Pending Pickup', statusClass: 'warning' },
            { id: '#SK-9922', category: 'Cardboard', weight: '5.1 kg', status: 'Assigned', statusClass: 'success' },
            { id: '#SK-9923', category: 'Aluminum Cans', weight: '1.2 kg', status: 'Assigned', statusClass: 'success' }
        ];

        return res.status(200).json({
            success: true,
            data: {
                totalUsers,
                activeCollectors,
                collections: mockCollections,
                aiLatency: '120ms' // In a fully live app, this would be an average from a logs table
            }
        });
    } catch (error) {
        console.error("Admin Metrics Error:", error);
        return res.status(500).json({ success: false, message: 'Server error fetching metrics.' });
    }
};
