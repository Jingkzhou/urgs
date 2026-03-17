import React from 'react';
import { SlideLayout } from '../layout/SlideLayout';
import { SQLParsingAnimationDemo } from '../shared/SQLParsingAnimationDemo';

export const SQLParsingDetailPage = () => {
    return (
        <SlideLayout
            title="SQL 智能解析：血缘自动化提取"
            subtitle="从代码提交到依赖感知的全流程动画图解"
        >
            <SQLParsingAnimationDemo />
        </SlideLayout>
    );
};
