import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Users, Search, Plus, Shield, X, Trash2, Mail, Lock, Phone, User, BadgeCheck, Eye, EyeOff } from 'lucide-react';
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

const ROLE_OPTIONS = [
  { value: 'admin', label: 'Admin', description: 'Full system access', color: 'bg-red-50 border-red-200 text-red-700' },
  { value: 'manager', label: 'Manager', description: 'Operations & team management', color: 'bg-blue-50 border-blue-200 text-blue-700' },
  { value: 'fleet_manager', label: 'Fleet Manager', description: 'Vehicle & driver oversight', color: 'bg-indigo-50 border-indigo-200 text-indigo-700' },
  { value: 'accountant', label: 'Accountant', description: 'Finance & billing access', color: 'bg-green-50 border-green-200 text-green-700' },
  { value: 'project_associate', label: 'Project Associate', description: 'Job & trip coordination', color: 'bg-amber-50 border-amber-200 text-amber-700' },
  { value: 'driver', label: 'Driver', description: 'Trip execution & mobile app', color: 'bg-purple-50 border-purple-200 text-purple-700' },
  { value: 'pump_operator', label: 'Pump Operator', description: 'Fuel dispensing & stock management', color: 'bg-orange-50 border-orange-200 text-orange-700' },
] as const;

export default function EmployeesPage() {
  const [search, setSearch] = useState('');
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
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
      setShowPassword(false);
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
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-xl mx-4 overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            {/* Header */}
            <div className="relative bg-gradient-to-r from-blue-600 to-indigo-600 px-6 py-5">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                  <Users className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-white">Add New Employee</h2>
                  <p className="text-blue-100 text-sm">Fill in the details to create a new team member</p>
                </div>
              </div>
              <button
                onClick={() => { setIsCreateOpen(false); setShowPassword(false); }}
                className="absolute top-4 right-4 p-1.5 hover:bg-white/20 rounded-lg transition-colors"
              >
                <X size={18} className="text-white" />
              </button>
            </div>

            <form
              className="p-6 space-y-5"
              onSubmit={(e) => {
                e.preventDefault();
                createMutation.mutate();
              }}
            >
              {/* Name Row */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">First Name <span className="text-red-500">*</span></label>
                  <div className="relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      className="input w-full pl-10"
                      placeholder="John"
                      value={createForm.first_name}
                      onChange={(e) => setCreateForm((p) => ({ ...p, first_name: e.target.value }))}
                      required
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">Last Name</label>
                  <div className="relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      className="input w-full pl-10"
                      placeholder="Doe"
                      value={createForm.last_name}
                      onChange={(e) => setCreateForm((p) => ({ ...p, last_name: e.target.value }))}
                    />
                  </div>
                </div>
              </div>

              {/* Email */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Email Address <span className="text-red-500">*</span></label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="email"
                    className="input w-full pl-10"
                    placeholder="john@kavyatransports.com"
                    value={createForm.email}
                    onChange={(e) => setCreateForm((p) => ({ ...p, email: e.target.value }))}
                    required
                  />
                </div>
              </div>

              {/* Password */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Password <span className="text-red-500">*</span></label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    className="input w-full pl-10 pr-10"
                    placeholder="Min 6 characters"
                    value={createForm.password}
                    onChange={(e) => setCreateForm((p) => ({ ...p, password: e.target.value }))}
                    required
                    minLength={6}
                  />
                  <button
                    type="button"
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    onClick={() => setShowPassword(!showPassword)}
                    tabIndex={-1}
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
                {createForm.password && createForm.password.length < 6 && (
                  <p className="text-xs text-amber-600 mt-1">Password must be at least 6 characters</p>
                )}
              </div>

              {/* Phone */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Phone Number</label>
                <div className="relative">
                  <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="tel"
                    className="input w-full pl-10"
                    placeholder="9876543210"
                    value={createForm.phone}
                    onChange={(e) => setCreateForm((p) => ({ ...p, phone: e.target.value }))}
                  />
                </div>
              </div>

              {/* Role Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  <BadgeCheck className="inline w-4 h-4 mr-1 -mt-0.5" />
                  Assign Role <span className="text-red-500">*</span>
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {ROLE_OPTIONS.map((role) => {
                    const isSelected = createForm.role_names[0] === role.value;
                    return (
                      <button
                        key={role.value}
                        type="button"
                        className={`text-left px-3 py-2.5 rounded-lg border-2 transition-all ${
                          isSelected
                            ? `${role.color} border-current ring-1 ring-current/20 shadow-sm`
                            : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                        }`}
                        onClick={() => setCreateForm((p) => ({ ...p, role_names: [role.value] }))}
                      >
                        <p className={`text-sm font-medium ${isSelected ? '' : 'text-gray-800'}`}>{role.label}</p>
                        <p className={`text-xs mt-0.5 ${isSelected ? 'opacity-80' : 'text-gray-500'}`}>{role.description}</p>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Actions */}
              <div className="flex justify-end gap-3 pt-4 border-t border-gray-100">
                <button
                  type="button"
                  className="px-4 py-2.5 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
                  onClick={() => { setIsCreateOpen(false); setShowPassword(false); }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg transition-colors flex items-center gap-2"
                  disabled={createMutation.isPending || !createForm.email || !createForm.password || !createForm.first_name || createForm.password.length < 6}
                >
                  {createMutation.isPending ? (
                    <>
                      <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" /><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" /></svg>
                      Creating...
                    </>
                  ) : (
                    <>
                      <Plus size={16} /> Create Employee
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
