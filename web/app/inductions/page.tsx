'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

interface Induction {
  id: string
  title: string
  description: string
  status: 'pending' | 'completed' | 'overdue'
  dueDate?: string
  completedDate?: string
}

export default function InductionsPage() {
  const router = useRouter()
  const [inductions] = useState<Induction[]>([
    {
      id: '1',
      title: 'Site Safety Induction',
      description: 'General safety procedures and site rules',
      status: 'completed',
      completedDate: '2024-01-10',
    },
    {
      id: '2',
      title: 'Fire Safety Training',
      description: 'Fire safety procedures and evacuation routes',
      status: 'pending',
      dueDate: '2024-01-25',
    },
    {
      id: '3',
      title: 'Equipment Operation',
      description: 'Training on heavy machinery operation',
      status: 'overdue',
      dueDate: '2024-01-15',
    },
  ])

  const getStatusColor = (status: Induction['status']) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800'
      case 'pending':
        return 'bg-yellow-100 text-yellow-800'
      case 'overdue':
        return 'bg-red-100 text-red-800'
    }
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
              <h1 className="text-xl font-bold">Induction Management</h1>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {inductions.length === 0 ? (
          <div className="card text-center py-12">
            <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
            <p className="text-gray-600">No inductions available</p>
          </div>
        ) : (
          <div className="space-y-4">
            {inductions.map((induction) => (
              <div key={induction.id} className="card">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      <h3 className="text-lg font-semibold text-gray-900">{induction.title}</h3>
                      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(induction.status)}`}>
                        {induction.status}
                      </span>
                    </div>
                    <p className="text-gray-600 mb-3">{induction.description}</p>
                    <div className="text-sm text-gray-500">
                      {induction.status === 'completed' && induction.completedDate && (
                        <p>Completed: {new Date(induction.completedDate).toLocaleDateString()}</p>
                      )}
                      {induction.status !== 'completed' && induction.dueDate && (
                        <p>Due: {new Date(induction.dueDate).toLocaleDateString()}</p>
                      )}
                    </div>
                  </div>
                  <div className="ml-4">
                    {induction.status === 'pending' || induction.status === 'overdue' ? (
                      <button className="btn-primary">
                        Start
                      </button>
                    ) : (
                      <button className="btn-outline">
                        View
                      </button>
                    )}
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



