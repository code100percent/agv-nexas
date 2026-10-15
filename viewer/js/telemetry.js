/**
 * AGV Nexus - Authenticated WebSocket Telemetry Client & Interpolation Queue
 */

import { CONFIG } from './config.js';

export class TelemetryClient {
  constructor(options = {}) {
    this.robotId = options.robotId || CONFIG.DEFAULT_ROBOT_ID;
    this.token = options.token || null;
    this.wsUrl = options.wsUrl || CONFIG.WS_URL;
    this.onTelemetry = options.onTelemetry || (() => {});
    this.onConnectionStatus = options.onConnectionStatus || (() => {});

    this.socket = null;
    this.reconnectTimer = null;
    this.reconnectAttempts = 0;
    this.isManualClosed = false;

    this.lastReceivedTime = 0;
    this.stalenessCheckTimer = null;
    this.currentStatus = 'disconnected'; // 'connected' | 'stale' | 'disconnected'
  }

  connect() {
    this.isManualClosed = false;

    let targetUrl = `${this.wsUrl}?robot_id=${encodeURIComponent(this.robotId)}`;
    if (this.token) {
      targetUrl += `&token=${encodeURIComponent(this.token)}`;
    }

    try {
      this.socket = new WebSocket(targetUrl);
    } catch (e) {
      console.warn('[TelemetryClient] WebSocket initialization error:', e);
      this._scheduleReconnect();
      return;
    }

    this.socket.onopen = () => {
      console.info(`[TelemetryClient] Connected to gateway for robot ${this.robotId}`);
      this.reconnectAttempts = 0;
      this._setStatus('connected');

      // Send initial subscribe action
      this.send({ action: 'subscribe', robot_id: this.robotId });

      // Start ping heartbeat
      this.pingInterval = setInterval(() => {
        if (this.socket && this.socket.readyState === WebSocket.OPEN) {
          this.send({ action: 'ping' });
        }
      }, 5000);

      this._startStalenessWatcher();
    };

    this.socket.onmessage = (event) => {
      this.lastReceivedTime = Date.now();
      try {
        const envelope = JSON.parse(event.data);
        if (envelope.event === 'robot.telemetry' && envelope.payload) {
          this._setStatus(envelope.payload.data_freshness === 'stale' ? 'stale' : 'connected');
          this.onTelemetry(envelope.payload);
        }
      } catch (err) {
        console.warn('[TelemetryClient] Failed to parse message JSON:', err);
      }
    };

    this.socket.onerror = (err) => {
      console.warn('[TelemetryClient] WebSocket error event:', err);
    };

    this.socket.onclose = () => {
      this._setStatus('disconnected');
      if (this.pingInterval) clearInterval(this.pingInterval);
      if (!this.isManualClosed) {
        this._scheduleReconnect();
      }
    };
  }

  send(data) {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify(data));
    }
  }

  _setStatus(newStatus) {
    if (this.currentStatus !== newStatus) {
      this.currentStatus = newStatus;
      this.onConnectionStatus(newStatus);
    }
  }

  _startStalenessWatcher() {
    if (this.stalenessCheckTimer) clearInterval(this.stalenessCheckTimer);
    this.stalenessCheckTimer = setInterval(() => {
      const elapsed = Date.now() - this.lastReceivedTime;
      if (this.currentStatus === 'connected' && elapsed > CONFIG.TELEMETRY.STALENESS_THRESHOLD_MS) {
        this._setStatus('stale');
      }
    }, 1000);
  }

  _scheduleReconnect() {
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    const delay = Math.min(1000 * Math.pow(1.5, this.reconnectAttempts), 8000);
    this.reconnectAttempts++;
    console.info(`[TelemetryClient] Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})...`);
    this.reconnectTimer = setTimeout(() => this.connect(), delay);
  }

  disconnect() {
    this.isManualClosed = true;
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    if (this.stalenessCheckTimer) clearInterval(this.stalenessCheckTimer);
    if (this.pingInterval) clearInterval(this.pingInterval);
    if (this.socket) {
      this.socket.close();
      this.socket = null;
    }
    this._setStatus('disconnected');
  }
}
