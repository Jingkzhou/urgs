import React from 'react';
import ReactDOM from 'react-dom/client';
import dayjs from 'dayjs';
import weekday from 'dayjs/plugin/weekday';
import localeData from 'dayjs/plugin/localeData';
import weekOfYear from 'dayjs/plugin/weekOfYear';
import weekYear from 'dayjs/plugin/weekYear';
import advancedFormat from 'dayjs/plugin/advancedFormat';
import customParseFormat from 'dayjs/plugin/customParseFormat';
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
import { getApiBaseUrl, installServiceRequestAdapters, isDesktopRuntime } from './config';
import { installDesktopDownloadAdapter } from './utils/desktopDownload';
import { initializeDesktopRuntimeConfig } from './utils/desktopRuntime';
import './index.css';

const rootElement = document.getElementById('root');
if (!rootElement) {
  throw new Error("Could not find root element to mount to");
}

const root = ReactDOM.createRoot(rootElement);

const startApplication = async () => {
  await initializeDesktopRuntimeConfig();
  installServiceRequestAdapters();
  installDesktopDownloadAdapter();
  const editDesktopConnection = localStorage.getItem('urgs_desktop_edit_connection') === '1';

  root.render(
    <React.StrictMode>
      {isDesktopRuntime() && (!getApiBaseUrl() || editDesktopConnection) ? <DesktopConnectionSetup /> : <App />}
      <DesktopAutoUpdater />
    </React.StrictMode>
  );
};

void startApplication();
