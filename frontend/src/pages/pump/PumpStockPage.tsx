import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, TrendingUp, TrendingDown, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';
import { fuelPumpService } from '@/services/fuelPumpService';

export default function PumpStockPage() {
  const queryClient = useQueryClient();
  const [showAddForm, setShowAddForm] = useState(false);
  const [page, setPage] = useState(1);
  const [selectedTank, setSelectedTank] = useState<string>('');

  const { data: tanksData } = useQuery({
    queryKey: ['fuel-tanks'],
    queryFn: fuelPumpService.getTanks,
  });

  const { data: txnsData, isLoading } = useQuery({
    queryKey: ['stock-transactions', page, selectedTank],
    queryFn: () => fuelPumpService.getStockTransactions({
      page, limit: 20,
      ...(selectedTank ? { tank_id: Number(selectedTank) } : {}),
    }),
  });

  const tanks = tanksData?.data || [];
  const txns = txnsData?.data || [];
  const pagination = txnsData?.pagination;

  const [form, setForm] = useState({
    tank_id: '',
    transaction_type: 'tanker_refill',
    quantity_litres: '',
    rate_per_litre: '',
    reference_number: '',
    remarks: '',
  });

  const mutation = useMutation({
    mutationFn: (data: any) => fuelPumpService.addStock(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['fuel-tanks'] });
      queryClient.invalidateQueries({ queryKey: ['stock-transactions'] });
      queryClient.invalidateQueries({ queryKey: ['pump-dashboard'] });
      toast.success('Stock transaction recorded');
      setShowAddForm(false);
      setForm({ tank_id: '', transaction_type: 'tanker_refill', quantity_litres: '', rate_per_litre: '', reference_number: '', remarks: '' });
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.detail || 'Failed to add stock');
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    mutation.mutate({
      tank_id: Number(form.tank_id),
      transaction_type: form.transaction_type,
      quantity_litres: Number(form.quantity_litres),
      rate_per_litre: form.rate_per_litre ? Number(form.rate_per_litre) : null,
      reference_number: form.reference_number || null,
      remarks: form.remarks || null,
    });
  };

  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Tank Stock Management</h1>
          <p className="text-sm text-gray-500">Refills, adjustments, and stock history</p>
        </div>
        <button
          onClick={() => setShowAddForm(!showAddForm)}
          className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition text-sm"
        >
          <Plus size={16} /> Add Stock Transaction
        </button>
      </div>

      {/* Add Stock Form */}
      {showAddForm && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4">New Stock Transaction</h2>
          <form onSubmit={handleSubmit} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tank *</label>
              <select
                value={form.tank_id}
                onChange={(e) => setForm({ ...form, tank_id: e.target.value })}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
                required
              >
                <option value="">Select tank</option>
                {tanks.map((t: any) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Type *</label>
              <select
                value={form.transaction_type}
                onChange={(e) => setForm({ ...form, transaction_type: e.target.value })}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
              >
                <option value="tanker_refill">Tanker Refill</option>
                <option value="manual_adjustment">Manual Adjustment</option>
                <option value="loss">Loss / Spillage</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Quantity (L) *</label>
              <input
                type="number" step="0.01" min="0.01"
                value={form.quantity_litres}
                onChange={(e) => setForm({ ...form, quantity_litres: e.target.value })}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Rate / Litre (₹)</label>
              <input
                type="number" step="0.01"
                value={form.rate_per_litre}
                onChange={(e) => setForm({ ...form, rate_per_litre: e.target.value })}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Reference No.</label>
              <input
                type="text"
                value={form.reference_number}
                onChange={(e) => setForm({ ...form, reference_number: e.target.value })}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
                placeholder="Tanker bill number"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Remarks</label>
              <input
                type="text"
                value={form.remarks}
                onChange={(e) => setForm({ ...form, remarks: e.target.value })}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
              />
            </div>
            <div className="sm:col-span-2 flex gap-3">
              <button type="button" onClick={() => setShowAddForm(false)} className="px-4 py-2 border border-gray-300 rounded-lg text-sm">
                Cancel
              </button>
              <button type="submit" disabled={mutation.isPending} className="px-4 py-2 bg-primary-600 text-white rounded-lg text-sm hover:bg-primary-700 disabled:opacity-50">
                {mutation.isPending ? 'Saving...' : 'Save Transaction'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Filter */}
      <div className="flex items-center gap-3">
        <select
          value={selectedTank}
          onChange={(e) => { setSelectedTank(e.target.value); setPage(1); }}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm"
        >
          <option value="">All tanks</option>
          {tanks.map((t: any) => (
            <option key={t.id} value={t.id}>{t.name}</option>
          ))}
        </select>
      </div>

      {/* Transactions Table */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Qty (L)</th>
                <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Rate</th>
                <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Amount</th>
                <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Before</th>
                <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">After</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ref</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {isLoading ? (
                <tr><td colSpan={8} className="px-4 py-8 text-center text-gray-400">Loading...</td></tr>
              ) : txns.length === 0 ? (
                <tr><td colSpan={8} className="px-4 py-8 text-center text-gray-400">No transactions found</td></tr>
              ) : (
                txns.map((txn: any) => (
                  <tr key={txn.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-700">
                      {new Date(txn.created_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center gap-1 px-2 py-0.5 text-xs rounded-full ${
                        txn.transaction_type === 'tanker_refill' ? 'bg-green-100 text-green-700' :
                        txn.transaction_type === 'loss' ? 'bg-red-100 text-red-700' :
                        txn.transaction_type === 'issue' ? 'bg-blue-100 text-blue-700' :
                        'bg-yellow-100 text-yellow-700'
                      }`}>
                        {txn.transaction_type === 'tanker_refill' ? <TrendingUp size={12} /> :
                         txn.transaction_type === 'loss' ? <TrendingDown size={12} /> :
                         <RefreshCw size={12} />}
                        {txn.transaction_type.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right font-medium">{Number(txn.quantity_litres).toFixed(1)}</td>
                    <td className="px-4 py-3 text-right text-gray-600">
                      {txn.rate_per_litre ? `₹${Number(txn.rate_per_litre).toFixed(2)}` : '-'}
                    </td>
                    <td className="px-4 py-3 text-right font-medium">
                      {txn.total_amount ? `₹${Number(txn.total_amount).toLocaleString()}` : '-'}
                    </td>
                    <td className="px-4 py-3 text-right text-gray-600">{Number(txn.stock_before).toLocaleString()}L</td>
                    <td className="px-4 py-3 text-right text-gray-600">{Number(txn.stock_after).toLocaleString()}L</td>
                    <td className="px-4 py-3 text-gray-600">{txn.reference_number || '-'}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {pagination && pagination.pages > 1 && (
          <div className="px-4 py-3 border-t border-gray-200 flex items-center justify-between text-sm">
            <span className="text-gray-500">Page {pagination.page} of {pagination.pages}</span>
            <div className="flex gap-2">
              <button disabled={page <= 1} onClick={() => setPage(p => p - 1)} className="px-3 py-1 border rounded text-sm disabled:opacity-50">Previous</button>
              <button disabled={page >= pagination.pages} onClick={() => setPage(p => p + 1)} className="px-3 py-1 border rounded text-sm disabled:opacity-50">Next</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
