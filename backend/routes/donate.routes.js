const express = require('express');
const router = express.Router();
const donateController = require('../controllers/donate.controller');
const { verifyToken } = require('../middlewares/auth.middleware');
const { validate } = require('../middlewares/validate.middleware');
const { z } = require('zod');

// Validation schema for creating a donation
const createDonationSchema = z.object({
    body: z.object({
        scrapType: z.string().min(1, "Scrap type is required"),
        weightKg: z.number().positive("Weight must be greater than 0"),
        ngoName: z.string().optional()
    })
});

// Protected routes
router.use(verifyToken);

router.post('/', validate(createDonationSchema), donateController.createDonation);
router.get('/', donateController.getUserDonations);

module.exports = router;
