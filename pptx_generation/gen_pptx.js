const pptxgen = require('pptxgenjs');
const path = require('path');
const fs = require('fs');

// 导入 html2pptx 库
// 注意：该脚本可能需要相对于其所在目录的路径
// 我们将直接从 skills 目录导入
const html2pptx = require('/Users/work/Documents/GitHub/urgs/.agent/skills/pptx/scripts/html2pptx.js');

async function createRequirementsPresentation() {
    const pptx = new pptxgen();
    pptx.layout = 'LAYOUT_16x9';
    pptx.author = 'Antigravity AI';
    pptx.title = 'URGS 项目业务需求文档';

    const slidesDir = '/Users/work/Documents/GitHub/urgs/pptx_generation/slides';
    const slideFiles = Array.from({ length: 10 }, (_, i) => `slide${i + 1}.html`);

    console.log('开始转换 HTML 到 PPTX...');

    for (const file of slideFiles) {
        const filePath = path.join(slidesDir, file);
        console.log(`正在处理: ${file}`);
        try {
            await html2pptx(filePath, pptx);
        } catch (error) {
            console.error(`处理 ${file} 时出错:`, error);
            // 这里我们抛出错误，以便让 Antigravity 知道出了问题
            throw error;
        }
    }

    const outputPath = '/Users/work/Documents/GitHub/urgs/URGS_Requirements.pptx';
    await pptx.writeFile({ fileName: outputPath });
    console.log(`PPTX 已成功生成: ${outputPath}`);
}

createRequirementsPresentation().catch(err => {
    console.error('生成流程失败:', err);
    process.exit(1);
});
