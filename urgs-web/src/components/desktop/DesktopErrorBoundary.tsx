import React from 'react';
import { describeDesktopError, writeDesktopLog } from '@/services/grokDesktop';

interface DesktopErrorBoundaryProps {
    children: React.ReactNode;
}

interface DesktopErrorBoundaryState {
    error: Error | null;
}

class DesktopErrorBoundary extends React.Component<DesktopErrorBoundaryProps, DesktopErrorBoundaryState> {
    state: DesktopErrorBoundaryState = { error: null };

    static getDerivedStateFromError(error: Error): DesktopErrorBoundaryState {
        return { error };
    }

    componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
        void writeDesktopLog(
            'ERROR',
            'web.render',
            `error=${describeDesktopError(error, true)} component_stack=${errorInfo.componentStack?.slice(0, 3_000) || 'unknown'}`,
        );
    }

    render() {
        if (!this.state.error) return this.props.children;

        return (
            <div className="flex h-full min-h-0 items-center justify-center bg-slate-50 p-6" role="alert">
                <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 text-center shadow-sm">
                    <h1 className="text-base font-semibold text-slate-900">页面暂时无法显示</h1>
                    <p className="mt-2 text-sm leading-6 text-slate-500">请重新加载页面后重试。如果问题持续，请查看客户端运行日志。</p>
                    <button
                        type="button"
                        onClick={() => window.location.reload()}
                        className="mt-4 rounded-xl bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700"
                    >
                        重新加载
                    </button>
                </div>
            </div>
        );
    }
}

export default DesktopErrorBoundary;
