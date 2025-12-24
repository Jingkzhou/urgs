/// <reference types="vite/client" />
/**
 * Global Configuration
 * 
 * To override the WebSocket URL for remote servers:
 * 1. Create a .env file in the project root
 * 2. Add VITE_WS_URL=ws://your-server-ip:8080/ws/im
 */

// Default to localhost if not specified in environment
const DEFAULT_WS_URL = 'ws://localhost:8080/ws/im';

// Interface for window object
declare global {
    interface Window {
        __RUNTIME_CONFIG__?: {
            VITE_WS_URL?: string;
        };
    }
}

// Priority: Runtime config.js (Docker) > Build-time Env > Default
export const WS_URL = window.__RUNTIME_CONFIG__?.VITE_WS_URL || import.meta.env.VITE_WS_URL || DEFAULT_WS_URL;
