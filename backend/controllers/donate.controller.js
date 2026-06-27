const Donation = require('../models/donation.model');

// Create a new donation
const createDonation = async (req, res) => {
    try {
        const { scrapType, weightKg, ngoName } = req.body;
        
        // Simple logic for eco-coins and CO2 saved based on weight
        const ecoCoinsEarned = Math.floor(weightKg * 10); // 10 coins per kg
        const co2SavedKg = weightKg * 1.5; // Example: 1.5 kg CO2 saved per kg of scrap

        const donation = await Donation.create({
            userId: req.userId,
            scrapType,
            weightKg,
            ecoCoinsEarned,
            co2SavedKg,
            ngoName
        });

        res.status(201).json({
            message: "Donation successful!",
            donation
        });
    } catch (error) {
        res.status(500).json({ message: "Error creating donation", error: error.message });
    }
};

// Get user donations and impact stats
const getUserDonations = async (req, res) => {
    try {
        const donations = await Donation.findAll({ where: { userId: req.userId } });
        
        let totalCoins = 0;
        let totalCO2 = 0;
        donations.forEach(d => {
            totalCoins += d.ecoCoinsEarned;
            totalCO2 += d.co2SavedKg;
        });

        res.status(200).json({
            donations,
            stats: {
                totalCoins,
                totalCO2
            }
        });
    } catch (error) {
        res.status(500).json({ message: "Error fetching donations", error: error.message });
    }
};

module.exports = {
    createDonation,
    getUserDonations
};
