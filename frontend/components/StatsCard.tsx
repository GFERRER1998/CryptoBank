"use client";

interface StatsCardProps {
  title: string;
  value: string;
  change: string;
  icon: string;
}

export function StatsCard({ title, value, change, icon }: StatsCardProps) {
  const isPositive = change.startsWith("+");

  return (
    <div className="bg-gray-800/50 rounded-xl p-6 border border-gray-700">
      <div className="flex items-center justify-between mb-4">
        <span className="text-2xl">{icon}</span>
        <span
          className={`text-sm font-medium ${
            isPositive ? "text-green-400" : "text-red-400"
          }`}
        >
          {change}
        </span>
      </div>
      <p className="text-gray-400 text-sm mb-1">{title}</p>
      <p className="text-2xl font-bold text-white">{value}</p>
    </div>
  );
}
