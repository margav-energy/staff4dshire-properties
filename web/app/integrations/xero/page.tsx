'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function XeroIntegrationPage() {
  const router = useRouter()
  const [isConnected, setIsConnected] = useState(false)

  const handleConnect = () => {
    // Simulate OAuth flow
    alert('Redirecting to Xero for authorization...')
    setTimeout(() => {
      setIsConnected(true)
    }, 2000)
  }

  const handleDisconnect = () => {
    if (confirm('Are you sure you want to disconnect Xero?')) {
      setIsConnected(false)
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
              <h1 className="text-xl font-bold">Xero Integration</h1>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="card">
          <div className="flex items-center space-x-4 mb-6">
            <div className="w-16 h-16 bg-primary-100 rounded-xl flex items-center justify-center">
              <span className="text-2xl">📊</span>
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900">Xero Accounting</h2>
              <p className="text-gray-600">Sync your timesheets with Xero</p>
            </div>
          </div>

          {isConnected ? (
            <div className="space-y-6">
              <div className="p-4 bg-green-50 border border-green-200 rounded-xl">
                <div className="flex items-center">
                  <svg className="w-6 h-6 text-green-600 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <div>
                    <p className="font-semibold text-green-800">Connected</p>
                    <p className="text-sm text-green-700">Your account is synced with Xero</p>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Sync Frequency
                  </label>
                  <select className="input-field">
                    <option>Daily</option>
                    <option>Weekly</option>
                    <option>Manual</option>
                  </select>
                </div>

                <div>
                  <label className="flex items-center">
                    <input type="checkbox" className="rounded border-gray-300 text-primary-700 focus:ring-primary-700" defaultChecked />
                    <span className="ml-2 text-sm text-gray-700">Auto-sync approved timesheets</span>
                  </label>
                </div>
              </div>

              <button
                onClick={handleDisconnect}
                className="btn-outline border-red-600 text-red-600 hover:bg-red-50 w-full"
              >
                Disconnect Xero
              </button>
            </div>
          ) : (
            <div className="space-y-6">
              <div className="p-4 bg-gray-50 rounded-xl">
                <h3 className="font-semibold mb-2">Benefits of connecting:</h3>
                <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
                  <li>Automatically sync timesheet data to Xero</li>
                  <li>Create invoices from approved timesheets</li>
                  <li>Track project costs and expenses</li>
                  <li>Generate financial reports</li>
                </ul>
              </div>

              <button
                onClick={handleConnect}
                className="btn-primary w-full py-4"
              >
                Connect to Xero
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}



