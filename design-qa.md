# 我发布的工作列表设计 QA

- Source visual truth: `/Users/zhoujingkun/.codex/generated_images/019f2564-149b-7cf3-b364-eed574302490/call_xjiwouZ9oxblGmTo1yZ93iEY.png`
- Implementation screenshot: unavailable
- Viewport: intended `1440x1024`
- State: “我发布的工作”列表，首条工作展开，展示工作内容、任务进度、主任务、子任务和风险记录

## Full-view comparison evidence

未完成。项目要求所有网页操作必须使用 gstack `/browse`，但当前仓库未包含该技能；按项目说明尝试从 GitHub 初始化 gstack 时，环境无法连接 `github.com:443`。

## Focused region comparison evidence

未完成。由于无法取得实现截图，不能将参考图与实现图放入同一比较输入，也不能可靠判断密集列表、展开区和任务表的实际渲染差异。

## Fidelity surfaces

- Fonts and typography: 源码沿用现有项目字体体系和 `text-xs` / `text-sm` 层级，未完成像素级检查。
- Spacing and layout rhythm: 主列表由 16 列压缩为 8 个信息组，展开区使用左右摘要和分层任务表，未完成浏览器尺寸检查。
- Colors and visual tokens: 沿用现有 `slate`、`red`、`blue`、`green`、`amber` 语义色，未完成截图采样核对。
- Image quality and asset fidelity: 本页面没有新增位图资产，图标继续使用项目现有 Lucide 图标库。
- Copy and content: 保留现有工作字段、任务字段和操作，并新增页面说明与任务进度汇总文案。

## Findings

- [P1] 缺少实现截图和同屏视觉比较
  - Location: `urgs-web/src/components/marketplace/WorkList.tsx`
  - Evidence: 参考图可读取，但 `/browse` 不可用，无法捕获实现状态。
  - Impact: 不能确认常用视口下是否存在横向溢出、文字截断或展开区间距偏差。
  - Fix: gstack `/browse` 可用后，以 `1440x1024` 打开任务中心，展开首条工作，截图并与参考图同屏比较。

## Patches made since previous QA pass

- 将工作主列表从 16 个独立字段列重组为 8 个信息组。
- 将展开内容重组为工作内容、任务进度、主任务、子任务和风险记录。
- 增加任务完成率及状态数量汇总。
- 保留搜索、批量删除、导入、导出、新建、编辑、发布、取消、暂停/继续、资产记录和风险追加操作。

## Implementation checklist

- 恢复 gstack `/browse`。
- 捕获 `1440x1024` 的列表和展开状态。
- 修复截图对比中发现的 P0/P1/P2 问题。
- 将 `final result` 更新为 `passed`。

## Follow-up polish

待视觉对比后确认。

final result: blocked
