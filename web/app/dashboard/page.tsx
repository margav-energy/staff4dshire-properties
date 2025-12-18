'use client'

import { useSearchParams, useRouter } from 'next/navigation'
import { useState } from 'react'

export default function DashboardPage() {
  const searchParams = useSearchParams()
  const router = useRouter()
  const role = searchParams.get('role') || 'staff'

  const renderDashboard = () => {
    switch (role) {
      case 'admin':
        return <AdminDashboard />
      case 'supervisor':
        return <SupervisorDashboard />
      default:
        return <StaffDashboard />
    }
  }

  return renderDashboard()
}

function StaffDashboard() {
  const router = useRouter()
  
  const handleLogout = () => {
    if (confirm('Are you sure you want to logout?')) {
      router.push('/')
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-primary-700 text-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-bold">Staff4dshire Properties</h1>
            </div>
            <div className="flex items-center space-x-4">
              <button 
                onClick={() => router.push('/notifications')}
                className="p-2 hover:bg-primary-800 rounded-lg relative"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
                <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>
              <button 
                onClick={() => router.push('/settings')}
                className="p-2 hover:bg-primary-800 rounded-lg"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>
              <button 
                onClick={handleLogout}
                className="p-2 hover:bg-primary-800 rounded-lg"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Welcome Section */}
        <div className="card bg-primary-700 text-white mb-8">
          <h2 className="text-2xl font-bold mb-2">Welcome Back!</h2>
          <p className="text-gray-200">
            {new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
          </p>
        </div>

        {/* Quick Actions */}
        <div className="mb-8">
          <h3 className="text-xl font-bold text-gray-900 mb-4">Quick Actions</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <ActionCard 
              icon="📝" 
              title="Sign In/Out" 
              color="primary"
              onClick={() => router.push('/sign-in-out')}
            />
            <ActionCard 
              icon="⏰" 
              title="Timesheet" 
              color="secondary"
              onClick={() => router.push('/timesheet')}
            />
            <ActionCard 
              icon="📁" 
              title="Documents" 
              color="secondary"
              onClick={() => router.push('/documents')}
            />
            <ActionCard 
              icon="✅" 
              title="Compliance" 
              color="success"
              onClick={() => router.push('/compliance/fit-to-work')}
            />
            <ActionCard 
              icon="⚠️" 
              title="Report Incident" 
              color="error"
              onClick={() => router.push('/incidents/report')}
            />
            <ActionCard 
              icon="🔔" 
              title="Notifications" 
              color="info"
              onClick={() => router.push('/notifications')}
            />
            <ActionCard 
              icon="📊" 
              title="Reports" 
              color="warning"
              onClick={() => router.push('/reports')}
            />
            <ActionCard 
              icon="⚙️" 
              title="Settings" 
              color="secondary"
              onClick={() => router.push('/settings')}
            />
          </div>
        </div>

        {/* Weekly Hours Summary */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div className="card">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-gray-900">This Week</h3>
              <svg className="w-6 h-6 text-primary-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div className="text-4xl font-bold text-primary-700 mb-2">42h 30m</div>
            <p className="text-gray-600">Total hours worked</p>
          </div>

          <div className="card">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-gray-900">Recent Activity</h3>
              <svg className="w-6 h-6 text-primary-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <div className="space-y-3">
              <ActivityItem title="Signed in" time="Today, 07:30" status="success" />
              <ActivityItem title="Project: City Center" time="Today, 07:31" status="info" />
              <ActivityItem title="Timesheet submitted" time="Yesterday" status="success" />
            </div>
          </div>
        </div>

        {/* Recent Timesheet Entries */}
        <div className="card">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold text-gray-900">Recent Timesheet Entries</h3>
            <button 
              onClick={() => router.push('/timesheet')}
              className="text-sm text-primary-700 font-semibold hover:text-primary-800"
            >
              View All →
            </button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Date</th>
                  <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Project</th>
                  <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Time</th>
                  <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Hours</th>
                  <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Status</th>
                </tr>
              </thead>
              <tbody>
                {[1, 2, 3, 4, 5].map((i) => (
                  <tr 
                    key={i} 
                    className="border-b border-gray-100 hover:bg-gray-50 cursor-pointer"
                    onClick={() => router.push('/timesheet')}
                  >
                    <td className="py-3 px-4 text-sm text-gray-900">Mon, Jan {i + 15}</td>
                    <td className="py-3 px-4 text-sm text-gray-700">City Center Development</td>
                    <td className="py-3 px-4 text-sm text-gray-700">07:30 - 16:30</td>
                    <td className="py-3 px-4 text-sm font-medium text-primary-700">8h 0m</td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                        Approved
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}

function SupervisorDashboard() {
  const router = useRouter()
  
  const handleLogout = () => {
    if (confirm('Are you sure you want to logout?')) {
      router.push('/')
    }
  }

  const handleApprove = (userId: string) => {
    alert(`Timesheet approved for user ${userId}`)
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-primary-700 text-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-bold">Staff4dshire Properties - Supervisor</h1>
            </div>
            <div className="flex items-center space-x-4">
              <button 
                onClick={() => router.push('/notifications')}
                className="p-2 hover:bg-primary-800 rounded-lg relative"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
                <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>
              <button 
                onClick={() => router.push('/settings')}
                className="p-2 hover:bg-primary-800 rounded-lg"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>
              <button 
                onClick={handleLogout}
                className="p-2 hover:bg-primary-800 rounded-lg"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Live Headcount Card */}
        <div className="card bg-primary-700 text-white mb-8">
          <div className="flex justify-between items-center">
            <div>
              <h2 className="text-xl font-semibold mb-2">Live Headcount</h2>
              <div className="text-5xl font-bold mb-2">42</div>
              <p className="text-gray-200">Currently on site</p>
            </div>
            <div className="w-20 h-20 bg-white bg-opacity-20 rounded-full flex items-center justify-center">
              <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
          </div>
          <button 
            onClick={() => router.push('/compliance/fire-roll-call')}
            className="mt-4 w-full bg-white text-primary-700 py-3 rounded-xl font-semibold hover:bg-gray-100 transition-colors"
          >
            Fire Roll Call
          </button>
        </div>

        {/* Quick Actions */}
        <div className="mb-8">
          <h3 className="text-xl font-bold text-gray-900 mb-4">Quick Actions</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <ActionCard 
              icon="👥" 
              title="View Headcount" 
              color="primary"
              onClick={() => router.push('/reports')}
            />
            <ActionCard 
              icon="✅" 
              title="Approve Times" 
              color="success"
              onClick={() => router.push('/timesheet')}
            />
            <ActionCard 
              icon="✏️" 
              title="Edit Times" 
              color="secondary"
              onClick={() => router.push('/timesheet')}
            />
            <ActionCard 
              icon="📊" 
              title="Reports" 
              color="warning"
              onClick={() => router.push('/reports')}
            />
            <ActionCard 
              icon="🔔" 
              title="Notifications" 
              color="info"
              onClick={() => router.push('/notifications')}
            />
            <ActionCard 
              icon="⚠️" 
              title="Incidents" 
              color="error"
              onClick={() => router.push('/incidents/management')}
            />
            <ActionCard 
              icon="📋" 
              title="Toolbox Talk" 
              color="secondary"
              onClick={() => router.push('/compliance/toolbox-talk')}
            />
            <ActionCard 
              icon="⚙️" 
              title="Settings" 
              color="secondary"
              onClick={() => router.push('/settings')}
            />
          </div>
        </div>

        {/* Pending Approvals */}
        <div className="card mb-8">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold text-gray-900">Pending Approvals</h3>
            <span className="px-3 py-1 bg-primary-100 text-primary-700 rounded-full text-sm font-semibold">
              5
            </span>
          </div>
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                <div className="flex items-center space-x-4">
                  <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
                    <span className="text-primary-700 font-semibold">JD</span>
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">John Doe {i}</p>
                    <p className="text-sm text-gray-600">Week of Jan 15, 2024</p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <button 
                    onClick={() => handleApprove(`user-${i}`)}
                    className="btn-primary py-2 px-4 text-sm"
                  >
                    Approve
                  </button>
                  <button 
                    onClick={() => router.push('/timesheet')}
                    className="p-2 text-gray-600 hover:bg-gray-200 rounded-lg"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function AdminDashboard() {
  const router = useRouter()
  
  const handleLogout = () => {
    if (confirm('Are you sure you want to logout?')) {
      router.push('/')
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-primary-700 text-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-bold">Staff4dshire Properties - Admin</h1>
            </div>
            <div className="flex items-center space-x-4">
              <button 
                onClick={() => router.push('/notifications')}
                className="p-2 hover:bg-primary-800 rounded-lg relative"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
                <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>
              <button 
                onClick={() => router.push('/settings')}
                className="p-2 hover:bg-primary-800 rounded-lg"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>
              <button 
                onClick={handleLogout}
                className="p-2 hover:bg-primary-800 rounded-lg"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Statistics */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard 
            title="Total Staff" 
            value="156" 
            icon="👥" 
            color="primary"
            onClick={() => router.push('/users')}
          />
          <StatCard 
            title="Active Projects" 
            value="12" 
            icon="📍" 
            color="success"
            onClick={() => router.push('/projects')}
          />
          <StatCard 
            title="This Week" 
            value="1,248h" 
            icon="⏰" 
            color="secondary"
            onClick={() => router.push('/reports')}
          />
          <StatCard 
            title="Compliance" 
            value="98%" 
            icon="✅" 
            color="warning"
            onClick={() => router.push('/reports')}
          />
        </div>

        {/* Quick Actions */}
        <div className="mb-8">
          <h3 className="text-xl font-bold text-gray-900 mb-4">Quick Actions</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <ActionCard 
              icon="📊" 
              title="Attendance Reports" 
              color="primary"
              onClick={() => router.push('/reports')}
            />
            <ActionCard 
              icon="📥" 
              title="Export Timesheets" 
              color="success"
              onClick={() => router.push('/timesheet/export')}
            />
            <ActionCard 
              icon="🎓" 
              title="Induction Management" 
              color="secondary"
              onClick={() => router.push('/inductions')}
            />
            <ActionCard 
              icon="👥" 
              title="User Management" 
              color="info"
              onClick={() => router.push('/users')}
            />
            <ActionCard 
              icon="📍" 
              title="Project Management" 
              color="warning"
              onClick={() => router.push('/projects')}
            />
            <ActionCard 
              icon="⚠️" 
              title="Incident Management" 
              color="error"
              onClick={() => router.push('/incidents/management')}
            />
            <ActionCard 
              icon="📋" 
              title="Job Approvals" 
              color="secondary"
              onClick={() => router.push('/jobs/approvals')}
            />
            <ActionCard 
              icon="💰" 
              title="Invoices" 
              color="success"
              onClick={() => router.push('/invoices')}
            />
            <ActionCard 
              icon="⚙️" 
              title="Settings" 
              color="secondary"
              onClick={() => router.push('/settings')}
            />
          </div>
        </div>

        {/* Alerts & Activity */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div className="card">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Alerts</h3>
            <div className="space-y-3">
              <AlertItem 
                icon="⚠️" 
                message="3 Documents Expiring" 
                color="warning"
                onClick={() => router.push('/documents')}
              />
              <AlertItem 
                icon="❌" 
                message="1 Document Expired" 
                color="error"
                onClick={() => router.push('/documents')}
              />
              <AlertItem 
                icon="ℹ️" 
                message="5 Pending Approvals" 
                color="info"
                onClick={() => router.push('/jobs/approvals')}
              />
            </div>
          </div>
          <div className="card">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h3>
            <div className="space-y-3">
              <ActivityItem 
                title="New User Added" 
                time="2 hours ago" 
                status="info"
                onClick={() => router.push('/users')}
              />
              <ActivityItem 
                title="Timesheet Exported" 
                time="5 hours ago" 
                status="success"
                onClick={() => router.push('/timesheet/export')}
              />
              <ActivityItem 
                title="Project Created" 
                time="1 day ago" 
                status="success"
                onClick={() => router.push('/projects')}
              />
            </div>
          </div>
        </div>

        {/* Top Projects */}
        <div className="card">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold text-gray-900">Top Projects This Week</h3>
            <button 
              onClick={() => router.push('/projects')}
              className="text-sm text-primary-700 font-semibold hover:text-primary-800"
            >
              View All →
            </button>
          </div>
          <div className="space-y-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <div 
                key={i} 
                className="flex items-center justify-between p-4 bg-gray-50 rounded-xl hover:bg-gray-100 cursor-pointer transition-colors"
                onClick={() => router.push('/projects')}
              >
                <div className="flex items-center space-x-4">
                  <div className="w-10 h-10 bg-primary-100 text-primary-700 rounded-lg flex items-center justify-center font-semibold">
                    {i}
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">Project {i}</p>
                    <p className="text-sm text-gray-600">{120 + i * 15}h this week</p>
                  </div>
                </div>
                <div className="flex items-center space-x-2 text-gray-600">
                  <span className="font-medium">{25 + i * 3}</span>
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function ActionCard({ icon, title, color, onClick }: { icon: string; title: string; color: string; onClick?: () => void }) {
  const colorClasses: Record<string, string> = {
    primary: 'bg-primary-100 text-primary-700',
    secondary: 'bg-secondary-100 text-secondary-700',
    success: 'bg-green-100 text-green-700',
    warning: 'bg-orange-100 text-orange-700',
    info: 'bg-blue-100 text-blue-700',
    error: 'bg-red-100 text-red-700',
  }

  return (
    <div 
      onClick={onClick}
      className="card hover:shadow-lg transition-shadow cursor-pointer"
    >
      <div className={`w-14 h-14 ${colorClasses[color] || colorClasses.primary} rounded-xl flex items-center justify-center text-2xl mb-3`}>
        {icon}
      </div>
      <h4 className="font-semibold text-gray-900">{title}</h4>
    </div>
  )
}

function StatCard({ title, value, icon, color, onClick }: { title: string; value: string; icon: string; color: string; onClick?: () => void }) {
  const colorClasses: Record<string, string> = {
    primary: 'text-primary-700',
    secondary: 'text-secondary-700',
    success: 'text-green-700',
    warning: 'text-orange-700',
    info: 'text-blue-700',
  }

  return (
    <div 
      onClick={onClick}
      className={`card ${onClick ? 'cursor-pointer hover:shadow-lg transition-shadow' : ''}`}
    >
      <div className="flex justify-between items-start mb-4">
        <p className="text-sm text-gray-600">{title}</p>
        <span className="text-2xl">{icon}</span>
      </div>
      <div className={`text-3xl font-bold ${colorClasses[color] || colorClasses.primary}`}>
        {value}
      </div>
    </div>
  )
}

function ActivityItem({ title, time, status, onClick }: { title: string; time: string; status: string; onClick?: () => void }) {
  const statusColors: Record<string, string> = {
    success: 'text-green-600',
    error: 'text-red-600',
    warning: 'text-orange-600',
    info: 'text-blue-600',
  }

  return (
    <div 
      onClick={onClick}
      className={`flex items-start space-x-3 ${onClick ? 'cursor-pointer hover:bg-gray-50 p-2 rounded-lg -m-2 transition-colors' : ''}`}
    >
      <div className={`w-2 h-2 rounded-full mt-2 ${statusColors[status] || statusColors.info} bg-current`} />
      <div>
        <p className="text-sm font-medium text-gray-900">{title}</p>
        <p className="text-xs text-gray-500">{time}</p>
      </div>
    </div>
  )
}

function AlertItem({ icon, message, color, onClick }: { icon: string; message: string; color: string; onClick?: () => void }) {
  const colorClasses: Record<string, string> = {
    warning: 'text-orange-600',
    error: 'text-red-600',
    info: 'text-blue-600',
  }

  return (
    <div 
      onClick={onClick}
      className={`flex items-center space-x-3 ${onClick ? 'cursor-pointer hover:bg-gray-50 p-2 rounded-lg -m-2 transition-colors' : ''}`}
    >
      <span className="text-xl">{icon}</span>
      <p className={`text-sm font-medium ${colorClasses[color] || colorClasses.info}`}>
        {message}
      </p>
    </div>
  )
}

