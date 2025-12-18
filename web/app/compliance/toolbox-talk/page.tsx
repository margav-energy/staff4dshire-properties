'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function ToolboxTalkPage() {
  const router = useRouter()
  const [attendance, setAttendance] = useState<Record<string, boolean>>({})

  // Mock attendees
  const attendees = [
    { id: '1', name: 'John Doe', role: 'Site Worker' },
    { id: '2', name: 'Jane Smith', role: 'Supervisor' },
    { id: '3', name: 'Bob Johnson', role: 'Site Worker' },
  ]

  const handleSubmit = async () => {
    const presentCount = Object.values(attendance).filter(Boolean).length
    alert(`Toolbox talk attendance recorded: ${presentCount} present`)
    router.back()
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
              <h1 className="text-xl font-bold">Toolbox Talk Attendance</h1>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="card mb-6">
          <h2 className="text-xl font-bold mb-2">Today's Toolbox Talk</h2>
          <p className="text-gray-600">
            Topic: Site Safety and Emergency Procedures
          </p>
          <p className="text-sm text-gray-500 mt-2">
            Date: {new Date().toLocaleDateString()}
          </p>
        </div>

        <div className="card">
          <h3 className="text-lg font-semibold mb-4">Mark Attendance</h3>
          <div className="space-y-3">
            {attendees.map((attendee) => (
              <div
                key={attendee.id}
                className="flex items-center justify-between p-4 bg-gray-50 rounded-xl"
              >
                <div>
                  <p className="font-medium text-gray-900">{attendee.name}</p>
                  <p className="text-sm text-gray-600">{attendee.role}</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={attendance[attendee.id] || false}
                    onChange={(e) =>
                      setAttendance({ ...attendance, [attendee.id]: e.target.checked })
                    }
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-700"></div>
                </label>
              </div>
            ))}
          </div>

          <div className="mt-6 pt-6 border-t">
            <div className="flex justify-between items-center mb-4">
              <span className="text-gray-700">Total Present:</span>
              <span className="text-xl font-bold text-primary-700">
                {Object.values(attendance).filter(Boolean).length} / {attendees.length}
              </span>
            </div>
            <button
              onClick={handleSubmit}
              className="btn-primary w-full py-4"
            >
              Record Attendance
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}



