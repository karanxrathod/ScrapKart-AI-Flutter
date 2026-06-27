const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/booking.controller');

router.post('/assign-collector', bookingController.assignCollector);

router.post('/otp/generate', bookingController.generateOtp);
router.post('/otp/verify', bookingController.verifyOtp);

router.get('/optimize-route', bookingController.optimizeRoute);

module.exports = router;
