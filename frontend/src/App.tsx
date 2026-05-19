import { useEffect } from 'react';
import { useAppStore } from './store';
import { socket } from './api';

function App() {
  const {
    shipments,
    drivers,
    dashboardMetrics,
    fetchShipments,
    fetchDrivers,
    fetchDashboardMetrics,
    loadingShipments,
    loadingMetrics
  } = useAppStore();

  useEffect(() => {
    fetchShipments();
    fetchDrivers();
    fetchDashboardMetrics();

    // Listen for real-time updates
    socket.on('shipment_created', (shipment) => {
      console.log('New shipment:', shipment);
    });

    socket.on('driver_location_updated', (update) => {
      console.log('Driver location updated:', update);
    });

    return () => {
      socket.off('shipment_created');
      socket.off('driver_location_updated');
    };
  }, [fetchShipments, fetchDrivers, fetchDashboardMetrics]);

  return (
    <div className="min-h-screen bg-slate-900 text-white">
      {/* Header */}
      <header className="bg-slate-800 border-b border-slate-700 px-6 py-4">
        <h1 className="text-3xl font-bold">🚚 Carrier Dispatch Pro</h1>
        <p className="text-slate-400 mt-1">Enterprise Fleet Management</p>
      </header>

      {/* Main Content */}
      <main className="p-6">
        {/* Dashboard Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-8">
          <MetricCard
            label="Active Shipments"
            value={dashboardMetrics?.active_shipments || 0}
            icon="📦"
          />
          <MetricCard
            label="Available Drivers"
            value={dashboardMetrics?.available_drivers || 0}
            icon="👨‍💼"
          />
          <MetricCard
            label="Total Distance"
            value={`${dashboardMetrics?.total_distance || 0} mi`}
            icon="📍"
          />
          <MetricCard
            label="Revenue Today"
            value={`$${dashboardMetrics?.revenue_today || 0}`}
            icon="💰"
          />
          <MetricCard
            label="On-Time Delivery"
            value={`${dashboardMetrics?.on_time_delivery || 0}%`}
            icon="✅"
          />
          <MetricCard
            label="Avg Rating"
            value={`${dashboardMetrics?.average_rating || 0} ⭐`}
            icon="⭐"
          />
        </div>

        {/* Shipments Section */}
        <div className="bg-slate-800 rounded-lg border border-slate-700 p-6 mb-8">
          <h2 className="text-2xl font-bold mb-4">📋 Active Shipments</h2>
          {loadingShipments ? (
            <p className="text-slate-400">Loading shipments...</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="border-b border-slate-700">
                  <tr>
                    <th className="text-left py-2 px-4">ID</th>
                    <th className="text-left py-2 px-4">From</th>
                    <th className="text-left py-2 px-4">To</th>
                    <th className="text-left py-2 px-4">Status</th>
                    <th className="text-left py-2 px-4">Driver</th>
                    <th className="text-left py-2 px-4">Weight</th>
                  </tr>
                </thead>
                <tbody>
                  {shipments.map((shipment) => (
                    <tr key={shipment.id} className="border-b border-slate-700 hover:bg-slate-700">
                      <td className="py-3 px-4">{shipment.id}</td>
                      <td className="py-3 px-4">{shipment.origin}</td>
                      <td className="py-3 px-4">{shipment.destination}</td>
                      <td className="py-3 px-4">
                        <StatusBadge status={shipment.status} />
                      </td>
                      <td className="py-3 px-4">{shipment.driver_id || 'Unassigned'}</td>
                      <td className="py-3 px-4">{shipment.weight} lbs</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Drivers Section */}
        <div className="bg-slate-800 rounded-lg border border-slate-700 p-6">
          <h2 className="text-2xl font-bold mb-4">👨‍💼 Active Drivers</h2>
          {loadingMetrics ? (
            <p className="text-slate-400">Loading drivers...</p>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {drivers.map((driver) => (
                <DriverCard key={driver.id} driver={driver} />
              ))}
            </div>
          )}
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-slate-800 border-t border-slate-700 text-center py-4 mt-8">
        <p className="text-slate-400">© 2025 3 Jays Dispatching - All Rights Reserved</p>
      </footer>
    </div>
  );
}

interface MetricCardProps {
  label: string;
  value: number | string;
  icon: string;
}

function MetricCard({ label, value, icon }: MetricCardProps) {
  return (
    <div className="bg-slate-800 border border-slate-700 rounded-lg p-4 hover:border-slate-600 transition">
      <div className="text-2xl mb-2">{icon}</div>
      <p className="text-slate-400 text-sm">{label}</p>
      <p className="text-2xl font-bold mt-2">{value}</p>
    </div>
  );
}

interface StatusBadgeProps {
  status: string;
}

function StatusBadge({ status }: StatusBadgeProps) {
  const colors: Record<string, string> = {
    pending: 'bg-yellow-500/20 text-yellow-300',
    assigned: 'bg-blue-500/20 text-blue-300',
    in_transit: 'bg-purple-500/20 text-purple-300',
    delivered: 'bg-green-500/20 text-green-300'
  };

  return (
    <span className={`px-3 py-1 rounded-full text-xs font-semibold ${colors[status] || colors.pending}`}>
      {status.replace(/_/g, ' ').toUpperCase()}
    </span>
  );
}

interface DriverCardProps {
  driver: {
    id: string;
    name: string;
    status: string;
    vehicle_id: string;
    miles_today: number;
  };
}

function DriverCard({ driver }: DriverCardProps) {
  return (
    <div className="bg-slate-700 rounded-lg p-4 border border-slate-600">
      <h3 className="font-bold text-lg mb-2">{driver.name}</h3>
      <div className="text-sm space-y-1 text-slate-300">
        <p>ID: {driver.id}</p>
        <p>Vehicle: {driver.vehicle_id}</p>
        <p>Today: {driver.miles_today} mi</p>
        <p>Status: <span className="text-green-400 font-semibold">{driver.status.replace(/_/g, ' ')}</span></p>
      </div>
    </div>
  );
}

export default App;
