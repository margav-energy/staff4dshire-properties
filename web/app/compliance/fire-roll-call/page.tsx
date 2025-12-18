'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function FireRollCallPage() {
  const router = useRouter()
  const [status, setStatus] = useState<'in-progress' | 'completed'>('in-progress')
  const [attendance, setAttendance] = useState<Record<string, 'present' | 'missing' | 'unknown'>>({})

  // Mock staff on site
  const staffOnSite = [
    { id: '1', name: 'John Doe', lastSeen: '10:30 AM' },
    { id: '2', name: 'Jane Smith', lastSeen: '10:25 AM' },
    { id: '3', name: 'Bob Johnson', lastSeen: '10:15 AM' },
    { id: '4', name: 'Alice Brown', lastSeen: '10:20 AM' },
  ]

  const handleStatusChange = (staffId: string, newStatus: 'present' | 'missing' | 'unknown') => {
    setAttendance({ ...attendance, [staffId]: newStatus })
  }

  const handleComplete = () => {
    const present = Object.values(attendance).filter(s => s === 'present').length
    const missing = Object.values(attendance).filter(s => s === 'missing').length
    alert(`Fire roll call completed: ${present} present, ${missing} missing`)
    setStatus('completed')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-primary-700 text-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <button onClick={() => router.back()} className="p-2 hover:bg-primary-800 rounded-lg">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </button>
              <h1 className="text-xl font-bold">Fire Roll Call</h1>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="card bg-red-50 border-red-200 mb-6">
          <div className="flex items-center">
            <svg className="w-8 h-8 text-red-600 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <div>
              <h2 className="text-lg font-bold text-red-800">Emergency Roll Call</h2>
              <p className="text-sm text-red-700">Verify all staff are accounted for</p>
            </div>
          </div>
        </div>

        <div className="card">
          <h3 className="text-lg font-semibold mb-4">Staff on Site</h3>
          <div className="space-y-3 mb-6">
            {staffOnSite.map((staff) => (
              <div
                key={staff.id}
                className="flex items-center justify-between p-4 bg-gray-50 rounded-xl"
              >
                <div>
                  <p className="font-medium text-gray-900">{staff.name}</p>
                  <p className="text-sm text-gray-600">Last seen: {staff.lastSeen}</p>
                </div>
                <div className="flex space-x-2">
                  <button
                    onClick={() => handleStatusChange(staff.id, 'present')}
                    className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                      attendance[staff.id] === 'present'
                        ? 'bg-green-600 text-white'
                        : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                    }`}
                  >
                    Present
                  </button>
                  <button
                    onClick={() => handleStatusChange(staff.id, 'missing')}
                    className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                      attendance[staff.id] === 'missing'
                        ? 'bg-red-600 text-white'
                        : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                    }`}
                  >
                    Missing
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="pt-6 border-t">
            <div className="grid grid-cols-3 gap-4 mb-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-green-600">
                  {Object.values(attendance).filter(s => s === 'present').length}
                </div>
                <div className="text-sm text-gray-600">Present</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-red-600">
                  {Object.values(attendance).filter(s => s === 'missing').length}
                </div>
                <div className="text-sm text-gray-600">Missing</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-gray-600">
                  {staffOnSite.length - Object.keys(attendance).length}
                </div>
                <div className="text-sm text-gray-600">Not Checked</div>
              </div>
            </div>

            <button
              onClick={handleComplete}
              disabled={Object.keys(attendance).length !== staffOnSite.length}
              className="btn-primary w-full py-4 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Complete Roll Call
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}



