const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Booking = sequelize.define('Booking', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    userId: {
        type: DataTypes.STRING,
        allowNull: false
    },
    collectorId: {
        type: DataTypes.STRING,
        allowNull: true
    },
    status: {
        type: DataTypes.ENUM('Pending', 'Assigned', 'InProgress', 'Completed', 'Cancelled'),
        defaultValue: 'Pending'
    },
    otp: {
        type: DataTypes.STRING,
        allowNull: true
    },
    isOtpVerified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
    }
}, {
    timestamps: true,
    tableName: 'bookings'
});

module.exports = Booking;
