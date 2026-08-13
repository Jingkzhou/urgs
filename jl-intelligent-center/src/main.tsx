import React from 'react';
import ReactDOM from 'react-dom/client';
import { invoke } from '@tauri-apps/api/core';
import { listen } from '@tauri-apps/api/event';
import App from './App';
import { TASK_CENTER_STORAGE_KEY } from './components/task-center/storage';
import { isDesktopRuntime } from './config';
import './index.css';

interface LegacyTaskCenterHandoff {
  snapshot?: string | null;
  authUser?: string | null;
  migratedPaths: string[];
}

const LEGACY_IMPORT_MARKER = 'jl_intelligent_center_legacy_imported_v1';

const importLegacyState = async () => {
  if (!isDesktopRuntime()) return false;
  const handoff = await invoke<LegacyTaskCenterHandoff>('load_legacy_task_center_handoff');
  let imported = false;
  if (!localStorage.getItem(LEGACY_IMPORT_MARKER) && handoff.snapshot) {
    localStorage.setItem(TASK_CENTER_STORAGE_KEY, handoff.snapshot);
    localStorage.setItem(LEGACY_IMPORT_MARKER, new Date().toISOString());
    imported = true;
  }
  if (handoff.authUser) {
    localStorage.setItem('auth_user', handoff.authUser);
  }
  return imported;
};

const rootElement = document.getElementById('root');
if (!rootElement) throw new Error('未找到应用根节点');

const startApplication = async () => {
  try {
    await importLegacyState();
  } catch (error) {
    console.error('迁移旧智能任务中心数据失败，继续启动新应用', error);
  }
  if (isDesktopRuntime()) {
    await listen('task-center-handoff-requested', async () => {
      try {
        if (await importLegacyState()) window.location.reload();
      } catch (error) {
        console.error('接收 URGS 智能任务中心交接数据失败', error);
      }
    });
  }
  document.documentElement.classList.toggle('desktop-runtime', isDesktopRuntime());
  ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  );
};

void startApplication();
