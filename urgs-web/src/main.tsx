import React from 'react';
import ReactDOM from 'react-dom/client';
import { ConfigProvider } from 'antd';
import dayjs from 'dayjs';
import weekday from 'dayjs/plugin/weekday';
import localeData from 'dayjs/plugin/localeData';
import weekOfYear from 'dayjs/plugin/weekOfYear';
import weekYear from 'dayjs/plugin/weekYear';
import advancedFormat from 'dayjs/plugin/advancedFormat';
import customParseFormat from 'dayjs/plugin/customParseFormat';
import 'antd/dist/antd.css';
import 'dayjs/locale/zh-cn';

dayjs.extend(customParseFormat);
dayjs.extend(advancedFormat);
dayjs.extend(weekday);
dayjs.extend(localeData);
dayjs.extend(weekOfYear);
dayjs.extend(weekYear);
dayjs.locale('zh-cn');

import App from './App';
import DesktopConnectionSetup from './components/desktop/DesktopConnectionSetup';
import DesktopAutoUpdater from './components/desktop/DesktopAutoUpdater';
import DesktopErrorBoundary from './components/desktop/DesktopErrorBoundary';
import { getCurrentWebviewWindow } from '@tauri-apps/api/webviewWindow';
import { getApiBaseUrl, installServiceRequestAdapters, isDesktopRuntime } from './config';
import { invokeDesktop, writeDesktopLog } from './services/desktopBridge';
import { installDesktopDownloadAdapter } from './utils/desktopDownload';
import { initializeDesktopAutostart } from './utils/desktopAutostart';
import { initializeDesktopRuntimeConfig } from './utils/desktopRuntime';
import { installDesktopErrorLogging } from './utils/desktopErrorLogging';
import './index.css';
import './styles/dual-platform.css';

installDesktopErrorLogging();

const rootElement = document.getElementById('root');
if (!rootElement) {
  throw new Error("Could not find root element to mount to");
}

const root = ReactDOM.createRoot(rootElement);

const revealDesktopMainWindow = async () => {
  if (!isDesktopRuntime()) {
    return;
  }

  try {
    if (getCurrentWebviewWindow().label !== 'main') {
      return;
    }

    await invokeDesktop('complete_desktop_startup');
  } catch (error) {
    console.error('显示桌面客户端主窗口失败', error);
    void writeDesktopLog('ERROR', 'web.startup', `显示桌面客户端主窗口失败: ${error instanceof Error ? error.message : String(error)}`);
  }
};

const startApplication = async () => {
  await initializeDesktopRuntimeConfig();
  await initializeDesktopAutostart();
  installServiceRequestAdapters();
  installDesktopDownloadAdapter();
  const desktopRuntime = isDesktopRuntime();
  if (desktopRuntime) installDesktopErrorLogging();
  document.documentElement.classList.toggle('desktop-runtime', desktopRuntime);
  const editDesktopConnection = localStorage.getItem('urgs_desktop_edit_connection') === '1';

  root.render(
    <React.StrictMode>
      <DesktopErrorBoundary>
        <ConfigProvider theme={{ zeroRuntime: true, cssVar: { key: 'urgs' } }}>
          {desktopRuntime && (!getApiBaseUrl() || editDesktopConnection) ? <DesktopConnectionSetup /> : <App />}
          <DesktopAutoUpdater />
        </ConfigProvider>
      </DesktopErrorBoundary>
    </React.StrictMode>
  );

  void revealDesktopMainWindow();
};

void startApplication();
