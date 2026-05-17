import React from 'react';
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { MetricChartType } from '../../api/metrics';

export interface MetricChartPoint {
  name: string;
  value: number;
  max: number;
  min: number;
}

interface MetricChartRendererProps {
  data: MetricChartPoint[];
  chartType: MetricChartType;
  color: string;
  gradientId: string;
  glowId: string;
  tooltip: React.ReactElement;
}

const chartMargin = { top: 10, right: 30, left: 0, bottom: 0 };

const Axis = () => (
  <>
    <CartesianGrid strokeDasharray="4 4" stroke="rgba(0,0,0,0.03)" vertical={false} />
    <XAxis
      dataKey="name"
      axisLine={false}
      tickLine={false}
      tick={{ fill: '#94a3b8', fontSize: 10, fontWeight: 800 }}
      dy={15}
    />
    <YAxis
      axisLine={false}
      tickLine={false}
      tick={{ fill: '#94a3b8', fontSize: 10, fontWeight: 800 }}
      dx={-10}
    />
  </>
);

const MetricChartRenderer: React.FC<MetricChartRendererProps> = ({
  data,
  chartType,
  color,
  gradientId,
  glowId,
  tooltip,
}) => {
  if (chartType === 'line') {
    return (
      <ResponsiveContainer width="100%" height={320}>
        <LineChart data={data} margin={chartMargin}>
          <Axis />
          <Tooltip content={tooltip} cursor={{ stroke: color, strokeWidth: 1, strokeDasharray: '5 5' }} />
          <Line
            type="monotone"
            dataKey="value"
            stroke={color}
            strokeWidth={4}
            strokeLinecap="round"
            dot={false}
            activeDot={{ r: 6, fill: color, stroke: '#fff', strokeWidth: 3 }}
          />
        </LineChart>
      </ResponsiveContainer>
    );
  }

  if (chartType === 'bar') {
    return (
      <ResponsiveContainer width="100%" height={320}>
        <BarChart data={data} margin={chartMargin}>
          <Axis />
          <Tooltip content={tooltip} cursor={{ fill: 'rgba(15,23,42,0.04)' }} />
          <Bar dataKey="value" fill={color} radius={[10, 10, 4, 4]} barSize={28} />
        </BarChart>
      </ResponsiveContainer>
    );
  }

  if (chartType === 'pie') {
    return (
      <ResponsiveContainer width="100%" height={320}>
        <PieChart>
          <Tooltip content={tooltip} />
          <Pie data={data} dataKey="value" nameKey="name" innerRadius={70} outerRadius={118} paddingAngle={2}>
            {data.map((entry, index) => (
              <Cell
                key={entry.name}
                fill={index === data.length - 1 ? color : `${color}${Math.max(35, 90 - index * 8).toString(16)}`}
                stroke="#fff"
                strokeWidth={2}
              />
            ))}
          </Pie>
        </PieChart>
      </ResponsiveContainer>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={320}>
      <AreaChart data={data} margin={chartMargin}>
        <defs>
          <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor={color} stopOpacity={0.15} />
            <stop offset="95%" stopColor={color} stopOpacity={0} />
          </linearGradient>
          <linearGradient id={glowId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity={0.3} />
            <stop offset="100%" stopColor={color} stopOpacity={0} />
          </linearGradient>
        </defs>
        <Axis />
        <Tooltip content={tooltip} cursor={{ stroke: color, strokeWidth: 1, strokeDasharray: '5 5' }} />
        <Area type="monotone" dataKey="value" stroke="none" fill={`url(#${glowId})`} isAnimationActive={false} />
        <Area
          type="monotone"
          dataKey="value"
          stroke={color}
          strokeWidth={4}
          strokeLinecap="round"
          fill={`url(#${gradientId})`}
          isAnimationActive={false}
          dot={false}
          activeDot={{ r: 6, fill: color, stroke: '#fff', strokeWidth: 3 }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
};

export default MetricChartRenderer;
