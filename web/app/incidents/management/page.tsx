'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

type Severity = 'low' | 'medium' | 'high' | 'critical'
type Status = 'open' | 'investigating' | 'resolved' | 'closed'

interface Incident {
  id: string
  description: string
  severity: Severity
  status: Status
  reporter: string
  reportedAt: string
  project?: string
}

export default function IncidentManagementPage() {
  const router = useRouter()
  const [filter, setFilter] = useState<'all' | Severity | Status>('all')

  // Mock data
  const incidents: Incident[] = [
    {
      id: '1',
      description: 'Minor equipment malfunction',
      severity: 'low',
      status: 'resolved',
      reporter: 'John Doe',
      reportedAt: '2024-01-15T10:30:00',
      project: 'City Center Development',
    },
    {
      id: '2',
      description: 'Safety concern with scaffolding',
      severity: 'high',
      status: 'investigating',
      reporter: 'Jane Smith',
      reportedAt: '2024-01-16T14:20:00',
      project: 'Residential Complex',
    },
  ]

  const filteredIncidents = filter === 'all'
    ? incidents
    : incidents.filter(inc => inc.severity === filter || inc.status === filter)

  const getSeverityColor = (severity: Severity) => {
    switch (severity) {
      case 'low': return 'bg-green-100 text-green-800'
      case 'medium': return 'bg-yellow-100 text-yellow-800'
      case 'high': return 'bg-orange-100 text-orange-800'
      case 'critical': return 'bg-red-100 text-red-800'
    }
  }

  const getStatusColor = (status: Status) => {
    switch (status) {
      case 'open': return 'bg-blue-100 text-blue-800'
      case 'investigating': return 'bg-yellow-100 text-yellow-800'
      case 'resolved': return 'bg-green-100 text-green-800'
      case 'closed': return 'bg-gray-100 text-gray-800'
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
              <h1 className="text-xl font-bold">Incident Management</h1>
            </div>
            <button
              onClick={() => router.push('/incidents/report')}
              className="px-4 py-2 bg-white text-primary-700 rounded-lg font-semibold hover:bg-gray-100"
            >
              Report New
            </button>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Filters */}
        <div className="mb-6 flex flex-wrap gap-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-full font-medium ${
              filter === 'all' ? 'bg-primary-700 text-white' : 'bg-white text-gray-700'
            }`}
          >
            All
          </button>
          {(['low', 'medium', 'high', 'critical'] as Severity[]).map((sev) => (
            <button
              key={sev}
              onClick={() => setFilter(sev)}
              className={`px-4 py-2 rounded-full font-medium capitalize ${
                filter === sev ? 'bg-primary-700 text-white' : 'bg-white text-gray-700'
              }`}
            >
              {sev}
            </button>
          ))}
          {(['open', 'investigating', 'resolved', 'closed'] as Status[]).map((stat) => (
            <button
              key={stat}
              onClick={() => setFilter(stat)}
              className={`px-4 py-2 rounded-full font-medium capitalize ${
                filter === stat ? 'bg-primary-700 text-white' : 'bg-white text-gray-700'
              }`}
            >
              {stat}
            </button>
          ))}
        </div>

        {/* Incidents List */}
        {filteredIncidents.length === 0 ? (
          <div className="card text-center py-12">
            <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <p className="text-gray-600">No incidents found</p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredIncidents.map((incident) => (
              <div key={incident.id} className="card">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      <h3 className="font-semibold text-gray-900">{incident.description}</h3>
                      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getSeverityColor(incident.severity)}`}>
                        {incident.severity}
                      </span>
                      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(incident.status)}`}>
                        {incident.status}
                      </span>
                    </div>
                    <div className="text-sm text-gray-600 space-y-1">
                      <p>Reported by: {incident.reporter}</p>
                      <p>Date: {new Date(incident.reportedAt).toLocaleString()}</p>
                      {incident.project && <p>Project: {incident.project}</p>}
                    </div>
                  </div>
                  <button className="p-2 hover:bg-gray-100 rounded-lg">
                    <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}



