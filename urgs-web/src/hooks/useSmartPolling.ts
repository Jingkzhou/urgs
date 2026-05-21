import { useEffect, useRef } from 'react';

interface SmartPollingOptions {
  enabled?: boolean;
  immediate?: boolean;
}

export function useSmartPolling(
  callback: () => void | Promise<void>,
  intervalMs: number,
  options: SmartPollingOptions = {}
) {
  const { enabled = true, immediate = true } = options;
  const callbackRef = useRef(callback);
  const runningRef = useRef(false);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    callbackRef.current = callback;
  }, [callback]);

  useEffect(() => {
    if (!enabled || intervalMs <= 0) return;

    const clearTimer = () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
    };

    const run = async () => {
      if (document.hidden || runningRef.current) return;
      runningRef.current = true;
      try {
        await callbackRef.current();
      } finally {
        runningRef.current = false;
      }
    };

    const startTimer = () => {
      clearTimer();
      if (!document.hidden) {
        timerRef.current = setInterval(run, intervalMs);
      }
    };

    const handleVisibilityChange = () => {
      if (document.hidden) {
        clearTimer();
        return;
      }
      run();
      startTimer();
    };

    if (immediate) run();
    startTimer();
    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      clearTimer();
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [enabled, immediate, intervalMs]);
}
