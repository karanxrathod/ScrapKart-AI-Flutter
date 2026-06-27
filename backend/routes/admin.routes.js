const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');

router.get('/metrics', adminController.getMetrics);

module.exports = router;
