import test from 'node:test';
import assert from 'node:assert/strict';
import {
    deriveWebSocketUrl,
    parseDeployEnv,
    resolveDesktopRuntimeConfig,
} from './build-web.mjs';

test('parseDeployEnv ignores comments and supports quoted values', () => {
    assert.deepEqual(parseDeployEnv(`
# comment
URGS_API_BASE_URL=http://25.18.17.210:18080
WEB_WS_URL="wss://example.com/ws/im"
`), {
        URGS_API_BASE_URL: 'http://25.18.17.210:18080',
        WEB_WS_URL: 'wss://example.com/ws/im',
    });
});

test('deriveWebSocketUrl follows API scheme and appends IM path', () => {
    assert.equal(
        deriveWebSocketUrl('https://urgs.example.com/base/'),
        'wss://urgs.example.com/base/ws/im',
    );
});

test('resolveDesktopRuntimeConfig derives WebSocket when WEB_WS_URL is empty', () => {
    assert.deepEqual(resolveDesktopRuntimeConfig(`
URGS_API_BASE_URL=http://25.18.17.210:18080
WEB_WS_URL=
`), {
        apiBaseUrl: 'http://25.18.17.210:18080',
        wsUrl: 'ws://25.18.17.210:18080/ws/im',
    });
});

test('resolveDesktopRuntimeConfig honors explicit WEB_WS_URL', () => {
    assert.deepEqual(resolveDesktopRuntimeConfig(`
URGS_API_BASE_URL=https://urgs.example.com
WEB_WS_URL=wss://im.example.com/socket
`), {
        apiBaseUrl: 'https://urgs.example.com',
        wsUrl: 'wss://im.example.com/socket',
    });
});

test('resolveDesktopRuntimeConfig prefers Desktop-specific values', () => {
    assert.deepEqual(resolveDesktopRuntimeConfig(`
URGS_API_BASE_URL=http://host.docker.internal:8080
WEB_WS_URL=ws://host.docker.internal:8080/ws/im
DESKTOP_API_BASE_URL=http://127.0.0.1:18080
DESKTOP_WS_URL=ws://127.0.0.1:18080/custom-im
`), {
        apiBaseUrl: 'http://127.0.0.1:18080',
        wsUrl: 'ws://127.0.0.1:18080/custom-im',
    });
});
