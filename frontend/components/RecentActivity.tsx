"use client";

const activities = [
  {
    type: "Supply",
    asset: "ETH",
    amount: "2.5",
    user: "0x1234...5678",
    time: "2 min ago",
  },
  {
    type: "Borrow",
    asset: "USDC",
    amount: "1,500",
    user: "0x8765...4321",
    time: "5 min ago",
  },
  {
    type: "Swap",
    asset: "CB → ETH",
    amount: "500",
    user: "0x9876...1234",
    time: "8 min ago",
  },
  {
    type: "Repay",
    asset: "USDC",
    amount: "2,000",
    user: "0x5432...8765",
    time: "12 min ago",
  },
];

export function RecentActivity() {
  return (
    <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700">
      <h3 className="text-lg font-semibold text-white mb-4">Recent Activity</h3>
      <div className="space-y-4">
        {activities.map((activity, i) => (
          <div
            key={i}
            className="flex items-center justify-between py-3 border-b border-gray-700 last:border-0"
          >
            <div className="flex items-center gap-3">
              <div
                className={`w-8 h-8 rounded-lg flex items-center justify-center text-sm ${
                  activity.type === "Supply"
                    ? "bg-green-500/20 text-green-400"
                    : activity.type === "Borrow"
                    ? "bg-yellow-500/20 text-yellow-400"
                    : activity.type === "Swap"
                    ? "bg-purple-500/20 text-purple-400"
                    : "bg-blue-500/20 text-blue-400"
                }`}
              >
                {activity.type[0]}
              </div>
              <div>
                <p className="text-white font-medium">{activity.type}</p>
                <p className="text-gray-400 text-sm">{activity.asset}</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-white">{activity.amount}</p>
              <p className="text-gray-400 text-sm">{activity.time}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
