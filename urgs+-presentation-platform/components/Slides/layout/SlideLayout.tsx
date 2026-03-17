import React from 'react';

export const SlideLayout: React.FC<{ children: React.ReactNode, title?: string, subtitle?: string }> = ({ children, title, subtitle }) => (
    <div className="w-full h-full flex flex-col items-center justify-center">
        {title && (
            <div className="mb-12 text-center w-full">
                <h2 className="text-4xl md:text-5xl font-bold text-slate-900 tracking-tight mb-4 anim-fade-up">{title}</h2>
                {subtitle && <p className="text-xl md:text-2xl text-slate-500 font-light anim-fade-up delay-100">{subtitle}</p>}
            </div>
        )}
        <div className="w-full flex-1 flex flex-col justify-center">
            {children}
        </div>
    </div>
);
