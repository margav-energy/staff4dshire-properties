'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

interface Job {
  id: string
  title: string
  description: string
  worker: string
  project: string
  submittedAt: string
  status: 'pending' | 'approved' | 'rejected'
}

export default function JobApprovalsPage() {
  const router = useRouter()
  const [jobs] = useState<Job[]>([
    {
      id: '1',
      title: 'Foundation Work Completed',
      description: 'Completed foundation work for Building A',
      worker: 'John Doe',
      project: 'City Center Development',
      submittedAt: '2024-01-16T10:30:00',
      status: 'pending',
    },
    {
      id: '2',
      title: 'Electrical Installation',
      description: 'Completed electrical installation for Unit 5',
      worker: 'Jane Smith',
      project: 'Residential Complex',
      submittedAt: '2024-01-15T14:20:00',
      status: 'pending',
    },
  ])

  const handleApprove = (jobId: string) => {
    alert(`Job ${jobId} approved`)
  }

  const handleReject = (jobId: string) => {
    alert(`Job ${jobId} rejected`)
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
              <h1 className="text-xl font-bold">Job Approvals</h1>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {jobs.length === 0 ? (
          <div className="card text-center py-12">
            <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p className="text-gray-600">No pending job approvals</p>
          </div>
        ) : (
          <div className="space-y-4">
            {jobs.map((job) => (
              <div key={job.id} className="card">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      <h3 className="text-lg font-semibold text-gray-900">{job.title}</h3>
                      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                        job.status === 'pending'
                          ? 'bg-yellow-100 text-yellow-800'
                          : job.status === 'approved'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-red-100 text-red-800'
                      }`}>
                        {job.status}
                      </span>
                    </div>
                    <p className="text-gray-600 mb-3">{job.description}</p>
                    <div className="text-sm text-gray-500 space-y-1">
                      <p>Worker: {job.worker}</p>
                      <p>Project: {job.project}</p>
                      <p>Submitted: {new Date(job.submittedAt).toLocaleString()}</p>
                    </div>
                  </div>
                  {job.status === 'pending' && (
                    <div className="ml-4 flex space-x-2">
                      <button
                        onClick={() => handleApprove(job.id)}
                        className="px-4 py-2 bg-green-600 text-white rounded-lg font-semibold hover:bg-green-700"
                      >
                        Approve
                      </button>
                      <button
                        onClick={() => handleReject(job.id)}
                        className="px-4 py-2 bg-red-600 text-white rounded-lg font-semibold hover:bg-red-700"
                      >
                        Reject
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}



