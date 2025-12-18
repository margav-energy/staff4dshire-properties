'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function TimesheetPage() {
  const router = useRouter()
  const [selectedWeek, setSelectedWeek] = useState(new Date())

  // Mock data - replace with actual API calls
  const weekEntries = [
    {
      id: '1',
      date: '2024-01-15',
      project: 'City Center Development',
      signIn: '07:30',
      signOut: '16:30',
      hours: 8,
      minutes: 0,
      location: 'London, UK',
      status: 'approved',
    },
    {
      id: '2',
      date: '2024-01-16',
      project: 'City Center Development',
      signIn: '07:30',
      signOut: '16:30',
      hours: 8,
      minutes: 0,
      location: 'London, UK',
      status: 'approved',
    },
  ]

  const totalHours = weekEntries.reduce((sum, entry) => sum + entry.hours + entry.minutes / 60, 0)
  const hours = Math.floor(totalHours)
  const minutes = Math.round((totalHours - hours) * 60)

  const getWeekRange = () => {
    const startOfWeek = new Date(selectedWeek)
    startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay() + 1)
    const endOfWeek = new Date(startOfWeek)
    endOfWeek.setDate(endOfWeek.getDate() + 6)
    
    return `${startOfWeek.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${endOfWeek.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`
  }

  const navigateWeek = (direction: 'prev' | 'next') => {
    const newDate = new Date(selectedWeek)
    newDate.setDate(newDate.getDate() + (direction === 'next' ? 7 : -7))
    setSelectedWeek(newDate)
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
              <h1 className="text-xl font-bold">Timesheet</h1>
            </div>
            <button
              onClick={() => router.push('/timesheet/export')}
              className="p-2 hover:bg-primary-800 rounded-lg"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
            </button>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Weekly Summary */}
        <div className="card bg-primary-700 text-white mb-6">
          <div className="text-center">
            <h2 className="text-xl font-semibold mb-2">This Week</h2>
            <div className="text-5xl font-bold mb-2">
              {hours}h {minutes}m
            </div>
            <p className="text-gray-200">{weekEntries.length} entries</p>
          </div>
        </div>

        {/* Week Navigation */}
        <div className="card mb-6">
          <div className="flex items-center justify-between">
            <button
              onClick={() => navigateWeek('prev')}
              className="p-2 hover:bg-gray-100 rounded-lg"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <span className="text-lg font-semibold">{getWeekRange()}</span>
            <button
              onClick={() => navigateWeek('next')}
              className="p-2 hover:bg-gray-100 rounded-lg"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </div>
        </div>

        {/* Entries List */}
        {weekEntries.length === 0 ? (
          <div className="card text-center py-12">
            <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p className="text-gray-600">No entries this week</p>
          </div>
        ) : (
          <div className="space-y-4">
            {weekEntries.map((entry) => (
              <div key={entry.id} className="card">
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-4">
                    <div className="w-12 h-12 bg-primary-100 rounded-xl flex flex-col items-center justify-center">
                      <span className="text-xs font-semibold text-primary-700">
                        {new Date(entry.date).toLocaleDateString('en-US', { weekday: 'short' }).toUpperCase()}
                      </span>
                      <span className="text-lg font-bold text-primary-700">
                        {new Date(entry.date).getDate()}
                      </span>
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900">{entry.project}</h3>
                      <p className="text-sm text-gray-600 mt-1">
                        {entry.signIn} - {entry.signOut}
                      </p>
                      <p className="text-xs text-gray-500 mt-1">{entry.location}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-semibold text-primary-700">
                      {entry.hours}h {entry.minutes}m
                    </div>
                    <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                      entry.status === 'approved' 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {entry.status === 'approved' ? 'Approved' : 'Pending'}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}



