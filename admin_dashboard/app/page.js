'use client';
import React, { useState, useEffect } from 'react';
import './globals.css';

export default function AdminDashboard() {
  const [metrics, setMetrics] = useState({
    totalUsers: 0,
    activeCollectors: 0,
    collections: [],
    aiLatency: '120ms'
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Fetch live data from Node.js backend
    fetch('http://localhost:5000/api/admin/metrics')
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setMetrics(data.data);
        }
        setLoading(false);
      })
      .catch(err => {
        console.error("Failed to fetch backend metrics:", err);
        setLoading(false);
      });
  }, []);

  return (
    <div className="dashboard-container">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="brand">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M3 3v18h18" />
            <path d="m19 9-5 5-4-4-3 3" />
          </svg>
          ScrapKart Admin
        </div>
        
        <nav style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          <div className="nav-item active">
            <span>📊</span> Overview
          </div>
          <div className="nav-item">
            <span>♻️</span> Live Collections
          </div>
          <div className="nav-item">
            <span>🚚</span> Active Collectors
          </div>
          <div className="nav-item">
            <span>⚙️</span> AI Metrics
          </div>
        </nav>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        <header className="header">
          <h1>Dashboard Overview</h1>
          <div className="badge success" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span className="pulse"></span> {loading ? 'Connecting...' : 'Live Data'}
          </div>
        </header>

        {/* Key Metrics */}
        <div className="metrics-grid">
          <div className="glass-panel metric-card">
            <span className="metric-title">Total Registered Users</span>
            <span className="metric-value">{loading ? '...' : metrics.totalUsers}</span>
            <span className="metric-trend">Total accounts across platform</span>
          </div>
          <div className="glass-panel metric-card">
            <span className="metric-title">Active Collectors</span>
            <span className="metric-value">{loading ? '...' : metrics.activeCollectors}</span>
            <span className="metric-trend">On route right now</span>
          </div>
          <div className="glass-panel metric-card">
            <span className="metric-title">AI Processing Latency</span>
            <span className="metric-value">{loading ? '...' : metrics.aiLatency}</span>
            <span className="metric-trend" style={{ color: '#3b82f6' }}>↓ 75% optimized</span>
          </div>
        </div>

        {/* Main Body */}
        <div className="dashboard-body">
          {/* Live Table */}
          <div className="glass-panel">
            <h2 className="panel-header">Live Scrap Collections</h2>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Request ID</th>
                  <th>Category (AI)</th>
                  <th>Est. Volume</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="4" style={{textAlign: 'center'}}>Loading collections...</td></tr>
                ) : metrics.collections && metrics.collections.length > 0 ? (
                  metrics.collections.map(col => (
                    <tr key={col.id}>
                      <td>{col.id}</td>
                      <td>{col.category}</td>
                      <td>{col.weight}</td>
                      <td><span className={`badge ${col.statusClass}`}>{col.status}</span></td>
                    </tr>
                  ))
                ) : (
                  <tr><td colSpan="4" style={{textAlign: 'center'}}>No collections found.</td></tr>
                )}
              </tbody>
            </table>
          </div>

          {/* AI Metrics Chart Placeholder */}
          <div className="glass-panel">
            <h2 className="panel-header">AI Latency (ms)</h2>
            <div className="chart-placeholder">
              <div className="chart-bar" style={{ height: '20%' }}></div>
              <div className="chart-bar" style={{ height: '40%' }}></div>
              <div className="chart-bar" style={{ height: '30%' }}></div>
              <div className="chart-bar" style={{ height: '70%' }}></div>
              <div className="chart-bar" style={{ height: '50%' }}></div>
              <div className="chart-bar" style={{ height: '90%' }}></div>
              <div className="chart-bar" style={{ height: '10%' }}></div>
            </div>
            <p style={{ textAlign: 'center', marginTop: '1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
              Real-time inference times
            </p>
          </div>
        </div>
      </main>
    </div>
  );
}
