const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Donation = sequelize.define('Donation', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    userId: {
        type: DataTypes.STRING,
        allowNull: false
    },
    scrapType: {
        type: DataTypes.STRING,
        allowNull: false
    },
    weightKg: {
        type: DataTypes.FLOAT,
        allowNull: false
    },
    ecoCoinsEarned: {
        type: DataTypes.INTEGER,
        defaultValue: 0
    },
    co2SavedKg: {
        type: DataTypes.FLOAT,
        defaultValue: 0.0
    },
    ngoName: {
        type: DataTypes.STRING,
        allowNull: true
    }
}, {
    timestamps: true,
    tableName: 'donations'
});

module.exports = Donation;
