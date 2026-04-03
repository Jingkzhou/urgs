import React, { Suspense } from 'react';

const MonacoEditor = React.lazy(() => import('@monaco-editor/react'));

interface LazyMonacoEditorProps {
    loadingFallback: React.ReactNode;
    [key: string]: any;
}

const LazyMonacoEditor: React.FC<LazyMonacoEditorProps> = ({ loadingFallback, ...props }) => {
    return (
        <Suspense fallback={loadingFallback}>
            <MonacoEditor {...props} />
        </Suspense>
    );
};

export default LazyMonacoEditor;
