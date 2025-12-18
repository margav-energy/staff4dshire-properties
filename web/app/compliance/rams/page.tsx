'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function RAMSPage() {
  const router = useRouter()
  const [hasRead, setHasRead] = useState(false)
  const [hasUnderstood, setHasUnderstood] = useState(false)
  const [signature, setSignature] = useState('')

  const handleSubmit = async () => {
    if (!hasRead || !hasUnderstood || !signature.trim()) {
      alert('Please complete all required fields')
      return
    }
    alert('RAMS sign-off submitted successfully')
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
              <h1 className="text-xl font-bold">RAMS Sign-Off</h1>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="card mb-6">
          <h2 className="text-xl font-bold mb-4">Risk Assessment and Method Statement</h2>
          <div className="prose max-w-none">
            <p className="text-gray-700 mb-4">
              Please read the following Risk Assessment and Method Statement (RAMS) carefully before signing off.
            </p>
            <div className="bg-gray-50 p-4 rounded-lg mb-4">
              <h3 className="font-semibold mb-2">Project: City Center Development</h3>
              <p className="text-sm text-gray-600 mb-4">
                This document outlines the risks associated with the work and the methods to be used to mitigate those risks.
              </p>
              <div className="space-y-2 text-sm">
                <p><strong>Hazards Identified:</strong></p>
                <ul className="list-disc list-inside ml-4 space-y-1">
                  <li>Working at height</li>
                  <li>Heavy machinery operation</li>
                  <li>Exposure to hazardous materials</li>
                </ul>
                <p className="mt-4"><strong>Control Measures:</strong></p>
                <ul className="list-disc list-inside ml-4 space-y-1">
                  <li>Use of appropriate PPE</li>
                  <li>Regular safety briefings</li>
                  <li>Emergency procedures in place</li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <div className="card space-y-6">
          <div className="flex items-start">
            <input
              type="checkbox"
              id="hasRead"
              checked={hasRead}
              onChange={(e) => setHasRead(e.target.checked)}
              className="mt-1 w-5 h-5 text-primary-700 rounded border-gray-300 focus:ring-primary-700"
            />
            <label htmlFor="hasRead" className="ml-3 text-gray-700">
              I confirm that I have read and understood the Risk Assessment and Method Statement
            </label>
          </div>

          <div className="flex items-start">
            <input
              type="checkbox"
              id="hasUnderstood"
              checked={hasUnderstood}
              onChange={(e) => setHasUnderstood(e.target.checked)}
              className="mt-1 w-5 h-5 text-primary-700 rounded border-gray-300 focus:ring-primary-700"
            />
            <label htmlFor="hasUnderstood" className="ml-3 text-gray-700">
              I understand the risks and control measures and agree to follow them
            </label>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Digital Signature *
            </label>
            <input
              type="text"
              value={signature}
              onChange={(e) => setSignature(e.target.value)}
              className="input-field"
              placeholder="Type your full name to sign"
              required
            />
          </div>

          <button
            onClick={handleSubmit}
            className="btn-primary w-full py-4"
          >
            Sign Off RAMS
          </button>
        </div>
      </div>
    </div>
  )
}



