// WebSocket Service for Real-time Features
// Connects to backend WS manager for: alerts, tracking, trip updates, notifications

import { useAppStore } from '@/store/appStore';
import { useAuthStore } from '@/store/authStore';
import type { Alert, Notification } from '@/types';

type WSMessageType =
  | 'alert'
  | 'notification'
  | 'vehicle_tracking'
  | 'trip_update'
  | 'dashboard_update'
  | 'ping';

interface WSMessage {
  type: WSMessageType;
  data?: any;
  vehicle_id?: number;
  trip_id?: number;
}

type Listener = (msg: WSMessage) => void;

class KTWebSocketService {
  private ws: WebSocket | null = null;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 10;
  private baseDelay = 1000;
  private listeners = new Map<string, Set<Listener>>();
  private disposed = false;

  get connected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }

  connect(): void {
    this.disposed = false;
    if (this.ws?.readyState === WebSocket.OPEN || this.ws?.readyState === WebSocket.CONNECTING) return;

    const token = useAuthStore.getState().token ?? localStorage.getItem('access_token');
    if (!token) return;

    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.host;
    const url = `${protocol}//${host}/ws?token=${encodeURIComponent(token)}`;

    try {
      this.ws = new WebSocket(url);
      this.ws.onopen = this.handleOpen;
      this.ws.onmessage = this.handleMessage;
      this.ws.onclose = this.handleClose;
      this.ws.onerror = this.handleError;
    } catch {
      this.scheduleReconnect();
    }
  }

  disconnect(): void {
    this.disposed = true;
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    if (this.ws) {
      this.ws.onclose = null;
      this.ws.close();
      this.ws = null;
    }
    this.reconnectAttempts = 0;
  }

  subscribe(type: string, listener: Listener): () => void {
    if (!this.listeners.has(type)) this.listeners.set(type, new Set());
    this.listeners.get(type)!.add(listener);
    return () => this.listeners.get(type)?.delete(listener);
  }

  send(data: Record<string, unknown>): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data));
    }
  }

  subscribeVehicle(vehicleId: number): void {
    this.send({ action: 'subscribe_vehicle', vehicle_id: vehicleId });
  }

  unsubscribeVehicle(vehicleId: number): void {
    this.send({ action: 'unsubscribe_vehicle', vehicle_id: vehicleId });
  }

  subscribeTrip(tripId: number): void {
    this.send({ action: 'subscribe_trip', trip_id: tripId });
  }

  unsubscribeTrip(tripId: number): void {
    this.send({ action: 'unsubscribe_trip', trip_id: tripId });
  }

  // --- private handlers ---

  private handleOpen = (): void => {
    this.reconnectAttempts = 0;
    this.disposed = false;
    this.emit('connected', { type: 'connected' as any });
  };

  private handleMessage = (event: MessageEvent): void => {
    try {
      const msg: WSMessage = JSON.parse(event.data);
      if (msg.type === 'ping') {
        this.send({ type: 'pong' });
        return;
      }
      this.dispatch(msg);
      this.emit(msg.type, msg);
    } catch { /* ignore malformed messages */ }
  };

  private handleClose = (): void => {
    this.ws = null;
    if (!this.disposed) this.scheduleReconnect();
  };

  private handleError = (): void => {
    this.ws?.close();
  };

  private scheduleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) return;
    const delay = Math.min(this.baseDelay * Math.pow(2, this.reconnectAttempts), 30000);
    this.reconnectAttempts++;
    this.reconnectTimer = setTimeout(() => this.connect(), delay);
  }

  private dispatch(msg: WSMessage): void {
    const store = useAppStore.getState();

    switch (msg.type) {
      case 'alert':
        if (msg.data) {
          const alert: Alert = {
            id: msg.data.id ?? crypto.randomUUID(),
            vehicle_id: msg.data.vehicle_id,
            trip_id: msg.data.trip_id,
            driver_id: msg.data.driver_id,
            alert_type: msg.data.alert_type ?? 'general',
            severity: msg.data.severity ?? 'info',
            title: msg.data.title ?? 'Alert',
            message: msg.data.message ?? '',
            is_acknowledged: false,
            created_at: msg.data.created_at ?? new Date().toISOString(),
          };
          store.addAlert(alert);
        }
        break;
      case 'notification':
        if (msg.data) {
          const notif: Notification = {
            id: msg.data.id ?? crypto.randomUUID(),
            type: msg.data.type ?? 'system',
            title: msg.data.title ?? 'Notification',
            message: msg.data.message ?? '',
            severity: msg.data.severity ?? 'info',
            is_read: false,
            action_url: msg.data.action_url,
            created_at: msg.data.created_at ?? new Date().toISOString(),
          };
          store.addNotification(notif);
        }
        break;
      // vehicle_tracking, trip_update, dashboard_update are dispatched to subscribers via listeners
    }
  }

  private emit(type: string, msg: WSMessage): void {
    this.listeners.get(type)?.forEach((fn) => fn(msg));
    this.listeners.get('*')?.forEach((fn) => fn(msg));
  }
}

export const wsService = new KTWebSocketService();
export default wsService;
