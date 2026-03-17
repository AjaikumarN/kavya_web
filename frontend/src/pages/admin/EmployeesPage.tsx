import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Users, Search, Plus, Shield, X, Trash2 } from 'lucide-react';
import DataTable, { Column } from '@/components/common/DataTable';
import { KPICard, StatusBadge } from '@/components/common/Modal';
import api from '@/services/api';
import { safeArray } from '@/utils/helpers';
import toast from 'react-hot-toast';

interface Employee {
  id: number;
  name: string;
  email: string;
  phone: string;
  role: string;
  status: string;
  department: string;
  joined_date: string;
}

export default function EmployeesPage() {
  const [search, setSearch] = useState('');
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [createForm, setCreateForm] = useState({
    email: '',
    password: '',
    first_name: '',
    last_name: '',
    phone: '',
    role_names: ['manager'] as string[],
  });
  const qc = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['admin-employees', search],
    queryFn: async () => {
      const res = await api.get('/users', { params: { search: search || undefined } });
      return res;
    },
  });

  const createMutation = useMutation({
    mutationFn: async () => {
      return api.post('/users', createForm);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-employees'] });
      qc.invalidateQueries({ queryKey: ['jobs-assign-drivers'] });
      qc.invalidateQueries({ queryKey: ['trips-create-drivers'] });
      qc.invalidateQueries({ queryKey: ['trip-lookup-drivers'] });
      qc.invalidateQueries({ queryKey: ['lr-lookup-drivers'] });
      toast.success('Employee created successfully');
      setIsCreateOpen(false);
      setCreateForm({ email: '', password: '', first_name: '', last_name: '', phone: '', role_names: ['manager'] });
    },
    onError: (err: any) => {
      const msg = err?.response?.data?.detail || err?.message || 'Failed to create employee';
      toast.error(msg);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      return api.delete(`/users/${id}`);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-employees'] });
      qc.invalidateQueries({ queryKey: ['jobs-assign-drivers'] });
      qc.invalidateQueries({ queryKey: ['trips-create-drivers'] });
      qc.invalidateQueries({ queryKey: ['trip-lookup-drivers'] });
      qc.invalidateQueries({ queryKey: ['lr-lookup-drivers'] });
      toast.success('Employee deleted successfully');
    },
    onError: (err: any) => {
      const msg = err?.response?.data?.detail || err?.message || 'Failed to delete employee';
      toast.error(msg);
    },
  });

  const employees: Employee[] = safeArray(data).map((u: any) => ({
    id: u.id,
    name: u.full_name || u.name || `${u.first_name || ''} ${u.last_name || ''}`.trim() || u.email,
    email: u.email,
    phone: u.phone || '-',
    role: u.role || (u.roles && u.roles[0]) || 'user',
    status: u.is_active === false ? 'inactive' : 'active',
    department: u.department || '-',
    joined_date: u.created_at || '-',
  }));

  const columns: Column<Employee>[] = [
    {
      key: 'name',
      header: 'Name',
      render: (e) => (
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
            <span className="text-sm font-medium text-blue-600">{e.name.charAt(0)}</span>
          </div>
          <div>
            <p className="font-medium text-gray-900">{e.name}</p>
            <p className="text-xs text-gray-500">{e.email}</p>
          </div>
        </div>
      ),
    },
    { key: 'phone', header: 'Phone', render: (e) => <span className="text-sm">{e.phone}</span> },
    { key: 'role', header: 'Role', render: (e) => <StatusBadge status={e.role} /> },
    { key: 'department', header: 'Department', render: (e) => <span className="text-sm">{e.department}</span> },
    { key: 'status', header: 'Status', render: (e) => <StatusBadge status={e.status} /> },
    {
      key: 'actions',
      header: 'Actions',
      render: (e) => (
        <button
          type="button"
          className="inline-flex items-center gap-1 text-red-600 hover:text-red-700 text-sm"
          onClick={() => {
            if (deleteMutation.isPending) return;
            const ok = window.confirm(`Delete employee \"${e.name}\"?`);
            if (!ok) return;
            deleteMutation.mutate(e.id);
          }}
          disabled={deleteMutation.isPending}
          title="Delete employee"
        >
          <Trash2 size={14} /> Delete
        </button>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Employees</h1>
          <p className="page-subtitle">Manage all system users and employees</p>
        </div>
        <button className="btn-primary flex items-center gap-2" onClick={() => setIsCreateOpen(true)}>
          <Plus size={16} /> Add Employee
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <KPICard title="Total Employees" value={employees.length} icon={<Users className="w-5 h-5" />} color="blue" />
        <KPICard title="Active" value={employees.filter(e => e.status === 'active').length} icon={<Shield className="w-5 h-5" />} color="green" />
        <KPICard title="Inactive" value={employees.filter(e => e.status === 'inactive').length} icon={<Users className="w-5 h-5" />} color="gray" />
      </div>

      <div className="card">
        <div className="flex items-center gap-4 mb-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search employees..."
              className="input pl-10 w-full"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>
        <DataTable columns={columns} data={employees} isLoading={isLoading} emptyMessage="No employees found" />
      </div>

      {/* Create Employee Modal */}
      {isCreateOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4">
            <div className="flex items-center justify-between px-6 py-4 border-b">
              <h2 className="text-lg font-semibold">Add Employee</h2>
              <button onClick={() => setIsCreateOpen(false)} className="p-1 hover:bg-gray-100 rounded">
                <X size={18} />
              </button>
            </div>
            <form
              className="p-6 space-y-4"
              onSubmit={(e) => {
                e.preventDefault();
                createMutation.mutate();
              }}
            >
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">First Name *</label>
                  <input
                    className="input w-full"
                    value={createForm.first_name}
                    onChange={(e) => setCreateForm((p) => ({ ...p, first_name: e.target.value }))}
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
                  <input
                    className="input w-full"
                    value={createForm.last_name}
                    onChange={(e) => setCreateForm((p) => ({ ...p, last_name: e.target.value }))}
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                <input
                  type="email"
                  className="input w-full"
                  value={createForm.email}
                  onChange={(e) => setCreateForm((p) => ({ ...p, email: e.target.value }))}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Password *</label>
                <input
                  type="password"
                  className="input w-full"
                  value={createForm.password}
                  onChange={(e) => setCreateForm((p) => ({ ...p, password: e.target.value }))}
                  required
                  minLength={6}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                <input
                  className="input w-full"
                  value={createForm.phone}
                  onChange={(e) => setCreateForm((p) => ({ ...p, phone: e.target.value }))}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Role *</label>
                <select
                  className="input w-full"
                  value={createForm.role_names[0]}
                  onChange={(e) => setCreateForm((p) => ({ ...p, role_names: [e.target.value] }))}
                >
                  <option value="admin">Admin</option>
                  <option value="manager">Manager</option>
                  <option value="fleet_manager">Fleet Manager</option>
                  <option value="accountant">Accountant</option>
                  <option value="project_associate">Project Associate</option>
                  <option value="driver">Driver</option>
                </select>
              </div>
              <div className="flex justify-end gap-3 pt-3 border-t">
                <button type="button" className="btn-secondary" onClick={() => setIsCreateOpen(false)}>
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  disabled={createMutation.isPending || !createForm.email || !createForm.password || !createForm.first_name}
                >
                  {createMutation.isPending ? 'Creating...' : 'Create Employee'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
